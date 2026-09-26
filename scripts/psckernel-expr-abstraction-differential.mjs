import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { nameFromDotted, nameKey } from '../dist/src/core/name.js';
import { levelToString } from '../dist/src/core/level.js';
import {
  app,
  bvar,
  constant,
  forallE,
  lam,
} from '../dist/src/core/expr.js';
import { abstractFVar } from '../dist/src/core/instantiate.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_EXPR_ABSTRACTION_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/ExprAbstractionFixture.lean'],
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

function binderInfoKey(info) {
  switch (info) {
    case 'default': return 'd';
    case 'implicit': return 'i';
    case 'strictImplicit': return 's';
    case 'instImplicit': return 'c';
    default: throw new Error(`unknown binder info ${String(info)}`);
  }
}

function exprKey(expr) {
  switch (expr.kind) {
    case 'bvar': return `b${expr.index}`;
    case 'fvar': return `f{${expr.id}}`;
    case 'mvar': return `v{${expr.id}}`;
    case 'sort': return `S{${levelToString(expr.level)}}`;
    case 'const':
      return `C{${nameKey(expr.name)}}[${expr.levels.map(levelToString).join(',')}]`;
    case 'app': return `A(${exprKey(expr.fn)},${exprKey(expr.arg)})`;
    case 'lam':
      return `L{${nameKey(expr.name)},${binderInfoKey(expr.binderInfo)}}(${exprKey(expr.type)},${exprKey(expr.body)})`;
    case 'forall':
      return `P{${nameKey(expr.name)},${binderInfoKey(expr.binderInfo)}}(${exprKey(expr.type)},${exprKey(expr.body)})`;
    case 'let':
      return `T{${nameKey(expr.name)},${expr.nondep ? '1' : '0'}}(${exprKey(expr.type)},${exprKey(expr.value)},${exprKey(expr.body)})`;
    case 'lit':
      return expr.literal.kind === 'nat' ? `N${expr.literal.value}` : `Q${expr.literal.value}`;
    case 'mdata': return `M(${exprKey(expr.expr)})`;
    case 'proj':
      return `R{${nameKey(expr.typeName)},${expr.index}}(${exprKey(expr.expr)})`;
    default: throw new Error(`unknown expression kind ${expr.kind}`);
  }
}

const targetId = 'x';
const otherId = 'y';
const nameY = nameFromDotted('y');
const nameP = nameFromDotted('P');
const targetExpr = { kind: 'fvar', id: targetId };
const otherExpr = { kind: 'fvar', id: otherId };
const constT = constant(nameFromDotted('T'));

const cases = new Map([
  ['non-target', abstractFVar(otherExpr, targetId)],
  ['target-root', abstractFVar(targetExpr, targetId)],
  ['loose-shift', abstractFVar(bvar(0), targetId)],
  ['application', abstractFVar(app(targetExpr, bvar(0)), targetId)],
  [
    'lambda-depth',
    abstractFVar(
      lam(nameY, constT, app(targetExpr, bvar(0)), 'default'),
      targetId,
    ),
  ],
  [
    'forall-depth',
    abstractFVar(
      forallE(nameY, targetExpr, targetExpr, 'implicit'),
      targetId,
    ),
  ],
  [
    'loose-under-binder',
    abstractFVar(lam(nameY, constT, bvar(1), 'default'), targetId),
  ],
  [
    'let-depth',
    abstractFVar(
      {
        kind: 'let',
        name: nameY,
        type: targetExpr,
        value: targetExpr,
        body: app(targetExpr, bvar(0)),
        nondep: true,
      },
      targetId,
    ),
  ],
  [
    'projection',
    abstractFVar(
      {
        kind: 'proj',
        typeName: nameP,
        index: 3,
        expr: targetExpr,
      },
      targetId,
    ),
  ],
  ['nested-non-target', abstractFVar(app(otherExpr, targetExpr), targetId)],
]);

for (const key of fixture.keys()) {
  if (!cases.has(key)) fail(`unclassified PSCKernel fixture output: ${key}`);
}

for (const [key, expression] of cases) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const expected = exprKey(expression);
  const actual = fixture.get(key);
  if (actual !== expected) {
    fail(`${key}: TS=${JSON.stringify(expected)} PSCKernel=${JSON.stringify(actual)}`);
  }
}

if (fixture.size !== cases.size) {
  fail(`unexpected fixture size ${fixture.size}; expected ${cases.size}`);
}

console.log(
  `PSCKERNEL_EXPR_ABSTRACTION_DIFFERENTIAL: PASS (${cases.size} structural parity cases, 0 deviations)`,
);
