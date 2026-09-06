# Claudux

**Regenerate your docs from the code. The paragraphs you wrote by hand stay byte-identical.**

What a run checks before it spends anything, on this repo:

```console
$ claudux check
• Node: v26.8.1
• Backend: claude
• Claude CLI: 2.1.263 (Claude Code)
• Model: fable
🔐 Checking Claude CLI authentication...
📁 Detected project type: javascript
• docs/: present

✅ Environment check passed
```

I let Claude rewrite a VitePress site whenever the code moved, and it kept
stomping the two pages I'd written by hand. Claudux is the wrapper I built to
stop that. It runs your own Claude CLI or Codex CLI (no API key, no hosted
service) and applies its patches only where a committed manifest allows.

[Quick start](#quick-start) · [A real update](#one-real-bounded-update) ·
[Docs](https://firstbitelabsllc.github.io/claudux/) ·
[Issues](https://github.com/firstbitelabsllc/claudux/issues)

<p align="center">
  <a href="https://github.com/firstbitelabsllc/claudux/actions/workflows/ci.yml"><img src="https://github.com/firstbitelabsllc/claudux/actions/workflows/ci.yml/badge.svg" alt="CI status" /></a>
  <a href="https://github.com/firstbitelabsllc/claudux/stargazers"><img src="https://img.shields.io/github/stars/firstbitelabsllc/claudux?style=flat" alt="GitHub stars" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" /></a>
  <img src="https://img.shields.io/badge/node-%E2%89%A518-5fa04e?style=flat" alt="Node ≥ 18" />
</p>

## What a run may touch

`docs-structure.json`, committed in your repo. One page from this repo's
own, trimmed:

```json
{
  "path": "docs/technical/deterministic-generation.md",
  "sections": [
    { "id": "pipeline", "heading": "Pipeline", "pinned": true },
    { "id": "validators", "heading": "Validators",
      "source_patterns": ["lib/docs-manifest.sh"] }
  ]
}
```

- **pinned**: hash-checked. A patch that touches it is rejected.
- **source_patterns**: the files allowed to change this section.
- **patch**: the model gets no file access. It returns patch JSON; Claudux
  checks the whole batch, then writes.

<p align="center">
  <img src="assets/claudux-rails.svg" alt="How manifest mode applies a section-patch batch: the repository declares writable sections, the backend returns patch JSON without direct file access, and claudux validates every target, boundary, impact rule, and protected hash before transactionally committing the target documentation files." width="820" />
</p>

## Quick start

Node 18+ and a Claude CLI (default) or Codex CLI you're logged into.

```bash
curl -fsSL https://raw.githubusercontent.com/firstbitelabsllc/claudux/main/install.sh | sh
cd your-project
claudux check    # Node, backend login, docs state
claudux update   # generate or update the docs
claudux serve    # preview at http://localhost:5173
```

`update` is the only command that spends model usage, and it spends yours.
Read `git diff` before you commit. `CLAUDUX_REF=v2.0.7` on the install line
pins a release; a bad ref fails instead of falling back to `main`.

<p align="center">
  <img src="assets/claudux-terminal-demo.svg" alt="A real claudux session: claudux update detects the project type, generates VitePress docs with Claude, and validates links; claudux serve previews them at localhost:5173" width="780" />
</p>

## One real bounded update

I added `allocateCents(total, parts)` to a small package, pinned the guide's
quick-start section, and ran:

```bash
claudux update -m "Document the new allocateCents API from its source and tests."
```

```text
$ git diff --name-only HEAD^
docs/api/index.md
```

The pinned guide was byte-identical. [Full receipt](evidence/real-target-lifecycle.md):
manifest hashes, the rejected out-of-bounds write, docs build, browser result.

## Safety model

| Mode | Backend access | On failure |
| --- | --- | --- |
| No manifest | Writes docs paths directly; any change outside docs, local state, and manifest paths is rejected | Restores unrelated source and `HEAD`; leaves the docs diff for review |
| Committed `docs-structure.json` | Read-only; patches checked against page IDs, writable sections, source ownership, deletion rules, protected hashes | Rejects the whole batch or restores every target file |

Skip-marker blocks (`<!-- skip -->` … `<!-- /skip -->`, `// skip`, `# skip`,
`/* skip */`, `-- skip`) are hash-guarded too. After a run, Claudux checks
routes, links, assets, anchors, and symlink escapes; `--strict` fails on
unresolved links. Model output can still be wrong; review the diff.

In CI, `claudux update --check` runs the backend read-only and writes
nothing: exit `0` when no file would change, `2` when files would, `1` on
error. An unchanged proposal does not prove the docs are complete.

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
