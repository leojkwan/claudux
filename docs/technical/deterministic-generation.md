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
10. Validate the guard snapshot, internal links, and save the checkpoint.

## Section Patch Application

When `docs-structure.json` exists, claudux removes direct `docs/**` write authority from the model. The model returns a single marker-delimited JSON payload, and claudux extracts, validates, and applies it locally.

The extractor is intentionally strict:
- It scans raw output plus nested JSONL string fields named `text`, `content`, `result`, and `message`.
- Identical repeated payloads are deduplicated, which covers echoed Claude or Codex output.
- Conflicting repeated payloads, orphaned markers, end-before-start ordering, and invalid JSON fail the run.
- Fenced JSON is accepted, and a bare array is normalized to an object with a `patches` array.
- Turn-summary fields such as `summary` are ignored, so truncated recap text cannot satisfy the contract.

Patch application is bounded and transactional:
- Every patch must resolve to one manifest `page_id` plus `section_id`, and a batch cannot target the same section twice.
- `body_markdown` can contain deeper subheadings and code fences, but same-level or higher headings outside fences are rejected.
- Missing on-disk headings fail unless `create_if_missing: true` is set on that patch.
- Pinned sections and sections with `generated: false` stay read-only unless both `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` and `unlock_pinned: true` are present.
- Incremental runs enforce `.claudux/index/impacted-docs.json`; full scans can touch any non-pinned generated section in the manifest.
- Validation is all-or-nothing. One invalid or out-of-scope patch leaves every file unchanged.

Backend controls stay explicit in patch mode: Claude is limited to `Read`, and Codex keeps `approval_policy="never"` while defaulting to a read-only sandbox unless `CODEX_SANDBOX_MODE` overrides it.

## Static Analysis Index

The static index is deterministic cache state under `.claudux/index/static-analysis.json`, not hand-maintained documentation. `build_static_analysis_index()` rebuilds it from `git ls-files -z`: tracked `docs/**/*.md` files become the docs inventory, and tracked non-doc project files outside `.claudux/` and `node_modules/` become the source inventory.

Each run records stable facts rather than prose:
- `head_sha`.
- Manifest path, digest, page count, and source-owned page count when `docs-structure.json` exists.
- Hashes for tracked source files, plus hashes and heading inventories for tracked docs pages.
- `package.json` scripts, CLI commands parsed from `bin/claudux`, exported shell functions, tracked test file hashes, dependency edges, internal docs links, protected skip blocks, and page/section source ownership.
- For claudux itself, the current script inventory is `lint`, `test`, `test:all`, and `test:ci`.
- For claudux itself, the current CLI command inventory extracted from `bin/claudux` is `--check`, `--help`, `--version`, `-V`, `-h`, `check`, `dev`, `diff`, `help`, `recreate`, `serve`, `server`, `status`, `template`, `update`, `validate`, and `version`.

The model does not receive the full JSON blob. `format_static_analysis_index_context()` projects it into a compact prompt summary with counts, command lists, source-owned page mappings, and the manifest preservation rule before any model output is accepted.

The cache is intentionally reproducible. `static-analysis.json`, `docs-guard-snapshot.json`, and `impacted-docs.json` omit wall-clock timestamps, so identical repo state produces byte-stable deterministic artifacts.

## docs-structure.json Manifest

`docs-structure.json` is the operational contract for docs structure. `claudux.md` can influence taste, but the manifest owns patch addresses, navigation targets, required headings, source ownership, and deletion authority. When both `docs-structure.json` and `docs-map.md` exist, `build_generation_prompt()` treats the manifest as primary and keeps `docs-map.md` as supplemental legacy guidance only.

Key semantics are enforced mechanically:
- Root `deletion_policy` must be `manifest_pages_require_manifest_change`.
- Root `generated_sections_default` must be `bounded_patch`.
- Each page `deletion_policy` must be `never_delete_without_manifest_change`.
- Each page path must be a repo-relative markdown path under `docs/`, and page IDs, page paths, and page `order` values must be unique.
- Navigation links must be root-relative docs links that resolve to manifest pages; blank titles, placeholder links, and external URLs fail validation.
- Page `id`, section `id`, navigation `id`, and page `nav_group` values must match the stable manifest-key pattern `[a-z0-9][a-z0-9._-]*`.
- Section IDs must be unique within a page, and a page cannot declare the same `level + heading` pair twice.
- `source_patterns` must be repo-root relative; absolute paths, Windows drive prefixes, and `..` traversal are rejected before impact mapping.
- Authority fields such as `pinned`, `generated`, and `required` must be real JSON booleans, not strings.
- A section is required by default unless it explicitly sets `required: false`.
- `generated: false` marks a section read-only even when it is not pinned.

