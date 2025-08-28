# Auto Project Detection

[Home](/) > [Features](/features/) > Auto Project Detection

Claudux automatically detects project types and configurations to provide tailored documentation generation. The detection system supports multiple programming languages, frameworks, and project structures with intelligent prioritization and fallback mechanisms.

## Overview

Project detection enables Claudux to:
- **Automatically identify project types** based on file patterns and configurations
- **Load project-specific templates** for optimal documentation structure
- **Apply framework-specific documentation patterns**
- **Configure AI prompts** with relevant context and constraints
- **Provide intelligent defaults** while allowing manual overrides

## Technical Implementation

The project detection system is implemented in `/Users/lkwan/Snapchat/Dev/claudux/lib/project.sh` with two main functions: `load_project_config()` and `detect_project_type()`.

### Configuration Loading

```bash
# From lib/project.sh:4-30
load_project_config() {
    PROJECT_NAME="Your Project"
    PROJECT_TYPE="generic"
    
    # Try docs-ai-config.json first
    if [[ -f "docs-ai-config.json" ]] && command -v jq &> /dev/null; then
        PROJECT_NAME=$(jq -r '.project.name // "Your Project"' docs-ai-config.json 2>/dev/null || echo "Your Project")
        PROJECT_TYPE=$(jq -r '.project.type // "generic"' docs-ai-config.json 2>/dev/null || echo "generic")
    # Fallback to .claudux.json
    elif [[ -f ".claudux.json" ]]; then
        if command -v jq &> /dev/null; then
            PROJECT_NAME=$(jq -r '.name // "Your Project"' .claudux.json 2>/dev/null || echo "Your Project")
            PROJECT_TYPE=$(jq -r '.type // empty' .claudux.json 2>/dev/null || echo "")
        elif grep -q '"name"' .claudux.json 2>/dev/null; then
            PROJECT_NAME=$(grep '"name"' .claudux.json | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || echo "Your Project")
        fi
    fi
    
    # Auto-detect type if not specified
    if [[ -z "$PROJECT_TYPE" ]] || [[ "$PROJECT_TYPE" == "generic" ]]; then
        PROJECT_TYPE=$(detect_project_type)
    fi
    
    export PROJECT_NAME
    export PROJECT_TYPE
}
```

### Configuration Sources Priority

1. **`docs-ai-config.json`** - Primary configuration file (with jq parsing)
2. **`.claudux.json`** - Legacy configuration file (with graceful fallback parsing)
3. **Auto-detection** - Intelligent detection based on file patterns
4. **Generic fallback** - Default project type when detection fails

### Auto-Detection Algorithm

```bash
# From lib/project.sh:32-64
detect_project_type() {
    # iOS/Swift project
    if [[ -f "Project.swift" ]] || [[ -n "$(find . -maxdepth 1 -name "*.xcodeproj" -o -name "*.xcworkspace" 2>/dev/null | head -1)" ]]; then
        echo "ios"
    # Next.js project (check before React)
    elif [[ -f "next.config.js" ]] || [[ -f "next.config.mjs" ]] || [[ -f "next.config.ts" ]] || ([[ -f "package.json" ]] && grep -q '"next"' package.json 2>/dev/null); then
        echo "nextjs"
    # React project
    elif [[ -f "package.json" ]] && grep -q '"react"' package.json 2>/dev/null; then
        echo "react"
    # Node.js project
    elif [[ -f "package.json" ]] && grep -q '"@types/node"' package.json 2>/dev/null; then
        echo "nodejs"
    # JavaScript project
    elif [[ -f "package.json" ]]; then
        echo "javascript"
    # Rust project
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    # Python project
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        echo "python"
    # Go project
    elif [[ -f "go.mod" ]]; then
        echo "go"
    # Java project
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        echo "java"
    else
        echo "generic"
    fi
}
```

## Supported Project Types

### iOS/Swift Projects

**Detection Patterns**:
- `Project.swift` (Tuist configuration)
- `*.xcodeproj` (Xcode project files)
- `*.xcworkspace` (Xcode workspace files)

**Features**:
- App icon detection from Assets.xcassets
- iOS-specific documentation templates
- Swift code analysis patterns
- App Store deployment considerations

```bash
# iOS detection logic
if [[ -f "Project.swift" ]] || [[ -n "$(find . -maxdepth 1 -name "*.xcodeproj" -o -name "*.xcworkspace" 2>/dev/null | head -1)" ]]; then
    echo "ios"
```

