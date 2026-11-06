/**
 * High-resolution Canvas 2D scene renderer, scene interaction and export.
 * Fully independent of 3D libraries. Made by Alhan.
 */
import { AXIS_NAMES, clamp } from '../core/math.js';
import { projectTo3D, cameraToScreen } from '../core/projection.js';

const COLORS = ['#7ca9ff', '#a88cff', '#6fe4d5', '#ffc18a', '#f997cf', '#e7de88'];
const TYPE = { explorer: 'Explorer', slice: 'Cross section', compare: 'Compare', learn: 'Guided view' };

function hexToRgba(hex, alpha) {
  const value = hex.replace('#', '');
  const r = Number.parseInt(value.slice(0, 2), 16);
  const g = Number.parseInt(value.slice(2, 4), 16);
  const b = Number.parseInt(value.slice(4, 6), 16);
  return `rgba(${r},${g},${b},${alpha})`;
}

function directionAxis(first, second) {
  let maxDifference = 0; let axis = 0;
  for (let i = 0; i < first.length; i++) {
    const difference = Math.abs(first[i] - second[i]);
    if (difference > maxDifference) { maxDifference = difference; axis = i; }
  }
  return axis;
}

export class SceneRenderer {
  constructor(canvas, stage, tooltip) {
    this.canvas = canvas;
    this.stage = stage;
    this.tooltip = tooltip;
    this.ctx = canvas.getContext('2d', { alpha: false });
    this.points = [];
    this.width = 0;
    this.height = 0;
    this.ratio = 1;
    this.hovered = -1;
    this.lastState = null;
    this.lastGeometry = null;
    this.lastVertices = [];
    this.stars = Array.from({ length: 65 }, (_, index) => {
      const f = v => (Math.sin(v * 127.1 + 78.233) * 43758.5453) % 1;
      return { x: Math.abs(f(index + 1)), y: Math.abs(f(index + 201)), size: 0.3 + Math.abs(f(index + 401)) * 1.2 };
    });
    this.resizeObserver = new ResizeObserver(() => this.resize());
    this.resizeObserver.observe(stage);
    this.resize();
  }

  resize() {
    const rect = this.canvas.getBoundingClientRect();
    if (!rect.width || !rect.height) return;
    this.width = rect.width;
    this.height = rect.height;
    this.ratio = Math.min(window.devicePixelRatio || 1, 2);
    this.canvas.width = Math.round(rect.width * this.ratio);
    this.canvas.height = Math.round(rect.height * this.ratio);
    this.ctx.setTransform(this.ratio, 0, 0, this.ratio, 0, 0);
  }

