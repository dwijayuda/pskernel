import assert from 'node:assert/strict';
import { test } from 'node:test';
import { generateKeyPairSync, sign } from 'node:crypto';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { createCertificateBoundary } from './certificate-boundary.mjs';
import { knowledgeObject } from './savef-graph.mjs';
import { archiveSignatureBytes, packOfflineCapsule, verifyOfflineCapsule, readOfflineCapsule } from './offline-capsule.mjs';
import { verifyCapsuleCommand } from './offline-verifier-cli.mjs';
import { semanticLockFixture } from './semantic-lock-fixture.mjs';
import { wasmLiteralCertificateChecker } from './wasm-literal-certificate.mjs';

const object = (value, domain = 'test-data', contract = 'test-data/1') => canonicalArtifact(value, domain, contract);
function fixture({ changeKnowledge, includeCertificate = true } = {}) {
  const lockFixture = semanticLockFixture(), lock = lockFixture.lock;
  const subject = object({ left: 12, right: 12 }, 'test-subject');
  const payload = object({ statement: 'fixture integer equality; no compiler theorem' });
  const license = object({ spdx: 'MIT' });
  const certificate = object({ contract: 'psc-certificate/1', checkerId: 'fixture-equality',
    subjectId: subject.identity, payload: { left: 12, right: 12 } }, 'certificate', 'psc-certificate/1');
  const context = { semanticIdentity: { semanticLockId: lock.identity }, scope: { profile: 'fixture-only' },
    allowedAssumptions: [], requiredClaims: ['fixture-equality'] };
  const fields = { contract: 'psc-knowledge-object/2', kind: 'proof', semanticIdentity: context.semanticIdentity,
    authorityClass: 'validation-authority', scope: context.scope, dependencies: [], assumptions: [],
    claims: [{ claimId: 'fixture-equality', status: 'validated', subjectId: subject.identity, certificateId: certificate.identity }],
    payload: payload.identity, implementationWitnesses: [], evidence: [], provenance: [], resourceEvidence: [],
    license: license.identity, supersedes: [], migrations: [] };
  changeKnowledge?.(fields);
  const knowledge = knowledgeObject(fields);
  const manifest = object({ contract: 'psc-evidence-manifest/1', semanticLockId: lock.identity,
    roots: [knowledge.identity], archive: [{ role: 'semantic-lock', artifact: lock.identity },
      { role: 'license', artifact: license.identity }] }, 'evidence-manifest', 'psc-evidence-manifest/1');
  let calls = 0;
  // A real, tiny integer-equality validator for this fixture. It deliberately
  // has no theorem-kernel or compiler-preservation claim class.
  const boundary = createCertificateBoundary({ checkers: new Map([['fixture-equality', {
    claimClass: 'fixture-integer-equality', identity: { id: 'fixture-equality/1' },
    async verify(bytes, requested) {
      calls++;
      const proposed = JSON.parse(bytes), actual = JSON.parse(requested.bytes);
      if (!Number.isSafeInteger(actual.left) || actual.left !== actual.right ||
          !canonicalBytes(proposed).equals(canonicalBytes(actual))) return { kind: 'rejectedInvalid' };
      return { kind: 'accepted', claimClass: 'fixture-integer-equality', subjectId: requested.identity, evidence: {} };
    },
  }]]) });
  const policy = { expectedManifestId: manifest.identity, expectedSemanticLockId: lock.identity, context,
    semanticLockPolicy: lockFixture.policy,
    claimPolicies: new Map([['fixture-equality', { subjectId: subject.identity, claimClass: 'fixture-integer-equality', checkerId: 'fixture-equality' }]]),
    certificateBoundary: boundary, requiredArchiveRoles: ['semantic-lock', 'license'] };
  const artifacts = [subject, ...lockFixture.artifacts, payload, license, knowledge, ...(includeCertificate ? [certificate] : [])];
  const capsule = packOfflineCapsule({ manifest, artifacts });
  return { subject, lock, payload, license, knowledge, manifest, artifacts, capsule, policy, boundary, calls: () => calls };
}

