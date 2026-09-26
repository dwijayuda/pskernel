import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { nameFromDotted } from '../dist/src/core/name.js';
import {
  levelZero,
  levelSucc,
  levelParam,
  levelMVar,
  levelMaxRaw,
  levelIMaxRaw,
  mkMax,
  mkIMax,
  instantiateLevel,
  normalizeLevel,
  levelEquivalent,
  levelLe,
  levelToString,
} from '../dist/src/core/level.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_LEVEL_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/LevelFixture.lean'],
  {
    cwd: selfhost,
    encoding: 'utf8',
  },
);

if (fixtureRun.error) {
  fail(`could not run Lean fixture: ${fixtureRun.error.message}`);
}
if (fixtureRun.status !== 0) {
  if (fixtureRun.stdout) process.stderr.write(fixtureRun.stdout);
  if (fixtureRun.stderr) process.stderr.write(fixtureRun.stderr);
  fail(`Lean fixture exited with status ${fixtureRun.status}`);
}

const fixture = new Map();
for (const rawLine of fixtureRun.stdout.split(/\r?\n/)) {
  if (rawLine === '') continue;
  const tab = rawLine.indexOf('\t');
  if (tab <= 0) fail(`malformed fixture line: ${JSON.stringify(rawLine)}`);
  const key = rawLine.slice(0, tab);
  const value = rawLine.slice(tab + 1);
  if (fixture.has(key)) fail(`duplicate fixture key: ${key}`);
  fixture.set(key, value);
}

const uName = nameFromDotted('u');
const vName = nameFromDotted('v');
const wName = nameFromDotted('w');
const u = levelParam(uName);
const v = levelParam(vName);
const w = levelParam(wName);
const mU = levelMVar(uName);
const one = levelSucc(levelZero);
const u1 = levelSucc(u);
const u2 = levelSucc(u1);
const v1 = levelSucc(v);
const canonicalInput = levelMaxRaw(levelMaxRaw(v, u), w);
const imaxInput = levelIMaxRaw(v, u1);
const incompleteLeft = mkMax(v, u);
const incompleteRight = mkMax(mkIMax(u, v), u);

const expectedParity = new Map([
  ['smart.max.zero', levelToString(mkMax(levelZero, u))],
  ['smart.max.sameBase', levelToString(mkMax(u1, u2))],
  ['smart.imax.nonzero', levelToString(mkIMax(u, v1))],
  [
    'instantiate.changed',
    levelToString(instantiateLevel(levelMaxRaw(u, v), [uName], [levelZero])),
  ],
  ['normalize.atomic', levelToString(normalizeLevel(levelSucc(u1)))],
  ['normalize.maxCanonical', levelToString(normalizeLevel(canonicalInput))],
  ['normalize.sameBase', levelToString(normalizeLevel(levelMaxRaw(u1, u2)))],
  ['normalize.explicit', levelToString(normalizeLevel(levelMaxRaw(one, u1)))],
  ['normalize.imaxOnePass', levelToString(normalizeLevel(imaxInput))],
  ['normalize.imaxTwice', levelToString(normalizeLevel(normalizeLevel(imaxInput)))],
  [
    'equivalent.maxCommutative',
    String(levelEquivalent(levelMaxRaw(u, v), levelMaxRaw(v, u))),
  ],
  ['equivalent.symbolKinds', String(levelEquivalent(u, mU))],
  ['le.zeroU', String(levelLe(levelZero, u))],
  ['le.uU1', String(levelLe(u, u1))],
  ['le.u1U', String(levelLe(u1, u))],
  ['le.maxU', String(levelLe(u, levelMaxRaw(u, v)))],
  ['le.maxGeqFallthrough', String(levelLe(mkIMax(u, v), levelMaxRaw(u, v)))],
  ['equivalent.incomplete', String(levelEquivalent(incompleteLeft, incompleteRight))],
  ['le.incomplete.forward', String(levelLe(incompleteLeft, incompleteRight))],
  ['le.incomplete.reverse', String(levelLe(incompleteRight, incompleteLeft))],
]);

for (const key of fixture.keys()) {
  if (!expectedParity.has(key)) {
    fail(`unclassified PSCKernel fixture output: ${key}`);
  }
}

for (const [key, expected] of expectedParity) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== expected) {
    fail(`${key}: TS=${JSON.stringify(expected)} PSCKernel=${JSON.stringify(actual)}`);
  }
}

if (fixture.size !== expectedParity.size) {
  fail(`unexpected fixture size ${fixture.size}; expected ${expectedParity.size}`);
}

console.log(`PSCKERNEL_LEVEL_DIFFERENTIAL: PASS (${expectedParity.size} parity cases, 0 deviations)`);