Those rules keep structure changes reviewable as manifest diffs instead of letting a model invent new patch keys, nav targets, deletion behavior, or ambiguous section addresses from prose.

## Pinned Pages and Sections

Pinned is the write barrier. Required is the existence barrier.

During patch application:
- Ordinary generated sections can be rewritten when they are inside the current impact allowlist.
- Sections with `pinned: true` are read-only by default.
- Sections with `generated: false` are read-only by the same guard, even if they are not pinned.

During guard validation, claudux tracks every pinned section plus every section that is still required:
- Pinned and required headings must still exist on disk after generation.
- That captured sequence must stay in manifest order within the page.
- Only read-only section bodies are hash-locked; editable generated sections can change as long as they stay within their declared boundary.
- `required: false` opts a non-pinned section out of the existence and order guard, but it does not make a `generated: false` section writable.
- Manifest-owned pages themselves must remain present on disk.

An intentional pinned rewrite needs two signals in the same run: `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` in the environment and `unlock_pinned: true` on the individual patch. That keeps a model-only run from silently editing doctrine.

Page deletion is guarded separately from section editing. With a manifest present, the internal cleanup helper in `lib/cleanup.sh` refuses manifest-owned deletion unless `CLAUDUX_ALLOW_MANIFEST_CLEANUP=1` is set, and `claudux recreate` refuses the same deletion unless `CLAUDUX_ALLOW_MANIFEST_RECREATE=1` is set. The current public CLI exposes `recreate`, not a standalone `cleanup` subcommand.

## Content Protection Markers

`lib/content-protection.sh` chooses literal marker pairs by file extension, and the deterministic helpers mirror the same pairs when they hash protected blocks:

- Markdown, HTML, XML, and Vue use `<!-- skip -->` / `<!-- /skip -->`.
- JavaScript, TypeScript, Swift, Java, C-family, Rust, and Go use `// skip` / `// /skip`.
- Python, shell, Ruby, and Perl use `# skip` / `# /skip`.
- CSS-family files use `/* skip */` / `/* /skip */`.
- SQL uses `-- skip` / `-- /skip`.
- Unknown extensions fall back to the hash-comment form.

Matching is trimmed, line-based, and literal. That means indented markers still count, and regex-looking markers such as `/* skip */` are handled as exact text rather than patterns.

The same boundaries drive three separate behaviors:

- `strip_protected_content` removes protected blocks before prompt construction.
- `build_static_analysis_index` records protected blocks across tracked project files with markers, line numbers, and hashes.
- The guard snapshot re-validates both block count and block hashes after generation.

Protected-block preservation is not limited to markdown docs. Any tracked file with a recognized marker pair can participate in the guard, which is why protected code snippets in `src/`, `tests/`, or top-level project files survive deterministic runs unchanged.

## Dependency-Aware Scope

Incremental mode starts from the changed-file set derived from `.claudux-state.json`, then resolves that set through manifest ownership and reverse dependency edges from the static index. The expansion is intentionally upstream: if `lib/ui.sh` changes, `bin/claudux` is pulled into scope because the router sources that library. That matters for pages like `home.index`, which own `bin/claudux` but do not own `lib/ui.sh` directly. Pages such as `api.index` may also move into scope on the same change, but there the direct `lib/*.sh` page ownership already matches before the reverse edge is even considered.

Dependency edges come from more than shell `source` statements:
- Shell-like files contribute `source` and `.` relationships.
- `bin/claudux` contributes explicit edges for every file in `REQUIRED_LIBS`, plus the conditional `lib/codex-utils.sh` source.
- `package.json` scripts contribute edges when they reference repo files under `bin/`, `lib/`, `tests/`, or `scripts/`.

`resolve_impacted_docs_from_changed_files()` writes `.claudux/index/impacted-docs.json` with `changed_files`, `expanded_files`, `dependency_notes`, `pages`, and `sections`. Patch mode then uses that file as the incremental allowlist:
- A section with its own `source_patterns` must be directly impacted to be patchable in an incremental run.
- A generated section without its own ownership can be patched when its page is impacted.
- Full scans skip the allowlist and can touch any non-pinned generated section in the manifest.

That keeps unrelated docs stable on larger repos while still letting structure-adjacent changes widen scope when the code graph, not just the changed-file list, says they should.

## Validators

Validation is layered rather than one big pass. `claudux update` validates the manifest before model invocation, then re-runs post-generation manifest checks, guard checks, and link validation after patches land. `claudux validate` follows the public verification path through `lib/ui.sh`: manifest first, links second. The success path does not run link validation twice, and the final banner keeps the check mark owned by the shared `success()` wrapper.

