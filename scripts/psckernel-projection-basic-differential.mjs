import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

import { Environment } from '../dist/src/core/environment.js';
import { LocalContext } from '../dist/src/core/local-context.js';
import { app, bvar, constant, forallE, mkAppN, sort } from '../dist/src/core/expr.js';
import { levelSucc, levelToString, levelZero } from '../dist/src/core/level.js';
import { nameFromDotted, nameToString } from '../dist/src/core/name.js';
import { TypeChecker } from '../dist/src/kernel/type-checker.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const selfhost = path.join(root, 'selfhost');

function fail(message) {
  console.error(`PSCKERNEL_PROJECTION_BASIC_DIFFERENTIAL_FAIL: ${message}`);
  process.exit(1);
}

const fixtureRun = spawnSync(
  'lake',
  ['env', 'lean', '--run', 'packages/psckernel/test/ProjectionBasicFixture.lean'],
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

const N = (text) => nameFromDotted(text);
const proj = (typeName, index, expr) => ({ kind: 'proj', typeName, index, expr });

function exprKey(expr) {
  switch (expr.kind) {
    case 'bvar': return `b${expr.index}`;
    case 'fvar': return `f{${expr.id}}`;
    case 'mvar': return `v{${expr.id}}`;
    case 'sort': return `S{${levelToString(expr.level)}}`;
    case 'const': return `C{${nameToString(expr.name)}}[${expr.levels.map(levelToString).join(',')}]`;
    case 'app': return `A(${exprKey(expr.fn)},${exprKey(expr.arg)})`;
    case 'lam': return `L{${nameToString(expr.name)}}(${exprKey(expr.type)},${exprKey(expr.body)})`;
    case 'forall': return `P{${nameToString(expr.name)}}(${exprKey(expr.type)},${exprKey(expr.body)})`;
    case 'let': return `T{${nameToString(expr.name)},${expr.nondep === true ? '1' : '0'}}(${exprKey(expr.type)},${exprKey(expr.value)},${exprKey(expr.body)})`;
    case 'lit': return expr.literal.kind === 'nat' ? `N${expr.literal.value}` : `Q${expr.literal.value}`;
    case 'mdata': return exprKey(expr.expr);
    case 'proj': return `R{${nameToString(expr.typeName)},${expr.index}}(${exprKey(expr.expr)})`;
  }
}

function attempt(fn) {
  try { return exprKey(fn()); } catch { return 'none'; }
}

function axiom(name, type) {
  return { kind: 'axiom', name, levelParams: [], type, isUnsafe: false };
}

function makeEnv() {
  const env = new Environment();
  const sort1 = sort(levelSucc(levelZero));
  const A = constant(N('A'));
  const B = constant(N('B'));
  const S = N('S');
  const SMk = N('S.mk');
  const Box = N('Box');
  const BoxMk = N('Box.mk');
  const ProofBox = N('ProofBox');
  const ProofBoxMk = N('ProofBox.mk');

  env.add(axiom(N('A'), sort1));
  env.add(axiom(N('a'), A));
  env.add(axiom(N('B'), sort1));
  env.add(axiom(N('b'), B));

  env.add({
    kind: 'inductive', name: S, levelParams: [], type: sort1,
    numParams: 0, numIndices: 0, all: [S, SMk], ctors: [SMk],
    numNested: 0, isRec: false, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: SMk, levelParams: [],
    type: forallE(N('fst'), A, forallE(N('snd'), B, constant(S))),
    induct: S, cidx: 0, numParams: 0, numFields: 2, isUnsafe: false,
  });
  env.add(axiom(N('s'), constant(S)));

  env.add({
    kind: 'inductive', name: Box, levelParams: [],
    type: forallE(N('A'), sort1, sort1),
    numParams: 1, numIndices: 0, all: [Box, BoxMk], ctors: [BoxMk],
    numNested: 0, isRec: false, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: BoxMk, levelParams: [],
    type: forallE(
      N('A'), sort1,
      forallE(N('value'), bvar(0), app(constant(Box), bvar(1))),
    ),
    induct: Box, cidx: 0, numParams: 1, numFields: 1, isUnsafe: false,
  });
  env.add(axiom(N('boxa'), app(constant(Box), A)));

  env.add({
    kind: 'inductive', name: ProofBox, levelParams: [], type: sort(levelZero),
    numParams: 0, numIndices: 0, all: [ProofBox, ProofBoxMk], ctors: [ProofBoxMk],
    numNested: 0, isRec: false, isUnsafe: false, isReflexive: false,
  });
  env.add({
    kind: 'constructor', name: ProofBoxMk, levelParams: [],
    type: forallE(N('data'), A, constant(ProofBox)),
    induct: ProofBox, cidx: 0, numParams: 0, numFields: 1, isUnsafe: false,
  });
  env.add(axiom(N('proofBox'), constant(ProofBox)));
  return env;
}

const expected = new Map();
{
  const env = makeEnv();
  const tc = new TypeChecker(env, new LocalContext());
  const S = N('S');
  const Box = N('Box');
  const ProofBox = N('ProofBox');
  const sCtor = mkAppN(constant(N('S.mk')), [constant(N('a')), constant(N('b'))]);
  const boxCtor = mkAppN(constant(N('Box.mk')), [constant(N('A')), constant(N('a'))]);

  expected.set('reduce-first', attempt(() => tc.whnf(proj(S, 0, sCtor))));
  expected.set('reduce-second', attempt(() => tc.whnf(proj(S, 1, sCtor))));
  expected.set('infer-first', attempt(() => tc.infer(proj(S, 0, constant(N('s'))), true)));
  expected.set('infer-second', attempt(() => tc.infer(proj(S, 1, constant(N('s'))), true)));
  expected.set('check-first', attempt(() => tc.check(proj(S, 0, constant(N('s'))))));
  expected.set('param-infer', attempt(() => tc.infer(proj(Box, 0, constant(N('boxa'))), true)));
  expected.set('param-reduce', attempt(() => tc.whnf(proj(Box, 0, boxCtor))));
  expected.set('bad-index', attempt(() => tc.infer(proj(S, 2, constant(N('s'))), true)));
  expected.set('wrong-name', attempt(() => tc.infer(proj(Box, 0, constant(N('s'))), true)));
  expected.set('proof-to-data', attempt(() => tc.infer(proj(ProofBox, 0, constant(N('proofBox'))), true)));
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

console.log(`PSCKERNEL_PROJECTION_BASIC_DIFFERENTIAL: PASS (${expected.size} projection parity cases, 0 deviations)`);
