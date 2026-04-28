import type { UiAction } from '../../ui/hud/renderHud';

const KEY_ACTIONS: Record<string, UiAction> = {
  e: 'start-engine',
  ' ': 'fire-turret',
  f: 'fire-turret',
  r: 'repair-gate',
  c: 'reclaim-station',
  b: 'brace',
  x: 'recover-train'
};

export function actionForKey(key: string): UiAction | null {
  return KEY_ACTIONS[key.toLowerCase()] ?? null;
}
