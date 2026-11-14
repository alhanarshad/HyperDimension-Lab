import test from "node:test";
import assert from "node:assert/strict";
import { EXAMPLE, inspectProfile, parseProfile } from "./profile.mjs";

test("computes signed grade and ascent independently", () => {
  const report = inspectProfile(parseProfile("0,10\n10,15\n30,10"), 30);
  assert.deepEqual(report.sections.map(({ grade, steep }) => [grade, steep]), [[50, true], [-25, false]]);
  assert.equal(report.ascent, 5);
  assert.equal(report.descent, 5);
});
test("rejects duplicates, backtracking, and unknown fields", () => {
  for (const sample of ["0,0\n0,1", "3,2\n1,4", "0,2\n1,4,8", "0,2\n1,NaN", "0,1"]) {
    assert.throws(() => parseProfile(sample));
  }
});
test("example spans the expected distance", () => {
  assert.equal(inspectProfile(parseProfile(EXAMPLE), 12).distance, 960);
});
