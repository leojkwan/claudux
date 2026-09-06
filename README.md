# Claudux

**Update your docs when your code changes. Keep the parts you wrote.**

Claudux uses your authenticated Claude CLI or Codex CLI to draft and update a
VitePress documentation site. Commit a manifest to choose which sections it
may change and which it must leave alone.

[Get started](#quick-start) · [See a real update](#one-real-bounded-update) ·
[Read the docs](https://firstbitelabsllc.github.io/claudux/) ·
[Report a problem](https://github.com/firstbitelabsllc/claudux/issues)

<p align="center">
  <a href="https://github.com/firstbitelabsllc/claudux/actions/workflows/ci.yml"><img src="https://github.com/firstbitelabsllc/claudux/actions/workflows/ci.yml/badge.svg" alt="CI status" /></a>
  <a href="https://github.com/firstbitelabsllc/claudux/stargazers"><img src="https://img.shields.io/github/stars/firstbitelabsllc/claudux?style=flat" alt="GitHub stars" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" /></a>
  <img src="https://img.shields.io/badge/node-%E2%89%A518-5fa04e?style=flat" alt="Node ≥ 18" />
</p>

For an existing docs site, `docs-structure.json` names the pages, writable
sections, and protected text. The backend proposes patches; Claudux checks
the whole batch before applying it. Without a manifest, the first run has
broader write access and restores unrelated source if it changes. Read the
[safety model](#safety-model) before running it on work you want to keep.

<p align="center">
  <img src="assets/claudux-rails.svg" alt="How manifest mode applies a section-patch batch: the repository declares writable sections, the backend returns patch JSON without direct file access, and claudux validates every target, boundary, impact rule, and protected hash before transactionally committing the target documentation files." width="820" />
</p>

## Quick start

Requirements: Node 18+ and an authenticated Claude CLI (default) or Codex CLI
on the machine. There is no hosted API-key path.

```bash
curl -fsSL https://raw.githubusercontent.com/firstbitelabsllc/claudux/main/install.sh | sh
cd your-project
claudux check    # verify Node and backend authentication
claudux update   # generate or update docs
claudux serve    # preview at http://localhost:5173
```

Those five commands are the setup; model generation can take longer depending
on the repository and backend. Inspect `git diff` before committing the docs.
Generation uses your existing provider allowance and can incur its usual
usage costs. `claudux check` verifies setup without generating documentation.

The installer clones GitHub into `~/.local/share/claudux` and symlinks the CLI
onto your PATH. It tracks `main` by default. Pin the current release with:

```bash
curl -fsSL https://raw.githubusercontent.com/firstbitelabsllc/claudux/v2.0.7/install.sh \
  | CLAUDUX_REF=v2.0.7 sh
```

A missing ref fails instead of silently falling back to `main`. For one run
without installing, use `npx github:firstbitelabsllc/claudux update`. Run
`claudux` with no arguments for the interactive menu.

<p align="center">
  <img src="assets/claudux-terminal-demo.svg" alt="A real claudux session: claudux update detects the project type, generates VitePress docs with Claude, and validates links; claudux serve previews them at localhost:5173" width="780" />
</p>

Reconstructed from a real run against a two-file Node CLI: project detection,
generation, link validation, and the VitePress preview.

## One real bounded update

In a disposable Node package, the initial API page documented `addCents` and
`formatUsd`. The source and tests then added `allocateCents(total, parts)`.
With a committed manifest, this command ran the backend read-only:

```bash
claudux update -m "Document the new allocateCents API from its source and tests."
```

Before the run, the API page had no `allocateCents` entry and the guide's
quick-start section was pinned. After the run, the API page contained the new
signature, examples, and error behavior; the pinned guide remained
byte-identical:

```text
$ git diff --name-only HEAD^
docs/api/index.md
```

The [full lifecycle receipt](evidence/real-target-lifecycle.md) records the
install commit, manifest hashes, rejected unrelated-source mutation, docs
build, link check, dependency audit, and browser result.

## Safety model

| Mode | Backend access | Mechanical boundary | On failure |
| --- | --- | --- | --- |
| First run / no manifest | May write documentation paths directly | claudux rejects new worktree, index, or commit mutations outside documentation, local state, and manifest paths | Restores unrelated source and `HEAD`; leaves the docs diff for review |
| Committed `docs-structure.json` | Read-only | Page IDs, source ownership, writable sections, deletion rules, impact limits, and protected hashes | Rejects the whole patch batch or restores every target file |

Manifest mode also hash-guards pinned sections, explicit read-only sections,
and skip-marker blocks:

```markdown
<!-- skip -->
This block is hash-guarded by claudux.
<!-- /skip -->
```

Language-specific marker pairs include `// skip`, `# skip`, `/* skip */`, and
`-- skip`.

## CI docs-drift gate

With a committed `docs-structure.json`, `claudux update --check` runs the
backend read-only and compares its proposed section patches against the docs
on disk, writing nothing. Exit codes: `0` when docs match sources, `2` when
drift is detected (the drifting files are listed), `1` on a validation or
backend error. Wire it into CI so a pull request fails when its docs fall
behind its code:

```yaml
- run: claudux update --check
```

The gate proposes through the same model that `claudux update` uses, so a
drift verdict reflects what an update would change rather than a text diff;
a no-op proposal exits `0`. Because the proposal is model-generated, treat
the gate as a boundary-enforced reviewer: a false positive costs one re-run,
a false negative costs nothing the next update would not also miss.

After generation, claudux checks VitePress routes, Markdown links, local
assets, anchors, traversal, and symlink escapes. External URLs are skipped.
Unresolved links warn by default; `--strict` fails the update.

`claudux update -m "document the new auth flow"` focuses a run on one area.
Model output can still be wrong, so the generated diff remains the review
surface. `serve` never invokes a model, though it may scaffold VitePress files
and run `npm install`. `check` never generates docs, but it does verify the
selected backend's authentication.

## Command and configuration reference

These are the supported CLI entry points:

```bash
claudux                 # Interactive menu
claudux update          # Generate or update docs
claudux update -m "..." # Update with a focused directive
claudux serve           # Start the VitePress dev server
claudux check           # Verify Node, backend CLI, and docs state
claudux help            # Show help
claudux --version       # Show installed version
```

Project-level configuration is optional. Put `claudux.json` in the project
root:

```json
{
  "project": {
    "name": "Your Project",
    "type": "react"
  }
}
```

- `claudux.json` sets project metadata and type overrides.
- `claudux.md` stores optional documentation preferences (navigation order, sections to include or omit, naming policy); claudux reads it when present.
- `docs-structure.json` is the deterministic manifest for pinned pages, source-owned sections, bounded patching, and deletion guards.

claudux auto-detects iOS, Next.js, React, Node.js, JavaScript, Java, Python, Go, and Rust. Anything else falls back to a generic profile, or set `project.type` in `claudux.json` to one of the exact strings: `ios`, `nextjs`, `react`, `nodejs`, `javascript`, `rust`, `python`, `go`, `java`, `generic` — or any type with a template under `lib/templates/` (`flutter`, `android`, and `rails` ship today). An unrecognized value (like `node`) warns and falls back to auto-detection rather than silently degrading to the generic profile.

## Project docs

- [Live docs](https://firstbitelabsllc.github.io/claudux/)
- [Architecture](./ARCHITECTURE.md)
- [Deterministic generation](./docs/technical/deterministic-generation.md)
- [Changelog](./CHANGELOG.md)
- [Security](./SECURITY.md)
- [Contributing](./CONTRIBUTING.md)

## License

MIT
