#!/bin/bash
# Documentation server functions

# Start VitePress documentation server
serve() {
    info "🌐 Starting documentation server..."
    
    # Create minimal docs if it doesn't exist
    if [[ ! -d "docs" ]]; then
        warn "📄 Creating minimal docs setup..."
        mkdir -p docs
        cat > docs/index.md << 'EOF'
# Project Documentation

Documentation is being set up. Run `./claudux update` to generate full docs.

## Quick Start

1. Run `./claudux update` to generate documentation
2. Run `./claudux serve` to view the docs
3. Visit http://localhost:5173

## Features

This documentation is powered by:
- **Claude AI** for intelligent content generation
- **VitePress** for beautiful, fast documentation sites
- **Automatic link validation** to prevent 404s
- **Semantic obsolescence detection** to keep docs fresh
EOF
    fi
    
    # Set up VitePress if needed
    if [[ ! -f "docs/package.json" ]]; then
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