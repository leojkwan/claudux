# Deterministic Generation

Claudux treats documentation structure as source-owned state. The model can propose wording changes, but the repo owns the page tree, required sections, pinned headings, deletion policy, and source-to-doc mapping.

## Why Large Repos Need a Manifest

Large repos rarely fail because the model cannot write a page. They fail because the model rewrites the tree around whatever it noticed last. A checkout route changes and the docs tool edits a pricing page, drops an E2E harness section, or reorders navigation because the prompt called the structure a preference.

`docs-structure.json` turns structure into a checked-in contract:

- Page IDs and paths are stable.
- Navigation order is explicit.
- Source-owned pages declare the files that make them stale.
- Required sections declare the headings that must survive.
- Pinned sections are not deleted or reparented by a model-only run.
- Deletion policy is reviewed as a manifest diff, not inferred from prose.

The manifest is intentionally separate from `claudux.md`. `claudux.md` describes site taste. `docs-structure.json` is operational state. If a legacy `docs-map.md` also exists, claudux treats it as supplemental guidance; the manifest remains the binding authority.

## Pipeline

The deterministic pipeline is:

1. Validate `docs-structure.json` before generation.
2. Build `.claudux/index/static-analysis.json` from tracked source files, docs files, package scripts, markdown headings, and manifest ownership.
3. Capture a guard snapshot for pinned heading order, pinned/read-only section body hashes, and protected skip-marker blocks.
4. Add the static index summary to the model prompt as authoritative facts.
5. Use `.claudux-state.json` to find changed files since the previous run.
6. Resolve changed files through manifest `source_patterns` to the impacted page or section set and write `.claudux/index/impacted-docs.json`.
7. Ask the model for section patch JSON instead of direct documentation writes.
8. Apply patches only to manifest-owned generated sections inside the impacted allowlist during incremental runs.
9. Validate `docs-structure.json` again after generation.
10. Validate the pre-generation guard snapshot and internal links.
11. Rebuild the deterministic static index, impacted-doc allowlist, and guard snapshot against the final patched docs before saving the checkpoint.

## Section Patch Application

When `docs-structure.json` exists, claudux removes direct documentation write authority from the model. The backend must return one marker-delimited JSON payload, and claudux extracts, validates, and applies that payload locally.

The extracted payload is staged at `.claudux/index/section-patches.json` by default. `CLAUDUX_SECTION_PATCH_FILE` can relocate it for tests, harnesses, or alternate scratch layouts.

`format_section_patch_contract()` prints the manifest-derived allowlist of patchable `page_id#section_id` targets and the separate read-only list before backend invocation. The manifest is the addressing surface. A generated section can be source-owned and still writable; read-only status comes from `pinned: true` or `generated: false`.

### Extractor behavior

- The extractor scans raw output plus nested JSONL string fields named `text`, `content`, `result`, and `message`.
- Plain final responses and backend event streams use the same marker contract.
- Identical repeated payloads are deduplicated, including repeated marker pairs and echoed agent/result events.
- Conflicting repeated payloads, orphaned markers, end-before-start ordering, and invalid JSON fail the run.
- Fenced JSON is accepted, and a bare array is normalized to an object with a `patches` array.
- Turn-summary fields are ignored so truncated recap text cannot satisfy the contract.

### Patch application rules

- Every patch must resolve to one manifest page and one manifest section, and a batch cannot target the same section twice.
- `body_markdown` is the canonical body field. `markdown` and `content` remain compatibility aliases when reading older payloads.
- If the body repeats the section heading, claudux strips that heading before writing.
- A body can contain deeper subheadings and fenced examples, but same-level or higher headings outside fences are rejected.
- Missing on-disk headings fail unless `create_if_missing: true` is set.
- Pinned sections and `generated: false` sections require both `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` and per-patch `unlock_pinned: true`.
- Incremental runs enforce the impacted-doc allowlist; full scans can touch any non-pinned generated section in the manifest.
- Transient cache provenance is rejected from patch bodies. The prompt can use run-specific facts for scope, but committed prose must describe stable behavior.
- Patch validation and application are all-or-nothing. One invalid, duplicate, read-only, out-of-scope, provenance-leaking, or boundary-escaping patch prevents the target documentation files from changing. Later guard, link, cache, and checkpoint stages remain separate.

After patches land, `update()` runs post-generation manifest validation, validates the pre-generation guard snapshot, runs link validation, refreshes deterministic caches, and only then saves the checkpoint. If extraction or application fails, `retain_generation_debug_log()` keeps the backend JSONL log available for inspection while the docs tree stays untouched.

