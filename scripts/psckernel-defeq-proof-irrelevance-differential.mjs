import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { LocalContext } from '../dist/src/core/local-context.js';
import { constant, sort } from '../dist/src/core/expr.js';
import { levelSucc, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_DEFEQ_PROOF_IRRELEVANCE_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/DefEqProofIrrelevanceFixture.lean'],
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

const N = (text) => nameFromDotted(text);
const C = (text) => constant(N(text));

function axiom(name, type) {
  return { kind: 'axiom', name: N(name), levelParams: [], type, isUnsafe: false };
}

function definition(name, type, value) {
  return {
    kind: 'definition', name: N(name), levelParams: [], type, value,
    hints: { kind: 'regular', height: 0n }, safety: 'safe',
  };
}

function makeEnv() {
  const env = new Environment();
  const propSort = sort(levelZero);
  const typeSort = sort(levelSucc(levelZero));
  env.add(axiom('P', propSort));
  env.add(axiom('p', C('P')));
  env.add(axiom('q', C('P')));
  env.add(axiom('Q', propSort));
  env.add(axiom('r', C('Q')));
  env.add(definition('AliasP', propSort, C('P')));
  env.add(axiom('aliasProof', C('AliasP')));
  env.add(axiom('A', typeSort));
  env.add(axiom('a', C('A')));
  env.add(axiom('b', C('A')));
  return env;
}

function defEqKey(left, right) {
  try {
    return new TypeChecker(makeEnv(), new LocalContext()).isDefEq(left, right) ? '1' : '0';
  } catch {
    return 'error';
  }
}

const expected = new Map([
  ['same-prop', defEqKey(C('p'), C('q'))],
  ['same-prop-symmetric', defEqKey(C('q'), C('p'))],
  ['defeq-prop-types', defEqKey(C('p'), C('aliasProof'))],
  ['different-props', defEqKey(C('p'), C('r'))],
  ['data', defEqKey(C('a'), C('b'))],
  ['prop-expressions', defEqKey(C('P'), C('Q'))],
  ['reflexive-data', defEqKey(C('a'), C('a'))],
  ['delta', defEqKey(C('AliasP'), C('P'))],
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

console.log(`PSCKERNEL_DEFEQ_PROOF_IRRELEVANCE_DIFFERENTIAL: PASS (${expected.size} parity cases, 0 deviations)`);
