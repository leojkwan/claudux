# Features

[Home](/) > Features

Claudux provides powerful AI-driven documentation generation with advanced features designed for modern development workflows. Built with Unix philosophy and Bash-first architecture, it delivers intelligent automation while maintaining simplicity and reliability.

## Core Features

### 🧠 Two-Phase AI Generation
Intelligent documentation generation using a comprehensive analysis and execution approach:
- **Phase 1**: Deep codebase analysis, obsolescence detection, and detailed planning
- **Phase 2**: Systematic execution of the generated plan with real-time validation
- Semantic analysis with 95%+ confidence thresholds for content decisions

[Learn more about Two-Phase Generation →](/features/two-phase-generation)

### 🛡️ Content Protection
Advanced protection mechanisms for sensitive and valuable content:
- File-type aware protection markers (`<!-- skip -->`, `// skip`, `# skip`)
- Protected directory detection (notes/, private/, .git/, etc.)
- Sensitive file pattern recognition (.env, .key, .pem files)
- Automatic content stripping during analysis

[Learn more about Content Protection →](/features/content-protection)

### 🧹 Smart Cleanup
AI-powered obsolescence detection that safely removes outdated documentation:
- Semantic analysis of documentation vs. current codebase
- Cross-referencing documented features against actual implementation
- Conservative approach with high confidence thresholds
- Preservation of valuable historical content

[Learn more about Smart Cleanup →](/features/smart-cleanup)

### 🔍 Auto Project Detection
Intelligent project type detection supporting multiple frameworks and languages:
- iOS/Swift projects (Xcode, Project.swift)
- JavaScript frameworks (Next.js, React, Node.js)
- System languages (Rust, Go, Python, Java)
- Generic fallback for unknown project types
- Configuration-based overrides

[Learn more about Project Detection →](/features/project-detection)

### 📚 VitePress Integration
Seamless integration with VitePress for modern documentation sites:
- Automated configuration generation
- Dynamic sidebar and navigation setup
- Logo detection and asset management
- Theme customization and styling
- Mobile-responsive design with accessibility

[Learn more about VitePress Integration →](/features/vitepress-integration)

## Architecture Highlights

### Unix Philosophy
- **Do one thing well**: Focused on documentation generation
- **Modular design**: Separate libraries for distinct functionality
- **Composable tools**: Each feature works independently and together
- **Shell-first approach**: Bash as the primary implementation language

### Error Handling
- Graceful degradation when optional tools are missing
- Comprehensive error reporting with actionable guidance
- Lock file management to prevent concurrent execution
- Signal handling for clean interruption

### Cross-Platform Support
- macOS and Linux compatibility
- Platform-specific command handling (`md5` vs `md5sum`)
- Consistent behavior across different environments
- Fallback strategies for missing dependencies

## Configuration

Claudux supports flexible configuration through multiple sources:

- **`docs-ai-config.json`**: Project-specific AI documentation settings
- **`.claudux.json`**: Legacy configuration support
- **`docs-map.md`**: Documentation structure guidance
- **`.ai-docs-style.md`**: Custom AI style guides
- **`CLAUDE.md`**: Project-specific coding patterns and conventions

## Quality Assurance

### Link Validation
- Automatic validation of generated documentation links
- Broken link detection with auto-fix capabilities
- VitePress configuration validation
- Cross-reference checking between navigation and files

### Content Quality
- Real code example extraction and validation
- Implementation accuracy verification
- Outdated content identification
- Consistent formatting and style application

## Getting Started

1. **Install**: `npm install -g claudux`
2. **Configure**: Create `docs-ai-config.json` in your project root
3. **Generate**: Run `claudux update` to create comprehensive documentation
4. **Serve**: Use `claudux serve` to preview your documentation
5. **Maintain**: Regular updates keep documentation current with code changes

Each feature is designed to work seamlessly together while remaining independently valuable, providing a comprehensive documentation solution that grows with your project.