Manifest validation covers contract correctness:
- JSON shape, unique page IDs, unique page paths, unique deterministic order values, and `docs/*.md` page paths.
- Stable manifest keys for navigation IDs, page IDs, section IDs, and `nav_group`.
- Strict enums for deletion-policy and generated-section defaults.
- Non-empty navigation titles, root-relative docs links, and navigation targets that resolve to manifest pages.
- Repo-root-relative `source_patterns` and real boolean values for `pinned`, `generated`, and `required`.
- Unique section IDs plus unambiguous `level + heading` anchors within each page.
- Post-generation checks that manifest pages exist on disk, required headings still exist, and declared heading anchors are not duplicated on disk.
- Post-generation runs also require at least one pinned section so the guard snapshot has doctrine to preserve.

Link validation adds two docs-site checks:
- `lib/validate-links.sh` first runs `check_duplicate_ids()` across explicit markdown `{#id}` anchors.
- It then resolves VitePress nav and sidebar links against `docs/index.md`, `docs/<path>/index.md`, or `docs/<path>.md` and reports any missing targets.
- On the all-green path, `lib/validate-links.sh` prints `✅ All internal links validated successfully!`, then `lib/ui.sh` calls `success "All links are valid!"`. Because `success()` prefixes its own `✅`, the wrapper banner renders with a single check mark.

The guard snapshot enforces preservation rules that schema validation cannot prove:
- Captured pinned and required headings must stay in manifest order.
- Pinned or otherwise read-only section bodies must keep the same hash unless pinned unlock is explicitly enabled.
- Existing skip-marker blocks must keep the same count and content hash across docs and source files.

Deletion safeguards are validated by policy too. When `docs-structure.json` exists, the internal cleanup helper in `lib/cleanup.sh` refuses manifest-owned deletion unless `CLAUDUX_ALLOW_MANIFEST_CLEANUP=1` is set, and `claudux recreate` refuses the same deletion unless `CLAUDUX_ALLOW_MANIFEST_RECREATE=1` is set.

## StrongYes Harness Example

StrongYes has a local Supabase E2E harness that shows why pinned doctrine matters.

The local loop in `CLAUDE.md` points agents at `npm run db:start`, `npm run db:reset`, and `npm run db:stop` for migrations and auth testing. `scripts/run-local-supabase-test.mjs` wraps that loop by starting Supabase when needed, optionally resetting migrations, forwarding harness arguments, generating an ephemeral `E2E_TEST_USER_PASSWORD` when missing, and stopping the stack if it started it.

The Playwright seed path is even more structure-sensitive. `e2e/fixtures/staging-seed.ts` is idempotent: it resolves or creates the canonical user, inserts only missing game-plan cards, inserts only missing memories, and refuses to seed the production Supabase ref. `e2e/fixtures/global-setup.ts` treats missing env as an opted-out no-op but propagates the production guard.

That doctrine should not be rewritten as generic "run your tests" content. In the StrongYes repo itself, it needs source-owned sections:

- Local Supabase lifecycle owned by `scripts/run-local-supabase-test.mjs`.
- Idempotent seed semantics owned by `e2e/fixtures/staging-seed.ts`.
- Production guard semantics pinned as a required section.
- Playwright setup behavior owned by `e2e/fixtures/global-setup.ts` and `playwright.config.ts`.

When those files change, the docs should update those sections. When unrelated UI files change, the harness doctrine should survive untouched.

Claudux's own `docs-structure.json` keeps this section pinned as doctrine, but it does not use `../strongyes-web/...` as `source_patterns`. Cross-repo example files are evidence in prose, not worktree-relative incremental ownership keys.

## Checkpoint Contract

`.claudux-state.json` is the local freshness checkpoint that powers `claudux diff` and `claudux status`. It is developer-local, ignored by git, and separate from the deterministic cache artifacts under `.claudux/index/`.

A successful save writes:
- `last_sha`: the Git `HEAD` recorded at checkpoint time.
- `last_run`: the wall-clock timestamp for that successful save.
- `backend`: the active backend, such as `claude` or `codex`.
- `files_documented`: the tracked `docs/` files present at save time.
- `deterministic`: metadata derived from the static analysis index.

The nested deterministic block includes:
- `prompt_version`.
- `index.path`, `index.version`, and `index.head_sha`.
- `manifest_hash`.
- `source_hashes` for tracked non-doc files.
- `doc_section_hashes` for manifest sections currently found on disk.
- `source_to_section_coverage` built from page and section `source_patterns`.

`claudux diff` compares `last_sha..HEAD`, and `claudux status` uses the same checkpoint to report generation time, backend, documented-file count, and how many commits behind HEAD the docs are when the saved SHA still exists.

The split is intentional: `last_run` is wall-clock state, while the nested deterministic metadata should stay stable when the repo inputs and manifest ownership have not changed.
