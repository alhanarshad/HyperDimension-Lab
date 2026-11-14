const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

function element() {
  return {
    value: "",
    hidden: false,
    textContent: "",
    attributes: {},
    listeners: {},
    setAttribute(name, value) { this.attributes[name] = value; },
    addEventListener(name, listener) { this.listeners[name] = listener; },
    emit(name) { this.listeners[name]({ preventDefault() {} }); },
    focus() { this.focused = true; },
  };
}

test("collect unique stars, validate the riddle, and restart", () => {
  const ids = ["stars", "status", "quest-title", "instruction", "riddle", "answer", "celebration", "restart"];
  const elements = Object.fromEntries(ids.map((id) => [id, element()]));
  const stars = Array.from({ length: 5 }, element);
  elements.stars.querySelectorAll = () => stars;
  elements.riddle.hidden = true;
  elements.celebration.hidden = true;
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, "quest.js"), "utf8"), {
    document: { getElementById: (id) => elements[id] },
  });
  stars[0].emit("click");
  stars[0].emit("click");
  assert.equal(elements.status.textContent, "1 of 3 stars collected.");
  stars[1].emit("click");
  stars[2].emit("click");
  assert.equal(elements.riddle.hidden, false);
  assert.equal(elements.answer.focused, true);
  elements.answer.value = "flame";
  elements.riddle.emit("submit");
  assert.equal(elements.celebration.hidden, true);
  elements.answer.value = " A Candle ";
  elements.riddle.emit("submit");
  assert.equal(elements.celebration.hidden, false);
  elements.restart.emit("click");
  assert.equal(elements.celebration.hidden, true);
  assert.equal(stars[0].attributes["aria-pressed"], "false");
});
