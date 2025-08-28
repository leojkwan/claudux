# Troubleshooting Guide

[Home](/) > Troubleshooting

This guide covers common issues and solutions when using Claudux. Most problems fall into a few categories with straightforward fixes.

## Claude CLI Issues

### "Claude Code CLI not found" Error

**Error message:**
```
ERROR: Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code
```

**Solutions:**
```bash
# Install Claude CLI globally
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version

# Check if it's in your PATH
which claude

# Alternative: use npx (doesn't require global install)
npx @anthropic-ai/claude-code --version
```

**If still not working:**
```bash
# Check Node.js version (requires v18+)
node --version

# Reinstall with clear npm cache
npm cache clean --force
npm install -g @anthropic-ai/claude-code

# macOS: Fix permissions if needed
sudo npm install -g @anthropic-ai/claude-code
```

### Claude Authentication Issues

**Error message:**
```
ERROR: Claude CLI authentication failed
```

**Solutions:**
```bash
# Check authentication status
claude config get

# Re-authenticate if needed
claude config set api-key YOUR_API_KEY

# Test authentication
claude config get model
```

## Installation and Permission Issues

### Permission Denied During Install

**Error message:**
```
EACCES: permission denied, mkdir '/usr/local/lib/node_modules'
```

**Solutions:**
```bash
# Option 1: Use a Node version manager (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install node
npm install -g claudux

# Option 2: Change npm default directory
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
npm install -g claudux

# Option 3: Use sudo (not recommended for security)
sudo npm install -g claudux
```

### "Command not found: claudux"

**After successful npm install:**

```bash
# Check if npm global bin is in PATH
npm config get prefix
echo $PATH

# Add npm bin to PATH if missing
echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Or use the full path temporarily
$(npm config get prefix)/bin/claudux --version
```

## Server and Port Issues

### Port Conflicts (5173-5190 Range)

**Error message:**
```
Error: Port 5173 is already in use
```

**Automatic resolution:**
Claudux automatically scans ports 5173-5190 and finds an available one. If all ports are busy:

```bash
# Kill processes using docs ports
lsof -ti:5173-5190 | xargs kill -9

# Or specify a different port range in VitePress config
cd docs
npm run docs:dev -- --port 3000
```

**Manual port checking:**
```bash
# Check what's using port 5173
lsof -i :5173

# Find available ports in range
for port in {5173..5190}; do
  ! nc -z localhost $port && echo "Port $port is available"
done
```

### VitePress Server Won't Start

**Common issues:**

```bash
# 1. Missing dependencies
cd docs
npm install

# 2. Corrupted node_modules
rm -rf docs/node_modules docs/package-lock.json
cd docs && npm install

# 3. Check VitePress configuration
cat docs/.vitepress/config.ts

# 4. Verify docs:dev script exists
cd docs && npm run 2>/dev/null | grep docs:dev
```

## Platform-Specific Issues

### macOS vs Linux Differences

**MD5 Command Differences:**

**Error on Linux:**
```
md5: command not found
```

**Error on macOS:**
```  
md5sum: command not found
```

**Claudux handles this automatically**, but if you see these errors:

```bash
# On macOS (install GNU tools)
brew install coreutils
# Now both md5 and md5sum are available

# On Linux (install BSD tools if needed)
sudo apt-get install bsdmainutils  # For md5 command
```

**sed -i Syntax Differences:**

Claudux uses portable sed syntax, but if you encounter issues:

```bash
# macOS requires backup extension
sed -i '' 's/old/new/g' file

# Linux doesn't need backup extension  
sed -i 's/old/new/g' file
```

## Lock File and Process Issues

### Lock File Race Conditions

**Error message:**
```
WARNING: Another claudux instance is already running (PID: 12345)
If this is incorrect, remove the lock file: /tmp/claudux-abc123.lock
```

**Solutions:**
```bash
# Check if process is actually running
ps aux | grep claudux

# Remove stale lock file manually
rm -f /tmp/claudux-*.lock

# Or let claudux clean it automatically
claudux update  # Will remove stale locks

# Force removal if PID doesn't exist
kill -0 12345 2>/dev/null || rm -f /tmp/claudux-*.lock
```

### Background Process Cleanup Issues

**Symptoms:**
- Claude processes remain after Ctrl+C
- VitePress server keeps running after exit
- High CPU usage from orphaned processes

**Solutions:**
```bash
# Kill all claudux-related processes
pkill -f claudux
pkill -f "vitepress.*docs"

# Clean exit handler test
trap 'echo "Cleaning up..."; kill 0' EXIT

# Check for zombie processes
ps aux | grep -E "(claude|vitepress)" | grep -v grep
```

## Symlink and Path Issues

### Symlink Loop Detection

**Error message:**
```
ERROR: Too many symlink levels (possible loop)
```

**This occurs when:**
- Symlinks create circular references
- Maximum symlink depth (10) is exceeded

**Solutions:**
```bash
# Find problematic symlinks
find . -type l -exec file {} \; | grep -E "(broken|loop)"

# Check symlink chain
ls -la $(which claudux)
file $(which claudux)

# Reinstall to fix corrupted symlinks
npm uninstall -g claudux
npm install -g claudux
```

### Working Directory Issues

