import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import {
  app,
  bvar,
  constant,
  exprLeanEq,
  forallE,
  lam,
  mkAppN,
  natLit,
  sort,
} from '../dist/src/core/expr.js';
import { levelParam, levelSucc, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_RECURSOR_BASIC_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const leanRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/RecursorBasicTests.lean'],
  { cwd: selfhost, encoding: 'utf8' },
);
if (leanRun.error) fail(`could not run Lean contract: ${leanRun.error.message}`);
if (leanRun.status !== 0) {
  if (leanRun.stdout) process.stderr.write(leanRun.stdout);
  if (leanRun.stderr) process.stderr.write(leanRun.stderr);
  fail(`Lean contract exited with status ${leanRun.status}`);
}

const leanPassed = new Set();
for (const line of leanRun.stdout.split(/\r?\n/)) {
  const prefix = 'PSCKERNEL_RECURSOR_BASIC_PASS: ';
  if (line.startsWith(prefix)) leanPassed.add(line.slice(prefix.length));
}

const N = (text) => nameFromDotted(text);
const axiom = (name, type) => ({ kind: 'axiom', name, levelParams: [], type, isUnsafe: false });

function makeEnv() {
  const env = new Environment();
  const sort1 = sort(levelSucc(levelZero));
  const A = constant(N('A'));
  const I = N('I'), C0 = N('I.c0'), C1 = N('I.c1'), IRec = N('I.rec');
  const J = N('J'), JMk = N('J.mk'), JRec = N('J.rec');
  const Box = N('Box'), BoxMk = N('Box.mk'), BoxRec = N('Box.rec');
  const TailRec = N('I.tailRec'), URec = N('I.uRec'), u = N('u');

  env.add(axiom(N('A'), sort1));
  env.add(axiom(N('a'), A));
  env.add({
    kind: 'inductive', name: I, levelParams: [], type: sort1,
    numParams: 0, numIndices: 0, all: [I, C0, C1], ctors: [C0, C1],
    numNested: 0, isRec: false, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: C0, levelParams: [], type: constant(I),
    induct: I, cidx: 0, numParams: 0, numFields: 0, isUnsafe: false,
  });
  env.add({
    kind: 'constructor', name: C1, levelParams: [], type: constant(I),
    induct: I, cidx: 1, numParams: 0, numFields: 0, isUnsafe: false,
  });
  env.add({
    kind: 'recursor', name: IRec, levelParams: [],
    type: forallE(N('major'), constant(I), A), all: [I],
    numParams: 0, numIndices: 0, numMotives: 0, numMinors: 0,
    rules: [{ ctor: C0, nFields: 0, rhs: natLit(7) }], k: false, isUnsafe: false,
  });

  env.add({
    kind: 'inductive', name: J, levelParams: [], type: sort1,
    numParams: 0, numIndices: 0, all: [J, JMk], ctors: [JMk],
    numNested: 0, isRec: false, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: JMk, levelParams: [],
    type: forallE(N('value'), A, constant(J)),
    induct: J, cidx: 0, numParams: 0, numFields: 1, isUnsafe: false,
  });
  env.add({
    kind: 'recursor', name: JRec, levelParams: [],
    type: forallE(N('major'), constant(J), A), all: [J],
    numParams: 0, numIndices: 0, numMotives: 0, numMinors: 0,
    rules: [{ ctor: JMk, nFields: 1, rhs: lam(N('field'), A, bvar(0)) }],
    k: false, isUnsafe: false,
  });

  env.add({
    kind: 'inductive', name: Box, levelParams: [], type: sort1,
    numParams: 1, numIndices: 0, all: [Box, BoxMk], ctors: [BoxMk],
    numNested: 0, isRec: false, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: BoxMk, levelParams: [],
    type: forallE(N('T'), sort1, forallE(N('value'), bvar(0), app(constant(Box), bvar(1)))),
    induct: Box, cidx: 0, numParams: 1, numFields: 1, isUnsafe: false,
  });
  env.add({
    kind: 'recursor', name: BoxRec, levelParams: [], type: sort1, all: [Box],
    numParams: 1, numIndices: 0, numMotives: 0, numMinors: 0,
    rules: [{
      ctor: BoxMk,
      nFields: 1,
      rhs: lam(N('T'), sort1, lam(N('value'), bvar(0), bvar(0))),
    }],
    k: false, isUnsafe: false,
  });

  env.add({
    kind: 'recursor', name: TailRec, levelParams: [], type: sort1, all: [I],
    numParams: 0, numIndices: 0, numMotives: 0, numMinors: 0,
    rules: [{ ctor: C0, nFields: 0, rhs: lam(N('tail'), A, bvar(0)) }],
    k: false, isUnsafe: false,
  });
  env.add({
    kind: 'recursor', name: URec, levelParams: [u], type: sort1, all: [I],
    numParams: 0, numIndices: 0, numMotives: 0, numMinors: 0,
    rules: [{ ctor: C0, nFields: 0, rhs: sort(levelParam(u)) }],
    k: false, isUnsafe: false,
  });
  return env;
}

