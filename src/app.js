/**
 * HyperDimension Lab application controller.
 * A hands-on exploration of 3D through 6D geometry.
 * Made by Alhan. Copyright 2026 Alhan Arshad. Licensed under MIT.
 */
import { makePolytope, SHAPES } from './core/geometry.js';
import { AXIS_NAMES, planePairs, clamp, signed } from './core/math.js';
import { transformVertices } from './core/projection.js';
import { intersectPolytope } from './core/slice.js';
import { LESSONS, SHAPE_NOTES, dimensionDescription } from './core/lessons.js';
import { SceneRenderer } from './ui/renderer.js';

const byId = id => document.getElementById(id);
const query = new URLSearchParams(location.search);
const DIMENSION_NAMES = {3:'The Third Dimension',4:'The Fourth Dimension',5:'The Fifth Dimension',6:'The Sixth Dimension'};
const HYPERCUBE_NAMES = {3:'CUBE',4:'TESSERACT',5:'PENTERACT',6:'HEXERACT'};
const PLANE_LABEL = plane => plane.split(':').map(index => AXIS_NAMES[Number(index)]).join('');
const isReducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
const queryDimension = Number(query.get('d'));
const initialDimension = Number.isInteger(queryDimension) && queryDimension >= 3 && queryDimension <= 6 ? queryDimension : 4;
const initialShape = SHAPES.some(shape => shape.id === query.get('s') && initialDimension >= shape.min) ? query.get('s') : 'hypercube';

const state = {
  dimension: initialDimension,
  shape: initialShape,
  mode: ['explorer','slice','compare','learn'].includes(query.get('m')) ? query.get('m') : 'explorer',
  projection: query.get('p') === 'orthographic' ? 'orthographic' : 'perspective',
  depth: clamp(Number(query.get('depth')) || 3.4, 2.4, 7),
  speed: .55,
  playing: !isReducedMotion,
  compound: true,
  plane: '',
  angles: {},
  showEdges: true,
  showVertices: true,
  showAxes: false,
  showLabels: false,
  glow: true,
  sliceAxis: Math.min(initialDimension - 1, 3),
  sliceValue: clamp(Number(query.get('cut')) || 0, -1.6, 1.6),
  camera: {yaw:-.44, pitch:.24, zoom:1, cameraMode:'perspective'},
  lesson: 1
};

function defaultPlane(dimension) { return `0:${Math.min(dimension - 1, 3)}`; }
function resetAngles() {
  state.angles = { [defaultPlane(state.dimension)]: .34, '1:2': -.25 };
}
resetAngles();
state.plane = query.get('plane') && planePairs(initialDimension).some(pair => pair.join(':') === query.get('plane')) ? query.get('plane') : defaultPlane(initialDimension);

let geometry = makePolytope(state.shape, state.dimension);
let renderer = null;
let toastTimer = null;
let previousFrame = performance.now();
let frameCounter = 0;
let fpsElapsed = 0;
let isDragging = false;
let previousPointer = [0,0];

function toast(text) {
  const element = byId('toast');
  element.textContent = text;
  element.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { element.hidden = true; }, 2600);
}

function updateGeometry() {
  geometry = makePolytope(state.shape, state.dimension);
  state.sliceAxis = Math.min(state.sliceAxis, state.dimension - 1);
  if (!planePairs(state.dimension).some(pair => pair.join(':') === state.plane)) state.plane = defaultPlane(state.dimension);
}

function changeDimension(dimension) {
  if (dimension === state.dimension) return;
  state.dimension = dimension;
  if (dimension < 4 && state.shape === 'duoprism') state.shape = 'hypercube';
  state.sliceAxis = Math.min(dimension - 1, 3);
  state.sliceValue = 0;
  state.plane = defaultPlane(dimension);
  resetAngles();
  updateGeometry();
  updateUI();
}

function changeShape(shape) {
  if (state.shape === shape) return;
  if (SHAPES.find(item => item.id === shape)?.min > state.dimension) return;
  state.shape = shape;
  updateGeometry();
  updateUI();
}

function changeMode(mode) {
  state.mode = mode;
  if (mode === 'learn') selectLesson(state.lesson);
  updateUI();
}

