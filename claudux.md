## claudux repository notes (evergreen)

- This file intentionally contains no user-facing or procedural docs. Keep content evergreen.
- All documentation is generated; do not maintain instructions here. Edit generators/templates instead:
  - `lib/docs-generation.sh` — end-to-end generation flow and prompt assembly
  - `lib/templates/**` — project templates and content seeds
  - `lib/vitepress/**` — config/templates for site build
  - `lib/ui.sh` — CLI messages/help surfaced to users
- Never edit `docs/**` or `docs/.vitepress/**` directly; they are generated.
- Core conventions: Bash-first, snake_case, strict mode (`set -u`, `set -o pipefail`), command availability checks, `bin/claudux` acts only as a router.
- Cleanup safety: only remove stale generated docs; never delete source code. Protected paths are enforced in `lib/content-protection.sh`.
- VitePress base: local/dev uses `process.env.DOCS_BASE || '/'`; CI sets `DOCS_BASE=/claudux/` for GitHub Pages.

If content drifts into step-by-step guidance or command flags, move it into `lib/**` so generated docs remain the single source of truth.