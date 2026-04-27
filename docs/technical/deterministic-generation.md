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

When `docs-structure.json` exists, claudux stops giving the model direct `docs/**` write authority. The model returns one marker-delimited JSON payload, and claudux validates and applies the patch locally.

The extractor is backend-agnostic and defensive:

- It scans raw text plus nested JSONL string fields such as `text`, `content`, `result`, and `message`.
- Repeated identical payloads are deduplicated, which covers echoed Claude and Codex output.
- Orphaned markers, end-before-start ordering, conflicting repeated payloads, and invalid JSON fail the run.
- Fenced JSON is accepted, and a bare array is normalized to an object with a `patches` field.
- Truncated summary previews are ignored unless they contain a complete marker pair.

Patch application is bounded the same way:

- Every target must resolve to a manifest `page_id` plus `section_id`, and a batch cannot hit the same section twice.
- `body_markdown` may contain code fences and deeper subheadings, but same-or-higher-level headings outside code fences are rejected so content cannot escape its section.
- Incremental runs enforce `.claudux/index/impacted-docs.json`; full scans can touch any non-pinned generated section in the manifest.
- If the on-disk heading is missing, the patch fails unless `create_if_missing: true` is set.
- Validation is all-or-nothing. One invalid or out-of-scope patch leaves every file unchanged.

Backend-specific execution is still explicit: Claude is restricted to the `Read` tool in patch mode, and Codex keeps `approval_policy` set to never while defaulting to a read-only sandbox unless `CODEX_SANDBOX_MODE` overrides it.

## Static Analysis Index

The static index is deterministic cache state, not documentation. Claudux builds it from `git ls-files -z`: tracked `docs/**/*.md` files become the docs inventory, and tracked non-doc project files outside `.claudux/` and `node_modules/` become the source inventory.

Each run writes a stable fact table with:

- `head_sha`.
- Manifest path, digest, page count, and source-owned page count when `docs-structure.json` exists.
- Hashes for tracked non-doc files.
- Hashes plus heading inventories for tracked `docs/*.md` files.
- `package.json` scripts.
- CLI commands parsed from `bin/claudux`.
- Exported shell functions from shell-like files.
- Test file hashes.
- Dependency edges from shell `source` / `.` statements plus package scripts that reference repo files.
- Internal docs links resolved to `docs/*.md`.
- Protected content blocks with marker pairs, line spans, and hashes.
- Page-level and section-level manifest ownership.

The model does not receive the whole JSON blob verbatim. `format_static_analysis_index_context()` projects it into a compact prompt summary with counts, command lists, and source-owned page mappings before any model output is accepted.

The cache is intentionally byte-stable for identical inputs. `static-analysis.json`, `docs-guard-snapshot.json`, and `impacted-docs.json` omit wall-clock timestamps, so identical repo state produces identical deterministic artifacts.

## docs-structure.json Manifest

`docs-structure.json` is the operational contract for docs structure. `claudux.md` can influence taste, but the manifest owns patch addresses, navigation targets, required headings, and deletion authority.

Key semantics are mechanical, not advisory:

- Root `deletion_policy` must be `manifest_pages_require_manifest_change`.
- Root `generated_sections_default` must be `bounded_patch`.
- Each page `deletion_policy` must be `never_delete_without_manifest_change`.
- Navigation links must be root-relative docs links that resolve to manifest-declared pages.
- `source_patterns` must be repo-root relative; absolute paths, Windows drive prefixes, and `..` traversal are rejected before impact mapping.
- Section IDs and page IDs are stable patch keys, not display copy.
- A section is treated as required unless it explicitly sets `required: false`.
- `generated: false` makes a section read-only even when it is not pinned.

That default-required behavior matters. Post-generation validation assumes manifest headings are structural contract by default; opting a section out is an explicit `required: false` choice, not the absence of a field.

The same rule keeps cross-repo examples honest. Claudux can describe another repo in prose, but manifest ownership cannot point outside the current worktree.

## Pinned Pages and Sections

Pinned is the write barrier. Required is the existence barrier.

During patch application:

- Ordinary generated sections can be rewritten when they are inside the current impact allowlist.
- Sections with `pinned: true` are read-only by default.
- Sections with `generated: false` are read-only by the same guard, even if they are not pinned.

During guard validation, claudux tracks a slightly wider set:

- Pinned and required headings must still exist on disk after generation.
- Pinned headings must stay in manifest order within the page.
- Only read-only section bodies are hash-locked; editable generated sections can change as long as they stay within their declared boundary.
- Manifest-owned pages themselves must remain present on disk.

