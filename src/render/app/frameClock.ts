export interface FrameClock {
  getDelta(): number;
}

export function createFrameClock(now: () => number = () => performance.now()): FrameClock {
  let previousTime = now();

  return {
    getDelta(): number {
      const currentTime = now();
      const elapsedMilliseconds = currentTime - previousTime;
      previousTime = currentTime;

      if (elapsedMilliseconds <= 0) {
        return 0;
      }

      return elapsedMilliseconds / 1000;
    }
  };
}