Patch mode constrains filesystem authority, not provider compatibility. Claude is limited to `Read`. Codex keeps `approval_policy` set to `never` and defaults to a read-only sandbox in section-patch mode unless `CODEX_SANDBOX_MODE` overrides it.

## Static Analysis Index

The static index is deterministic cache state written to `.claudux/index/static-analysis.json` by default. `CLAUDUX_INDEX_DIR` or `CLAUDUX_STATIC_INDEX_FILE` can relocate it, and prompt construction reads the resolved path.

`build_static_analysis_index()` rebuilds the index from tracked files on every deterministic run. Markdown under `docs/` is indexed as documentation. Tracked non-doc files outside `docs/`, `.claudux/`, and nested `node_modules/` paths are indexed as sources.

### Recorded facts

The index stores structured facts for deterministic scoping:

- Manifest path, manifest hash, page ownership, and section ownership metadata.
- Package scripts from `package.json`.
- CLI tokens parsed from Bash `case` labels in `bin/claudux`.
- Exported shell functions and tracked test files.
- Dependency edges from shell `source` and `.` statements, `REQUIRED_LIBS`, the conditional Codex adapter source, and repo-file references inside package scripts.
- Source and docs hashes plus markdown heading inventories.
- Internal markdown docs links.
- Protected skip-marker blocks with marker text, line spans, and hashes.
- Manifest page and section source ownership.

These are cache records, not documentation copy. The prompt can use them to scope a generation pass, but committed prose should avoid run-specific cache values.

### Prompt summary

`format_static_analysis_index_context()` projects the index into a compact authoritative prompt summary before model output. That summary tells the model which scripts, command tokens, tests, ownership mappings, and preservation rules are current for the run.

Manifest mode still requires bounded section patch JSON. The static index can narrow what the model should consider, but it does not grant direct write access and it does not override the manifest allowlist.

### Byte-stable caches

`static-analysis.json`, `docs-guard-snapshot.json`, and `impacted-docs.json` omit wall-clock timestamps and are written from reproducible inputs where the source graph permits it.

After section patches land and post-generation checks run, `update()` calls `refresh_deterministic_generation_caches()` before `save_claudux_state()`. That refresh rebuilds the static index against the final docs tree, recomputes the impact allowlist when the run has an incremental changed-file list, and captures a fresh guard snapshot.

### Boundary of the index

The static index is authoritative for source ownership, command existence, dependency expansion, prompt scoping, docs-link inventories, and protected-block inventories. It is not a provider compatibility check and it is not the VitePress route validator. Backend model availability is checked at runtime, and nav/sidebar targets are validated by `lib/validate-links.sh`.

## docs-structure.json Manifest

`docs-structure.json` is the default checked-in manifest, but claudux resolves the active manifest through `docs_structure_path()`. Advanced runs and tests can override the path with `CLAUDUX_DOCS_STRUCTURE` or `DOCS_STRUCTURE_FILE` without changing the repo default.

The manifest is the operational contract for docs structure. `claudux.md` can influence taste, but the manifest owns patch addresses, navigation targets, required headings, source ownership, and deletion authority. When both `docs-structure.json` and `docs-map.md` exist, prompt construction treats the manifest as primary and keeps the docs map as supplemental legacy guidance.

### Manifest schema rules

Preflight validation enforces the structural contract before any backend runs:

- Root `deletion_policy` must be `manifest_pages_require_manifest_change`.
- Root `generated_sections_default` must be `bounded_patch`.
- Each page `deletion_policy` must be `never_delete_without_manifest_change`.
- Page paths must be repo-relative markdown paths under `docs/`.
- Page IDs, page paths, page order values, navigation IDs, and navigation order values must be unique.
- Navigation titles must be non-empty, and navigation links must be root-relative docs links that resolve to manifest pages.
- Page IDs, section IDs, navigation IDs, and page `nav_group` values must match `[a-z0-9][a-z0-9._-]*`.
- Section IDs must be unique within a page, and a page cannot declare the same heading level plus heading text twice.
- `source_patterns` must be repo-root relative; absolute paths, drive prefixes, empty strings, non-string entries, and parent traversal are rejected before impact mapping.
- Authority fields such as `pinned`, `generated`, and `required` must be real JSON booleans.
- A section is required by default unless it explicitly sets `required: false`.
- `generated: false` marks a section read-only even when it is not pinned.

### Post-generation rules

Post-generation validation adds on-disk checks:

