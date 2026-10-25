// Host-boundary replay fixtures prepared by the real native service.
// These tests are not generated compiler execution or semantic qualification.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { createGeneratedJsCompilerSession } from '../host-tools/generated-compiler-session.mjs';
import { boundedRun, sha } from '../host-tools/generated-target-tools.mjs';
const directory = path.resolve('dist/output-abi/host-boundary');
fs.mkdirSync(directory, { recursive: true });
const reference = JSON.parse(fs.readFileSync('dist/output-abi/native-reference.json'));
const item = reference.requestInventory.find(row => row.request[1] === 'lean-checked'
  && row.request[0] === 'psc1-compiler-service/2' && row.status === 'candidate');
assert.ok(item);
const input = path.join(directory, 'native-request.json'), output = path.join(directory, 'native-candidate.json');
fs.writeFileSync(input, JSON.stringify(item.request));
const preparation = boundedRun('prlimit', ['--as=4294967296', '--stack=8388608', '--',
  path.resolve('.lake/build/bin/psc1_output_abi_probe'), 'js', input, output], {
  timeoutMs: 240000, timeoutPolicy: 'standard-240s',
  env: { ...process.env, LEAN_MAIN_USE_THREAD: '0', LEAN_NUM_THREADS: '0', LEAN_STACK_SIZE_KB: '8192' },
});
assert.equal(preparation.status, 0, preparation.stderr);
const candidate = JSON.parse(fs.readFileSync(output));
assert.equal(sha(JSON.stringify(candidate)), item.candidateSha256);
const sources = item.request[6].map(([module, text]) => ({ module, kind: 'lean', text }));
const checker = path.resolve('.lake/build/bin/psc1_independent_checker');
const runner = path.resolve('scripts/generated-compiler-runner.mjs'), root = path.join(directory, 'store');
let serial = 0;
function session(mutation = '', outputAbi = 'io-dispatcher') {
  const id = 'output-abi-host-' + serial++, file = path.join(directory, id + '.mjs');
  fs.writeFileSync(file, 'const template=' + JSON.stringify(candidate) + ';\n' +
    'export function psCompilerJsServiceCandidate(input){const wire=JSON.parse(input), value=structuredClone(template);' +
    'value.requestId=wire[1];value.admissionRequest.requestId=wire[1];' + mutation + ';return JSON.stringify(value);}\n');
  return createGeneratedJsCompilerSession({ requestId: id, sources, entryModule: 'Entry',
    assurance: 'checked', outputAbi, serviceFile: file, serviceSha256: sha(fs.readFileSync(file)),
    runnerFile: runner, runnerSha256: sha(fs.readFileSync(runner)),
    checkerExecutable: checker, checkerSha256: sha(fs.readFileSync(checker)), publicationRoot: root });
}
const accepted = session(), receipt = accepted.execute();
assert.equal(receipt.outputAbi, 'io-dispatcher');
assert.equal(receipt.logicalAdmission, 'accepted');
const published = accepted.publish(), prior = fs.readlinkSync(path.join(root, 'current'));
assert.equal(prior, 'generations/' + published.generation);
const records = [];
for (const [name, mutation, pattern] of [
  ['protocol downgrade', 'value.protocol="psc1-compiler-service/1"', /RESPONSE_MISMATCH:protocol/],
  ['ABI mismatch', 'value.outputAbi="scalar"', /RESPONSE_MISMATCH:outputAbi/],
  ['missing ABI', 'delete value.outputAbi', /RESPONSE_FIELDS/],
  ['injected authority field', 'value.capabilities=["writeUtf8"]', /RESPONSE_FIELDS/],
  ['changed source identity', 'value.sourceClosureDigest="wrong"', /RESPONSE_MISMATCH:sourceClosureDigest/],
  ['checker rejection', 'value.admissionRequest.admissions="{}"', /PSC1_CHECKER_REJECTED/],
  ['invalid output syntax', 'value.source="export const = ;"', /PROCESS_FAILED:target-syntax/],
  ['extra public export', 'value.source+="\\nexport const unplanned=0n;\\n"', /PROCESS_FAILED:target-public-api/],
]) {
  const selected = session(mutation);
  assert.throws(() => selected.execute(), pattern, name);
  assert.equal(selected.state, 'rejected');
  assert.throws(() => selected.publish(), /NOT_ADMITTED/);
  assert.equal(fs.readlinkSync(path.join(root, 'current')), prior);
  records.push({ name, priorPreserved: true });
}
assert.throws(() => session('', 'unknown'), /REQUEST_INVALID/);
const scalar = session('', 'scalar');
assert.equal(Object.hasOwn(scalar.request, 'outputAbi'), false);
assert.throws(() => scalar.execute(), /RESPONSE_FIELDS/);
assert.equal(fs.readlinkSync(path.join(root, 'current')), prior);
records.push({ name: 'unknown ABI rejected before execution', priorPreserved: true },
  { name: 'explicit IO candidate cannot enter scalar session', priorPreserved: true });
fs.writeFileSync(path.join(directory, 'qualification.json'), JSON.stringify({
  schema: 'psc1-output-abi-host-boundary/1', testedCommit: process.env.GITHUB_SHA,
  status: 'passed', compilerSemantics: 'native-prepared replay only', negatives: records.length,
  logicalAdmission: 'actual official Lean 4.35.0', priorGeneration: published.generation, records,
}, null, 2) + '\n');
console.log('PSC1_OUTPUT_ABI_HOST_BOUNDARY: PASS ' + JSON.stringify({ negatives: records.length }));
