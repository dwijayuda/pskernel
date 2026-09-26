import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { hasValue, isUnsafeConstant } from '../dist/src/core/declaration.js';
import { constant } from '../dist/src/core/expr.js';
import { nameFromDotted, nameToString } from '../dist/src/core/name.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_DECLARATION_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/DeclarationFixture.lean'],
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

const name = (text) => nameFromDotted(text);
const typeExpr = constant(name('Type'), []);
const bodyExpr = constant(name('body'), []);
const proofExpr = constant(name('proof'), []);
const hiddenExpr = constant(name('hidden'), []);
const levelParams = [name('u')];

const safeDef = {
  kind: 'definition',
  name: name('f'),
  levelParams,
  type: typeExpr,
  value: bodyExpr,
  hints: { kind: 'regular', height: 2n },
  safety: 'safe',
};
const unsafeDef = { ...safeDef, safety: 'unsafe' };
const partialDef = { ...safeDef, safety: 'partial' };
const theoremInfo = {
  kind: 'theorem',
  name: name('thm'),
  levelParams,
  type: typeExpr,
  value: proofExpr,
};
const opaqueInfo = {
  kind: 'opaque',
  name: name('opq'),
  levelParams,
  type: typeExpr,
  value: hiddenExpr,
  isUnsafe: true,
};
const axiomInfo = {
  kind: 'axiom',
  name: name('ax'),
  levelParams,
  type: typeExpr,
  isUnsafe: true,
};
const quotInfo = {
  kind: 'quot',
  name: name('Quot'),
  levelParams,
  type: typeExpr,
  quotKind: 'type',
};
const inductiveInfo = {
  kind: 'inductive',
  name: name('NatLike'),
  levelParams,
  type: typeExpr,
  numParams: 1,
  numIndices: 0,
  all: [name('NatLike')],
  ctors: [name('NatLike.zero'), name('NatLike.succ')],
  numNested: 0,
  isRec: true,
  isReflexive: false,
  isUnsafe: true,
};

const hintKey = (hint) =>
  hint.kind === 'regular' ? `regular:${hint.height}` : hint.kind;

const expected = new Map([
  ['definition.name', nameToString(safeDef.name)],
  ['definition.levelCount', String(safeDef.levelParams.length)],
  ['definition.hint', hintKey(safeDef.hints)],
  ['definition.safety', safeDef.safety],
  ['definition.hasValue', String(hasValue(safeDef))],
  ['theorem.hasValue', String(hasValue(theoremInfo))],
  ['opaque.hasValue', String(hasValue(opaqueInfo))],
  ['axiom.hasValue', String(hasValue(axiomInfo))],
  ['unsafe.definition', String(isUnsafeConstant(unsafeDef))],
  ['unsafe.safeDefinition', String(isUnsafeConstant(safeDef))],
  ['unsafe.axiom', String(isUnsafeConstant(axiomInfo))],
  ['unsafe.opaque', String(isUnsafeConstant(opaqueInfo))],
  ['unsafe.theorem', String(isUnsafeConstant(theoremInfo))],
  ['unsafe.quot', String(isUnsafeConstant(quotInfo))],
  ['unsafe.inductive', String(isUnsafeConstant(inductiveInfo))],
  ['partial.definition', String(partialDef.safety === 'partial')],
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
  `PSCKERNEL_DECLARATION_DIFFERENTIAL: PASS (${expected.size} overlap parity cases, 0 deviations)`,
);
