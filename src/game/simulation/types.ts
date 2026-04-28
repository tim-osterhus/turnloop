export type GamePhase = 'briefing' | 'ready' | 'travel' | 'blocked' | 'encounter' | 'station' | 'disabled' | 'complete';

export type GateStatus = 'locked' | 'open';
export type StationStatus = 'unreclaimed' | 'reclaimed';
export type EncounterStatus = 'active' | 'cleared';

export type TrainModuleKind = 'locomotive' | 'cargo' | 'turret' | 'repair';

export interface TrainModule {
  id: string;
  name: string;
  kind: TrainModuleKind;
  unlocked: boolean;
}

export interface TrainState {
  durability: number;
  maxDurability: number;
  modules: TrainModule[];
}

export interface RouteState {
  currentSegmentId: string;
  progress: number;
}

export interface GateState {
  id: string;
  name: string;
  status: GateStatus;
  repairCost: number;
}

export interface StationState {
  id: string;
  name: string;
  status: StationStatus;
  unlockModuleId: string;
}

export interface ThreatState {
  id: string;
  name: string;
  health: number;
  maxHealth: number;
}

export interface EncounterState {
  id: string;
  status: EncounterStatus;
  threats: ThreatState[];
  scrapReward: number;
}

export interface WorldDefinition {
  startSegmentId: string;
  gates: Record<string, GateState>;
  stations: Record<string, StationState>;
  modules: Record<string, TrainModule>;
  encounter: EncounterState;
}

export interface GameState {
  phase: GamePhase;
  route: RouteState;
  train: TrainState;
  gates: Record<string, GateState>;
  stations: Record<string, StationState>;
  encounter: EncounterState;
  scrap: number;
  message: string;
}

export type EncounterInput = 'direct-turret-hit' | 'brace';
