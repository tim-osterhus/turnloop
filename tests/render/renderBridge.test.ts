import { Group } from 'three';
import { describe, expect, it, vi } from 'vitest';
import { syncRailScene } from '../../src/render/adapters/renderBridge';
import type { RailSceneObjects } from '../../src/render/objects/createRailScene';
import type { GameState } from '../../src/game/simulation/types';

function baseState(): GameState {
  return {
    phase: 'encounter',
    route: { currentSegmentId: 'hub-to-bridge', progress: 64 },
    train: {
      durability: 80,
      maxDurability: 100,
      modules: [
        { id: 'locomotive', name: 'Locomotive', kind: 'locomotive', unlocked: true },
        { id: 'repair-bay', name: 'Repair Bay', kind: 'repair', unlocked: true }
      ]
    },
    availableModules: {},
    gates: {
      'bridge-7': { id: 'bridge-7', name: 'Bridge 7', status: 'open', repairCost: 8 }
    },
    stations: {},
    encounter: {
      id: 'signal-echo',
      status: 'active',
      threats: [{ id: 'knot', name: 'Signal Echo Knot', health: 15, maxHealth: 30 }],
      scrapReward: 8
    },
    scrap: 0,
    message: ''
  };
}

function createObjects() {
  const objects: RailSceneObjects = {
    root: new Group(),
    train: new Group(),
    threat: new Group(),
    bridgeGate: new Group(),
    station: new Group(),
    setTrainProgress: vi.fn(),
    setThreatHealthRatio: vi.fn(),
    setBridgeOpen: vi.fn(),
    setRepairBayVisible: vi.fn()
  };
  return objects;
}

describe('syncRailScene', () => {
  it('syncs train progress, bridge state, repair bay visibility, threat ratio, and rotates threat', () => {
    const objects = createObjects();

    syncRailScene(objects, baseState());

    expect(objects.setTrainProgress).toHaveBeenCalledWith(64);
    expect(objects.setBridgeOpen).toHaveBeenCalledWith(true);
    expect(objects.setRepairBayVisible).toHaveBeenCalledWith(true);
    expect(objects.setThreatHealthRatio).toHaveBeenCalledWith(0.5);
    expect(objects.threat.rotation.y).toBeGreaterThan(0);
  });

  it('uses closed and hidden defaults when bridge or threat records are absent or invalid', () => {
    const objects = createObjects();
    const state = {
      ...baseState(),
      gates: {},
      train: { ...baseState().train, modules: [] },
      encounter: {
        ...baseState().encounter,
        threats: [{ id: 'bad', name: 'Bad Echo', health: 4, maxHealth: 0 }]
      }
    };

    expect(() => syncRailScene(objects, state)).not.toThrow();

    expect(objects.setTrainProgress).toHaveBeenCalledWith(64);
    expect(objects.setBridgeOpen).toHaveBeenCalledWith(false);
    expect(objects.setRepairBayVisible).toHaveBeenCalledWith(false);
    expect(objects.setThreatHealthRatio).toHaveBeenCalledWith(0);
  });

  it('uses the first living threat when earlier threats are defeated', () => {
    const objects = createObjects();
    const state = {
      ...baseState(),
      encounter: {
        ...baseState().encounter,
        threats: [
          { id: 'spent', name: 'Spent Echo', health: 0, maxHealth: 30 },
          { id: 'live', name: 'Live Echo', health: 20, maxHealth: 40 }
        ]
      }
    };

    syncRailScene(objects, state);

    expect(objects.setThreatHealthRatio).toHaveBeenCalledWith(0.5);
  });
});
