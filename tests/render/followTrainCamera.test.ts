import { Object3D, PerspectiveCamera, Vector3 } from 'three';
import { describe, expect, it } from 'vitest';
import { syncFollowTrainCamera } from '../../src/render/camera/followTrainCamera';

describe('syncFollowTrainCamera', () => {
  it('moves the camera toward a third-person chase position behind the train', () => {
    const camera = new PerspectiveCamera();
    camera.position.set(-9, 5, 9);
    const train = new Object3D();
    train.position.set(4, 0, 0);

    syncFollowTrainCamera(camera, train, 1);

    expect(camera.position.distanceTo(new Vector3(-1.4, 4.2, 5.8))).toBeLessThan(0.01);
  });

  it('ignores non-finite deltas instead of producing invalid camera coordinates', () => {
    const camera = new PerspectiveCamera();
    camera.position.set(1, 2, 3);
    const train = new Object3D();
    train.position.set(4, 0, 0);

    syncFollowTrainCamera(camera, train, Number.NaN);

    expect(Number.isFinite(camera.position.x)).toBe(true);
    expect(Number.isFinite(camera.position.y)).toBe(true);
    expect(Number.isFinite(camera.position.z)).toBe(true);
  });
});