### JavaScript Ecosystem

#### Next.js Projects
**Detection Patterns** (checked before React):
- `next.config.js`, `next.config.mjs`, `next.config.ts`
- `"next"` dependency in `package.json`

**Features**:
- SSR/SSG documentation patterns
- API routes documentation
- Deployment configuration guides

#### React Projects
**Detection Patterns**:
- `"react"` dependency in `package.json`
- Excludes Next.js projects (higher priority)

**Features**:
- Component documentation
- Hook usage patterns
- State management integration

#### Node.js Projects
**Detection Patterns**:
- `"@types/node"` in `package.json`
- Server-side JavaScript focus

**Features**:
- API documentation
- Server architecture guides
- Deployment and scaling documentation

#### Generic JavaScript Projects
**Detection Patterns**:
- `package.json` exists
- Fallback for JavaScript projects

**Features**:
- Basic JavaScript documentation patterns
- NPM script documentation
- General web development practices

### System Programming Languages

#### Rust Projects
**Detection Patterns**:
- `Cargo.toml` (Rust package manifest)

**Features**:
- Crate documentation
- Memory safety explanations
- Performance optimization guides

#### Go Projects
**Detection Patterns**:
- `go.mod` (Go module file)

**Features**:
- Package documentation
- Goroutine and channel patterns
- Deployment and containerization

#### Python Projects
**Detection Patterns**:
- `pyproject.toml` (Modern Python projects)
- `setup.py` (Traditional Python packages)
- `requirements.txt` (Dependency specification)

**Features**:
- Module and package documentation
- Virtual environment setup
- Testing with pytest patterns

#### Java Projects
**Detection Patterns**:
- `pom.xml` (Maven projects)
- `build.gradle` or `build.gradle.kts` (Gradle projects)

**Features**:
- JavaDoc integration
- Spring Framework patterns
- Build and deployment documentation

### Generic Projects
**Fallback**: When no specific patterns are detected

**Features**:
- Basic project structure documentation
- General development practices
- Customizable through configuration files

## Priority and Precedence

The detection algorithm follows a specific priority order to handle overlapping patterns:

1. **iOS/Swift** - Most specific platform detection
2. **Next.js** - Checked before generic React to prevent misclassification
3. **React** - Specific framework before generic Node.js
4. **Node.js** - Server-side before generic JavaScript
5. **JavaScript** - Generic JavaScript projects
6. **System Languages** (Rust, Go, Python, Java) - Equal priority, file-based detection
7. **Generic** - Final fallback

### Example: Next.js vs React Classification

```bash
# Next.js projects contain React but are detected as Next.js
project/
├── package.json          # Contains both "next" and "react"
├── next.config.js        # Next.js-specific
└── pages/               # Next.js routing

# Result: "nextjs" (not "react")
```

## Logo Detection Integration

```bash
# From lib/project.sh:66-85
find_project_logo() {
    local logo_path=""
    
    # iOS app icon
    if [[ "$PROJECT_TYPE" == "ios" ]]; then
        # Look for app icon in Assets
        logo_path=$(find . -path "*/Assets.xcassets/AppIcon.appiconset/*.png" -o -path "*/Assets.xcassets/AppIcon.appiconset/*.jpg" 2>/dev/null | grep -E "(1024|512)" | head -1)
        
        # Try other common locations
        if [[ -z "$logo_path" ]]; then
            logo_path=$(find . -name "logo*.png" -o -name "logo*.jpg" -o -name "icon*.png" -o -name "icon*.jpg" 2>/dev/null | grep -v node_modules | head -1)
        fi
    else
        # Generic logo search
        logo_path=$(find . -maxdepth 3 -name "logo*.png" -o -name "logo*.jpg" -o -name "logo*.svg" -o -name "icon*.png" -o -name "icon*.svg" 2>/dev/null | grep -v node_modules | head -1)
    fi
    
    echo "$logo_path"
}
```

### iOS-Specific Logo Detection
- Searches `Assets.xcassets/AppIcon.appiconset/` for high-resolution icons
- Prefers 1024x1024 or 512x512 versions
- Falls back to generic logo patterns

### Generic Logo Detection
- Searches up to 3 directory levels deep
- Supports PNG, JPG, and SVG formats
- Excludes `node_modules` directory
- Prefers files with "logo" or "icon" in the name

## Configuration Override Examples

### Manual Project Type Override

