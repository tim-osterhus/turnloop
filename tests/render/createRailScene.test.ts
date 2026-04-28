import { BoxGeometry, Mesh, MeshStandardMaterial } from 'three';
import { describe, expect, it, vi } from 'vitest';
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

  it('includes authored low-poly corridor landmarks for the visual identity slice', () => {
    const objects = createRailScene();

    expect(objects.root.getObjectByName('route-cut-marker-west')).toBeDefined();
    expect(objects.root.getObjectByName('maintenance-pylon-0')).toBeDefined();
    expect(objects.root.getObjectByName('pressure-needle-0')).toBeDefined();
    expect(objects.bridgeGate.getObjectByName('bridge-rule-lamp')).toBeDefined();
    expect(objects.station.getObjectByName('station-ticket-slit')).toBeDefined();
  });

  it('defaults non-finite train progress to the start position', () => {
    const objects = createRailScene();

    objects.setTrainProgress(0);
    const startX = objects.train.position.x;

    objects.setTrainProgress(Number.NaN);
    expect(Number.isFinite(objects.train.position.x)).toBe(true);
    expect(objects.train.position.x).toBe(startX);

    objects.setTrainProgress(Number.POSITIVE_INFINITY);
    expect(Number.isFinite(objects.train.position.x)).toBe(true);
    expect(objects.train.position.x).toBe(startX);
  });

  it('disposes scene-owned geometry and single or array materials', () => {
    const objects = createRailScene();
    const sceneMesh = objects.root.getObjectByName('void-ballast-plane');
    expect(sceneMesh).toBeInstanceOf(Mesh);

    const singleMaterialMesh = sceneMesh as Mesh<BoxGeometry, MeshStandardMaterial>;
    const geometryDispose = vi.spyOn(singleMaterialMesh.geometry, 'dispose');
    const materialDispose = vi.spyOn(singleMaterialMesh.material, 'dispose');

    const arrayMaterialGeometry = new BoxGeometry(1, 1, 1);
    const arrayMaterials = [new MeshStandardMaterial(), new MeshStandardMaterial()];
    const arrayMaterialMesh = new Mesh(arrayMaterialGeometry, arrayMaterials);
    objects.root.add(arrayMaterialMesh);
    const arrayGeometryDispose = vi.spyOn(arrayMaterialGeometry, 'dispose');
    const firstArrayMaterialDispose = vi.spyOn(arrayMaterials[0], 'dispose');
    const secondArrayMaterialDispose = vi.spyOn(arrayMaterials[1], 'dispose');

    objects.setRepairBayVisible(false);
    objects.dispose();

    expect(geometryDispose).toHaveBeenCalledOnce();
    expect(materialDispose).toHaveBeenCalledOnce();
    expect(arrayGeometryDispose).toHaveBeenCalledOnce();
    expect(firstArrayMaterialDispose).toHaveBeenCalledOnce();
    expect(secondArrayMaterialDispose).toHaveBeenCalledOnce();
  });
});