test('offline capsule replays a scoped validator, context and all artifact bytes', async () => {
  const f = fixture();
  const result = await verifyOfflineCapsule(f.capsule.bytes, f.policy);
  assert.equal(result.kind, 'accepted', JSON.stringify(result));
  assert.equal(f.calls(), 1);
  assert.equal(result.validity.verifiedClaims[0].claimClass, 'fixture-integer-equality');
  assert.equal(result.releaseAccepted, false);
  assert.equal(result.authority, 'audit-record-only');
});

test('stale context, forbidden assumptions and missing evidence fail closed', async () => {
  const stale = fixture(); stale.policy.context.scope = { profile: 'another-profile' };
  assert.match((await verifyOfflineCapsule(stale.capsule.bytes, stale.policy)).code, /STALE_CONTEXT/);
  assert.equal(stale.calls(), 0);
  const assumption = fixture({ changeKnowledge: value => { value.assumptions = ['new-axiom']; } });
  assert.match((await verifyOfflineCapsule(assumption.capsule.bytes, assumption.policy)).code, /ASSUMPTION_DENIED/);
  const missing = fixture({ includeCertificate: false });
  assert.match((await verifyOfflineCapsule(missing.capsule.bytes, missing.policy)).code, /MISSING_ARTIFACT/);
});

test('capsule cannot omit semantic lock policy or substitute a different knowledge lock', async () => {
  const f = fixture(), policy = { ...f.policy }; delete policy.semanticLockPolicy;
  assert.match((await verifyOfflineCapsule(f.capsule.bytes, policy)).code, /SEMANTIC_LOCK_POLICY/);
  const substituted = { ...f.policy, context: { ...f.policy.context, semanticIdentity: { semanticLockId: f.payload.identity } } };
  assert.match((await verifyOfflineCapsule(f.capsule.bytes, substituted)).code, /SEMANTIC_LOCK_POLICY/);
  assert.equal(f.calls(), 0);
});

test('claim labels cannot reinterpret unrelated evidence or bypass required proof checks', async () => {
  const f = fixture();
  f.policy.claimPolicies.set('fixture-equality', { ...f.policy.claimPolicies.get('fixture-equality'), claimClass: 'global-preservation' });
  assert.match((await verifyOfflineCapsule(f.capsule.bytes, f.policy)).code, /INTERPRETATION_MISMATCH/);
  const unconfigured = fixture(); unconfigured.policy.claimPolicies.clear();
  assert.match((await verifyOfflineCapsule(unconfigured.capsule.bytes, unconfigured.policy)).code, /INTERPRETATION_UNAVAILABLE/);
  const unproved = fixture({ changeKnowledge: value => { value.claims[0].status = 'target-unproved'; } });
  assert.match((await verifyOfflineCapsule(unproved.capsule.bytes, unproved.policy)).code, /REQUIRED_CLAIM/);
  assert.equal(unproved.calls(), 0);
});

test('Ed25519 signatures bind the exact manifest to consumer-selected keys', async () => {
  const f = fixture(), keys = generateKeyPairSync('ed25519');
  const signature = { signerId: 'release-fixture', algorithm: 'ed25519',
    signature: sign(null, archiveSignatureBytes(f.manifest.identity), keys.privateKey).toString('base64') };
  const signed = packOfflineCapsule({ manifest: f.manifest, artifacts: f.artifacts, signatures: [signature] });
  const policy = { ...f.policy, publicKeys: new Map([['release-fixture', keys.publicKey]]), requiredSignerIds: ['release-fixture'] };
  assert.equal((await verifyOfflineCapsule(signed.bytes, policy)).kind, 'accepted');
  assert.match((await verifyOfflineCapsule(f.capsule.bytes, policy)).code, /SIGNATURE_REQUIRED/);
  const attacker = generateKeyPairSync('ed25519');
  assert.match((await verifyOfflineCapsule(signed.bytes, { ...policy, publicKeys: new Map([['release-fixture', attacker.publicKey]]) })).code, /SIGNATURE_INVALID/);
  assert.match((await verifyOfflineCapsule(signed.bytes, f.policy)).code, /SIGNER_UNTRUSTED/);
});

