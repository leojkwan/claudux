# Claudux AI Assistant Instructions

## Project Context
Claudux is a Bash-based CLI tool for AI-powered documentation generation using Claude and VitePress. The codebase prioritizes Unix compatibility, modular architecture, and semantic content analysis.

## CRITICAL RULES - MUST FOLLOW

### Language and Dependencies
- **ALWAYS write core functionality in Bash** - this is a Bash-first project
- **NEVER introduce Python, Ruby, or other scripting languages** for core features
- **NEVER add npm dependencies** beyond what's in package.json unless absolutely necessary
- **ALWAYS check for command availability** before using (see `lib/project.sh:check_command()`)
- **ALWAYS use `set -u` and `set -o pipefail`** in new Bash scripts

### Code Organization
- **ALWAYS place new library functions in appropriate `lib/*.sh` files**
- **NEVER put business logic in `bin/claudux`** - it's a router only
- **ALWAYS source dependencies using**: `source "$SCRIPT_DIR/../lib/module.sh"`
- **FOLLOW the pattern** in `lib/colors.sh` for new utility modules
- **CREATE new templates** in `lib/templates/` for new project types

### Function Patterns
- **USE snake_case** for all Bash functions and variables
- **ALWAYS validate function existence** with `check_function` before calling
- **FOLLOW error handling pattern**:
```bash
error_exit() {
    print_color "RED" "❌ $1" >&2
    exit "${2:-1}"
}
```
- **USE the established logging pattern**:
```bash
log_verbose "Message" # For verbose output
print_color "GREEN" "✓ Success"
print_color "YELLOW" "⚠️ Warning"
```

### Path and File Handling
- **ALWAYS use absolute paths** via `resolve_script_path()`
- **NEVER use relative paths** in sourced files
- **FOLLOW symlink resolution pattern** from `bin/claudux:11-31`
- **USE `mktemp`** for temporary files, not hardcoded paths
- **ALWAYS clean up background processes** in trap handlers

## PROJECT-SPECIFIC PATTERNS

### Claude AI Integration
- **ALWAYS use the pattern** in `lib/claude-utils.sh:generate_with_claude()`
- **BUILD prompts using** the multi-part structure in `lib/docs-generation.sh:build_generation_prompt()`
- **RESPECT model selection**: `local model="${FORCE_MODEL:-opus}"`
- **NEVER hardcode Claude commands** - use the abstraction layer

### VitePress Configuration
- **GENERATE configs using** templates in `lib/vitepress/config-template.ts`
- **FOLLOW sidebar generation pattern** in `lib/vitepress/setup.sh:generate_sidebar_config()`
- **ALWAYS check for existing VitePress** before installation
- **USE dynamic port allocation** for dev server (3000-3100 range)

### Project Detection
- **ADD new project types** to `lib/project.sh:detect_project_type()`
- **CREATE corresponding template** in `lib/templates/`
- **FOLLOW the detection pattern** using file existence checks
- **MAINTAIN priority order** (more specific frameworks before generic)

### Documentation Generation
- **RESPECT the two-phase process**: analysis first, then generation
- **USE semantic obsolescence detection** (95% confidence threshold)
- **PROTECT sensitive content** using patterns in `lib/content-protection.sh`
- **NEVER delete protected directories**: `notes/`, `private/`, `.git/`, etc.

## TESTING REQUIREMENTS

### Before Committing
- **RUN `./bin/claudux version`** to verify basic functionality
- **TEST with a sample project** using `claudux update`
- **VERIFY VitePress serves** with `claudux serve`
- **CHECK cleanup safety** with `claudux clean --dry-run`

### When Adding Features
- **TEST on both macOS and Linux** (different `md5sum` vs `md5` commands)
- **VERIFY graceful degradation** when optional tools missing (jq, git)
- **TEST interrupt handling** (Ctrl+C during generation)
- **ENSURE lock file cleanup** on all exit paths

## COMMON TASKS

### Adding a New Command
1. **ADD case in `bin/claudux`** main switch statement
2. **CREATE handler function** in appropriate `lib/*.sh` file
3. **UPDATE help text** in `lib/ui.sh:show_help()`
4. **ADD to interactive menu** if user-facing

### Adding Project Type Support
1. **CREATE template** in `lib/templates/projecttype-claude.md`
2. **ADD detection logic** to `lib/project.sh:detect_project_type()`
3. **UPDATE `get_project_config()`** to return template path
4. **TEST with real project** of that type

### Modifying AI Prompts
1. **LOCATE prompt building** in `lib/docs-generation.sh`
2. **MAINTAIN the structure**: system context, analysis, user directive
3. **TEST output quality** with `--force-model` flag
4. **VERIFY token efficiency** - prompts should be concise

## ANTI-PATTERNS - NEVER DO

### Code Style
- **DON'T use camelCase** in Bash - always snake_case
- **DON'T use `echo`** for user output - use `print_color` or `printf`
- **DON'T parse JSON with sed** when jq is available
- **DON'T use global variables** without `readonly` or `local` declaration

### Error Handling
- **DON'T silently fail** - always report errors
- **DON'T use `exit` directly** - use `error_exit` function
- **DON'T ignore pipe failures** - always use `set -o pipefail`
- **DON'T assume commands exist** - check with `command -v`

### AI Integration
- **DON'T call Claude directly** - use `generate_with_claude()`
- **DON'T exceed context limits** - check file sizes before sending
- **DON'T regenerate unchanged content** - use incremental updates
- **DON'T ignore rate limits** - implement exponential backoff

## ENVIRONMENT AND CONFIGURATION

### Required Environment Variables
- `CLAUDUX_VERBOSE`: Set to 1 for verbose output
- `FORCE_MODEL`: Override default Claude model
- `NO_COLOR`: Disable colored output

### Configuration Files
- **Project config**: `claudux.json` in project root
- **Docs map**: `docs-map.md` for structure planning
- **VitePress config**: `docs/.vitepress/config.ts`

### File Locations
- **Generated docs**: Always in `docs/` directory
- **Lock files**: `/tmp/claudux.lock`
- **Temp files**: Created with `mktemp`, cleaned on exit

## SECURITY CONSIDERATIONS

- **NEVER log sensitive information** from analyzed code
- **ALWAYS respect `.gitignore`** patterns
- **PROTECT private directories** (`private/`, `secret/`, etc.)
- **SANITIZE user input** in prompts and file paths
- **VALIDATE JSON** before parsing

## DEBUGGING

### Enable Verbose Mode
```bash
CLAUDUX_VERBOSE=1 claudux update
```

### Check Dependencies
```bash
claudux debug
```

### Test Specific Model
```bash
claudux update --force-model sonnet
```

### Dry Run Cleanup
```bash
claudux clean --dry-run
```

## CRITICAL GOTCHAS

1. **macOS vs Linux differences**: `md5` vs `md5sum`, `sed -i` syntax
2. **Symlink loops**: Max depth 10 in `resolve_script_path()`
3. **Lock file races**: Use `flock` when available
4. **VitePress port conflicts**: Scan 3000-3100 range
5. **Claude context limits**: 200K tokens max per request
6. **JSON parsing fallbacks**: jq not always available
7. **Background process cleanup**: Must trap all exit signals

## COMMIT MESSAGE FORMAT

Follow conventional commits:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation only
- `refactor:` Code restructuring
- `test:` Test additions/changes
- `chore:` Maintenance tasks

Example: `feat(templates): add Django project support`

---

**When modifying this project, respect its Unix philosophy: do one thing well, make it modular, and handle errors gracefully.**