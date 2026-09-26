import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { constant, exprLeanEq } from '../dist/src/core/expr.js';
import { LocalContext } from '../dist/src/core/local-context.js';
import { nameFromDotted, nameToString } from '../dist/src/core/name.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_LOCAL_CONTEXT_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/LocalContextFixture.lean'],
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

const nameX = nameFromDotted('x');
const nameY = nameFromDotted('y');
const nameZ = nameFromDotted('z');
const typeT = constant(nameFromDotted('T'), []);
const typeU = constant(nameFromDotted('U'), []);
const valueV = constant(nameFromDotted('v'), []);

const ctx = new LocalContext();
ctx.addLocal('x', nameX, typeT, 'implicit');
ctx.addLet('y', nameY, typeU, valueV);
const extended = ctx.clone();
extended.addLocal('z', nameZ, typeT, 'default');

const local = ctx.get('x');
const letDecl = ctx.get('y');
const entries = ctx.entries();

const expected = new Map([
  ['entries.order', entries.map((decl) => decl.id).join(',')],
  ['entries.count', String(entries.length)],
  ['local.kind', local?.kind ?? 'missing'],
  ['local.binder', local?.kind === 'local'
    ? ({ default: 'd', implicit: 'i', strictImplicit: 's', instImplicit: 'c' })[local.binderInfo]
    : 'missing'],
  ['local.user', local ? nameToString(local.userName) : 'missing'],
  ['local.type', String(local !== undefined && exprLeanEq(local.type, typeT))],
  ['let.kind', letDecl?.kind ?? 'missing'],
  ['let.value', String(letDecl?.kind === 'let' && exprLeanEq(letDecl.value, valueV))],
  ['missing', String(ctx.get('z') === undefined)],
  ['persistent', String(ctx.entries().length === 2 && extended.entries().length === 3)],
]);

for (const key of fixture.keys()) {
  if (!expected.has(key)) fail(`unclassified PSCKernel fixture output: ${key}`);
}

for (const [key, value] of expected) {
  if (!fixture.has(key)) fail(`missing fixture key: ${key}`);
  const actual = fixture.get(key);
  if (actual !== value) {
    fail(`${key}: TS=${JSON.stringify(value)} PSCKernel=${JSON.stringify(actual)}`);
  }
}

if (fixture.size !== expected.size) {
  fail(`unexpected fixture size ${fixture.size}; expected ${expected.size}`);
}

console.log(
  `PSCKERNEL_LOCAL_CONTEXT_DIFFERENTIAL: PASS (${expected.size} overlap parity cases, 0 deviations)`,
);