An intentional pinned rewrite needs two signals in the same run: `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` in the environment and `unlock_pinned: true` on the individual patch. That keeps a model-only run from silently editing doctrine.

Page deletion is guarded separately from section editing. When a manifest exists, `claudux cleanup` requires `CLAUDUX_ALLOW_MANIFEST_CLEANUP=1`, and `claudux recreate` requires `CLAUDUX_ALLOW_MANIFEST_RECREATE=1`, before either path can remove manifest-owned docs.

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

Filename-only incremental mode is too coarse. `lib/docs-manifest.sh` resolves changed files through `source_patterns` so claudux can name the page or section likely to be stale. It also expands the changed set through reverse dependency edges from the static index.

Example:

```text
lib/docs-generation.sh -> technical.deterministic-generation (docs/technical/deterministic-generation.md)
lib/docs-generation.sh -> technical.deterministic-generation#pipeline (docs/technical/deterministic-generation.md)
lib/ui.sh -> bin/claudux [shell-source]
bin/claudux -> api.index (docs/api/index.md)
```

The model still sees the changed file list, but it also gets the manifest-owned impact set. Claudux also writes that impact set to `.claudux/index/impacted-docs.json` and uses it as a patch allowlist. Sections with their own `source_patterns` must be directly impacted; sections without their own ownership can be patched when their page is impacted.

That distinction matters on large codebases where one source file has known dependents and hundreds of unrelated docs should stay untouched.

## Validators

Manifest validation has two modes:

- Preflight validates JSON shape, unique page IDs, relative `docs/*.md` paths, deterministic navigation/page order values, deletion policy, non-empty source ownership patterns, section IDs, and unambiguous section `level + heading` anchors.
- Navigation links must be root-relative docs links and must resolve to manifest pages, so placeholder or external nav targets fail before a model can treat them as structure.
- Navigation IDs, page IDs, section IDs, and page `nav_group` values must be stable manifest keys because patch batches and incremental allowlists address sections as `page_id#section_id`.
- Manifest policy fields are strict enums. Unknown deletion policies or generated-section defaults fail before cleanup, recreate, or generation can treat them as operational authority.
- Manifest `source_patterns` must be repo-root relative. Absolute paths and `..` traversal are rejected so incremental scope does not depend on where a worktree is checked out.
- Section authority fields such as `pinned`, `generated`, and `required` must be JSON booleans, not strings. A typo like `"pinned": "true"` cannot silently disable pinned-section guards.
- Post-generation also verifies every manifest page exists, every required or pinned heading still appears on disk, and every manifest section heading appears at most once at its declared level.

The guard snapshot adds the preservation check that schema validation cannot prove by itself:

- Pinned headings must remain in manifest order within their page.
- Pinned/read-only section bodies must keep the same hash unless `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` is set for an intentional human override.
- Existing skip-marker blocks must keep the same content hash, including language-specific blocks in source-owned files.
- A model can still improve generated prose, but it cannot erase hand-written doctrine behind skip markers and pass validation.

`claudux validate` runs manifest validation before link validation. `claudux update` runs it before model invocation and again after model writes.

Deletion paths are guarded too. When `docs-structure.json` exists, `claudux cleanup` refuses to grant AI deletion authority by default, and `claudux recreate` refuses to remove `docs/` by default. Both operations require an explicit environment override because deleting a manifest-owned page is a manifest change, not a model inference.

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

`.claudux-state.json` is the local freshness checkpoint that powers `claudux diff` and `claudux status`. It stays developer-local and is not a source of truth for repo structure.

A successful save writes:

- `last_sha`: the Git `HEAD` at the time of the run.
- `last_run`: the wall-clock timestamp for that successful checkpoint.
- `backend`: the active backend, such as `claude` or `codex`.
- `files_documented`: the tracked `docs/` files present when the checkpoint was saved.
- `deterministic`: a derived metadata block built from the static analysis index.

That `deterministic` block includes:

- `prompt_version`.
- `index.path`, `index.version`, and `index.head_sha`.
- `manifest_hash`.
- `source_hashes` for tracked non-doc files.
- `doc_section_hashes` for manifest sections currently found on disk.
- `source_to_section_coverage` built from page and section `source_patterns`.

The checkpoint deliberately separates wall-clock state from deterministic repo facts. `last_run` changes every successful save; the nested deterministic metadata should stay stable when the repo inputs and manifest ownership have not changed.
