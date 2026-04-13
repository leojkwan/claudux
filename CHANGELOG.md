# Changelog

All notable changes to claudux are documented in this file.

## [1.2.0] - 2026-04-12

### Added

- **Multi-backend support.** Switch AI backends via `CLAUDUX_BACKEND=codex` env var. Codex adapter uses GPT-5.4 with xhigh reasoning effort in non-interactive exec mode. Claude remains the default.
- **Change tracking.** `claudux diff` shows files changed since the last documentation run. `claudux status` shows checkpoint state (last run time, SHA, backend, stale file count). Checkpoint stored in `.claudux-state.json` (gitignored).
- **Incremental updates.** `claudux update` scopes the LLM prompt to only changed files when a checkpoint exists, reducing token usage on large repos.
- **New CLI commands.** `diff`, `status`, and `validate` are now wired into the CLI. `check` shows active backend and CLI availability.
- **Test suite.** 183 tests across 6 suites (backend router, state file, diff calculation, hardening, integration, CLI). Pure bash, zero dependencies.
- **CI pipeline.** GitHub Actions with 5 parallel jobs: ShellCheck lint, file structure, bash syntax, version consistency, and full test suite. Runs on every push/PR to main.
- **npm publish workflow.** Automated publish on `v*` tag push. Verifies tag matches `package.json` version, runs full CI, publishes with provenance.
- **ARCHITECTURE.md.** Module map, two-phase pipeline, backend router interface, content protection, concurrency model, and security design.
- **SECURITY.md.** Responsible disclosure policy and threat model (shell injection, path traversal, dependency chain, secrets-in-docs).
- **GitHub templates.** Bug report and feature request issue templates. PR template with checklist.
- **Terminal demo SVG.** Visual demo of `claudux update` session in README and docs site.
- **Hero banner SVG.** Styled banner for README with tagline.

### Changed

- `claudux help` now lists all 11 commands (was 7). Help text includes `CLAUDUX_BACKEND` env var documentation.
- `claudux check` now shows active backend and validates the correct CLI (Claude or Codex) based on `CLAUDUX_BACKEND`.
- README expanded with multi-backend section, comparison table, architecture cross-link, and demo SVG.
- CONTRIBUTING.md updated with CI-based release process and `NPM_TOKEN` setup instructions.
- package.json description and keywords updated for multi-backend discoverability.

### Fixed

- `claudux diff` and `claudux status` previously returned "Unknown command" despite being documented in help text.
- `save_claudux_state` produced invalid JSON when `docs/` had no tracked files.
- JSON escaping bug: filenames with double-quotes or backslashes corrupted `.claudux-state.json`.
- Codex JSONL formatter matched hypothetical event types instead of actual Codex CLI v0.119 events.
- `check_generation_backend()` called Claude validation even when Codex backend was active.

## [1.1.1] - 2026-04-11

- Initial public release on npm
- Claude-only backend with two-phase documentation generation
- VitePress site scaffolding and serving
- Link validation with auto-fix
- Content protection for manual edits
- Project type auto-detection (React, Next.js, Python, Go, iOS, Android, Rust, Rails, Flutter, etc.)

[1.2.0]: https://github.com/leojkwan/claudux/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/leojkwan/claudux/releases/tag/v1.1.1
