import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { LocalContext } from '../dist/src/core/local-context.js';
import {
  app,
  bvar,
  constant,
  fvar,
  lam,
  sort,
} from '../dist/src/core/expr.js';
import { levelParam, levelToString, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted, nameToString } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_REDUCTION_BASIC_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/ReductionBasicFixture.lean'],
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

const valueA = constant(name('A'));
const valueB = constant(name('B'));
const typeT = constant(name('T'));
const emptyEnv = new Environment();
const emptyCtx = new LocalContext();
const whnf = (env, lctx, expr) => new TypeChecker(env, lctx).whnf(expr);

const expected = new Map();
expected.set('easy-const', exprKey(whnf(emptyEnv, emptyCtx, valueA)));

const letExpr = {
  kind: 'let',
  name: name('x'),
  type: typeT,
  value: valueA,
  body: bvar(0),
  nondep: false,
};
expected.set('let-zeta', exprKey(whnf(emptyEnv, emptyCtx, letExpr)));

const identity = lam(name('x'), typeT, bvar(0));
expected.set('beta', exprKey(whnf(emptyEnv, emptyCtx, app(identity, valueA))));

const chooseFirst = lam(name('x'), typeT, lam(name('y'), typeT, bvar(1)));
expected.set(
  'nested-beta',
  exprKey(whnf(emptyEnv, emptyCtx, app(app(chooseFirst, valueA), valueB))),
);

const letCtx = new LocalContext();
letCtx.addLet('xId', name('x'), typeT, valueA);
expected.set('local-let', exprKey(whnf(emptyEnv, letCtx, fvar('xId'))));

function definition(declName, levelParams, value) {
  return {
    kind: 'definition',
    name: name(declName),
    levelParams,
    type: constant(name('Type')),
    value,
    hints: { kind: 'regular', height: 1n },
    safety: 'safe',
  };
}

const deltaEnv = new Environment();
deltaEnv.add(definition('d', [], valueA));
expected.set('delta', exprKey(whnf(deltaEnv, emptyCtx, constant(name('d')))));

const identityEnv = new Environment();
identityEnv.add(definition('id', [], identity));
expected.set(
  'delta-beta',
  exprKey(whnf(identityEnv, emptyCtx, app(constant(name('id')), valueA))),
);

const theoremEnv = new Environment();
theoremEnv.add({
  kind: 'theorem',
  name: name('thm'),
  levelParams: [],
  type: constant(name('Prop')),
  value: constant(name('proof')),
});
expected.set('theorem-stuck', exprKey(whnf(theoremEnv, emptyCtx, constant(name('thm')))));

const u = name('u');
const polyEnv = new Environment();
polyEnv.add(definition('poly', [u], sort(levelParam(u))));
expected.set(
  'universe-delta',
  exprKey(whnf(polyEnv, emptyCtx, constant(name('poly'), [levelZero]))),
);
expected.set(
  'bad-universe-arity',
  exprKey(whnf(polyEnv, emptyCtx, constant(name('poly')))),
);

const reducibleHead = {
  kind: 'let',
  name: name('f'),
  type: constant(name('Fn')),
  value: identity,
  body: bvar(0),
  nondep: false,
};
expected.set(
  'let-head-beta',
  exprKey(whnf(emptyEnv, emptyCtx, app(reducibleHead, valueA))),
);

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
  `PSCKERNEL_REDUCTION_BASIC_DIFFERENTIAL: PASS (${expected.size} overlap parity cases, 0 deviations)`,
);
