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

**Claude CLI**  
Install and authenticate the Claude CLI:

```bash
# Install Claude CLI
npm install -g @anthropic-ai/claude-cli

# Authenticate (follow the prompts)
claude config
```

Verify your setup:
```bash
claude config get
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
- Claude CLI installation and authentication
- Documentation directory status

Example output:
```
🔎 Environment check

• Node: v18.17.0
• Claude: claude-cli/1.2.3
• docs/: not present (will be created on first run)
```

## Troubleshooting

**Claude CLI not found**
```bash
npm install -g @anthropic-ai/claude-cli
claude config
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