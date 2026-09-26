import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { app, bvar, constant, forallE, lam, sort } from '../dist/src/core/expr.js';
import { levelSucc, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { addOrdinaryInductive } from '../dist/src/kernel/inductive/ordinary.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_INDUCTIVE_ADMISSION_UNIFORM_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/InductiveAdmissionUniformFixture.lean'],
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

function listLikeType() {
  return forallE(n('α'), type0, type0);
}

function directDecl() {
  const target = n('Uniform.ListLike');
  const nilType = forallE(
    n('α'), type0,
    app(constant(target), bvar(0)),
  );
  const consType = forallE(
    n('α'), type0,
    forallE(
      n('x'), bvar(0),
      forallE(
        n('xs'), app(constant(target), bvar(1)),
        app(constant(target), bvar(2)),
      ),
    ),
  );
  return {
    levelParams: [], numParams: 1, isUnsafe: false, numNested: 0,
    types: [{
      name: target, type: listLikeType(),
      ctors: [
        { name: n('Uniform.ListLike.nil'), type: nilType },
        { name: n('Uniform.ListLike.cons'), type: consType },
      ],
    }],
  };
}

function erasedDecl(validParameter) {
  const target = n('Uniform.Erased');
  const recursiveArgument = validParameter ? bvar(0) : sort(levelZero);
  const recursiveOccurrence = app(constant(target), recursiveArgument);
  const eraser = lam(n('ignored'), type0, sort(levelZero));
  const erasedFieldType = app(eraser, recursiveOccurrence);
  const ctorType = forallE(
    n('α'), type0,
    forallE(
      n('ghost'), erasedFieldType,
      app(constant(target), bvar(1)),
    ),
  );
  return {
    levelParams: [], numParams: 1, isUnsafe: false, numNested: 0,
    types: [{
      name: target, type: listLikeType(),
      ctors: [{ name: n('Uniform.Erased.mk'), type: ctorType }],
    }],
  };
}

function accepted(decl) {
  const env = new Environment();
  try {
    addOrdinaryInductive(env, decl);
    return true;
  } catch {
    return false;
  }
}

const expected = new Map([
  ['direct', boolText(accepted(directDecl()))],
  ['erased-uniform', boolText(accepted(erasedDecl(true)))],
  ['erased-nonuniform', boolText(accepted(erasedDecl(false)))],
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

console.log(`PSCKERNEL_INDUCTIVE_ADMISSION_UNIFORM_DIFFERENTIAL: PASS (${expected.size} parity observations, 0 deviations)`);
