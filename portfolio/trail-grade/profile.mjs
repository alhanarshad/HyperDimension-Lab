export const EXAMPLE = `0,264
85,269
165,278
240,293
290,302
360,299
455,285
535,287
625,303
695,322
760,326
865,311
960,306`;

export function parseProfile(input) {
  const points = [];
  for (const [index, row] of input.split(/\r?\n/).entries()) {
    const line = row.trim();
    if (!line || line.startsWith("#")) continue;
    const fields = line.split(",").map((value) => value.trim());
    if (fields.length !== 2 || fields.some((field) => !/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/.test(field))) {
      throw new Error(`Line ${index + 1} needs two decimal numbers.`);
    }
    const [distance, elevation] = fields.map(Number);
    if (!Number.isFinite(distance) || !Number.isFinite(elevation) || distance < 0) {
      throw new Error(`Line ${index + 1} has an invalid distance or elevation.`);
    }
    if (points.length && distance <= points.at(-1).distance) {
      throw new Error(`Distance must increase on line ${index + 1}.`);
    }
    points.push({ distance, elevation });
    if (points.length > 2000) throw new Error("Use at most 2,000 samples.");
  }
  if (points.length < 2) throw new Error("Enter at least two samples.");
  return points;
}

export function inspectProfile(points, threshold) {
  let ascent = 0;
  let descent = 0;
  let maximum = 0;
  const sections = [];
  for (let index = 1; index < points.length; index++) {
    const from = points[index - 1];
    const to = points[index];
    const change = to.elevation - from.elevation;
    const grade = 100 * (change / (to.distance - from.distance));
    if (!Number.isFinite(grade) || !Number.isFinite(change)) throw new Error("A section exceeds the numeric range.");
    ascent += Math.max(change, 0);
    descent += Math.max(-change, 0);
    if (Math.abs(grade) > Math.abs(maximum)) maximum = grade;
    sections.push({ from, to, change, grade, steep: Math.abs(grade) >= threshold });
  }
  return { sections, ascent, descent, maximum, distance: points.at(-1).distance - points[0].distance };
}
