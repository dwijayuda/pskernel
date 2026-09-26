import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { LocalContext } from '../dist/src/core/local-context.js';
import { app, bvar, constant, forallE, mkAppN, sort } from '../dist/src/core/expr.js';
import { levelSucc, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_DEFEQ_STRUCT_ETA_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/DefEqStructEtaFixture.lean'],
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
const proj = (typeName, index, expr) => ({ kind: 'proj', typeName, index, expr });
const axiom = (name, type) => ({ kind: 'axiom', name, levelParams: [], type, isUnsafe: false });

function makeEnv() {
  const env = new Environment();
  const sort1 = sort(levelSucc(levelZero));
  const A = constant(N('A'));
  const S = N('S');
  const SMk = N('S.mk');
  const Box = N('Box');
  const BoxMk = N('Box.mk');
  const R = N('R');
  const RMk = N('R.mk');
  const M = N('M');
  const MOne = N('M.one');
  const MTwo = N('M.two');

  env.add(axiom(N('A'), sort1));
  env.add(axiom(N('a'), A));
  env.add(axiom(N('b'), A));

  env.add({
    kind: 'inductive', name: S, levelParams: [], type: sort1,
    numParams: 0, numIndices: 0, all: [S, SMk], ctors: [SMk],
    numNested: 0, isRec: false, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: SMk, levelParams: [],
    type: forallE(N('fst'), A, forallE(N('snd'), A, constant(S))),
    induct: S, cidx: 0, numParams: 0, numFields: 2, isUnsafe: false,
  });
  env.add(axiom(N('s'), constant(S)));

  env.add({
    kind: 'inductive', name: Box, levelParams: [],
    type: forallE(N('A'), sort1, sort1),
    numParams: 1, numIndices: 0, all: [Box, BoxMk], ctors: [BoxMk],
    numNested: 0, isRec: false, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: BoxMk, levelParams: [],
    type: forallE(
      N('A'), sort1,
      forallE(N('value'), bvar(0), app(constant(Box), bvar(1))),
    ),
    induct: Box, cidx: 0, numParams: 1, numFields: 1, isUnsafe: false,
  });
  env.add(axiom(N('boxa'), app(constant(Box), A)));

  env.add({
    kind: 'inductive', name: R, levelParams: [], type: sort1,
    numParams: 0, numIndices: 0, all: [R, RMk], ctors: [RMk],
    numNested: 0, isRec: true, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: RMk, levelParams: [],
    type: forallE(N('field'), A, constant(R)),
    induct: R, cidx: 0, numParams: 0, numFields: 1, isUnsafe: false,
  });
  env.add(axiom(N('r'), constant(R)));

  env.add({
    kind: 'inductive', name: M, levelParams: [], type: sort1,
    numParams: 0, numIndices: 0, all: [M, MOne, MTwo], ctors: [MOne, MTwo],
    numNested: 0, isRec: false, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: MOne, levelParams: [],
    type: forallE(N('field'), A, constant(M)),
    induct: M, cidx: 0, numParams: 0, numFields: 1, isUnsafe: false,
  });
  env.add({
    kind: 'constructor', name: MTwo, levelParams: [],
    type: forallE(N('field'), A, constant(M)),
    induct: M, cidx: 1, numParams: 0, numFields: 1, isUnsafe: false,
  });
  env.add(axiom(N('m'), constant(M)));
  return env;
}

const expected = new Map();
{
  const env = makeEnv();
  const tc = new TypeChecker(env, new LocalContext());
  const S = N('S');
  const Box = N('Box');
  const R = N('R');
  const M = N('M');
  const s = constant(N('s'));
  const boxa = constant(N('boxa'));
  const r = constant(N('r'));
  const m = constant(N('m'));
  const sExpansion = mkAppN(constant(N('S.mk')), [proj(S, 0, s), proj(S, 1, s)]);
  const boxExpansion = mkAppN(constant(N('Box.mk')), [constant(N('A')), proj(Box, 0, boxa)]);
  const wrongField = mkAppN(constant(N('S.mk')), [proj(S, 0, s), constant(N('a'))]);
  const incomplete = app(constant(N('S.mk')), proj(S, 0, s));
  const recursive = app(constant(N('R.mk')), proj(R, 0, r));
  const multiCtor = app(constant(N('M.one')), proj(M, 0, m));

  expected.set('forward', tc.isDefEq(s, sExpansion) ? '1' : '0');
  expected.set('symmetric', tc.isDefEq(sExpansion, s) ? '1' : '0');
  expected.set('parameterized', tc.isDefEq(boxa, boxExpansion) ? '1' : '0');
  expected.set('wrong-field', tc.isDefEq(s, wrongField) ? '1' : '0');
  expected.set('incomplete', tc.isDefEq(s, incomplete) ? '1' : '0');
  expected.set('recursive', tc.isDefEq(r, recursive) ? '1' : '0');
  expected.set('multi-ctor', tc.isDefEq(m, multiCtor) ? '1' : '0');
  expected.set('ordinary-unequal', tc.isDefEq(constant(N('a')), constant(N('b'))) ? '1' : '0');
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

console.log(`PSCKERNEL_DEFEQ_STRUCT_ETA_DIFFERENTIAL: PASS (${expected.size} structure eta parity cases, 0 deviations)`);