```json
// docs-ai-config.json
{
  "project": {
    "name": "My Awesome Project",
    "type": "ios"  // Override auto-detection
  },
  "ai": {
    "model": "sonnet",
    "style_guide": ".ai-docs-style.md"
  }
}
```

### Legacy Configuration Format

```json
// .claudux.json
{
  "name": "Legacy Project",
  "type": "nodejs",
  "version": "1.0.0"
}
```

### Fallback Parsing (No jq)

When `jq` is not available, the system falls back to basic grep parsing:

```bash
elif grep -q '"name"' .claudux.json 2>/dev/null; then
    PROJECT_NAME=$(grep '"name"' .claudux.json | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || echo "Your Project")
```

## Integration with Documentation Generation

### Template Selection

Project type determines which template is used:

```bash
# Template path resolution (from docs-generation.sh)
if [[ -f "$LIB_DIR/templates/${project_type}/config.json" ]]; then
    template_config="$LIB_DIR/templates/${project_type}/config.json"
elif [[ -f "$LIB_DIR/templates/${project_type}-project-config.json" ]]; then
    template_config="$LIB_DIR/templates/${project_type}-project-config.json"
elif [[ -f "$LIB_DIR/templates/generic/config.json" ]]; then
    template_config="$LIB_DIR/templates/generic/config.json"
fi
```

### AI Prompt Customization

Project type influences AI behavior:

```bash
# Platform-specific guardrails (from docs-generation.sh)
Platform guardrails:
- For non-iOS projects, DO NOT include iOS-specific concepts, links, or pages 
  (e.g., Tuist, SwiftData, CloudKit, App Store, TestFlight, Xcode). 
  Only include them for `project_type=ios`.
```

### VitePress Configuration

Project type affects generated VitePress configuration:

```bash
# Project description customization (from vitepress/setup.sh)
PROJECT_DESCRIPTION="$PROJECT_NAME documentation"
if [[ "$PROJECT_TYPE" == "ios" ]]; then
    PROJECT_DESCRIPTION="$PROJECT_NAME - iOS app documentation"
elif [[ "$PROJECT_TYPE" == "react" ]]; then
    PROJECT_DESCRIPTION="$PROJECT_NAME - React app documentation"
elif [[ "$PROJECT_TYPE" == "nodejs" ]]; then
    PROJECT_DESCRIPTION="$PROJECT_NAME - Node.js project documentation"
fi
```

## Error Handling and Graceful Degradation

### Missing Dependencies

```bash
# jq availability check
if [[ -f "docs-ai-config.json" ]] && command -v jq &> /dev/null; then
    # Use jq for reliable JSON parsing
else
    # Fall back to grep/sed parsing
fi
```

### File System Errors

```bash
# Safe file detection with error suppression
if [[ -n "$(find . -maxdepth 1 -name "*.xcodeproj" -o -name "*.xcworkspace" 2>/dev/null | head -1)" ]]; then
    echo "ios"
fi
```

### Invalid Configuration

```bash
# Fallback values for failed parsing
PROJECT_NAME=$(jq -r '.project.name // "Your Project"' docs-ai-config.json 2>/dev/null || echo "Your Project")
```

## Debugging Project Detection

### Verbose Mode

Enable verbose logging to see detection decisions:

```bash
CLAUDUX_VERBOSE=1 claudux update
```

Output includes:
```bash
info "   Project: $PROJECT_NAME (type: $PROJECT_TYPE)"
```

### Manual Detection Testing

Test project detection independently:

```bash
# In the project root
source lib/project.sh
detect_project_type
# Output: ios, react, nodejs, etc.
```

### Configuration Validation

Check current project configuration:

```bash
source lib/project.sh
load_project_config
echo "Name: $PROJECT_NAME"
echo "Type: $PROJECT_TYPE"
```

## Future Enhancements

Planned improvements to project detection:

### Enhanced Detection Patterns
- **Monorepo support** with multiple project types
- **Framework version detection** for specialized templates
- **Custom detection rules** via configuration
- **CI/CD pipeline integration** detection

### Improved Configuration
- **Hierarchical configuration** merging multiple sources
- **Environment-specific overrides** (development, production)
- **Team-wide configuration** sharing via git

### Advanced Features
- **Multi-language projects** with mixed documentation
- **Microservice architecture** detection
- **Docker and containerization** awareness
- **Cloud platform** integration detection

The auto project detection system provides the foundation for intelligent, context-aware documentation generation that adapts to your specific development stack and project structure.