import { describe, expect, it } from 'vitest';
import { actionForKey } from '../../../src/game/input/inputMap';

describe('actionForKey', () => {
  it('maps each supported control key to its UI action', () => {
    expect(actionForKey('e')).toBe('start-engine');
    expect(actionForKey(' ')).toBe('fire-turret');
    expect(actionForKey('f')).toBe('fire-turret');
    expect(actionForKey('r')).toBe('repair-gate');
    expect(actionForKey('c')).toBe('reclaim-station');
    expect(actionForKey('b')).toBe('brace');
    expect(actionForKey('x')).toBe('recover-train');
  });

  it('maps letter keys case-insensitively', () => {
    expect(actionForKey('E')).toBe('start-engine');
    expect(actionForKey('F')).toBe('fire-turret');
    expect(actionForKey('R')).toBe('repair-gate');
    expect(actionForKey('C')).toBe('reclaim-station');
    expect(actionForKey('B')).toBe('brace');
    expect(actionForKey('X')).toBe('recover-train');
  });

  it('returns null for unmapped keys', () => {
    expect(actionForKey('q')).toBeNull();
    expect(actionForKey('Enter')).toBeNull();
    expect(actionForKey('')).toBeNull();
  });
});