- Every manifest page must exist.
- Required headings must exist in their declared page.
- Manifest-declared heading anchors must not be duplicated on disk.
- The manifest must include pinned doctrine for the guard snapshot to preserve.

These rules keep structure changes reviewable as manifest diffs instead of letting a model invent patch keys, nav targets, order values, deletion behavior, or ambiguous section addresses from prose.

## Pinned Pages and Sections

Pinned is the write barrier. Required is the existence barrier.

During patch application:

- Ordinary generated sections can be rewritten when they are inside the current impact allowlist.
- Sections with `pinned: true` are read-only by default.
- Sections with `generated: false` are read-only by the same guard, even if they are not pinned.
- Section-level `source_patterns` affect incremental ownership and allowlist scope, but they do not make a section read-only.
- A generated section can be source-owned and still patchable.

During guard validation, claudux tracks every pinned section plus every section that is still required:

- Pinned and required headings must still exist on disk after generation.
- The captured sequence must stay in manifest order within the page.
- Only read-only section bodies are hash-locked; editable generated sections can change as long as they stay inside their declared boundary.
- `required: false` opts a non-pinned section out of the existence and order guard, but it does not make a `generated: false` section writable.
- Manifest-owned pages themselves must remain present on disk.

An intentional pinned rewrite needs two signals in the same run: `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` in the environment and `unlock_pinned: true` on the individual patch. That keeps model-only runs from silently editing doctrine.

Page deletion is separate from section editing. The `cleanup_docs_silent` hook called by `update` is a no-op, so the normal generation path does not run a hidden deletion pass. The legacy interactive `cleanup_docs` helper refuses manifest-owned deletion unless `CLAUDUX_ALLOW_MANIFEST_CLEANUP=1` is set and the manifest validates.

## Content Protection Markers

`lib/content-protection.sh` chooses literal marker pairs by file extension, and the deterministic helpers in `lib/docs-manifest.sh` mirror the same pairs when they index and guard protected blocks:

- Markdown, HTML, XML, and Vue use `<!-- skip -->` / `<!-- /skip -->`.
- JavaScript, TypeScript, Swift, Java, C-family, Rust, and Go use `// skip` / `// /skip`.
- Python, shell, Ruby, and Perl use `# skip` / `# /skip`.
- CSS-family files use `/* skip */` / `/* /skip */`.
- SQL uses `-- skip` / `-- /skip`.
- Unknown extensions fall back to the hash-comment form.

Matching is trimmed, line-based, and literal. Indented markers still count, and regex-looking markers such as the CSS pair are treated as exact text rather than patterns.

The deterministic path uses those boundaries in two enforced places:

- `build_static_analysis_index()` records protected blocks across tracked project files with marker text, line spans, and hashes.
- The guard snapshot captures recorded protected blocks and later rejects runs that remove a block or change a recorded block hash.

Protected-block preservation is not limited to markdown docs. Any tracked file with a recognized marker pair can participate in the guard, which keeps protected code snippets, fixture notes, and top-level project files stable during deterministic runs.

## Dependency-Aware Scope

Incremental mode starts from `claudux_diff_since_last()`. That function unions the committed diff from `last_sha..HEAD` with dirty documentation and configuration files reported by `claudux_docs_worktree_changes()`.

### Dirty docs and config files

Dirty freshness signals are limited to files that can affect generated documentation state before they are committed:

- `docs/`
- `docs-structure.json`
- `docs-map.md`
- `.ai-docs-style.md`
- `docs-site-plan.json`

For those pathspecs, claudux includes unstaged changes, staged changes, and untracked files. This closes the dogfood gap where a section patch updates tracked docs while `HEAD` still matches the saved checkpoint, so an incremental `update` still sees that dirty docs/config state as in-scope even when the checkpoint commit is otherwise current.

### Incremental allowlist

After the changed-file list is built, `resolve_impacted_docs_from_changed_files()` expands scope through manifest ownership and reverse dependency edges from the static index. The expansion is intentionally upstream: if a sourced library changes, the router that sources it is pulled into scope. That matters for pages that own the router directly but not every library it loads.

Dependency edges come from more than shell `source` statements:

- Shell-like files contribute `source` and `.` relationships.
- `bin/claudux` contributes explicit edges for files in `REQUIRED_LIBS` plus the conditional Codex adapter source.
- `package.json` scripts contribute edges when they reference repo files under `bin/`, `lib/`, `tests/`, or `scripts/`.

