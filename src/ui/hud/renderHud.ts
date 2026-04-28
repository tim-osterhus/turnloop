import type { GameState } from '../../game/simulation/types';

export type UiAction =
  | 'start-engine'
  | 'fire-turret'
  | 'brace'
  | 'repair-gate'
  | 'reclaim-station'
  | 'recover-train';

export interface HudCallbacks {
  onAction: (action: UiAction) => void;
}

const HUD_ACTIONS: Array<{ action: UiAction; label: string }> = [
  { action: 'start-engine', label: 'Start engine' },
  { action: 'fire-turret', label: 'Fire turret' },
  { action: 'brace', label: 'Brace' },
  { action: 'repair-gate', label: 'Repair gate' },
  { action: 'reclaim-station', label: 'Reclaim station' },
  { action: 'recover-train', label: 'Recover train' }
];

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function renderThreat(state: GameState): string {
  const threat = state.encounter.threats[0];
  if (!threat) {
    return '<p class="hud-threat">Threat None</p>';
  }

  return `<p class="hud-threat">Threat ${escapeHtml(threat.name)} ${threat.health}/${threat.maxHealth}</p>`;
}

function renderModules(state: GameState): string {
  const modules = state.train.modules
    .map((module) => `<li>${escapeHtml(module.name)}</li>`)
    .join('');

  return `<ul class="hud-modules">${modules}</ul>`;
}

function renderActions(): string {
  return HUD_ACTIONS.map(
    ({ action, label }) => `<button type="button" data-action="${action}">${label}</button>`
  ).join('');
}

export function renderHud(root: HTMLElement, state: GameState, callbacks: HudCallbacks): void {
  const routeProgress = Math.round(state.route.progress);

  root.innerHTML = `
    <section class="hud-shell">
      <header class="hud-brand">
        <h1>Rustline Reclaimer</h1>
        <p>${escapeHtml(state.message)}</p>
      </header>
      <section class="hud-stats" aria-label="Train status">
        <p>Durability ${state.train.durability}/${state.train.maxDurability}</p>
        <p>Scrap ${state.scrap}</p>
        <p>Route ${routeProgress}%</p>
      </section>
      <section class="hud-encounter" aria-label="Encounter status">
        ${renderThreat(state)}
      </section>
      <section class="hud-actions" aria-label="Train actions">
        ${renderActions()}
      </section>
      <section class="hud-consist" aria-label="Train modules">
        <h2>Train modules</h2>
        ${renderModules(state)}
      </section>
    </section>
  `;

  root.querySelectorAll<HTMLButtonElement>('[data-action]').forEach((button) => {
    const action = button.dataset.action as UiAction;
    button.addEventListener('click', () => callbacks.onAction(action));
  });
}
