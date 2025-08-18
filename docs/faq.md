[Home](/) > FAQ

# Frequently Asked Questions

## General Questions

### What is Claudux?

Claudux is a Bash-based CLI tool that uses Claude AI to automatically generate and maintain comprehensive documentation for your codebase. It combines AI-powered content generation with VitePress to create beautiful, searchable documentation sites.

### How is Claudux different from other documentation generators?

Unlike traditional generators that extract comments or use templates, Claudux:
- Uses AI to understand your code semantically
- Generates cohesive, narrative documentation
- Maintains consistency across all pages
- Updates intelligently without losing custom content
- Works with any programming language

### What do I need to use Claudux?

Requirements:
- Node.js 18 or higher
- Claude CLI installed and authenticated
- A Claude Code subscription
- Bash shell (macOS, Linux, or WSL on Windows)

### Is Claudux free to use?

Claudux itself is open-source and free. However, it requires a Claude Code subscription for the AI generation capabilities.

## Installation Issues

### "Command not found" after installation

Add npm global bin directory to your PATH:

```bash
export PATH="$PATH:$(npm config get prefix)/bin"
```

Add this to your shell profile (`~/.bashrc`, `~/.zshrc`) for persistence.

### Permission denied during npm install

Use npm's user directory:

```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
npm install -g claudux
```

### Claude CLI not authenticated

Authenticate with Claude:

```bash
claude login
```

You need a valid Claude Code subscription.

## Usage Questions

### How often should I update documentation?

Recommended frequency:
- After significant feature additions
- Before releases
- Weekly for active projects
- After major refactoring

### Can I customize the generated documentation?

Yes! Multiple ways:
1. Create `CLAUDE.md` with project-specific instructions
2. Use `docs-ai-config.json` for configuration
3. Add protection markers for custom content
4. Modify VitePress configuration after generation

### How do I protect custom content?

Use protection markers:

```markdown
<!-- CLAUDUX:PROTECTED:START -->
Your custom content here
<!-- CLAUDUX:PROTECTED:END -->
```

Or add patterns to `.clauduxignore`:
```
docs/custom/**
*-manual.md
```

### What project types are supported?

Claudux auto-detects:
- React/Next.js
- iOS/Swift
- Python
- Rust
- Go
- Ruby/Rails
- Android
- Flutter
- Vue/Angular
- Generic JavaScript/TypeScript

### Can I use Claudux with monorepos?

Yes! Run Claudux in each package directory or at the root for comprehensive docs:

```bash
# Document entire monorepo
cd monorepo-root
claudux update

# Or document specific packages
cd packages/package-1
claudux update
```

## Troubleshooting

### Documentation not generating

Check these:
1. Claude CLI authenticated: `claude config get`
2. Project has source files
3. Sufficient disk space
4. No lock files: `rm /tmp/claudux*.lock`

### Broken links after generation

Run link repair:
```bash
claudux repair
```

Or validate and fix manually:
```bash
claudux validate
```

### VitePress server won't start

Port conflict resolution:
```bash
# Use different port
VITE_PORT=3000 claudux serve

# Or kill existing process
lsof -i :5173
kill <PID>
```

### Cleanup deleted important files

Restore from git:
```bash
git checkout -- docs/important-file.md
```

Add to protection:
```bash
echo "docs/important-file.md" >> .clauduxignore
```

## Configuration

### How do I change the AI model?

Set environment variable:
```bash
export FORCE_MODEL=sonnet  # or opus, haiku
claudux update
```

Or per command:
```bash
claudux update --force-model opus
```

### Can I disable colored output?

Yes:
```bash
export NO_COLOR=1
claudux update
```

### How do I increase verbosity?

Multiple levels:
```bash
claudux update -v      # Verbose
claudux update -vv     # Very verbose
CLAUDUX_VERBOSE=2 claudux update  # Debug level
```

## Advanced Usage

### Can I use Claudux in CI/CD?

Yes! Example GitHub Actions:

```yaml
- name: Update Docs
  run: |
    npm install -g claudux
    claudux update --force-model sonnet
  env:
    CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
```

### How do I create custom templates?

1. Create template files:
```bash
lib/templates/myframework-config.json
lib/templates/myframework-claude.md
```

2. Add detection logic:
```bash
# In lib/project.sh
if [[ -f "myframework.config" ]]; then
    echo "myframework"
fi
```

### Can I extend Claudux functionality?

Yes! Claudux is modular:
1. Add new modules to `lib/`
2. Source in `bin/claudux`
3. Add commands to router
4. Submit PR to share!

## Performance

### Generation is slow

Speed up generation:
- Use faster model: `--force-model haiku`
- Reduce scope with focused message: `-m "Only update API docs"`
- Clean up large `docs/` folder first

### Claude API rate limits

Claudux handles rate limits automatically with exponential backoff. If persistent:
- Wait a few minutes
- Use different model
- Check Claude service status

## Security

### Is my code sent to Claude?

Yes, code content is sent to Claude's API for analysis. Claudux:
- Never logs sensitive data
- Respects `.gitignore`
- Protects private directories
- Uses secure HTTPS connections

### Can I use Claudux with proprietary code?

Check your organization's policies. Consider:
- Claude's data usage policies
- Your company's AI usage guidelines
- Using self-hosted alternatives (future feature)

## Errors

### "Failed to detect project type"

Claudux defaults to generic template. To fix:
1. Specify type in `docs-ai-config.json`
2. Ensure project files are present
3. Check detection logic matches your setup

### "Context limit exceeded"

Large codebases may exceed token limits. Solutions:
- Focus on specific directories
- Use incremental updates
- Split into multiple runs

### "VitePress build failed"

Usually configuration issues:
```bash
cd docs
npm install
npm run build
```

Check error messages for specific issues.

## Contributing

### How can I contribute?

Many ways to help:
- Report bugs
- Suggest features
- Improve documentation
- Submit PRs
- Share templates

See [Contributing Guide](/development/contributing).

### Where do I report issues?

GitHub Issues: https://github.com/leokwan/claudux/issues

### How do I request features?

Open a discussion: https://github.com/leokwan/claudux/discussions

## More Help

Still have questions?

- Read the [User Guide](/guide/)
- Check [Troubleshooting](/troubleshooting)
- Review [Examples](/examples/)
- Open an [issue](https://github.com/leokwan/claudux/issues)
- Start a [discussion](https://github.com/leokwan/claudux/discussions)