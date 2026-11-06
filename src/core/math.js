/**
 * Small, dependency-free linear algebra utilities for Euclidean spaces up to R6.
 * Made by Alhan | HyperDimension Lab
 */
export const AXIS_NAMES = ['X', 'Y', 'Z', 'W', 'V', 'U'];
export const EPSILON = 1e-8;

export function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

export function lerp(a, b, t) {
  return a + (b - a) * t;
}

export function magnitude(vector) {
  return Math.hypot(...vector);
}

export function distanceSquared(a, b) {
  return a.reduce((sum, value, index) => sum + (value - b[index]) ** 2, 0);
}

export function mixVectors(a, b, t) {
  return a.map((value, index) => lerp(value, b[index], t));
}

export function planePairs(dimension) {
  const pairs = [];
  for (let i = 0; i < dimension; i++) {
    for (let j = i + 1; j < dimension; j++) pairs.push([i, j]);
  }
  return pairs;
}

/** Rotate a point in an arbitrary coordinate plane, preserving its Euclidean norm. */
export function rotatePlane(vector, axisA, axisB, angle) {
  const result = vector.slice();
  const c = Math.cos(angle);
  const s = Math.sin(angle);
  result[axisA] = vector[axisA] * c - vector[axisB] * s;
  result[axisB] = vector[axisA] * s + vector[axisB] * c;
  return result;
}

export function rotateThroughPlanes(vector, angles = {}) {
  let point = vector.slice();
  for (const [key, angle] of Object.entries(angles)) {
    const [axisA, axisB] = key.split(':').map(Number);
    if (Math.abs(angle) > EPSILON) point = rotatePlane(point, axisA, axisB, angle);
  }
  return point;
}

export function normalizeVertices(vertices, radius = 1.55) {
  const max = Math.max(...vertices.map(magnitude));
  if (max < EPSILON) return vertices.map(vertex => vertex.slice());
  return vertices.map(vertex => vertex.map(coordinate => coordinate * radius / max));
}

export function bounds(values) {
  if (!values.length) return [0, 0];
  return [Math.min(...values), Math.max(...values)];
}

export function signed(value, digits = 2) {
  const rounded = Math.abs(value) < 0.5 * 10 ** (-digits) ? 0 : value;
  return rounded.toFixed(digits);
}
