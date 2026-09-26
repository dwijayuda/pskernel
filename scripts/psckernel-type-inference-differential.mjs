import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { LocalContext } from '../dist/src/core/local-context.js';
import { app, bvar, constant, forallE, lam, sort } from '../dist/src/core/expr.js';
import { levelToString, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted, nameToString } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_TYPE_INFERENCE_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/TypeInferenceFixture.lean'],
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

function exprKey(expr) {
  switch (expr.kind) {
    case 'bvar': return `b${expr.index}`;
    case 'fvar': return `f{${expr.id}}`;
    case 'mvar': return `v{${expr.id}}`;
    case 'sort': return `S{${levelToString(expr.level)}}`;
    case 'const': return `C{${nameToString(expr.name)}}[${expr.levels.map(levelToString).join(',')}]`;
    case 'app': return `A(${exprKey(expr.fn)},${exprKey(expr.arg)})`;
    case 'lam': return `L{${nameToString(expr.name)}}(${exprKey(expr.type)},${exprKey(expr.body)})`;
    case 'forall': return `P{${nameToString(expr.name)}}(${exprKey(expr.type)},${exprKey(expr.body)})`;
    case 'let': return `T{${nameToString(expr.name)},${expr.nondep === true ? '1' : '0'}}(${exprKey(expr.type)},${exprKey(expr.value)},${exprKey(expr.body)})`;
    case 'lit': return expr.literal.kind === 'nat' ? `N${expr.literal.value}` : `Q${expr.literal.value}`;
    case 'mdata': return exprKey(expr.expr);
    case 'proj': return `R{${nameToString(expr.typeName)},${expr.index}}(${exprKey(expr.expr)})`;
  }
}

function inferKey(env, expr) {
  try {
    return exprKey(new TypeChecker(env, new LocalContext()).infer(expr, true));
  } catch {
    return 'none';
  }
}

function axiom(declName, type) {
  return { kind: 'axiom', name: name(declName), levelParams: [], type, isUnsafe: false };
}

function makeEnv() {
  const env = new Environment();
  const sort0 = sort(levelZero);
  const A = constant(name('A'));
  const B = constant(name('B'));
  env.add(axiom('A', sort0));
  env.add(axiom('a', A));
  env.add(axiom('B', sort0));
  env.add(axiom('b', B));
  env.add(axiom('P', forallE(name('x'), A, sort0)));
  env.add(axiom('g', forallE(name('x'), A, app(constant(name('P')), bvar(0)))));
  return env;
}

const A = constant(name('A'));
const B = constant(name('B'));
const sort0 = sort(levelZero);
const expected = new Map();

const identity = lam(name('x'), A, bvar(0));
expected.set('identity-lambda', inferKey(makeEnv(), identity));
expected.set('unchecked-lambda-domain', inferKey(makeEnv(), lam(name('x'), constant(name('a')), bvar(0))));
expected.set('nested-lambda', inferKey(makeEnv(), lam(name('x'), A, lam(name('y'), B, bvar(1)))));
expected.set('dependent-lambda', inferKey(makeEnv(), lam(name('x'), A, app(constant(name('g')), bvar(0)))));
expected.set('pi-prop', inferKey(makeEnv(), forallE(name('p'), sort0, bvar(0))));
expected.set('pi-type', inferKey(makeEnv(), forallE(name('p'), sort0, sort0)));
expected.set('pi-bad-domain', inferKey(makeEnv(), forallE(name('x'), constant(name('a')), A)));
expected.set('dependent-let', inferKey(makeEnv(), {
  kind: 'let', name: name('x'), type: A, value: constant(name('a')),
  body: app(constant(name('g')), bvar(0)), nondep: false,
}));
expected.set('nondependent-let', inferKey(makeEnv(), {
  kind: 'let', name: name('x'), type: A, value: constant(name('a')),
  body: constant(name('b')), nondep: false,
}));
expected.set('lambda-app', inferKey(makeEnv(), app(identity, constant(name('a')))));

for (const key of fixture.keys()) {
  if (!expected.has(key)) fail(`unclassified PSCKernel fixture output: ${key}`);
}
for (const [key, value] of expected) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== value) fail(`${key}: TS=${JSON.stringify(value)} PSCKernel=${JSON.stringify(actual)}`);
}
if (fixture.size !== expected.size) fail(`unexpected fixture size ${fixture.size}; expected ${expected.size}`);

console.log(`PSCKERNEL_TYPE_INFERENCE_DIFFERENTIAL: PASS (${expected.size} overlap parity cases, 0 deviations)`);
