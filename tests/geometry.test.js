import test from 'node:test';
import assert from 'node:assert/strict';
import { makePolytope, geometryIsValid, hypercube, simplex, orthoplex, duoprism } from '../src/core/geometry.js';
import { distanceSquared, magnitude, planePairs, rotatePlane } from '../src/core/math.js';
import { projectTo3D, transformVertices } from '../src/core/projection.js';
import { intersectPolytope } from '../src/core/slice.js';

function choose(n, k) {
  let p = 1;
  for (let i = 1; i <= k; i++) p = p * (n - i + 1) / i;
  return Math.round(p);
}

for (const dimension of [3,4,5,6]) {
  test(`${dimension}D hypercube counts and topology`, () => {
    const g = hypercube(dimension);
    assert.equal(g.vertexCount, 2 ** dimension);
    assert.equal(g.edgeCount, dimension * 2 ** (dimension - 1));
    assert.equal(g.faceCount, choose(dimension, 2) * 2 ** (dimension - 2));
    assert.equal(geometryIsValid(g), true);
    const degrees = Array(g.vertexCount).fill(0);
    for (const [a,b] of g.edges) { degrees[a]++; degrees[b]++; }
    assert.ok(degrees.every(value => value === dimension));
  });
  test(`${dimension}D simplex has equal edge lengths`, () => {
    const g = simplex(dimension);
    assert.equal(g.vertexCount, dimension + 1);
    assert.equal(g.edgeCount, choose(dimension + 1, 2));
    assert.equal(g.faceCount, choose(dimension + 1, 3));
    assert.equal(geometryIsValid(g), true);
    const lengths = g.edges.map(([a,b]) => distanceSquared(g.vertices[a],g.vertices[b]));
    assert.ok(Math.max(...lengths) - Math.min(...lengths) < 1e-8, `Distances differ: ${lengths}`);
  });
  test(`${dimension}D orthoplex count and structure`, () => {
    const g = orthoplex(dimension);
    assert.equal(g.vertexCount, 2 * dimension);
    assert.equal(g.edgeCount, 2 * dimension * (dimension - 1));
    assert.equal(g.faceCount, 8 * choose(dimension, 3));
    assert.equal(geometryIsValid(g), true);
  });
  test(`${dimension}D centered hypercube section`, () => {
    const g = hypercube(dimension);
    const section = intersectPolytope(g, g.vertices, dimension - 1, 0);
    assert.equal(section.vertexCount, 2 ** (dimension - 1));
    assert.equal(section.edgeCount, (dimension - 1) * 2 ** (dimension - 2));
    assert.ok(section.vertices.every(point => Math.abs(point[dimension - 1]) < 1e-8));
  });
  test(`${dimension}D all coordinate plane rotations preserve length`, () => {
    const point = hypercube(dimension).vertices[0];
    for (const [a,b] of planePairs(dimension)) {
      const rotated = rotatePlane(point,a,b,1.124);
      assert.ok(Math.abs(magnitude(rotated) - magnitude(point)) < 1e-9);
    }
  });
}

for (const dimension of [4,5,6]) {
  test(`${dimension}D duoprism produces valid topology`, () => {
    const g = duoprism(dimension);
    assert.equal(g.vertexCount, 20 * (2 ** (dimension - 4)));
    assert.equal(geometryIsValid(g), true);
    assert.equal(new Set(g.edges.map(([a,b]) => [Math.min(a,b),Math.max(a,b)].join(':'))).size, g.edges.length);
    assert.ok(g.faceCount > 0);
  });
}

test('out of range dimensions and shapes reject', () => {
  assert.throws(() => makePolytope('hypercube',7), RangeError);
  assert.throws(() => makePolytope('duoprism',3), RangeError);
  assert.throws(() => makePolytope('unknown',4), RangeError);
});

test('projection reduces all points to three finite spatial coordinates', () => {
  for (const dimension of [3,4,5,6]) {
    const original = hypercube(dimension).vertices;
    for (const mode of ['perspective','orthographic']) {
      const output = original.map(vertex => projectTo3D(vertex,mode,3.4));
      assert.ok(output.every(item => item.point.length === 3 && item.point.every(Number.isFinite)));
    }
  }
});

test('rotated section remains on a true hyperplane', () => {
  const g = hypercube(4);
  const rotated = transformVertices(g.vertices, { '0:3':0.432,'1:2':0.343 });
  const section = intersectPolytope(g,rotated,3,0.24);
  assert.ok(section.vertexCount > 0);
  assert.ok(section.edgeCount > 0);
  assert.ok(section.vertices.every(v => Math.abs(v[3] - .24) < 1e-7));
});

test('a plane away from all vertices has an empty intersection', () => {
  const g = hypercube(6);
  const section = intersectPolytope(g,g.vertices,5,5);
  assert.equal(section.vertexCount,0);
  assert.equal(section.edgeCount,0);
});
