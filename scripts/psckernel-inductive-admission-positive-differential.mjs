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
  console.error(`PSCKERNEL_INDUCTIVE_ADMISSION_POSITIVE_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/InductiveAdmissionPositiveFixture.lean'],
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

function directDecl() {
  const target = n('Positive.NatLike');
  return {
    levelParams: [], numParams: 0, isUnsafe: false, numNested: 0,
    types: [{
      name: target, type: type0,
      ctors: [
        { name: n('Positive.NatLike.zero'), type: constant(target) },
        {
          name: n('Positive.NatLike.succ'),
          type: forallE(n('n'), constant(target), constant(target)),
        },
      ],
    }],
  };
}

function higherDecl() {
  const target = n('Positive.Higher');
  const callbackType = forallE(n('p'), sort(levelZero), constant(target));
  return {
    levelParams: [], numParams: 0, isUnsafe: false, numNested: 0,
    types: [{
      name: target, type: type0,
      ctors: [{
        name: n('Positive.Higher.mk'),
        type: forallE(n('f'), callbackType, constant(target)),
      }],
    }],
  };
}

function negativeDecl() {
  const target = n('Positive.Negative');
  const badFieldType = forallE(n('x'), constant(target), sort(levelZero));
  return {
    levelParams: [], numParams: 0, isUnsafe: false, numNested: 0,
    types: [{
      name: target, type: type0,
      ctors: [{
        name: n('Positive.Negative.mk'),
        type: forallE(n('f'), badFieldType, constant(target)),
      }],
    }],
  };
}

function nonrecursiveDecl() {
  const target = n('Positive.Color');
  return {
    levelParams: [], numParams: 0, isUnsafe: false, numNested: 0,
    types: [{
      name: target, type: type0,
      ctors: [
        { name: n('Positive.Color.red'), type: constant(target) },
        { name: n('Positive.Color.blue'), type: constant(target) },
      ],
    }],
  };
}

function universeViolationDecl() {
  const target = n('Positive.UniverseViolation');
  return {
    levelParams: [], numParams: 0, isUnsafe: false, numNested: 0,
    types: [{
      name: target, type: type0,
      ctors: [{
        name: n('Positive.UniverseViolation.mk'),
        type: forallE(n('α'), sort(levelSucc(levelZero)), constant(target)),
      }],
    }],
  };
}

function validate(decl) {
  const env = new Environment();
  try {
    addOrdinaryInductive(env, decl);
    const typeDecl = decl.types[0];
    if (!typeDecl) return { ok: false };
    const info = env.find(typeDecl.name);
    if (!info || info.kind !== 'inductive') return { ok: false };
    const fields = [];
    for (const ctor of typeDecl.ctors) {
      const ctorInfo = env.find(ctor.name);
      if (!ctorInfo || ctorInfo.kind !== 'constructor') return { ok: false };
      fields.push(ctorInfo.numFields);
    }
    return {
      ok: true,
      isRec: info.isRec,
      isReflexive: info.isReflexive,
      fields,
    };
  } catch {
    return { ok: false };
  }
}

function summary(result) {
  if (!result.ok) return 'false';
  return `true|${result.isRec ? '1' : '0'}|${result.isReflexive ? '1' : '0'}|${result.fields.join(',')}`;
}

const expected = new Map([
  ['direct', summary(validate(directDecl()))],
  ['higher-order', summary(validate(higherDecl()))],
  ['negative', boolText(!validate(negativeDecl()).ok)],
  ['nonrecursive', summary(validate(nonrecursiveDecl()))],
  ['universe-violation', boolText(!validate(universeViolationDecl()).ok)],
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

console.log(`PSCKERNEL_INDUCTIVE_ADMISSION_POSITIVE_DIFFERENTIAL: PASS (${expected.size} overlap parity observations, 0 deviations)`);
