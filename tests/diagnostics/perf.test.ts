import type { WebGLRenderer } from 'three';
import { describe, expect, it } from 'vitest';
import { samplePerf } from '../../src/diagnostics/perf';

describe('samplePerf', () => {
  it('returns draw calls and triangle counts from a renderer-like object', () => {
    const renderer = {
      info: {
        render: {
          calls: 7,
          triangles: 321
        }
      }
    } as WebGLRenderer;

    const snapshot = samplePerf(renderer);

    expect(snapshot.drawCalls).toBe(7);
    expect(snapshot.triangles).toBe(321);
    expect(snapshot.fps).toBeGreaterThanOrEqual(0);
  });
});
