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

When `docs-structure.json` exists, claudux switches generation into section patch mode.

In that mode the model gets the static index, manifest impact set, and a strict output contract. It returns JSON between `CLAUDUX_SECTION_PATCHES_JSON_START` and `CLAUDUX_SECTION_PATCHES_JSON_END`:

```json
{
  "patches": [
    {
      "page_id": "technical.deterministic-generation",
      "section_id": "section-patch-application",
      "body_markdown": "Updated markdown body without the heading."
    }
  ]
}
```

Exactly one payload marker pair is allowed. Multiple payload blocks or orphaned start/end markers fail before JSON parsing, so claudux never silently chooses one model-proposed patch set over another.

Claudux then applies the patch itself:

- The page ID and section ID must exist in `docs-structure.json`.
- The target page must already exist on disk.
- The target section's heading anchor is unambiguous: one `level + heading` pair per manifest page and one matching heading on disk.
- The patch replaces only the body under that manifest heading, ending before the next same-or-higher-level heading.
- The whole patch batch validates before any file is written; one invalid patch leaves every doc file unchanged.
- Patch bodies may include deeper subheadings, but same-or-higher-level headings are rejected because they would escape the bounded section.
- Incremental runs reject patches outside `.claudux/index/impacted-docs.json`; full scans keep the wider manifest-generated section contract.
- Pinned sections are rejected unless the human explicitly runs with `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` and the patch sets `unlock_pinned: true`.
- Claude runs with only the `Read` tool in patch mode.
- Codex runs with a read-only sandbox in patch mode.

This is the practical boundary: the model can propose source-aware wording, but the repository code owns what gets written and where.

## Static Analysis Index

The static index is local cache state, not a generated doc. It lives under `.claudux/index/` and is ignored by git.

Each run records:

- HEAD SHA.
- Manifest hash and page counts.
- Tracked source file hashes.
- Tracked docs file hashes.
- Markdown headings per docs file.
- `package.json` scripts.
- CLI command aliases from `bin/claudux`.
- Exported shell functions from shell-like source files.
- Test files.
- Deterministic dependency edges from shell sources and package scripts.
- Internal docs links.
- Manifest source ownership.

This gives the prompt a stable fact table before any model output. A large repo can change thousands of files, but claudux can still start from sorted paths and hashes instead of asking the model to rediscover the project from a blank scan.

The deterministic cache deliberately omits wall-clock `generated_at` fields. Run time belongs in `.claudux-state.json`; the static index, guard snapshot, and impacted-docs allowlist should be byte-stable when inputs are unchanged.

## docs-structure.json Manifest

The manifest owns structure with fields that are easy to review:

```json
{
  "version": 1,
  "deletion_policy": "manifest_pages_require_manifest_change",
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

## Pinned Pages and Sections

Pinned does not mean frozen wording. It means the section's identity, heading, and place in the page survive reruns.

Allowed with an explicit manifest or human unlock:

- Updating body text inside a pinned section when source facts changed.
- Adding generated subsections under an allowed parent.
- Proposing a manifest diff that renames or moves the section.

Blocked:

- Deleting a manifest-listed page because the model thinks it is obsolete.
- Moving a pinned section to another page without a manifest diff.
- Replacing the entire docs tree with a newly inferred information architecture.

This complements skip markers from `lib/content-protection.sh`. Skip markers protect local content regions with language-aware marker pairs such as `<!-- skip -->`, `// skip`, `# skip`, `/* skip */`, and `-- skip`. Pinned manifest sections protect documentation structure.

## Content Protection Markers

`lib/content-protection.sh` defines the marker pair for each supported file type. The static index records protected blocks from tracked source and docs files before a model runs, and the guard snapshot validates those block hashes after generation.

Marker matching is literal and line-based. This keeps regex-looking markers such as `/* skip */` deterministic and prevents a model from changing source-owned doctrine inside skip blocks while leaving the surrounding file shape intact.

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
