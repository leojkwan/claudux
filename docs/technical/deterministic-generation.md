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

The manifest is intentionally separate from `claudux.md`. `claudux.md` describes site taste. `docs-structure.json` is operational state.

## Pipeline

The deterministic pipeline is:

1. Validate `docs-structure.json` before generation.
2. Build `.claudux/index/static-analysis.json` from tracked source files, docs files, package scripts, markdown headings, and manifest ownership.
3. Add the static index summary to the model prompt as authoritative facts.
4. Use `.claudux-state.json` to find changed files since the previous run.
5. Resolve changed files through manifest `source_patterns` to the impacted page or section set.
6. Let the model update only the relevant documentation surface.
7. Validate `docs-structure.json` again after generation.
8. Validate internal links and save the checkpoint.

The current implementation still allows whole-file writes because the model backends write through Claude Code or Codex. The contract now makes those writes auditable. The next hardening step is section-level patch application keyed by manifest section IDs.

## Static Analysis Index

The static index is local cache state, not a generated doc. It lives under `.claudux/index/` and is ignored by git.

Each run records:

- HEAD SHA.
- Manifest hash and page counts.
- Tracked source file hashes.
- Tracked docs file hashes.
- Markdown headings per docs file.
- `package.json` scripts.
- Manifest source ownership.

This gives the prompt a stable fact table before any model output. A large repo can change thousands of files, but claudux can still start from sorted paths and hashes instead of asking the model to rediscover the project from a blank scan.

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

Allowed:

- Updating body text inside a pinned section when source facts changed.
- Adding generated subsections under an allowed parent.
- Proposing a manifest diff that renames or moves the section.

Blocked:

- Deleting a manifest-listed page because the model thinks it is obsolete.
- Moving a pinned section to another page without a manifest diff.
- Replacing the entire docs tree with a newly inferred information architecture.

This complements skip markers from `lib/content-protection.sh`. Skip markers protect local content regions. Pinned manifest sections protect documentation structure.

## Dependency-Aware Scope

Filename-only incremental mode is too coarse. `lib/docs-manifest.sh` resolves changed files through `source_patterns` so claudux can name the page or section likely to be stale.

Example:

```text
lib/docs-generation.sh -> technical.deterministic-generation (docs/technical/deterministic-generation.md)
lib/docs-generation.sh -> technical.deterministic-generation#pipeline (docs/technical/deterministic-generation.md)
```

The model still sees the changed file list, but it also gets the manifest-owned impact set. That distinction matters on large codebases where one source file has a known doc owner and hundreds of unrelated docs should stay untouched.

## Validators

Manifest validation has two modes:

- Preflight validates JSON shape, unique page IDs, relative `docs/*.md` paths, deletion policy, and section IDs.
- Post-generation also verifies every manifest page exists and every required or pinned heading still appears on disk.

`claudux validate` runs manifest validation before link validation. `claudux update` runs it before model invocation and again after model writes.

## StrongYes Harness Example

StrongYes has a local Supabase E2E harness that shows why pinned doctrine matters.

The local loop in `CLAUDE.md` points agents at `npm run db:start`, `npm run db:reset`, and `npm run db:stop` for migrations and auth testing. `scripts/run-local-supabase-test.mjs` wraps that loop by starting Supabase when needed, optionally resetting migrations, forwarding harness arguments, generating an ephemeral `E2E_TEST_USER_PASSWORD` when missing, and stopping the stack if it started it.

The Playwright seed path is even more structure-sensitive. `e2e/fixtures/staging-seed.ts` is idempotent: it resolves or creates the canonical user, inserts only missing game-plan cards, inserts only missing memories, and refuses to seed the production Supabase ref. `e2e/fixtures/global-setup.ts` treats missing env as an opted-out no-op but propagates the production guard.

That doctrine should not be rewritten as generic "run your tests" content. It needs source-owned sections:

- Local Supabase lifecycle owned by `scripts/run-local-supabase-test.mjs`.
- Idempotent seed semantics owned by `e2e/fixtures/staging-seed.ts`.
- Production guard semantics pinned as a required section.
- Playwright setup behavior owned by `e2e/fixtures/global-setup.ts` and `playwright.config.ts`.

When those files change, the docs should update those sections. When unrelated UI files change, the harness doctrine should survive untouched.

## Checkpoint Contract

`.claudux-state.json` remains local per developer. It records the last successful generation point. The static index adds deterministic context around that checkpoint by recording hashes and manifest ownership at run time.

Future checkpoint hardening should record:

- Static index version.
- Prompt version.
- Backend and model.
- Manifest hash.
- Source hashes.
- Docs section hashes.
- Source-to-section coverage.

That makes "what changed since docs were last trusted" answerable without asking a model to infer history.
