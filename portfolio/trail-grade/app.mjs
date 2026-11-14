import { EXAMPLE, inspectProfile, parseProfile } from "./profile.mjs";

const get = (id) => document.getElementById(id);
const canvas = get("chart");
const ctx = canvas.getContext("2d");
let last;
const meters = new Intl.NumberFormat(undefined, { maximumFractionDigits: 1 });
const lengthText = (n) => `${meters.format(n)} m`;
const gradeText = (n) => `${n.toFixed(1)}%`;

function draw(points, sections) {
  const colors = { grid: "#334a3b", text: "#b2c3b6", line: "#a9e8b4", steep: "#ffd287" };
  const width = canvas.width;
  const height = canvas.height;
  const left = 68, right = width - 18, top = 22, bottom = height - 39;
  const elevations = points.map((p) => p.elevation);
  const floor = Math.min(...elevations);
  const span = Math.max(5, Math.max(...elevations) - floor);
  const start = points[0].distance;
  const end = points.at(-1).distance;
  const x = (distance) => left + (distance - start) / (end - start) * (right - left);
  const y = (elevation) => bottom - (elevation - floor) / span * (bottom - top);
  ctx.clearRect(0, 0, width, height);
  ctx.font = "16px ui-monospace, monospace";
  ctx.textAlign = "right";
  for (let i = 0; i <= 4; i++) {
    const value = floor + i * span / 4;
    const at = y(value);
    ctx.strokeStyle = colors.grid;
    ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(left, at); ctx.lineTo(right, at); ctx.stroke();
    ctx.fillStyle = colors.text;
    ctx.fillText(lengthText(value), left - 8, at + 5);
  }
  ctx.textAlign = "center";
  for (let i = 0; i <= 4; i++) {
    const distance = start + i * (end - start) / 4;
    ctx.fillText(lengthText(distance), x(distance), bottom + 26);
  }
  ctx.beginPath();
  ctx.moveTo(x(start), bottom);
  for (const point of points) ctx.lineTo(x(point.distance), y(point.elevation));
  ctx.lineTo(x(end), bottom);
  ctx.closePath();
  ctx.fillStyle = "#1e3d2d";
  ctx.fill();
  ctx.lineWidth = 3;
  ctx.lineJoin = "round";
  for (const { from, to, steep } of sections) {
    ctx.strokeStyle = steep ? colors.steep : colors.line;
    ctx.beginPath(); ctx.moveTo(x(from.distance), y(from.elevation)); ctx.lineTo(x(to.distance), y(to.elevation)); ctx.stroke();
  }
}

function refresh() {
  const threshold = Number(get("threshold").value);
  get("threshold-value").textContent = `${threshold}%`;
  try {
    const points = parseProfile(get("samples").value);
    const report = inspectProfile(points, threshold);
    for (const key of ["distance", "ascent", "descent"]) get(key).textContent = lengthText(report[key]);
    get("maximum").textContent = gradeText(report.maximum);
    const fragment = document.createDocumentFragment();
    for (const section of report.sections) {
      const row = document.createElement("tr");
      row.dataset.steep = section.steep;
      for (const value of [lengthText(section.from.distance), lengthText(section.to.distance), gradeText(section.grade), lengthText(section.change)]) {
        const cell = document.createElement("td");
        cell.textContent = value;
        row.append(cell);
      }
      fragment.append(row);
    }
    get("sections").replaceChildren(fragment);
    get("error").textContent = "";
    last = { points, sections: report.sections };
    draw(last.points, last.sections);
  } catch (error) {
    get("error").textContent = `${error.message} ${last ? "Showing the last valid profile." : ""}`;
  }
}

get("controls").addEventListener("submit", (event) => { event.preventDefault(); refresh(); });
get("threshold").addEventListener("input", refresh);
get("example").addEventListener("click", () => { get("samples").value = EXAMPLE; refresh(); });
get("samples").value = EXAMPLE;
refresh();
