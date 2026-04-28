import type { GameState } from '../simulation/types';

export const SAVE_KEY = 'rustline-reclaimer-save-v1';

interface SavePayload {
  version: 1;
  state: GameState;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isSavePayload(value: unknown): value is SavePayload {
  return isRecord(value) && value.version === 1 && isRecord(value.state);
}

export function saveGame(state: GameState): void {
  const payload: SavePayload = { version: 1, state };
  localStorage.setItem(SAVE_KEY, JSON.stringify(payload));
}

export function loadGame(): GameState | null {
  const rawSave = localStorage.getItem(SAVE_KEY);
  if (rawSave === null) {
    return null;
  }

  try {
    const payload: unknown = JSON.parse(rawSave);
    return isSavePayload(payload) ? payload.state : null;
  } catch {
    return null;
  }
}

export function clearSave(): void {
  localStorage.removeItem(SAVE_KEY);
}