function selectLesson(index) {
  const clamped = clamp(index, 0, LESSONS.length - 1);
  state.lesson = clamped;
  const lesson = LESSONS[clamped];
  state.dimension = lesson.dimension;
  state.shape = lesson.shape;
  state.projection = lesson.projection;
  state.plane = lesson.plane;
  state.sliceAxis = Math.min(state.dimension - 1, 3);
  state.sliceValue = 0;
  resetAngles();
  updateGeometry();
  updateUI();
}

function updateDimensions() {
  byId('dimensionPicker').innerHTML = [3,4,5,6].map(number =>
    `<button type="button" class="dimension-btn ${state.dimension === number ? 'active' : ''}" data-dimension="${number}" aria-pressed="${state.dimension === number}"><strong>${number}D</strong><small>${number === 3 ? 'SPACE' : 'HYPER'}</small></button>`).join('');
  byId('dimensionCaption').textContent = `${dimensionDescription(state.dimension)} · ${planePairs(state.dimension).length} rotation planes`;
}

function updateShapes() {
  const glyphs = { hypercube:'⬡', simplex:'△', orthoplex:'✧', duoprism:'◇' };
  byId('shapeGrid').innerHTML = SHAPES.map(item => {
    const disabled = state.dimension < item.min;
    return `<button type="button" class="shape-choice ${state.shape === item.id ? 'active' : ''}" data-shape="${item.id}" ${disabled ? 'disabled title="Requires 4D or higher"' : ''} aria-pressed="${state.shape === item.id}"><span class="shape-glyph" aria-hidden="true">${glyphs[item.id]}</span><strong>${item.label}</strong><small>${item.caption}</small></button>`;
  }).join('');
}

function updatePlanes() {
  const pairs = planePairs(state.dimension);
  byId('rotationCount').textContent = `${pairs.length} planes`;
  byId('planeList').innerHTML = pairs.map(pair => {
    const key = pair.join(':');
    const label = pair.map(index => AXIS_NAMES[index]).join('');
    return `<button type="button" class="plane-chip ${key === state.plane ? 'active' : ''}" data-plane="${key}" aria-pressed="${key === state.plane}">${label}</button>`;
  }).join('');
}

function updateInspector() {
  const dimension = state.dimension;
  const n = dimension;
  const planeCount = n * (n - 1) / 2;
  const label = state.shape === 'hypercube' ? HYPERCUBE_NAMES[n] : `${n}D ${state.shape.toUpperCase()}`;
  byId('objectTitle').textContent = label;
  byId('geometryLabel').textContent = label;
  byId('previewDimension').textContent = String(n).padStart(2, '0');
  byId('infoName').textContent = `${n}D ${geometry.name}`;
  byId('shapeDescription').textContent = geometry.description;
  byId('verticesCount').textContent = geometry.vertexCount.toLocaleString();
  byId('edgesCount').textContent = geometry.edgeCount.toLocaleString();
  byId('facesCount').textContent = geometry.faceCount.toLocaleString();
  byId('planesCount').textContent = planeCount;
  const formulae = {
    hypercube: ['V = 2<sup>n</sup>', `With n = ${n}, this gives ${geometry.vertexCount} vertices and ${geometry.edgeCount} edges.`],
    simplex: ['V = n + 1', `A ${n}D simplex has ${geometry.vertexCount} vertices, all pairwise connected.`],
    orthoplex: ['V = 2n', `There are exactly two opposite vertices on each of the ${n} axes.`],
    duoprism: ['V = 20 · 2<sup>n − 4</sup>', `This polygon product contains ${geometry.vertexCount} vertices in ${n} dimensions.`]
  };
  byId('formula').innerHTML = formulae[state.shape][0];
  byId('formulaDescription').textContent = formulae[state.shape][1];
  byId('coordinateChips').innerHTML = AXIS_NAMES.slice(0,n).map(axis => `<span>${axis}</span>`).join('');
  byId('coordinateDescription').textContent = n === 3 ? 'Three mutually perpendicular spatial coordinates.' :
    `${n} independent spatial coordinates. The extra axes represent spatial dimensions, not time.`;
  byId('stageDimension').textContent = `${n}D SPACE`;
  byId('figureNumber').textContent = String(n).padStart(3,'0');
  byId('projectionLabel').textContent = `${state.projection.toUpperCase()} PROJECTION`;
}

