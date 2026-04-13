# Installation

## Prerequisites

**Node.js ≥ 18.0.0**  
Download from [nodejs.org](https://nodejs.org/) or use a version manager:

```bash
# Using nvm
nvm install 18
nvm use 18

# Using fnm
fnm install 18
fnm use 18
```

**AI Backend CLI**

claudux supports Claude (default) and Codex as backends. Install at least one:

```bash
# Claude (default backend)
npm install -g @anthropic-ai/claude-cli
claude config  # authenticate

# Codex (alternative backend)
npm install -g @openai/codex
# Set CLAUDUX_BACKEND=codex to use
```

Verify your setup:
```bash
claudux check  # shows active backend and CLI status
```

## Install Claudux

### Global Installation (Recommended)

```bash
npm install -g claudux
```

Verify installation:
```bash
claudux --version
```

### Local Installation

For project-specific usage:

```bash
# As dev dependency
npm install --save-dev claudux

# Run with npx
npx claudux update
```

### From Source

```bash
git clone https://github.com/leojkwan/claudux.git
cd claudux
npm install -g .
```

## Environment Check

Verify your environment is properly configured:

```bash
claudux check
```

This command validates:
- Node.js version and availability
- Active backend (Claude or Codex)
- Backend CLI installation and authentication
- Documentation directory status

Example output:
```
🔎 Environment check

• Node: v18.17.0
• Backend: claude
• Claude CLI: installed
• Model: sonnet
• docs/: not present (will be created on first run)
```

## Troubleshooting

**Backend CLI not found**
```bash
# For Claude (default)
npm install -g @anthropic-ai/claude-cli
claude config

# For Codex
npm install -g @openai/codex
```

**Permission errors**
```bash
# Fix npm permissions
sudo chown -R $(whoami) ~/.npm
```

**Node version issues**
```bash
# Check version
node --version

# Update if needed
nvm install --lts
```

## Next Steps

Once installed, head to the [commands guide](/guide/commands) to start generating documentation.