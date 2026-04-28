import type { EncounterInput, GameState, TrainModule, WorldDefinition } from './types';

const FIRST_GATE_ID = 'bridge-7';

function cloneRecord<T extends { id: string }>(record: Record<string, T>): Record<string, T> {
  return Object.fromEntries(Object.entries(record).map(([key, value]) => [key, { ...value }]));
}

function cloneModules(modules: Record<string, TrainModule>, ids: string[]): TrainModule[] {
  return ids.map((id) => ({ ...modules[id], unlocked: true }));
}

export function createInitialGameState(world: WorldDefinition): GameState {
  return {
    phase: 'briefing',
    route: {
      currentSegmentId: world.startSegmentId,
      progress: 0
    },
    train: {
      durability: 100,
      maxDurability: 100,
      modules: cloneModules(world.modules, ['locomotive', 'cargo-car', 'turret-car'])
    },
    availableModules: cloneRecord(world.modules),
    gates: cloneRecord(world.gates),
    stations: cloneRecord(world.stations),
    encounter: {
      ...world.encounter,
      threats: world.encounter.threats.map((threat) => ({ ...threat }))
    },
    scrap: 0,
    message: 'Engine cold. Press start to bring the line back under procedure.'
  };
}

export function startEngine(state: GameState): GameState {
  if (state.phase !== 'briefing' && state.phase !== 'ready') {
    return state;
  }
  return {
    ...state,
    phase: 'travel',
    message: 'Engine live. Maintain third-person line-of-sight and watch the signal boards.'
  };
}

export function advanceTravel(state: GameState, seconds: number): GameState {
  if (state.phase !== 'travel') {
    return state;
  }
  const safeSeconds = Math.max(0, seconds);
  const progress = Math.min(100, state.route.progress + safeSeconds * 6);
  if (progress >= 42 && state.encounter.status === 'active') {
    return {
      ...state,
      phase: 'encounter',
      route: { ...state.route, progress },
      message: 'Anomalous signal mass on the rail. Manual turret authorization granted.'
    };
  }
  const firstGate = state.gates[FIRST_GATE_ID];
  if (progress >= 72 && (!firstGate || firstGate.status === 'locked')) {
    return {
      ...state,
      phase: 'blocked',
      route: { ...state.route, progress: 72 },
      message: 'Bridge 7 remains outside safe operating tolerance. Repair requires 8 scrap.'
    };
  }
  if (progress >= 100) {
    return {
      ...state,
      phase: 'station',
      route: { ...state.route, progress },
      message: 'Threshold Station reached. Reclamation procedure available.'
    };
  }
  return {
    ...state,
    route: { ...state.route, progress },
    message: 'Rail pressure nominal. Continue forward.'
  };
}

export function repairGate(state: GameState, gateId: string): GameState {
  const gate = state.gates[gateId];
  if (state.phase !== 'blocked') {
    return {
      ...state,
      message: gate ? `${gate.name} can only be repaired while blocked.` : 'Unknown repair procedure.'
    };
  }
  if (!gate || gate.status === 'open' || state.scrap < gate.repairCost) {
    return {
      ...state,
      message: gate ? `${gate.name} requires ${gate.repairCost} scrap.` : 'Unknown repair procedure.'
    };
  }
  return {
    ...state,
    phase: 'travel',
    scrap: state.scrap - gate.repairCost,
    gates: {
      ...state.gates,
      [gateId]: { ...gate, status: 'open' }
    },
    message: `${gate.name} recalibrated. Containment route reopened.`
  };
}

export function advanceEncounter(state: GameState, input: EncounterInput): GameState {
  if (state.phase !== 'encounter' || state.encounter.status === 'cleared') {
    return state;
  }
  if (input === 'brace') {
    const nextDurability = Math.max(0, state.train.durability - 5);
    return {
      ...state,
      phase: nextDurability === 0 ? 'disabled' : state.phase,
      train: {
        ...state.train,
        durability: nextDurability
      },
      message: 'Emergency brace absorbed part of the signal impact.'
    };
  }
  const targetIndex = state.encounter.threats.findIndex((threat) => threat.health > 0);
  if (targetIndex === -1) {
    return {
      ...state,
      phase: 'travel',
      encounter: {
        ...state.encounter,
        status: 'cleared'
      },
      message: 'No live anomalous targets remain.'
    };
  }
  const threats = state.encounter.threats.map((threat, index) =>
    index === targetIndex ? { ...threat, health: Math.max(0, threat.health - 15) } : threat
  );
  const cleared = threats.every((threat) => threat.health === 0);
  return {
    ...state,
    phase: cleared ? 'travel' : 'encounter',
    encounter: {
      ...state.encounter,
      status: cleared ? 'cleared' : 'active',
      threats
    },
    scrap: cleared ? state.scrap + state.encounter.scrapReward : state.scrap,
    message: cleared ? 'Signal Echo Knot dispersed. Salvage recovered.' : 'Manual turret hit confirmed.'
  };
}

export function reclaimStation(state: GameState, stationId: string): GameState {
  const station = state.stations[stationId];
  if (!station) {
    return { ...state, message: 'Unknown station procedure.' };
  }
  if (state.phase !== 'station') {
    return { ...state, message: `${station.name} can only be reclaimed from station approach.` };
  }
  if (station.status === 'reclaimed') {
    return state;
  }
  const alreadyUnlocked = state.train.modules.some((module) => module.id === station.unlockModuleId);
  const moduleToUnlock = state.availableModules[station.unlockModuleId];
  if (!moduleToUnlock) {
    return { ...state, message: `${station.name} reward module ${station.unlockModuleId} is unavailable.` };
  }
  return {
    ...state,
    phase: 'complete',
    stations: {
      ...state.stations,
      [stationId]: { ...station, status: 'reclaimed' }
    },
    train: {
      ...state.train,
      modules: alreadyUnlocked ? state.train.modules : [...state.train.modules, { ...moduleToUnlock, unlocked: true }]
    },
    message: `${station.name} reclaimed. ${moduleToUnlock.name} attached to consist.`
  };
}

export function disableTrain(state: GameState): GameState {
  return {
    ...state,
    phase: 'disabled',
    train: {
      ...state.train,
      durability: 0
    },
    message: 'Train disabled. Progress preserved. Recovery procedure required.'
  };
}

export function recoverTrain(state: GameState): GameState {
  if (state.phase !== 'disabled') {
    return state;
  }
  return {
    ...state,
    phase: 'ready',
    train: {
      ...state.train,
      durability: Math.ceil(state.train.maxDurability * 0.55)
    },
    message: 'Recovery complete. Repair bay procedures recommended.'
  };
}
