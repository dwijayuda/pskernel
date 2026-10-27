// Executes the exact portable checker source using PSC1; Linux Actions only.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { performance } from 'node:perf_hooks';
import { resolveTypeScriptCli, typeScriptProfileArgs } from './typescript-cli.mjs';

assert.equal(process.platform, 'linux');
assert.match(process.env.GITHUB_SHA || '', /^[a-f0-9]{40}$/);
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const dir = 'dist/pskernel-min/portable';
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, 'package.json'), '{"type":"module"}\n');
const sources = ['packages/pskernel-min/src/Ps/MinKernel/Check.lean',
  'packages/pskernel-min/src/Ps/MinKernel/Tests/Vectors.lean'];
const sourceIdentities = sources.map(file => ({ path: file, sha256: sha(fs.readFileSync(file)),
  bytes: fs.statSync(file).size, lines: fs.readFileSync(file, 'utf8').trimEnd().split('\n').length }));
function run(command, args, input) {
  const result = spawnSync(command, args, { input, encoding: 'utf8', timeout: 240000,
    maxBuffer: 32 * 1024 * 1024 });
  assert.equal(result.error, undefined, String(result.error));
  assert.equal(result.status, 0, result.stdout + '\n' + result.stderr);
  return result.stdout;
}
const stem = path.join(dir, 'vectors');
const started = performance.now();
run('lake', ['env', 'lean', '--run', 'scripts/MinKernelSourceCompile.lean']);
const compileMs = performance.now() - started;
const admissions = fs.readFileSync(stem + '.admissions.json', 'utf8');
const checker = '.lake/build/bin/psc1_independent_checker';
const checkStarted = performance.now();
const official = JSON.parse(run(checker, ['--check'], admissions));
assert.equal(official.accepted, true);
assert.equal(official.provider, 'lean4-cpp');
assert.equal(official.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const officialSourceAdmissionMs = performance.now() - checkStarted;
run(process.execPath, [resolveTypeScriptCli(), ...typeScriptProfileArgs([
  stem + '.ts', '--target', 'ES2022', '--module', 'ES2022', '--moduleResolution', 'bundler',
  '--strict', '--skipLibCheck', '--noEmitOnError', '--pretty', 'false'])]);
const cold = performance.now();
const module = await import(pathToFileURL(path.resolve(stem + '.js')).href);
const exportName = Object.keys(module).filter(key => /rawVector$/.test(key));
assert.equal(exportName.length, 1, 'exact unique portable vector export; exports=' + Object.keys(module));
const vector = module[exportName[0]];
const observations = [];
for (let index = 0; index < 16; index++) {
  const value = vector(BigInt(index));
  assert.equal(value, index < 5, 'portable semantic vector ' + index);
  observations.push({ index, accepted: value });
}
const coldImportAndVectorsMs = performance.now() - cold;
// Finite, explicitly paired STLC/Core fixtures. This encoding is tested here;
// no theorem about a general PSC1 canonical-to-fragment translation is implied.
const name = value => ({ k: 's', p: { k: 'a' }, v: value });
const nat = { k: 'const', n: name('Nat'), ls: [] };
const literal = value => ({ k: 'nat', v: String(value) });
const bound = { k: 'b', i: 0 };
const lambda = { k: 'lam', n: name('x'), bi: 'default', t: nat, b: bound };
const arrow = { k: 'forall', n: name('x'), bi: 'default', t: nat, b: nat };
const constant = value => ({ k: 'const', n: name(value), ls: [] });
const declaration = (n, v, t = nat) => ({ kind: 'constant', declaration: {
  k: 'definition', h: { k: 'regular', h: '1' }, lp: [], n: name(n), s: 'safe', t, v } });
const fixtures = [
  { index: 0, id: 'empty-environment', declarations: [] },
  { index: 1, id: 'nat-identity', declarations: [declaration('Min.Id', lambda, arrow)] },
  { index: 2, id: 'sequential-prior-constant', declarations: [declaration('Min.A', literal(7)),
    declaration('Min.B', constant('Min.A'))] },
  { index: 4, id: 'beta-application', declarations: [declaration('Min.Apply',
    { k: 'app', f: lambda, a: literal(7) })] },
  { index: 8, id: 'forward-reference-refusal', declarations: [declaration('Min.Future', constant('Min.Future'))] },
];
const differential = fixtures.map(fixture => {
  const input = JSON.stringify({ protocol: 'pskernel-lean/1', format: 'proofscript-checked-admissions',
    version: 2, admissions: fixture.declarations });
  const before = performance.now();
  const result = JSON.parse(run(checker, ['--check'], input));
  assert.equal(result.leanCommit, official.leanCommit);
  const nativeProcessMs = performance.now() - before;
  const beforeMin = performance.now();
  const accepted = vector(BigInt(fixture.index));
  const generatedInProcessMs = performance.now() - beforeMin;
  assert.equal(result.accepted, accepted, fixture.id);
  return { id: fixture.id, accepted, canonicalSha256: sha(input), nativeProcessMs, generatedInProcessMs };
});
const warm = performance.now();
for (let iteration = 0; iteration < 10000; iteration++)
  for (let index = 0; index < 16; index++) assert.equal(vector(BigInt(index)), index < 5);
const warm160000VectorsMs = performance.now() - warm;
for (const row of sourceIdentities) assert.equal(sha(fs.readFileSync(row.path)), row.sha256);
const receipt = { schema: 'psc1-min-kernel-portability/1', commit: process.env.GITHUB_SHA,
  sourceIdentities, checkerSourceModules: 1, runtimeProofImports: 0,
  generatedVectorExport: exportName[0], observations, generatedTsBytes: fs.statSync(stem + '.ts').size,
  generatedJsBytes: fs.statSync(stem + '.js').size, generatedJsSha256: sha(fs.readFileSync(stem + '.js')),
  admissionsSha256: sha(admissions), officialCheckerSha256: sha(fs.readFileSync(checker)),
  officialSourceAdmission: official, differential, compileMs, officialSourceAdmissionMs,
  coldImportAndVectorsMs, warm160000VectorsMs, memoryUsage: process.memoryUsage(),
  nativeCheckerSource: 'actual current PSC1 source compiler; not a generated compiler generation',
  trust: 'Lean-to-IR/backend preservation is empirically exercised, not formally proved',
  selfHost: 'not-qualified: generated checker does not admit the compiler dependency graph',
  performanceScope: 'test harness includes fixtures/assertions; not a PSC1 graph-check benchmark' };
fs.writeFileSync(path.join(dir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_MIN_PORTABLE_PASS ' + JSON.stringify(receipt));