function updateSliceUI() {
  byId('sliceControls').hidden = state.mode !== 'slice';
  byId('sliceAxis').innerHTML = AXIS_NAMES.slice(0,state.dimension).map((axis, i) =>
    `<option value="${i}" ${state.sliceAxis === i ? 'selected' : ''}>${axis} axis</option>`).join('');
  byId('sliceRange').value = state.sliceValue;
  byId('planeEquation').textContent = `${AXIS_NAMES[state.sliceAxis]} = ${signed(state.sliceValue)}`;
}

function updateLessons() {
  const visible = state.mode === 'learn';
  byId('lessonCard').hidden = !visible;
  if (!visible) return;
  const lesson = LESSONS[state.lesson];
  byId('lessonEyebrow').textContent = lesson.eyebrow;
  byId('lessonTitle').textContent = lesson.title;
  byId('lessonBody').textContent = lesson.body;
  byId('lessonTakeaway').textContent = lesson.takeaway;
  byId('lessonCounter').textContent = `${String(state.lesson + 1).padStart(2,'0')} OF ${String(LESSONS.length).padStart(2,'0')}`;
  byId('previousLesson').disabled = state.lesson === 0;
  byId('nextLesson').disabled = state.lesson === LESSONS.length - 1;
}

function updateInsight() {
  const n = state.dimension;
  const insights = {
    explorer: [
      'You’re looking at a shadow of something larger.',
      `The ${n}D object is projected into 3D and then rendered on your 2D screen. Rotation reveals relationships hidden from any single view. ${SHAPE_NOTES[state.shape]}`
    ],
    slice: [
      'A lower-dimensional world comes into focus.',
      `The highlighted edges are the true intersection of this ${n}D polytope with a hyperplane. Move the slice to study how its cross-section changes.`
    ],
    compare: [
      'Two projections, one mathematical object.',
      'Perspective scales points using hidden-coordinate depth. Orthographic projection drops the extra coordinates without depth scaling. Compare their different apparent structures.'
    ],
    learn: [
      'Build intuition, one dimension at a time.',
      'The guided lessons move from familiar 3D shadows to tesseracts, rotation planes, cross-sections and the full six-dimensional hypercube.'
    ]
  };
  const [title, body] = insights[state.mode];
  byId('insightTitle').textContent = title;
  byId('insightText').textContent = body;
  byId('insightNumber').textContent = state.mode === 'learn' ? String(state.lesson + 1).padStart(2,'0') : '01';
  byId('insightAction').innerHTML = state.mode === 'learn' ? 'Back to explorer <span>↗</span>' : 'Start learning <span>↗</span>';
  byId('sceneHeading').innerHTML = `${DIMENSION_NAMES[n]}<span class="heading-period">.</span>`;
  let subtitle = `${geometry.name}: ${geometry.vertexCount} vertices and ${geometry.edgeCount} edges in ${n}D space.`;
  if (n === 4 && state.shape === 'hypercube') subtitle = 'A tesseract, seen through the limits of three-dimensional space.';
  if (state.mode === 'slice') subtitle = 'Move a hyperplane through the geometry to uncover its cross-sections.';
  if (state.mode === 'compare') subtitle = 'A single structure, seen through two fundamentally different projections.';
  if (state.mode === 'learn') subtitle = `Lesson ${state.lesson + 1} of ${LESSONS.length}: ${LESSONS[state.lesson].title}`;
  byId('sceneSubtitle').textContent = subtitle;
  byId('sceneOverline').textContent = {
    explorer: 'HYPERSPATIAL EXPLORATION', slice: 'GEOMETRIC CROSS SECTIONS', compare: 'PROJECTION COMPARISON', learn: 'THE FIELD GUIDE'
  }[state.mode];
}

