# Frequently Asked Questions

[Home](/) > FAQ

## What is Claudux?

Claudux is a Bash-based CLI tool that uses Claude AI and VitePress to generate comprehensive, navigable documentation from your codebase. It analyzes your project structure, code patterns, and existing documentation to create production-ready docs that stay in sync with your code.

Unlike traditional documentation generators that rely on comments or manual maintenance, Claudux understands your code context and generates meaningful content that reflects your actual implementation.

## How does it differ from other documentation generators?

**Traditional generators** (JSDoc, Sphinx, etc.):
- Rely on code comments and manual maintenance
- Generate reference docs but lack contextual understanding
- Often produce fragmented, hard-to-navigate output
- Require extensive configuration and templates

**Claudux advantages**:
- **AI-powered understanding**: Analyzes code semantics, not just syntax
- **Two-phase generation**: Plans structure first, then generates coherent content
- **Automatic navigation**: Builds VitePress sites with working breadcrumbs and search
- **Semantic obsolescence detection**: Identifies outdated content at 95% confidence
- **Zero configuration**: Works out of the box with automatic project type detection
- **Link validation**: Prevents 404 errors with built-in validation and auto-fixing

## What project types are supported?

Claudux automatically detects and optimizes for these project types:

- **iOS/Swift**: Xcode projects (`.xcodeproj`, `.xcworkspace`, `Project.swift`)
- **Next.js**: React frameworks with Next.js configuration
- **React**: Standard React applications
- **Node.js**: Server-side JavaScript with Node.js types
- **JavaScript**: General JavaScript projects with `package.json`
- **Rust**: Projects with `Cargo.toml`
- **Python**: Projects with `pyproject.toml`, `setup.py`, or `requirements.txt`
- **Go**: Projects with `go.mod`
- **Java**: Maven (`pom.xml`) or Gradle (`build.gradle`) projects
- **Generic**: Any other project type with intelligent fallbacks

The detection logic prioritizes more specific frameworks before falling back to generic types (e.g., Next.js is detected before React).

## Does my code leave my machine?

**No, with caveats.** Here's exactly what happens:

**What stays local**:
- Your source code files are processed locally
- The generated documentation files remain on your machine
- No code is uploaded to external services by Claudux itself

**What goes to Claude**:
- **Analysis prompts**: Claudux sends structured prompts about your project to Claude AI
- **Code context**: Selected code snippets may be included in prompts for analysis
- **Project structure**: Information about your project's organization and patterns

**Privacy controls**:
- **Protected paths**: `notes/`, `private/`, `.git/`, `node_modules/` are automatically excluded
- **Protected files**: `*.env`, `*.key`, `*.pem`, `*.p12`, `*.keystore` files are skipped
- **Skip markers**: Use `<!-- skip -->` / `<!-- /skip -->` to protect sensitive content sections
- **Local processing**: All file operations and Git integration happen locally

You control exactly what information is analyzed by using content protection features.

## Can I customize the output?

Yes, Claudux offers multiple customization levels:

**Automatic customization**:
- Project type detection determines appropriate templates and structure
- Logo/icon detection for iOS apps and web projects
- Dynamic VitePress configuration based on your project structure

**Configuration files**:
- `docs-ai-config.json`: Project metadata and feature toggles
- `CLAUDE.md`: AI assistant instructions and coding patterns
- `docs-map.md`: Custom documentation structure planning

**Template customization**:
- Templates are located in `lib/templates/` for each project type
- You can modify existing templates or create new ones
- Project-specific patterns are learned from your actual codebase

**Runtime customization**:
- Use `-m "directive"` or `--with "directive"` to provide focused generation instructions
- Set `FORCE_MODEL=sonnet` or `FORCE_MODEL=opus` to choose Claude model
- Use `CLAUDUX_VERBOSE=1` for detailed output

## How much does it cost?

