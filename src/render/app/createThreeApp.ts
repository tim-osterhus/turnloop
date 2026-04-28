import { AmbientLight, DirectionalLight, Fog, HemisphereLight, PerspectiveCamera, Scene, Vector3, WebGLRenderer } from 'three';
import { palette } from '../materials/palette';
import { createFrameClock, type FrameClock } from './frameClock';

export interface ThreeApp {
  scene: Scene;
  camera: PerspectiveCamera;
  renderer: WebGLRenderer;
  clock: FrameClock;
  resize(): void;
  render(): void;
  dispose(): void;
}

const CAMERA_TARGET = new Vector3(-6.9, 1.05, 0);

export function createThreeApp(canvas: HTMLCanvasElement): ThreeApp {
  const scene = new Scene();
  scene.background = palette.void;
  scene.fog = new Fog(palette.void, 9, 27);

  const camera = new PerspectiveCamera(54, 1, 0.1, 120);
  camera.position.set(-13.9, 4.4, 6.1);
  camera.lookAt(CAMERA_TARGET);

  const renderer = new WebGLRenderer({
    canvas,
    antialias: false,
    powerPreference: 'high-performance'
  });
  renderer.setClearColor(palette.void, 1);

  const clock = createFrameClock();
  scene.add(new AmbientLight(palette.voidFill, 1.25));
  scene.add(new HemisphereLight(palette.ash, palette.void, 1.4));

  const rimLight = new DirectionalLight(palette.signal, 1.8);
  rimLight.name = 'rustline-rim-light';
  rimLight.position.set(6, 5, -5);
  scene.add(rimLight);

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
