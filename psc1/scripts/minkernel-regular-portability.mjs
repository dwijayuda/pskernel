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
const dir = 'dist/pskernel-min/regular';
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, 'package.json'), '{"type":"module"}\n');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const sources = [
  'packages/foundation/src/Ps/Foundation/Name.lean',
  'packages/pskernel-min/src/Ps/MinKernel/Profile/RegularProfile.lean',
  'packages/pskernel-min/src/Ps/MinKernel/Profile/RegularCheck.lean',
  'packages/pskernel-min/src/Ps/MinKernel/Profile/RegularNames.lean',
  'packages/pskernel-min/src/Ps/MinKernel/Tests/RegularVectors.lean',
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
run('lake', ['env', 'lean', '--run', 'scripts/MinKernelSourceCompile.lean', 'regular']);
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
assert.equal(typeof generated.psMinRegVector, 'function');
run('lake', ['build', 'minkernel_regular_tests'], undefined, 'packages/pskernel-min');
const nativeText = run('.lake/build/bin/minkernel_regular_tests', [], undefined, 'packages/pskernel-min');
fs.writeFileSync(path.join(dir, 'native-tests.log'), nativeText);
const nativeRows = [...nativeText.matchAll(/^PSC1_MIN_REGULAR_VECTOR ([0-9]+) (true|false)$/gm)]
  .map(match => ({ index: Number(match[1]), outcome: match[2] }));
const cases = [
  {
    "index": 0,
    "id": "empty-environment",
    "expectedOutcome": true
  },
  {
    "index": 1,
    "id": "identity-nat",
    "expectedOutcome": true
  },
  {
    "index": 2,
    "id": "boolean-literal",
    "expectedOutcome": true
  },
  {
    "index": 3,
    "id": "unit-literal",
    "expectedOutcome": true
  },
  {
    "index": 4,
    "id": "datatype-nullary",
    "expectedOutcome": true
  },
  {
    "index": 5,
    "id": "datatype-binary",
    "expectedOutcome": true
  },
  {
    "index": 6,
    "id": "owned-recursor-instance",
    "expectedOutcome": true
  },
  {
    "index": 7,
    "id": "owned-recursor-applied-nat",
    "expectedOutcome": true
  },
  {
    "index": 8,
    "id": "owned-recursor-applied-arr",
    "expectedOutcome": true
  },
  {
    "index": 9,
    "id": "regular-nat-list-constructor",
    "expectedOutcome": true
  },
  {
    "index": 10,
    "id": "regular-nat-list-eliminator",
    "expectedOutcome": true
  },
  {
    "index": 11,
    "id": "empty-datatype-elimination",
    "expectedOutcome": true
  },
  {
    "index": 12,
    "id": "recursive-only-constructor-function",
    "expectedOutcome": true
  },
  {
    "index": 13,
    "id": "recursive-only-empty-model",
    "expectedOutcome": true
  },
  {
    "index": 14,
    "id": "prior-function-field",
    "expectedOutcome": true
  },
  {
    "index": 15,
    "id": "older-datatype-slot",
    "expectedOutcome": true
  },
  {
    "index": 16,
    "id": "older-result-scope",
    "expectedOutcome": true
  },
  {
    "index": 17,
    "id": "sequential-constants",
    "expectedOutcome": true
  },
  {
    "index": 18,
    "id": "list-option-code-scope",
    "expectedOutcome": true
  },
  {
    "index": 19,
    "id": "type-equality",
    "expectedOutcome": true
  },
  {
    "index": 20,
    "id": "forward-constant",
    "expectedOutcome": false
  },
  {
    "index": 21,
    "id": "closed-unbound-variable",
    "expectedOutcome": false
  },
  {
    "index": 22,
    "id": "logical-empty-from-datatype",
    "expectedOutcome": false
  },
  {
    "index": 23,
    "id": "logical-empty-from-bool",
    "expectedOutcome": false
  },
  {
    "index": 24,
    "id": "missing-constructor",
    "expectedOutcome": false
  },
  {
    "index": 25,
    "id": "missing-family",
    "expectedOutcome": false
  },
  {
    "index": 26,
    "id": "missing-recursive-field",
    "expectedOutcome": false
  },
  {
    "index": 27,
    "id": "wrong-constructor-argument",
    "expectedOutcome": false
  },
  {
    "index": 28,
    "id": "wrong-minor-result",
    "expectedOutcome": false
  },
  {
    "index": 29,
    "id": "field-hypothesis-order",
    "expectedOutcome": false
  },
  {
    "index": 30,
    "id": "missing-minor-application",
    "expectedOutcome": false
  },
  {
    "index": 31,
    "id": "extra-minor-application",
    "expectedOutcome": false
  },
  {
    "index": 32,
    "id": "wrong-major-type",
    "expectedOutcome": false
  },
  {
    "index": 33,
    "id": "wrong-universe",
    "expectedOutcome": false
  },
  {
    "index": 34,
    "id": "higher-universe",
    "expectedOutcome": false
  },
  {
    "index": 35,
    "id": "forged-parameters",
    "expectedOutcome": false
  },
  {
    "index": 36,
    "id": "forged-indices",
    "expectedOutcome": false
  },
  {
    "index": 37,
    "id": "forged-motives",
    "expectedOutcome": false
  },
  {
    "index": 38,
    "id": "forged-minor-count",
    "expectedOutcome": false
  },
  {
    "index": 39,
    "id": "group-universes",
    "expectedOutcome": false
  },
  {
    "index": 40,
    "id": "group-parameters",
    "expectedOutcome": false
  },
  {
    "index": 41,
    "id": "group-indices",
    "expectedOutcome": false
  },
  {
    "index": 42,
    "id": "group-motives",
    "expectedOutcome": false
  },
  {
    "index": 43,
    "id": "group-minor-count",
    "expectedOutcome": false
  },
  {
    "index": 44,
    "id": "forward-data-field",
    "expectedOutcome": false
  },
  {
    "index": 45,
    "id": "negative-current-self-as-ground",
    "expectedOutcome": false
  },
  {
    "index": 46,
    "id": "out-of-scope-result-code",
    "expectedOutcome": false
  },
  {
    "index": 47,
    "id": "bad-annotation-data-slot",
    "expectedOutcome": false
  },
  {
    "index": 48,
    "id": "bad-lambda-domain-slot",
    "expectedOutcome": false
  },
  {
    "index": 49,
    "id": "no-base-datatype-cannot-fabricate-value",
    "expectedOutcome": false
  },
  {
    "index": 50,
    "id": "wrong-list-recursive-argument",
    "expectedOutcome": false
  },
  {
    "index": 51,
    "id": "type-equality-exhaustion",
    "expectedOutcome": false
  },
  {
    "index": 52,
    "id": "type-validation-exhaustion",
    "expectedOutcome": false
  },
  {
    "index": 53,
    "id": "registry-exhaustion",
    "expectedOutcome": false
  },
  {
    "index": 54,
    "id": "declaration-exhaustion",
    "expectedOutcome": false
  },
  {
    "index": 55,
    "id": "term-exhaustion",
    "expectedOutcome": false
  },
  {
    "index": 56,
    "id": "bad-second-declaration",
    "expectedOutcome": false
  }
];
assert.equal(nativeRows.length, cases.length + 2);
const observations = nativeRows.map((row, index) => {
  assert.equal(row.index, index);
  const expected = String(index < cases.length ? cases[index].expectedOutcome : false);
  assert.equal(row.outcome, expected, 'native regular case ' + index);
  const actual = generated.psMinRegVector(BigInt(index));
  assert.equal(String(actual), expected, 'generated regular case ' + index);
  return { ...row, id: cases[index]?.id ?? 'out-of-range-' + (index - cases.length),
    expected, generated: String(actual) };
});
for (const row of sourceIdentities) assert.equal(sha(fs.readFileSync(row.path)), row.sha256);
// The checked proof fixture must occur structurally in the *current* runtime
// source output. This diagnostic is not an acceptance whitelist or raw decoder.
run('lake', ['build', 'regular_core_witness'], undefined, 'proofs/pskernel-min');
const witnessText = run('.lake/build/bin/regular_core_witness', [], undefined, 'proofs/pskernel-min');
const witness = JSON.parse(witnessText);
fs.writeFileSync(path.join(dir, 'core-witness.json'), JSON.stringify(witness, null, 2) + '\n');
const currentAdmissions = fs.readFileSync('dist/pskernel-min/portable/vectors.admissions.json');
const currentWire = JSON.parse(currentAdmissions);
const currentOrigins = JSON.parse(fs.readFileSync('dist/pskernel-min/portable/vectors.source.json','utf8'));
const nameKey = name => {
  const parts=[];
  for(let i=0;i<1024;i++) {
    assert.ok(name && typeof name==='object');
    if(name.k==='a') return JSON.stringify(parts.reverse());
    assert.ok(name.k==='s'||name.k==='n');
    assert.equal(typeof name.v,'string');
    parts.push([name.k,name.v]);name=name.p;
  }
  assert.fail('oversize name');
};
const origin=currentOrigins.origins.find(o=>JSON.stringify(o.moduleName)===JSON.stringify(['Ps','MinKernel','Check']));
assert.ok(origin);
const batch=origin.batches.find(b=>JSON.stringify(b.sourceName)===JSON.stringify(['psMinTyEq']));
assert.ok(batch);
const worker=batch.members.find(m=>m.role==='normalizedWorker');
assert.ok(worker);
const recordIndex=currentWire.admissions.findIndex(a=>a.kind==='constant' && nameKey(a.declaration.n)===nameKey(worker.nameWire));
assert.ok(recordIndex>=0);
const sorted = value => Array.isArray(value) ? value.map(sorted) : value && typeof value==='object'
  ? Object.fromEntries(Object.keys(value).sort().map(k=>[k,sorted(value[k])])) : value;
const witnessKey=JSON.stringify(sorted(witness));
const occurrences=[];
function children(e) {
  switch(e.k) {
    case 'app':return [['f',e.f],['a',e.a]];
    case 'lam':case 'forall':return [['t',e.t],['b',e.b]];
    case 'let':return [['t',e.t],['v',e.v],['b',e.b]];
    case 'proj':return [['e',e.e]];
    case 'const':case 'b':case 'sort':case 'nat':case 'str':return [];
    default:assert.fail('unknown current Core tag '+e.k);
  }
}
const pending=[[currentWire.admissions[recordIndex].declaration.v,'v']];
while(pending.length) {
  const [node,location]=pending.pop();
  if(JSON.stringify(sorted(node))===witnessKey) occurrences.push({record:recordIndex,path:location});
  for(const[field,child]of children(node))pending.push([child,location+'.'+field]);
}
assert.equal(occurrences.length,1,'checked source witness must occur uniquely in actual origin-bound worker');
const sourceWitness={authoritative:false,scope:'exact current source occurrence and proved representative; not general canonical admission',
  currentAdmissionsSha256:sha(currentAdmissions),worker:worker.nameWire,occurrences,witnessSha256:sha(Buffer.from(witnessText))};
fs.writeFileSync(path.join(dir,'source-witness.json'),JSON.stringify(sourceWitness,null,2)+'\n');
const receipt = { schema: 'psc1-min-regular-portability/1', commit: process.env.GITHUB_SHA,
  authoritative: false, canonicalAdmission: false, sourceIdentities,
  checkerExplicitImportClosureModules: 2, completeTestClosureModules: 5,
  testOnlySourceModules: ['Ps.Foundation.Name','Ps.MinKernel.Profile.RegularNames','Ps.MinKernel.Tests.RegularVectors'], sourceReport,
  canonicalAdmissionSha256: sha(admissionBytes), officialSourceAdmission: official,
  officialCheckerSha256: sha(fs.readFileSync('.lake/build/bin/psc1_independent_checker')),
  sourceCompileDriverSha256: sha(fs.readFileSync('scripts/MinKernelSourceCompile.lean')),
  payloadScope: 'Entire five-module profile test bundle; not isolated checker payload',
  generatedTsBytes: fs.statSync(stem + '.ts').size,
  generatedJsBytes: fs.statSync(stem + '.js').size,
  generatedJsSha256: sha(fs.readFileSync(stem + '.js')),
  positiveCases: 20, refusalCases: 37, outOfRangeProbes: 2,
  observations, sourceWitness, comparison: 'normalized-profile expected acceptance/refusal plus native/generated equality',
  theoremBoundary: 'Safe Lean normalized-profile inference/admission has a model and consistency proof; generated-code/canonical translation preservation is not formally proved',
  resourceBoundary: 'Structural recursion on finite Lean values; aggregate size, host stack and hostile JS objects are not qualified',
  canonicalMinDual: 'still unsupported; this helper grants no checking authority' };
fs.writeFileSync(path.join(dir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
console.log('PSC1_MIN_REGULAR_PORTABLE_PASS ' + JSON.stringify(receipt));
