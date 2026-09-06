# Claudux

**Regenerate your docs from the code, without losing the paragraphs you wrote by hand.**

I kept a VitePress site for a project and let Claude rewrite it whenever the
code moved. It was fast and it kept stomping the two pages I'd actually
written with care. Claudux is the wrapper I built to stop that. It runs your
own Claude CLI or Codex CLI (no API key, no hosted service), asks it for
patches, and applies them only where a committed manifest says it may.

[Quick start](#quick-start) · [A real update](#one-real-bounded-update) ·
[Docs](https://firstbitelabsllc.github.io/claudux/) ·
[Issues](https://github.com/firstbitelabsllc/claudux/issues)

<p align="center">
  <a href="https://github.com/firstbitelabsllc/claudux/actions/workflows/ci.yml"><img src="https://github.com/firstbitelabsllc/claudux/actions/workflows/ci.yml/badge.svg" alt="CI status" /></a>
  <a href="https://github.com/firstbitelabsllc/claudux/stargazers"><img src="https://img.shields.io/github/stars/firstbitelabsllc/claudux?style=flat" alt="GitHub stars" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" /></a>
  <img src="https://img.shields.io/badge/node-%E2%89%A518-5fa04e?style=flat" alt="Node ≥ 18" />
</p>

The manifest is a `docs-structure.json` in your repo. It lists the pages, the
sections the model may rewrite, and the text it must leave alone. The model
never gets file access in that mode; it returns patch JSON and Claudux checks
the whole batch, including hashes of the protected blocks, before writing
anything. Without a manifest the first run is broader, and Claudux restores
any source file it touches outside the docs. Read [the safety model](#safety-model)
before pointing it at work you care about.

<p align="center">
  <img src="assets/claudux-rails.svg" alt="How manifest mode applies a section-patch batch: the repository declares writable sections, the backend returns patch JSON without direct file access, and claudux validates every target, boundary, impact rule, and protected hash before transactionally committing the target documentation files." width="820" />
</p>

## Quick start

Node 18+ and a Claude CLI (default) or Codex CLI you're already logged into.

```bash
curl -fsSL https://raw.githubusercontent.com/firstbitelabsllc/claudux/main/install.sh | sh
cd your-project
claudux check    # Node, backend login, docs state
claudux update   # generate or update the docs
claudux serve    # preview at http://localhost:5173
```

`update` is the only command that spends model usage, and it spends yours.
Look at `git diff` before you commit what it wrote.

The installer clones into `~/.local/share/claudux` and symlinks the CLI onto
your PATH, tracking `main`. To pin a release instead:

```bash
curl -fsSL https://raw.githubusercontent.com/firstbitelabsllc/claudux/v2.0.7/install.sh \
  | CLAUDUX_REF=v2.0.7 sh
```

A bad ref fails loudly instead of falling back to `main`. For a one-off,
`npx github:firstbitelabsllc/claudux update` works without installing.

<p align="center">
  <img src="assets/claudux-terminal-demo.svg" alt="A real claudux session: claudux update detects the project type, generates VitePress docs with Claude, and validates links; claudux serve previews them at localhost:5173" width="780" />
</p>

## One real bounded update

Small Node package, docs already covering `addCents` and `formatUsd`. I added
`allocateCents(total, parts)` with tests, committed a manifest that pinned
the guide's quick-start section, and ran:

```bash
claudux update -m "Document the new allocateCents API from its source and tests."
```

After: the API page had the new signature, examples, and error behavior. The
pinned guide was byte-identical. Only one file changed:

```text
$ git diff --name-only HEAD^
docs/api/index.md
```

The [full receipt](evidence/real-target-lifecycle.md) has the install commit,
manifest hashes, the rejected out-of-bounds write, the docs build, the link
check, and the browser result.

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

## Check a proposed update in CI

With a committed `docs-structure.json`, `claudux update --check` runs the
backend read-only and compares its proposed section patches against the docs
on disk, writing nothing. Exit codes: `0` when the proposal changes no files,
`2` when the proposal would change files (those files are listed), and `1` on
a validation or backend error. Use it in CI to surface proposed docs changes:

```yaml
- run: claudux update --check
```

The proposal comes from the same model that `claudux update` uses. An unchanged
proposal exits `0` even when the model missed an undocumented source change.
This checks proposed edits; it does not establish that the docs are accurate
or cover the source. Keep human review and any API-specific documentation
checks you already use.

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
