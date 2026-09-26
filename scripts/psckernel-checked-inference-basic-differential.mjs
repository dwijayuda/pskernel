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
  console.error(`PSCKERNEL_CHECKED_INFERENCE_BASIC_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/CheckedInferenceBasicFixture.lean'],
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

function checkKey(env, expr) {
  try {
    return exprKey(new TypeChecker(env, new LocalContext()).check(expr));
  } catch {
    return 'none';
  }
}

function axiom(declName, type) {
  return { kind: 'axiom', name: name(declName), levelParams: [], type, isUnsafe: false };
}

function definition(declName, type, value) {
  return {
    kind: 'definition',
    name: name(declName),
    levelParams: [],
    type,
    value,
    hints: { kind: 'regular', height: 0n },
    safety: 'safe',
  };
}

function letE(bindName, type, value, body, nondep = false) {
  return { kind: 'let', name: name(bindName), type, value, body, nondep };
}

function makeEnv() {
  const env = new Environment();
  const sort0 = sort(levelZero);
  const A = constant(name('A'));
  const B = constant(name('B'));
  const AliasType = constant(name('AliasType'));
  env.add(axiom('A', sort0));
  env.add(axiom('a', A));
  env.add(axiom('B', sort0));
  env.add(axiom('b', B));
  env.add(definition('AliasType', sort0, A));
  env.add(axiom('aa', AliasType));
  env.add(axiom('f', forallE(name('x'), A, A)));
  return env;
}

const A = constant(name('A'));
const sort0 = sort(levelZero);
const expected = new Map();

expected.set('sort', checkKey(makeEnv(), sort0));
expected.set('const', checkKey(makeEnv(), constant(name('a'))));
expected.set('valid-app', checkKey(makeEnv(), app(constant(name('f')), constant(name('a')))));
expected.set('defeq-app', checkKey(makeEnv(), app(constant(name('f')), constant(name('aa')))));
expected.set('bad-app', checkKey(makeEnv(), app(constant(name('f')), constant(name('b')))));
expected.set('valid-lambda', checkKey(makeEnv(), lam(name('x'), A, bvar(0))));
expected.set('bad-lambda-domain', checkKey(makeEnv(), lam(name('x'), constant(name('a')), bvar(0))));
expected.set('valid-pi', checkKey(makeEnv(), forallE(name('p'), sort0, sort0)));
expected.set('bad-pi-domain', checkKey(makeEnv(), forallE(name('x'), constant(name('a')), A)));
expected.set('valid-let', checkKey(makeEnv(), letE('x', A, constant(name('a')), bvar(0))));
expected.set('bad-let-type', checkKey(makeEnv(), letE('x', constant(name('a')), constant(name('a')), bvar(0))));
expected.set('bad-let-value', checkKey(makeEnv(), letE('x', A, constant(name('b')), bvar(0))));
expected.set('defeq-let-value', checkKey(makeEnv(), letE('x', A, constant(name('aa')), bvar(0))));
expected.set('unknown-const', checkKey(makeEnv(), constant(name('missing'))));

for (const key of fixture.keys()) {
  if (!expected.has(key)) fail(`unclassified PSCKernel fixture output: ${key}`);
}
for (const [key, value] of expected) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== value) fail(`${key}: TS=${JSON.stringify(value)} PSCKernel=${JSON.stringify(actual)}`);
}
if (fixture.size !== expected.size) fail(`unexpected fixture size ${fixture.size}; expected ${expected.size}`);

console.log(`PSCKERNEL_CHECKED_INFERENCE_BASIC_DIFFERENTIAL: PASS (${expected.size} checked parity cases, 0 deviations)`);
