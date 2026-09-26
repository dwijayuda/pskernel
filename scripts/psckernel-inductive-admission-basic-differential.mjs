import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { app, bvar, constant, forallE, fvar, sort } from '../dist/src/core/expr.js';
import { levelSucc, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted, strName } from '../dist/src/core/name.js';
import { addOrdinaryInductive } from '../dist/src/kernel/inductive/ordinary.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_INDUCTIVE_ADMISSION_BASIC_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/InductiveAdmissionBasicFixture.lean'],
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
const type0 = sort(levelSucc(levelZero));
const boolText = (value) => value ? 'true' : 'false';

function enumDecl() {
  const color = n('Basic.Color');
  return {
    levelParams: [], numParams: 0, isUnsafe: false, numNested: 0,
    types: [{
      name: color, type: type0,
      ctors: [
        { name: n('Basic.Color.red'), type: constant(color) },
        { name: n('Basic.Color.blue'), type: constant(color) },
      ],
    }],
  };
}

function boxDecl() {
  const box = n('Basic.Box');
  const alpha = n('α');
  const value = n('value');
  return {
    levelParams: [], numParams: 1, isUnsafe: false, numNested: 0,
    types: [{
      name: box,
      type: forallE(alpha, type0, type0),
      ctors: [{
        name: n('Basic.Box.mk'),
        type: forallE(
          alpha, type0,
          forallE(value, bvar(0), app(constant(box), bvar(1))),
        ),
      }],
    }],
  };
}

function accepted(decl, seed = () => new Environment()) {
  const env = seed();
  try {
    addOrdinaryInductive(env, decl);
    return { ok: true, env };
  } catch {
    return { ok: false, env };
  }
}

function validationSummary(result, typeName, ctorNames) {
  if (!result.ok) return 'false';
  const typeInfo = result.env.find(typeName);
  if (!typeInfo || typeInfo.kind !== 'inductive') return 'false';
  const fields = [];
  for (const ctorName of ctorNames) {
    const info = result.env.find(ctorName);
    if (!info || info.kind !== 'constructor') return 'false';
    fields.push(info.numFields);
  }
  return `true|${typeInfo.numIndices}|${fields.join(',')}`;
}

const expected = new Map();
expected.set(
  'enum',
  validationSummary(
    accepted(enumDecl()),
    n('Basic.Color'),
    [n('Basic.Color.red'), n('Basic.Color.blue')],
  ),
);
expected.set(
  'box',
  validationSummary(
    accepted(boxDecl()),
    n('Basic.Box'),
    [n('Basic.Box.mk')],
  ),
);

expected.set('empty-block', boolText(!accepted({
  levelParams: [], numParams: 0, types: [], isUnsafe: false, numNested: 0,
}).ok));

{
  const u = n('u');
  expected.set('duplicate-universe', boolText(!accepted({ ...enumDecl(), levelParams: [u, u] }).ok));
}

expected.set('type-name-conflict', boolText(!accepted(enumDecl(), () => {
  const env = new Environment();
  env.add({ kind: 'axiom', name: n('Basic.Color'), levelParams: [], type: type0, isUnsafe: false });
  return env;
}).ok));

expected.set('recursor-name-conflict', boolText(!accepted(enumDecl(), () => {
  const env = new Environment();
  env.add({ kind: 'axiom', name: strName(n('Basic.Color'), 'rec'), levelParams: [], type: type0, isUnsafe: false });
  return env;
}).ok));

expected.set('num-params-mismatch', boolText(!accepted({ ...boxDecl(), numParams: 2 }).ok));

{
  const color = n('Basic.DuplicateCtor');
  const mk = n('Basic.DuplicateCtor.mk');
  expected.set('duplicate-ctor', boolText(!accepted({
    levelParams: [], numParams: 0, isUnsafe: false, numNested: 0,
    types: [{
      name: color, type: type0,
      ctors: [{ name: mk, type: constant(color) }, { name: mk, type: constant(color) }],
    }],
  }).ok));
}

{
  const color = n('Basic.BadResult');
  expected.set('wrong-result', boolText(!accepted({
    levelParams: [], numParams: 0, isUnsafe: false, numNested: 0,
    types: [{
      name: color, type: type0,
      ctors: [{ name: n('Basic.BadResult.mk'), type: type0 }],
    }],
  }).ok));
}

{
  const color = n('Basic.FreeHeader');
  expected.set('free-header', boolText(!accepted({
    levelParams: [], numParams: 0, isUnsafe: false, numNested: 0,
    types: [{ name: color, type: fvar('x'), ctors: [] }],
  }).ok));
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

console.log(`PSCKERNEL_INDUCTIVE_ADMISSION_BASIC_DIFFERENTIAL: PASS (${expected.size} overlap parity observations, 0 deviations)`);
