# Protection Marker Examples

Here are examples of how to protect your content from AI updates:

## 1. Protect entire files
Add this at the very top of any file:

```markdown
<!-- AI: DO NOT EDIT -->
# My Personal Implementation Notes

This entire file is protected from AI updates.
```

## 2. Protect specific sections

```markdown
# Setup Guide

This section will be updated by AI...

<!-- #leave-alone -->
## My Personal Setup

I use these specific tools:
- Custom Xcode shortcuts
- My specific git workflow
- Personal debugging techniques

Don't change this part!
<!-- #/leave-alone -->

This section can be updated by AI again...
```

## 3. Alternative protection markers

```markdown
# Data Models

<!-- MANUAL START -->
## My Custom Implementation Notes

I've implemented a specific pattern here that handles edge cases:
1. Custom error handling
2. Specific CloudKit sync patterns
3. Performance optimizations

These are my personal design decisions.
<!-- MANUAL END -->
```

## 4. Inline protection

```markdown
The standard way to do X is with method Y. #leave-alone However, I personally prefer method Z because of my specific requirements. #leave-alone

The AI can update this part normally.
```

## 5. Protected folders

Simply create folders named:
- `notes/` - Personal project notes
- `personal/` - Personal content
- `private/` - Private documentation

These folders are automatically skipped by AI updates.

## Tips:

- **Use protection sparingly** - Only protect what you actually wrote personally
- **Be explicit** - Mark the exact sections you want preserved
- **Keep it simple** - Use `<!-- #leave-alone -->` for most cases
- **Document why** - Add a comment explaining why you're protecting something 