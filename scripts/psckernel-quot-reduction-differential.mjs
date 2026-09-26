import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import {
  bvar,
  constant,
  exprLeanEq,
  mkAppN,
} from '../dist/src/core/expr.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_QUOT_REDUCTION_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const leanRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/QuotReductionTests.lean'],
  { cwd: selfhost, encoding: 'utf8' },
);
if (leanRun.error) fail(`could not run Lean contract: ${leanRun.error.message}`);
if (leanRun.status !== 0) {
  if (leanRun.stdout) process.stderr.write(leanRun.stdout);
  if (leanRun.stderr) process.stderr.write(leanRun.stderr);
  fail(`Lean contract exited with status ${leanRun.status}`);
}

const labels = [
  'Quot.lift reduces a Quot.mk major',
  'Quot.ind reduces a Quot.mk major',
  'Quot.lift preserves trailing arguments',
  'Quot.ind preserves trailing arguments',
  'quotient reduction weak-head reduces the major',
  'quotient reduction requires initialized quotient support',
  'non-Quot.mk major stays stuck',
  'malformed Quot.mk arity stays stuck',
  'partial Quot.lift application stays stuck',
];

const leanPassed = new Set();
for (const line of leanRun.stdout.split(/\r?\n/)) {
  const prefix = 'PSCKERNEL_QUOT_REDUCTION_PASS: ';
  if (line.startsWith(prefix)) leanPassed.add(line.slice(prefix.length));
}
for (const label of labels) {
  if (!leanPassed.has(label)) fail(`missing Lean PASS observation: ${label}`);
}
if (leanPassed.size !== labels.length) {
  fail(`unexpected Lean observation count ${leanPassed.size}; expected ${labels.length}`);
}

const N = (text) => nameFromDotted(text);
const C = (text) => constant(N(text));
const payload = C('x');
const tail = C('tail');
const quotMk = (value) => mkAppN(C('Quot.mk'), [C('A'), C('r'), value]);
const quotLift = (major, trailing = []) =>
  mkAppN(C('Quot.lift'), [C('A'), C('r'), C('B'), C('f'), C('h'), major, ...trailing]);
const quotInd = (major, trailing = []) =>
  mkAppN(C('Quot.ind'), [C('A'), C('r'), C('motive'), C('proof'), major, ...trailing]);

const env = new Environment();
env.quotInitialized = true;
const tc = new TypeChecker(env);
const uninitialized = new TypeChecker(new Environment());
const observations = [];

{
  const e = quotLift(quotMk(payload));
  observations.push(exprLeanEq(tc.whnf(e), mkAppN(C('f'), [payload])));
}
{
  const e = quotInd(quotMk(payload));
  observations.push(exprLeanEq(tc.whnf(e), mkAppN(C('proof'), [payload])));
}
{
  const e = quotLift(quotMk(payload), [tail]);
  observations.push(exprLeanEq(tc.whnf(e), mkAppN(C('f'), [payload, tail])));
}
{
  const e = quotInd(quotMk(payload), [tail]);
  observations.push(exprLeanEq(tc.whnf(e), mkAppN(C('proof'), [payload, tail])));
}
{
  const major = {
    kind: 'let',
    name: N('q'),
    type: C('QuotType'),
    value: quotMk(payload),
    body: bvar(0),
    nondep: false,
  };
  const e = quotLift(major);
  observations.push(exprLeanEq(tc.whnf(e), mkAppN(C('f'), [payload])));
}
{
  const e = quotLift(quotMk(payload));
  observations.push(exprLeanEq(uninitialized.whnf(e), e));
}
{
  const e = quotLift(C('notQuot'));
  observations.push(exprLeanEq(tc.whnf(e), e));
}
{
  const malformed = mkAppN(C('Quot.mk'), [C('A'), payload]);
  const e = quotLift(malformed);
  observations.push(exprLeanEq(tc.whnf(e), e));
}
{
  const e = mkAppN(C('Quot.lift'), [C('A'), C('r'), C('B'), C('f'), C('h')]);
  observations.push(exprLeanEq(tc.whnf(e), e));
}

for (let i = 0; i < observations.length; i++) {
  if (!observations[i]) fail(`TypeScript reference failed contract case: ${labels[i]}`);
}

console.log(`PSCKERNEL_QUOT_REDUCTION_DIFFERENTIAL: PASS (${observations.length} quotient parity cases, 0 deviations)`);
