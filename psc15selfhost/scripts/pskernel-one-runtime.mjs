import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'dist/pskernel-one');
const ts = path.join(out, 'KernelOne.ts');
const js = path.join(out, 'KernelOne.js');
const report = path.join(out, 'runtime-results.json');
if (fs.existsSync(js)) fs.unlinkSync(js);
if (fs.existsSync(report)) fs.unlinkSync(report);
const sha = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const compiler = process.env.TSC ?? 'npx';
const args = [ts, '--target', 'ES2022', '--module', 'ES2022', '--strict', '--noEmitOnError'];
if (!process.env.TSC) args.unshift('--no-install', 'tsc');
const result = spawnSync(compiler, args, {cwd: root, encoding: 'utf8', timeout: 120000});
fs.writeFileSync(path.join(out, 'tsc.log'), `${result.stdout ?? ''}${result.stderr ?? ''}`);
fs.writeFileSync(report, JSON.stringify({schema: 'pskernel-one-level-runtime/1',
  status: result.status === 0 ? 'compiled-not-executed' : 'tsc-failed',
  tscExitStatus: result.status, signal: result.signal, error: result.error?.message ?? null,
  results: 0, sourceSha256: sha(ts), node: process.version}, null, 2) + '\n');
assert.equal(result.status, 0, `Real TypeScript compiler failed:\n${result.stdout}\n${result.stderr}`);
const start = performance.now();
const m = await import(pathToFileURL(js));
const N = m.PsKernelOneName;
const L = m.PsKernelOneLevel;
const param = s => L.param(N.str(N.anonymous, s));
const u = param('u'), v = param('v'), w = param('w');
const focused = [
  ['max-reassociation', L.max(L.max(u, v), w), L.max(u, L.max(v, w)), true],
  ['max-permutation', L.max(L.max(u, v), w), L.max(w, L.max(v, u)), true],
  ['duplicate-leaf', L.max(u, L.max(v, u)), L.max(u, v), true],
  ['missing-parameter', L.max(L.max(u, v), w), L.max(u, v), false],
  ['different-parameter', L.max(u, v), L.max(u, w), false],
  ['successor-different', L.succ(u), u, false],
  ['imax-zero', L.imax(u, L.zero), L.zero, true],
  ['imax-not-max', L.imax(u, v), L.max(u, v), false],
  ['zero-identity', L.max(L.zero, L.max(u, v)), L.max(v, u), true],
  ['name-boundary', param('a.b'), L.param(N.str(N.str(N.anonymous, 'a'), 'b')), false],
  ['unicode-equal', param('a𝄞'), param('a𝄞'), true],
  ['unicode-different', param('a𝄞'), param('a𝄢'), false],
  ['numeric-name-width', L.param(N.num(N.anonymous, 9007199254740992n)), L.param(N.num(N.anonymous, 9007199254740993n)), false],
];
for (const [name, left, right, expected] of focused) assert.equal(m.psKernelOneLevelEquivalent(left, right), expected, name);
const corpus = [
  [L.zero, 0], [u, 1], [v, 2], [w, 4], [L.max(u, v), 3],
  [L.max(v, u), 3], [L.max(u, w), 5], [L.max(v, w), 6],
  [L.max(L.max(u, v), w), 7], [L.max(u, L.max(w, v)), 7],
  [L.max(w, L.max(v, u)), 7], [L.max(u, L.max(v, u)), 3],
];
for (const [a, am] of corpus) for (const [b, bm] of corpus) assert.equal(m.psKernelOneLevelEquivalent(a, b), am === bm);
fs.writeFileSync(report, JSON.stringify({schema: 'pskernel-one-level-runtime/1', status: 'passed',
  claims: 'Generated Name/Level foundation only; no declaration checker or fixed point', results: 157,
  node: process.version, corpusMillisecondsIncludingImport: performance.now() - start,
  memoryUsage: process.memoryUsage(), artifacts: ['KernelOne.lean', 'KernelOne.ps', 'KernelOne.ts', 'KernelOne.js'].map(name => {
    const file = path.join(out, name); return {path: name, sha256: sha(file), bytes: fs.statSync(file).size};
  })}, null, 2) + '\n');
console.log('PSKERNEL_ONE_LEVEL_RUNTIME: PASS (13 focused + 144 ordered pairs; generated foundation only)');