`resolve_impacted_docs_from_changed_files()` writes `.claudux/index/impacted-docs.json` by default, or the path from `CLAUDUX_IMPACT_ALLOWLIST_FILE`. The allowlist records the changed files, dependency-expanded files, dependency notes, impacted pages, and impacted sections. Patch mode then uses that file as the incremental write boundary:

- A section with its own `source_patterns` must be directly impacted to be patchable in an incremental run.
- A generated section without its own ownership can be patched when its page is impacted.
- Full scans skip the allowlist and can touch any non-pinned generated section in the manifest.

For incremental section-patch runs, `refresh_deterministic_generation_caches()` reruns impact resolution with the same changed-file list and allowlist path after patches and validation. The refreshed allowlist is cache state for the final run, not a stale pre-patch artifact.

## Validators

Validation is layered rather than one big pass. `claudux update` validates the manifest before model invocation, builds the static index, captures the guard snapshot before generation, and then applies model output only through the manifest section-patch contract. After patches land, it re-runs post-generation manifest checks, validates the pre-generation guard snapshot, runs link validation, refreshes deterministic caches, and only then saves the checkpoint.

The guard snapshot lives at `.claudux/index/docs-guard-snapshot.json` by default. `CLAUDUX_GUARD_SNAPSHOT_FILE` can relocate it for test harnesses or alternate scratch layouts.

### Manifest and guard validation

Manifest validation covers contract correctness:

- JSON shape, unique page IDs, unique page paths, unique deterministic order values, and `docs/*.md` page paths.
- Stable manifest keys for navigation IDs, page IDs, section IDs, and `nav_group`.
- Strict enums for deletion policy and generated-section defaults.
- Non-empty navigation titles, root-relative docs links, and navigation targets that resolve to manifest pages.
- Repo-root-relative `source_patterns` and real boolean values for `pinned`, `generated`, and `required`.
- Unique section IDs plus unambiguous heading-level and heading-text pairs within each page.
- Post-generation checks that manifest pages exist on disk, required headings still exist, and declared heading anchors are not duplicated on disk.
- Post-generation runs also require pinned doctrine so the guard snapshot has read-only content to preserve.

The guard snapshot enforces preservation rules that schema validation cannot prove:

- Captured pinned and required headings must stay in manifest order.
- Pinned or otherwise read-only section bodies must keep the same hash unless pinned unlock is explicitly enabled.
- Files that carried recorded protected blocks must still exist on disk.
- Recorded skip-marker blocks must keep at least the captured block count, and each captured block must keep the same content hash in order across docs and source files.

The update path does not perform semantic cleanup: its `cleanup_docs_silent` call is intentionally empty. The separate legacy `cleanup_docs` helper has its own manifest deletion guard, but that helper is not part of normal `claudux update` validation.

### VitePress proof

The checked-in VitePress config follows the project preferences:

- `base` is `process.env.DOCS_BASE || '/'`, `cleanUrls` is enabled, and the outline uses levels two and three with the label `On this page`.
- The top nav order is Guide, Features, Technical, and API, matching the manifest navigation order.
- The sidebar defines a root `/` entry so the sidebar appears on the homepage and provides the site-wide fallback.
- Section-specific sidebar entries exist for Guide, Features, and Technical.
- Current internal nav/sidebar targets resolve to checked-in docs pages: Guide, Installation, Commands, Configuration, Features, Generation Pipeline, Cleanup, Content Protection, Technical, Project Profiles, Deterministic Generation, Examples, API, and Troubleshooting.
- Social links are absolute GitHub and npm URLs.

`lib/validate-links.sh` proves config targets by extracting `link:` entries from the VitePress config, resolving `/` to `docs/index.md`, `/path/` to `docs/path/index.md`, and `/path` to `docs/path.md`. Before route checking it also rejects duplicate explicit markdown `{#id}` anchors. Hash fragments are stripped for file existence checks, so the validator proves route targets and explicit anchor uniqueness rather than arbitrary heading text.

### Link validation behavior

Link validation adds docs-site checks on top of the manifest contract:

- On the green path, `lib/validate-links.sh` prints a single successful internal-link message, then the shared UI layer adds its own success prefix.
- The failure path may re-run `lib/validate-links.sh --output <tmp>` to collect a machine-readable missing-file list for one auto-fix pass.
- `--strict` turns any remaining broken links into a hard error.
- `tests/run-tests.sh` includes the regression guard that the internal link-validation pass must not emit a doubled success prefix.

### Backend-aware verification boundary

Verification intentionally distinguishes between configuration echo, backend preflight, and true generation failure:

