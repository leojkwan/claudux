# Project Templates for AI Documentation System

This AI-powered documentation system works with **any programming language or project type**. Choose the template that best matches your project or create a custom one.

## Quick Setup

1. **Copy your template:**
   ```bash
   cp templates/[your-project-type]-config.json docs-ai-config.json
   ```

2. **Customize for your project:**
   - Update `project.name` and `project.description`
   - Adjust file paths in `files` section
   - Modify `claude_instructions.focus_areas`

3. **Create your documentation map:**
   ```bash
   cp templates/docs-map-[your-project-type].md docs-map.md
   ```

4. **Set up AI style guide (optional):**
   ```bash
   # Copy to project (project-specific)
   cp templates/.ai-docs-style.md .ai-docs-style.md
   
   # OR copy to home directory (global for all projects)
   cp templates/.ai-docs-style.md ~/.ai-docs-style.md
   ```

## Available Templates

### 📱 **iOS/Swift Projects**
```bash
cp templates/ios-project-config.json docs-ai-config.json
```
- **Best for**: iOS apps, macOS apps, Swift packages
- **Build systems**: Tuist, SPM, Xcode
- **Testing**: XCTest, EmergeTools snapshots

### ⚛️ **React/Web Projects**  
```bash
cp templates/react-project-config.json docs-ai-config.json
```
- **Best for**: React, Vue, vanilla JS web apps
- **Build systems**: Vite, Webpack, Turbo
- **Testing**: Vitest, Jest, Playwright

### 🌐 **Next.js Projects**
```bash
cp templates/nextjs-project-config.json docs-ai-config.json
```
- **Best for**: Full-stack React apps, SSR/SSG
- **Build systems**: Next.js, Turbo
- **Testing**: Jest, Playwright

### 🐍 **Python Projects**
```bash
cp templates/python-project-config.json docs-ai-config.json
```
- **Best for**: FastAPI, Django, Flask, data science
- **Build systems**: Poetry, pip, conda
- **Testing**: pytest, unittest

### 🐹 **Go Projects**
```bash
cp templates/go-project-config.json docs-ai-config.json
```
- **Best for**: Web APIs, microservices, CLI tools
- **Build systems**: go mod, make
- **Testing**: go test, testify

### 💎 **Ruby on Rails Projects**
```bash
cp templates/rails-project-config.json docs-ai-config.json
```
- **Best for**: Web applications, APIs
- **Build systems**: Bundler, Rails
- **Testing**: RSpec, Minitest

### 🦀 **Rust Projects**
```bash
cp templates/rust-project-config.json docs-ai-config.json
```
- **Best for**: Web services, CLI tools, systems
- **Build systems**: Cargo, workspace
- **Testing**: cargo test, criterion

### 📱 **Flutter Projects**
```bash
cp templates/flutter-project-config.json docs-ai-config.json
```
- **Best for**: Cross-platform mobile apps
- **Build systems**: Flutter, Dart pub
- **Testing**: Flutter test, integration tests

### 🤖 **Android Projects**
```bash
cp templates/android-project-config.json docs-ai-config.json
```
- **Best for**: Native Android apps
- **Build systems**: Gradle, Android Studio
- **Testing**: JUnit, Espresso, Compose tests

## Creating Custom Templates

The config format is simple JSON with these key sections:

```json
{
  "project": {
    "name": "Your Project",
    "type": "your_language",
    "language": "YourLanguage",
    "build_system": "your_build_tool"
  },
  "files": {
    "main_config": "your-main-config-file",
    "source_dir": "src"
  },
  "claude_instructions": {
    "focus_areas": [
      "Key files/patterns to focus on",
      "Architecture patterns to understand"
    ]
  }
}
```

## Language-Agnostic Core

The system works because it focuses on **universal documentation patterns**:

- 📋 **Project setup** - How to get started
- 🏗️ **Architecture** - How code is organized  
- 🧪 **Testing** - How to run tests
- 🚀 **Deployment** - How to build/deploy
- 📚 **API Reference** - Code documentation

## Benefits for Any Project

- **🤖 AI reads your actual code** - No outdated docs
- **📝 VitePress** - Fast, modern documentation site
- **🎯 Project-aware** - Understands your tech stack
- **⚡ One command** - `./docs-ai.sh` keeps docs fresh
- **🛡️ Protection markers** - Control what AI can and can't edit
- **📁 Safe notes folder** - Personal notes never touched by AI

## Need Help?

1. **Start with a template** closest to your project
2. **Customize the config** for your specific needs  
3. **Run `./docs-ai.sh plan`** to see what it would do
4. **Use protection markers** in your docs to keep personal sections safe

The system is designed to work with **any codebase** - the templates just provide sensible defaults! 