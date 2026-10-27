// Linux Actions only: normalized-profile qualification; never production canonical admission.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { resolveTypeScriptCli, typeScriptProfileArgs } from './typescript-cli.mjs';

assert.equal(process.platform, 'linux');
assert.match(process.env.GITHUB_SHA || '', /^[a-f0-9]{40}$/);
const dir = 'dist/pskernel-min/operational';
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, 'package.json'), '{"type":"module"}\n');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const sources = [
 'packages/pskernel-min/src/Ps/MinKernel/Profile/RegularProfile.lean',
 'packages/pskernel-min/src/Ps/MinKernel/Profile/RegularCheck.lean',
 'packages/pskernel-min/src/Ps/MinKernel/Profile/OperationalProfile.lean',
 'packages/pskernel-min/src/Ps/MinKernel/Profile/OperationalCheck.lean',
 'packages/pskernel-min/src/Ps/MinKernel/Tests/OperationalVectors.lean',
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
run('lake', ['env', 'lean', '--run', 'scripts/MinKernelSourceCompile.lean', 'operational']);
const stem = path.join(dir, 'vectors');
const admissionBytes = fs.readFileSync(stem + '.admissions.json');
const official = JSON.parse(run('.lake/build/bin/psc1_independent_checker', ['--check'], admissionBytes));
assert.equal(official.accepted, true);
assert.equal(official.protocol, 'pskernel-lean/1');
assert.equal(official.provider, 'lean4-cpp');
assert.equal(official.leanVersion, '4.35.0');
assert.equal(official.profile, 'lean4.35-core');
assert.equal(official.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const sourceReport = JSON.parse(fs.readFileSync(stem + '.source.json', 'utf8'));
assert.equal(sourceReport.schema, 'psc1-min-source-compile/2');
assert.equal(sourceReport.moduleCount, 5);
assert.equal(sourceReport.origins.length, 5);
assert.equal(sourceReport.providerChecked, false);
run(process.execPath, [resolveTypeScriptCli(), ...typeScriptProfileArgs([
  stem + '.ts', '--target', 'ES2022', '--module', 'ES2022', '--moduleResolution', 'bundler',
  '--strict', '--skipLibCheck', '--noEmitOnError', '--pretty', 'false'])]);
const generated = await import(pathToFileURL(path.resolve(stem + '.js')).href);
assert.equal(typeof generated.psMinOpVector, 'function');
run('lake', ['build', 'minkernel_operational_tests'], undefined, 'packages/pskernel-min');
const nativeText = run('.lake/build/bin/minkernel_operational_tests', [], undefined, 'packages/pskernel-min');
fs.writeFileSync(path.join(dir, 'native-tests.log'), nativeText);
const nativeRows = [...nativeText.matchAll(/^PSC1_MIN_OPERATIONAL_VECTOR ([0-9]+) (true|false)$/gm)]
  .map(match => ({ index: Number(match[1]), outcome: match[2] }));
const cases = [
  {
    "index": 0,
    "id": "empty-environment",
    "expectedOutcome": true
  },
  {
    "index": 1,
    "id": "base-old-checker",
    "expectedOutcome": true
  },
  {
    "index": 2,
    "id": "let-local-binding",
    "expectedOutcome": true
  },
  {
    "index": 3,
    "id": "let-nested-scope",
    "expectedOutcome": true
  },
  {
    "index": 4,
    "id": "lambda-let",
    "expectedOutcome": true
  },
  {
    "index": 5,
    "id": "actual-spec-projection-field-0",
    "expectedOutcome": true
  },
  {
    "index": 6,
    "id": "actual-spec-projection-field-1",
    "expectedOutcome": true
  },
  {
    "index": 7,
    "id": "actual-spec-projection-field-2",
    "expectedOutcome": true
  },
  {
    "index": 8,
    "id": "actual-spec-projection-field-3",
    "expectedOutcome": true
  },
  {
    "index": 9,
    "id": "actual-spec-projection-field-4",
    "expectedOutcome": true
  },
  {
    "index": 10,
    "id": "actual-spec-projection-field-5",
    "expectedOutcome": true
  },
  {
    "index": 11,
    "id": "actual-declaration-projection-field-0",
    "expectedOutcome": true
  },
  {
    "index": 12,
    "id": "actual-declaration-projection-field-1",
    "expectedOutcome": true
  },
  {
    "index": 13,
    "id": "actual-spec-constructed-projected",
    "expectedOutcome": true
  },
  {
    "index": 14,
    "id": "actual-declaration-constructed-projected",
    "expectedOutcome": true
  },
  {
    "index": 15,
    "id": "let-bound-actual-declaration-projection",
    "expectedOutcome": true
  },
  {
    "index": 16,
    "id": "natSucc",
    "expectedOutcome": true
  },
  {
    "index": 17,
    "id": "natPred",
    "expectedOutcome": true
  },
  {
    "index": 18,
    "id": "natAdd",
    "expectedOutcome": true
  },
  {
    "index": 19,
    "id": "natSub",
    "expectedOutcome": true
  },
  {
    "index": 20,
    "id": "natBeq",
    "expectedOutcome": true
  },
  {
    "index": 21,
    "id": "natBlt",
    "expectedOutcome": true
  },
  {
    "index": 22,
    "id": "boolNot",
    "expectedOutcome": true
  },
  {
    "index": 23,
    "id": "boolBeq",
    "expectedOutcome": true
  },
  {
    "index": 24,
    "id": "nat-add-application",
    "expectedOutcome": true
  },
  {
    "index": 25,
    "id": "nat-recursion",
    "expectedOutcome": true
  },
  {
    "index": 26,
    "id": "list-nil",
    "expectedOutcome": true
  },
  {
    "index": 27,
    "id": "list-cons",
    "expectedOutcome": true
  },
  {
    "index": 28,
    "id": "list-recursion",
    "expectedOutcome": true
  },
  {
    "index": 29,
    "id": "option-none",
    "expectedOutcome": true
  },
  {
    "index": 30,
    "id": "option-some",
    "expectedOutcome": true
  },
  {
    "index": 31,
    "id": "option-recursion",
    "expectedOutcome": true
  },
  {
    "index": 32,
    "id": "bool-eq-ite-equal",
    "expectedOutcome": true
  },
  {
    "index": 33,
    "id": "bool-eq-ite-distinct",
    "expectedOutcome": true
  },
  {
    "index": 34,
    "id": "bool-eq-ite-dynamic",
    "expectedOutcome": true
  },
  {
    "index": 35,
    "id": "sequential-body-reference",
    "expectedOutcome": true
  },
  {
    "index": 36,
    "id": "let-value-cannot-see-new-binder",
    "expectedOutcome": false
  },
  {
    "index": 37,
    "id": "let-wrong-annotation",
    "expectedOutcome": false
  },
  {
    "index": 38,
    "id": "let-bad-body-scope",
    "expectedOutcome": false
  },
  {
    "index": 39,
    "id": "let-invalid-type-code",
    "expectedOutcome": false
  },
  {
    "index": 40,
    "id": "let-cannot-forge-empty",
    "expectedOutcome": false
  },
  {
    "index": 41,
    "id": "projection-refuses-0-2",
    "expectedOutcome": false
  },
  {
    "index": 42,
    "id": "projection-refuses-2-6",
    "expectedOutcome": false
  },
  {
    "index": 43,
    "id": "projection-refuses-1-0",
    "expectedOutcome": false
  },
  {
    "index": 44,
    "id": "projection-refuses-3-0",
    "expectedOutcome": false
  },
  {
    "index": 45,
    "id": "projection-refuses-4-0",
    "expectedOutcome": false
  },
  {
    "index": 46,
    "id": "projection-refuses-9-0",
    "expectedOutcome": false
  },
  {
    "index": 47,
    "id": "projection-wrong-owner-major",
    "expectedOutcome": false
  },
  {
    "index": 48,
    "id": "projection-wrong-field-type",
    "expectedOutcome": false
  },
  {
    "index": 49,
    "id": "nat-add-wrong-argument",
    "expectedOutcome": false
  },
  {
    "index": 50,
    "id": "list-cons-wrong-tail",
    "expectedOutcome": false
  },
  {
    "index": 51,
    "id": "option-some-wrong-value",
    "expectedOutcome": false
  },
  {
    "index": 52,
    "id": "list-minor-wrong-field-order",
    "expectedOutcome": false
  },
  {
    "index": 53,
    "id": "nat-minor-wrong-result",
    "expectedOutcome": false
  },
  {
    "index": 54,
    "id": "option-minor-wrong-domain",
    "expectedOutcome": false
  },
  {
    "index": 55,
    "id": "ite-proposition-is-bool-equality",
    "expectedOutcome": false
  },
  {
    "index": 56,
    "id": "ite-wrong-branch-type",
    "expectedOutcome": false
  },
  {
    "index": 57,
    "id": "bare-proof-cannot-forge-empty",
    "expectedOutcome": false
  },
  {
    "index": 58,
    "id": "wrong-nat-level",
    "expectedOutcome": false
  },
  {
    "index": 59,
    "id": "wrong-nat-parameters",
    "expectedOutcome": false
  },
  {
    "index": 60,
    "id": "forged-indices",
    "expectedOutcome": false
  },
  {
    "index": 61,
    "id": "wrong-nat-rec-level",
    "expectedOutcome": false
  },
  {
    "index": 62,
    "id": "wrong-nat-rec-motives",
    "expectedOutcome": false
  },
  {
    "index": 63,
    "id": "wrong-nat-rec-minors",
    "expectedOutcome": false
  },
  {
    "index": 64,
    "id": "wrong-list-type-arity",
    "expectedOutcome": false
  },
  {
    "index": 65,
    "id": "wrong-list-rec-type-arity",
    "expectedOutcome": false
  },
  {
    "index": 66,
    "id": "wrong-option-minors",
    "expectedOutcome": false
  },
  {
    "index": 67,
    "id": "ite-forged-motive",
    "expectedOutcome": false
  },
  {
    "index": 68,
    "id": "ite-forged-minors",
    "expectedOutcome": false
  },
  {
    "index": 69,
    "id": "ite-wrong-level",
    "expectedOutcome": false
  },
  {
    "index": 70,
    "id": "primitive-forward-type-slot",
    "expectedOutcome": false
  },
  {
    "index": 71,
    "id": "recursor-forward-result-slot",
    "expectedOutcome": false
  },
  {
    "index": 72,
    "id": "forward-constant",
    "expectedOutcome": false
  },
  {
    "index": 73,
    "id": "term-fuel-refusal",
    "expectedOutcome": false
  },
  {
    "index": 74,
    "id": "declaration-fuel-refusal",
    "expectedOutcome": false
  },
  {
    "index": 75,
    "id": "registry-fuel-refusal",
    "expectedOutcome": false
  }
];
assert.equal(nativeRows.length, cases.length + 2);
const observations = nativeRows.map((row, index) => {
  assert.equal(row.index, index);
  const expected = String(index < cases.length ? cases[index].expectedOutcome : false);
  assert.equal(row.outcome, expected, 'native regular case ' + index);
  const actual = generated.psMinOpVector(BigInt(index));
  assert.equal(String(actual), expected, 'generated regular case ' + index);
  return { ...row, id: cases[index]?.id ?? 'out-of-range-' + (index - cases.length),
    expected, generated: String(actual) };
});
for (const row of sourceIdentities) assert.equal(sha(fs.readFileSync(row.path)), row.sha256);
const receipt = { schema: 'psc1-min-operational-portability/1', commit: process.env.GITHUB_SHA,
  authoritative: false, canonicalAdmission: false, sourceIdentities,
  checkerExplicitImportClosureModules: 4, completeTestClosureModules: 5,
  testOnlySourceModules: ['Ps.MinKernel.Tests.OperationalVectors'], sourceReport,
  canonicalAdmissionSha256: sha(admissionBytes), officialSourceAdmission: official,
  officialCheckerSha256: sha(fs.readFileSync('.lake/build/bin/psc1_independent_checker')),
  sourceCompileDriverSha256: sha(fs.readFileSync('scripts/MinKernelSourceCompile.lean')),
  payloadScope: 'Entire five-module profile test bundle; not isolated checker payload',
  generatedTsBytes: fs.statSync(stem + '.ts').size,
  generatedJsBytes: fs.statSync(stem + '.js').size,
  generatedJsSha256: sha(fs.readFileSync(stem + '.js')),
  positiveCases: 36, refusalCases: 40, outOfRangeProbes: 2,
  observations, comparison: 'operational-profile expected acceptance/refusal plus native/generated equality',
  theoremBoundary: 'Safe Lean normalized-profile inference/admission has a model and consistency proof; generated-code/canonical translation preservation is not formally proved',
  resourceBoundary: 'Structural recursion on finite Lean values; aggregate size, host stack and hostile JS objects are not qualified',
  canonicalMinDual: 'still unsupported; this helper grants no checking authority' };
fs.writeFileSync(path.join(dir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_MIN_OPERATIONAL_PORTABLE_PASS ' + JSON.stringify(receipt));
