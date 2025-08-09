import { defineConfig } from 'vite'
import path from 'path'

export default defineConfig({
  // Completely disable PostCSS
  css: {
    postcss: {}  // Empty config instead of false
  },
  
  // Prevent config file discovery from parent directories
  configFileDependencies: [],
  
  // Ensure Vite doesn't look outside docs directory
  root: process.cwd(),
  
  // Explicitly set the config search to stop at docs directory
  envDir: process.cwd(),
  
  // Override any parent project's config
  resolve: {
    alias: {}
  },
  
  // Disable any parent project plugins
  plugins: []
})