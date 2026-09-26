import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { nameFromDotted } from '../dist/src/core/name.js';
import { levelMVar } from '../dist/src/core/level.js';
import {
  app,
  bvar,
  constant,
  exprLeanEq,
  getAppArgs,
  getAppFn,
  hasFVar,
  hasMVar,
  lam,
  natLit,
  strLit,
} from '../dist/src/core/expr.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_EXPR_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/ExprFixture.lean'],
  {
    cwd: selfhost,
    encoding: 'utf8',
  },
);

if (fixtureRun.error) {
  fail(`could not run Lean fixture: ${fixtureRun.error.message}`);
}
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

const nameA = nameFromDotted('A');
const nameF = nameFromDotted('f');
const nameX = nameFromDotted('x');
const nameY = nameFromDotted('y');
const typeA = constant(nameA, []);
const fn = constant(nameF, []);
const arg1 = bvar(0);
const arg2 = bvar(1);
const application = app(app(fn, arg1), arg2);
const lambdaLeft = lam(nameX, typeA, bvar(0), 'default');
const lambdaRight = lam(nameY, typeA, bvar(0), 'implicit');
const letLeft = {
  kind: 'let',
  name: nameX,
  type: typeA,
  value: arg1,
  body: bvar(0),
  nondep: true,
};
const letRight = {
  kind: 'let',
  name: nameY,
  type: typeA,
  value: arg1,
  body: bvar(0),
  nondep: false,
};
const projectionLeft = { kind: 'proj', typeName: nameA, index: 0, expr: arg1 };
const projectionRight = { kind: 'proj', typeName: nameA, index: 1, expr: arg1 };
const fvarExpr = { kind: 'fvar', id: 'x' };
const exprMVar = { kind: 'mvar', id: 'y' };
const levelMVarExpr = { kind: 'sort', level: levelMVar(nameX) };

const actualArgs = getAppArgs(application);
const expectedParity = new Map([
  ['literal.same', String(exprLeanEq(natLit(7), natLit(7)))],
  ['literal.kindDifferent', String(exprLeanEq(natLit(7), strLit('7')))],
  ['eqv.binderPresentation', String(exprLeanEq(lambdaLeft, lambdaRight))],
  ['eqv.letNondep', String(exprLeanEq(letLeft, letRight))],
  ['eqv.projectionIndex', String(exprLeanEq(projectionLeft, projectionRight))],
  ['app.fn', String(exprLeanEq(getAppFn(application), fn))],
  [
    'app.args',
    String(
      actualArgs.length === 2
        && exprLeanEq(actualArgs[0], arg1)
        && exprLeanEq(actualArgs[1], arg2),
    ),
  ],
  ['flags.fvar', String(hasFVar(app(fn, fvarExpr)))],
  ['flags.exprMVar', String(hasMVar(app(fn, exprMVar)))],
  ['flags.levelMVar', String(hasMVar(levelMVarExpr))],
]);

for (const key of fixture.keys()) {
  if (!expectedParity.has(key)) fail(`unclassified PSCKernel fixture output: ${key}`);
}

for (const [key, expected] of expectedParity) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== expected) {
    fail(`${key}: TS=${JSON.stringify(expected)} PSCKernel=${JSON.stringify(actual)}`);
  }
}

if (fixture.size !== expectedParity.size) {
  fail(`unexpected fixture size ${fixture.size}; expected ${expectedParity.size}`);
}

console.log(`PSCKERNEL_EXPR_DIFFERENTIAL: PASS (${expectedParity.size} parity cases, 0 deviations)`);