function updateUI() {
  updateDimensions(); updateShapes(); updatePlanes(); updateInspector(); updateSliceUI(); updateLessons(); updateInsight();
  for (const button of document.querySelectorAll('[data-mode]')) {
    const active = button.dataset.mode === state.mode;
    button.classList.toggle('active', active);
    button.setAttribute('aria-selected', String(active));
  }
  for (const button of document.querySelectorAll('[data-projection]')) {
    button.classList.toggle('active', button.dataset.projection === state.projection);
  }
  byId('depthRange').value = state.depth;
  byId('depthOutput').textContent = state.depth.toFixed(1);
  byId('speedRange').value = state.speed;
  byId('speedOutput').textContent = `${state.speed.toFixed(2)}×`;
  byId('compoundToggle').checked = state.compound;
  const toggles = [ ['edgesToggle','showEdges'],['verticesToggle','showVertices'],['axesToggle','showAxes'],['labelsToggle','showLabels'],['glowToggle','glow'] ];
  for (const [id,key] of toggles) byId(id).checked = state[key];
  byId('playSymbol').textContent = state.playing ? 'Ⅱ' : '▶';
  byId('playButton').title = state.playing ? 'Pause animation (Space)' : 'Play animation (Space)';
  byId('playButton').setAttribute('aria-label', state.playing ? 'Pause rotation' : 'Play rotation');
}

function urlForView() {
  const url = new URL(location.href);
  url.searchParams.set('d', String(state.dimension));
  url.searchParams.set('s', state.shape);
  url.searchParams.set('m', state.mode === 'learn' ? 'explorer' : state.mode);
  url.searchParams.set('p', state.projection);
  url.searchParams.set('depth', String(state.depth));
  url.searchParams.set('plane', state.plane);
  url.searchParams.set('cut', String(state.sliceValue));
  return url.href;
}

function setupListeners() {
  byId('dimensionPicker').addEventListener('click', event => {
    const button = event.target.closest('[data-dimension]');
    if (button) changeDimension(Number(button.dataset.dimension));
  });
  byId('shapeGrid').addEventListener('click', event => {
    const button = event.target.closest('[data-shape]');
    if (button) changeShape(button.dataset.shape);
  });
  byId('planeList').addEventListener('click', event => {
    const button = event.target.closest('[data-plane]');
    if (button) { state.plane = button.dataset.plane; updatePlanes(); }
  });
  document.querySelectorAll('[data-mode]').forEach(button => button.addEventListener('click', () => changeMode(button.dataset.mode)));
  document.querySelectorAll('[data-projection]').forEach(button => button.addEventListener('click', () => {
    state.projection = button.dataset.projection; updateUI();
  }));
  byId('speedRange').addEventListener('input', e => { state.speed = Number(e.target.value); byId('speedOutput').textContent = `${state.speed.toFixed(2)}×`; });
  byId('depthRange').addEventListener('input', e => { state.depth = Number(e.target.value); byId('depthOutput').textContent = state.depth.toFixed(1); });
  byId('compoundToggle').addEventListener('change', e => { state.compound = e.target.checked; });
  for (const [id,key] of [ ['edgesToggle','showEdges'],['verticesToggle','showVertices'],['axesToggle','showAxes'],['labelsToggle','showLabels'],['glowToggle','glow'] ]) {
    byId(id).addEventListener('change', e => { state[key] = e.target.checked; });
  }
  byId('sliceAxis').addEventListener('change', e => { state.sliceAxis = Number(e.target.value); updateSliceUI(); });
  byId('sliceRange').addEventListener('input', e => { state.sliceValue = Number(e.target.value); byId('planeEquation').textContent = `${AXIS_NAMES[state.sliceAxis]} = ${signed(state.sliceValue)}`; });
  byId('centerSlice').addEventListener('click', () => { state.sliceValue = 0; updateSliceUI(); });
  byId('previousLesson').addEventListener('click', () => selectLesson(state.lesson - 1));
  byId('nextLesson').addEventListener('click', () => selectLesson(state.lesson + 1));
  byId('insightAction').addEventListener('click', () => changeMode(state.mode === 'learn' ? 'explorer' : 'learn'));
  byId('playButton').addEventListener('click', () => { state.playing = !state.playing; updateUI(); });
  byId('resetButton').addEventListener('click', () => {
    resetAngles(); state.camera = { yaw:-.44,pitch:.24,zoom:1,cameraMode:'perspective' }; state.sliceValue = 0;
    updateSliceUI(); toast('Scene reset');
  });
  byId('snapshotButton').addEventListener('click', () => { renderer.downloadImage(); toast('Image saved'); });
  byId('shareButton').addEventListener('click', async () => {
    try { await navigator.clipboard.writeText(urlForView()); toast('View link copied'); }
    catch { toast('Could not copy. Use the address bar to share this page.'); }
  });

  const canvas = byId('sceneCanvas');
  canvas.addEventListener('pointerdown', event => {
    if (event.button !== 0 && event.pointerType === 'mouse') return;
    isDragging = true;
    previousPointer = [event.clientX,event.clientY];
    canvas.setPointerCapture(event.pointerId);
    byId('vertexTooltip').hidden = true;
  });
  canvas.addEventListener('pointermove', event => {
    if (isDragging) {
      const dx = event.clientX - previousPointer[0];
      const dy = event.clientY - previousPointer[1];
      state.camera.yaw += dx * .007;
      state.camera.pitch = clamp(state.camera.pitch + dy * .007, -1.52, 1.52);
      previousPointer = [event.clientX,event.clientY];
    } else renderer.hoverAt(event.clientX, event.clientY);
  });
  canvas.addEventListener('pointerup', () => { isDragging = false; });
  canvas.addEventListener('pointercancel', () => { isDragging = false; });
  canvas.addEventListener('pointerleave', () => { byId('vertexTooltip').hidden = true; });
  canvas.addEventListener('wheel', event => {
    event.preventDefault();
    state.camera.zoom = clamp(state.camera.zoom * Math.exp(-event.deltaY * .001), .45, 3.5);
  }, { passive:false });
  canvas.addEventListener('dblclick', () => { state.camera.yaw = -.44; state.camera.pitch = .24; state.camera.zoom = 1; });
  window.addEventListener('keydown', event => {
    if (event.target instanceof HTMLElement && ['INPUT','SELECT','TEXTAREA','BUTTON'].includes(event.target.tagName)) return;
    const key = event.key.toLowerCase();
    if (event.code === 'Space') { event.preventDefault(); state.playing = !state.playing; updateUI(); }
    if (key === 'r') byId('resetButton').click();
    if (key === 's' && !event.ctrlKey && !event.metaKey) changeMode('slice');
    if (key === 'c' && !event.ctrlKey && !event.metaKey) changeMode('compare');
    if (key === 'e') changeMode('explorer');
    if (key === 'arrowleft') state.camera.yaw -= .11;
    if (key === 'arrowright') state.camera.yaw += .11;
  });
}

