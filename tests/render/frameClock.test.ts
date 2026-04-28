import { describe, expect, it } from 'vitest';
import { createFrameClock } from '../../src/render/app/frameClock';

describe('createFrameClock', () => {
  it('returns elapsed seconds between calls from the injected clock', () => {
    const times = [1000, 1016, 1049];
    let index = 0;
    const clock = createFrameClock(() => times[index++]);

    expect(clock.getDelta()).toBe(0.016);
    expect(clock.getDelta()).toBe(0.033);
  });

  it('returns 0 when time moves backwards', () => {
    const times = [2000, 1990];
    let index = 0;
    const clock = createFrameClock(() => times[index++]);

    expect(clock.getDelta()).toBe(0);
  });
});
