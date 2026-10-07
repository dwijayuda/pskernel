import assert from 'node:assert/strict';
import { test } from 'node:test';
import { canonicalBytes, canonicalArtifact, artifactId, artifactKey, passDefinition,
  recordPassExecution, verifyPassExecution } from './artifact-evidence.mjs';

function fixture(evidence = []) {
  const artifacts = new Map();
  const add = artifact => { artifacts.set(artifactKey(artifact.identity), artifact.bytes); return artifact; };
  const implementation = add(canonicalArtifact({ implementation: 'fixture-only' }, 'implementation', 'test-implementation/1'));
  const input = add(canonicalArtifact({ input: 7 }, 'input', 'test-input/1'));
  const output = add(canonicalArtifact({ output: 7 }, 'output', 'test-output/1'));
  const definition = add(passDefinition({ passId: 'test-pass/1', version: 1,
    inputContract: 'test-input/1', outputContract: 'test-output/1',
    semanticRelationId: 'test-equality/1', resourceContractId: 'test-resource/1',
    determinismClass: 'deterministic', totalityClass: 'bounded-partial',
    implementationId: implementation.identity, validatorId: null, theoremIds: [], assumptionIds: ['test-host'] }));
  const record = recordPassExecution({ definition, inputs: [input], outputs: [output],
    parameters: { target: 'test' }, semanticIdentity: { contract: 'test-semantics/1' },
    resourcePolicy: { maxSteps: 10 }, evidence });
  add(record); add(record.action);
  const options = { resolveArtifact: identity => artifacts.get(artifactKey(identity)), allowedAssumptions: ['test-host'] };
  return { record, options, artifacts, add, input, output };
}

test('canonical identities ignore object insertion order, retain arrays and domain', () => {
  assert.deepEqual(canonicalBytes({ b: 1, a: [1, 2] }), canonicalBytes({ a: [1, 2], b: 1 }));
  assert.notDeepEqual(canonicalBytes([1, 2]), canonicalBytes([2, 1]));
  const bytes = Buffer.from('same');
  assert.notEqual(artifactKey(artifactId(bytes, 'input', 'test/1')), artifactKey(artifactId(bytes, 'output', 'test/1')));
  const cycle = {}; cycle.self = cycle;
  for (const value of [cycle, [undefined], new Array(2), NaN, -0, 1.5, { get value() { throw new Error('getter ran'); } }]) {
    assert.throws(() => canonicalBytes(value), /PSC_EVIDENCE_CANONICAL/);
  }
  assert.throws(() => canonicalBytes('huge', { maxBytes: 2 }), /BYTES_EXHAUSTED/);
  assert.throws(() => canonicalBytes([[[1]]], { maxDepth: 1 }), /WORK_EXHAUSTED/);
});

test('complete byte integrity remains distinct from preservation', async () => {
  const { record, options } = fixture();
  const result = await verifyPassExecution(record, options);
  assert.equal(result.integrityVerified, true);
  assert.equal(result.preservationVerified, false);
  assert.equal(result.authority, 'audit-record-only');
  await assert.rejects(verifyPassExecution(record, { ...options, requiredEvidenceKinds: ['global-preservation'] }), /EVIDENCE_REQUIRED/);
  await assert.rejects(verifyPassExecution(record, { ...options, allowedAssumptions: [] }), /ASSUMPTION_DENIED/);
});

test('untrusted artifact, action and semantic provenance changes reject', async () => {
  const { record, options, artifacts, input } = fixture();
  artifacts.set(artifactKey(input.identity), Buffer.from('tampered'));
  await assert.rejects(verifyPassExecution(record, options), /ARTIFACT_BYTES/);
  artifacts.set(artifactKey(input.identity), input.bytes);
  for (const modify of [
    value => { value.action.parameters.target = 'other'; },
    value => { value.inputSemanticFingerprints[0].sourceArtifact = value.outputs[0]; },
    value => { value.assumptionIds = []; },
  ]) {
    const value = JSON.parse(record.bytes); modify(value);
    const changed = canonicalArtifact(value, 'pass-execution', 'psc-pass-execution/1');
    await assert.rejects(verifyPassExecution(changed, options), /ACTION_ID|FINGERPRINT_PROVENANCE|PASS_ASSUMPTIONS/);
  }
});

