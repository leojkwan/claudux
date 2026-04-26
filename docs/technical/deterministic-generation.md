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

When `docs-structure.json` exists, claudux switches generation into section patch mode and asks the model for marker-delimited JSON instead of direct file edits.

The extractor and patcher are stricter than the prompt contract alone:

- Claudux requires exactly one unique payload. Repeated identical marker-delimited payloads are deduplicated, which covers duplicated JSONL echoes; conflicting payloads fail.
- Start and end markers must be paired and ordered. Orphaned markers fail fast, and truncated summary previews are ignored unless they form a complete marker pair.
- JSON may be wrapped in a fenced code block, and a bare array is normalized to `{ "patches": [...] }`.
- Every patch target must resolve to a manifest `page_id` and `section_id`, and a batch cannot target the same section twice.
- `body_markdown` is normalized by stripping a repeated copy of the section heading when present.
- Same-or-higher-level headings outside code fences are rejected so a patch cannot escape its section boundary.
- Incremental runs enforce `.claudux/index/impacted-docs.json`; full scans allow the wider set of manifest-generated sections.
- Pinned or `generated: false` sections are read-only unless both `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` and `unlock_pinned: true` are set.
- The whole batch validates before any write. One invalid patch leaves every file unchanged.

A normal successful run then replaces only the body between the manifest heading and the next same-or-higher-level heading. If a manifest-listed heading is missing on disk, the patcher fails unless the patch explicitly opts into `create_if_missing: true`.

Tooling is backend-specific but still bounded. Claude gets only the `Read` tool in patch mode. Codex keeps `approval_policy="never"` and defaults to a read-only sandbox in patch mode, although `CODEX_SANDBOX_MODE` can still override the sandbox selection.

## Static Analysis Index

The static index is local cache state, not generated documentation. It lives under `.claudux/index/` and is ignored by git.

Each run writes a deterministic fact table with:

- `head_sha`.
- Manifest digest and page/source-owned counts when `docs-structure.json` exists.
- Hashes for tracked source files.
- Hashes and heading inventories for tracked `docs/*.md` files.
- `package.json` scripts.
- CLI command aliases parsed from `bin/claudux`.
- Exported shell functions from shell-like source files.
- Test file hashes.
- Dependency edges from shell `source` / `.` statements plus package scripts that reference repo files.
- Internal docs links resolved to `docs/*.md`.
- Protected content blocks with marker pair, line span, and body hash.
- Manifest source ownership at both page and section granularity.

That index is what lets the prompt start from repository facts instead of a fresh heuristic scan. The same artifact also powers reverse dependency expansion for incremental scope and gives the deterministic checkpoint enough structured coverage data to explain why a section was considered in scope.

The deterministic cache deliberately omits wall-clock `generated_at` fields. Runtime belongs in `.claudux-state.json`; the static index, guard snapshot, and impacted-docs allowlist are expected to be byte-stable when inputs are unchanged.

## docs-structure.json Manifest

The manifest owns structure with fields that are easy to review:

```json
{
  "version": 1,
  "deletion_policy": "manifest_pages_require_manifest_change",
  "generated_sections_default": "bounded_patch",
  "navigation": [
    { "id": "technical", "title": "Technical", "link": "/technical/", "order": 3 }
  ],
  "pages": [
    {
      "id": "technical.deterministic-generation",
      "path": "docs/technical/deterministic-generation.md",
      "title": "Deterministic Generation",
      "nav_group": "technical",
      "order": 110,
      "deletion_policy": "never_delete_without_manifest_change",
      "source_patterns": ["lib/docs-generation.sh", "lib/docs-manifest.sh"],
      "sections": [
        {
          "id": "pipeline",
          "heading": "Pipeline",
          "level": 2,
          "pinned": true
        }
      ]
    }
  ]
}
```

The model may recommend a manifest change in its plan. Claudux must apply that as a normal file diff before treating the new structure as valid.

Policy fields are enums, not free-form prose. The root `deletion_policy` must be `manifest_pages_require_manifest_change`, the root `generated_sections_default` must be `bounded_patch`, and each page `deletion_policy` must be `never_delete_without_manifest_change`.

Navigation fields are manifest-owned too. Each navigation item needs a non-empty `title`, a root-relative `link`, and that link must resolve to a page path declared in the same manifest.

Manifest IDs are API keys, not display copy. Navigation IDs, page IDs, section IDs, and page `nav_group` values must use stable key syntax such as `technical.deterministic-generation` or `section-patch-application`; whitespace, slashes, and `#` delimiters are rejected before patching or impacted-doc allowlists depend on them.

## Pinned Pages and Sections

In the current implementation, pinned is a write barrier, not just a navigation hint.

During patch application:

- Ordinary generated sections can be rewritten in place when they are inside the current impact allowlist.
- Sections with `pinned: true` are read-only by default.
- Sections with `generated: false` are treated as read-only by the same guard, even if they are not marked pinned.

During post-generation validation, claudux also rechecks that:

- Pinned headings still exist.
- Pinned headings stay in manifest order within the page.
- Read-only section bodies keep the same hash unless `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` is set.
- Manifest-owned pages are still present on disk.

That means pinned doctrine does not silently drift during a normal `claudux update`. To intentionally rewrite a pinned section in one run, the human must set `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` and the patch must set `unlock_pinned: true`. To intentionally move or rename a section, the manifest must change first.

This is separate from skip markers. Skip markers protect literal content blocks inside files. Pinned and read-only manifest sections protect the structure and guarded bodies of the documentation itself. Cleanup and recreate guards extend the same policy to page deletion: manifest-owned pages are not removed unless the human opts into the explicit manifest cleanup or recreate overrides.

## Content Protection Markers

`lib/content-protection.sh` defines extension-based marker families, and the manifest helpers mirror the same literal pairs when they hash protected blocks:

- Markdown, HTML, XML, and Vue use `<!-- skip -->` / `<!-- /skip -->`.
- JavaScript, TypeScript, Swift, Java, C-family, Rust, and Go use `// skip` / `// /skip`.
- Python, shell, Ruby, and Perl use `# skip` / `# /skip`.
- CSS-family files use `/* skip */` / `/* /skip */`.
- SQL uses `-- skip` / `-- /skip`.
- Unknown extensions fall back to the hash-comment form.

Matching is trimmed, line-based, and literal. Claudux does not treat these markers as regex patterns, which is why CSS markers such as `/* skip */` can be indexed and validated safely.

The same boundaries drive three different pieces of behavior:

- `strip_protected_content` removes protected blocks before prompt construction.
- `build_static_analysis_index` records protected blocks in `.claudux/index/static-analysis.json` with their markers, line numbers, and hashes.
- `capture_docs_structure_guard_snapshot` and `validate_docs_structure_guard_snapshot` verify that those blocks survive generation unchanged.

Protected-block preservation applies to both docs files and tracked source files. If a generation run rewrites the contents of an existing protected block or drops one of the blocks entirely, the guard snapshot fails the run.

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

`.claudux-state.json` remains local per developer. It records the last successful generation point. The deterministic checkpoint metadata records:

- Static index version.
- Prompt version.
- Backend selection.
- Manifest hash.
- Source hashes.
- Docs section hashes.
- Source-to-section coverage.

That makes "what changed since docs were last trusted" answerable without asking a model to infer history.
