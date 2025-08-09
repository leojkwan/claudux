#!/bin/bash
# Documentation server functions

# Start VitePress documentation server
serve() {
    info "🌐 Starting documentation server..."
    
    # Check if docs exist and have content
    if [[ ! -d "docs" ]] || [[ ! -f "docs/index.md" ]]; then
        warn "📄 No documentation found!"
        echo ""
        echo "You need to generate documentation first."
        echo "Run: claudux update (or select option 1 from the menu)"
        echo ""
        read -p "Would you like to generate docs now? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update
            return
        else
            warn "Creating minimal docs setup for preview..."
            mkdir -p docs
            cat > docs/index.md << 'EOF'
# Project Documentation

Documentation has not been generated yet.

## Quick Start

1. Run `claudux update` to generate documentation
2. Run `claudux serve` to view the docs
3. Visit http://localhost:5173

## Features

This documentation is powered by:
- **Claude AI** for intelligent content generation
- **VitePress** for beautiful, fast documentation sites
- **Automatic link validation** to prevent 404s
- **Semantic obsolescence detection** to keep docs fresh
EOF
        fi
    fi
    
    # Set up VitePress if needed (also check for vite.config.js and postcss.config.js for isolation)
    if [[ ! -f "docs/package.json" ]] || [[ ! -f "docs/vite.config.js" ]] || [[ ! -f "docs/postcss.config.js" ]]; then
        warn "📦 Setting up VitePress..."
        if ! "$LIB_DIR/vitepress/setup.sh"; then
            error_exit "Failed to set up VitePress"
        fi
    fi
    
    # Change to docs directory and start server
    if ! cd docs; then
        error_exit "Failed to access docs directory"
    fi
    
    # Install dependencies if needed
    # Check if node_modules exists and has vitepress installed
    if [[ ! -d "node_modules" ]] || [[ ! -d "node_modules/vitepress" ]]; then
        warn "📦 Installing docs dependencies..."
        if ! npm install --no-audit --no-fund 2>&1 | grep -v "npm error A complete log"; then
            error_exit "Failed to install dependencies. Check npm configuration."
        fi
    else
        # Dependencies already installed - just show a quick message
        info "✅ Dependencies already installed"
    fi
    
    # Check if docs:dev script exists
    if ! npm run 2>/dev/null | grep -q "docs:dev"; then
        error_exit "docs:dev script not found in package.json. Run setup again."
    fi
    
    success "📖 Docs available at: http://localhost:5173"
    echo ""
    info "Press Ctrl+C to stop the server"
    echo ""
    
    # Start the dev server
    npm run docs:dev
}