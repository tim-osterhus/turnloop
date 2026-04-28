import { describe, expect, it } from 'vitest';
import { INITIAL_WORLD } from '../../src/game/content/world';
import { createInitialGameState } from '../../src/game/simulation/gameState';
import type { GameState } from '../../src/game/simulation/types';
import { createUiRenderSnapshot } from '../../src/ui/renderUiSnapshot';

function baseState(): GameState {
  return createInitialGameState(INITIAL_WORLD);
}

describe('createUiRenderSnapshot', () => {
  it('keeps the same snapshot for fractional route progress changes that round to the same percent', () => {
    const first = { ...baseState(), route: { ...baseState().route, progress: 12.1 } };
    const second = { ...first, route: { ...first.route, progress: 12.4 } };

    expect(createUiRenderSnapshot(second)).toEqual(createUiRenderSnapshot(first));
  });

  it('changes the snapshot when route progress crosses a rounded percent', () => {
    const first = { ...baseState(), route: { ...baseState().route, progress: 12.4 } };
    const second = { ...first, route: { ...first.route, progress: 12.5 } };

    expect(createUiRenderSnapshot(second)).not.toEqual(createUiRenderSnapshot(first));
  });

  it('changes the snapshot for each visible train status and directive field', () => {
    const state = baseState();
    const original = createUiRenderSnapshot(state);
    const cases: Array<[string, GameState]> = [
      ['phase', { ...state, phase: 'travel' }],
      ['durability', { ...state, train: { ...state.train, durability: state.train.durability - 1 } }],
      ['max durability', { ...state, train: { ...state.train, maxDurability: state.train.maxDurability + 10 } }],
      ['scrap', { ...state, scrap: state.scrap + 1 }],
      ['message', { ...state, message: 'Updated directive.' }]
    ];

    for (const [label, changed] of cases) {
      expect(createUiRenderSnapshot(changed), label).not.toEqual(original);
    }
  });

  it('changes the snapshot for module, gate, station, and HUD threat fields independently', () => {
    const state = baseState();
    const original = createUiRenderSnapshot(state);
    const cases: Array<[string, GameState]> = [
      [
        'module',
        {
          ...state,
          train: {
            ...state.train,
            modules: [
              ...state.train.modules,
              { id: 'repair-bay', name: 'Containment Repair Bay', kind: 'repair' as const, unlocked: true }
            ]
          }
        }
      ],
      [
        'gate',
        {
          ...state,
          gates: {
            ...state.gates,
            'bridge-7': { ...state.gates['bridge-7'], status: 'open' as const }
          }
        }
      ],
      [
        'station',
        {
          ...state,
          stations: {
            ...state.stations,
            'threshold-station': { ...state.stations['threshold-station'], status: 'reclaimed' as const }
          }
        }
      ],
      [
        'threat',
        {
          ...state,
          encounter: {
            ...state.encounter,
            threats: [{ ...state.encounter.threats[0], name: 'Altered Echo', health: 12, maxHealth: 24 }]
          }
        }
      ]
    ];

    for (const [label, changed] of cases) {
      expect(createUiRenderSnapshot(changed), label).not.toEqual(original);
    }
  });
});
