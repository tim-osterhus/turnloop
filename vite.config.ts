import { defineConfig } from 'vitest/config';

export default defineConfig({
  base: './',
  publicDir: 'public',
  build: {
    outDir: 'site',
    emptyOutDir: true,
    sourcemap: true,
    target: 'es2022'
  },
  test: {
    environment: 'jsdom',
    globals: true
  }
});
