import { describe, expect, it } from 'vitest';
import { createRailScene } from '../../src/render/objects/createRailScene';

describe('createRailScene', () => {
  it('creates named rail scene groups and updates visibility and placement through setters', () => {
    const objects = createRailScene();

    expect(objects.root.name).toBe('rustline-rail-scene');
    expect(objects.train.name).toBe('rustline-train');
    expect(objects.threat.name).toBe('signal-echo-knot');
    expect(objects.bridgeGate.name).toBe('bridge-7-gate');
    expect(objects.station.name).toBe('threshold-station');

    objects.setTrainProgress(0);
    const startX = objects.train.position.x;
    objects.setTrainProgress(100);
    expect(objects.train.position.x).toBeGreaterThan(startX);

    objects.setThreatHealthRatio(0);
    expect(objects.threat.visible).toBe(false);
    objects.setThreatHealthRatio(0.5);
    expect(objects.threat.visible).toBe(true);
    expect(objects.threat.scale.x).toBeGreaterThan(0.5);

    objects.setBridgeOpen(false);
    expect(objects.bridgeGate.visible).toBe(true);
    objects.setBridgeOpen(true);
    expect(objects.bridgeGate.visible).toBe(false);

    objects.setRepairBayVisible(false);
    const repairBay = objects.train.getObjectByName('repair-bay-car');
    expect(repairBay?.visible).toBe(false);
    objects.setRepairBayVisible(true);
    expect(repairBay?.visible).toBe(true);
  });
});
