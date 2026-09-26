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
import { instantiate, instantiate1, lift } from '../dist/src/core/instantiate.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_EXPR_INSTANTIATION_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/ExprInstantiationFixture.lean'],
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

const nameX = nameFromDotted('x');
const nameP = nameFromDotted('P');
const constA = constant(nameFromDotted('A'));
const constB = constant(nameFromDotted('B'));
const constT = constant(nameFromDotted('T'));

const cases = new Map([
  ['lift-zero', lift(bvar(2), 0, 0)],
  ['lift-cutoff', lift(app(bvar(0), bvar(1)), 2, 1)],
  [
    'lift-binder',
    lift(lam(nameX, bvar(0), app(bvar(0), bvar(1)), 'default'), 1, 0),
  ],
  ['empty', instantiate(app(bvar(0), bvar(2)), [])],
  ['single', instantiate1(app(bvar(0), bvar(1)), constA)],
  [
    'multi',
    instantiate(app(app(bvar(0), bvar(1)), bvar(2)), [constA, constB]),
  ],
  [
    'subst-lift',
    instantiate(lam(nameX, constT, app(bvar(0), bvar(1)), 'default'), [bvar(0)]),
  ],
  [
    'forall-depth',
    instantiate(forallE(nameX, bvar(0), app(bvar(0), bvar(1)), 'implicit'), [constA]),
  ],
  [
    'let-depth',
    instantiate(
      {
        kind: 'let',
        name: nameX,
        type: bvar(0),
        value: bvar(0),
        body: app(bvar(0), bvar(1)),
        nondep: true,
      },
      [constA],
    ),
  ],
  [
    'projection',
    instantiate1(
      {
        kind: 'proj',
        typeName: nameP,
        index: 2,
        expr: app(bvar(0), bvar(1)),
      },
      constA,
    ),
  ],
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
  `PSCKERNEL_EXPR_INSTANTIATION_DIFFERENTIAL: PASS (${cases.size} structural parity cases, 0 deviations)`,
);
