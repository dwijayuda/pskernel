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
  natLit,
  sort,
} from '../dist/src/core/expr.js';
import { levelSucc, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_RECURSOR_NAT_LITERAL_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const leanRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/RecursorNatLiteralTests.lean'],
  { cwd: selfhost, encoding: 'utf8' },
);
if (leanRun.error) fail(`could not run Lean contract: ${leanRun.error.message}`);
if (leanRun.status !== 0) {
  if (leanRun.stdout) process.stderr.write(leanRun.stdout);
  if (leanRun.stderr) process.stderr.write(leanRun.stderr);
  fail(`Lean contract exited with status ${leanRun.status}`);
}

const prefix = 'PSCKERNEL_RECURSOR_NAT_LITERAL_PASS: ';
const leanPassed = new Set();
for (const line of leanRun.stdout.split(/\r?\n/)) {
  if (line.startsWith(prefix)) leanPassed.add(line.slice(prefix.length));
}

const labels = [
  'Nat literal zero selects Nat.zero rule',
  'positive Nat literal selects Nat.succ rule',
  'Nat literal one forwards zero predecessor literal',
  'explicit Nat.succ constructor still reduces',
];
for (const label of labels) {
  if (!leanPassed.has(label)) fail(`missing Lean PASS observation: ${label}`);
}
if (leanPassed.size !== labels.length) {
  fail(`unexpected Lean observation count ${leanPassed.size}; expected ${labels.length}`);
}

const N = (text) => nameFromDotted(text);

function makeEnv() {
  const env = new Environment();
  const Nat = N('Nat');
  const Zero = N('Nat.zero');
  const Succ = N('Nat.succ');
  const Rec = N('Nat.testRec');
  const natType = constant(Nat);
  const sort1 = sort(levelSucc(levelZero));

  env.add({
    kind: 'inductive', name: Nat, levelParams: [], type: sort1,
    numParams: 0, numIndices: 0, all: [Nat, Zero, Succ], ctors: [Zero, Succ],
    numNested: 0, isRec: true, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: Zero, levelParams: [], type: natType,
    induct: Nat, cidx: 0, numParams: 0, numFields: 0, isUnsafe: false,
  });
  env.add({
    kind: 'constructor', name: Succ, levelParams: [],
    type: forallE(N('n'), natType, natType),
    induct: Nat, cidx: 1, numParams: 0, numFields: 1, isUnsafe: false,
  });
  env.add({
    kind: 'recursor', name: Rec, levelParams: [], type: sort1, all: [Nat],
    numParams: 0, numIndices: 0, numMotives: 0, numMinors: 0,
    rules: [
      { ctor: Zero, nFields: 0, rhs: natLit(100) },
      { ctor: Succ, nFields: 1, rhs: lam(N('pred'), natType, bvar(0)) },
    ],
    k: false, isUnsafe: false,
  });
  return env;
}

const env = makeEnv();
const tc = new TypeChecker(env);
const rec = constant(N('Nat.testRec'));
const observations = [
  exprLeanEq(tc.whnf(app(rec, natLit(0))), natLit(100)),
  exprLeanEq(tc.whnf(app(rec, natLit(3))), natLit(2)),
  exprLeanEq(tc.whnf(app(rec, natLit(1))), natLit(0)),
  exprLeanEq(
    tc.whnf(app(rec, app(constant(N('Nat.succ')), natLit(8)))),
    natLit(8),
  ),
];

for (let i = 0; i < observations.length; i++) {
  if (!observations[i]) fail(`TypeScript reference failed contract case: ${labels[i]}`);
}

console.log(`PSCKERNEL_RECURSOR_NAT_LITERAL_DIFFERENTIAL: PASS (${observations.length} Nat literal recursor parity cases, 0 deviations)`);
