import baseConfig from '../docs/.vitepress/config'
import { defineConfig } from 'vitepress'

// GitHub Pages only. Keeps override outside docs/ so local "recreate" won't delete it.
export default defineConfig({
  ...baseConfig,
  base: '/claudux/'
})


