# Troubleshooting

Common issues and solutions when using claudux.

## Installation Issues

### Claude CLI Not Found

**Error:**
```
ERROR: Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code
```

**Solution:**
```bash
npm install -g @anthropic-ai/claude-cli
claude config  # Follow authentication prompts
claudux check  # Verify installation
```

### Node Version Issues

**Error:**
```
ERROR: Node.js v18+ is required (found v16.14.0)
```

**Solution:**
```bash
# Using nvm
nvm install 18
nvm use 18

# Using fnm  
fnm install 18
fnm use 18

# Verify
node --version  # Should show v18+
```

### Permission Errors

**Error:**
```
EACCES: permission denied, mkdir '/usr/local/lib/node_modules/claudux'
```

**Solution:**
```bash
# Fix npm permissions
sudo chown -R $(whoami) ~/.npm

# Or use nvm to avoid system-wide installation
nvm install 18 && nvm use 18
npm install -g claudux
```

## Authentication Issues

### Claude Authentication Failed

**Error:**
```
ERROR: Claude authentication failed
```

**Solution:**
```bash
# Re-authenticate with Claude
claude config

# Verify authentication
claude config get

# Test Claude access
claude config get model
```

### API Key Issues

**Error:**
```
Unauthorized: Invalid API key
```

**Solution:**
1. Visit [Claude Console](https://console.anthropic.com/)
2. Generate new API key
3. Re-authenticate: `claude config`
4. Verify: `claude config get`

## Generation Issues

### Empty or Incomplete Documentation

**Symptoms:**
- Documentation generates but has minimal content
- Missing expected sections
- Generic placeholder content

**Diagnosis:**
```bash
claudux check  # Verify environment
```

**Solutions:**

1. **Project type detection issue:**
   ```bash
   # Check detected type
   claudux update -m "Debug: show detected project type and structure"
   
   # Override if incorrect
   echo '{"project": {"type": "react"}}' > claudux.json
   claudux update
   ```

2. **Insufficient source code:**
   ```bash
   # Ensure source files exist
   ls src/ lib/ components/  # Check for source directories
   ```

3. **Model selection:**
   ```bash
   # Try more capable model
   FORCE_MODEL=opus claudux update
   ```

### Generation Timeout

**Error:**
```
Claude generation timed out after 90 seconds
```

**Solutions:**

1. **Use faster model:**
   ```bash
   FORCE_MODEL=sonnet claudux update
   ```

2. **Focused generation:**
   ```bash
   claudux update -m "Update only the API documentation"
   ```

3. **Network issues:**
   ```bash
   # Check internet connectivity
   curl -I https://api.anthropic.com
   
   # Retry generation
   claudux update
   ```

## Documentation Issues

### Broken Internal Links

**Error:**
```
⚠️  Link validation found issues. Some documentation links may be broken.
```

**Auto-fix:**
```bash
claudux update -m "Fix broken links and create missing pages"
```

**Manual fix:**
```bash
# Preview to identify broken links  
claudux serve  # Check localhost:5173

# Fix specific issues
claudux update -m "Create missing API reference page"
```

### Missing VitePress Configuration

**Error:**
```
Failed to load VitePress config
```

**Solution:**
```bash
# Regenerate VitePress setup
claudux recreate

# Or check if config exists
ls docs/.vitepress/config.ts

# If missing, regenerate
claudux update
```

### Server Won't Start

**Error:**
```
ERROR: Failed to start VitePress dev server
```

**Solutions:**

1. **Port conflict:**
   ```bash
   # Check what's using port 5173
   lsof -i :5173
   
   # Kill conflicting process
   kill <PID>
   
   # Restart server
   claudux serve
   ```

2. **Missing dependencies:**
   ```bash
   cd docs/
   npm install
   cd ..
   claudux serve
   ```

3. **Corrupted node_modules:**
   ```bash
   cd docs/
   rm -rf node_modules package-lock.json
   npm install
   cd ..
   claudux serve
   ```

## Environment Issues

### Git Repository Required

**Error:**
```
⚠️  No git repository found. Are you in the right directory?
```

**Solution:**
```bash
# Initialize git repository
git init
git add .
git commit -m "Initial commit"

# Then run claudux
claudux update
```

### Working Directory Issues

**Error:**
```
ERROR: Working directory does not exist
```

**Solution:**
```bash
# Ensure you're in a valid directory
pwd
ls -la

# Navigate to your project root
cd /path/to/your/project
claudux update
```

## Performance Issues

### Slow Generation

**Symptoms:**
- Generation takes longer than 5 minutes
- AI appears to hang during analysis

**Solutions:**

1. **Check model selection:**
   ```bash
   # Use faster model
   FORCE_MODEL=sonnet claudux update
   ```

2. **Focused updates:**
   ```bash
   # Target specific areas
   claudux update -m "Update only the installation guide"
   ```

3. **Project size:**
   ```bash
   # For very large codebases, consider focused updates
   claudux update -m "Document only public API, skip internal modules"
   ```

### Memory Issues

**Error:**
```
JavaScript heap out of memory
```

**Solution:**
```bash
# Increase Node memory limit
export NODE_OPTIONS="--max_old_space_size=4096"
claudux update
```

## Debugging Tools

### Environment Check

```bash
claudux check
```

**Output includes:**
- Node.js version and availability
- Claude CLI installation status
- Documentation directory status
- Git repository validation

### Verbose Output

All claudux commands are verbose by default. For additional debugging:

```bash
# Check git status before generation
git status

# Monitor file changes during generation
ls -la docs/ && claudux update && ls -la docs/

# Review generated VitePress config
cat docs/.vitepress/config.ts
```

### Log Analysis

Check Claude CLI logs for detailed error information:

```bash
# Claude CLI maintains logs of API interactions
claude config get  # Shows configuration and status
```

## Getting Help

### Community Support

1. **GitHub Issues**: [Report bugs and request features](https://github.com/leojkwan/claudux/issues)
2. **Documentation**: This site provides comprehensive guidance
3. **Examples**: Check the [examples section](/examples/) for common patterns

### Diagnostic Information

When reporting issues, include:

```bash
# Environment details
claudux --version
claudux check
node --version  
claude --version

# Project context
cat claudux.json       # If exists
head -20 package.json  # Project metadata
git status             # Repository state
```

### Error Recovery

**Safe recovery workflow:**
```bash
# 1. Check environment
claudux check

# 2. Verify Claude authentication  
claude config get

# 3. Start fresh if needed
claudux recreate

# 4. Regenerate with basic approach
claudux update

# 5. If still failing, try different model
FORCE_MODEL=sonnet claudux update
```

This troubleshooting guide covers the most common issues encountered when using claudux across different environments and project types.