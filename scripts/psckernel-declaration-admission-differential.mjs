import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { bvar, constant, fvar, sort } from '../dist/src/core/expr.js';
import { levelParam, levelSucc, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { Kernel } from '../dist/src/kernel/kernel.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_DECLARATION_ADMISSION_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/DeclarationAdmissionFixture.lean'],
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

const name = (text) => nameFromDotted(text);
const sort0 = sort(levelZero);
const sort1 = sort(levelSucc(levelZero));
const P = constant(name('P'));
const p = constant(name('p'));

function axiom(declName, levelParams, type) {
  return { kind: 'axiom', name: name(declName), levelParams, type, isUnsafe: false };
}

function definition(declName, levelParams, type, value) {
  return {
    kind: 'definition',
    name: name(declName),
    levelParams,
    type,
    value,
    hints: { kind: 'regular', height: 0n },
    safety: 'safe',
  };
}

function theorem(declName, type, value) {
  return { kind: 'theorem', name: name(declName), levelParams: [], type, value };
}

function opaque(declName, type, value) {
  return { kind: 'opaque', name: name(declName), levelParams: [], type, value, isUnsafe: false };
}

function seededKernel() {
  const kernel = new Kernel(new Environment());
  kernel.addAxiom(axiom('P', [], sort0));
  kernel.addAxiom(axiom('p', [], P));
  return kernel;
}

function accepted(makeKernel, action) {
  const kernel = makeKernel();
  try {
    action(kernel);
    return 'true';
  } catch {
    return 'false';
  }
}

const expected = new Map();

expected.set('valid-axiom', accepted(
  () => new Kernel(new Environment()),
  (kernel) => kernel.addAxiom(axiom('A', [], sort0)),
));
expected.set('duplicate-name', accepted(
  seededKernel,
  (kernel) => kernel.addAxiom(axiom('P', [], sort0)),
));
expected.set('duplicate-level-params', accepted(
  () => new Kernel(new Environment()),
  (kernel) => {
    const u = name('u');
    kernel.addAxiom(axiom('A', [u, u], sort(levelParam(u))));
  },
));
expected.set('declared-level-param', accepted(
  () => new Kernel(new Environment()),
  (kernel) => {
    const u = name('u');
    kernel.addAxiom(axiom('Poly', [u], sort(levelParam(u))));
  },
));
expected.set('undefined-level-param', accepted(
  () => new Kernel(new Environment()),
  (kernel) => {
    const u = name('u');
    kernel.addAxiom(axiom('BadPoly', [], sort(levelParam(u))));
  },
));
expected.set('type-must-be-type', accepted(
  seededKernel,
  (kernel) => kernel.addAxiom(axiom('badType', [], p)),
));
expected.set('free-var-closed', accepted(
  () => new Kernel(new Environment()),
  (kernel) => kernel.addAxiom(axiom('freeType', [], fvar('free'))),
));
expected.set('loose-bvar-closed', accepted(
  () => new Kernel(new Environment()),
  (kernel) => kernel.addAxiom(axiom('loose', [], bvar(0))),
));
expected.set('mvar-closed', accepted(
  () => new Kernel(new Environment()),
  (kernel) => kernel.addAxiom(axiom('meta', [], { kind: 'mvar', id: 'm' })),
));
expected.set('valid-definition', accepted(
  () => new Kernel(new Environment()),
  (kernel) => kernel.addDefinition(definition('U', [], sort1, sort0)),
));
expected.set('definition-mismatch', accepted(
  () => new Kernel(new Environment()),
  (kernel) => kernel.addDefinition(definition('badDef', [], sort0, sort0)),
));
expected.set('definition-value-closed', accepted(
  () => new Kernel(new Environment()),
  (kernel) => kernel.addDefinition(definition('badValue', [], sort1, fvar('free'))),
));
expected.set('valid-theorem', accepted(
  seededKernel,
  (kernel) => kernel.addTheorem(theorem('T', P, p)),
));
expected.set('theorem-requires-prop', accepted(
  seededKernel,
  (kernel) => kernel.addTheorem(theorem('notTheorem', sort0, p)),
));
expected.set('valid-opaque', accepted(
  () => new Kernel(new Environment()),
  (kernel) => kernel.addOpaque(opaque('O', sort1, sort0)),
));
expected.set('opaque-mismatch', accepted(
  () => new Kernel(new Environment()),
  (kernel) => kernel.addOpaque(opaque('badOpaque', sort0, sort0)),
));

{
  const kernel = seededKernel();
  const before = kernel.env.size;
  try {
    kernel.addDefinition(definition('badTxn', [], sort0, sort0));
  } catch {
    // Expected rejection. Persistence is checked below.
  }
  expected.set('failure-persistent', before === kernel.env.size ? 'true' : 'false');
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

console.log(`PSCKERNEL_DECLARATION_ADMISSION_DIFFERENTIAL: PASS (${expected.size} admission parity cases, 0 deviations)`);
