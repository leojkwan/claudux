#!/bin/bash
# Deterministic docs manifest and static index helpers

DOCS_STRUCTURE_FILE="${DOCS_STRUCTURE_FILE:-docs-structure.json}"
CLAUDUX_INDEX_DIR="${CLAUDUX_INDEX_DIR:-.claudux/index}"
CLAUDUX_STATIC_INDEX_FILE="${CLAUDUX_STATIC_INDEX_FILE:-$CLAUDUX_INDEX_DIR/static-analysis.json}"
CLAUDUX_GUARD_SNAPSHOT_FILE="${CLAUDUX_GUARD_SNAPSHOT_FILE:-$CLAUDUX_INDEX_DIR/docs-guard-snapshot.json}"
CLAUDUX_SECTION_PATCH_FILE="${CLAUDUX_SECTION_PATCH_FILE:-$CLAUDUX_INDEX_DIR/section-patches.json}"

docs_structure_path() {
    echo "${CLAUDUX_DOCS_STRUCTURE:-$DOCS_STRUCTURE_FILE}"
}

require_node_for_manifest() {
    if ! command -v node >/dev/null 2>&1; then
        echo "ERROR: Node.js is required to validate docs-structure.json" >&2
        return 1
    fi
}

# Validate docs-structure.json when present.
# Default mode validates schema only. --post-generation also checks declared
# pages and pinned/required headings exist on disk after the model writes files.
validate_docs_structure_manifest() {
    local mode="preflight"
    if [[ "${1:-}" == "--post-generation" ]]; then
        mode="post-generation"
    fi

    local manifest
    manifest="$(docs_structure_path)"
    if [[ ! -f "$manifest" ]]; then
        return 0
    fi

    require_node_for_manifest || return 1

    node - "$manifest" "$mode" <<'NODE'
const fs = require('fs');

const manifestPath = process.argv[2];
const mode = process.argv[3] || 'preflight';
const errors = [];

function fail(message) {
  errors.push(`docs-structure.json: ${message}`);
}

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

let manifest;
try {
  manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
} catch (error) {
  fail(`invalid JSON (${error.message})`);
  manifest = null;
}

if (manifest) {
  if (!isObject(manifest)) fail('root must be an object');
  if (manifest.version === undefined) fail('missing required "version"');
  if (!Array.isArray(manifest.pages) || manifest.pages.length === 0) {
    fail('missing non-empty "pages" array');
  }

  const pageIds = new Set();
  const pagePaths = new Set();
  let sourceOwnedPages = 0;
  let pinnedSections = 0;

  for (const [pageIndex, page] of (manifest.pages || []).entries()) {
    const label = page?.id || `pages[${pageIndex}]`;
    if (!isObject(page)) {
      fail(`pages[${pageIndex}] must be an object`);
      continue;
    }

    if (!page.id || typeof page.id !== 'string') {
      fail(`${label}: missing string id`);
    } else if (pageIds.has(page.id)) {
      fail(`${label}: duplicate page id`);
    } else {
      pageIds.add(page.id);
    }

    if (!page.path || typeof page.path !== 'string') {
      fail(`${label}: missing string path`);
    } else {
      if (page.path.startsWith('/') || page.path.includes('..')) {
        fail(`${label}: path must be a relative docs path`);
      }
      if (!page.path.startsWith('docs/') || !page.path.endsWith('.md')) {
        fail(`${label}: path must start with docs/ and end with .md`);
      }
      if (pagePaths.has(page.path)) {
        fail(`${label}: duplicate page path ${page.path}`);
      } else {
        pagePaths.add(page.path);
      }
    }

    if (!page.title || typeof page.title !== 'string') {
      fail(`${label}: missing string title`);
    }

    if (!page.deletion_policy || typeof page.deletion_policy !== 'string') {
      fail(`${label}: missing string deletion_policy`);
    }

    if (page.source_patterns !== undefined) {
      if (!Array.isArray(page.source_patterns)) {
        fail(`${label}: source_patterns must be an array`);
      } else if (page.source_patterns.length > 0) {
        sourceOwnedPages += 1;
      }
    }

    const sections = page.sections;
    if (sections !== undefined && !Array.isArray(sections)) {
      fail(`${label}: sections must be an array`);
      continue;
    }

    const sectionIds = new Set();
    for (const [sectionIndex, section] of (sections || []).entries()) {
      const sectionLabel = section?.id || `${label}.sections[${sectionIndex}]`;
      if (!isObject(section)) {
        fail(`${sectionLabel}: section must be an object`);
        continue;
      }
      if (!section.id || typeof section.id !== 'string') {
        fail(`${sectionLabel}: missing string id`);
      } else if (sectionIds.has(section.id)) {
        fail(`${sectionLabel}: duplicate section id`);
      } else {
        sectionIds.add(section.id);
      }
      if (!section.heading || typeof section.heading !== 'string') {
        fail(`${sectionLabel}: missing string heading`);
      }
      if (!Number.isInteger(section.level) || section.level < 1 || section.level > 6) {
        fail(`${sectionLabel}: level must be an integer from 1 to 6`);
      }
      if (section.pinned === true) pinnedSections += 1;
    }

    if (mode === 'post-generation' && page.path && fs.existsSync(page.path)) {
      const content = fs.readFileSync(page.path, 'utf8');
      for (const section of sections || []) {
        if (!section.heading || !section.level) continue;
        if (section.required === false && section.pinned !== true) continue;
        const headingPattern = new RegExp(
          `^#{${section.level}}\\s+${escapeRegExp(section.heading)}(?:\\s+\\{#[^}]+\\})?\\s*$`,
          'm'
        );
        if (!headingPattern.test(content)) {
          fail(`${label}: missing required heading "${section.heading}" in ${page.path}`);
        }
      }
    } else if (mode === 'post-generation' && page.path) {
      fail(`${label}: manifest page is missing on disk (${page.path})`);
    }
  }

  if (mode === 'post-generation' && pinnedSections === 0) {
    fail('post-generation validation requires at least one pinned section');
  }

  if (errors.length === 0) {
    console.log(
      `[claudux:manifest] ok (${(manifest.pages || []).length} pages, ${sourceOwnedPages} source-owned pages, ${pinnedSections} pinned sections)`
    );
  }
}

if (errors.length > 0) {
  for (const error of errors) console.error(`[claudux:manifest] ${error}`);
  process.exit(1);
}
NODE
}

