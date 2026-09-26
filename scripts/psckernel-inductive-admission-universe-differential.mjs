import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { constant, forallE, sort } from '../dist/src/core/expr.js';
import { levelSucc, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { addOrdinaryInductive } from '../dist/src/kernel/inductive/ordinary.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_INDUCTIVE_ADMISSION_UNIVERSE_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/InductiveAdmissionUniverseFixture.lean'],
  { cwd: selfhost, encoding: 'utf8' },
);
if (fixtureRun.error) fail(`could not run Lean fixture: ${fixtureRun.error.message}`);
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

const n = (text) => nameFromDotted(text);
const boolText = (value) => value ? 'true' : 'false';

function unaryDecl(typeNameText, resultLevel, fieldDomainLevel) {
  const typeName = n(typeNameText);
  const ctorName = n(`${typeNameText}.mk`);
  return {
    levelParams: [],
    numParams: 0,
    isUnsafe: false,
    numNested: 0,
    types: [{
      name: typeName,
      type: sort(resultLevel),
      ctors: [{
        name: ctorName,
        type: forallE(n('α'), sort(fieldDomainLevel), constant(typeName)),
      }],
    }],
  };
}

function accepted(decl) {
  const env = new Environment();
  try {
    addOrdinaryInductive(env, decl);
    return true;
  } catch {
    return false;
  }
}

const one = levelSucc(levelZero);
const two = levelSucc(one);

const expected = new Map([
  ['too-large-field', boolText(accepted(unaryDecl('Universe.Small', one, one)))],
  ['bounded-field', boolText(accepted(unaryDecl('Universe.Wide', two, one)))],
  ['prop-field-exemption', boolText(accepted(unaryDecl('Universe.PropLike', levelZero, two)))],
]);

for (const key of fixture.keys()) {
  if (!expected.has(key)) fail(`unclassified PSCKernel fixture output: ${key}`);
}
for (const [key, value] of expected) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== value) fail(`${key}: TS=${JSON.stringify(value)} PSCKernel=${JSON.stringify(actual)}`);
}
if (fixture.size !== expected.size) fail(`unexpected fixture size ${fixture.size}; expected ${expected.size}`);

console.log(`PSCKERNEL_INDUCTIVE_ADMISSION_UNIVERSE_DIFFERENTIAL: PASS (${expected.size} parity observations, 0 deviations)`);
