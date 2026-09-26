import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { LocalContext } from '../dist/src/core/local-context.js';
import { app, bvar, constant, forallE, fvar, lam, sort } from '../dist/src/core/expr.js';
import { levelParam, mkMax, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_DEFEQ_BASIC_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/DefEqBasicFixture.lean'],
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

const name = (text) => nameFromDotted(text);
const A = constant(name('A'));
const a = constant(name('a'));

function axiom(declName, levelParams, type) {
  return { kind: 'axiom', name: name(declName), levelParams, type, isUnsafe: false };
}
function definition(declName, type, value) {
  return {
    kind: 'definition',
    name: name(declName),
    levelParams: [],
    type,
    value,
    hints: { kind: 'regular', height: 0 },
    safety: 'safe',
  };
}
function makeEnv() {
  const env = new Environment();
  env.add(axiom('A', [], sort(levelZero)));
  env.add(axiom('a', [], A));
  env.add(definition('alias', A, a));
  env.add(definition('id', forallE(name('x'), A, A), lam(name('x'), A, bvar(0))));
  return env;
}
function defeq(env, lctx, left, right) {
  try { return new TypeChecker(env, lctx).isDefEq(left, right) ? 'true' : 'false'; }
  catch { return 'false'; }
}

const expected = new Map();
expected.set('structural', defeq(makeEnv(), new LocalContext(), a, a));
expected.set('binder-presentation', defeq(
  makeEnv(), new LocalContext(),
  lam(name('x'), A, bvar(0), 'default'),
  lam(name('renamed'), A, bvar(0), 'implicit'),
));
const uName = name('u');
const u = levelParam(uName);
expected.set('sort-level', defeq(
  makeEnv(), new LocalContext(),
  sort(mkMax(u, u)), sort(u),
));
const polyEnv = makeEnv();
polyEnv.add(axiom('Poly', [uName], sort(u)));
expected.set('const-level', defeq(
  polyEnv, new LocalContext(),
  constant(name('Poly'), [mkMax(u, u)]),
  constant(name('Poly'), [u]),
));
expected.set('beta', defeq(
  makeEnv(), new LocalContext(),
  app(lam(name('x'), A, bvar(0)), a), a,
));
expected.set('zeta', defeq(
  makeEnv(), new LocalContext(),
  { kind: 'let', name: name('x'), type: A, value: a, body: bvar(0), nondep: false }, a,
));
expected.set('delta', defeq(makeEnv(), new LocalContext(), constant(name('alias')), a));
expected.set('delta-beta', defeq(
  makeEnv(), new LocalContext(),
  app(constant(name('id')), a), a,
));
const localCtx = new LocalContext();
localCtx.addLet('xId', name('x'), A, a);
expected.set('local-let', defeq(makeEnv(), localCtx, fvar('xId'), a));
expected.set('different-constants', defeq(makeEnv(), new LocalContext(), A, a));
const fn = constant(name('f'));
expected.set('different-app-args', defeq(
  makeEnv(), new LocalContext(), app(fn, A), app(fn, a),
));
expected.set('pi-recursive', defeq(
  makeEnv(), new LocalContext(),
  forallE(name('x'), sort(mkMax(u, u)), sort(u), 'default'),
  forallE(name('y'), sort(u), sort(mkMax(u, u)), 'implicit'),
));

for (const key of fixture.keys()) {
  if (!expected.has(key)) fail(`unclassified PSCKernel fixture output: ${key}`);
}
for (const [key, value] of expected) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== value) fail(`${key}: TS=${JSON.stringify(value)} PSCKernel=${JSON.stringify(actual)}`);
}
if (fixture.size !== expected.size) fail(`unexpected fixture size ${fixture.size}; expected ${expected.size}`);

console.log(`PSCKERNEL_DEFEQ_BASIC_DIFFERENTIAL: PASS (${expected.size} overlap parity cases, 0 deviations)`);
