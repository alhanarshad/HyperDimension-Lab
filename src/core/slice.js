/**
 * True hyperplane / polytope intersections using the edges and 2-faces.
 * The cross-section is represented by its vertices and edge segments.
 * Made by Alhan | HyperDimension Lab
 */
import { EPSILON, mixVectors } from './math.js';

const keyOf = (point) => point.map(value => Math.round(value * 1e7)).join(',');

export function intersectPolytope(polytope, transformedVertices, axis, value) {
  if (!Number.isInteger(axis) || axis < 0 || axis >= polytope.dimension) {
    throw new RangeError('Slice axis must be within the dimension of the polytope');
  }
  const vertices = [];
  const edges = [];
  const lookup = new Map();
  const sourceEdgeHits = Array(polytope.edges.length).fill(null);
  const add = (point) => {
    const key = keyOf(point);
    if (lookup.has(key)) return lookup.get(key);
    const id = vertices.length;
    vertices.push(point);
    lookup.set(key, id);
    return id;
  };
  const addLine = (a, b) => {
    if (a === b || a == null || b == null) return;
    const key = Math.min(a, b) + ':' + Math.max(a, b);
    if (!seen.has(key)) { seen.add(key); edges.push([a, b]); }
  };
  const seen = new Set();
  const edgeLookup = new Map();
  for (let i = 0; i < polytope.edges.length; i++) {
    const [a, b] = polytope.edges[i];
    edgeLookup.set(Math.min(a, b) + ':' + Math.max(a, b), i);
    const pa = transformedVertices[a]; const pb = transformedVertices[b];
    const da = pa[axis] - value; const db = pb[axis] - value;
    if (Math.abs(da) < EPSILON && Math.abs(db) < EPSILON) {
      const first = add(pa); const last = add(pb);
      sourceEdgeHits[i] = [first, last];
      addLine(first, last);
      continue;
    }
    if (da * db > 0) continue;
    const t = da / (da - db);
    if (t < -EPSILON || t > 1 + EPSILON) continue;
    sourceEdgeHits[i] = [add(mixVectors(pa, pb, Math.max(0, Math.min(1, t))))];
  }

  // Every 2-face cut by the plane contributes an edge of the section.
  for (const face of polytope.faces) {
    const hits = new Set();
    for (let i = 0; i < face.length; i++) {
      const a = face[i]; const b = face[(i + 1) % face.length];
      const originalEdge = edgeLookup.get(Math.min(a,b) + ':' + Math.max(a,b));
      if (originalEdge == null) continue;
      for (const id of sourceEdgeHits[originalEdge] || []) hits.add(id);
    }
    const ids = [...hits];
    if (ids.length === 2) {
      addLine(ids[0], ids[1]);
    } else if (ids.length > 2) {
      // Coincident or degenerate cuts: connect the farthest pair in the face.
      let longest = -1; let first = ids[0]; let last = ids[1];
      for (let a = 0; a < ids.length; a++) {
        for (let b = a + 1; b < ids.length; b++) {
          const d = vertices[ids[a]].reduce((sum, coordinate, k) =>
            sum + (coordinate - vertices[ids[b]][k]) ** 2, 0);
          if (d > longest) { longest = d; first = ids[a]; last = ids[b]; }
        }
      }
      addLine(first, last);
    }
  }
  return { vertices, edges, vertexCount: vertices.length, edgeCount: edges.length };
}
