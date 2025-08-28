[Home](/) > [Guide](/guide/) > Installation

# Installation Guide

This guide walks you through installing Claudux and all its prerequisites for AI-powered documentation generation.

## System Requirements

Before installing Claudux, ensure your system meets these requirements:

### Node.js
- **Version**: Node.js ≥ 18.0.0
- **Why**: Claudux runs on Node.js and requires modern JavaScript features
- **Check**: Run `node --version` to check your current version

### Operating System
- **Supported**: macOS, Linux, Windows (with WSL recommended)
- **Why**: Claudux is a Bash-based CLI tool with Unix-style dependencies

## Prerequisites

### 1. Install Node.js

If you don't have Node.js 18+ installed:

**Option 1: Using Node Version Managers (Recommended)**

Version managers allow you to install and switch between multiple Node.js versions easily.

**Using `nvm` (Node Version Manager) - macOS/Linux:**
```bash
# Install nvm (if not already installed)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Reload your shell configuration
source ~/.bashrc  # or ~/.zshrc for macOS

# Install the latest LTS version
nvm install --lts
nvm use --lts
nvm alias default lts/*  # Set as default
```

**Using `fnm` (Fast Node Manager) - Cross-platform:**
```bash
# Install fnm (macOS/Linux)
curl -fsSL https://fnm.vercel.app/install | bash

# Or using Homebrew (macOS)
brew install fnm

# Install Node LTS
fnm install --lts
fnm use lts-latest
fnm default lts-latest
```

**Using `volta` (Fastest, Rust-based) - Cross-platform:**
```bash
# Install Volta
curl https://get.volta.sh | bash

# Install Node.js (automatically uses LTS)
volta install node
```

**Option 2: Direct Installation**

**macOS with Homebrew:**
```bash
brew install node@20  # Install Node.js 20 LTS
```

**Windows with Chocolatey:**
```powershell
choco install nodejs-lts
```

**Ubuntu/Debian via NodeSource:**
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Verify Node.js Installation:**
```bash
node --version  # Should show v18.0.0 or higher
npm --version   # Should show npm 9.x or higher
```

### 2. Install Claude CLI

Claudux requires the Claude CLI to interact with Claude AI.

**Modern npm Installation (npm 7+):**
```bash
# Install Claude CLI globally with automatic peer dependency resolution
npm install -g @anthropic-ai/claude-code --legacy-peer-deps=false

# Or if you encounter conflicts, use:
npm install -g @anthropic-ai/claude-code --force
```

**Using Package Managers:**

**pnpm (Faster & more efficient):**
```bash
# Install pnpm if not present
npm install -g pnpm

# Install Claude CLI
pnpm add -g @anthropic-ai/claude-code
```

**yarn:**
```bash
# Install yarn if not present
npm install -g yarn

# Install Claude CLI
yarn global add @anthropic-ai/claude-code
```

**bun (Fastest option):**
```bash
# Install bun (if not present)
curl -fsSL https://bun.sh/install | bash

# Install Claude CLI
bun add -g @anthropic-ai/claude-code
```

**Verify Claude CLI Installation:**
```bash
claude --version  # Should show version info

# Check installation location
which claude      # Unix/macOS
where claude      # Windows
```

### 3. Configure Claude CLI

Before using Claudux, you need to authenticate with Claude:

```bash
# Configure Claude CLI (requires Anthropic API key)
claude config

# Or check existing configuration
claude config get
```

**Getting an Anthropic API Key:**
1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Create an account or sign in
3. Go to API Keys section
4. Generate a new API key
5. Add credits to your account for Claude API usage

### 4. Optional: Install Git

While not strictly required, Git is recommended for version control:

```bash
# Check if Git is installed
git --version

# If not installed, install Git:
# - macOS: Install Xcode Command Line Tools
xcode-select --install

# - Ubuntu/Debian:
sudo apt-get update && sudo apt-get install git

# - CentOS/RHEL:
sudo yum install git
```

## Installing Claudux

### Global Installation (Recommended)

Install Claudux globally to use it anywhere:

**Using npm (with modern flags):**
```bash
# Install from npm registry with latest resolver
npm install -g claudux@latest --prefer-online

# Or install with exact version for consistency
npm install -g claudux@1.1.0 --save-exact

# Verify installation
claudux --version
```

**Using alternative package managers:**

```bash
# Using pnpm (recommended for speed)
pnpm add -g claudux

# Using yarn
yarn global add claudux

# Using bun (fastest)
bun add -g claudux
```

### Local Installation (Project-Specific)

For project-specific installations with better dependency management:

**Modern npm with workspace awareness:**
```bash
# Initialize package.json if needed
npm init -y

# Install as dev dependency (recommended for documentation tools)
npm install --save-dev claudux

# Add to package.json scripts
npm pkg set scripts.docs="claudux update"
npm pkg set scripts.docs:serve="claudux serve"

# Run via npm scripts
npm run docs
npm run docs:serve
```

**Using npx (no installation needed):**
```bash
# Run directly without installing
npx claudux@latest --version

# Generate docs without installation
npx claudux@latest update
```

**Lock file best practices:**
```bash
# Ensure reproducible installs
npm ci              # Uses package-lock.json
pnpm install --frozen-lockfile
yarn install --frozen-lockfile
```

## Verification

After installation, verify everything works correctly:

### 1. Check Claudux Installation

```bash
# Verify Claudux is installed
claudux --version  # Should show version like "claudux 1.0.0"

# Check dependencies
claudux check
```

The `claudux check` command will verify:
- ✅ Node.js version compatibility
- ✅ Claude CLI installation
- ✅ Claude CLI authentication
- ✅ Basic functionality

