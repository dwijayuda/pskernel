import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { constant } from '../dist/src/core/expr.js';
import { nameFromDotted, nameToString } from '../dist/src/core/name.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_ENVIRONMENT_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/EnvironmentFixture.lean'],
  {
    cwd: selfhost,
    encoding: 'utf8',
  },
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

const name = (text) => nameFromDotted(text);
const axiom = (text) => ({
  kind: 'axiom',
  name: name(text),
  levelParams: [],
  type: constant(name('Type')),
  isUnsafe: false,
});

const empty = new Environment();
const expected = new Map();
expected.set('empty.size', String(empty.size));
expected.set('empty.hasA', String(empty.has(name('A'))));
expected.set('quot.initial', String(empty.quotInitialized));

const envA = empty.clone();
envA.add(axiom('A'));
expected.set('add.size', String(envA.size));
expected.set('add.hasA', String(envA.has(name('A'))));
expected.set('add.findA', nameToString(envA.find(name('A')).name));
expected.set('persistent.baseSize', String(empty.size));

let duplicateRejected = false;
try {
  envA.add(axiom('A'));
} catch {
  duplicateRejected = true;
}
expected.set('duplicate.rejected', String(duplicateRejected));

const envB = envA.clone();
envB.add(axiom('B'));
expected.set('two.size', String(envB.size));
expected.set('two.hasB', String(envB.has(name('B'))));

const marked = envA.clone();
marked.quotInitialized = true;
expected.set('quot.marked', String(marked.quotInitialized));
expected.set('quot.preserveSize', String(marked.size));

const exact = empty.clone();
exact.add(axiom('A.B'));
expected.set('exact.hasAB', String(exact.has(name('A.B'))));
expected.set('exact.hasB', String(exact.has(name('B'))));

for (const key of fixture.keys()) {
  if (!expected.has(key)) fail(`unclassified PSCKernel fixture output: ${key}`);
}
for (const [key, value] of expected) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== value) {
    fail(`${key}: TS=${JSON.stringify(value)} PSCKernel=${JSON.stringify(actual)}`);
  }
}
if (fixture.size !== expected.size) {
  fail(`unexpected fixture size ${fixture.size}; expected ${expected.size}`);
}

console.log(
  `PSCKERNEL_ENVIRONMENT_DIFFERENTIAL: PASS (${expected.size} overlap parity cases, 0 deviations)`,
);
