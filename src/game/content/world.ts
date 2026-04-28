import type { WorldDefinition } from '../simulation/types';

export const INITIAL_WORLD: WorldDefinition = {
  startSegmentId: 'hub-to-bridge',
  gates: {
    'bridge-7': {
      id: 'bridge-7',
      name: 'Bridge 7 Pressure Fault',
      status: 'locked',
      repairCost: 8
    }
  },
  stations: {
    'threshold-station': {
      id: 'threshold-station',
      name: 'Threshold Station',
      status: 'unreclaimed',
      unlockModuleId: 'repair-bay'
    }
  },
  modules: {
    locomotive: {
      id: 'locomotive',
      name: 'Old Meridian Locomotive',
      kind: 'locomotive',
      unlocked: true
    },
    'cargo-car': {
      id: 'cargo-car',
      name: 'Scrap Tender',
      kind: 'cargo',
      unlocked: true
    },
    'turret-car': {
      id: 'turret-car',
      name: 'Manual Turret Car',
      kind: 'turret',
      unlocked: true
    },
    'repair-bay': {
      id: 'repair-bay',
      name: 'Containment Repair Bay',
      kind: 'repair',
      unlocked: false
    }
  },
  encounter: {
    id: 'signal-echo',
    status: 'active',
    scrapReward: 8,
    threats: [
      {
        id: 'echo-knot',
        name: 'Signal Echo Knot',
        health: 30,
        maxHealth: 30
      }
    ]
  }
};
