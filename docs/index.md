---
layout: home

hero:
  name: claudux
  text: Your docs write themselves
  tagline: AI-powered documentation generator that analyzes your codebase and generates comprehensive, navigable docs that stay in sync with your code
  actions:
    - theme: brand
      text: Get Started
      link: /guide/
    - theme: alt
      text: View on GitHub
      link: https://github.com/leojkwan/claudux

features:
  - icon: 🔄
    title: Stays Current
    details: Updates with your code, not months later. Automatic semantic analysis detects when docs need refreshing.
  
  - icon: 🧠
    title: Actually Understands
    details: Analyzes structure, patterns, and context using Claude AI to generate meaningful documentation.
  
  - icon: ⚡
    title: Ships Fast  
    details: One command generates complete VitePress sites with navigation, search, and mobile-friendly design.
  
  - icon: 🔒
    title: Runs Locally
    details: Your code never leaves your machine. Everything processes locally for complete privacy.
  
  - icon: 🍰
    title: Zero Config
    details: Works out of the box with intelligent project detection. Customize when needed.
  
  - icon: 🔗
    title: Zero Broken Links
    details: Built-in link validation prevents 404s. Auto-generates missing pages when possible.
---

## Quick Start

```bash
# Install globally
npm install -g claudux

# Generate docs for your project
cd your-project
claudux update

# Preview locally  
claudux serve  # http://localhost:5173
```

## The Problem Every Developer Knows

**Documentation debt is killing your productivity.** You ship features, but docs lag behind. New team members struggle to onboard. You spend weekends writing docs instead of building.

## How It Works

Claudux uses a **two-phase flow** to produce reliable docs:

1. **🧠 Plan**: Analyze source code and produce a navigable outline + VitePress config
2. **✍️ Write**: Generate pages with correct links, breadcrumbs, and cross-references

## Commands Overview

| Command | Purpose |
|---------|---------|
| `claudux update` | Generate/update docs (includes cleanup & validation) |
| `claudux serve` | Start dev server at localhost:5173 |
| `claudux recreate` | Start fresh (delete all docs) |
| `claudux template` | Generate claudux.md (docs preferences) |

## Requirements

- Node.js ≥ 18
- Claude CLI installed and authenticated (`claude config get`)

---

<div style="text-align: center; margin-top: 40px;">
  <strong>Keep your docs as fresh as your code.</strong><br>
  <a href="https://www.npmjs.com/package/claudux">📦 Install from npm</a> • 
  <a href="https://github.com/leojkwan/claudux">⭐ Star on GitHub</a>
</div>