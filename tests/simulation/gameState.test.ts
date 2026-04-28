import { describe, expect, it } from 'vitest';
import { INITIAL_WORLD } from '../../src/game/content/world';
import {
  advanceEncounter,
  advanceTravel,
  createInitialGameState,
  disableTrain,
  reclaimStation,
  recoverTrain,
  repairGate,
  startEngine
} from '../../src/game/simulation/gameState';

const gateId = 'bridge-7';
const stationId = 'threshold-station';

function startedState() {
  return startEngine(createInitialGameState(INITIAL_WORLD));
}

function encounterState() {
  return advanceTravel(startedState(), 7);
}

function clearedEncounterState() {
  return advanceEncounter(advanceEncounter(encounterState(), 'direct-turret-hit'), 'direct-turret-hit');
}

function blockedState(scrap = 8) {
  return { ...advanceTravel(clearedEncounterState(), 10), scrap };
}

function stationReadyState() {
  return advanceTravel(repairGate(blockedState(8), gateId), 5);
}

describe('Rustline Reclaimer simulation', () => {
  it('starts with the bridge locked and enough briefing state to begin', () => {
    const state = createInitialGameState(INITIAL_WORLD);

    expect(state.phase).toBe('briefing');
    expect(state.gates[gateId].status).toBe('locked');
    expect(state.train.durability).toBe(100);
    expect(state.train.modules.map((module) => module.id)).toEqual(['locomotive', 'cargo-car', 'turret-car']);
  });

  it('moves the train along the route after the engine starts', () => {
    const started = startedState();
    const advanced = advanceTravel(started, 4);

    expect(started.phase).toBe('travel');
    expect(advanced.route.progress).toBeGreaterThan(started.route.progress);
    expect(advanced.route.currentSegmentId).toBe('hub-to-bridge');
  });

  it('ignores engine start outside briefing or ready phases', () => {
    const blocked = blockedState(8);
    const restarted = startEngine(blocked);

    expect(restarted.phase).toBe('blocked');
    expect(restarted.route.progress).toBe(blocked.route.progress);
  });

  it('does not let negative travel time reduce progress', () => {
    const traveled = advanceTravel(startedState(), 3);
    const rewound = advanceTravel(traveled, -10);

    expect(rewound.route.progress).toBe(traveled.route.progress);
  });

  it('opens the bridge only when blocked and scrap covers the repair cost', () => {
    const poorAttempt = repairGate(blockedState(0), gateId);
    const repaired = repairGate(blockedState(8), gateId);
    const earlyAttempt = repairGate({ ...createInitialGameState(INITIAL_WORLD), scrap: 8 }, gateId);

    expect(poorAttempt.gates[gateId].status).toBe('locked');
    expect(poorAttempt.scrap).toBe(0);
    expect(repaired.gates[gateId].status).toBe('open');
    expect(repaired.scrap).toBe(0);
    expect(earlyAttempt.gates[gateId].status).toBe('locked');
    expect(earlyAttempt.scrap).toBe(8);
  });

  it('ignores turret input outside active encounter phase', () => {
    const state = createInitialGameState(INITIAL_WORLD);
    const attempted = advanceEncounter(state, 'direct-turret-hit');

    expect(attempted).toEqual(state);
  });

  it('defeats the first threat with direct turret fire and awards enough scrap for the bridge repair', () => {
    const damaged = advanceEncounter(encounterState(), 'direct-turret-hit');
    const defeated = advanceEncounter(damaged, 'direct-turret-hit');

    expect(damaged.encounter.threats[0].health).toBe(15);
    expect(defeated.encounter.threats[0].health).toBe(0);
    expect(defeated.encounter.status).toBe('cleared');
    expect(defeated.scrap).toBe(8);
  });

  it('direct turret fire targets the next living threat', () => {
    const state = encounterState();
    const multiThreat = {
      ...state,
      encounter: {
        ...state.encounter,
        threats: [
          { id: 'spent', name: 'Spent Echo', health: 0, maxHealth: 30 },
          { id: 'live', name: 'Live Echo', health: 30, maxHealth: 30 }
        ]
      }
    };
    const fired = advanceEncounter(multiThreat, 'direct-turret-hit');

    expect(fired.encounter.threats[0].health).toBe(0);
    expect(fired.encounter.threats[1].health).toBe(15);
  });

  it('disables the train immediately when bracing drops durability to zero', () => {
    const encounter = encounterState();
    const fragile = {
      ...encounter,
      train: {
        ...encounter.train,
        durability: 5
      }
    };

    const braced = advanceEncounter(fragile, 'brace');

    expect(braced.phase).toBe('disabled');
    expect(braced.train.durability).toBe(0);
  });

  it('disables the train without deleting repaired gates or unlocked modules', () => {
    const reclaimed = reclaimStation(stationReadyState(), stationId);
    const disabled = disableTrain(reclaimed);

    expect(disabled.phase).toBe('disabled');
    expect(disabled.train.durability).toBe(0);
    expect(disabled.gates[gateId].status).toBe('open');
    expect(disabled.train.modules.some((module) => module.id === 'repair-bay')).toBe(true);
  });

  it('reclaiming the first station unlocks the repair bay car once', () => {
    const reclaimed = reclaimStation(stationReadyState(), stationId);
    const reclaimedAgain = reclaimStation(reclaimed, stationId);
    const earlyAttempt = reclaimStation(createInitialGameState(INITIAL_WORLD), stationId);

    expect(reclaimed.stations[stationId].status).toBe('reclaimed');
    expect(reclaimed.train.modules.filter((module) => module.id === 'repair-bay')).toHaveLength(1);
    expect(reclaimedAgain.train.modules.filter((module) => module.id === 'repair-bay')).toHaveLength(1);
    expect(earlyAttempt.stations[stationId].status).toBe('unreclaimed');
    expect(earlyAttempt.train.modules.filter((module) => module.id === 'repair-bay')).toHaveLength(0);
  });

  it('recovers the train only from disabled phase', () => {
    const active = startedState();
    const ignored = recoverTrain(active);
    const disabled = disableTrain(active);
    const recovered = recoverTrain(disabled);

    expect(ignored).toEqual(active);
    expect(recovered.phase).toBe('ready');
    expect(recovered.train.durability).toBe(Math.ceil(disabled.train.maxDurability * 0.55));
  });
});
