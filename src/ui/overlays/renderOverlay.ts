import type { GameState } from '../../game/simulation/types';
import type { UiAction } from '../hud/renderHud';

export interface OverlayCallbacks {
  onAction: (action: UiAction) => void;
}

function wireAction(root: HTMLElement, action: UiAction, callbacks: OverlayCallbacks): void {
  root.querySelector<HTMLButtonElement>(`[data-action="${action}"]`)?.addEventListener('click', () => {
    callbacks.onAction(action);
  });
}

export function renderOverlay(root: HTMLElement, state: GameState, callbacks: OverlayCallbacks): void {
  if (state.phase === 'briefing') {
    root.innerHTML = `
      <section class="overlay briefing-overlay">
        <h1>Rustline Reclaimer</h1>
        <p>Bring a containment maintenance train back online and reclaim the broken rail corridor under procedure.</p>
        <button type="button" data-action="start-engine">Start engine</button>
      </section>
    `;
    wireAction(root, 'start-engine', callbacks);
    return;
  }

  if (state.phase === 'disabled') {
    root.innerHTML = `
      <section class="overlay disabled-overlay">
        <h1>Recovery required</h1>
        <p>Recovery crews can restore the train enough to continue the reclamation route.</p>
        <button type="button" data-action="recover-train">Recover train</button>
      </section>
    `;
    wireAction(root, 'recover-train', callbacks);
    return;
  }

  if (state.phase === 'complete') {
    root.innerHTML = `
      <section class="overlay complete-overlay">
        <h1>Station reclaimed</h1>
        <p>Threshold Station is secured and the repair bay is attached to the consist.</p>
      </section>
    `;
    return;
  }

  root.innerHTML = '';
}
