# Two-Phase Generation

Claudux uses a structured two-phase approach to ensure accurate, comprehensive documentation generation.

## Why Two Phases?

**Problem**: Single-pass generation often produces:
- Inconsistent navigation structure
- Missing cross-references between pages
- Outdated content mixed with new content
- Broken internal links

**Solution**: Plan first, then execute systematically.

## Phase 1: Analysis & Planning

### 🔍 Configuration Loading

Reads all relevant configuration files:

```bash
# Project configuration
claudux.json                    # Project settings
CLAUDE.md                      # Coding patterns and conventions

# Template configuration  
lib/templates/{type}/config.json # Project-type specific structure

# Documentation preferences
claudux.md                     # Site structure preferences (if exists)
```

### 📊 Codebase Analysis

Scans source code to understand:

**Architecture patterns:**
- Entry points and main modules
- Import/export relationships
- Framework usage (React, Express, FastAPI, etc.)
- Testing approaches

**Code organization:**
- Directory structure and naming conventions
- Configuration file patterns
- Build and deployment setup
- Documentation style (if exists)

**Example analysis output:**
```
📊 Project Analysis Results:
• Type: Next.js application
• Entry points: pages/, app/, components/
• API routes: pages/api/, app/api/
• Testing: Jest + React Testing Library
• Deployment: Vercel configuration detected
```

### 📋 Documentation Audit

Reviews existing documentation:

**Content analysis:**
- Cross-references docs against current code
- Identifies outdated sections (confidence scores)
- Finds missing documentation gaps
- Detects broken internal links

**Structure analysis:**
- Evaluates current navigation hierarchy
- Identifies redundant or obsolete pages
- Plans optimal information architecture

### 🗺️ Execution Planning

Creates a detailed plan before making changes:

**New files to create:**
```
✨ NEW FILES:
- docs/guide/deployment.md (Vercel deployment guide)
- docs/api/authentication.md (New auth endpoints)
- docs/examples/hooks.md (React hooks examples)
```

**Files to update:**
```
📝 UPDATES:
- docs/guide/installation.md (Update Node version requirement)
- docs/api/routes.md (Add 3 new API endpoints)
```

**Files to remove:**
```
🗑️ OBSOLETE (95% confidence):
- docs/legacy/old-api.md (References deleted endpoints)
```

### ⚙️ VitePress Configuration Generation

Generates optimized VitePress config:

**Auto-detected elements:**
- Project name and description from `package.json`
- Repository links from git remote
- Logo/icon detection
- Social links (GitHub, npm)

**Navigation structure:**
- Sidebar hierarchy matching planned docs
- Cross-section consistency
- Mobile-optimized navigation
- Breadcrumb integration

## Phase 2: Execution

### 📝 Content Generation

Executes the plan systematically:

**Creation process:**
1. Generate new documentation files
2. Update existing content with current information
3. Remove obsolete files (high confidence only)
4. Update VitePress configuration

**Quality controls:**
- Every code example from actual source
- All internal links verified before creation
- Consistent terminology across pages
- No placeholder or hypothetical content

### 🔗 Link Validation

Final validation pass:

```bash
🔍 Validating documentation links...
✅ Internal links: 47/47 valid
✅ Anchor links: 23/23 valid  
✅ Asset references: 12/12 valid
⚠️  External links: 2 timeouts (non-critical)
```

**Auto-fix capability:**
If validation finds missing pages, claudux can automatically create minimal placeholder content and retry validation.

## Benefits of Two-Phase Approach

### 🎯 Accuracy

- **Consistent structure**: All pages follow planned hierarchy
- **Complete coverage**: Nothing gets missed in analysis phase
- **Current content**: Everything reflects actual code state

### 🚀 Performance  

- **Efficient AI usage**: Single comprehensive analysis vs multiple queries
- **Reduced regeneration**: Only updates what actually changed
- **Faster iterations**: Plan guides focused updates

### 🛠️ Reliability

- **Predictable output**: Plan phase catches issues before generation
- **Link integrity**: All links validated before file creation  
- **Error recovery**: Failed generations don't leave partial artifacts

## Monitoring Phase Progress

During generation, claudux shows real-time progress:

```bash
📊 Phase 1: Analyzing project structure...
✅ Configuration loaded
✅ Codebase scanned (247 files)  
✅ Documentation audit complete
✅ Execution plan created

📝 Phase 2: Generating documentation...
✨ Created docs/guide/deployment.md
📝 Updated docs/api/routes.md  
🔗 Validating links... ✅ 47/47 valid
✅ Documentation generation complete!
```

## Customizing the Process

### Focused Directives

Guide the planning phase with specific instructions:

```bash
claudux update -m "Focus on API documentation and add more code examples"
```

The directive influences both phases:
- **Phase 1**: Analysis prioritizes API-related code
- **Phase 2**: Generation emphasizes API docs and examples

### Template Customization

Modify project-type templates in `lib/templates/{type}/config.json` to change:
- Default documentation structure
- Sidebar organization preferences  
- Required vs optional sections
- Code example priorities

This ensures the planning phase uses your preferred patterns for similar projects.