test('hash changes, duplicated keys, missing archive roles and byte budgets are rejected', async () => {
  const f = fixture(), decoded = JSON.parse(f.capsule.bytes);
  const payload = decoded.artifacts.find(item => artifactKey(item.identity) === artifactKey(f.payload.identity));
  payload.data = Buffer.from('changed').toString('base64');
  assert.equal((await verifyOfflineCapsule(canonicalBytes(decoded), f.policy)).kind, 'rejectedInvalid');
  const duplicate = Buffer.from(f.capsule.bytes.toString().replace('{', '{"contract":"psc-offline-capsule/1",'));
  assert.equal((await verifyOfflineCapsule(duplicate, f.policy)).kind, 'rejectedInvalid');
  assert.match((await verifyOfflineCapsule(f.capsule.bytes, { ...f.policy, requiredArchiveRoles: ['toolchain'] })).code, /ROLE_REQUIRED/);
  assert.equal((await verifyOfflineCapsule(f.capsule.bytes, { ...f.policy, resourceLimits: { maxTotalBytes: 1 } })).kind, 'resourceExhausted');
  assert.equal((await verifyOfflineCapsule(f.capsule.bytes, { ...f.policy, resourceLimits: { maxObjects: 0 } })).kind, 'resourceExhausted');
});

test('typed dependency links cannot claim an artifact object is a theory', async () => {
  const f = fixture();
  const childFields = JSON.parse(f.knowledge.bytes); childFields.kind = 'artifact'; childFields.claims = [];
  const child = knowledgeObject(childFields);
  const rootFields = JSON.parse(f.knowledge.bytes); rootFields.dependencies = [{ relation: 'theory', target: child.identity }];
  const root = knowledgeObject(rootFields), rawManifest = JSON.parse(f.manifest.bytes); rawManifest.roots = [root.identity];
  const manifest = object(rawManifest, 'evidence-manifest', 'psc-evidence-manifest/1');
  const capsule = packOfflineCapsule({ manifest, artifacts: [...f.artifacts, child, root] });
  assert.match((await verifyOfflineCapsule(capsule.bytes, { ...f.policy, expectedManifestId: manifest.identity })).code, /EDGE_TYPE/);
  rootFields.dependencies[0].relation = 'artifact';
  const validRoot = knowledgeObject(rootFields); rawManifest.roots = [validRoot.identity];
  const validManifest = object(rawManifest, 'evidence-manifest', 'psc-evidence-manifest/1');
  const valid = packOfflineCapsule({ manifest: validManifest, artifacts: [...f.artifacts, child, validRoot] });
  assert.equal((await verifyOfflineCapsule(valid.bytes, { ...f.policy, expectedManifestId: validManifest.identity })).kind, 'accepted');
});

test('CLI verifies a local unsigned metadata capsule without compiler or checker execution', async () => {
  const f = fixture({ changeKnowledge: value => { value.claims = []; } });
  const directory = await mkdtemp(path.join(tmpdir(), 'psc-offline-'));
  try {
    const file = path.join(directory, 'capsule.json'), policyFile = path.join(directory, 'policy.json');
    await writeFile(file, f.capsule.bytes);
    await writeFile(policyFile, JSON.stringify({ contract: 'psc-offline-consumer-policy/1',
      expectedManifestId: f.manifest.identity, expectedSemanticLockId: f.lock.identity,
      semanticLockPolicy: f.policy.semanticLockPolicy,
      context: { ...f.policy.context, requiredClaims: [] }, checkers: [], claims: [], publicKeys: [],
      requiredSignerIds: [], requiredArchiveRoles: ['license'] }));
    const result = await verifyCapsuleCommand(file, policyFile);
    assert.equal(result.kind, 'accepted'); assert.deepEqual(result.validity.verifiedClaims, []);
    await assert.rejects(readOfflineCapsule(file, { maxCapsuleBytes: 1 }), /RESOURCE_EXHAUSTED/);
  } finally { await rm(directory, { recursive: true, force: true }); }
});