Claudux usage costs depend on your Claude API usage through the Claude CLI:

**Typical costs per run**:
- **Claude Opus**: ~$0.05 per documentation update
- **Claude Sonnet**: ~$0.01 per documentation update

**Cost factors**:
- Project size (more files = higher cost)
- Update frequency (incremental updates are cheaper)
- Model choice (Opus is more expensive but more capable)
- Content complexity (detailed analysis requires more tokens)

**Cost optimization tips**:
- Use `FORCE_MODEL=sonnet` for faster, cheaper updates
- Use focused directives (`-m "message"`) for targeted updates instead of full regeneration
- Leverage incremental updates rather than `recreate` command
- Protect unnecessary files with skip markers to reduce analysis scope

You pay only for Claude API usage - Claudux itself is free and open source.

## Can I use different Claude models?

Yes, Claudux supports model selection:

**Available models**:
- **Opus** (default): Most powerful, best for complex projects and comprehensive analysis
- **Sonnet**: Fast and capable, good for most projects and frequent updates

**Setting model**:
```bash
# Environment variable (persistent)
export FORCE_MODEL=sonnet
claudux update

# One-time override
FORCE_MODEL=opus claudux update

# Via Claude CLI config
claude config set model sonnet
```

**Model characteristics**:
- **Opus**: 60-120 seconds per run, higher cost, most thorough analysis
- **Sonnet**: 30-60 seconds per run, lower cost, good balance of speed and quality

**When to use which**:
- **Opus**: Complex codebases, initial documentation creation, comprehensive refactoring
- **Sonnet**: Regular updates, simple projects, iterative improvements

The model setting is respected across all Claudux commands that interact with Claude AI.

## How do I protect sensitive content?

Claudux provides multiple layers of content protection:

**Automatic protection**:
```bash
# These directories are automatically excluded
notes/
private/
.git/
node_modules/
vendor/
target/
build/
dist/

# These file types are automatically excluded
*.env
*.key
*.pem
*.p12
*.keystore
```

**Skip markers** (syntax varies by file type):

```markdown
<!-- skip -->
Sensitive markdown content here
<!-- /skip -->
```

```javascript
// skip
const API_KEY = "secret-key-here";
// /skip
```

```python
# skip
DATABASE_PASSWORD = "super-secret"
# /skip
```

```swift
// skip
private let secretKey = "confidential"
// /skip
```

**Configuration-based exclusion**:
```json
// docs-ai-config.json
{
  "excludePaths": ["internal/", "secrets/"],
  "excludePatterns": ["*.secret", "test-data/"]
}
```

**Verification**:
- Use `claudux update -v` to see what files are being analyzed
- Review generated prompts in verbose mode to ensure sensitive content is excluded
- Check the content protection logic in `lib/content-protection.sh`

## How do I handle large codebases?

Claudux is designed to handle large projects efficiently:

**Automatic optimizations**:
- **Incremental processing**: Only analyzes changed files when possible
- **Semantic chunking**: Breaks large codebases into logical sections
- **Context limits**: Respects Claude's 200K token limit per request
- **File filtering**: Excludes binary files, dependencies, and generated content

**Manual optimizations**:
```bash
# Use focused directives for targeted updates
claudux update -m "Update API documentation only"

# Use faster model for regular updates
FORCE_MODEL=sonnet claudux update

# Exclude large directories
echo "large-dataset/" >> .gitignore  # Respects gitignore patterns
```

**Project structure tips**:
- Keep documentation source files organized in logical directories
- Use skip markers for large auto-generated files
- Consider splitting very large monorepos into multiple documentation sites
- Place large binary assets in excluded directories

**Performance indicators**:
- Projects with <1000 files: ~1-2 minutes
- Projects with 1000-5000 files: ~3-5 minutes  
- Projects with >5000 files: May require focused updates or exclusions

If you encounter timeout issues, use focused directives or exclude large directories that don't need documentation.