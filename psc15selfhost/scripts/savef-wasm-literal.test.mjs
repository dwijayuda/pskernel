import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import { artifactId, artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { createWasmLiteralKnowledge, createWasmLiteralReuseSession, wasmLiteralReuseTask } from './savef-wasm-literal.mjs';

const minimal = Buffer.from([0,97,115,109,1,0,0,0, 1,5,1,96,0,1,127, 3,2,1,0,
  7,10,1,6,97,110,115,119,101,114,0,0, 10,6,1,4,0,65,42,11]);
const expected = exports => canonicalArtifact({ contract: 'psc-wasm-literal-expectation/1', exports },
  'wasm-literal-expectation', 'psc-wasm-literal-expectation/1');
const answer = expected([{ name: 'answer', type: 'uint32', value: '42' }]);
const license = canonicalArtifact({ spdx: 'NOASSERTION', scope: 'focused fixture; metadata grants no distribution rights' },
  'license-notice', 'psc-license-notice/1');
const context = { semanticIdentity: { contract: 'psc-wasm-literal-expectation/1', representation: 'closed-i32-exports' },
  scope: { use: 'exact-literal-binary-reuse', sourcePreservation: false },
  allowedAssumptions: ['trusted-wasm-literal-validator-implementation'],
  requiredClaims: ['wasm-closed-i32-literal-export-behavior'] };

async function setup(bytes = minimal, expectation = answer) {
  const binary = { bytes: Buffer.from(bytes), identity: artifactId(bytes, 'wasm-binary', 'webassembly-core/1') };
  const packed = await createWasmLiteralKnowledge({ binary, expectation, license,
    semanticIdentity: context.semanticIdentity, scope: context.scope });
  assert.equal(packed.kind, 'accepted');
  const blobs = new Map(packed.artifacts.map(item => [artifactKey(item.identity), Buffer.from(item.bytes)]));
  const options = { binary, expectation, knowledgeId: packed.object.identity, context,
    resolveArtifact: id => blobs.get(artifactKey(id)) };
  return { binary, expectation, packed, blobs, options, session: await createWasmLiteralReuseSession(options) };
}

async function reuse(session) {
  const handle = await session.acquire();
  const performed = await session.apply(handle, { operationId: session.operationId, task: session.task, input: session.expectation });
  const accepted = await session.accept({ task: session.task, output: performed.output, uses: [performed.execution],
    counterfactualArm: 'focused-reuse-fixture', costObservation: { campaign: false } });
  assert.equal(accepted.kind, 'accepted');
  assert.equal(accepted.events.length, 1);
  assert.equal(accepted.assuranceAfter.sourcePreservation, false);
  assert.equal(JSON.parse(accepted.events[0].bytes).causalImprovement, 'not-established');
  assert.equal(session.measurements().certificateChecks, 1);
  assert.equal(session.measurements().operationCalls, 1);
  assert.equal(session.measurements().outputChecks, 1);
  return { performed, accepted };
}

test('SAVEF replays an actual binary validator and records reuse only after output acceptance', async () => {
  const { session, packed } = await setup();
  assert.equal(packed.indexed, false);
  assert.equal(packed.sourcePreservation, false);
  const { performed } = await reuse(session);
  assert.deepEqual(performed.output.bytes, minimal);
  const { instance } = await WebAssembly.instantiate(performed.output.bytes);
  assert.equal(instance.exports.answer(), 42);
  await assert.rejects(session.accept({ task: session.task, output: performed.output, uses: [performed.execution],
    counterfactualArm: 'focused-reuse-fixture', costObservation: {} }), /USE_NOT_LIVE/);
  session.close();
  await assert.rejects(session.acquire(), /CLOSED/);
});

test('wrong task, changed certificate, stale context, tampered bytes and alternate payloads cannot authorize reuse', async () => {
  const f = await setup(), handle = await f.session.acquire();
  const changedExpectation = expected([{ name: 'answer', type: 'uint32', value: '43' }]);
  await assert.rejects(f.session.apply(handle, { operationId: f.session.operationId,
    task: wasmLiteralReuseTask(changedExpectation.identity), input: changedExpectation }), /WASM_REUSE_TASK/);
  await assert.rejects(f.session.apply(handle, { operationId: f.session.operationId,
    task: f.session.task, input: changedExpectation }), /WASM_REUSE_VALIDITY/);
  const performed = await f.session.apply(handle, { operationId: f.session.operationId, task: f.session.task, input: f.expectation });
  const alternativeBytes = Buffer.from(minimal); alternativeBytes[alternativeBytes.length - 2] = 43;
  const alternative = { bytes: alternativeBytes, identity: artifactId(alternativeBytes, 'wasm-binary', 'webassembly-core/1') };
  assert.equal((await f.session.accept({ task: f.session.task, output: alternative, uses: [performed.execution],
    counterfactualArm: 'focused-reuse-fixture', costObservation: {} })).kind, 'rejectedInvalid');
  const stale = await createWasmLiteralReuseSession({ ...f.options, context: { ...context, scope: { other: true } } });
  await assert.rejects(stale.acquire(), /STALE_CONTEXT/); stale.close();
  const certificate = f.packed.artifacts.find(item => item.identity.contract === 'psc-certificate/1');
  f.blobs.set(artifactKey(certificate.identity), Buffer.from('{}'));
  await assert.rejects(f.session.acquire(), /ARTIFACT_BYTES|ARTIFACT_DIGEST|ARTIFACT_LENGTH/);
  const declined = await createWasmLiteralKnowledge({ binary: alternative, expectation: answer, license,
    semanticIdentity: context.semanticIdentity, scope: context.scope });
  assert.equal(declined.kind, 'rejectedInvalid');
  f.session.close();
});

test('real PSC-emitted literal artifact and derived expectation pass SAVEF replay and executed reuse', async () => {
  const binaryFile = '.lake/build/bin/pscv_wasm_literal_validation_tests' + (process.platform === 'win32' ? '.exe' : '');
  function run(flag) {
    const result = spawnSync(binaryFile, [flag], { encoding: 'utf8', maxBuffer: 1024 * 1024, timeout: 30000 });
    assert.equal(result.status, 0, result.error?.message ?? result.stderr); return result.stdout.trim();
  }
  const binary = Buffer.from(run('--bytes').split(',').map(Number));
  const expectationBytes = Buffer.from(run('--expectation'));
  const expectation = { bytes: expectationBytes,
    identity: artifactId(expectationBytes, 'wasm-literal-expectation', 'psc-wasm-literal-expectation/1') };
  const { session } = await setup(binary, expectation);
  const { performed } = await reuse(session);
  const { instance } = await WebAssembly.instantiate(performed.output.bytes);
  assert.equal(instance.exports.unsignedMax(), -1);
  assert.equal(instance.exports.signedMin(), -2147483648);
  assert.equal(instance.exports.truth(), 1);
  session.close();
});
