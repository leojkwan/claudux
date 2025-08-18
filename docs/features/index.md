[Home](/) > Features

# Features Overview

Claudux combines cutting-edge AI with robust Unix engineering to deliver a documentation solution that actually works. Here's what makes it special.

## Core Features

### 🤖 AI-Powered Generation
Leverages Claude's advanced language model to understand your codebase and generate documentation that reads naturally, maintains consistency, and captures your project's unique patterns.

### ⚡ Two-Phase Generation
Our unique two-phase approach ensures high-quality output:
1. **Analysis Phase**: Complete codebase understanding
2. **Generation Phase**: Coherent documentation creation

[Learn more →](/features/two-phase-generation)

### 🧹 Smart Cleanup
Semantic obsolescence detection identifies truly outdated content with 95% confidence, preserving your custom documentation while removing stale auto-generated content.

[Learn more →](/features/smart-cleanup)

### 📚 VitePress Integration
Ships with a beautiful, responsive documentation site powered by VitePress, complete with search, dark mode, and mobile optimization.

[Learn more →](/features/vitepress-integration)

### 🎯 Project Auto-Detection
Automatically identifies your project type and applies appropriate templates, supporting React, Next.js, iOS, Python, Rust, and more.

[Learn more →](/features/project-detection)

### 🔒 Content Protection
Respects your `.gitignore` patterns and protects sensitive directories, with custom markers for preserving hand-written content.

[Learn more →](/features/content-protection)

## Advanced Capabilities

### Incremental Updates
Only regenerates changed sections, preserving custom content and reducing generation time.

### Link Validation
Automatically validates all internal and external links, with auto-repair capabilities.

### Multi-Framework Support
Specialized templates for:
- React/Next.js applications
- iOS/Swift projects
- Python packages
- Rust crates
- Go modules
- Ruby gems
- Generic JavaScript

### Custom Templates
Extensible template system allows adding support for new frameworks and project types.

## Quality Features

### Context Awareness
AI understands your:
- Project structure
- Coding patterns
- Framework conventions
- API designs
- Testing approaches

### Consistent Output
Maintains consistent:
- Terminology
- Code style
- Documentation format
- Cross-references
- Examples

### Breadcrumb Navigation
Automatic breadcrumb generation for easy navigation through documentation hierarchy.

### Protected Patterns
Never touches:
- `.git/` directory
- `node_modules/`
- Private/secret directories
- Custom protected content
- Environment files

## Developer Experience

### Zero Configuration
Works out of the box with sensible defaults, no configuration required for most projects.

### Interactive Menu
User-friendly interface for those who prefer guided interaction over command-line options.

### Verbose Feedback
Clear progress indicators and detailed output for understanding what's happening.

### Error Recovery
Graceful error handling with helpful messages and recovery suggestions.

## Performance

### Efficient Processing
- Parallel file analysis
- Smart caching
- Incremental updates
- Token optimization

### Scalability
Handles projects of any size:
- Small libraries
- Large monorepos
- Multi-language codebases
- Complex architectures

## Integration Features

### CI/CD Ready
Easy integration with:
- GitHub Actions
- GitLab CI
- Jenkins
- CircleCI
- Custom pipelines

### Version Control Friendly
- Clean diff output
- Predictable file structure
- Merge-friendly format
- Git-aware operations

### Platform Support
- macOS (primary)
- Linux (full support)
- Windows (via WSL)
- Docker containers

## Documentation Features

### Auto-Generated Sections
- API reference
- Component documentation
- Configuration guides
- Installation instructions
- Usage examples
- Architecture diagrams (as Mermaid)

### Rich Content
- Syntax highlighting
- Code examples
- Tables
- Diagrams
- Cross-references
- Search functionality

### Customization
- Custom templates
- AI instructions
- Configuration options
- Protected content
- Styling options

## Comparison with Alternatives

| Feature | Claudux | JSDoc | Sphinx | Docusaurus |
|---------|---------|-------|--------|------------|
| AI-Powered | ✅ | ❌ | ❌ | ❌ |
| Zero Config | ✅ | ❌ | ❌ | ⚠️ |
| Multi-Language | ✅ | ❌ | ⚠️ | ⚠️ |
| Smart Cleanup | ✅ | ❌ | ❌ | ❌ |
| Auto-Detection | ✅ | ❌ | ❌ | ❌ |
| Two-Phase Gen | ✅ | ❌ | ❌ | ❌ |
| Link Validation | ✅ | ❌ | ⚠️ | ⚠️ |

## Use Cases

### Open Source Projects
Generate comprehensive documentation for contributors and users.

### Internal Tools
Document internal APIs and services for team members.

### Client Projects
Deliver professional documentation alongside code.

### Learning Projects
Understand codebases better through AI-generated documentation.

### Legacy Code
Document existing codebases that lack documentation.

## Coming Soon

- 🌍 Multi-language documentation
- 📊 Metrics and analytics
- 🎨 Custom themes
- 🔄 Real-time updates
- 📱 Mobile app
- 🤝 Collaboration features

## Getting Started

Ready to experience these features?

1. [Install Claudux](/guide/installation)
2. [Follow the Quick Start](/guide/quickstart)
3. [Explore Commands](/guide/commands)
4. [Customize Configuration](/guide/configuration)