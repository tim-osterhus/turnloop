import type { WebGLRenderer } from 'three';

export interface PerfSnapshot {
  fps: number;
  drawCalls: number;
  triangles: number;
}

let lastSampleTime = performance.now();
let framesSinceSample = 0;
let latestFps = 0;

export function samplePerf(renderer: WebGLRenderer): PerfSnapshot {
  framesSinceSample += 1;
  const now = performance.now();
  const elapsed = now - lastSampleTime;

  if (elapsed >= 500) {
    latestFps = Math.round((framesSinceSample * 1000) / elapsed);
    framesSinceSample = 0;
    lastSampleTime = now;
  }

  return {
    fps: latestFps,
    drawCalls: renderer.info.render.calls,
    triangles: renderer.info.render.triangles
  };
}
