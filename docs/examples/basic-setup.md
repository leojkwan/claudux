[Home](/) > [Examples](/examples/) > Basic Setup

# Basic Setup Example

A step-by-step walkthrough of setting up Claudux for a typical JavaScript project.

## Project Overview

We'll document a sample React application with the following structure:

```
my-react-app/
├── src/
│   ├── components/
│   │   ├── Button.jsx
│   │   ├── Card.jsx
│   │   └── Header.jsx
│   ├── hooks/
│   │   ├── useAuth.js
│   │   └── useData.js
│   ├── services/
│   │   └── api.js
│   └── App.jsx
├── package.json
└── README.md
```

## Step 1: Install Claudux

```bash
# Install globally
npm install -g claudux

# Verify installation
claudux version
```

## Step 2: Initial Setup

Navigate to your project:

```bash
cd my-react-app
```

Check environment:

```bash
claudux check
```

Output:
```
🔎 Environment check

• Node: v18.17.0 ✓
• Claude: claude-code v1.2.3 ✓
• Authentication: Valid ✓
• Project type: react
• docs/: not present (will be created)
```

## Step 3: Generate Documentation

Run the update command:

```bash
claudux update
```

Watch the process:
```
🚀 Claudux - AI-Powered Documentation Generator

📝 Generating documentation...
✓ Project type detected: react
✓ Loading configuration...
✓ Analyzing codebase structure...
  - Found 3 components
  - Found 2 custom hooks
  - Found API service
✓ Creating documentation plan...
✓ Generating documentation files...
  - Created docs/index.md
  - Created docs/guide/installation.md
  - Created docs/components/button.md
  - Created docs/components/card.md
  - Created docs/components/header.md
  - Created docs/hooks/use-auth.md
  - Created docs/hooks/use-data.md
  - Created docs/api/services.md
✓ Setting up VitePress configuration...
✓ Cleaning obsolete files...

✅ Documentation generated successfully!
📁 Created 12 files in ./docs
🚀 Run 'claudux serve' to preview
```

## Step 4: Review Generated Structure

Check what was created:

```bash
tree docs -L 2
```

Output:
```
docs/
├── .vitepress/
│   └── config.ts
├── index.md
├── guide/
│   ├── index.md
│   ├── installation.md
│   └── quickstart.md
├── components/
│   ├── index.md
│   ├── button.md
│   ├── card.md
│   └── header.md
├── hooks/
│   ├── index.md
│   ├── use-auth.md
│   └── use-data.md
└── api/
    ├── index.md
    └── services.md
```

## Step 5: Preview Documentation

Start the development server:

```bash
claudux serve
```

Output:
```
🚀 Starting VitePress development server...
✓ Installing dependencies...
✓ Server running at http://localhost:5173
✓ Opening browser...
Press Ctrl+C to stop
```

## Step 6: Customize Configuration

Create project configuration:

```bash
cat > docs-ai-config.json << 'EOF'
{
  "projectName": "My React App",
  "primaryLanguage": "javascript",
  "frameworks": ["react"],
  "features": {
    "apiDocs": true,
    "tutorials": true,
    "examples": true
  }
}
EOF
```

## Step 7: Add Custom Instructions

Create AI instructions:

```bash
cat > CLAUDE.md << 'EOF'
# My React App Documentation

## Project Context
This is a React application for task management.

## Documentation Requirements
- Include component prop tables
- Add usage examples for each component
- Document hook dependencies
- Show API request/response examples

## Code Style
- Functional components only
- Hooks for state management
- Async/await for API calls
EOF
```

## Step 8: Update with Customization

Regenerate with new configuration:

```bash
claudux update
```

Notice the difference:
- More detailed component documentation
- Prop tables for components
- Usage examples
- API request/response examples

## Step 9: Protect Custom Content

Add custom content with protection:

```bash
cat >> docs/deployment.md << 'EOF'
# Deployment Guide

## Standard Deployment
This section will be updated by Claudux.

<!-- CLAUDUX:PROTECTED:START -->
## Production Deployment

Our specific deployment process:
1. Run tests: npm test
2. Build: npm run build
3. Deploy to AWS: ./deploy.sh prod
4. Verify: https://app.example.com

API Keys are in 1Password.
Database connection string in AWS Secrets Manager.
<!-- CLAUDUX:PROTECTED:END -->
EOF
```

## Step 10: Regular Updates

After making code changes:

```bash
# Quick update
claudux update

# Or with specific focus
claudux update -m "Update component documentation with new props"
```

## Generated Documentation Examples

### Component Documentation

`docs/components/button.md`:
```markdown
[Home](/) > [Components](/components/) > Button

# Button Component

A reusable button component with multiple variants and sizes.

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `variant` | `'primary' \| 'secondary' \| 'danger'` | `'primary'` | Button style variant |
| `size` | `'small' \| 'medium' \| 'large'` | `'medium'` | Button size |
| `onClick` | `() => void` | - | Click handler |
| `disabled` | `boolean` | `false` | Disable button |
| `children` | `ReactNode` | - | Button content |

## Usage

\```jsx
import { Button } from './components/Button';

function App() {
  return (
    <Button 
      variant="primary" 
      size="large"
      onClick={() => console.log('Clicked!')}
    >
      Click Me
    </Button>
  );
}
\```

## Examples

### Primary Button
\```jsx
<Button variant="primary">Save</Button>
\```

### Danger Button
\```jsx
<Button variant="danger" onClick={handleDelete}>
  Delete
</Button>
\```
```

### Hook Documentation

`docs/hooks/use-auth.md`:
```markdown
[Home](/) > [Hooks](/hooks/) > useAuth

# useAuth Hook

Custom hook for authentication management.

## Usage

\```javascript
import { useAuth } from '../hooks/useAuth';

function Profile() {
  const { user, login, logout, isAuthenticated } = useAuth();
  
  if (!isAuthenticated) {
    return <LoginForm onLogin={login} />;
  }
  
  return (
    <div>
      <h1>Welcome, {user.name}</h1>
      <button onClick={logout}>Logout</button>
    </div>
  );
}
\```

## Return Value

| Property | Type | Description |
|----------|------|-------------|
| `user` | `User \| null` | Current user object |
| `isAuthenticated` | `boolean` | Authentication status |
| `login` | `(credentials) => Promise<void>` | Login function |
| `logout` | `() => void` | Logout function |
| `loading` | `boolean` | Loading state |

## Dependencies

This hook uses:
- React Context API for state management
- localStorage for token persistence
- API service for authentication requests
```

## Tips for Best Results

1. **Clean Code**: Ensure code is well-organized before generation
2. **Meaningful Names**: Use descriptive file and function names
3. **Comments Help**: Add JSDoc comments for better documentation
4. **Regular Updates**: Run `claudux update` after significant changes
5. **Review Output**: Always review generated documentation

## Common Customizations

### Focus on Specific Areas

```bash
# Only update API documentation
claudux update -m "Focus only on API documentation in src/services"

# Update component examples
claudux update -m "Add more usage examples for all components"
```

### Different Models for Different Needs

```bash
# Quick update with faster model
claudux update --force-model haiku

# Comprehensive update with best model
claudux update --force-model opus
```

## Troubleshooting

### If Documentation Seems Generic

Add more specific instructions in `CLAUDE.md`:
```markdown
## Specific Requirements
- Document Redux actions and reducers
- Include React Router examples
- Show form validation patterns
- Document error handling
```

### If Files Are Missing

Check project detection:
```bash
claudux check
```

Ensure files follow expected patterns for your project type.

## Next Steps

- Add more [configuration](/guide/configuration)
- Explore [advanced usage](/examples/advanced-usage)
- Set up [CI/CD integration](/examples/#cicd-integration)
- Learn about [content protection](/features/content-protection)

## Summary

You've successfully:
- ✅ Installed Claudux
- ✅ Generated documentation
- ✅ Customized configuration
- ✅ Added AI instructions
- ✅ Protected custom content
- ✅ Learned update workflow

Your documentation is now ready to maintain and grow with your project!