# Build a deterministic static index before model invocation. The index is
# local cache state and intentionally lives under .claudux/index/.
build_static_analysis_index() {
    local manifest index_dir index_file
    manifest="$(docs_structure_path)"
    index_dir="${CLAUDUX_INDEX_DIR:-.claudux/index}"
    index_file="${CLAUDUX_STATIC_INDEX_FILE:-$index_dir/static-analysis.json}"

    require_node_for_manifest || return 1
    mkdir -p "$index_dir" || return 1

    node - "$manifest" "$index_file" <<'NODE'
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

const manifestPath = process.argv[2];
const indexFile = process.argv[3];

function sha256File(filePath) {
  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

function sha256String(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function git(args) {
  return execFileSync('git', args, {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'ignore'],
  }).trim();
}

function trackedFiles() {
  try {
    const output = execFileSync('git', ['ls-files', '-z'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    return output.split('\0').filter(Boolean).sort();
  } catch {
    return [];
  }
}

function headingsFor(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  return content
    .split(/\r?\n/)
    .map(line => line.match(/^(#{1,6})\s+(.+?)\s*$/))
    .filter(Boolean)
    .map(match => ({
      level: match[1].length,
      text: match[2].replace(/\s+\{#[^}]+}\s*$/, '').trim(),
    }));
}

function normalizeSourcePath(rawValue, fromFile, trackedSet) {
  let candidate = String(rawValue || '').trim().replace(/^['"]|['"]$/g, '');
  if (!candidate || candidate.startsWith('<(')) return null;

  candidate = candidate
    .replace(/\$\{LIB_DIR\}/g, 'lib')
    .replace(/\$LIB_DIR/g, 'lib')
    .replace(/\$\{SCRIPT_DIR\}\/\.\.\/lib\//g, 'lib/')
    .replace(/\$SCRIPT_DIR\/\.\.\/lib\//g, 'lib/');

  if (candidate.startsWith('${SCRIPT_DIR}/') || candidate.startsWith('$SCRIPT_DIR/')) {
    const suffix = candidate.replace(/^\$\{?SCRIPT_DIR\}?\//, '');
    if (fromFile.startsWith('tests/')) {
      candidate = `tests/${suffix}`;
    } else if (fromFile.startsWith('bin/')) {
      candidate = `bin/${suffix}`;
    } else {
      candidate = path.normalize(path.join(path.dirname(fromFile), suffix));
    }
  } else if (candidate.startsWith('./') || candidate.startsWith('../')) {
    candidate = path.normalize(path.join(path.dirname(fromFile), candidate));
  }

  candidate = path.normalize(candidate).replace(/\\/g, '/').replace(/^\.\//, '');
  if (candidate.startsWith('../')) return null;
  if (trackedSet.has(candidate) || fs.existsSync(candidate)) return candidate;
  return null;
}

function isShellLikeFile(filePath) {
  if (filePath === 'bin/claudux' || filePath.endsWith('.sh') || filePath.endsWith('.bash') || filePath.endsWith('.zsh')) {
    return true;
  }
  try {
    return /^#!.*\b(?:bash|sh|zsh)\b/.test(fs.readFileSync(filePath, 'utf8').split(/\r?\n/, 1)[0] || '');
  } catch {
    return false;
  }
}

function shellSourceEdges(filePath, trackedSet) {
  if (!isShellLikeFile(filePath)) return [];

  const content = fs.readFileSync(filePath, 'utf8');
  const edges = [];

  if (filePath === 'bin/claudux') {
    const libsMatch = content.match(/REQUIRED_LIBS=\(([\s\S]*?)\)/m);
    if (libsMatch) {
      const libs = [...libsMatch[1].matchAll(/"([^"]+)"/g)].map(match => `lib/${match[1]}`);
      for (const lib of libs) {
        if (trackedSet.has(lib) || fs.existsSync(lib)) {
          edges.push({ from: filePath, to: lib, kind: 'shell-source' });
        }
      }
    }
    if (trackedSet.has('lib/codex-utils.sh') || fs.existsSync('lib/codex-utils.sh')) {
      edges.push({ from: filePath, to: 'lib/codex-utils.sh', kind: 'conditional-shell-source' });
    }
  }

  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const match = trimmed.match(/^(?:if\s+!\s+)?(?:source|\.)\s+([^;\s]+)/);
    if (!match) continue;
    const target = normalizeSourcePath(match[1], filePath, trackedSet);
    if (target && target !== filePath) {
      edges.push({ from: filePath, to: target, kind: 'shell-source' });
    }
  }

  return edges;
}

function packageScriptEdges(packageScripts, trackedSet) {
  const edges = [];
  for (const [scriptName, script] of Object.entries(packageScripts || {})) {
    const regex = /(?:^|[\s"'`])((?:bin|lib|tests|scripts)\/[A-Za-z0-9._/-]+)(?=$|[\s"'`;])/g;
    let match;
    while ((match = regex.exec(String(script))) !== null) {
      let target = match[1].replace(/^\.\//, '');
      if (!path.extname(target)) {
        for (const ext of ['', '.sh', '.js', '.mjs']) {
          if (trackedSet.has(`${target}${ext}`) || fs.existsSync(`${target}${ext}`)) {
            target = `${target}${ext}`;
            break;
          }
        }
      }
      if (trackedSet.has(target) || fs.existsSync(target)) {
        edges.push({ from: 'package.json', to: target, kind: `package-script:${scriptName}` });
      }
    }
  }
  return edges;
}

function shellFunctionExports(filePath) {
  if (!isShellLikeFile(filePath)) return [];

  const content = fs.readFileSync(filePath, 'utf8');
  return content
    .split(/\r?\n/)
    .map(line => line.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{/))
    .filter(Boolean)
    .map(match => ({ file: filePath, name: match[1], kind: 'shell-function' }));
}

function cliCommandsFromBin(filePath) {
  if (!fs.existsSync(filePath)) return [];
  const content = fs.readFileSync(filePath, 'utf8');
  const commands = new Set();
  for (const line of content.split(/\r?\n/)) {
    const match = line.match(/^\s*((?:"[^"]+"|'[^']+'|[A-Za-z0-9_-]+)(?:\|(?:"[^"]+"|'[^']+'|[A-Za-z0-9_-]+))*)\)/);
    if (!match) continue;
    for (const raw of match[1].split('|')) {
      const command = raw.replace(/^['"]|['"]$/g, '');
      if (command && command !== '*' && command !== '""') commands.add(command);
    }
  }
  return [...commands].sort();
}

function docsPathFromLink(link, fromFile) {
  if (!link || /^(?:https?:|mailto:|tel:)/.test(link) || link.startsWith('#')) return null;
  const clean = link.split('#')[0].split('?')[0];
  if (!clean) return null;

  let target;
  if (clean.startsWith('/')) {
    target = `docs${clean}`;
  } else {
    target = path.join(path.dirname(fromFile), clean);
  }
  target = target.replace(/\\/g, '/');
  if (target.endsWith('/')) target += 'index.md';
  if (!path.extname(target)) target += '.md';
  return path.normalize(target).replace(/\\/g, '/').replace(/^\.\//, '');
}

function docsLinksFor(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const links = [];
  const regex = /\[[^\]]+\]\(([^)]+)\)/g;
  let match;
  while ((match = regex.exec(content)) !== null) {
    const target = docsPathFromLink(match[1], filePath);
    if (target) links.push({ from: filePath, to: target, kind: 'markdown-link' });
  }
  return links;
}

const files = trackedFiles();
const trackedSet = new Set(files);
const docsFiles = files.filter(file => file.startsWith('docs/') && file.endsWith('.md'));
const sourceFiles = files.filter(file => {
  if (file.startsWith('docs/')) return false;
  if (file.startsWith('.claudux/')) return false;
  if (file.includes('/node_modules/')) return false;
  return fs.existsSync(file) && fs.statSync(file).isFile();
});

let manifest = null;
if (fs.existsSync(manifestPath)) {
  manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
}

let packageScripts = {};
if (fs.existsSync('package.json')) {
  try {
    packageScripts = JSON.parse(fs.readFileSync('package.json', 'utf8')).scripts || {};
  } catch {
    packageScripts = {};
  }
}

let headSha = 'unknown';
try {
  headSha = git(['rev-parse', 'HEAD']);
} catch {
  headSha = 'unknown';
}

const dependencyEdges = [
  ...sourceFiles.flatMap(file => shellSourceEdges(file, trackedSet)),
  ...packageScriptEdges(packageScripts, trackedSet),
]
  .filter((edge, index, all) =>
    all.findIndex(candidate => candidate.from === edge.from && candidate.to === edge.to && candidate.kind === edge.kind) === index
  )
  .sort((a, b) => `${a.from}\0${a.to}\0${a.kind}`.localeCompare(`${b.from}\0${b.to}\0${b.kind}`));

const index = {
  version: 1,
  generated_at: new Date().toISOString(),
  head_sha: headSha,
  manifest: manifest
    ? {
        path: manifestPath,
        sha256: sha256File(manifestPath),
        pages: Array.isArray(manifest.pages) ? manifest.pages.length : 0,
        source_owned_pages: Array.isArray(manifest.pages)
          ? manifest.pages.filter(page => Array.isArray(page.source_patterns) && page.source_patterns.length > 0).length
          : 0,
      }
    : null,
  package_scripts: packageScripts,
  cli_commands: cliCommandsFromBin('bin/claudux'),
  exported_symbols: sourceFiles.flatMap(shellFunctionExports).sort((a, b) =>
    `${a.file}\0${a.name}`.localeCompare(`${b.file}\0${b.name}`)
  ),
  tests: sourceFiles
    .filter(file => file.startsWith('tests/'))
    .map(file => ({ path: file, sha256: sha256File(file) })),
  dependency_edges: dependencyEdges,
  source_files: sourceFiles.map(file => ({
    path: file,
    sha256: sha256File(file),
  })),
  docs_files: docsFiles.map(file => ({
    path: file,
    sha256: sha256File(file),
    headings: headingsFor(file),
  })),
  docs_links: docsFiles.flatMap(docsLinksFor).sort((a, b) =>
    `${a.from}\0${a.to}`.localeCompare(`${b.from}\0${b.to}`)
  ),
  source_ownership: manifest && Array.isArray(manifest.pages)
    ? manifest.pages.map(page => ({
        page_id: page.id,
        path: page.path,
        source_patterns: page.source_patterns || [],
        sections: (page.sections || []).map(section => ({
          section_id: section.id,
          heading: section.heading,
          level: section.level,
          pinned: section.pinned === true,
          source_patterns: section.source_patterns || [],
        })),
      }))
    : [],
};

fs.mkdirSync(path.dirname(indexFile), { recursive: true });
fs.writeFileSync(indexFile, `${JSON.stringify(index, null, 2)}\n`);
console.log(
  `[claudux:index] wrote ${indexFile} (${index.source_files.length} source files, ${index.docs_files.length} docs files, ${sha256String(JSON.stringify(index.source_ownership)).slice(0, 12)} ownership hash)`
);
NODE
}

format_static_analysis_index_context() {
    local index_file="${CLAUDUX_STATIC_INDEX_FILE:-${CLAUDUX_INDEX_DIR:-.claudux/index}/static-analysis.json}"
    if [[ ! -f "$index_file" ]]; then
        return 0
    fi

    require_node_for_manifest || return 1

    node - "$index_file" <<'NODE'
const fs = require('fs');
const index = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));

console.log('**STATIC ANALYSIS INDEX (authoritative facts before model output)**');
console.log(`- Index file: ${process.argv[2]}`);
console.log(`- HEAD: ${index.head_sha}`);
console.log(`- Source files indexed: ${index.source_files.length}`);
console.log(`- Documentation files indexed: ${index.docs_files.length}`);
if (index.manifest) {
  console.log(`- Manifest: ${index.manifest.path} (${index.manifest.pages} pages, ${index.manifest.source_owned_pages} source-owned)`);
}
const scripts = Object.keys(index.package_scripts || {});
if (scripts.length > 0) {
  console.log(`- Package scripts: ${scripts.sort().join(', ')}`);
}
if ((index.cli_commands || []).length > 0) {
  console.log(`- CLI commands: ${index.cli_commands.join(', ')}`);
}
if ((index.tests || []).length > 0) {
  console.log(`- Test files indexed: ${index.tests.length}`);
}
if ((index.dependency_edges || []).length > 0) {
  console.log(`- Dependency edges indexed: ${index.dependency_edges.length}`);
}
const owned = (index.source_ownership || []).filter(page => (page.source_patterns || []).length > 0);
if (owned.length > 0) {
  console.log('- Source-owned pages:');
  for (const page of owned.slice(0, 40)) {
    console.log(`  - ${page.page_id} -> ${page.path} <= ${page.source_patterns.join(', ')}`);
  }
}
console.log('- Generation rule: preserve manifest page IDs, nav order, deletion_policy, and pinned sections unless docs-structure.json changes first.');
NODE
}

claudux_section_patch_mode_enabled() {
    local manifest
    manifest="$(docs_structure_path)"
    [[ -f "$manifest" ]]
}

format_section_patch_contract() {
    local manifest
    manifest="$(docs_structure_path)"
    if [[ ! -f "$manifest" ]]; then
        return 0
    fi

    require_node_for_manifest || return 1

    node - "$manifest" <<'NODE'
const fs = require('fs');

const manifestPath = process.argv[2];
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const allowed = [];
const pinned = [];

for (const page of manifest.pages || []) {
  for (const section of page.sections || []) {
    const entry = {
      page_id: page.id,
      section_id: section.id,
      path: page.path,
      heading: section.heading,
      level: section.level,
    };
    if (section.pinned === true || section.generated === false) {
      pinned.push(entry);
    } else {
      allowed.push(entry);
    }
  }
}

console.log('**SECTION PATCH MODE (manifest-enforced)**');
console.log('- Direct documentation writes are disabled. Return patch JSON in your final response; claudux will apply it.');
console.log('- Output exactly one payload between CLAUDUX_SECTION_PATCHES_JSON_START and CLAUDUX_SECTION_PATCHES_JSON_END.');
console.log('- Schema: {"patches":[{"page_id":"...","section_id":"...","body_markdown":"markdown body without the heading"}]}');
console.log('- Pinned sections are read-only unless the human explicitly runs with CLAUDUX_UNLOCK_PINNED_SECTIONS=1 and the patch sets "unlock_pinned": true.');
if (allowed.length > 0) {
  console.log('- Allowed generated sections:');
  for (const section of allowed) {
    console.log(`  - ${section.page_id}#${section.section_id} -> ${section.path} (h${section.level} ${section.heading})`);
  }
} else {
  console.log('- Allowed generated sections: none. Return {"patches":[]} unless you are proposing a manifest diff for a future run.');
}
if (pinned.length > 0) {
  console.log('- Read-only pinned/source-owned sections:');
  for (const section of pinned.slice(0, 40)) {
    console.log(`  - ${section.page_id}#${section.section_id} -> ${section.path} (h${section.level} ${section.heading})`);
  }
}
NODE
}

extract_section_patch_payload() {
    local log_file="$1"
    local output_file="${2:-${CLAUDUX_SECTION_PATCH_FILE:-${CLAUDUX_INDEX_DIR:-.claudux/index}/section-patches.json}}"

    require_node_for_manifest || return 1
    mkdir -p "$(dirname "$output_file")" || return 1

    node - "$log_file" "$output_file" <<'NODE'
const fs = require('fs');

const logFile = process.argv[2];
const outputFile = process.argv[3];
const raw = fs.existsSync(logFile) ? fs.readFileSync(logFile, 'utf8') : '';
const chunks = [];

function collectStrings(value) {
  if (typeof value === 'string') {
    chunks.push(value);
    return;
  }
  if (Array.isArray(value)) {
    for (const item of value) collectStrings(item);
    return;
  }
  if (value && typeof value === 'object') {
    for (const [key, nested] of Object.entries(value)) {
      if (['text', 'content', 'result', 'message', 'summary'].includes(key)) {
        collectStrings(nested);
      } else if (typeof nested === 'object') {
        collectStrings(nested);
      }
    }
  }
}

for (const line of raw.split(/\r?\n/)) {
  if (!line.trim()) continue;
  try {
    collectStrings(JSON.parse(line));
  } catch {
    chunks.push(line);
  }
}

const text = chunks.join('\n');
const match = text.match(/CLAUDUX_SECTION_PATCHES_JSON_START\s*([\s\S]*?)\s*CLAUDUX_SECTION_PATCHES_JSON_END/);
if (!match) {
  console.error('[claudux:patch] missing section patch payload markers');
  process.exit(1);
}

let payloadText = match[1].trim();
payloadText = payloadText.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim();

let payload;
try {
  payload = JSON.parse(payloadText);
} catch (error) {
  console.error(`[claudux:patch] invalid section patch JSON (${error.message})`);
  process.exit(1);
}

if (Array.isArray(payload)) {
  payload = { patches: payload };
}
if (!payload || !Array.isArray(payload.patches)) {
  console.error('[claudux:patch] payload must be an object with a patches array');
  process.exit(1);
}

fs.mkdirSync(require('path').dirname(outputFile), { recursive: true });
fs.writeFileSync(outputFile, `${JSON.stringify(payload, null, 2)}\n`);
console.log(`[claudux:patch] extracted ${payload.patches.length} patch(es) to ${outputFile}`);
NODE
}

apply_manifest_section_patches() {
    local patch_file="${1:-${CLAUDUX_SECTION_PATCH_FILE:-${CLAUDUX_INDEX_DIR:-.claudux/index}/section-patches.json}}"
    local manifest
    manifest="$(docs_structure_path)"

    if [[ ! -f "$manifest" ]]; then
        return 0
    fi
    if [[ ! -f "$patch_file" ]]; then
        echo "[claudux:patch] no section patch file found: $patch_file" >&2
        return 1
    fi

    require_node_for_manifest || return 1

    node - "$manifest" "$patch_file" <<'NODE'
const fs = require('fs');
const path = require('path');

const manifestPath = process.argv[2];
const patchPath = process.argv[3];
const unlockPinned = process.env.CLAUDUX_UNLOCK_PINNED_SECTIONS === '1';
const impactAllowlistPath = process.env.CLAUDUX_IMPACT_ALLOWLIST_FILE || '';
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const payload = JSON.parse(fs.readFileSync(patchPath, 'utf8'));
const patches = Array.isArray(payload) ? payload : payload.patches;
const errors = [];
const applied = [];
let impactAllowlist = null;
const fileStates = new Map();
const operations = [];
const seenTargets = new Set();

if (impactAllowlistPath && fs.existsSync(impactAllowlistPath)) {
  impactAllowlist = JSON.parse(fs.readFileSync(impactAllowlistPath, 'utf8'));
}

function fail(message) {
  errors.push(`section patch: ${message}`);
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function normalizeBody(value, section) {
  let body = String(value ?? '').replace(/\r\n/g, '\n').trim();
  const headingPattern = new RegExp(`^#{${section.level}}\\s+${escapeRegExp(section.heading)}(?:\\s+\\{#[^}]+\\})?\\s*\\n+`);
  body = body.replace(headingPattern, '').trim();
  return body;
}

function bodyBoundaryHeading(body, section) {
  let fenceChar = null;
  for (const [offset, line] of body.split('\n').entries()) {
    const fence = line.match(/^\s*(```+|~~~+)/);
    if (fence) {
      const currentFenceChar = fence[1][0];
      if (!fenceChar) {
        fenceChar = currentFenceChar;
      } else if (fenceChar === currentFenceChar) {
        fenceChar = null;
      }
      continue;
    }
    if (fenceChar) continue;

    const match = line.match(/^(#{1,6})\s+(.+?)\s*$/);
    if (match && match[1].length <= section.level) {
      return {
        line: offset + 1,
        level: match[1].length,
        heading: match[2].trim(),
      };
    }
  }
  return null;
}

function findSection(lines, section) {
  const headingPattern = new RegExp(
    `^#{${section.level}}\\s+${escapeRegExp(section.heading)}(?:\\s+\\{#[^}]+\\})?\\s*$`
  );
  const start = lines.findIndex(line => headingPattern.test(line));
  if (start === -1) return null;

  let end = lines.length;
  for (let index = start + 1; index < lines.length; index += 1) {
    const match = lines[index].match(/^(#{1,6})\s+/);
    if (match && match[1].length <= section.level) {
      end = index;
      break;
    }
  }

  return { start, end };
}

function readPageState(pagePath) {
  if (!fileStates.has(pagePath)) {
    const original = fs.readFileSync(pagePath, 'utf8').replace(/\r\n/g, '\n');
    const hadFinalNewline = original.endsWith('\n');
    const lines = original.split('\n');
    if (hadFinalNewline) lines.pop();
    fileStates.set(pagePath, { lines, changed: false });
  }
  return fileStates.get(pagePath);
}

function impactAllowlistAllows(page, section) {
  if (!impactAllowlist) return true;
  const pageIds = new Set((impactAllowlist.pages || []).map(item => item.page_id));
  const sectionIds = new Set((impactAllowlist.sections || []).map(item => `${item.page_id}#${item.section_id}`));
  if (sectionIds.has(`${page.id}#${section.id}`)) return true;
  const sectionHasSourcePatterns = Array.isArray(section.source_patterns) && section.source_patterns.length > 0;
  return !sectionHasSourcePatterns && pageIds.has(page.id);
}

if (!Array.isArray(patches)) {
  fail('payload must include a patches array');
} else {
  for (const [index, patch] of patches.entries()) {
    if (!patch || typeof patch !== 'object') {
      fail(`patches[${index}] must be an object`);
      continue;
    }

    const page = (manifest.pages || []).find(candidate => candidate.id === patch.page_id);
    if (!page) {
      fail(`patches[${index}] references unknown page_id "${patch.page_id}"`);
      continue;
    }

    const section = (page.sections || []).find(candidate => candidate.id === patch.section_id);
    if (!section) {
      fail(`patches[${index}] references unknown section_id "${patch.section_id}" on ${page.id}`);
      continue;
    }

    const targetKey = `${page.id}#${section.id}`;
    if (seenTargets.has(targetKey)) {
      fail(`patches[${index}] duplicates target ${targetKey}`);
      continue;
    }
    seenTargets.add(targetKey);

    if (!impactAllowlistAllows(page, section)) {
      fail(`${page.id}#${section.id} is outside incremental impact allowlist`);
      continue;
    }

    if ((section.pinned === true || section.generated === false) && !(unlockPinned && patch.unlock_pinned === true)) {
      fail(`${page.id}#${section.id} is pinned/read-only; set CLAUDUX_UNLOCK_PINNED_SECTIONS=1 and unlock_pinned=true to patch it`);
      continue;
    }

    if (!fs.existsSync(page.path)) {
      fail(`${page.path} does not exist; create manifest pages before section patching`);
      continue;
    }

    const rawBody = patch.body_markdown ?? patch.markdown ?? patch.content;
    if (typeof rawBody !== 'string') {
      fail(`${page.id}#${section.id} patch is missing body_markdown`);
      continue;
    }

    const body = normalizeBody(rawBody, section);
    const boundaryHeading = bodyBoundaryHeading(body, section);
    if (boundaryHeading) {
      fail(`${page.id}#${section.id} body contains h${boundaryHeading.level} heading "${boundaryHeading.heading}" on body line ${boundaryHeading.line}; section patches cannot create same-or-higher-level headings`);
      continue;
    }

    const state = readPageState(page.path);
    const span = findSection(state.lines, section);
    if (!span && patch.create_if_missing !== true) {
      fail(`${page.path} is missing heading "${section.heading}"`);
      continue;
    }

    operations.push({
      page_id: page.id,
      section_id: section.id,
      page_path: page.path,
      section,
      body,
      create_if_missing: patch.create_if_missing === true,
    });
  }
}

if (errors.length === 0) {
  for (const operation of operations) {
    const state = readPageState(operation.page_path);
    let span = findSection(state.lines, operation.section);
    if (!span) {
      if (operation.create_if_missing) {
        state.lines.push('', `${'#'.repeat(operation.section.level)} ${operation.section.heading}`);
        span = { start: state.lines.length - 1, end: state.lines.length };
      } else {
        fail(`${operation.page_path} is missing heading "${operation.section.heading}"`);
        continue;
      }
    }

    const replacement = [state.lines[span.start]];
    const body = operation.body;
    if (body.length > 0) {
      replacement.push('', ...body.split('\n'));
    }
    replacement.push('');

    const next = [
      ...state.lines.slice(0, span.start),
      ...replacement,
      ...state.lines.slice(span.end),
    ];
    state.lines = next.join('\n').replace(/\n{3,}/g, '\n\n').trimEnd().split('\n');
    state.changed = true;
    applied.push(`${operation.page_id}#${operation.section_id}`);
  }
}

if (errors.length > 0) {
  for (const error of errors) console.error(`[claudux:patch] ${error}`);
  process.exit(1);
}

for (const [pagePath, state] of fileStates.entries()) {
  if (!state.changed) continue;
  fs.mkdirSync(path.dirname(pagePath), { recursive: true });
  fs.writeFileSync(pagePath, `${state.lines.join('\n').trimEnd()}\n`);
}

console.log(`[claudux:patch] applied ${applied.length} section patch(es)`);
for (const item of applied) console.log(`[claudux:patch] ${item}`);
NODE
}

capture_docs_structure_guard_snapshot() {
    local manifest snapshot_file snapshot_dir
    manifest="$(docs_structure_path)"
    snapshot_file="${CLAUDUX_GUARD_SNAPSHOT_FILE:-${CLAUDUX_INDEX_DIR:-.claudux/index}/docs-guard-snapshot.json}"
    snapshot_dir="$(dirname "$snapshot_file")"

    require_node_for_manifest || return 1
    mkdir -p "$snapshot_dir" || return 1

    node - "$manifest" "$snapshot_file" <<'NODE'
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const manifestPath = process.argv[2];
const snapshotFile = process.argv[3];

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function findHeading(content, section) {
  const pattern = new RegExp(
    `^#{${section.level}}\\s+${escapeRegExp(section.heading)}(?:\\s+\\{#[^}]+\\})?\\s*$`,
    'm'
  );
  const match = pattern.exec(content);
  if (!match) return null;
  return content.slice(0, match.index).split(/\r?\n/).length;
}

function walkMarkdown(dir) {
  if (!fs.existsSync(dir)) return [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const entryPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === '.vitepress') continue;
      files.push(...walkMarkdown(entryPath));
    } else if (entry.isFile() && entryPath.endsWith('.md')) {
      files.push(entryPath.split(path.sep).join('/'));
    }
  }
  return files.sort();
}

function protectedBlocks(content) {
  const blocks = [];
  const marker = /<!--\s*skip\s*-->([\s\S]*?)<!--\s*\/skip\s*-->/g;
  let match;
  while ((match = marker.exec(content)) !== null) {
    blocks.push({
      sha256: sha256(match[0]),
      preview: match[0].split(/\r?\n/).slice(0, 3).join('\\n'),
    });
  }
  return blocks;
}

let manifest = null;
if (fs.existsSync(manifestPath)) {
  manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
}

const pinnedPages = [];
if (manifest && Array.isArray(manifest.pages)) {
  for (const page of manifest.pages) {
    if (!page.path || !fs.existsSync(page.path)) continue;
    const content = fs.readFileSync(page.path, 'utf8');
    const sections = (page.sections || [])
      .filter(section => section && (section.pinned === true || section.required !== false))
      .map(section => ({
        id: section.id,
        heading: section.heading,
        level: section.level,
        line: findHeading(content, section),
      }));
    if (sections.length > 0) {
      pinnedPages.push({
        page_id: page.id,
        path: page.path,
        sections,
      });
    }
  }
}

const protectedFiles = walkMarkdown('docs')
  .map(file => ({
    path: file,
    blocks: protectedBlocks(fs.readFileSync(file, 'utf8')),
  }))
  .filter(file => file.blocks.length > 0);

const snapshot = {
  version: 1,
  generated_at: new Date().toISOString(),
  manifest_path: fs.existsSync(manifestPath) ? manifestPath : null,
  pinned_pages: pinnedPages,
  protected_files: protectedFiles,
};

fs.mkdirSync(path.dirname(snapshotFile), { recursive: true });
fs.writeFileSync(snapshotFile, `${JSON.stringify(snapshot, null, 2)}\n`);
console.log(
  `[claudux:guard] wrote ${snapshotFile} (${pinnedPages.length} pinned pages, ${protectedFiles.length} protected files)`
);
NODE
}

validate_docs_structure_guard_snapshot() {
    local snapshot_file
    snapshot_file="${CLAUDUX_GUARD_SNAPSHOT_FILE:-${CLAUDUX_INDEX_DIR:-.claudux/index}/docs-guard-snapshot.json}"

    if [[ ! -f "$snapshot_file" ]]; then
        return 0
    fi

    require_node_for_manifest || return 1

    node - "$snapshot_file" <<'NODE'
const fs = require('fs');
const crypto = require('crypto');

const snapshotPath = process.argv[2];
const errors = [];

function fail(message) {
  errors.push(`docs guard: ${message}`);
}

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function findHeading(content, section) {
  const pattern = new RegExp(
    `^#{${section.level}}\\s+${escapeRegExp(section.heading)}(?:\\s+\\{#[^}]+\\})?\\s*$`,
    'm'
  );
  const match = pattern.exec(content);
  if (!match) return null;
  return content.slice(0, match.index).split(/\r?\n/).length;
}

function protectedBlocks(content) {
  const blocks = [];
  const marker = /<!--\s*skip\s*-->([\s\S]*?)<!--\s*\/skip\s*-->/g;
  let match;
  while ((match = marker.exec(content)) !== null) {
    blocks.push({ sha256: sha256(match[0]) });
  }
  return blocks;
}

let snapshot;
try {
  snapshot = JSON.parse(fs.readFileSync(snapshotPath, 'utf8'));
} catch (error) {
  fail(`invalid snapshot JSON (${error.message})`);
  snapshot = {};
}

for (const page of snapshot.pinned_pages || []) {
  if (!fs.existsSync(page.path)) {
    fail(`manifest page disappeared after generation (${page.path})`);
    continue;
  }
  const content = fs.readFileSync(page.path, 'utf8');
  let previousLine = 0;
  for (const section of page.sections || []) {
    if (section.line === null) continue;
    const currentLine = findHeading(content, section);
    if (currentLine === null) {
      fail(`${page.path}: pinned heading disappeared (${section.heading})`);
      continue;
    }
    if (currentLine < previousLine) {
      fail(`${page.path}: pinned heading order changed near "${section.heading}"`);
    }
    previousLine = currentLine;
  }
}

for (const file of snapshot.protected_files || []) {
  if (!fs.existsSync(file.path)) {
    fail(`protected file disappeared after generation (${file.path})`);
    continue;
  }
  const currentBlocks = protectedBlocks(fs.readFileSync(file.path, 'utf8'));
  if (currentBlocks.length < file.blocks.length) {
    fail(`${file.path}: protected skip block count decreased`);
    continue;
  }
  for (const [index, block] of (file.blocks || []).entries()) {
    if (!currentBlocks[index] || currentBlocks[index].sha256 !== block.sha256) {
      fail(`${file.path}: protected skip block ${index + 1} changed`);
    }
  }
}

if (errors.length > 0) {
  for (const error of errors) console.error(`[claudux:guard] ${error}`);
  process.exit(1);
}

console.log(
  `[claudux:guard] ok (${(snapshot.pinned_pages || []).length} pinned pages, ${(snapshot.protected_files || []).length} protected files)`
);
NODE
}

resolve_impacted_docs_from_changed_files() {
    local manifest
    manifest="$(docs_structure_path)"
    if [[ ! -f "$manifest" ]]; then
        return 0
    fi

    require_node_for_manifest || return 1

    node - "$manifest" <<'NODE'
const fs = require('fs');
const path = require('path');

const manifestPath = process.argv[2];
const allowlistPath = process.env.CLAUDUX_IMPACT_ALLOWLIST_FILE || '';
const changedFiles = (process.env.CLAUDUX_CHANGED_FILES || '')
  .split(/\r?\n/)
  .map(file => file.trim())
  .filter(Boolean);

function patternToRegExp(pattern) {
  const escaped = pattern
    .replace(/[.+^${}()|[\]\\]/g, '\\$&')
    .replace(/\*\*/g, '\u0000')
    .replace(/\*/g, '[^/]*')
    .replace(/\u0000/g, '.*');
  return new RegExp(`^${escaped}$`);
}

function matches(pattern, file) {
  if (pattern.endsWith('/**')) {
    return file.startsWith(pattern.slice(0, -3));
  }
  return patternToRegExp(pattern).test(file);
}

function defaultIndexPath() {
  if (process.env.CLAUDUX_STATIC_INDEX_FILE) return process.env.CLAUDUX_STATIC_INDEX_FILE;
  const indexDir = process.env.CLAUDUX_INDEX_DIR || '.claudux/index';
  return path.join(indexDir, 'static-analysis.json');
}

function dependencyExpandedFiles(seedFiles) {
  const expanded = new Set(seedFiles);
  const notes = [];
  const indexPath = defaultIndexPath();
  if (!fs.existsSync(indexPath)) {
    return { files: [...expanded].sort(), notes };
  }

  let index;
  try {
    index = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
  } catch {
    return { files: [...expanded].sort(), notes };
  }

  const edges = Array.isArray(index.dependency_edges) ? index.dependency_edges : [];
  let changed = true;
  while (changed) {
    changed = false;
    for (const edge of edges) {
      if (!edge || !edge.from || !edge.to) continue;
      if (expanded.has(edge.to) && !expanded.has(edge.from)) {
        expanded.add(edge.from);
        notes.push(`${edge.to} -> ${edge.from} [${edge.kind || 'dependency'}]`);
        changed = true;
      }
    }
  }

  return { files: [...expanded].sort(), notes: [...new Set(notes)].sort() };
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const hits = [];
const expanded = dependencyExpandedFiles(changedFiles);
const pages = [];
const sections = [];

for (const note of expanded.notes) {
  hits.push(`dependency-expanded scope: ${note}`);
}

for (const page of manifest.pages || []) {
  const pagePatterns = page.source_patterns || [];
  const pageHits = expanded.files.filter(file => pagePatterns.some(pattern => matches(pattern, file)));
  if (pageHits.length > 0) {
    pages.push({
      page_id: page.id,
      path: page.path,
      matched_files: pageHits,
    });
    hits.push(`${pageHits.join(', ')} -> ${page.id} (${page.path})`);
  }

  for (const section of page.sections || []) {
    const sectionPatterns = section.source_patterns || [];
    const sectionHits = expanded.files.filter(file => sectionPatterns.some(pattern => matches(pattern, file)));
    if (sectionHits.length > 0) {
      sections.push({
        page_id: page.id,
        section_id: section.id,
        path: page.path,
        heading: section.heading,
        pinned: section.pinned === true,
        matched_files: sectionHits,
      });
      hits.push(`${sectionHits.join(', ')} -> ${page.id}#${section.id} (${page.path})`);
    }
  }
}

if (allowlistPath) {
  const allowlist = {
    version: 1,
    generated_at: new Date().toISOString(),
    changed_files: changedFiles,
    expanded_files: expanded.files,
    dependency_notes: expanded.notes,
    pages,
    sections,
  };
  fs.mkdirSync(path.dirname(allowlistPath), { recursive: true });
  fs.writeFileSync(allowlistPath, `${JSON.stringify(allowlist, null, 2)}\n`);
}

for (const hit of [...new Set(hits)]) {
  console.log(hit);
}
NODE
}
