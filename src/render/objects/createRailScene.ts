import {
  BoxGeometry,
  ConeGeometry,
  CylinderGeometry,
  DirectionalLight,
  DodecahedronGeometry,
  Group,
  Mesh,
  MeshStandardMaterial,
  Object3D,
  PlaneGeometry,
  TetrahedronGeometry
} from 'three';
import { lampMaterial, palette, standardMaterial } from '../materials/palette';

export interface RailSceneObjects {
  root: Group;
  train: Group;
  threat: Group;
  bridgeGate: Group;
  station: Group;
  setTrainProgress(progress: number): void;
  setThreatHealthRatio(ratio: number): void;
  setBridgeOpen(open: boolean): void;
  setRepairBayVisible(visible: boolean): void;
  dispose(): void;
}

const TRACK_START_X = -8.5;
const TRACK_END_X = 8.5;

function box(name: string, size: [number, number, number], material: MeshStandardMaterial, position: [number, number, number]): Mesh {
  const mesh = new Mesh(new BoxGeometry(size[0], size[1], size[2]), material);
  mesh.name = name;
  mesh.position.set(position[0], position[1], position[2]);
  return mesh;
}

function cylinder(
  name: string,
  radius: number,
  depth: number,
  material: MeshStandardMaterial,
  position: [number, number, number],
  radialSegments = 8
): Mesh {
  const mesh = new Mesh(new CylinderGeometry(radius, radius, depth, radialSegments), material);
  mesh.name = name;
  mesh.position.set(position[0], position[1], position[2]);
  return mesh;
}

function cone(
  name: string,
  radius: number,
  height: number,
  material: MeshStandardMaterial,
  position: [number, number, number],
  radialSegments = 5
): Mesh {
  const mesh = new Mesh(new ConeGeometry(radius, height, radialSegments), material);
  mesh.name = name;
  mesh.position.set(position[0], position[1], position[2]);
  return mesh;
}

function addWheelSet(parent: Object3D, x: number): void {
  const wheelMaterial = standardMaterial(palette.soot, 0.96);
  for (const z of [-0.52, 0.52]) {
    const wheel = new Mesh(new CylinderGeometry(0.18, 0.18, 0.12, 8), wheelMaterial);
    wheel.name = 'iron-wheel';
    wheel.rotation.z = Math.PI / 2;
    wheel.position.set(x, 0.18, z);
    parent.add(wheel);
  }
}

function createCar(name: string, color: MeshStandardMaterial, x: number): Group {
  const car = new Group();
  car.name = name;
  car.position.x = x;
  car.add(box(`${name}-body`, [1.55, 0.72, 1.08], color, [0, 0.62, 0]));
  car.add(box(`${name}-chassis`, [1.75, 0.22, 1.2], standardMaterial(palette.soot), [0, 0.28, 0]));
  addWheelSet(car, -0.55);
  addWheelSet(car, 0.55);
  return car;
}

function createTrain(): { train: Group; repairBay: Group } {
  const train = new Group();
  train.name = 'rustline-train';

  const locomotive = createCar('locomotive', standardMaterial(palette.rust), -1.6);
  locomotive.add(box('locomotive-cab', [0.7, 0.78, 0.9], standardMaterial(palette.brass), [0.34, 1.28, 0]));
  locomotive.add(box('locomotive-stack', [0.24, 0.58, 0.24], standardMaterial(palette.soot), [-0.48, 1.28, 0]));
  locomotive.add(box('locomotive-number-plate', [0.42, 0.18, 0.04], lampMaterial(palette.signal), [-0.9, 0.78, -0.56]));

  const cargo = createCar('cargo-car', standardMaterial(palette.institutional), 0);
  cargo.add(box('cargo-crate', [0.95, 0.5, 0.82], standardMaterial(palette.ballast), [0.06, 1.06, 0]));

  const turretCar = createCar('turret-car', standardMaterial(palette.rust), 1.6);
  const turret = new Group();
  turret.name = 'turret';
  turret.position.set(0, 1.12, 0);
  turret.add(box('turret-base', [0.5, 0.22, 0.5], standardMaterial(palette.brass), [0, 0, 0]));
  turret.add(box('turret-barrel', [0.9, 0.13, 0.13], standardMaterial(palette.signal), [0.52, 0.12, 0]));
  turret.add(box('turret-sight-lamp', [0.16, 0.16, 0.08], lampMaterial(palette.anomaly), [0.92, 0.22, 0]));
  turretCar.add(turret);

  const repairBay = createCar('repair-bay-car', standardMaterial(palette.brass), 3.2);
  repairBay.add(box('repair-bay-armature', [1.0, 0.62, 0.16], standardMaterial(palette.signal), [0, 1.2, 0]));
  repairBay.visible = false;
  repairBay.scale.setScalar(0.01);

  train.add(locomotive, cargo, turretCar, repairBay);
  return { train, repairBay };
}

