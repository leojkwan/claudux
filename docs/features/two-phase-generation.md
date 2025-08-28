# Two-Phase Generation

[Home](/) > [Features](/features/) > Two-Phase Generation

Claudux employs a sophisticated two-phase approach to documentation generation that ensures comprehensive analysis before execution. This methodology provides superior quality and accuracy compared to single-pass generation approaches.

## Overview

The two-phase generation process separates analysis from execution, allowing for thorough planning and validation before making any changes to your documentation.

### Phase 1: Comprehensive Analysis & Planning 🧠
Deep project understanding and detailed execution planning

### Phase 2: Execute the Plan ✏️
Systematic implementation of the generated plan with real-time validation

## Technical Implementation

The core implementation is located in `/Users/lkwan/Snapchat/Dev/claudux/lib/docs-generation.sh` within the `build_generation_prompt()` function.

### Phase 1: Analysis & Planning

```bash
# From lib/docs-generation.sh:82-147
==== PHASE 1: COMPREHENSIVE ANALYSIS & PLANNING ====
🧠 First, analyze the entire project and create a detailed plan:

1. **Read Configuration & Templates**:
   - Load all template configs, style guides, and docs-map files
   - Read lib/vitepress/sidebar-example.md for sidebar configuration patterns
   - Understand the expected documentation structure
   - Note any protected areas or special requirements

2. **Analyze Codebase Structure**:
   - Scan source code to understand architecture
   - Identify key components, APIs, and features
   - Note testing approaches and build systems
   - Find main entry points and public interfaces

3. **Audit Existing Documentation**:
   - List all existing documentation files
   - Cross-reference each doc against current code
   - Identify outdated content (with confidence scores)
   - Find missing documentation gaps

4. **Create Detailed Execution Plan**:
   - List all NEW files to create with descriptions
   - List all files to UPDATE with specific changes
   - List any OBSOLETE files with 95%+ confidence
   - Show the final documentation structure
```

#### Configuration File Loading

The system intelligently loads configuration from multiple sources:

```bash
# Template configuration discovery
if [[ -f "$LIB_DIR/templates/${project_type}/config.json" ]]; then
    template_config="$LIB_DIR/templates/${project_type}/config.json"
elif [[ -f "$LIB_DIR/templates/${project_type}-project-config.json" ]]; then
    template_config="$LIB_DIR/templates/${project_type}-project-config.json"
elif [[ -f "$LIB_DIR/templates/generic/config.json" ]]; then
    template_config="$LIB_DIR/templates/generic/config.json"
fi

# AI style guide locations
for location in ".ai-docs-style.md" "$HOME/.ai-docs-style.md" "/usr/local/share/.ai-docs-style.md"; do
    if [[ -f "$location" ]]; then
        style_guide="$location"
        break
    fi
done
```

#### VitePress Configuration Generation

Phase 1 includes intelligent VitePress configuration generation:

```bash
# From lib/docs-generation.sh:109-145
5. **Generate VitePress Configuration**:
   - Create docs/.vitepress/config.ts based on your analysis
   - Auto-detect project name, description from package.json/README
   - For mobile apps, find and use app icon from Assets/Resources
   - Build sidebar structure matching your planned documentation
   - Include proper navigation categories
   - Set up social links based on detected repository
   - Enable 3-column layout with outline configuration
```

**Critical Link Validation**:
```bash
6. **Validate All Links**:
   CRITICAL: Every link in config.ts MUST correspond to a file you plan to create!
   - For each sidebar item link (e.g., '/guide/setup'), ensure you're creating 'guide/setup.md'
   - For hash links (e.g., '/guide/setup#installation'), ensure that heading exists
   - For nav links, verify the target files will exist
   - Use '/guide/' for index pages (maps to '/guide/index.md')
   - NO broken links allowed - this is a quality gate
```

### Phase 2: Execution

```bash
# From lib/docs-generation.sh:149-187
==== PHASE 2: EXECUTE THE PLAN ====
✏️ Now systematically execute your plan from Phase 1:

**CREATE New Documentation**:
- Generate all planned documentation files
- Use accurate, current code examples
- Follow template structures exactly
- Reference CLAUDE.md for project-specific coding patterns and conventions
- Ensure all internal links work
- Add breadcrumb navigation at the top of EVERY page
```