  background() {
    const { ctx, width: w, height: h } = this;
    ctx.fillStyle = '#080c15';
    ctx.fillRect(0, 0, w, h);
    const glow = ctx.createRadialGradient(w * .5, h * .48, 10, w * .5, h * .48, w * .58);
    glow.addColorStop(0, '#17203b');
    glow.addColorStop(.42, '#0d1426');
    glow.addColorStop(1, 'rgba(8,12,21,0)');
    ctx.fillStyle = glow;
    ctx.fillRect(0, 0, w, h);

    ctx.save();
    ctx.strokeStyle = 'rgba(133,157,208,.047)';
    ctx.lineWidth = 1;
    const step = 47;
    for (let x = (w % step) / 2; x < w; x += step) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
    }
    for (let y = (h % step) / 2; y < h; y += step) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
    }
    for (const star of this.stars) {
      ctx.fillStyle = 'rgba(193,214,255,.23)';
      ctx.beginPath();
      ctx.arc(w * star.x, h * star.y, star.size, 0, 2 * Math.PI);
      ctx.fill();
    }
    ctx.restore();
  }

  label(text, x, y, align = 'left', color = '#9ca9c4', size = 10) {
    const { ctx } = this;
    ctx.font = `600 ${size}px Inter, system-ui, sans-serif`;
    ctx.textAlign = align;
    ctx.textBaseline = 'middle';
    ctx.fillStyle = color;
    ctx.fillText(text, x, y);
  }

  drawAxes(center, size, camera) {
    const { ctx } = this;
    const origin = cameraToScreen([0,0,0], camera, center, size);
    for (let axis = 0; axis < 3; axis++) {
      const destination = [0,0,0]; destination[axis] = 1.7;
      const tip = cameraToScreen(destination, camera, center, size);
      ctx.beginPath(); ctx.moveTo(origin.x, origin.y); ctx.lineTo(tip.x, tip.y);
      ctx.strokeStyle = hexToRgba(COLORS[axis], .38);
      ctx.lineWidth = 1;
      ctx.setLineDash([3,7]); ctx.stroke(); ctx.setLineDash([]);
      this.label(AXIS_NAMES[axis], tip.x + 9, tip.y, 'left', COLORS[axis]);
    }
  }

  toScreen(vertices, center, size, camera, projection, depth) {
    return vertices.map(vertex => {
      const projected = projectTo3D(vertex, projection, depth);
      return cameraToScreen(projected.point, camera, center, size);
    });
  }

  drawEdges(geometry, positions, originalVertices, opacity, state, isSection = false) {
    const { ctx } = this;
    const segments = geometry.edges.map(([a,b]) => ({ a, b, z: (positions[a].z + positions[b].z) * .5 }))
      .sort((a,b) => a.z - b.z);
    for (const segment of segments) {
      const p = positions[segment.a]; const q = positions[segment.b];
      if (!p || !q) continue;
      const axis = isSection ? 2 : directionAxis(originalVertices[segment.a], originalVertices[segment.b]);
      const color = isSection ? '#87f5e7' : COLORS[axis];
      const fade = clamp(.75 + segment.z * .14, .22, 1);
      ctx.beginPath(); ctx.moveTo(p.x, p.y); ctx.lineTo(q.x, q.y);
      if (state.glow && opacity > .3) {
        ctx.shadowColor = hexToRgba(color, .78);
        ctx.shadowBlur = isSection ? 18 : 10;
      }
      const gradient = ctx.createLinearGradient(p.x, p.y, q.x || p.x + .001, q.y || p.y + .001);
      gradient.addColorStop(0, hexToRgba(color, opacity * fade * .67));
      gradient.addColorStop(.55, hexToRgba(color, opacity * fade));
      gradient.addColorStop(1, hexToRgba('#ffffff', opacity * fade * .63));
      ctx.strokeStyle = gradient;
      ctx.lineWidth = isSection ? 2.35 : clamp(1.15 + segment.z * .13, .8, 2.1);
      ctx.stroke(); ctx.shadowBlur = 0;
    }
  }

  drawNodes(positions, state, opacity = 1, section = false) {
    const { ctx } = this;
    for (let index = 0; index < positions.length; index++) {
      const point = positions[index];
      const highlighted = !section && this.hovered === index;
      const radius = highlighted ? 5.8 : section ? 3.1 : clamp(2.7 + point.z * .16, 1.8, 4.3);
      const color = section ? '#95fff1' : highlighted ? '#ffffff' : '#d1ddff';
      ctx.beginPath(); ctx.arc(point.x, point.y, radius, 0, Math.PI * 2);
      ctx.fillStyle = hexToRgba(color, opacity);
      if (state.glow && opacity > .3) {
        ctx.shadowColor = color; ctx.shadowBlur = highlighted ? 24 : 12;
      }
      ctx.fill(); ctx.shadowBlur = 0;
      if (highlighted) {
        ctx.beginPath(); ctx.arc(point.x, point.y, 10, 0, Math.PI * 2);
        ctx.strokeStyle = 'rgba(255,255,255,.4)'; ctx.lineWidth = 1; ctx.stroke();
      }
    }
  }

  renderView(bounds, state, geometry, transformed, section, projection, contextLabel) {
    const { ctx } = this;
    const { left, top, width, height } = bounds;
    ctx.save(); ctx.beginPath(); ctx.rect(left, top, width, height); ctx.clip();
    const center = { x: left + width / 2, y: top + height / 2 + 9 };
    const base = Math.min(width, height) * 1.21;
    const positions = this.toScreen(transformed, center, base, state.camera, projection, state.depth);
    if (state.showAxes) this.drawAxes(center, base, state.camera);

    const dimmed = state.mode === 'slice';
    if (state.showEdges) this.drawEdges(geometry, positions, geometry.vertices, dimmed ? .15 : .82, state);
    if (state.showVertices) this.drawNodes(positions, state, dimmed ? .2 : 1);

    if (state.mode === 'slice' && section) {
      const sliced = this.toScreen(section.vertices, center, base, state.camera, projection, state.depth);
      if (state.showEdges) this.drawEdges(section, sliced, section.vertices, .98, state, true);
      this.drawNodes(sliced, state, 1, true);
      if (sliced.length === 0) this.label('NO INTERSECTION AT THIS POSITION', center.x, center.y, 'center', '#a6b1cb', 12);
    }
    if (state.showLabels && !dimmed) {
      positions.forEach((point, i) => {
        if (positions.length > 32 && i % 2 !== 0) return;
        this.label(String(i), point.x + 8, point.y - 9, 'left', 'rgba(213,226,255,.72)', 10);
      });
    }
    if (contextLabel) {
      ctx.fillStyle = 'rgba(12,17,28,.84)';
      ctx.fillRect(left + 17, top + 17, Math.min(174, width - 34), 29);
      this.label(contextLabel, left + 29, top + 32, 'left', '#becae6', 10);
    }
    ctx.restore();
    return positions;
  }

  render(state, geometry, transformed, section = null) {
    if (this.width === 0 || this.height === 0) return;
    const { width: w, height: h, ctx } = this;
    this.lastState = state;
    this.lastGeometry = geometry;
    this.lastVertices = transformed;
    this.background();
    if (state.mode === 'compare') {
      const half = w / 2;
      this.points = this.renderView({left:0,top:0,width:half,height:h}, state, geometry, transformed, null, 'perspective', 'PERSPECTIVE');
      this.renderView({left:half,top:0,width:half,height:h}, state, geometry, transformed, null, 'orthographic', 'ORTHOGRAPHIC');
      ctx.strokeStyle = 'rgba(155,172,204,.24)';
      ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(half, 0); ctx.lineTo(half,h); ctx.stroke();
    } else {
      this.points = this.renderView({left:0,top:0,width:w,height:h}, state, geometry, transformed, section, state.projection,
        state.mode === 'slice' ? 'HYPERPLANE INTERSECTION' : null);
    }
    ctx.save();
    const marker = (state.mode === 'slice' ? 'SECTION' : state.mode === 'compare' ? 'DUAL VIEW' : `${geometry.dimension}D VIEW`);
    this.label(marker, w - 23, h - 24, 'right', 'rgba(169,185,218,.52)', 10);
    this.label('HYPERDIMENSION LAB   /   MADE BY ALHAN', 23, h - 24, 'left', 'rgba(169,185,218,.43)', 9);
    ctx.restore();
  }

  hoverAt(clientX, clientY) {
    if (!this.lastState || !this.lastGeometry) return;
    const rect = this.canvas.getBoundingClientRect();
    const x = clientX - rect.left; const y = clientY - rect.top;
    let closest = -1; let minimum = 14 ** 2;
    for (let i = 0; i < this.points.length; i++) {
      const p = this.points[i];
      const d = (p.x - x) ** 2 + (p.y - y) ** 2;
      if (d < minimum) { minimum = d; closest = i; }
    }
    this.hovered = closest;
    if (closest === -1 || this.lastState.mode === 'slice') {
      this.tooltip.hidden = true;
      return;
    }
    const values = this.lastVertices[closest].map(value => Math.abs(value) < .005 ? '0' : value.toFixed(2));
    this.tooltip.textContent = `Vertex ${closest}   [${values.join(', ')}]`;
    const left = clamp(x + 16, 10, this.width - 225);
    const top = clamp(y - 37, 10, this.height - 45);
    this.tooltip.style.left = `${left}px`;
    this.tooltip.style.top = `${top}px`;
    this.tooltip.hidden = false;
  }

  downloadImage() {
    const link = document.createElement('a');
    link.download = `hyperdimension-${this.lastState.dimension}d-${this.lastState.shape}.png`;
    link.href = this.canvas.toDataURL('image/png');
    link.click();
  }

  destroy() { this.resizeObserver.disconnect(); }
}
