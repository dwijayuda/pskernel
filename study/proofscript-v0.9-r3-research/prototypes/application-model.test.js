"use strict";
const assert = require("node:assert/strict");
const m = require("./application-model.js");

const cases = [
  [m.success(1), m.success(undefined), "success"],
  [m.failure("body"), m.success(undefined), "failure"],
  [m.cancelled("stop"), m.success(undefined), "cancelled"],
  [m.success(1), m.failure("release"), "failure"],
];

for (const [body, release, expected] of cases) {
  assert.equal(m.finalizeResource(body, release).exit.tag, expected);
}

for (const body of [m.failure("body"), m.cancelled("stop"), m.panic("panic")]) {
  const out = m.finalizeResource(body, m.failure("release"));
  assert.equal(out.exit.tag, "cleanupFailure");
  assert.equal(out.exit.body.tag, body.tag);
  assert.equal(out.exit.cleanup.tag, "failure");
}

const race = m.raceModel(
  { name: "a", exit: m.success(7) },
  { name: "b", exit: m.cancelled("loser") }
);

assert.equal(race.exit.tag, "success");
assert.deepEqual(race.trace, [
  "winner:a:success",
  "cancel-request:b",
  "cleanup-awaited:b",
  "scope-complete"
]);

console.log(JSON.stringify({status:"passed", resourceCases:7, raceCases:1}));
