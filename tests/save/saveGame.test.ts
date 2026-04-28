import { beforeEach, describe, expect, it } from 'vitest';
import { INITIAL_WORLD } from '../../src/game/content/world';
import {
  advanceEncounter,
  advanceTravel,
  createInitialGameState,
  reclaimStation,
  repairGate,
  startEngine
} from '../../src/game/simulation/gameState';
import { clearSave, loadGame, saveGame, SAVE_KEY } from '../../src/game/save/saveGame';

const gateId = 'bridge-7';
const stationId = 'threshold-station';

function legallyProgressedState() {
  const started = startEngine(createInitialGameState(INITIAL_WORLD));
  const encounter = advanceTravel(started, 7);
  const cleared = advanceEncounter(advanceEncounter(encounter, 'direct-turret-hit'), 'direct-turret-hit');
  const blocked = advanceTravel(cleared, 10);
  const repaired = repairGate(blocked, gateId);
  const stationReady = advanceTravel(repaired, 5);

  return reclaimStation(stationReady, stationId);
}

describe('saveGame persistence', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('returns null when no save exists', () => {
    expect(loadGame()).toBeNull();
  });

  it('round-trips legally progressed game state through localStorage', () => {
    const state = legallyProgressedState();

    saveGame(state);

    const loaded = loadGame();

    expect(loaded).toEqual(state);
    expect(loaded?.gates[gateId].status).toBe('open');
    expect(loaded?.stations[stationId].status).toBe('reclaimed');
    expect(loaded?.train.modules.some((module) => module.id === 'repair-bay' && module.unlocked)).toBe(true);
    expect(loaded?.availableModules['repair-bay']).toMatchObject({ id: 'repair-bay', unlocked: false });
    expect(loaded?.scrap).toBe(state.scrap);
    expect(loaded?.train.durability).toBe(state.train.durability);
  });

  it('returns null for malformed JSON', () => {
    localStorage.setItem(SAVE_KEY, '{not valid json');

    expect(loadGame()).toBeNull();
  });

  it('returns null for unsupported versions', () => {
    localStorage.setItem(SAVE_KEY, JSON.stringify({ version: 2, state: legallyProgressedState() }));

    expect(loadGame()).toBeNull();
  });

  it('removes an existing save', () => {
    saveGame(legallyProgressedState());

    clearSave();

    expect(localStorage.getItem(SAVE_KEY)).toBeNull();
    expect(loadGame()).toBeNull();
  });
});
