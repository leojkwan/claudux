# Smart Cleanup

Claudux automatically identifies and removes obsolete documentation using semantic analysis rather than simple pattern matching.

## The Documentation Rot Problem

**Traditional approaches fail:**
- Manual cleanup is time-consuming and error-prone
- Regex-based tools are too aggressive or miss subtle issues
- Stale content accumulates, confusing users

**Claudux solution:**
AI-powered semantic analysis identifies truly obsolete content with high confidence before removal.

## How Smart Cleanup Works

### 🧠 Semantic Analysis

Claudux analyzes documentation content against your current codebase:

**Code cross-referencing:**
- Function and class names mentioned in docs
- API endpoints documented vs. currently implemented
- Configuration options described vs. actually supported
- Dependencies referenced vs. currently installed

**Context understanding:**
- Distinguishes between deprecated and removed features
- Identifies redirect targets for moved content
- Preserves historical information that's still valuable
- Maintains links between related concepts

### 📊 Confidence Scoring

Cleanup decisions use confidence thresholds:

```bash
🧹 Cleanup Analysis:
📄 docs/api/legacy-auth.md
   ❌ References deleted AuthService class (95% confidence)
   ❌ Documents removed /auth/token endpoint (98% confidence)  
   ✅ REMOVE: High confidence obsolete content

📄 docs/guide/old-setup.md
   ⚠️  References deprecated setupV1() (75% confidence)
   ℹ️  KEEP: May still be relevant for migration users
```

**Threshold policy:**
- **≥95% confidence**: Automatic removal
- **75-94% confidence**: Flag for manual review
- **<75% confidence**: Preserve content

## What Gets Cleaned Up

### 🗑️ Automatically Removed

**Dead code references:**
```markdown
## Using the authenticate() method (REMOVED)
The authenticate() method was removed in v2.0...
```

**Broken API documentation:**
```markdown  
### POST /api/v1/legacy (404)
This endpoint returns user session data...
```

**Obsolete configuration:**
```yaml
# This section references deleted config.legacy.yml
legacy:
  enabled: true
```

### ⚠️ Preserved Content

**Migration documentation:**
```markdown
## Migrating from v1 to v2
While v1 APIs are deprecated, they remain supported...
```

**Troubleshooting guides:**
```markdown
## Common Issues with Legacy Setups  
If you're still using the old configuration...
```

**Historical context:**
```markdown
## Design Decision: Why We Moved Away from X
In v1, we used X for Y, but discovered...
```

## Cleanup Process

### 🔍 Detection Phase

1. **Content inventory**: Catalogs all documentation files
2. **Reference extraction**: Finds code/API references in each doc
3. **Cross-validation**: Checks references against current codebase
4. **Confidence calculation**: Scores likelihood of obsolescence

### 🧹 Removal Phase

1. **High-confidence removal**: Deletes files with ≥95% obsolescence confidence
2. **Partial cleanup**: Removes obsolete sections within otherwise valid files
3. **Link updates**: Updates internal links affected by removals
4. **Navigation cleanup**: Removes dead links from sidebar/nav

### ✅ Validation Phase

1. **Link integrity**: Ensures no broken internal links remain
2. **Content gaps**: Identifies missing documentation after cleanup
3. **Structure validation**: Confirms navigation hierarchy is intact

## Example Cleanup Session

```bash
🧹 Smart cleanup starting...

📊 Analysis Results:
• 47 documentation files scanned
• 156 code references validated
• 3 obsolete files identified
• 12 outdated sections found

🗑️ Removing obsolete content:
✓ docs/api/v1-authentication.md (96% confidence - API removed)
✓ docs/guide/old-deployment.md (98% confidence - process changed)  
✓ Section in docs/config.md about legacy.yml (94% confidence)

🔗 Updating affected links:
✓ Updated 8 internal references
✓ Removed 3 navigation entries

✅ Cleanup complete! 3 files removed, 8 files updated
```

## Manual Override Options

### Protected Content

Use skip markers to prevent cleanup of specific content:

```markdown
<!-- skip -->
## Legacy API Reference (Keep for Migration Users)
This documents the old v1 API that some users still rely on...
<!-- /skip -->
```

### Confidence Threshold Control

Adjust cleanup aggressiveness:

```bash
# Conservative cleanup (≥98% confidence)
claudux update -m "Conservative cleanup - only remove obviously obsolete content"

# Aggressive cleanup (≥85% confidence)  
claudux update -m "Aggressive cleanup - remove likely obsolete content"
```

### Dry Run Analysis

Preview what would be cleaned up without making changes:

```bash
claudux update -m "Analyze obsolete content but don't remove anything"
```

## Integration with Generation

Smart cleanup runs automatically during `claudux update`:

1. **Pre-generation cleanup**: Remove high-confidence obsolete files
2. **Content generation**: Create/update documentation  
3. **Post-generation validation**: Final link check and structure validation

This ensures the generation process works with clean, accurate existing content.

## Safety Features

### 🛡️ Protected Paths

Cleanup never touches protected directories:
- `notes/`, `private/`
- `.git/`, `node_modules/`  
- Any path matching protection patterns in `lib/content-protection.sh`

### 📝 Change Logging

All cleanup actions are logged:

```bash
📋 Cleanup Summary:
🗑️ Removed: docs/api/legacy.md (confidence: 96%)
📝 Updated: docs/guide/setup.md (removed legacy section)
🔗 Fixed: 5 broken internal links
```

### 🔄 Reversible Actions

Since claudux works with git repositories:
- All changes are trackable via git history
- Easy to revert: `git checkout -- docs/`
- Commit-by-commit review of cleanup decisions

## Best Practices

**Regular cleanup:**
```bash
# Weekly/monthly cleanup
claudux update  # Includes cleanup automatically
```

**Before major releases:**
```bash
claudux update -m "Thorough cleanup before v2.0 release"
```

**Migration periods:**
```bash
claudux update -m "Clean up v1 docs but preserve migration guides"
```

The smart cleanup feature ensures your documentation stays lean, accurate, and trustworthy without manual maintenance overhead.