test('evidence must use a configured checker and bind the exact execution subject', async () => {
  const proof = canonicalArtifact({ certificate: 'test-double-only' }, 'evidence', 'test-certificate/1');
  const { record, options, add } = fixture([{ kind: 'global-preservation', checkerId: 'test-checker', artifact: proof.identity }]);
  add(proof);
  await assert.rejects(verifyPassExecution(record, options), /CHECKER_UNAVAILABLE/);
  const good = new Map([['test-checker', async (_bytes, subject) => ({ verified: true, kind: 'global-preservation', subject })]]);
  assert.equal((await verifyPassExecution(record, { ...options, evidenceCheckers: good,
    requiredEvidenceKinds: ['global-preservation'] })).preservationVerified, true);
  const wrong = new Map([['test-checker', async (_bytes, subject) => ({ verified: true,
    kind: 'global-preservation', subject: { ...subject, outputs: [] } })]]);
  await assert.rejects(verifyPassExecution(record, { ...options, evidenceCheckers: wrong }), /EVIDENCE_REJECTED/);
});

function productFixture() {
  const f = fixture();
  const old = JSON.parse(f.record.definition.bytes);
  const { inputContract, outputContract, ...common } = old;
  const extra = f.add(canonicalArtifact({ binding: 7 }, 'binding', 'test-binding/1'));
  const effects = { supportedProfiles: ['fixture-only'], requiresAnalyses: [], preservesAnalyses: [], invalidatesAnalyses: ['*'],
    preservesInterfaces: [], invalidatesInterfaces: ['*'], preservesFingerprints: [], invalidatesFingerprints: ['*'],
    originPolicy: 'drop-with-reason', originReason: 'Fixture has no source origins.',
    authorityEffect: 'requiresRevalidation', assuranceClass: 'trustedImplementation' };
  const spec = (artifact, role) => ({ role, domain: artifact.identity.domain, contract: artifact.identity.contract });
  const fields = { ...common, schemaVersion: 2, contract: 'psc-pass-definition/2',
    inputArtifacts: [spec(f.input, 'source')], outputArtifacts: [spec(f.output, 'interface'), spec(extra, 'binding')], effects };
  const definition = f.add(passDefinition(fields));
  const args = { definition, inputs: [f.input], outputs: [f.output, extra],
    semanticIdentity: { contract: 'test-semantics/1' }, resourcePolicy: { maxSteps: 10 } };
  const record = f.add(recordPassExecution(args)); f.add(record.action);
  return { ...f, extra, fields, args, record };
}

test('typed product passes bind each output domain, contract, position and cardinality', async () => {
  const f = productFixture();
  const verified = await verifyPassExecution(f.record, f.options);
  assert.equal(verified.integrityVerified, true);
  assert.equal(verified.preservationVerified, false);
  for (const outputs of [[f.extra, f.output], [f.output], [f.output, f.extra, f.extra],
    [f.output, f.add(canonicalArtifact({ binding: 7 }, 'wrong-domain', 'test-binding/1'))]]) {
    assert.throws(() => recordPassExecution({ ...f.args, outputs }), /PASS_ARTIFACT/);
  }
  const changed = JSON.parse(f.record.bytes); changed.outputs.reverse();
  await assert.rejects(verifyPassExecution(canonicalArtifact(changed, 'pass-execution', 'psc-pass-execution/1'), f.options), /PASS_ARTIFACT_CONTRACT/);
});

test('legacy homogeneous passes still reject mixed output contracts', () => {
  const f = productFixture();
  const old = fixture();
  assert.throws(() => recordPassExecution({ ...f.args, definition: old.record.definition }), /PASS_ARTIFACT_CONTRACT/);
});

test('preservation metadata must be explicit and internally consistent', () => {
  const f = productFixture();
  for (const effects of [
    { ...f.fields.effects, preservesAnalyses: ['liveness'] },
    { ...f.fields.effects, preservesFingerprints: ['*'] },
    { ...f.fields.effects, authorityEffect: 'preservesByProof' },
    { ...f.fields.effects, assuranceClass: 'translationValidated' },
    { ...f.fields.effects, originReason: '' },
  ]) assert.throws(() => passDefinition({ ...f.fields, effects }), /PASS_/);
});
