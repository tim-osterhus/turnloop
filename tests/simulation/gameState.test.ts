import { describe, expect, it } from 'vitest';
import { INITIAL_WORLD } from '../../src/game/content/world';
import {
  advanceEncounter,
  advanceTravel,
  createInitialGameState,
  disableTrain,
  reclaimStation,
  repairGate,
  startEngine
} from '../../src/game/simulation/gameState';

const gateId = 'bridge-7';
const stationId = 'threshold-station';

describe('Rustline Reclaimer simulation', () => {
  it('starts with the bridge locked and enough briefing state to begin', () => {
    const state = createInitialGameState(INITIAL_WORLD);

    expect(state.phase).toBe('briefing');
    expect(state.gates[gateId].status).toBe('locked');
    expect(state.train.durability).toBe(100);
    expect(state.train.modules.map((module) => module.id)).toEqual(['locomotive', 'cargo-car', 'turret-car']);
  });

  it('moves the train along the route after the engine starts', () => {
    const started = startEngine(createInitialGameState(INITIAL_WORLD));
    const advanced = advanceTravel(started, 4);

    expect(started.phase).toBe('travel');
    expect(advanced.route.progress).toBeGreaterThan(started.route.progress);
    expect(advanced.route.currentSegmentId).toBe('hub-to-bridge');
  });

  it('opens the bridge only when scrap covers the repair cost', () => {
    const state = createInitialGameState(INITIAL_WORLD);
    const poorAttempt = repairGate(state, gateId);
    const funded = { ...state, scrap: 8 };
    const repaired = repairGate(funded, gateId);

    expect(poorAttempt.gates[gateId].status).toBe('locked');
    expect(poorAttempt.scrap).toBe(0);
    expect(repaired.gates[gateId].status).toBe('open');
    expect(repaired.scrap).toBe(0);
  });

  it('defeats the first threat with direct turret fire and awards enough scrap for the bridge repair', () => {
    const state = createInitialGameState(INITIAL_WORLD);
    const damaged = advanceEncounter(state, 'direct-turret-hit');
    const defeated = advanceEncounter(damaged, 'direct-turret-hit');

    expect(damaged.encounter.threats[0].health).toBe(15);
    expect(defeated.encounter.threats[0].health).toBe(0);
    expect(defeated.encounter.status).toBe('cleared');
    expect(defeated.scrap).toBe(8);
  });

  it('disables the train without deleting repaired gates or unlocked modules', () => {
    const repaired = repairGate({ ...createInitialGameState(INITIAL_WORLD), scrap: 8 }, gateId);
    const reclaimed = reclaimStation(repaired, stationId);
    const disabled = disableTrain(reclaimed);

    expect(disabled.phase).toBe('disabled');
    expect(disabled.train.durability).toBe(0);
    expect(disabled.gates[gateId].status).toBe('open');
    expect(disabled.train.modules.some((module) => module.id === 'repair-bay')).toBe(true);
  });

  it('reclaiming the first station unlocks the repair bay car once', () => {
    const repaired = repairGate({ ...createInitialGameState(INITIAL_WORLD), scrap: 8 }, gateId);
    const reclaimed = reclaimStation(repaired, stationId);
    const reclaimedAgain = reclaimStation(reclaimed, stationId);

    expect(reclaimed.stations[stationId].status).toBe('reclaimed');
    expect(reclaimed.train.modules.filter((module) => module.id === 'repair-bay')).toHaveLength(1);
    expect(reclaimedAgain.train.modules.filter((module) => module.id === 'repair-bay')).toHaveLength(1);
  });
});
