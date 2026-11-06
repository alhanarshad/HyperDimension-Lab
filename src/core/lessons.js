/** Curated learning prompts and scene presets. Made by Alhan. */
export const LESSONS = [
  {
    eyebrow: '01 / THE FIRST SHADOW', title: 'A cube is a shadow, too.',
    body: 'A 3D cube can cast a 2D shadow. The image loses depth, but it still contains clues about the original object. The same idea extends to a 4D object casting a 3D shadow.',
    dimension: 3, shape: 'hypercube', projection: 'orthographic', plane: '0:2',
    takeaway: 'Projections discard dimensions. They are useful views, not the whole object.'
  },
  {
    eyebrow: '02 / BEYOND THE CUBE', title: 'Meet the tesseract.',
    body: 'A tesseract is a 4D hypercube. It has 16 vertices, 32 edges, 24 square faces, and 8 cubic cells. The nested shapes you see are a 2D rendering of its 3D projection.',
    dimension: 4, shape: 'hypercube', projection: 'perspective', plane: '0:3',
    takeaway: 'Rotating in XW changes a 4D view in ways impossible for a rigid 3D rotation.'
  },
  {
    eyebrow: '03 / ONE PLANE AT A TIME', title: 'Rotation has two axes.',
    body: 'In 3D you may describe a rotation around an axis. More generally, a rotation occurs within a plane. 4D has six independent coordinate planes. 5D has ten, and 6D has fifteen.',
    dimension: 4, shape: 'orthoplex', projection: 'perspective', plane: '1:3',
    takeaway: 'Try rotating in XW, then YW, and watch the structure change.'
  },
  {
    eyebrow: '04 / CUTTING THROUGH', title: 'Make a dimension disappear.',
    body: 'Imagine a 3D cube passing through a flat 2D world: the inhabitants see changing slices. The same technique reveals the 3D cross-section of a rotating 4D object.',
    dimension: 4, shape: 'hypercube', projection: 'perspective', plane: '0:3', mode: 'slice',
    takeaway: 'A plane intersecting an nD polytope usually creates an (n−1)D section.'
  },
  {
    eyebrow: '05 / HIGHER STILL', title: 'Five dimensions, thirty-two corners.',
    body: 'A 5D hypercube has 32 vertices and 80 edges. Its projections are much denser because each vertex has five neighbors. The mathematics stays systematic even when intuition struggles.',
    dimension: 5, shape: 'hypercube', projection: 'perspective', plane: '0:4',
    takeaway: 'Each extra hypercube dimension doubles its vertices.'
  },
  {
    eyebrow: '06 / SIX DIMENSIONS', title: 'The hexeract.',
    body: 'A 6D hypercube has 64 vertices, 192 edges and 240 square faces. You cannot literally see six dimensions; here you can explore a consistent mathematical projection of them.',
    dimension: 6, shape: 'hypercube', projection: 'perspective', plane: '1:5',
    takeaway: 'The same geometric rules work beyond what we can physically visualize.'
  }
];

export const SHAPE_NOTES = {
  hypercube: 'A hypercube extends the pattern: segment → square → cube → tesseract → penteract → hexeract.',
  simplex: 'A simplex is the higher-dimensional counterpart of a triangle or tetrahedron. Every vertex connects to every other.',
  orthoplex: 'An orthoplex is built from pairs of opposite points on each axis. It is dual to a hypercube.',
  duoprism: 'A duoprism is a Cartesian product of two polygons. It behaves differently from a hypercube even when both live in 4D.'
};

export function dimensionDescription(dimension) {
  const names = { 3: 'Ordinary space', 4: 'Four dimensions', 5: 'Five dimensions', 6: 'Six dimensions' };
  return names[dimension] || 'Higher-dimensional space';
}