### 2. Test Basic Functionality

Create a test directory and run Claudux:

```bash
# Create a test project
mkdir test-claudux
cd test-claudux

# Initialize a simple Node.js project
npm init -y
echo "# Test Project" > README.md
echo "console.log('Hello world');" > index.js

# Run Claudux check
claudux check
```

Expected output:
```
📚 claudux - Test Project Documentation
Powered by Claude AI - Everything stays local

🔎 Environment check

• Node: v18.17.0
• Claude: claude-code 0.8.0
• docs/: not present (will be created on first run)
```

### 3. Generate Test Documentation

Try generating documentation for your test project:

```bash
# Generate docs (this will use Claude AI)
claudux update

# Start the documentation server
claudux serve  # Opens http://localhost:5173
```

If everything works, you should see:
1. Claude analyzing your project
2. Documentation files created in `docs/`
3. VitePress development server starting
4. Documentation site accessible at http://localhost:5173

## Common Installation Issues

### Issue: `command not found: claudux`

**Cause**: Global npm installation path not in PATH

**Solution 1 - Fix PATH (Recommended):**
```bash
# Check npm global path
npm config get prefix

# Add to shell profile based on your shell
# For bash:
echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# For zsh (macOS default):
echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# For fish:
set -U fish_user_paths (npm config get prefix)/bin $fish_user_paths
```

**Solution 2 - Reinstall with correct prefix:**
```bash
# Configure npm to use user directory
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.profile
source ~/.profile

# Reinstall claudux
npm install -g claudux
```

**Solution 3 - Use npx instead:**
```bash
# No PATH configuration needed
npx claudux --version
```

### Issue: `Claude CLI not found`

**Cause**: Claude CLI not installed or not in PATH

**Solution 1 - Verify and reinstall:**
```bash
# Check if Claude CLI is installed
npm list -g @anthropic-ai/claude-code

# Reinstall with cache clear
npm cache clean --force
npm install -g @anthropic-ai/claude-code@latest

# Verify installation
claude --version
```

**Solution 2 - Check PATH issues:**
```bash
# Find where npm installs global packages
npm config get prefix

# Check if claude binary exists
ls -la $(npm config get prefix)/bin/claude

# If exists but not in PATH, add to PATH
export PATH="$(npm config get prefix)/bin:$PATH"
```

**Solution 3 - Use different package manager:**
```bash
# Try pnpm (often resolves tricky dependencies)
pnpm add -g @anthropic-ai/claude-code

# Or use npx to run without installing
npx @anthropic-ai/claude-code --version
```

### Issue: Node.js version too old

**Cause**: Node.js version < 18.0.0

**Solution 1 - Update with version manager:**
```bash
# Using nvm
nvm install --lts
nvm use --lts
nvm alias default lts/*

# Using fnm
fnm install --lts
fnm use lts-latest
fnm default lts-latest

# Using volta
volta install node@lts
```

**Solution 2 - Check and upgrade existing Node:**
```bash
# Check current version
node --version

# If using Homebrew (macOS)
brew upgrade node

# If using apt (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Solution 3 - Use compatibility mode:**
```bash
# If stuck on older Node temporarily
npx -p node@18 claudux --version
```

### Issue: Permission denied during global install

**Cause**: Insufficient permissions for global npm packages

**Solution 1 - Change npm prefix (Best Practice):**
```bash
# Configure npm to use user directory (no sudo needed)
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global

# Add to PATH (choose your shell)
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc  # bash
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc   # zsh
source ~/.bashrc  # or ~/.zshrc

# Install without sudo
npm install -g claudux
```

**Solution 2 - Use Node Version Manager:**
```bash
# With nvm, global packages install in user space
nvm install --lts
nvm use --lts
npm install -g claudux  # No sudo needed
```

**Solution 3 - Fix npm permissions:**
```bash
# Change npm's default directory ownership
sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}

# Then install normally
npm install -g claudux
```

**Solution 4 - Use npx (No installation):**
```bash
# Run without installing globally
npx claudux@latest --version
```

**Avoid: Using sudo with npm**
```bash
# NOT RECOMMENDED - can cause permission issues later
sudo npm install -g claudux  # Avoid this
```

### Issue: Claude CLI authentication errors

**Cause**: Missing or invalid Anthropic API key

**Solution**:
```bash
# Reconfigure Claude CLI
claude config set api_key YOUR_API_KEY

# Test authentication
claude config get
```

## Environment Variables

Claudux supports several environment variables for customization:

```bash
# Set default verbosity level
export CLAUDUX_VERBOSE=1

# Force specific Claude model
export FORCE_MODEL=opus

# Disable colored output
export NO_COLOR=1
```

Add these to your shell profile (`~/.bashrc`, `~/.zshrc`) to make them persistent.

## Next Steps

Once Claudux is installed and verified:

1. **[Quick Start Tutorial →](/guide/quickstart)** - Generate your first documentation
2. **[Command Reference →](/guide/commands)** - Learn all available commands  
3. **[Configuration Guide →](/guide/configuration)** - Customize Claudux for your needs

## Getting Help

If you encounter issues not covered here:

- **Check Dependencies**: Run `claudux check` to verify your setup
- **Verbose Output**: Use `claudux -v` or `claudux -vv` for detailed logs
- **GitHub Issues**: Report bugs at [GitHub Issues](https://github.com/leojkwan/claudux/issues)
- **Documentation**: Browse the full [documentation site](/)

---

<p align="center">
  <strong>Ready to generate amazing documentation?</strong><br/>
  <a href="/guide/quickstart">Continue to Quick Start Tutorial →</a>
</p>