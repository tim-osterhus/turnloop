import { Color, MeshStandardMaterial } from 'three';

export const palette = {
  void: new Color('#050604'),
  voidFill: new Color('#15130d'),
  ballast: new Color('#29271f'),
  ballastLight: new Color('#3a3428'),
  rust: new Color('#7f3b20'),
  rustDark: new Color('#44291c'),
  brass: new Color('#b38442'),
  ash: new Color('#d8c7a2'),
  soot: new Color('#10100d'),
  rail: new Color('#1f211d'),
  signal: new Color('#dd6c32'),
  anomaly: new Color('#5fc49d'),
  institutional: new Color('#5e6a62'),
  institutionalDark: new Color('#303a35')
} as const;

export function standardMaterial(color: Color, roughness = 0.92): MeshStandardMaterial {
  return new MeshStandardMaterial({
    color,
    flatShading: true,
    roughness,
    metalness: 0.08
  });
}

export function lampMaterial(color: Color): MeshStandardMaterial {
  return new MeshStandardMaterial({
    color,
    emissive: color,
    emissiveIntensity: 0.85,
    flatShading: true,
    roughness: 0.72,
    metalness: 0.02
  });
}
