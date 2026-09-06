# Configuration

Claudux has three different configuration surfaces. They do not provide the
same guarantees:

- `claudux.json` supplies a small set of shell-read project and deployment
  values.
- `claudux.md` is free-form guidance included in the generation prompt.
- `docs-structure.json` is the validated page and section contract used by
  manifest mode.

## Project Configuration

The main CLI reads these fields from `claudux.json`:

```json
{
  "project": {
    "name": "Your Project",
    "type": "javascript",
    "model": "sonnet"
  }
}
```

| Field | Effect |
|-------|--------|
| `project.name` | Display name shown by the CLI and supplied to generation |
| `project.type` | Overrides project-type detection when the value is supported |
| `project.model` | Selects the Claude model when `FORCE_MODEL` is unset |

The shell does not interpret arbitrary documentation, feature, renderer, or
template fields from this file.

The VitePress setup script can additionally read deployment values when `jq`
is installed:

```json
{
  "deployment": {
    "base": "/your-project/",
    "siteUrl": "https://example.com/your-project/"
  }
}
```

`deployment.base` controls the generated `docs:build:pages` script.
`deployment.siteUrl` is substituted only when an existing VitePress config
contains the `{{SITE_URL}}` placeholder.

### Legacy file

The legacy `.claudux.json` format reads flat `name` and `type` fields:

```json
{
  "name": "Your Project",
  "type": "javascript"
}
```

Prefer `claudux.json` for new projects.

## Project Types

Claudux detects types in this order:

| Type | Detection |
|------|-----------|
| `ios` | `Project.swift`, `*.xcodeproj`, or `*.xcworkspace` |
| `nextjs` | Next.js config or a `next` dependency |
| `react` | A `react` dependency |
| `nodejs` | An `@types/node` dependency |
| `javascript` | Any remaining `package.json` |
| `rust` | `Cargo.toml` |
| `python` | `pyproject.toml`, `setup.py`, or `requirements.txt` |
| `go` | `go.mod` |
| `java` | `pom.xml`, `build.gradle`, or `build.gradle.kts` |
| `generic` | Fallback |

A configured value is also accepted when
`lib/templates/<type>-project-config.json` exists in the installed Claudux
revision. Unknown values warn and fall back to detection.

The selected JSON file under `lib/templates/` is a
[project profile](/technical/templates). It is prompt context, not a renderer
or schema engine.

## Documentation Preferences

Create `claudux.md` in the target repository to give the backend site-specific
guidance:

```markdown
# Site
- Title: Your Project
- Audience: application developers

# Structure
- Put installation before configuration.
- Keep one shared sidebar.

# Content
- Include runnable examples from the repository.
- Omit internal deployment procedures.
```

Claudux tells the backend to read this file. It does not parse or validate the
headings, enforce the requested navigation, or guarantee that every preference
appears in the result. Review the generated diff.

## Environment Variables

### Backend and model

| Variable | Default | Effect |
|----------|---------|--------|
| `CLAUDUX_BACKEND` | `claude` | Selects `claude` or `codex` |
| `FORCE_MODEL` | `project.model`, then `sonnet` | Selects the Claude model |
| `CODEX_MODEL` | `gpt-5.4` | Selects the Codex model |
| `CODEX_REASONING_EFFORT` | `xhigh` | Selects Codex reasoning effort |
| `CLAUDUX_TIMEOUT` | `600` | Codex timeout in seconds when `timeout` or `gtimeout` is available; `0` disables it |

```bash
CLAUDUX_BACKEND=codex \
CODEX_MODEL=gpt-5.4 \
CODEX_REASONING_EFFORT=xhigh \
claudux update
```

### Generation and manifest