#### Breadcrumb Navigation

Every generated page includes consistent breadcrumb navigation:

```bash
# Breadcrumb format
- Add breadcrumb navigation at the top of EVERY page (except root):
  * Format: [Home](/) > [Section](/section/) > Current Page
  * Example: [Home](/) > [Guide](/guide/) > [Setup](/guide/setup)
  * Place as first line of content after frontmatter
  * Use descriptive names, not paths
```

#### VitePress Routing Rules

The system follows strict routing conventions:

```bash
VitePress Routing Rules:
- '/guide/' → 'docs/guide/index.md'
- '/guide/setup' → 'docs/guide/setup.md' 
- '/guide/setup#install' → 'docs/guide/setup.md' with ## Install heading
- Always create index.md for directory roots
```

## Quality Assurance

### Content Validation

```bash
🎯 Quality Checks:
- Every code example must be from actual current code
- All links must point to existing files
- Technical details must match implementation
- No hypothetical or placeholder content
```

### Obsolescence Detection

The system uses semantic analysis with high confidence thresholds:

```bash
# From lib/docs-generation.sh:105-107
- List any OBSOLETE files with 95%+ confidence
```

This conservative approach ensures valuable documentation isn't accidentally deleted.

## User Directives

The two-phase system supports focused user directives:

```bash
# From lib/docs-generation.sh:189-197
**USER DIRECTIVE (Highest Priority)**
- ${user_directive}

Strictly adhere to this directive while keeping ZERO broken links in config.ts 
and ensuring every link maps to a real file you create.
```

User directives are passed via:
```bash
claudux update -m "Create API documentation for the new authentication system"
```

## Platform Guardrails

The system includes intelligent platform-specific guardrails:

```bash
Platform guardrails:
- For non-iOS projects, DO NOT include iOS-specific concepts, links, or pages 
  (e.g., Tuist, SwiftData, CloudKit, App Store, TestFlight, Xcode). 
  Only include them for `project_type=ios`.
- Resources menu must include only links with absolute URLs you can determine
- The nav must only include sections for which you will create pages
```

## Real-Time Execution

During Phase 2 execution, the system provides real-time feedback:

```bash
# From lib/docs-generation.sh:284-324
# Run Claude with real-time output (no buffering)
if command -v stdbuf &> /dev/null; then
    stdbuf -o0 -e0 claude \
        --print \
        --model "$model" \
        --allowedTools "Read,Write,Edit,Delete" \
        --permission-mode acceptEdits \
        "$prompt" 2>&1 | tee "$claude_log" | format_claude_output
```

## Auto-Fix Capability

The system includes intelligent auto-fix for broken links:

```bash
# From lib/docs-generation.sh:362-385
# Attempt a single auto-fix pass: collect missing files and re-run with a focused directive
if [[ -z "$already_autofixed" ]]; then
    local file_list=$(sed 's#^docs/##' "$missing_tmp" | tr '\n' ' ')
    warn "🛠️  Auto-fix: asking Claude to create missing pages: $file_list"
    
    local fix_msg="Create the following missing documentation files with correct frontmatter, breadcrumbs, and minimal but accurate content; update navigation accordingly."
    
    # Mark as autofixed to avoid loops and re-run
    CLAUDUX_AUTOFIXED=1 update --strict -m "$fix_msg"
fi
```

## Benefits

### Quality Assurance
- **Comprehensive planning** prevents incomplete or inconsistent documentation
- **Link validation** ensures all navigation works correctly
- **Content accuracy** through code cross-referencing

### Efficiency
- **Single session** completes both phases without user intervention
- **Auto-fix capability** resolves common issues automatically
- **Real-time feedback** shows progress throughout generation

### Reliability
- **Conservative obsolescence detection** protects valuable content
- **Platform-aware generation** prevents irrelevant content
- **Error handling** with detailed troubleshooting guidance

The two-phase approach represents a significant advancement in AI-powered documentation generation, providing both thoroughness and reliability that single-pass systems cannot achieve.