function spin(deltaSeconds) {
  if (!state.playing || state.speed === 0) return;
  const speed = deltaSeconds * state.speed * .44;
  const primary = state.plane;
  state.angles[primary] = ((state.angles[primary] || 0) + speed) % (Math.PI * 2);
  if (state.compound) {
    const mainAxes = primary.split(':').map(Number);
    const alt = planePairs(state.dimension).find(pair => pair.every(axis => !mainAxes.includes(axis))) ||
      planePairs(state.dimension).find(pair => pair.join(':') !== primary);
    if (alt) {
      const key = alt.join(':');
      state.angles[key] = ((state.angles[key] || 0) - speed * .44) % (Math.PI * 2);
    }
  }
}

function animate(now) {
  const seconds = clamp((now - previousFrame) / 1000, 0, .06);
  previousFrame = now;
  spin(seconds);
  const transformed = transformVertices(geometry.vertices, state.angles);
  const section = state.mode === 'slice' ? intersectPolytope(geometry, transformed, state.sliceAxis, state.sliceValue) : null;
  if (section) byId('sliceStats').textContent = `${section.vertexCount} section vertices · ${section.edgeCount} edges`;
  renderer.render(state, geometry, transformed, section);
  frameCounter++;
  fpsElapsed += seconds;
  if (fpsElapsed > 1) {
    byId('fpsCounter').textContent = `${Math.round(frameCounter / fpsElapsed)} FPS`;
    frameCounter = 0; fpsElapsed = 0;
  }
  requestAnimationFrame(animate);
}

function initialize() {
  renderer = new SceneRenderer(byId('sceneCanvas'), byId('stage'), byId('vertexTooltip'));
  setupListeners();
  if (state.mode === 'learn') selectLesson(1);
  updateUI();
  requestAnimationFrame(animate);
}
initialize();
