import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { app, bvar, constant, forallE, mkAppN, sort } from '../dist/src/core/expr.js';
import { levelParam, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted, nameToString } from '../dist/src/core/name.js';
import { addQuot } from '../dist/src/kernel/quotient.js';
import { N } from '../dist/src/kernel/names.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_QUOTIENT_ADMISSION_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/QuotientAdmissionFixture.lean'],
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
const anon = n('_');
const arrow = (a, b) => forallE(anon, a, b);
const boolText = (value) => value ? 'true' : 'false';

function expectedEqType(uName) {
  const u = levelParam(uName);
  return forallE(
    n('α'), sort(u),
    arrow(bvar(0), arrow(bvar(1), sort(levelZero))),
    'implicit',
  );
}

function expectedReflType(uName) {
  const u = levelParam(uName);
  return forallE(
    n('α'), sort(u),
    forallE(
      n('a'), bvar(0),
      mkAppN(constant(N.Eq, [u]), [bvar(1), bvar(0), bvar(0)]),
    ),
    'implicit',
  );
}

function seedEq({
  eqTypeOverride,
  reflTypeOverride,
  extraCtor = false,
  eqAsAxiom = false,
  uParams = [n('u')],
} = {}) {
  const env = new Environment();
  const uName = uParams[0] ?? n('u');
  const reflName = n('Eq.refl');
  const extraName = n('Eq.extra');
  const eqType = eqTypeOverride ?? expectedEqType(uName);
  const reflType = reflTypeOverride ?? expectedReflType(uName);
  if (eqAsAxiom) {
    env.add({ kind: 'axiom', name: N.Eq, levelParams: uParams, type: eqType, isUnsafe: false });
  } else {
    env.add({
      kind: 'inductive', name: N.Eq, levelParams: uParams, type: eqType,
      numParams: 2, numIndices: 1, all: [N.Eq],
      ctors: extraCtor ? [reflName, extraName] : [reflName],
      numNested: 0, isRec: false, isReflexive: false, isUnsafe: false,
    });
  }
  env.add({
    kind: 'constructor', name: reflName, levelParams: [uName], type: reflType,
    induct: N.Eq, cidx: 0, numParams: 2, numFields: 0, isUnsafe: false,
  });
  if (extraCtor) {
    env.add({
      kind: 'constructor', name: extraName, levelParams: [uName], type: reflType,
      induct: N.Eq, cidx: 1, numParams: 2, numFields: 0, isUnsafe: false,
    });
  }
  return env;
}

function accepted(env) {
  try {
    addQuot(env);
    return true;
  } catch {
    return false;
  }
}

function levelKey(level) {
  switch (level.kind) {
    case 'zero': return '0';
    case 'succ': return `s(${levelKey(level.of)})`;
    case 'max': return `m(${levelKey(level.left)},${levelKey(level.right)})`;
    case 'imax': return `i(${levelKey(level.left)},${levelKey(level.right)})`;
    case 'param': return `p{${nameToString(level.name)}}`;
    case 'mvar': return `v{${nameToString(level.name)}}`;
  }
}

function binderKey(info) {
  switch (info) {
    case 'default': return 'd';
    case 'implicit': return 'i';
    case 'strictImplicit': return 's';
    case 'instImplicit': return 'n';
  }
}

function exprKey(expr) {
  switch (expr.kind) {
    case 'bvar': return `b${expr.index}`;
    case 'fvar': return `f{${expr.id}}`;
    case 'mvar': return `v{${expr.id}}`;
    case 'sort': return `S{${levelKey(expr.level)}}`;
    case 'const': return `C{${nameToString(expr.name)}}[${expr.levels.map(levelKey).join(',')}]`;
    case 'app': return `A(${exprKey(expr.fn)},${exprKey(expr.arg)})`;
    case 'lam': return `L{${nameToString(expr.name)};${binderKey(expr.binderInfo)}}(${exprKey(expr.type)},${exprKey(expr.body)})`;
    case 'forall': return `P{${nameToString(expr.name)};${binderKey(expr.binderInfo)}}(${exprKey(expr.type)},${exprKey(expr.body)})`;
    case 'let': return `T{${nameToString(expr.name)};${expr.nondep ? '1' : '0'}}(${exprKey(expr.type)},${exprKey(expr.value)},${exprKey(expr.body)})`;
    case 'lit': return expr.literal.kind === 'nat' ? `N${expr.literal.value}` : `Q${expr.literal.value}`;
    case 'mdata': return `M(${exprKey(expr.expr)})`;
    case 'proj': return `R{${nameToString(expr.typeName)};${expr.index}}(${exprKey(expr.expr)})`;
  }
}

function quotInfoKey(env, name) {
  const info = env.find(name);
  if (!info || info.kind !== 'quot') return 'none';
  return [
    info.quotKind,
    info.levelParams.map(nameToString).join(','),
    exprKey(info.type),
  ].join('|');
}

const expected = new Map();

{
  const env = seedEq();
  expected.set('valid-init', boolText(accepted(env) && env.quotInitialized && env.size === 6));
  expected.set('quot-info', quotInfoKey(env, N.Quot));
  expected.set('quot-mk-info', quotInfoKey(env, N.QuotMk));
  expected.set('quot-lift-info', quotInfoKey(env, N.QuotLift));
  expected.set('quot-ind-info', quotInfoKey(env, N.QuotInd));
}

{
  const env = seedEq();
  addQuot(env);
  const size = env.size;
  let ok = true;
  try { addQuot(env); } catch { ok = false; }
  expected.set('idempotent', boolText(ok && env.size === size && env.quotInitialized));
}

expected.set('missing-eq', boolText(!accepted(new Environment())));
expected.set('eq-wrong-kind', boolText(!accepted(seedEq({ eqAsAxiom: true }))));
expected.set('eq-wrong-universe-arity', boolText(!accepted(seedEq({ uParams: [n('u'), n('v')] }))));
expected.set('eq-wrong-ctor-count', boolText(!accepted(seedEq({ extraCtor: true }))));
expected.set('eq-wrong-type', boolText(!accepted(seedEq({ eqTypeOverride: sort(levelZero) }))));
expected.set('refl-wrong-type', boolText(!accepted(seedEq({ reflTypeOverride: sort(levelZero) }))));

for (const [key, reserved] of [
  ['conflict-quot', N.Quot],
  ['conflict-quot-mk', N.QuotMk],
  ['conflict-quot-lift', N.QuotLift],
  ['conflict-quot-ind', N.QuotInd],
]) {
  const env = seedEq();
  env.add({ kind: 'axiom', name: reserved, levelParams: [], type: sort(levelZero), isUnsafe: false });
  expected.set(key, boolText(!accepted(env)));
}

{
  const env = seedEq({ eqTypeOverride: sort(levelZero) });
  const before = env.size;
  const rejected = !accepted(env);
  expected.set('failure-persistent', boolText(rejected && env.size === before && !env.quotInitialized));
}

for (const key of fixture.keys()) {
  if (!expected.has(key)) fail(`unclassified PSCKernel fixture output: ${key}`);
}
for (const [key, value] of expected) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== value) fail(`${key}: TS=${JSON.stringify(value)} PSCKernel=${JSON.stringify(actual)}`);
}
if (fixture.size !== expected.size) fail(`unexpected fixture size ${fixture.size}; expected ${expected.size}`);

console.log(`PSCKERNEL_QUOTIENT_ADMISSION_DIFFERENTIAL: PASS (${expected.size} parity observations, 0 deviations)`);