function createBridgeGate(): Group {
  const gate = new Group();
  gate.name = 'bridge-7-gate';
  gate.position.set(5.6, 0, 0);
  const material = standardMaterial(palette.signal);
  gate.add(box('bridge-left-post', [0.25, 2.15, 0.25], material, [-0.55, 1.05, 0]));
  gate.add(box('bridge-right-post', [0.25, 2.15, 0.25], material, [0.55, 1.05, 0]));
  gate.add(box('bridge-crossbar', [1.45, 0.22, 0.22], material, [0, 1.8, 0]));
  gate.add(box('bridge-lock-plate', [1.25, 0.64, 0.1], standardMaterial(palette.soot), [0, 0.9, -0.08]));
  gate.add(box('bridge-rule-lamp', [0.28, 0.28, 0.12], lampMaterial(palette.signal), [0, 1.78, -0.18]));
  return gate;
}

function createStation(): Group {
  const station = new Group();
  station.name = 'threshold-station';
  station.position.set(9.7, 0, -1.2);
  station.add(box('station-plinth', [1.65, 0.35, 1.35], standardMaterial(palette.institutional), [0, 0.18, 0]));
  station.add(box('station-marker', [0.64, 1.65, 0.44], standardMaterial(palette.brass), [0, 1.15, 0]));
  station.add(box('station-signal', [0.28, 0.28, 0.28], standardMaterial(palette.anomaly), [0, 2.1, 0]));
  station.add(box('station-ticket-slit', [0.48, 0.08, 0.06], standardMaterial(palette.soot), [0, 1.25, -0.24]));
  station.add(box('station-procedure-tag', [0.72, 0.18, 0.04], lampMaterial(palette.signal), [0, 0.72, -0.28]));
  return station;
}

function createThreat(): Group {
  const threat = new Group();
  threat.name = 'signal-echo-knot';
  threat.position.set(0.8, 1.75, -1.75);
  const material = standardMaterial(palette.anomaly, 0.85);
  for (let index = 0; index < 3; index += 1) {
    const shard = new Mesh(new ConeGeometry(0.32 - index * 0.04, 1.05, 5), material);
    shard.name = `signal-shard-${index}`;
    shard.rotation.set(index * 0.72, index * 1.1, index * 0.35);
    shard.position.set(Math.cos(index * 2.1) * 0.34, index * 0.05, Math.sin(index * 2.1) * 0.34);
    threat.add(shard);
  }
  return threat;
}

function createRouteCutMarker(name: string, x: number, z: number, rotationY: number): Group {
  const marker = new Group();
  marker.name = name;
  marker.position.set(x, 0, z);
  marker.rotation.y = rotationY;
  const postMaterial = standardMaterial(palette.institutionalDark);
  const lamp = lampMaterial(palette.signal);

  marker.add(box(`${name}-post-a`, [0.16, 1.65, 0.16], postMaterial, [-0.44, 0.78, 0]));
  marker.add(box(`${name}-post-b`, [0.16, 1.25, 0.16], postMaterial, [0.44, 0.58, 0]));
  marker.add(box(`${name}-rule-board`, [1.22, 0.28, 0.08], standardMaterial(palette.brass), [0, 1.26, 0]));
  marker.add(box(`${name}-fault-tick`, [0.2, 0.2, 0.1], lamp, [-0.28, 1.28, -0.06]));
  return marker;
}

function createMaintenancePylon(index: number, x: number, z: number, height: number): Group {
  const pylon = new Group();
  pylon.name = `maintenance-pylon-${index}`;
  pylon.position.set(x, 0, z);
  pylon.rotation.y = index % 2 === 0 ? -0.18 : 0.2;
  const material = standardMaterial(palette.institutionalDark, 0.96);

  const mast = box(`${pylon.name}-mast`, [0.18, height, 0.18], material, [0, height / 2, 0]);
  const arm = box(`${pylon.name}-arm`, [0.92, 0.12, 0.12], material, [0.42, height - 0.22, 0]);
  const insulator = cylinder(`${pylon.name}-insulator`, 0.09, 0.24, lampMaterial(palette.anomaly), [0.9, height - 0.24, 0], 6);
  insulator.rotation.x = Math.PI / 2;

  pylon.add(mast, arm, insulator);
  return pylon;
}

function createPressureNeedle(index: number, x: number, z: number, lean: number): Group {
  const needle = new Group();
  needle.name = `pressure-needle-${index}`;
  needle.position.set(x, 0, z);
  needle.rotation.z = lean;

  const spike = cone(`${needle.name}-spike`, 0.13, 1.35, standardMaterial(palette.rustDark), [0, 0.72, 0], 5);
  const eye = box(`${needle.name}-eye`, [0.18, 0.18, 0.08], lampMaterial(palette.anomaly), [0, 1.2, -0.04]);
  needle.add(spike, eye);
  return needle;
}

