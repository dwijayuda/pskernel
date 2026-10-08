import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import { artifactId, canonicalArtifact } from './artifact-evidence.mjs';
import { validateWasmLiteralBinary } from './wasm-literal-binary-validator.mjs';
import { wasmLiteralCertificateChecker } from './wasm-literal-certificate.mjs';
import { createCertificateBoundary } from './certificate-boundary.mjs';

const expected = entries => canonicalArtifact({ contract: 'psc-wasm-literal-expectation/1', exports: entries },
  'wasm-literal-expectation', 'psc-wasm-literal-expectation/1');
const answer = expected([{ name: 'answer', type: 'uint32', value: '42' }]);
// Independently written minimal MVP module. Its bytes are not obtained from
// this validator or PSC's encoder; the second test exercises the real encoder.
const bytes = Buffer.from([0,97,115,109,1,0,0,0, 1,5,1,96,0,1,127, 3,2,1,0,
  7,10,1,6,97,110,115,119,101,114,0,0, 10,6,1,4,0,65,42,11]);

test('independent literal decoder agrees with engine execution on a minimal module', async () => {
  const checked = validateWasmLiteralBinary(bytes, answer);
  assert.equal(checked.kind, 'accepted', JSON.stringify(checked));
  const { instance } = await WebAssembly.instantiate(bytes);
  assert.equal(instance.exports.answer(), 42);
  assert.equal(checked.sourcePreservation, 'requires-separately-checked-binding');
  assert.equal(checked.releaseAccepted, false);
});

test('real PSC lowering/encoder agrees on unsigned boundary, signed boundary and boolean', async () => {
  const executable = '.lake/build/bin/pscv_wasm_literal_validation_tests' + (process.platform === 'win32' ? '.exe' : '');
  const result = spawnSync(executable, ['--bytes'], { encoding: 'utf8', maxBuffer: 1024 * 1024, timeout: 30000 });
  assert.equal(result.status, 0, result.error?.message ?? result.stderr);
  const values = result.stdout.trim().split(',').map(Number);
  assert.ok(values.length && values.every(value => Number.isInteger(value) && value >= 0 && value <= 255));
  const binary = Buffer.from(values), expectedValue = expected([
    { name: 'unsignedMax', type: 'uint32', value: '4294967295' },
    { name: 'signedMin', type: 'int32', value: '-2147483648' },
    { name: 'truth', type: 'bool', value: '1' },
  ]);
  const emitted = spawnSync(executable, ['--expectation'], { encoding: 'utf8', maxBuffer: 1024 * 1024, timeout: 30000 });
  assert.equal(emitted.status, 0, emitted.error?.message ?? emitted.stderr);
  const expectationBytes = Buffer.from(emitted.stdout.trim());
  assert.deepEqual(expectationBytes, expectedValue.bytes);
  const expectations = { bytes: expectationBytes, identity: artifactId(expectationBytes, 'wasm-literal-expectation', 'psc-wasm-literal-expectation/1') };
  const checked = validateWasmLiteralBinary(binary, expectations);
  assert.equal(checked.kind, 'accepted', JSON.stringify(checked));
  const { instance } = await WebAssembly.instantiate(binary);
  assert.equal(instance.exports.unsignedMax(), -1);
  assert.equal(instance.exports.signedMin(), -2147483648);
  assert.equal(instance.exports.truth(), 1);
});

test('wrong behavior, malformed lengths, forbidden sections and exhaustion fail closed', () => {
  const drifted = Buffer.from(bytes); drifted[drifted.length - 2] = 43;
  assert.match(validateWasmLiteralBinary(drifted, answer).code, /LITERAL_MISMATCH/);
  const truncated = bytes.subarray(0, bytes.length - 1);
  assert.equal(validateWasmLiteralBinary(truncated, answer).kind, 'rejectedInvalid');
  const start = Buffer.concat([bytes.subarray(0, 31), Buffer.from([8,1,0]), bytes.subarray(31)]);
  assert.equal(validateWasmLiteralBinary(start, answer).kind, 'declinedUnsupported');
  const hugeVector = Buffer.concat([bytes.subarray(0, 8), Buffer.from([1,5,255,255,255,255,15])]);
  assert.equal(validateWasmLiteralBinary(hugeVector, answer).kind, 'resourceExhausted');
  assert.equal(validateWasmLiteralBinary(bytes, answer, { maxBytes: 1 }).kind, 'resourceExhausted');
  const duplicateSection = Buffer.concat([bytes, bytes.subarray(15, 19)]);
  assert.match(validateWasmLiteralBinary(duplicateSection, answer).code, /SECTION_ORDER_OR_DUPLICATE/);
  assert.match(validateWasmLiteralBinary(bytes, expected([{ name: 'answer', type: 'bool', value: '42' }])).code, /EXPECTATION_RANGE/);
});

