[Home](/) > Troubleshooting

# Troubleshooting Guide

This guide helps you resolve common issues with Claudux.

## Installation Problems

### Command Not Found

**Problem:** After installing Claudux, the command isn't recognized.

**Solution 1:** Add npm global bin to PATH:
```bash
export PATH="$PATH:$(npm config get prefix)/bin"
echo 'export PATH="$PATH:$(npm config get prefix)/bin"' >> ~/.bashrc
source ~/.bashrc
```

**Solution 2:** Use npx instead:
```bash
npx claudux update
```

### Permission Denied

**Problem:** EACCES error during global installation.

**Solution:** Configure npm to use user directory:
```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
npm install -g claudux
```

### Module Not Found

**Problem:** Error about missing lib files.

**Solution:** Reinstall Claudux:
```bash
npm uninstall -g claudux
npm install -g claudux
```

## Claude CLI Issues

### Not Authenticated

**Problem:** "Claude CLI not authenticated" error.

**Solution:**
```bash
# Login to Claude
claude login

# Verify authentication
claude config get
```

### API Key Invalid

**Problem:** Authentication failures.

**Solution:**
1. Check Claude Code subscription is active
2. Re-authenticate:
```bash
claude logout
claude login
```

### Rate Limit Errors

**Problem:** "Rate limit exceeded" messages.

**Solution:**
- Wait 5-10 minutes
- Use a different model: `--force-model haiku`
- Check API status

## Generation Problems

### No Documentation Generated

**Problem:** Command runs but no docs created.

**Checklist:**
```bash
# 1. Check Claude is working
claude --version

# 2. Verify project detection
claudux check

# 3. Check for lock files
ls -la /tmp/claudux*.lock
rm /tmp/claudux*.lock  # if found

# 4. Run with verbose output
claudux update -vv
```

### Incomplete Documentation

**Problem:** Some files missing or incomplete.

**Solution:**
```bash
# Clean and regenerate
claudux clean
claudux update

# Or force recreation
claudux recreate
```

### Wrong Project Type Detected

**Problem:** Documentation doesn't match project.

**Solution 1:** Override in config:
```json
// docs-ai-config.json
{
  "projectType": "react"
}
```

**Solution 2:** Force type:
```bash
claudux update --project-type react
```

## VitePress Issues

### Server Won't Start

**Problem:** `claudux serve` fails.

**Solution 1:** Check port availability:
```bash
lsof -i :5173
# Kill process if needed
kill -9 <PID>
```

**Solution 2:** Use different port:
```bash
VITE_PORT=3000 claudux serve
```

**Solution 3:** Reinstall dependencies:
```bash
cd docs
rm -rf node_modules package-lock.json
npm install
npm run dev
```

### Build Failures

**Problem:** VitePress build errors.

**Solution:**
```bash
cd docs
# Clear cache
rm -rf .vitepress/cache
# Reinstall
npm ci
# Try building
npm run build
```

### Missing Sidebar

**Problem:** Sidebar not showing on pages.

**Solution:** Check config.ts has root path:
```typescript
sidebar: {
  '/': [
    // sidebar items
  ]
}
```

## Cleanup Issues

### Protected Files Deleted

**Problem:** Important files removed during cleanup.

**Recovery:**
```bash
# Restore from git
git checkout -- docs/

# Add protection
echo "docs/important/**" >> .clauduxignore
```

**Prevention:** Use protection markers:
```markdown
<!-- CLAUDUX:PROTECTED:START -->
Content to protect
<!-- CLAUDUX:PROTECTED:END -->
```

### Cleanup Not Working

**Problem:** Obsolete files not being removed.

**Solution:** Lower threshold:
```bash
claudux clean --threshold 0.9
```

## Link Validation Issues

### False Positive Broken Links

**Problem:** Valid links reported as broken.

**Solution:** Check link format:
```markdown
# Correct formats
[Link](/guide/installation)
[Link](../api/cli)
[Link](#section)

# Incorrect
[Link](guide/installation)  # Missing leading /
[Link](/guide/installation.md)  # Don't include .md
```

### External Links Timeout

**Problem:** External link validation fails.

**Solution:** Increase timeout:
```bash
claudux validate --external --timeout 10000
```

## Performance Issues

### Generation Too Slow

**Problem:** Documentation takes too long to generate.

**Solutions:**

1. Use faster model:
```bash
claudux update --force-model haiku
```

2. Focus generation:
```bash
claudux update -m "Only update API documentation"
```

3. Clean first:
```bash
claudux clean --force
claudux update
```

### High Memory Usage

**Problem:** Process uses excessive memory.

**Solution:** Process in smaller chunks:
```bash
# Document subdirectories separately
cd src && claudux update
cd ../lib && claudux update
```

## Error Messages

### "Context limit exceeded"

**Problem:** Codebase too large for single request.

**Solutions:**
- Document sections separately
- Exclude large files in `.clauduxignore`
- Use focused updates

### "Lock file exists"

**Problem:** Previous run didn't complete.

**Solution:**
```bash
# Remove stale lock
rm /tmp/claudux-*.lock
# Try again
claudux update
```

### "No such file or directory"

**Problem:** Missing required files.

**Solution:**
```bash
# Verify working directory
pwd
# Check project structure
ls -la
# Run from project root
cd /path/to/project
claudux update
```

## Platform-Specific Issues

### macOS Issues

**SIP Restrictions:**
```bash
# If commands blocked by SIP
sudo spctl --master-disable
# Run command
sudo spctl --master-enable
```

**Homebrew Paths:**
```bash
# Add Homebrew to PATH
export PATH="/opt/homebrew/bin:$PATH"
```

### Linux Issues

**Missing Commands:**
```bash
# Install required tools
sudo apt-get update
sudo apt-get install nodejs npm git
```

**Permission Issues:**
```bash
# Fix npm permissions
sudo chown -R $(whoami) ~/.npm
```

### Windows (WSL) Issues

**Line Ending Problems:**
```bash
# Configure git
git config --global core.autocrlf input

# Convert files
dos2unix lib/*.sh
```

**Path Issues:**
```bash
# Use WSL paths, not Windows paths
cd /mnt/c/projects  # Not C:\projects
```

## Debug Techniques

### Enable Maximum Verbosity

```bash
CLAUDUX_VERBOSE=2 claudux update -vv 2>&1 | tee debug.log
```

### Trace Execution

```bash
bash -x $(which claudux) update
```

### Check Environment

```bash
# Show all Claudux variables
env | grep CLAUDUX

# Check system
claudux check
```

### Test Individual Modules

```bash
# Source and test module
source /usr/local/lib/node_modules/claudux/lib/project.sh
detect_project_type
```

## Getting More Help

If these solutions don't resolve your issue:

1. **Search existing issues:** https://github.com/leokwan/claudux/issues
2. **Open new issue** with:
   - Error message
   - System info (`claudux check` output)
   - Steps to reproduce
   - Debug log

3. **Ask in discussions:** https://github.com/leokwan/claudux/discussions

## Quick Fixes Reference

| Problem | Quick Fix |
|---------|-----------|
| Command not found | `export PATH="$PATH:$(npm config get prefix)/bin"` |
| Not authenticated | `claude login` |
| Lock file exists | `rm /tmp/claudux*.lock` |
| Port in use | `VITE_PORT=3000 claudux serve` |
| Wrong project type | Add `projectType` to docs-ai-config.json |
| Slow generation | Use `--force-model haiku` |
| Files deleted | Add to `.clauduxignore` |
| Broken links | Run `claudux repair` |