test('offline CLI replays the built-in literal Wasm checker under an exact claim class', async () => {
  const f = fixture(), bytes = Buffer.from([0,97,115,109,1,0,0,0,1,5,1,96,0,1,127,3,2,1,0,
    7,10,1,6,97,110,115,119,101,114,0,0,10,6,1,4,0,65,42,11]);
  const binary = { bytes, identity: artifactId(bytes, 'wasm-binary', 'webassembly-core/1') };
  const expectation = object({ contract: 'psc-wasm-literal-expectation/1', exports: [{ name: 'answer', type: 'uint32', value: '42' }] },
    'wasm-literal-expectation', 'psc-wasm-literal-expectation/1');
  const selected = wasmLiteralCertificateChecker({ binary, expectation });
  const certificate = object({ contract: 'psc-certificate/1', checkerId: 'wasm-literal', subjectId: selected.subject.identity,
    payload: selected.payload }, 'certificate', 'psc-certificate/1');
  const statement = object({ statement: 'binary answer export returns i32 42; no source preservation claim' });
  const fields = JSON.parse(f.knowledge.bytes); fields.payload = statement.identity;
  fields.claims = [{ claimId: 'wasm-literal', status: 'validated', subjectId: selected.subject.identity, certificateId: certificate.identity }];
  const knowledge = knowledgeObject(fields), manifestFields = JSON.parse(f.manifest.bytes); manifestFields.roots = [knowledge.identity];
  const manifest = object(manifestFields, 'evidence-manifest', 'psc-evidence-manifest/1');
  const capsule = packOfflineCapsule({ manifest, artifacts: [...f.artifacts, binary, expectation, selected.subject, certificate, statement, knowledge] });
  const directory = await mkdtemp(path.join(tmpdir(), 'psc-wasm-offline-'));
  try {
    const file = path.join(directory, 'capsule.json'), policyFile = path.join(directory, 'policy.json');
    const policy = { contract: 'psc-offline-consumer-policy/1', expectedManifestId: manifest.identity,
      expectedSemanticLockId: f.lock.identity, semanticLockPolicy: f.policy.semanticLockPolicy,
      context: { ...f.policy.context, requiredClaims: ['wasm-literal'] }, publicKeys: [], requiredSignerIds: [], requiredArchiveRoles: [],
      checkers: [{ checkerId: 'wasm-literal', kind: 'wasm-literal', binaryId: binary.identity, expectationId: expectation.identity, subjectId: selected.subject.identity }],
      claims: [{ claimId: 'wasm-literal', subjectId: selected.subject.identity, checkerId: 'wasm-literal', claimClass: selected.checker.claimClass }] };
    await writeFile(file, capsule.bytes); await writeFile(policyFile, JSON.stringify(policy));
    const result = await verifyCapsuleCommand(file, policyFile);
    assert.equal(result.kind, 'accepted', JSON.stringify(result));
    assert.equal(result.validity.verifiedClaims[0].claimClass, 'wasm-closed-i32-literal-export-behavior');
    policy.claims[0].claimClass = 'global-compiler-preservation'; await writeFile(policyFile, JSON.stringify(policy));
    assert.equal((await verifyCapsuleCommand(file, policyFile)).kind, 'rejectedInvalid');
  } finally { await rm(directory, { recursive: true, force: true }); }
});