- `show_header` and `claudux check` report the active backend plus selected Codex settings, but they do not prove that the installed Codex CLI supports the selected model.
- Commands that invoke a model go through `check_generation_backend()`. On the Codex path, `check_codex()` must find the CLI and verify auth before generation starts.
- Modern Codex CLI builds use `codex login status` for a zero-token auth probe; older builds fall back to an exec probe.
- Manifest validation, static-index construction, and guard capture run before backend invocation. The legacy cleanup helper's deletion guard is a separate path and does not run during a normal update.
- If a backend or patch-mode run fails after launch, `update()` retains the raw JSONL log and prints backend-specific recovery steps instead of checkpointing a misleading success.

## Pinned Harness Example

A mature web app often has a local E2E harness whose rules are more specific than generic "run the tests" advice.

For example, a local database harness might define the allowed start, reset, and stop commands for migrations and auth testing. A wrapper script such as `scripts/run-local-harness.mjs` can start services when needed, optionally reset fixtures, forward harness arguments, generate ephemeral test credentials when missing, and stop only the stack it started.

The browser seed path is even more structure-sensitive. A fixture such as `e2e/fixtures/staging-seed.ts` should be idempotent: resolve or create the canonical user, insert only missing domain records, and refuse to seed production resources. A global setup file can treat missing env as an opted-out no-op while still propagating the production guard.

That doctrine should not be rewritten as generic testing prose. In the application repo itself, it needs source-owned sections:

- Local service lifecycle owned by `scripts/run-local-harness.mjs`.
- Idempotent seed semantics owned by `e2e/fixtures/staging-seed.ts`.
- Production guard semantics pinned as a required section.
- Browser setup behavior owned by `e2e/fixtures/global-setup.ts` and `playwright.config.ts`.

When those files change, the docs should update those sections. When unrelated UI files change, the harness doctrine should survive untouched.

Claudux's own `docs-structure.json` keeps this section pinned as doctrine, but it does not use cross-repo paths as `source_patterns`. External example files are evidence in prose, not worktree-relative incremental ownership keys.

## Checkpoint Contract

`.claudux-state.json` is the local freshness checkpoint that scopes each incremental `update`. It is developer-local, ignored by git, and separate from deterministic cache artifacts under `.claudux/index/`.

### Saved fields

A successful save writes:

- `last_sha`: the Git `HEAD` recorded at checkpoint time, or `unknown` outside a usable Git history.
- `last_run`: the wall-clock timestamp for the successful save.
- `backend`: the active backend, such as `claude` or `codex`.
- `files_documented`: tracked docs files present at save time.
- `deterministic`: metadata derived from the static analysis index.

The nested deterministic block includes:

- `prompt_version`.
- Index path, index version, and index head metadata.
- The manifest hash.
- Source hashes for tracked non-doc files.
- Section hashes for manifest sections currently found on disk.
- Source-to-section coverage built from page and section `source_patterns`.

That nested block is intentionally best-effort. If Node is unavailable or the static index cannot be read, `build_deterministic_state_metadata_json()` returns a fallback object with nullable index and manifest metadata plus empty coverage arrays, so a successful docs run can still checkpoint freshness instead of failing after docs already updated.

The checkpoint records the backend but not the selected model or reasoning effort. A run can retry with different model settings while the persisted freshness state still answers the narrower question of which backend produced the docs.

Failed runs do not advance the checkpoint. `save_claudux_state()` only runs on the success path after generation, patch application, post-generation validation, link-validation handling, deterministic cache refresh, and change analysis. Backend rejection, section-patch extraction failure, strict link-validation failure, or cache-refresh failure keeps the previous checkpoint intact.

### Incremental change detection

`claudux_diff_since_last()` compares `last_sha..HEAD`, then unions in uncommitted documentation/config changes under `docs/`, `docs-structure.json`, `docs-map.md`, `.ai-docs-style.md`, and `docs-site-plan.json`. That dirty-doc scan includes unstaged changes, staged changes, and untracked files for those pathspecs, and its result becomes the changed-file list an incremental `update` resolves through manifest ownership.

This makes the freshness model two-dimensional:

- Source commits after the saved commit mean the docs may be stale relative to code history.
- Dirty docs/config files mean the worktree may contain generated or structural documentation changes that have not been committed or re-checkpointed.

`tests/test-diff-calculation.sh` covers dirty tracked docs, staged docs, and untracked docs.

The split is intentional: `last_run` is wall-clock state, while deterministic metadata and deterministic cache files should stay stable when repo inputs and manifest ownership have not changed.
