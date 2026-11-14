"use strict";

const get = (id) => document.getElementById(id);
const stars = Array.from(get("stars").querySelectorAll("button"));
const collected = new Set();
const status = get("status");

function reset() {
  collected.clear();
  for (const star of stars) {
    star.textContent = "✧";
    star.setAttribute("aria-pressed", "false");
  }
  get("quest-title").textContent = "Find the stars";
  get("instruction").hidden = false;
  get("stars").hidden = false;
  get("riddle").hidden = true;
  get("answer").value = "";
  get("celebration").hidden = true;
  status.textContent = "";
  stars[0].focus();
}

for (const [index, star] of stars.entries()) {
  star.addEventListener("click", () => {
    if (collected.has(index) || collected.size >= 3) return;
    collected.add(index);
    star.textContent = "✦";
    star.setAttribute("aria-pressed", "true");
    status.textContent = `${collected.size} of 3 stars collected.`;
    if (collected.size === 3) {
      get("quest-title").textContent = "Solve the riddle";
      get("instruction").hidden = true;
      get("stars").hidden = true;
      get("riddle").hidden = false;
      get("answer").focus();
    }
  });
}

get("riddle").addEventListener("submit", (event) => {
  event.preventDefault();
  const answer = get("answer").value.trim().toLowerCase().replace(/^a\s+/, "");
  if (answer !== "candle") {
    status.textContent = "Try something you might see on a cake.";
    return;
  }
  get("quest-title").textContent = "A birthday note";
  get("riddle").hidden = true;
  get("celebration").hidden = false;
  status.textContent = "Quest complete.";
  get("celebration").focus();
});

get("restart").addEventListener("click", reset);
