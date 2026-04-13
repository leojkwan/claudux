# Architecture

claudux is a pure-bash CLI tool with zero runtime dependencies. It analyzes a codebase, sends a structured prompt to an AI backend (Claude or Codex), and writes the result as a VitePress documentation site.

## Project layout

```
bin/
  claudux              # Entry point — arg parsing, dep validation, command dispatch
lib/
  colors.sh            # Terminal color codes and print helpers
  project.sh           # Project detection (type, name) from claudux.json or file heuristics
  content-protection.sh # Skip-marker parsing for sensitive content
  claude-utils.sh      # Claude CLI adapter — model selection, prompt dispatch, output parsing
  codex-utils.sh       # Codex CLI adapter (added by multi-backend feature, PRs #3/#5)
  git-utils.sh         # Git status, change tracking, diff helpers
  docs-generation.sh   # Two-phase pipeline: prompt building + doc writing + link validation
  cleanup.sh           # AI-powered obsolete-doc detection and removal
  server.sh            # VitePress dev server wrapper
  validate-links.sh    # Internal link checker (executed as subprocess, not sourced)
  ui.sh                # Interactive menu, help text, header display
  templates/           # Per-framework prompt configs (React, Next.js, iOS, Go, Python, etc.)
  vitepress/           # VitePress scaffolding (config template, theme, postcss, vite config)
docs/                  # Generated documentation site (VitePress)
.github/               # CI workflows
```

## Two-phase generation pipeline

Documentation generation runs in two phases:

### Phase 1: Prompt construction

`docs-generation.sh` builds a prompt by combining:

1. **Project detection** -- `project.sh` identifies the framework (React, Next.js, Python, Go, iOS, etc.) from marker files like `package.json`, `Podfile`, `go.mod`, `Cargo.toml`.
2. **Template config** -- framework-specific instructions from `lib/templates/` guide the AI toward idiomatic documentation for that stack.
3. **Style guide** -- optional `.ai-docs-style.md` in the project root or home directory.
4. **User directive** -- the `-m "..."` flag injects a focused instruction into the prompt.
5. **Codebase snapshot** -- relevant source files are included as context.

### Phase 2: AI execution and validation

The assembled prompt is dispatched to whichever backend is active:

- **Claude** (`claude-utils.sh`) -- runs via `claude` CLI in streaming mode. Output is parsed line-by-line and written to `docs/`.
- **Codex** (`codex-utils.sh`) -- runs via `codex exec` in non-interactive JSONL mode. Events (`item.started`, `item.completed`, `file_change`) are parsed and rendered as progress output.

After the AI writes files, `validate-links.sh` checks every internal link in the generated VitePress config and markdown files. Broken links are reported; the AI is re-prompted to fix them in a correction loop.

## Backend router

The backend is selected by the `CLAUDUX_BACKEND` environment variable:

```
CLAUDUX_BACKEND=claude  (default)  -->  claude-utils.sh
CLAUDUX_BACKEND=codex              -->  codex-utils.sh
```

Both adapters expose the same interface to `docs-generation.sh`:

| Function | Purpose |
|----------|---------|
| `check_<backend>()` | Verify CLI is installed and authenticated |
| `get_<backend>_model_settings()` | Return model name, timeout hint, effort level |
| `run_<backend>_exec()` | Dispatch prompt, stream output |
| `format_<backend>_output_stream()` | Parse backend-specific output into progress display |

The router is soft-loading: if `CLAUDUX_BACKEND=codex` but `codex-utils.sh` is missing, diagnostic commands (`check`, `help`, `--version`) still work. Only generation commands require the adapter.

## Content protection

Files can opt out of documentation with skip markers:

```markdown
<!-- skip -->
This section will not be documented.
<!-- /skip -->
```

`content-protection.sh` supports markers for markdown, Swift, JS/TS, Python, shell, HTML, and XML. The markers are stripped before the codebase snapshot is assembled.

## Concurrency

`bin/claudux` implements file-based locking via PID files in `$TMPDIR`. Only one claudux instance can run per project directory at a time. Stale locks from crashed processes are detected and cleaned up automatically.

## Security model

- No network calls except to the AI backend CLI (which handles its own auth).
- Zero runtime npm dependencies -- the `dependencies` field in `package.json` is empty.
- No `eval` or dynamic code execution.
- No secrets stored or transmitted -- authentication is delegated to the backend CLI.
- See SECURITY.md (shipping in PR #9) for the full threat model and disclosure policy.

## Testing

Tests are pure bash scripts with zero external dependencies. They cover file structure, library syntax, CLI behavior, help consistency, and project detection. The test suite (67 tests) and CI workflows are shipping in PRs #8 and #13. Run them with:

```bash
bash tests/run-tests.sh
```

CI runs ShellCheck linting, bash syntax checks, file structure validation, and the full test suite on every PR.
