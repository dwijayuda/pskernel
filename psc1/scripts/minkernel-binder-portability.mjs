// Linux Actions only: syntax transformation qualification, never logical admission.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { resolveTypeScriptCli, typeScriptProfileArgs } from './typescript-cli.mjs';

assert.equal(process.platform, 'linux');
assert.match(process.env.GITHUB_SHA || '', /^[a-f0-9]{40}$/);
const dir = 'dist/pskernel-min/binder';
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, 'package.json'), '{"type":"module"}\n');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const sources = [
  'packages/foundation/src/Ps/Foundation/Name.lean',
  'packages/core/src/Ps/Core/Level.lean',
  'packages/core/src/Ps/Core/Expr.lean',
  'packages/core/src/Ps/Core/Equality.lean',
  'packages/pskernel-min/src/Ps/MinKernel/Profile/LowerUnusedBinder.lean',
  'packages/pskernel-min/src/Ps/MinKernel/Tests/BinderVectors.lean',
];
const sourceIdentities = sources.map(file => ({ path: file,
  sha256: sha(fs.readFileSync(file)), bytes: fs.statSync(file).size }));
function run(command, args, input, cwd) {
  const result = spawnSync(command, args, { input, cwd, encoding: 'utf8',
    timeout: 240000, maxBuffer: 32 * 1024 * 1024 });
  assert.equal(result.error, undefined, String(result.error));
  assert.equal(result.status, 0, result.stdout + '\n' + result.stderr);
  return result.stdout;
}
run('lake', ['env', 'lean', '--run', 'scripts/MinKernelSourceCompile.lean', 'binder']);
const stem = path.join(dir, 'vectors');
const admissionBytes = fs.readFileSync(stem + '.admissions.json');
const official = JSON.parse(run('.lake/build/bin/psc1_independent_checker', ['--check'], admissionBytes));
assert.equal(official.accepted, true);
assert.equal(official.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const sourceReport = JSON.parse(fs.readFileSync(stem + '.source.json', 'utf8'));
assert.equal(sourceReport.schema, 'psc1-min-source-compile/2');
assert.equal(sourceReport.moduleCount, 6);
assert.equal(sourceReport.origins.length, 6);
assert.equal(sourceReport.providerChecked, false);
run(process.execPath, [resolveTypeScriptCli(), ...typeScriptProfileArgs([
  stem + '.ts', '--target', 'ES2022', '--module', 'ES2022', '--moduleResolution', 'bundler',
  '--strict', '--skipLibCheck', '--noEmitOnError', '--pretty', 'false'])]);
const generated = await import(pathToFileURL(path.resolve(stem + '.js')).href);
assert.equal(typeof generated.psMinBinderVector, 'function');
run('lake', ['build', 'minkernel_binder_tests'], undefined, 'packages/pskernel-min');
const nativeText = run('.lake/build/bin/minkernel_binder_tests', [], undefined, 'packages/pskernel-min');
fs.writeFileSync(path.join(dir, 'native-tests.log'), nativeText);
const nativeRows = [...nativeText.matchAll(/^PSC1_MIN_BINDER_VECTOR ([0-9]+) ([0-9]+)$/gm)]
  .map(match => ({ index: Number(match[1]), outcome: match[2] }));
const cases = [
  {
    "index": 0,
    "id": "outer-reference",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 1,
    "id": "inner-reference",
    "depth": 1,
    "expectedOutcome": 1
  },
  {
    "index": 2,
    "id": "sort",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 3,
    "id": "free-syntax-preserved",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 4,
    "id": "meta-syntax-preserved",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 5,
    "id": "constant-levels-preserved",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 6,
    "id": "natural-literal",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 7,
    "id": "string-literal",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 8,
    "id": "application-outer-references",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 9,
    "id": "lambda-local-binder",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 10,
    "id": "lambda-outer-body",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 11,
    "id": "lambda-domain-outer",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 12,
    "id": "pi-domain-and-body-outer",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 13,
    "id": "pi-local-binder",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 14,
    "id": "let-three-contexts",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 15,
    "id": "let-local-body-binder",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 16,
    "id": "projection-receiver",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 17,
    "id": "nested-local-binder",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 18,
    "id": "nested-outer-reference",
    "depth": 0,
    "expectedOutcome": 1
  },
  {
    "index": 19,
    "id": "nonzero-cutoff-outer",
    "depth": 3,
    "expectedOutcome": 1
  },
  {
    "index": 20,
    "id": "nonzero-cutoff-inner",
    "depth": 3,
    "expectedOutcome": 1
  },
  {
    "index": 21,
    "id": "reject-root",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 22,
    "id": "reject-nonzero-cutoff",
    "depth": 3,
    "expectedOutcome": 0
  },
  {
    "index": 23,
    "id": "reject-app-function",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 24,
    "id": "reject-app-argument",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 25,
    "id": "reject-lambda-domain",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 26,
    "id": "reject-lambda-body",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 27,
    "id": "reject-pi-domain",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 28,
    "id": "reject-pi-body",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 29,
    "id": "reject-let-type",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 30,
    "id": "reject-let-value",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 31,
    "id": "reject-let-body",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 32,
    "id": "reject-projection-receiver",
    "depth": 0,
    "expectedOutcome": 0
  },
  {
    "index": 33,
    "id": "reject-under-two-binders",
    "depth": 0,
    "expectedOutcome": 0
  }
];
assert.equal(nativeRows.length, cases.length + 2);
const observations = nativeRows.map((row, index) => {
  assert.equal(row.index, index);
  const expected = String(index < cases.length ? cases[index].expectedOutcome : 3);
  assert.equal(row.outcome, expected, 'native binder case ' + index);
  const actual = generated.psMinBinderVector(BigInt(index));
  assert.equal(String(actual), expected, 'generated binder case ' + index);
  return { ...row, id: cases[index]?.id ?? 'out-of-range-' + (index - cases.length),
    expected, generated: String(actual) };
});
for (const row of sourceIdentities) assert.equal(sha(fs.readFileSync(row.path)), row.sha256);
const receipt = { schema: 'psc1-min-binder-portability/1', commit: process.env.GITHUB_SHA,
  authoritative: false, logicalAdmission: false, sourceIdentities,
  helperExplicitImportClosureModules: 4, completeTestClosureModules: 6,
  testOnlyAdditionalModule: 'Ps.Core.Equality', sourceReport,
  canonicalAdmissionSha256: sha(admissionBytes), officialSourceAdmission: official,
  generatedTsBytes: fs.statSync(stem + '.ts').size,
  generatedJsBytes: fs.statSync(stem + '.js').size,
  generatedJsSha256: sha(fs.readFileSync(stem + '.js')),
  positiveTransformations: 21, refusalTransformations: 13, outOfRangeProbes: 2,
  observations, comparison: 'finite expected alpha-shapes plus native/generated outcome equality',
  theoremBoundary: 'Safe Lean helper success has an exact lifting inverse; generated-code preservation is not formally proved',
  resourceBoundary: 'Structural recursion on finite Lean values; aggregate size, host stack and hostile JS objects are not qualified',
  canonicalMinDual: 'still unsupported; this helper grants no checking authority' };
fs.writeFileSync(path.join(dir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_MIN_BINDER_PORTABLE_PASS ' + JSON.stringify(receipt));
