import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { LocalContext } from '../dist/src/core/local-context.js';
import {
  app,
  bvar,
  constant,
  forallE,
  fvar,
  natLit,
  sort,
  strLit,
} from '../dist/src/core/expr.js';
import { levelParam, levelSucc, levelToString, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted, nameToString } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_TYPE_INFERENCE_BASIC_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/TypeInferenceBasicFixture.lean'],
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

function levelListKey(levels) {
  return levels.map(levelToString).join(',');
}

function exprKey(expr) {
  switch (expr.kind) {
    case 'bvar': return `b${expr.index}`;
    case 'fvar': return `f{${expr.id}}`;
    case 'mvar': return `v{${expr.id}}`;
    case 'sort': return `S{${levelToString(expr.level)}}`;
    case 'const': return `C{${nameToString(expr.name)}}[${levelListKey(expr.levels)}]`;
    case 'app': return `A(${exprKey(expr.fn)},${exprKey(expr.arg)})`;
    case 'lam': return `L{${nameToString(expr.name)}}(${exprKey(expr.type)},${exprKey(expr.body)})`;
    case 'forall': return `P{${nameToString(expr.name)}}(${exprKey(expr.type)},${exprKey(expr.body)})`;
    case 'let': return `T{${nameToString(expr.name)},${expr.nondep === true ? '1' : '0'}}(${exprKey(expr.type)},${exprKey(expr.value)},${exprKey(expr.body)})`;
    case 'lit': return expr.literal.kind === 'nat' ? `N${expr.literal.value}` : `Q${expr.literal.value}`;
    case 'mdata': return exprKey(expr.expr);
    case 'proj': return `R{${nameToString(expr.typeName)},${expr.index}}(${exprKey(expr.expr)})`;
  }
}

function inferKey(env, lctx, expr) {
  try {
    return exprKey(new TypeChecker(env, lctx).infer(expr, true));
  } catch {
    return 'none';
  }
}

function axiom(declName, levelParams, type) {
  return {
    kind: 'axiom',
    name: name(declName),
    levelParams,
    type,
    isUnsafe: false,
  };
}

function baseEnv() {
  const env = new Environment();
  const sort0 = sort(levelZero);
  env.add(axiom('A', [], sort0));
  env.add(axiom('a', [], constant(name('A'))));
  env.add(axiom('B', [], sort0));
  env.add(axiom('b', [], constant(name('B'))));
  return env;
}

const expected = new Map();
const emptyCtx = new LocalContext();
const aType = constant(name('A'));
const bType = constant(name('B'));

expected.set('sort', inferKey(baseEnv(), emptyCtx, sort(levelZero)));

const xCtx = new LocalContext();
xCtx.addLocal('xId', name('x'), aType, 'default');
expected.set('known-fvar', inferKey(baseEnv(), xCtx, fvar('xId')));
expected.set('unknown-fvar', inferKey(baseEnv(), emptyCtx, fvar('missing')));
expected.set('known-const', inferKey(baseEnv(), emptyCtx, constant(name('a'))));

const u = name('u');
const polyEnv = baseEnv();
polyEnv.add(axiom('Poly', [u], sort(levelParam(u))));
expected.set('universe-const', inferKey(polyEnv, emptyCtx, constant(name('Poly'), [levelZero])));
expected.set('bad-universe-arity', inferKey(polyEnv, emptyCtx, constant(name('Poly'))));

const dependentEnv = baseEnv();
dependentEnv.add(axiom('f', [], forallE(name('x'), aType, bvar(0))));
expected.set('app', inferKey(dependentEnv, emptyCtx, app(constant(name('f')), constant(name('a')))));

const constantEnv = baseEnv();
const constantFType = forallE(name('x'), aType, bType);
constantEnv.add(axiom('f', [], constantFType));
expected.set('unchecked-arg', inferKey(constantEnv, emptyCtx, app(constant(name('f')), constant(name('missingArgument')))));

const wrappedEnv = baseEnv();
const wrappedType = {
  kind: 'let',
  name: name('T'),
  type: sort(levelZero),
  value: constantFType,
  body: bvar(0),
  nondep: false,
};
wrappedEnv.add(axiom('wrapped', [], wrappedType));
expected.set('app-whnf-type', inferKey(wrappedEnv, emptyCtx, app(constant(name('wrapped')), constant(name('a')))));

expected.set('let', inferKey(baseEnv(), emptyCtx, {
  kind: 'let', name: name('x'), type: aType, value: constant(name('a')), body: bvar(0), nondep: false,
}));
const innerLet = {
  kind: 'let', name: name('y'), type: aType, value: bvar(0), body: bvar(0), nondep: false,
};
expected.set('nested-let', inferKey(baseEnv(), emptyCtx, {
  kind: 'let', name: name('x'), type: aType, value: constant(name('a')), body: innerLet, nondep: false,
}));
expected.set('nat-lit', inferKey(baseEnv(), emptyCtx, natLit(7)));
expected.set('string-lit', inferKey(baseEnv(), emptyCtx, strLit('psc1')));
expected.set('loose-bvar', inferKey(baseEnv(), emptyCtx, bvar(0)));
expected.set('mvar', inferKey(baseEnv(), emptyCtx, { kind: 'mvar', id: 'm' }));
expected.set('non-function-app', inferKey(baseEnv(), emptyCtx, app(constant(name('a')), constant(name('a')))));

for (const key of fixture.keys()) {
  if (!expected.has(key)) fail(`unclassified PSCKernel fixture output: ${key}`);
}
for (const [key, value] of expected) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== value) fail(`${key}: TS=${JSON.stringify(value)} PSCKernel=${JSON.stringify(actual)}`);
}
if (fixture.size !== expected.size) fail(`unexpected fixture size ${fixture.size}; expected ${expected.size}`);

console.log(
  `PSCKERNEL_TYPE_INFERENCE_BASIC_DIFFERENTIAL: PASS (${expected.size} overlap parity cases, 0 deviations)`,
);
