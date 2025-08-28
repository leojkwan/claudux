# Claudux Documentation

> **Stop fighting stale documentation.** Claudux analyzes your codebase and generates comprehensive, navigable docs that actually stay in sync with your code.

## What is Claudux?

Claudux is an AI-powered documentation generator that uses Claude Code to understand your codebase and automatically generate production-ready documentation with VitePress. It's designed for developers who want to maintain up-to-date documentation without the manual overhead.

## Key Features

- **🔄 Stays Current** - Documentation updates alongside your code, not months later
- **🧠 Semantic Understanding** - Analyzes structure, patterns, and context—not just comments  
- **⚡ One-Command Generation** - From codebase to complete VitePress site in seconds
- **🔒 Privacy-First** - Runs locally using Claude Code CLI—your code never leaves your machine
- **🍰 Zero Configuration** - Works out of the box with sensible defaults

## Quick Start

Get started with Claudux in 30 seconds:

```bash
# Install globally (pick your favorite method)
npm install -g claudux@latest   # npm
pnpm add -g claudux             # pnpm (faster)
yarn global add claudux         # yarn
bun add -g claudux              # bun (fastest)

# Or use without installing
npx claudux@latest update       # npx (no install)

# Generate docs for your project
cd your-project
claudux update

# Preview locally  
claudux serve  # → http://localhost:5173
```

## How It Works

Claudux uses a sophisticated two-phase approach to generate accurate, well-structured documentation:

### Phase 1: Analysis & Planning
- Analyzes your entire codebase structure
- Detects project type and frameworks
- Plans documentation hierarchy
- Identifies outdated content with confidence scores

### Phase 2: Content Generation
- Generates documentation based on actual code
- Creates accurate code examples from source
- Builds navigable structure with proper links
- Validates all cross-references

## Supported Project Types

Claudux automatically detects and optimizes for:

- **iOS Apps** - Swift, SwiftUI, UIKit with Tuist support
- **Next.js** - React apps with App/Pages Router
- **React** - Standard React applications  
- **Node.js** - JavaScript/TypeScript projects
- **Python** - Django, Flask, FastAPI
- **Rust** - Cargo-based projects
- **Go** - Go modules
- **Generic** - Any codebase with README

## Documentation Structure

Claudux generates a complete documentation site including:

- **Getting Started Guide** - Installation and quick start
- **User Guide** - Commands and configuration
- **Feature Documentation** - Detailed feature explanations
- **API Reference** - Complete API documentation
- **Technical Docs** - Architecture and patterns
- **Examples** - Real-world usage examples

## Requirements

- **Node.js** ≥ 18.0.0
- **Claude CLI** installed and authenticated (`claude config get`)
- **Git** repository (recommended)

## Installation

```bash
# Install globally from npm (modern approach)
npm install -g claudux@latest --prefer-online

# Or use alternative package managers
pnpm add -g claudux       # Faster alternative
yarn global add claudux   # Yarn users
bun add -g claudux        # Blazing fast with Bun

# Verify installation
claudux --version

# Or run without installing
npx claudux@latest --version
```

## Core Commands

| Command | Description |
|---------|-------------|
| `claudux` | Interactive menu |
| `claudux update` | Generate/update documentation |
| `claudux serve` | Start development server |
| `claudux clean` | Smart cleanup of obsolete docs |
| `claudux recreate` | Start fresh (delete all docs) |
| `claudux create-template` | Generate CLAUDE.md template |

## Configuration

Claudux can be configured via `claudux.json` in your project root:

```json
{
  "project": {
    "name": "Your Project",
    "type": "javascript"
  }
}
```

## Next Steps

- [Installation Guide →](/guide/installation)
- [Quick Start Tutorial →](/guide/quickstart)
- [Command Reference →](/guide/commands)
- [View Examples →](/examples/)

## Why Claudux?

Traditional documentation tools require constant manual updates. Claudux understands your code semantically, generating documentation that reflects your actual implementation—not what you think it does.

### The Claudux Advantage

1. **Semantic Analysis** - Goes beyond comments to understand code intent
2. **Two-Phase Process** - Plans before generating for better structure
3. **Content Protection** - Never deletes your custom content
4. **Smart Cleanup** - Removes truly obsolete docs (95% confidence)
5. **Local-First** - Complete privacy with Claude Code CLI

## Contributing

We welcome contributions! See our [Contributing Guide](/development/contributing) to get started.

## License

MIT License - see [LICENSE](https://github.com/leojkwan/claudux/blob/main/LICENSE) for details.

---

<p align="center">
  <strong>Keep your docs as fresh as your code.</strong><br/>
  <a href="https://www.npmjs.com/package/claudux">npm</a> • 
  <a href="https://github.com/leojkwan/claudux">GitHub</a> • 
  <a href="/guide/">Get Started →</a>
</p>