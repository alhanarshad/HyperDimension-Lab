# HyperDimension Lab

**Explore geometry beyond three dimensions.**

HyperDimension Lab is a browser-based geometry studio for rotating, projecting and slicing polytopes in three, four, five and six dimensions. It uses a small original mathematics engine and the Canvas 2D API. It has no runtime dependencies, no accounts and no tracking.

**Made by Alhan**

## What you can do

- Switch between 3D, 4D, 5D and 6D spaces.
- Explore four families of polytopes: hypercubes, simplices, orthoplexes and polygon-product duoprisms. Duoprisms require four or more dimensions.
- Rotate objects through any available coordinate plane. 4D offers 6 planes, 5D offers 10 and 6D offers 15.
- Compare perspective and orthographic projections side by side.
- Intersect shapes with a real coordinate hyperplane and see the resulting section's vertices and edges. The section uses vertex-edge and face intersections in the original dimension, then projects the result for display.
- Change the projection distance, orbit the camera, zoom, display coordinate axes and vertex indexes.
- Read six guided lessons explaining projections, tesseracts, rotation planes, slicing and higher dimensions.
- Save a PNG of your view or copy a link to the main scene settings.

## Quick start

Requires Node.js 20 or later. No `npm install` needed.

```bash
npm start
```

Open <http://localhost:4173> in a browser.

Alternatively, use any local static HTTP server from the project directory:

```bash
python -m http.server 4173
```

Do not use the `file://` protocol because the browser loads source files as JavaScript modules.

## Controls

| Action | Input |
|---|---|
| Orbit 3D camera | Drag on scene |
| Zoom | Mouse wheel or trackpad |
| Pause or play rotation | Space |
| Reset the scene | R |
| Open slice view | S |
| Open comparison | C |
| Return to explorer | E |
| Orbit in small steps | Left and right arrow keys |
| Recenter camera | Double-click scene |
| Change actual higher-dimensional rotation | Select an XY, XW, YV or other plane in the left panel |

## A note on the mathematics

You cannot display four, five or six spatial dimensions directly on a two-dimensional screen. HyperDimension Lab does something more precise: it builds vertices and edges in \(\mathbb{R}^n\), applies rotations in selected coordinate planes, projects the coordinates into \(\mathbb{R}^3\) and uses a virtual camera to render the final image.

- A hypercube has \(2^n\) vertices, \(n2^{n-1}\) edges and \(\binom{n}{2}2^{n-2}\) square faces.
- A regular n-simplex has \(n+1\) vertices, with every pair joined by an edge.
- An n-orthoplex has \(2n\) vertices, organized as opposite pairs on n axes.
- The duoprism family here is the Cartesian product of a pentagon and a square, optionally multiplied by one or two line segments for 5D and 6D.
- Rotations preserve n-dimensional distances. The renderer uses successive depth-aware projections for each hidden axis. These projections are educational visualizations rather than literal human vision of higher-dimensional space.
- In slicing mode, the application intersects the hyperplane with polytope edges to determine section vertices, then cuts the original two-dimensional faces to derive section edges. Coincident and numerically degenerate cases are handled conservatively.

## Code structure

```text
index.html                 Main interface
src/styles.css             Interface styles and responsive layouts
src/app.js                 Application state and interaction
src/core/math.js           Vector operations and rotation planes
src/core/geometry.js       Geometry generators and topology
src/core/projection.js     Higher-dimensional and camera projections
src/core/slice.js          Hyperplane cross-section algorithm
src/core/lessons.js        Guided learning content
src/ui/renderer.js         Canvas renderer and PNG output
assets/icon.svg            App icon
server.js                  Local development server
package.json               Scripts, no runtime dependencies
tests/                     Math and geometry tests
.github/workflows/         Automated verification
```

## Development

```bash
npm run check
npm test
```

The project intentionally stays framework-free so that the core math is readable and portable. A good first contribution is another family of regular polytopes, a better high-dimensional clipping algorithm, or a new teaching module. Open a GitHub issue with a reproducible example before making significant changes.

## Limitations

The renderer displays wireframes, not solid volumetric cells. The screenshot output captures the canvas only, not the surrounding controls. Shared URLs restore the key scene settings, not every camera gesture or animation frame. The higher-dimensional projection uses a configurable perspective model; there is no single uniquely correct 2D picture of a 4D object.

## License

MIT © 2026 Alhan Arshad. Reuse is permitted under the MIT terms with the required copyright and license notices.

**Made by Alhan.**
