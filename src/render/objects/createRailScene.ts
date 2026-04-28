import {
  BoxGeometry,
  ConeGeometry,
  CylinderGeometry,
  DirectionalLight,
  Group,
  Mesh,
  MeshStandardMaterial,
  Object3D,
  PlaneGeometry
} from 'three';
import { palette, standardMaterial } from '../materials/palette';

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
}

const TRACK_START_X = -8.5;
const TRACK_END_X = 8.5;

function box(name: string, size: [number, number, number], material: MeshStandardMaterial, position: [number, number, number]): Mesh {
  const mesh = new Mesh(new BoxGeometry(size[0], size[1], size[2]), material);
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

  const cargo = createCar('cargo-car', standardMaterial(palette.institutional), 0);
  cargo.add(box('cargo-crate', [0.95, 0.5, 0.82], standardMaterial(palette.ballast), [0.06, 1.06, 0]));

  const turretCar = createCar('turret-car', standardMaterial(palette.rust), 1.6);
  const turret = new Group();
  turret.name = 'turret';
  turret.position.set(0, 1.12, 0);
  turret.add(box('turret-base', [0.5, 0.22, 0.5], standardMaterial(palette.brass), [0, 0, 0]));
  turret.add(box('turret-barrel', [0.9, 0.13, 0.13], standardMaterial(palette.signal), [0.52, 0.12, 0]));
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
  return gate;
}

function createStation(): Group {
  const station = new Group();
  station.name = 'threshold-station';
  station.position.set(9.7, 0, -1.2);
  station.add(box('station-plinth', [1.65, 0.35, 1.35], standardMaterial(palette.institutional), [0, 0.18, 0]));
  station.add(box('station-marker', [0.64, 1.65, 0.44], standardMaterial(palette.brass), [0, 1.15, 0]));
  station.add(box('station-signal', [0.28, 0.28, 0.28], standardMaterial(palette.anomaly), [0, 2.1, 0]));
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

function addTrack(root: Group): void {
  const railMaterial = standardMaterial(palette.soot, 0.98);
  const sleeperMaterial = standardMaterial(palette.rust, 0.95);
  root.add(box('left-rail', [19.5, 0.12, 0.12], railMaterial, [0, 0.12, -0.45]));
  root.add(box('right-rail', [19.5, 0.12, 0.12], railMaterial, [0, 0.12, 0.45]));
  for (let index = 0; index < 22; index += 1) {
    const x = TRACK_START_X + index * ((TRACK_END_X - TRACK_START_X) / 21);
    root.add(box(`sleeper-${index}`, [0.18, 0.12, 1.32], sleeperMaterial, [x, 0.04, 0]));
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

  addTrack(root);

  const { train, repairBay } = createTrain();
  const bridgeGate = createBridgeGate();
  const station = createStation();
  const threat = createThreat();

  const directionalLight = new DirectionalLight(palette.brass, 2.6);
  directionalLight.name = 'rustline-key-light';
  directionalLight.position.set(-4, 7, 5);

  root.add(train, bridgeGate, station, threat, directionalLight);

  function setTrainProgress(progress: number): void {
    const normalized = Math.min(100, Math.max(0, progress)) / 100;
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

  setTrainProgress(0);
  setThreatHealthRatio(1);
  setBridgeOpen(false);
  setRepairBayVisible(false);

  return { root, train, threat, bridgeGate, station, setTrainProgress, setThreatHealthRatio, setBridgeOpen, setRepairBayVisible };
}
