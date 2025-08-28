[Home](/) > [Examples](/examples/) > Basic Setup

# Basic Setup Examples

This guide provides step-by-step examples for setting up Claudux with different types of projects. Each example shows the complete process from installation to your first generated documentation.

## Prerequisites

Before starting any example, ensure you have:

- ✅ **Node.js 18+** installed ([nodejs.org](https://nodejs.org/))
- ✅ **Claude CLI** installed: `npm install -g @anthropic-ai/claude-code`
- ✅ **Claudux** installed: `npm install -g claudux`

Verify your setup:
```bash
claudux check
```

## Example 1: Node.js/Express API

Let's set up documentation for a typical Express.js API project.

### Project Structure
```
my-express-api/
├── package.json
├── src/
│   ├── app.js
│   ├── routes/
│   │   ├── auth.js
│   │   └── users.js
│   └── middleware/
│       └── auth.js
└── README.md
```

### Step-by-Step Setup

**1. Navigate to your project:**
```bash
cd ~/projects/my-express-api
```

**2. Run environment check:**
```bash
claudux check
```

Expected output:
```
📚 claudux - My Express API Documentation
Powered by Claude AI - Everything stays local

🔎 Environment check

• Node: v18.17.0
• Claude: claude-code 0.8.0
  Model: claude-3-5-sonnet-20241022
• docs/: not present (will be created on first run)
```

**3. Generate initial documentation:**
```bash
claudux update
```

This will:
- Detect your project as a Node.js/JavaScript project
- Analyze your Express routes and middleware
- Create comprehensive API documentation
- Set up VitePress with proper navigation

**4. Preview your documentation:**
```bash
claudux serve
```

Your docs will be available at `http://localhost:5173` with sections like:
- API Overview
- Authentication endpoints (`/auth`)
- User management endpoints (`/users`)
- Middleware documentation
- Installation and usage guides

### Using Interactive Mode

For beginners, try the interactive approach:

```bash
claudux
```

Select from the menu:
```
📚 claudux - My Express API Documentation
Powered by Claude AI - Everything stays local

Select:

  1) Generate docs              (scan code → markdown)
  2) Serve                      (vitepress dev server)
  3) Create CLAUDE.md           (AI context file)
  4) Exit

> 1
```

## Example 2: React Application

Setting up documentation for a Create React App or Vite React project.

### Project Structure
```
my-react-app/
├── package.json
├── src/
│   ├── App.js
│   ├── components/
│   │   ├── Button.jsx
│   │   ├── Modal.jsx
│   │   └── UserProfile.jsx
│   ├── hooks/
│   │   └── useAuth.js
│   └── utils/
│       └── api.js
└── public/
    └── index.html
```

### Step-by-Step Setup

**1. Navigate and check environment:**
```bash
cd ~/projects/my-react-app
claudux check
```

**2. Generate documentation:**
```bash
claudux update
```

Claudux will:
- Detect React project type from `package.json`
- Document your components with props
- Extract hook usage patterns
- Create component API documentation

**3. Serve and review:**
```bash
claudux serve
```

Generated documentation includes:
- Component library with prop documentation
- Hook API reference  
- Utility function documentation
- Usage examples extracted from your code

### Focused Updates

After initial generation, refine with specific directives:

```bash
# Focus on component documentation
claudux update -m "Document all React components with props and usage examples"

# Focus on hooks
claudux update -m "Create detailed documentation for custom hooks"

# Focus on state management
claudux update -m "Explain the state management architecture"
```

## Example 3: Next.js Application

Next.js projects get special treatment with App Router and Pages Router detection.

### Project Structure (App Router)
```
my-nextjs-app/
├── package.json
├── next.config.js
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── api/
│   │   └── users/route.ts
│   └── dashboard/
│       └── page.tsx
└── components/
    └── ui/
        ├── button.tsx
        └── card.tsx
```

### Step-by-Step Setup

**1. Navigate and initialize:**
```bash
cd ~/projects/my-nextjs-app
claudux update
```

**2. What Gets Generated:**

Claudux detects Next.js and creates:
- **Page Documentation** - All app router pages
- **API Routes** - RESTful endpoint documentation  
- **Component Library** - UI components with TypeScript props
- **Layout Documentation** - Layout patterns and metadata
- **Deployment Guide** - Next.js-specific deployment instructions

**3. Advanced Configuration:**

Create a project-specific configuration:

```bash
claudux create-template
```

This generates `CLAUDE.md` with Next.js-specific patterns like:
```markdown
# My Next.js App - AI Assistant Instructions

## Project Overview
This is a Next.js 14 application using the App Router with TypeScript.

## Key Patterns
- ALWAYS use Server Components by default
- NEVER use "use client" unless necessary for interactivity
- FOLLOW the app router file conventions (page.tsx, layout.tsx, route.ts)
- USE TypeScript strict mode for all components

## API Routes
- FOLLOW RESTful conventions in app/api/
- ALWAYS validate request bodies with Zod
- USE proper HTTP status codes

## Component Conventions  
- PLACE reusable UI components in components/ui/
- ALWAYS export TypeScript interfaces for props
- FOLLOW shadcn/ui patterns for styling
```

**4. Serve documentation:**
```bash
claudux serve
```

## Example 4: Basic Configuration File

For more control, create a `docs-ai-config.json` file:

### Configuration Example

```bash
# Create configuration file
cat > docs-ai-config.json << 'EOF'
{
  "project": {
    "name": "My Awesome API",
    "type": "nodejs"
  },
  "features": {
    "apiDocs": true,
    "examples": true,
    "tutorials": true
  },
  "claude": {
    "model": "sonnet"
  }
}
EOF
```

### Using the Configuration

```bash
# Configuration is automatically detected
claudux update
```

The configuration affects:
- **Project name** in generated documentation
- **Project type** detection override
- **Feature flags** for what content to generate
- **Model selection** for Claude API calls

### Configuration Options

```json
{
  "project": {
    "name": "Project Display Name",
    "type": "nodejs|react|nextjs|ios|python|rust|go|generic"
  },
  "features": {
    "apiDocs": true,        // Generate API documentation
    "examples": true,       // Include code examples
    "tutorials": true,      // Create tutorial content
    "deployment": true      // Add deployment guides
  },
  "claude": {
    "model": "opus|sonnet", // Claude model preference
    "verbose": true         // Enable verbose logging
  },
  "ignore": [
    "node_modules",
    "dist",
    "build"
  ]
}
```

## Interactive Mode Walkthrough

For new users, the interactive mode provides guidance:

### Running Interactive Mode

```bash
claudux
```

### First-Time Project Menu
```
📚 claudux - My Project Documentation
Powered by Claude AI - Everything stays local

Select:

  1) Generate docs              (scan code → markdown)
  2) Serve                      (vitepress dev server)
  3) Create CLAUDE.md           (AI context file)
  4) Exit

> 
```

**Option 1: Generate docs** - Runs `claudux update`
**Option 2: Serve** - Starts development server
**Option 3: Create CLAUDE.md** - Generates project context file
**Option 4: Exit** - Quit interactive mode

### Existing Project Menu

Once docs exist:
```
Select:

  1) Update docs                (regenerate from code)
  2) Update (focused)           (enter directive → update)
  3) Serve                      (vitepress dev server)
  4) Create CLAUDE.md           (AI context file)
  5) Recreate                   (start fresh)
  6) Exit
```

**New Options:**
- **Update (focused)** - Prompts for specific directive
- **Recreate** - Deletes all docs and starts fresh

### Using Focused Updates Interactively

Choose "Update (focused)" and you'll be prompted:

```
Enter focused directive (leave empty to cancel): Document the authentication system with examples

📚 claudux - My Project Documentation
Powered by Claude AI - Everything stays local

🤖 Claude analyzing project and generating documentation...
...
```

## Environment Variables

Control Claudux behavior with environment variables:

### Model Selection
```bash
# Use Claude Sonnet (faster, cheaper)
FORCE_MODEL=sonnet claudux update

# Use Claude Opus (more powerful, slower)
FORCE_MODEL=opus claudux update
```

### Verbose Logging
```bash
# Enable detailed logging
CLAUDUX_VERBOSE=1 claudux update

# Or use flag
claudux -v update
claudux -vv update  # Extra verbose
```

### Default Directives
```bash
# Set default message for updates
CLAUDUX_MESSAGE="Focus on API documentation" claudux update
```

### Combined Usage
```bash
# Sonnet model with verbose logging and custom message
FORCE_MODEL=sonnet CLAUDUX_VERBOSE=1 claudux update -m "Document React components"
```

## Common First-Time Issues

### Issue: Claude CLI Not Found
```bash
# Error: Claude CLI is required but not installed
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version
```

### Issue: Permission Denied
```bash
# If npm install fails with permissions
sudo npm install -g claudux

# Or use nvm for better Node.js management
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
npm install -g claudux
```

### Issue: Port Already in Use
```bash
# Claudux automatically finds available ports 5173-5190
claudux serve

# If all ports are busy, kill other processes
lsof -ti:5173 | xargs kill -9
```

### Issue: Generic Documentation
```bash
# Create project context for better results
claudux create-template

# Then update with context
claudux update

# Or use focused updates
claudux update -m "Document the specific authentication patterns used in this project"
```

## Success Indicators

### Good Generation Output
```bash
✅ Documentation generation complete!
📁 Created docs/ directory with 12 files
🔗 All links validated successfully
📖 VitePress configuration ready

Generated sections:
• Getting Started Guide (docs/guide/)
• API Reference (docs/api/)
• Examples (docs/examples/)
• Technical Documentation (docs/technical/)
```

### Quality Checklist

After generation, verify:
- ✅ Multiple markdown files created
- ✅ Navigation works in VitePress
- ✅ Links are valid (no 404s)
- ✅ Code examples are relevant
- ✅ Project-specific terminology used
- ✅ Content reflects your actual code

## Next Steps

Once you have basic documentation working:

1. **[Advanced Usage Examples →](advanced-usage.md)** - CI/CD integration, custom workflows
2. **[Command Reference →](/guide/commands)** - Learn all available options
3. **[Configuration Guide →](/guide/configuration)** - Customize for your needs

---

<p align="center">
  <strong>Ready for more advanced techniques?</strong><br/>
  <a href="advanced-usage.md">Explore advanced usage patterns →</a>
</p>