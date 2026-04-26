#!/bin/bash
# Deterministic docs manifest and static index helpers

DOCS_STRUCTURE_FILE="${DOCS_STRUCTURE_FILE:-docs-structure.json}"
CLAUDUX_INDEX_DIR="${CLAUDUX_INDEX_DIR:-.claudux/index}"
CLAUDUX_STATIC_INDEX_FILE="${CLAUDUX_STATIC_INDEX_FILE:-$CLAUDUX_INDEX_DIR/static-analysis.json}"
CLAUDUX_GUARD_SNAPSHOT_FILE="${CLAUDUX_GUARD_SNAPSHOT_FILE:-$CLAUDUX_INDEX_DIR/docs-guard-snapshot.json}"

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

const files = trackedFiles();
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
  source_files: sourceFiles.map(file => ({
    path: file,
    sha256: sha256File(file),
  })),
  docs_files: docsFiles.map(file => ({
    path: file,
    sha256: sha256File(file),
    headings: headingsFor(file),
  })),
  source_ownership: manifest && Array.isArray(manifest.pages)
    ? manifest.pages.map(page => ({
        page_id: page.id,
        path: page.path,
        source_patterns: page.source_patterns || [],
        sections: (page.sections || []).map(section => ({
          section_id: section.id,
          heading: section.heading,
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

const manifestPath = process.argv[2];
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

const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const hits = [];

for (const page of manifest.pages || []) {
  const pagePatterns = page.source_patterns || [];
  const pageHits = changedFiles.filter(file => pagePatterns.some(pattern => matches(pattern, file)));
  if (pageHits.length > 0) {
    hits.push(`${pageHits.join(', ')} -> ${page.id} (${page.path})`);
  }

  for (const section of page.sections || []) {
    const sectionPatterns = section.source_patterns || [];
    const sectionHits = changedFiles.filter(file => sectionPatterns.some(pattern => matches(pattern, file)));
    if (sectionHits.length > 0) {
      hits.push(`${sectionHits.join(', ')} -> ${page.id}#${section.id} (${page.path})`);
    }
  }
}

for (const hit of [...new Set(hits)]) {
  console.log(hit);
}
NODE
}
