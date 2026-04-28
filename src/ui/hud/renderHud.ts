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

const ACTIONS_BY_PHASE: Record<GameState['phase'], UiAction[]> = {
  briefing: ['start-engine'],
  ready: ['start-engine'],
  travel: [],
  blocked: ['repair-gate'],
  encounter: ['fire-turret', 'brace'],
  station: ['reclaim-station'],
  disabled: ['recover-train'],
  complete: []
};

const ACTION_KEYS: Record<UiAction, string> = {
  'start-engine': 'E',
  'fire-turret': 'F/SP',
  brace: 'B',
  'repair-gate': 'R',
  'reclaim-station': 'C',
  'recover-train': 'X'
};

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function renderThreat(state: GameState): string {
  const threat = state.phase === 'encounter' ? state.encounter.threats.find((candidate) => candidate.health > 0) : null;
  if (!threat) {
    return '<p class="hud-threat"><span>Target</span>Threat None</p>';
  }

  return `<p class="hud-threat"><span>Target</span>${escapeHtml(threat.name)} ${threat.health}/${threat.maxHealth}</p>`;
}

function renderModules(state: GameState): string {
  const modules = state.train.modules
    .map((module) => `<li><span>${escapeHtml(module.kind)}</span>${escapeHtml(module.name)}</li>`)
    .join('');

  return `<ul class="hud-modules">${modules}</ul>`;
}

function renderActions(state: GameState): string {
  const visibleActions = new Set(ACTIONS_BY_PHASE[state.phase]);
  const actions = HUD_ACTIONS.filter(({ action }) => visibleActions.has(action));
  if (actions.length === 0) {
    return '<p class="switchboard-empty">No manual procedure armed</p>';
  }

  return actions.map(
    ({ action, label }) => `
      <button type="button" data-action="${action}">
        <span class="switch-label">${label}</span>
        <span class="switch-key">KEY ${ACTION_KEYS[action]}</span>
      </button>
    `
  ).join('');
}

export function renderHud(root: HTMLElement, state: GameState, callbacks: HudCallbacks): void {
  const routeProgress = Math.round(state.route.progress);

  root.innerHTML = `
    <section class="hud-shell">
      <header class="hud-objective-chip">
        <span class="hud-title">Rustline Reclaimer</span>
        <span class="hud-kicker">LINE DIRECTIVE</span>
        <p>${escapeHtml(state.message)}</p>
      </header>
      <section class="hud-instrument-strip" aria-label="Train status">
        <p><span>Durability </span>${state.train.durability}/${state.train.maxDurability}</p>
        <p><span>Scrap </span>${state.scrap}</p>
        <p><span>Route </span>${routeProgress}%</p>
        ${renderThreat(state)}
      </section>
      <div class="hud-reticle" aria-hidden="true"></div>
      <section class="hud-switchboard" aria-label="Train actions">
        <span class="switchboard-label">Manual rail controls</span>
        ${renderActions(state)}
      </section>
      <section class="hud-consist-ribbon" aria-label="Train modules">
        <h2>Consist</h2>
        ${renderModules(state)}
      </section>
    </section>
  `;

  root.querySelectorAll<HTMLButtonElement>('[data-action]').forEach((button) => {
    const action = button.dataset.action as UiAction;
    button.addEventListener('click', () => callbacks.onAction(action));
  });
}
