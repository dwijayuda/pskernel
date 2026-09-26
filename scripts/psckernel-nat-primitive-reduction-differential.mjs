import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import {
  bvar,
  constant,
  exprLeanEq,
  mkAppN,
  natLit,
} from '../dist/src/core/expr.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_NAT_PRIMITIVE_REDUCTION_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const leanRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/NatPrimitiveReductionTests.lean'],
  { cwd: selfhost, encoding: 'utf8' },
);
if (leanRun.error) fail(`could not run Lean contract: ${leanRun.error.message}`);
if (leanRun.status !== 0) {
  if (leanRun.stdout) process.stderr.write(leanRun.stdout);
  if (leanRun.stderr) process.stderr.write(leanRun.stderr);
  fail(`Lean contract exited with status ${leanRun.status}`);
}

const labels = [
  'Nat.succ reduces literal operand',
  'Nat.add reduces literal operands',
  'Nat.sub saturates at zero',
  'Nat.mul reduces literal operands',
  'Nat.pow reduces literal operands',
  'Nat.gcd reduces literal operands',
  'Nat.mod reduces literal operands',
  'Nat.mod by zero returns dividend',
  'Nat.div reduces literal operands',
  'Nat.div by zero returns zero',
  'Nat.land reduces literal operands',
  'Nat.lor reduces literal operands',
  'Nat.xor reduces literal operands',
  'Nat.shiftLeft reduces literal operands',
  'Nat.shiftRight reduces literal operands',
  'Nat.beq returns Bool.true for equal literals',
  'Nat.ble returns Bool.false for descending literals',
  'Nat primitive operands are weak-head reduced',
  'Nat primitive with non-numeral operand stays stuck',
];

const leanPassed = new Set();
for (const line of leanRun.stdout.split(/\r?\n/)) {
  const prefix = 'PSCKERNEL_NAT_PRIMITIVE_REDUCTION_PASS: ';
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
const unary = (name, arg) => mkAppN(C(name), [arg]);
const binary = (name, left, right) => mkAppN(C(name), [left, right]);
const tc = new TypeChecker(new Environment());
const observations = [];

observations.push(exprLeanEq(tc.whnf(unary('Nat.succ', natLit(2))), natLit(3)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.add', natLit(2), natLit(3))), natLit(5)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.sub', natLit(2), natLit(5))), natLit(0)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.mul', natLit(3), natLit(4))), natLit(12)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.pow', natLit(2), natLit(5))), natLit(32)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.gcd', natLit(12), natLit(18))), natLit(6)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.mod', natLit(17), natLit(5))), natLit(2)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.mod', natLit(17), natLit(0))), natLit(17)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.div', natLit(17), natLit(5))), natLit(3)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.div', natLit(17), natLit(0))), natLit(0)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.land', natLit(6), natLit(3))), natLit(2)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.lor', natLit(4), natLit(1))), natLit(5)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.xor', natLit(6), natLit(3))), natLit(5)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.shiftLeft', natLit(3), natLit(2))), natLit(12)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.shiftRight', natLit(12), natLit(2))), natLit(3)));
observations.push(exprLeanEq(tc.whnf(binary('Nat.beq', natLit(4), natLit(4))), C('Bool.true')));
observations.push(exprLeanEq(tc.whnf(binary('Nat.ble', natLit(5), natLit(3))), C('Bool.false')));
{
  const left = {
    kind: 'let',
    name: N('x'),
    type: C('Nat'),
    value: natLit(2),
    body: bvar(0),
    nondep: false,
  };
  observations.push(exprLeanEq(tc.whnf(binary('Nat.add', left, natLit(3))), natLit(5)));
}
{
  const e = binary('Nat.add', C('unknownNat'), natLit(3));
  observations.push(exprLeanEq(tc.whnf(e), e));
}

for (let i = 0; i < observations.length; i++) {
  if (!observations[i]) fail(`TypeScript reference failed contract case: ${labels[i]}`);
}

console.log(`PSCKERNEL_NAT_PRIMITIVE_REDUCTION_DIFFERENTIAL: PASS (${observations.length} Nat primitive parity cases, 0 deviations)`);
