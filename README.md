# Rustline Reclaimer

Rustline Reclaimer is a static browser game for Turnloop. The player pilots and maintains an upgradable train base while reclaiming anomalous rail infrastructure.

## Local Commands

```bash
npm install
npm run dev
npm test
npm run build
npm run preview
```

## Architecture

- Vite and TypeScript build source files into the tracked `site/` static output.
- Three.js renders the active rail corridor.
- Simulation state lives outside Three.js objects.
- DOM overlays render HUD, repair prompts, briefing, and recovery states.
- The first playable intentionally avoids physics middleware and imported 3D models.

## Deployment Surface

The generated `site/` directory is the deployable static surface. Edit source files in `src/`, not generated files under `site/assets/`.
