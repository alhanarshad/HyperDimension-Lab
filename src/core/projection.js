/**
 * A sequence of mathematically defined nD to 3D projections.
 * The result is a 2D image of a 3D projection of a higher-dimensional object,
 * not a claim to display higher-dimensional space directly.
 * Made by Alhan | HyperDimension Lab
 */
import { clamp } from './math.js';

/**
 * Project R^n into R^3. For perspective mode, each higher axis contributes a
 * depth-dependent scale. Every stage discards exactly one coordinate.
 */
export function projectTo3D(point, mode = 'perspective', depth = 3.4) {
  let vector = point.slice();
  let gain = 1;
  for (let axis = vector.length - 1; axis >= 3; axis--) {
    const hidden = vector[axis];
    if (mode === 'perspective') {
      const localDepth = depth + (axis - 3) * 0.6;
      const factor = localDepth / Math.max(0.35, localDepth - hidden);
      gain *= factor;
      vector = vector.slice(0, axis).map(value => value * factor);
    } else {
      vector = vector.slice(0, axis);
    }
  }
  return { point: vector, gain };
}

export function orbitCamera(point, yaw, pitch) {
  const cy = Math.cos(yaw);
  const sy = Math.sin(yaw);
  const cp = Math.cos(pitch);
  const sp = Math.sin(pitch);
  const x = point[0] * cy + point[2] * sy;
  const z = point[2] * cy - point[0] * sy;
  const y = point[1] * cp - z * sp;
  return { x, y, z: point[1] * sp + z * cp };
}

export function cameraToScreen(point, camera, center, size) {
  const orbit = orbitCamera(point, camera.yaw, camera.pitch);
  const distance = 5.2;
  const denominator = Math.max(0.7, distance - orbit.z);
  const fovScale = camera.cameraMode === 'flat' ? 1 : distance / denominator;
  const scale = size * camera.zoom * 0.29 * fovScale;
  return {
    x: center.x + orbit.x * scale,
    y: center.y - orbit.y * scale,
    z: orbit.z,
    scale,
    visibility: denominator > 0.5
  };
}

export function transformVertices(vertices, angles) {
  const entries = Object.entries(angles).filter(([,angle]) => Math.abs(angle) > 1e-9)
    .map(([key, angle]) => [...key.split(':').map(Number), angle]);
  return vertices.map(source => {
    const point = source.slice();
    for (const [a, b, angle] of entries) {
      const c = Math.cos(angle);
      const s = Math.sin(angle);
      const x = point[a];
      const y = point[b];
      point[a] = x * c - y * s;
      point[b] = x * s + y * c;
    }
    return point;
  });
}

export function depthShade(depth, strength = 0.65) {
  return clamp((depth + 2.4) / 5, 0, 1) * strength + (1 - strength);
}
