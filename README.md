# 🚀 Claudux — Production‑ready docs from your code

> Generate and maintain high‑quality documentation straight from your codebase. Claudux plans, writes, and verifies VitePress docs in a single command using Claude Code — so your docs stay accurate as your code evolves.

[![npm version](https://img.shields.io/npm/v/claudux.svg)](https://www.npmjs.com/package/claudux)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<p align="center">
  <!-- Replace ./assets/readme-hero.png with your screenshot (recommended: 1600×900, .webp or .png) -->
  <img src="./assets/readme-hero.png" alt="Claudux documentation site screenshot" width="100%" />
</p>

## 💡 What it is

**Claudux** turns your repository into a complete, navigable documentation site. It analyzes your codebase, proposes a plan, writes the docs, and validates links/config — all locally.

### 🎯 Why teams use it

- **Always in sync**: update docs as part of your dev workflow, not as an afterthought
- **Code‑aware**: content reflects the real structure and patterns in your repo
- **Low‑friction**: one command; no brittle templates; no vendor lock‑in

## 🌟 Get started in 30 seconds

```bash
# Install (global)
npm install -g claudux

# Or install from GitHub
npm install -g github:leokwan/claudux

# Generate docs for a project
cd your-project
claudux update

# Preview locally
claudux serve  # http://localhost:5173
```

## 📚 Documentation

- Browse in-repo: [`docs/index.md`](docs/index.md)
- When you’re ready to host, use VitePress static output. Run `claudux serve` to preview locally and wire up your hosting.

## 🧠 How it works

Claudux uses a two‑phase flow to produce reliable docs:

1. **Plan**: analyze source code and produce a navigable outline + VitePress config
2. **Write**: generate pages with correct links, breadcrumbs, and cross‑references

## 🎨 Features

- **Code‑driven**: content comes from your actual project structure
- **Smart cleanup**: semantic obsolescence detection (not just regex)
- **VitePress‑ready**: clean config, search, edit links, and sensible defaults
- **Zero cloud lock‑in**: everything runs locally; keep your code private

## ✅ Requirements

- Node.js ≥ 18
- Claude CLI installed and authenticated (`claude config get`)

## 🛠️ Commands

```bash
claudux                     # Interactive menu
claudux update              # Generate/update docs (two‑phase, with cleanup)
claudux update -m "..."     # Update with a focused directive for Claude
claudux serve               # Start dev server (localhost:5173)
claudux validate            # Validate links in docs
claudux repair              # Validate and auto‑create missing pages
claudux clean               # Remove obsolete files only
claudux recreate            # Start fresh (delete all docs)
claudux template            # Analyze codebase and generate CLAUDE.md

# Full usage
claudux --help
```

## 🔧 Configuration

Create a `docs-ai-config.json` in your project root:

```json
{
  "projectName": "Your Awesome Project",
  "primaryLanguage": "typescript",
  "frameworks": ["react", "nextjs"],
  "features": {
    "apiDocs": true,
    "tutorials": true,
    "examples": true
  }
}
```

## 🖼️ Screenshot & social

- README hero image: place `assets/readme-hero.png` (1600×900 recommended; `.webp` preferred)
- Optional social card for docs: place `docs/public/og-image.png` and add OG meta in VitePress config

## 🤝 Contributing

We welcome contributions. See [CONTRIBUTING.md](CONTRIBUTING.md).

## 📄 License

MIT — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Keep your docs as fresh as your code.</strong><br>
  <a href="https://www.npmjs.com/package/claudux">Install from npm</a> • 
  <a href="https://github.com/leokwan/claudux">Star on GitHub</a> • 
  <a href="https://github.com/leokwan/claudux/issues">Report issues</a>
</p>