/**
 * Convex polytope generators. All edges and two-dimensional faces are explicit.
 * Faces make accurate plane intersections possible across 3D to 6D spaces.
 * Made by Alhan | HyperDimension Lab
 */
import { distanceSquared, normalizeVertices } from './math.js';

function result(name, dimension, vertices, edges, faces, description) {
  return {
    name, dimension, vertices: normalizeVertices(vertices), edges, faces, description,
    vertexCount: vertices.length,
    edgeCount: edges.length,
    faceCount: faces.length
  };
}

export function hypercube(dimension) {
  const vertexCount = 2 ** dimension;
  const vertices = Array.from({ length: vertexCount }, (_, value) =>
    Array.from({ length: dimension }, (_, axis) => value & (1 << axis) ? 1 : -1));
  const edges = [];
  const faces = [];
  for (let mask = 0; mask < vertexCount; mask++) {
    for (let a = 0; a < dimension; a++) {
      if (!(mask & (1 << a))) edges.push([mask, mask | (1 << a)]);
      for (let b = a + 1; b < dimension; b++) {
        if (!(mask & (1 << a)) && !(mask & (1 << b))) {
          faces.push([mask, mask | (1 << a), mask | (1 << a) | (1 << b), mask | (1 << b)]);
        }
      }
    }
  }
  return result('Hypercube', dimension, vertices, edges, faces,
    `The ${dimension}D analogue of a square and a cube. Each vertex connects to exactly ${dimension} others.`);
}

export function simplex(dimension) {
  const vertices = Array.from({ length: dimension + 1 }, (_, index) =>
    Array.from({ length: dimension }, (_, axis) =>
      (index === dimension ? 0 : Number(index === axis)) - 1 / (dimension + 1)));
  const edges = [];
  const faces = [];
  for (let a = 0; a < vertices.length; a++) {
    for (let b = a + 1; b < vertices.length; b++) {
      edges.push([a, b]);
      for (let c = b + 1; c < vertices.length; c++) faces.push([a, b, c]);
    }
  }
  // A simplex in R^n needs an equidistant regular embedding.
  // Its n+1 centered basis vertices are represented in n coordinates by
  // e0..e(n-1) and the origin, then whitened with the simplex Gram matrix.
  const base = vertices.map((_, index) => Array.from({ length: dimension }, (_, axis) =>
    index === dimension ? -1 / (dimension + 1) : Number(index === axis) - 1 / (dimension + 1)));
  const b = (Math.sqrt(dimension + 1) - 1) / dimension;
  const embedded = base.map(v => v.map((value, i) => value + b * v.reduce((s, x) => s + x, 0)));
  // Distances for n+1 points are exactly equal after the above whitening.
  return result('Simplex', dimension, embedded, edges, faces,
    `The simplest regular shape in ${dimension} dimensions, with just ${dimension + 1} vertices.`);
}

export function orthoplex(dimension) {
  const vertices = [];
  for (let i = 0; i < dimension; i++) {
    for (const sign of [1, -1]) {
      const point = Array(dimension).fill(0);
      point[i] = sign;
      vertices.push(point);
    }
  }
  const edges = [];
  const faces = [];
  for (let a = 0; a < vertices.length; a++) {
    for (let b = a + 1; b < vertices.length; b++) {
      if (Math.floor(a / 2) === Math.floor(b / 2)) continue;
      edges.push([a, b]);
      for (let c = b + 1; c < vertices.length; c++) {
        if (Math.floor(a / 2) !== Math.floor(c / 2) &&
            Math.floor(b / 2) !== Math.floor(c / 2)) faces.push([a, b, c]);
      }
    }
  }
  return result('Orthoplex', dimension, vertices, edges, faces,
    `A cross-polytope: the dual of the ${dimension}D hypercube, built from pairs of opposite vertices.`);
}

function polygon(sides, radius = 1) {
  return {
    points: Array.from({ length: sides }, (_, i) => {
      const theta = 2 * Math.PI * i / sides;
      return [radius * Math.cos(theta), radius * Math.sin(theta)];
    }),
    edges: Array.from({ length: sides }, (_, i) => [i, (i + 1) % sides]),
    faces: [Array.from({ length: sides }, (_, i) => i)]
  };
}

