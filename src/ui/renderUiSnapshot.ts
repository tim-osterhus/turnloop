import type { GameState } from '../game/simulation/types';

interface StatusSnapshot {
  id: string;
  status: string;
}

interface ModuleSnapshot {
  id: string;
  name: string;
  kind: string;
  unlocked: boolean;
}

interface ThreatSnapshot {
  id: string;
  name: string;
  health: number;
  maxHealth: number;
}

export interface UiRenderSnapshot {
  phase: GameState['phase'];
  routeProgress: number;
  durability: number;
  maxDurability: number;
  scrap: number;
  message: string;
  threat: ThreatSnapshot | null;
  gates: StatusSnapshot[];
  stations: StatusSnapshot[];
  modules: ModuleSnapshot[];
}

function statusSnapshots<T extends { id: string; status: string }>(records: Record<string, T>): StatusSnapshot[] {
  return Object.values(records)
    .map((entry) => ({ id: entry.id, status: entry.status }))
    .sort((left, right) => left.id.localeCompare(right.id));
}

export function createUiRenderSnapshot(state: GameState): UiRenderSnapshot {
  const threat = state.encounter.threats[0] ?? null;

  return {
    phase: state.phase,
    routeProgress: Math.round(state.route.progress),
    durability: state.train.durability,
    maxDurability: state.train.maxDurability,
    scrap: state.scrap,
    message: state.message,
    threat:
      threat === null
        ? null
        : {
            id: threat.id,
            name: threat.name,
            health: threat.health,
            maxHealth: threat.maxHealth
          },
    gates: statusSnapshots(state.gates),
    stations: statusSnapshots(state.stations),
    modules: state.train.modules.map((module) => ({
      id: module.id,
      name: module.name,
      kind: module.kind,
      unlocked: module.unlocked
    }))
  };
}

export function sameUiRenderSnapshot(left: UiRenderSnapshot | null, right: UiRenderSnapshot): boolean {
  return left !== null && JSON.stringify(left) === JSON.stringify(right);
}
