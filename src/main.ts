import './styles/app.css';

import { INITIAL_WORLD } from './game/content/world';
import { actionForKey } from './game/input/inputMap';
import { loadGame, saveGame } from './game/save/saveGame';
import {
  advanceEncounter,
  advanceTravel,
  createInitialGameState,
  reclaimStation,
  recoverTrain,
  repairGate,
  startEngine
} from './game/simulation/gameState';
import type { GameState } from './game/simulation/types';
import { samplePerf } from './diagnostics/perf';
import { syncRailScene } from './render/adapters/renderBridge';
import { createThreeApp, type ThreeApp } from './render/app/createThreeApp';
import { syncFollowTrainCamera } from './render/camera/followTrainCamera';
import { createRailScene, type RailSceneObjects } from './render/objects/createRailScene';
import { renderHud, type UiAction } from './ui/hud/renderHud';
import { renderOverlay } from './ui/overlays/renderOverlay';
import { createUiRenderSnapshot, sameUiRenderSnapshot, type UiRenderSnapshot } from './ui/renderUiSnapshot';

function requiredElement<T extends Element>(selector: string, type: { new (): T }): T {
  const element = document.querySelector(selector);
  if (!(element instanceof type)) {
    throw new Error(`Rustline Reclaimer boot failed: missing required ${selector} element.`);
  }
  return element;
}

const canvas = requiredElement('#game-canvas', HTMLCanvasElement);
const hudRoot = requiredElement('#hud-root', HTMLElement);
const overlayRoot = requiredElement('#overlay-root', HTMLElement);
const webglFallback = requiredElement('#webgl-fallback', HTMLElement);

let state: GameState = loadGame() ?? createInitialGameState(INITIAL_WORLD);
let threeApp: ThreeApp | null = null;
let railScene: RailSceneObjects | null = null;
let animationFrameId: number | null = null;
let lastUiRenderSnapshot: UiRenderSnapshot | null = null;

function hasMeaningfulProgress(currentState: GameState): boolean {
  return (
    currentState.phase === 'complete' ||
    currentState.gates['bridge-7']?.status === 'open' ||
    currentState.train.modules.some((module) => module.id === 'repair-bay')
  );
}

function persistProgress(): void {
  if (hasMeaningfulProgress(state)) {
    saveGame(state);
  }
}

function renderUi(force = false): void {
  const nextSnapshot = createUiRenderSnapshot(state);
  if (!force && sameUiRenderSnapshot(lastUiRenderSnapshot, nextSnapshot)) {
    return;
  }

  lastUiRenderSnapshot = nextSnapshot;
  const callbacks = { onAction: handleAction };
  renderHud(hudRoot, state, callbacks);
  renderOverlay(overlayRoot, state, callbacks);
}

function handleAction(action: UiAction): void {
  switch (action) {
    case 'start-engine':
      state = startEngine(state);
      break;
    case 'fire-turret':
      state = advanceEncounter(state, 'direct-turret-hit');
      break;
    case 'brace':
      state = advanceEncounter(state, 'brace');
      break;
    case 'repair-gate':
      state = repairGate(state, 'bridge-7');
      break;
    case 'reclaim-station':
      state = reclaimStation(state, 'threshold-station');
      break;
    case 'recover-train':
      state = recoverTrain(state);
      break;
  }

  persistProgress();
  renderUi();
}

function handleKeyDown(event: KeyboardEvent): void {
  const action = actionForKey(event.key);
  if (action === null) {
    return;
  }

  event.preventDefault();
  handleAction(action);
}

function handleCanvasClick(): void {
  handleAction('fire-turret');
}

function tick(): void {
  if (threeApp === null || railScene === null) {
    return;
  }

  const delta = Math.min(0.05, threeApp.clock.getDelta());
  if (state.phase === 'travel') {
    const previousPhase = state.phase;
    const nextState = advanceTravel(state, delta);
    if (nextState !== state) {
      state = nextState;
      if (state.phase !== previousPhase) {
        persistProgress();
      }
      renderUi();
    }
  }

  syncRailScene(railScene, state);
  syncFollowTrainCamera(threeApp.camera, railScene.train, delta);
  const perf = samplePerf(threeApp.renderer);
  document.documentElement.style.setProperty('--debug-fps', String(perf.fps));
  threeApp.render();
  animationFrameId = window.requestAnimationFrame(tick);
}

function bootRenderer(): void {
  try {
    threeApp = createThreeApp(canvas);
    railScene = createRailScene();
    threeApp.scene.add(railScene.root);
  } catch (error) {
    webglFallback.hidden = false;
    throw error;
  }
}

function cleanup(): void {
  if (animationFrameId !== null) {
    window.cancelAnimationFrame(animationFrameId);
    animationFrameId = null;
  }

  window.removeEventListener('keydown', handleKeyDown);
  canvas.removeEventListener('click', handleCanvasClick);
  railScene?.dispose();
  railScene = null;
  threeApp?.dispose();
  threeApp = null;
}

bootRenderer();
renderUi(true);
window.addEventListener('keydown', handleKeyDown);
canvas.addEventListener('click', handleCanvasClick);
tick();

import.meta.hot?.dispose(cleanup);