**Error message:**
```
ERROR: Working directory does not exist: /path/to/project
```

**Solutions:**
```bash
# Ensure you're in a valid directory
pwd
ls -la

# Avoid running from network drives or fuse mounts
cd ~/local-projects/your-project

# Check directory permissions
ls -ld .
```

## Claude Context and Token Limits

### Context Limit Exceeded

**Error message:**
```
Error: Context length exceeded (200K tokens maximum)
```

**Solutions:**

```bash
# Use focused directives to reduce context
claudux update -m "Update only API documentation"

# Exclude large files with skip markers
echo "# skip" >> large-file.py
echo "large generated content..." >> large-file.py  
echo "# /skip" >> large-file.py

# Use .gitignore patterns (respected by claudux)
echo "*.log" >> .gitignore
echo "test-data/" >> .gitignore

# Split large updates into focused chunks
claudux update -m "Update frontend components only"
claudux update -m "Update backend API docs only"
```

### JSON Parsing Issues

**When jq is not available:**

**Error message:**
```
jq: command not found
```

**Claudux provides fallbacks**, but for better reliability:

```bash
# Install jq for reliable JSON parsing
# macOS
brew install jq

# Ubuntu/Debian  
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq

# Verify installation
jq --version

# Test JSON parsing
echo '{"version": "1.0.0"}' | jq -r '.version'
```

**Manual JSON parsing fallback:**
```bash
# If jq fails, claudux uses grep/sed fallback
version=$(grep '"version"' package.json | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
```

## Debug and Diagnostic Commands

### Environment Check

```bash
# Check all dependencies and configuration
claudux check

# Detailed environment info
claudux --check

# Version information
claudux --version
node --version
claude --version

# Check Node.js version (requires v18+)
node --version | cut -d. -f1 | sed 's/v//'
```

### Verbose Mode

```bash
# Enable detailed logging
CLAUDUX_VERBOSE=1 claudux update

# Maximum verbosity (shows all tool calls)
CLAUDUX_VERBOSE=2 claudux update

# Or use short flags
claudux -v update     # verbose
claudux -vv update    # very verbose
claudux -q update     # quiet (errors only)
```

### Test Specific Model

```bash
# Test with different Claude models
claudux update --force-model sonnet
FORCE_MODEL=opus claudux update

# Test with dry run (no actual changes)
claudux clean --dry-run
```

### Link Validation Debug

```bash
# Check for broken links
claudux validate

# Auto-fix broken links
claudux repair

# Manual link checking
find docs -name "*.md" -exec grep -l "](.*)" {} \;
```

## Recovery Procedures

### Complete Reset

If nothing else works:

```bash
# 1. Clean all generated files
claudux clean
rm -rf docs/

# 2. Clear npm cache
npm cache clean --force

# 3. Reinstall claudux
npm uninstall -g claudux
npm install -g claudux

# 4. Verify installation
claudux check

# 5. Start fresh
claudux recreate
```

### Backup and Recovery

```bash
# Backup current docs before major operations
cp -r docs docs-backup-$(date +%Y%m%d)

# Recovery from backup
rm -rf docs
cp -r docs-backup-20241201 docs

# Git-based recovery
git checkout HEAD -- docs/
git clean -fd docs/
```

## Getting Help

### Log Collection

```bash
# Generate diagnostic information
claudux check > claudux-debug.log 2>&1
CLAUDUX_VERBOSE=2 claudux update >> claudux-debug.log 2>&1

# System information
uname -a >> claudux-debug.log
node --version >> claudux-debug.log
npm --version >> claudux-debug.log
claude --version >> claudux-debug.log 2>/dev/null || echo "Claude CLI not found" >> claudux-debug.log
```

### Common Debug Commands

```bash
# Check file permissions
ls -la $(which claudux)
ls -la ~/.npm-global/bin/ 2>/dev/null || ls -la /usr/local/bin/

# Check PATH
echo $PATH | tr ':' '\n' | grep -E "(npm|node)"

# Test Claude CLI directly
echo "Test prompt" | claude --model sonnet

# Validate project structure
find . -maxdepth 2 -name "*.md" -o -name "package.json" -o -name "*.py" -o -name "*.js"
```

### Reporting Issues

When reporting issues, include:

1. **Error message** (complete output)
2. **Environment info** (OS, Node.js version, Claude CLI version)
3. **Steps to reproduce** 
4. **Project type** (detected by `claudux check`)
5. **Relevant configuration files** (`docs-ai-config.json`, `.claudux.json`)

```bash
# Generate complete diagnostic report
{
  echo "=== Claudux Diagnostic Report ==="
  echo "Date: $(date)"
  echo "OS: $(uname -a)"
  echo "Node: $(node --version)"
  echo "NPM: $(npm --version)"
  echo "Claude CLI: $(claude --version 2>/dev/null || echo 'Not found')"
  echo "Claudux: $(claudux --version)"
  echo "Working directory: $(pwd)"
  echo "=== Project Detection ==="
  claudux check
  echo "=== File Structure ==="
  ls -la
  echo "=== Error Log ==="
  CLAUDUX_VERBOSE=2 claudux update
} > claudux-issue-report.log 2>&1
```

This comprehensive troubleshooting guide covers the most common issues encountered with Claudux. Most problems can be resolved by following the appropriate section above.