test('LEB overflow is rejected while legal padded encodings preserve their value', async () => {
  const padded = Buffer.concat([bytes.subarray(0, 31), Buffer.from([10,7,1,5,0,65,170,0,11])]);
  assert.equal(validateWasmLiteralBinary(padded, answer).kind, 'accepted');
  assert.ok(WebAssembly.validate(padded));
  const overflow = Buffer.concat([bytes.subarray(0, 31), Buffer.from([10,10,1,8,0,65,255,255,255,255,15,11])]);
  assert.equal(validateWasmLiteralBinary(overflow, answer).kind, 'rejectedInvalid');
  assert.equal(WebAssembly.validate(overflow), false);
  const custom = Buffer.concat([bytes, Buffer.from([0,2,1,120])]);
  assert.equal(validateWasmLiteralBinary(custom, answer).kind, 'accepted');
  const wrongType = Buffer.from(bytes); wrongType[14] = 126;
  assert.equal(validateWasmLiteralBinary(wrongType, answer).kind, 'declinedUnsupported');
});

test('offline certificate boundary replays the binary relation with exact pinned subject', async () => {
  const binary = { bytes: Buffer.from(bytes), identity: artifactId(bytes, 'wasm-binary', 'webassembly-core/1') };
  const selected = wasmLiteralCertificateChecker({ binary, expectation: answer });
  const boundary = createCertificateBoundary({ checkers: new Map([['wasm-literal', selected.checker]]) });
  const certificate = canonicalArtifact({ contract: 'psc-certificate/1', checkerId: 'wasm-literal',
    subjectId: selected.subject.identity, payload: selected.payload }, 'certificate', 'psc-certificate/1');
  binary.bytes[0] = 99;
  const result = await boundary.check({ certificate, subject: selected.subject });
  assert.equal(result.kind, 'accepted', JSON.stringify(result));
  assert.equal(boundary.describe(result.value).claimClass, 'wasm-closed-i32-literal-export-behavior');
  const forged = canonicalArtifact({ contract: 'psc-certificate/1', checkerId: 'wasm-literal',
    subjectId: selected.subject.identity, payload: { binaryId: answer.identity, expectationId: answer.identity } }, 'certificate', 'psc-certificate/1');
  assert.equal((await boundary.check({ certificate: forged, subject: selected.subject })).kind, 'rejectedInvalid');
  const drifted = Buffer.from(bytes); drifted[drifted.length - 2] = 43;
  const bad = wasmLiteralCertificateChecker({ binary: { bytes: drifted, identity: artifactId(drifted, 'wasm-binary', 'webassembly-core/1') }, expectation: answer });
  const badBoundary = createCertificateBoundary({ checkers: new Map([['wasm-literal', bad.checker]]) });
  const badCert = canonicalArtifact({ contract: 'psc-certificate/1', checkerId: 'wasm-literal', subjectId: bad.subject.identity,
    payload: bad.payload }, 'certificate', 'psc-certificate/1');
  assert.equal((await badBoundary.check({ certificate: badCert, subject: bad.subject })).kind, 'rejectedInvalid');
  boundary.close(); badBoundary.close();
});

test('export names retain a leading BOM and numeric expectations reject trailing line terminators',async()=>{
  const named=Buffer.concat([bytes.subarray(0,19),
    Buffer.from([7,13,1,9,239,187,191,...Buffer.from('answer'),0,0]),bytes.subarray(31)]);
  const instance=new WebAssembly.Instance(new WebAssembly.Module(named));
  assert.equal(instance.exports['\uFEFFanswer'](),42);
  assert.equal(instance.exports.answer,undefined);
  assert.match(validateWasmLiteralBinary(named,answer).code,/LITERAL_MISMATCH/);
  assert.equal(validateWasmLiteralBinary(named,expected([{name:'\uFEFFanswer',type:'uint32',value:'42'}])).kind,'accepted');
  for(const suffix of ['\n','\r','\u2028','\u2029'])
    assert.match(validateWasmLiteralBinary(bytes,expected([{name:'answer',type:'uint32',value:'42'+suffix}])).code,/EXPECTATION_ENTRY/);
});