| Variable | Effect |
|----------|--------|
| `CLAUDUX_MESSAGE` | Supplies a default focused directive |
| `DOCS_BASE` | Sets the VitePress base used by generated config at runtime |
| `CLAUDUX_DOCS_STRUCTURE` | Overrides the manifest path |
| `DOCS_STRUCTURE_FILE` | Alternate manifest-path default |
| `CLAUDUX_UNLOCK_PINNED_SECTIONS=1` | Allows a patch that also sets `unlock_pinned: true` to target read-only content |
| `CODEX_SANDBOX_MODE` | Overrides the Codex sandbox requested by Claudux |

Manifest mode defaults Codex to a read-only sandbox; default generation uses
`workspace-write`. Overriding the sandbox can weaken the pre-execution
boundary, although manifest patch validation still controls accepted
documentation writes.

### Runtime paths

| Variable | Effect |
|----------|--------|
| `TMPDIR` | Base for process-private temporary files |
| `XDG_STATE_HOME` | Base for project locks and Codex stderr |
| `CODEX_STDERR_LOG` | Overrides the Codex stderr file |

## Content Protection

### Default generation

Without manifest mode, the backend can edit documentation paths directly.
Claudux snapshots Git `HEAD` and dirty non-documentation paths, then rejects
and restores unrelated mutations or commits after generation. This boundary
does not protect individual sections inside `docs/`.

`lib/content-protection.sh` contains a protected-path predicate for common
private, dependency, build, and key-file patterns, but the current generation
flow does not call that helper as a filesystem denylist. Treat those names as
prompt guidance, not automatic path enforcement.

### Manifest mode

With a qualifying committed `docs-structure.json`, the backend is read-only
and Claudux applies only validated section patches. Pinned sections, explicit
read-only sections, and recognized skip-marker blocks are hash-checked against
the pre-generation guard snapshot.

Markdown markers:

```markdown
<!-- skip -->
This block is guarded in manifest mode.
<!-- /skip -->
```

Code markers:

```javascript
// skip
const preservedExample = true;
// /skip
```

Supported marker styles include:

- `<!-- skip -->` for Markdown, HTML, XML, and Vue
- `// skip` for JavaScript, TypeScript, Swift, Java, C-family, Rust, and Go
- `# skip` for Python, shell, Ruby, and Perl
- `/* skip */` for CSS-family files
- `-- skip` for SQL

Skip markers are literal, line-based boundaries. Their mechanical
preservation guarantee belongs to manifest mode; the update path does not
strip protected content before prompting.

## VitePress Behavior

The backend authors `docs/.vitepress/config.ts` during generation. Claudux
does not deterministically derive the complete nav or sidebar from
`claudux.json`.

After a successful backend run, the update path normalizes an existing `base:`
entry to:

```typescript
base: process.env.DOCS_BASE || '/'
```

The model-free `claudux serve` path may run `lib/vitepress/setup.sh` when
support files are missing. That setup can:

- Create a minimal config only when `docs/.vitepress/config.ts` is absent
- Copy the bundled theme plus Vite and PostCSS isolation files
- Detect and copy a small set of conventional logo paths
- Rewrite `docs/package.json`
- Replace a fixed set of placeholders already present in the config

It does not infer a complete site structure from the project profile.

## Link Validation

`claudux update` checks:

- VitePress nav and sidebar routes
- Inline and reference-style Markdown links
- Local assets
- Generated and explicit anchors
- Duplicate explicit IDs
- Invalid percent encoding and path traversal
- Symlinks that escape `docs/`

External URLs are skipped. By default unresolved failures warn after one
optional missing-page repair pass. `claudux update --strict` makes remaining
failures fatal.

## CI Guidance

Generation invokes an authenticated model and can change tracked
documentation. A deterministic CI gate should validate an already-generated
tree:

```yaml
- name: Verify documentation
  run: |
    bash lib/validate-links.sh
    npm --prefix docs ci
    npm --prefix docs run docs:build
```

If CI intentionally runs `claudux update`, pin the Claudux revision and
backend configuration, provide backend authentication, use `--strict`, and
fail when the generated diff is not the reviewed result.

## Related

- [Commands](/guide/commands)
- [Project Profiles](/technical/templates)
- [Deterministic Generation](/technical/deterministic-generation)
