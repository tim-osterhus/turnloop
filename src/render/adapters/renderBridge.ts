import type { GameState } from '../../game/simulation/types';
import type { RailSceneObjects } from '../objects/createRailScene';

const THREAT_ROTATION_STEP = 0.035;

export function syncRailScene(objects: RailSceneObjects, state: GameState): void {
  objects.setTrainProgress(state.route.progress);
  objects.setBridgeOpen(state.gates['bridge-7']?.status === 'open');
  objects.setRepairBayVisible(state.train.modules.some((module) => module.id === 'repair-bay'));

  const threat = state.encounter.threats.find((candidate) => candidate.health > 0);
  const threatRatio = threat && threat.maxHealth > 0 ? Math.max(0, threat.health) / threat.maxHealth : 0;
  objects.setThreatHealthRatio(threatRatio);
  objects.threat.rotation.y += THREAT_ROTATION_STEP;
}