function segment() {
  return { points: [[-1], [1]], edges: [[0, 1]], faces: [] };
}

/** Cartesian product of polygonal polytopes, including all 2-faces. */
export function productPolytope(factors) {
  const sizes = factors.map(factor => factor.points.length);
  const strides = sizes.map((_, i) => sizes.slice(i + 1).reduce((p, v) => p * v, 1));
  const total = sizes.reduce((p, v) => p * v, 1);
  const unrank = (id) => sizes.map((size, i) => Math.floor(id / strides[i]) % size);
  const rank = (indices) => indices.reduce((sum, v, i) => sum + v * strides[i], 0);
  const vertices = Array.from({ length: total }, (_, i) => {
    const coords = unrank(i);
    return factors.flatMap((factor, f) => factor.points[coords[f]]);
  });
  const edges = [];
  const faces = [];
  const alternatives = (skip) => {
    const chosen = Array(factors.length).fill(0);
    const walk = (index, out) => {
      if (index === factors.length) { out(chosen.slice()); return; }
      if (skip.includes(index)) { walk(index + 1, out); return; }
      for (let j = 0; j < sizes[index]; j++) { chosen[index] = j; walk(index + 1, out); }
    };
    return callback => walk(0, callback);
  };
  for (let i = 0; i < factors.length; i++) {
    alternatives([i])(fixed => {
      for (const [a, b] of factors[i].edges) {
        const x = fixed.slice(); const y = fixed.slice();
        x[i] = a; y[i] = b;
        edges.push([rank(x), rank(y)]);
      }
      for (const face of factors[i].faces) {
        faces.push(face.map(k => { const x = fixed.slice(); x[i] = k; return rank(x); }));
      }
    });
    for (let j = i + 1; j < factors.length; j++) {
      alternatives([i, j])(fixed => {
        for (const [a, b] of factors[i].edges) {
          for (const [c, d] of factors[j].edges) {
            faces.push([[a,c], [b,c], [b,d], [a,d]].map(([m, n]) => {
              const x = fixed.slice(); x[i] = m; x[j] = n; return rank(x);
            }));
          }
        }
      });
    }
  }
  return { vertices, edges, faces };
}

export function duoprism(dimension) {
  if (dimension < 4) throw new RangeError('Duoprisms require at least 4 dimensions');
  const factors = [polygon(5), polygon(4), ...Array.from({ length: dimension - 4 }, segment)];
  const { vertices, edges, faces } = productPolytope(factors);
  return result('Duoprism', dimension, vertices, edges, faces,
    'Two polygons multiplied together in independent coordinate planes, then extended into higher dimensions.');
}

export const SHAPES = [
  { id: 'hypercube', label: 'Hypercube', caption: 'The classic', min: 3 },
  { id: 'simplex', label: 'Simplex', caption: 'Pure geometry', min: 3 },
  { id: 'orthoplex', label: 'Orthoplex', caption: 'Dual structure', min: 3 },
  { id: 'duoprism', label: 'Duoprism', caption: 'Polygon product', min: 4 }
];

export function makePolytope(shape, dimension) {
  if (!Number.isInteger(dimension) || dimension < 3 || dimension > 6) {
    throw new RangeError('Dimension must be an integer between 3 and 6');
  }
  switch (shape) {
    case 'hypercube': return hypercube(dimension);
    case 'simplex': return simplex(dimension);
    case 'orthoplex': return orthoplex(dimension);
    case 'duoprism': return duoprism(dimension);
    default: throw new RangeError(`Unknown shape: ${shape}`);
  }
}

export function geometryIsValid(polytope) {
  const { vertices, edges, faces, dimension } = polytope;
  return vertices.every(vertex => vertex.length === dimension && vertex.every(Number.isFinite)) &&
    edges.every(([a, b]) => a !== b && a >= 0 && b >= 0 && a < vertices.length && b < vertices.length && distanceSquared(vertices[a], vertices[b]) > 0) &&
    faces.every(face => face.length >= 3 && face.every(index => index >= 0 && index < vertices.length));
}
