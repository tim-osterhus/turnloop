import { Color, MeshStandardMaterial } from 'three';

export const palette = {
  void: new Color('#07090b'),
  ballast: new Color('#2b2822'),
  rust: new Color('#8a3f21'),
  brass: new Color('#b08a3a'),
  soot: new Color('#151515'),
  signal: new Color('#e24d2f'),
  anomaly: new Color('#48d1a0'),
  institutional: new Color('#66736b')
} as const;

export function standardMaterial(color: Color, roughness = 0.92): MeshStandardMaterial {
  return new MeshStandardMaterial({
    color,
    flatShading: true,
    roughness,
    metalness: 0.08
  });
}