const labels = [
  'matching constructor selects recursor rule',
  'constructor fields are forwarded to rule rhs',
  'constructor parameter prefix is dropped',
  'arguments after major are preserved',
  'rule rhs universe parameters instantiate',
  'major expression is weak-head reduced before rule selection',
  'unmatched constructor rule stays stuck',
  'recursor without major argument stays stuck',
  'wrong recursor universe arity stays stuck',
];

for (const label of labels) {
  if (!leanPassed.has(label)) fail(`missing Lean PASS observation: ${label}`);
}
if (leanPassed.size !== labels.length) {
  fail(`unexpected Lean observation count ${leanPassed.size}; expected ${labels.length}`);
}

const env = makeEnv();
const tc = new TypeChecker(env);
const A = constant(N('A'));
const a = constant(N('a'));
const c0 = constant(N('I.c0'));
const c1 = constant(N('I.c1'));
const observations = [];

{
  const e = app(constant(N('I.rec')), c0);
  observations.push(exprLeanEq(tc.whnf(e), natLit(7)));
}
{
  const major = app(constant(N('J.mk')), a);
  const e = app(constant(N('J.rec')), major);
  observations.push(exprLeanEq(tc.whnf(e), a));
}
{
  const major = mkAppN(constant(N('Box.mk')), [A, a]);
  const e = mkAppN(constant(N('Box.rec')), [A, major]);
  observations.push(exprLeanEq(tc.whnf(e), a));
}
{
  const e = mkAppN(constant(N('I.tailRec')), [c0, a]);
  observations.push(exprLeanEq(tc.whnf(e), a));
}
{
  const e = app(constant(N('I.uRec'), [levelZero]), c0);
  observations.push(exprLeanEq(tc.whnf(e), sort(levelZero)));
}
{
  const major = {
    kind: 'let', name: N('x'), type: constant(N('I')),
    value: c0, body: bvar(0), nondep: false,
  };
  const e = app(constant(N('I.rec')), major);
  observations.push(exprLeanEq(tc.whnf(e), natLit(7)));
}
{
  const e = app(constant(N('I.rec')), c1);
  observations.push(exprLeanEq(tc.whnf(e), e));
}
{
  const e = constant(N('I.rec'));
  observations.push(exprLeanEq(tc.whnf(e), e));
}
{
  const e = app(constant(N('I.rec'), [levelZero]), c0);
  observations.push(exprLeanEq(tc.whnf(e), e));
}

for (let i = 0; i < observations.length; i++) {
  if (!observations[i]) fail(`TypeScript reference failed contract case: ${labels[i]}`);
}

console.log(`PSCKERNEL_RECURSOR_BASIC_DIFFERENTIAL: PASS (${observations.length} recursor parity cases, 0 deviations)`);
