import { AmbientLight, Clock, Fog, PerspectiveCamera, Scene, Vector3, WebGLRenderer } from 'three';
import { palette } from '../materials/palette';

export interface ThreeApp {
  scene: Scene;
  camera: PerspectiveCamera;
  renderer: WebGLRenderer;
  clock: Clock;
  resize(): void;
  render(): void;
  dispose(): void;
}

const CAMERA_TARGET = new Vector3(0, 1.1, 0);

export function createThreeApp(canvas: HTMLCanvasElement): ThreeApp {
  const scene = new Scene();
  scene.background = palette.void;
  scene.fog = new Fog(palette.void, 12, 34);

  const camera = new PerspectiveCamera(48, 1, 0.1, 120);
  camera.position.set(-9, 5.8, 9);
  camera.lookAt(CAMERA_TARGET);

  const renderer = new WebGLRenderer({
    canvas,
    antialias: false,
    powerPreference: 'high-performance'
  });
  renderer.setClearColor(palette.void, 1);

  const clock = new Clock();
  scene.add(new AmbientLight(palette.institutional, 1.7));

  function resize(): void {
    const width = Math.max(1, canvas.clientWidth || canvas.width || window.innerWidth);
    const height = Math.max(1, canvas.clientHeight || canvas.height || window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.5));
    renderer.setSize(width, height, false);
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
  }

  function render(): void {
    renderer.render(scene, camera);
  }

  function dispose(): void {
    window.removeEventListener('resize', resize);
    renderer.dispose();
  }

  window.addEventListener('resize', resize);
  resize();

  return { scene, camera, renderer, clock, resize, render, dispose };
}
