[Home](/) > [Guide](/guide/) > Installation

# Installation

This guide covers installing Claudux and its prerequisites on your system.

## Prerequisites

### Node.js

Claudux requires Node.js version 18.0.0 or higher.

Check your Node.js version:
```bash
node --version
```

If you need to install or update Node.js:
- **macOS**: Use [Homebrew](https://brew.sh/) (`brew install node`) or download from [nodejs.org](https://nodejs.org/)
- **Linux**: Use your package manager or [NodeSource](https://github.com/nodesource/distributions)
- **Windows**: Download from [nodejs.org](https://nodejs.org/)

### Claude CLI

Claudux requires the Claude CLI to be installed and authenticated.

Install Claude CLI:
```bash
npm install -g @anthropic-ai/claude-code
```

Authenticate with your Claude Code account:
```bash
claude login
```

Verify installation:
```bash
claude --version
claude config get model
```

## Installing Claudux

### Option 1: Install from npm (Recommended)

```bash
npm install -g claudux
```

### Option 2: Install from GitHub

```bash
npm install -g github:leokwan/claudux
```

### Option 3: Clone and Link (Development)

```bash
# Clone the repository
git clone https://github.com/leokwan/claudux.git
cd claudux

# Install globally
npm install -g .

# Or link for development
npm link
```

## Verify Installation

Check that Claudux is installed correctly:

```bash
# Check version
claudux version

# Run environment check
claudux check
```

Expected output:
```
🚀 Claudux - AI-Powered Documentation Generator

🔎 Environment check

• Node: v18.0.0 or higher
• Claude: claude-code version X.X.X
• docs/: not present (will be created on first run)
```

## Platform-Specific Notes

### macOS

Claudux is developed and tested primarily on macOS. All features work out of the box.

```bash
# Install with Homebrew (if available)
brew install node
npm install -g claudux
```

### Linux

Full compatibility with common distributions. Some commands use different utilities:
- Uses `md5sum` instead of macOS's `md5`
- Requires `realpath` for path resolution (usually pre-installed)

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nodejs npm
npm install -g claudux

# Fedora/RHEL
sudo dnf install nodejs npm
npm install -g claudux
```

### Windows (WSL)

Claudux is a Bash-based tool and requires Windows Subsystem for Linux (WSL):

1. Install WSL2: [Microsoft Documentation](https://docs.microsoft.com/en-us/windows/wsl/install)
2. Install Ubuntu or your preferred Linux distribution
3. Follow the Linux installation instructions above

```bash
# In WSL terminal
sudo apt update
sudo apt install nodejs npm
npm install -g claudux
```

### Docker

You can run Claudux in a Docker container:

```dockerfile
FROM node:18-alpine
RUN apk add --no-cache bash git
RUN npm install -g @anthropic-ai/claude-code claudux
WORKDIR /workspace
```

## Optional Dependencies

These tools enhance Claudux functionality but aren't required:

### jq (Recommended)
For reliable JSON parsing:
```bash
# macOS
brew install jq

# Linux
sudo apt install jq  # Debian/Ubuntu
sudo dnf install jq  # Fedora
```

### Git
For repository detection and git-related features:
```bash
# Usually pre-installed, but if needed:
# macOS
brew install git

# Linux
sudo apt install git
```

## Environment Variables

Configure Claudux behavior with environment variables:

```bash
# Enable verbose output
export CLAUDUX_VERBOSE=1

# Force specific Claude model
export FORCE_MODEL=opus

# Disable colored output
export NO_COLOR=1
```

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) for persistence.

## Troubleshooting Installation

### Command Not Found

If `claudux` is not found after installation:

1. Check npm global bin path:
   ```bash
   npm config get prefix
   ```

2. Add to PATH in your shell profile:
   ```bash
   export PATH="$PATH:$(npm config get prefix)/bin"
   ```

3. Reload your shell:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

### Permission Errors

If you get EACCES errors during global installation:

Option 1: Use npm's directory (recommended):
```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
npm install -g claudux
```

Option 2: Use npx (no global install):
```bash
npx claudux update
```

### Claude CLI Issues

If Claude CLI authentication fails:

1. Ensure you have a valid Claude Code subscription
2. Try logging out and back in:
   ```bash
   claude logout
   claude login
   ```

3. Check your configuration:
   ```bash
   claude config list
   ```

## Upgrading Claudux

To upgrade to the latest version:

```bash
# From npm
npm update -g claudux

# From GitHub
npm install -g github:leokwan/claudux@latest
```

Check current version:
```bash
claudux version
```

## Uninstalling

To remove Claudux from your system:

```bash
npm uninstall -g claudux
```

This only removes the Claudux CLI. Your generated documentation in `docs/` folders remains untouched.

## Next Steps

Now that Claudux is installed, you're ready to:
- Follow the [Quick Start](/guide/quickstart) tutorial
- Learn about [Commands](/guide/commands)
- Explore [Configuration](/guide/configuration) options