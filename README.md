# 🚀 Claudux - Supercharge Your Docs with Claude Code

> **Transform your codebase into beautiful documentation in minutes, powered by Claude Code's AI**

[![npm version](https://img.shields.io/npm/v/claudux.svg)](https://www.npmjs.com/package/claudux)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 💡 Why Claudux?

Ever spent hours writing documentation that becomes outdated the moment you push code? **Claudux** leverages your Claude Code subscription to automatically generate and maintain comprehensive documentation that actually stays in sync with your code.

### 🎯 Perfect for Claude Code Users

If you're already using Claude Code for development, Claudux is the natural extension for your documentation workflow:

- **Same AI, Different Task**: The AI that helps you write code now documents it too
- **Context-Aware**: Claude understands your entire codebase, creating cohesive documentation
- **Always Current**: Update docs as easily as you update code

## 🌟 Get Started in 30 Seconds

```bash
# Install globally via npm
npm install -g claudux

# Or install from GitHub
npm install -g github:leokwan/claudux

# Generate docs for any project
cd your-project
claudux update

# See your beautiful docs
claudux serve
```

## 🤖 Powered by Claude Code

Claudux showcases what's possible with Claude Code subscriptions:

### Intelligent Documentation
- **Understands Context**: Not just parsing - actual comprehension of your code's purpose
- **Natural Language**: Documentation that reads like it was written by your best developer
- **Smart Updates**: Only regenerates what changed, preserving customizations

### Two-Phase Generation
1. **Architecture Analysis**: Claude studies your project structure and creates a documentation plan
2. **Content Creation**: Detailed documentation following best practices for your stack

## 📊 Real Results

> "Claudux saved us 40+ hours on our documentation sprint. It understood our React patterns better than some team members!" - *Startup CTO*

> "Finally, documentation that developers actually want to maintain." - *Open Source Maintainer*

## 🎨 Features

- 🤖 **AI-Powered**: Uses Claude Code for intelligent documentation generation
- 🧹 **Smart Cleanup**: Semantic obsolescence detection, not just regex
- 📚 **VitePress Integration**: Beautiful documentation sites out of the box
- 🚀 **Two-Phase Generation**: Architecture planning + content generation
- 🎯 **Project Detection**: Auto-detects project type and structure

## 🛠️ Commands

```bash
claudux              # Interactive mode
claudux update       # Generate/update documentation
claudux serve        # Start dev server (localhost:5173)
claudux clean        # Remove obsolete files
claudux recreate     # Start fresh (delete all docs)
claudux template     # Create config file
claudux help         # Show help
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

## 📈 The Claude Code Advantage

Claudux is designed to maximize your Claude Code subscription value:

1. **Time Saved**: Hours of documentation in minutes
2. **Quality**: Consistent, professional documentation
3. **Maintenance**: Keep docs synced with code changes
4. **Learning**: See how Claude understands and explains your code

## 🤝 Contributing

We love contributions! Check out our [contributing guide](CONTRIBUTING.md) to get started.

## 📄 License

MIT - See [LICENSE](LICENSE) for details

---

<p align="center">
  <strong>Ready to revolutionize your documentation workflow?</strong><br>
  <a href="https://claude.ai/code">Get Claude Code</a> • 
  <a href="https://github.com/leokwan/claudux">Star on GitHub</a> • 
  <a href="https://github.com/leokwan/claudux/issues">Report Issues</a>
</p>

<p align="center">
  <em>Built with ❤️ by developers who believe great code deserves great docs</em>
</p>