function addLowPolyGround(root: Group): void {
  const facets = [
    ['ballast-facet-west', -7.2, -2.6, 1.3, 0.2],
    ['ballast-facet-cut', -3.4, 2.5, 0.9, 0.8],
    ['ballast-facet-ditch', 1.4, -2.8, 1.1, -0.3],
    ['ballast-facet-east', 6.8, 2.25, 1.45, 0.5],
    ['ballast-facet-station', 9.2, -2.85, 0.9, -0.7]
  ] as const;

  for (const [name, x, z, scale, rotation] of facets) {
    const facet = new Mesh(new TetrahedronGeometry(scale, 0), standardMaterial(palette.ballastLight, 1));
    facet.name = name;
    facet.position.set(x, 0.05, z);
    facet.rotation.set(0.18, rotation, 0.08);
    facet.scale.y = 0.22;
    root.add(facet);
  }

  const boulder = new Mesh(new DodecahedronGeometry(0.62, 0), standardMaterial(palette.rustDark, 1));
  boulder.name = 'route-cut-marker-west';
  boulder.position.set(-9.6, 0.34, -1.55);
  boulder.scale.set(1.6, 0.55, 0.95);
  boulder.rotation.set(0.2, -0.4, 0.1);
  root.add(boulder);
}

function addCorridorLandmarks(root: Group): void {
  root.add(createRouteCutMarker('route-rule-board-west', -6.8, -1.45, 0.12));
  root.add(createRouteCutMarker('route-rule-board-east', 3.2, 1.55, Math.PI + 0.05));

  [-5.7, -1.7, 2.4, 6.1].forEach((x, index) => {
    root.add(createMaintenancePylon(index, x, index % 2 === 0 ? -2.15 : 2.05, 2.1 + index * 0.12));
  });

  [
    [-4.4, 1.0, -0.15],
    [0.2, -1.05, 0.12],
    [4.8, 1.08, -0.08]
  ].forEach(([x, z, lean], index) => {
    root.add(createPressureNeedle(index, x, z, lean));
  });
}

function addTrack(root: Group): void {
  const railMaterial = standardMaterial(palette.rail, 0.98);
  const sleeperMaterial = standardMaterial(palette.rustDark, 0.95);
  root.add(box('left-rail', [19.5, 0.12, 0.12], railMaterial, [0, 0.12, -0.45]));
  root.add(box('right-rail', [19.5, 0.12, 0.12], railMaterial, [0, 0.12, 0.45]));
  for (let index = 0; index < 22; index += 1) {
    const x = TRACK_START_X + index * ((TRACK_END_X - TRACK_START_X) / 21);
    const sleeper = box(`sleeper-${index}`, [0.18, 0.12, 1.32], sleeperMaterial, [x, 0.04, 0]);
    sleeper.rotation.y = (index % 3 - 1) * 0.025;
    root.add(sleeper);
  }
}

export function createRailScene(): RailSceneObjects {
  const root = new Group();
  root.name = 'rustline-rail-scene';

  const terrain = new Mesh(new PlaneGeometry(26, 12, 1, 1), standardMaterial(palette.ballast, 1));
  terrain.name = 'void-ballast-plane';
  terrain.rotation.x = -Math.PI / 2;
  terrain.position.y = -0.02;
  root.add(terrain);

  addLowPolyGround(root);
  addTrack(root);
  addCorridorLandmarks(root);

  const { train, repairBay } = createTrain();
  const bridgeGate = createBridgeGate();
  const station = createStation();
  const threat = createThreat();

  const directionalLight = new DirectionalLight(palette.brass, 2.6);
  directionalLight.name = 'rustline-key-light';
  directionalLight.position.set(-4, 7, 5);

  root.add(train, bridgeGate, station, threat, directionalLight);

  function setTrainProgress(progress: number): void {
    const finiteProgress = Number.isFinite(progress) ? progress : 0;
    const normalized = Math.min(100, Math.max(0, finiteProgress)) / 100;
    train.position.x = TRACK_START_X + normalized * (TRACK_END_X - TRACK_START_X);
    train.position.y = 0;
    train.position.z = 0;
  }

  function setThreatHealthRatio(ratio: number): void {
    const safeRatio = Number.isFinite(ratio) ? Math.min(1, Math.max(0, ratio)) : 0;
    threat.visible = safeRatio > 0;
    const scale = safeRatio > 0 ? 0.55 + safeRatio * 0.9 : 0.01;
    threat.scale.setScalar(scale);
  }

  function setBridgeOpen(open: boolean): void {
    bridgeGate.visible = !open;
  }

  function setRepairBayVisible(visible: boolean): void {
    repairBay.visible = visible;
    repairBay.scale.setScalar(visible ? 1 : 0.01);
  }

  function dispose(): void {
    root.traverse((object) => {
      if (!(object instanceof Mesh)) {
        return;
      }

      object.geometry.dispose();
      const { material } = object;
      if (Array.isArray(material)) {
        material.forEach((entry) => entry.dispose());
      } else {
        material.dispose();
      }
    });
  }

  setTrainProgress(0);
  setThreatHealthRatio(1);
  setBridgeOpen(false);
  setRepairBayVisible(false);

  return {
    root,
    train,
    threat,
    bridgeGate,
    station,
    setTrainProgress,
    setThreatHealthRatio,
    setBridgeOpen,
    setRepairBayVisible,
    dispose
  };
}
