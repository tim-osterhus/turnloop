import { Object3D, PerspectiveCamera, Vector3 } from 'three';

const CHASE_OFFSET = new Vector3(-5.4, 4.2, 5.8);
const LOOK_AHEAD = new Vector3(1.6, 1.05, 0);
const FOLLOW_SPEED = 8;

const desiredPosition = new Vector3();
const lookTarget = new Vector3();

export function syncFollowTrainCamera(camera: PerspectiveCamera, train: Object3D, deltaSeconds: number): void {
  const safeDelta = Number.isFinite(deltaSeconds) ? Math.max(0, deltaSeconds) : 0;
  const blend = Math.min(1, safeDelta * FOLLOW_SPEED);

  desiredPosition.copy(train.position).add(CHASE_OFFSET);
  camera.position.lerp(desiredPosition, blend);

  lookTarget.copy(train.position).add(LOOK_AHEAD);
  camera.lookAt(lookTarget);
}
