import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { buildVerifierDistribution, staticModuleDependencies } from './build-verifier-distribution.mjs';
import { semanticLockFixture } from './semantic-lock-fixture.mjs';
import { artifactId, canonicalArtifact } from './artifact-evidence.mjs';
import { wasmLiteralCertificateChecker } from './wasm-literal-certificate.mjs';
import { knowledgeObject } from './savef-graph.mjs';
import { packOfflineCapsule } from './offline-capsule.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive } from './observed-build-archive.mjs';
import { coreProofCertificateChecker } from './certificate-boundary.mjs';
import { canonicalBytes } from './artifact-evidence.mjs';

function capsuleFixture() {
  const f = semanticLockFixture(), bytes = Buffer.from([0,97,115,109,1,0,0,0,1,5,1,96,0,1,127,3,2,1,0,
    7,10,1,6,97,110,115,119,101,114,0,0,10,6,1,4,0,65,42,11]);
  const binary = { bytes, identity: artifactId(bytes, 'wasm-binary', 'webassembly-core/1') };
  const expectation = canonicalArtifact({ contract: 'psc-wasm-literal-expectation/1', exports: [{ name: 'answer', type: 'uint32', value: '42' }] },
    'wasm-literal-expectation', 'psc-wasm-literal-expectation/1');
  const selected = wasmLiteralCertificateChecker({ binary, expectation });
  const certificate = canonicalArtifact({ contract: 'psc-certificate/1', checkerId: 'wasm-literal', subjectId: selected.subject.identity,
    payload: selected.payload }, 'certificate', 'psc-certificate/1');
  const license = canonicalArtifact({ spdx: 'MIT' }, 'license', 'test-license/1');
  const context = { semanticIdentity: { semanticLockId: f.lock.identity }, scope: { profile: 'fictional-distribution-fixture' },
    allowedAssumptions: [], requiredClaims: ['literal'] };
  const knowledge = knowledgeObject({ contract: 'psc-knowledge-object/2', kind: 'artifact', semanticIdentity: context.semanticIdentity,
    authorityClass: 'validation-authority', scope: context.scope, dependencies: [], assumptions: [],
    claims: [{ claimId: 'literal', status: 'validated', subjectId: selected.subject.identity, certificateId: certificate.identity }],
    payload: binary.identity, implementationWitnesses: [], evidence: [], provenance: [], resourceEvidence: [], license: license.identity,
    supersedes: [], migrations: [] });
  const manifest = canonicalArtifact({ contract: 'psc-evidence-manifest/1', semanticLockId: f.lock.identity, roots: [knowledge.identity],
    archive: [{ role: 'semantic-lock', artifact: f.lock.identity }, { role: 'target', artifact: binary.identity }] },
    'evidence-manifest', 'psc-evidence-manifest/1');
  const capsule = packOfflineCapsule({ manifest, artifacts: [...f.artifacts, binary, expectation, selected.subject, certificate, license, knowledge] });
  const policy = { contract: 'psc-offline-consumer-policy/1', expectedManifestId: manifest.identity, expectedSemanticLockId: f.lock.identity,
    semanticLockPolicy: f.policy, context, publicKeys: [], requiredSignerIds: [], requiredArchiveRoles: ['target'],
    checkers: [{ checkerId: 'wasm-literal', kind: 'wasm-literal', binaryId: binary.identity, expectationId: expectation.identity, subjectId: selected.subject.identity }],
    claims: [{ claimId: 'literal', subjectId: selected.subject.identity, checkerId: 'wasm-literal', claimClass: selected.checker.claimClass }] };
  return { capsule, policy };
}

test('distribution inventory parses actual ESM declarations without executing source or mistaking IR tags for imports', () => {
  const source = "import { readFile } from 'node:fs/promises';\n" +
    "export { value } from './dependency.mjs';\n" +
    "const tags = ['import', 'from']; /* import 'fictional.mjs'; */\n" +
    "throw new Error('must not execute');\n";
  assert.deepEqual(staticModuleDependencies(source), ['node:fs/promises', './dependency.mjs']);
  assert.deepEqual(staticModuleDependencies("const deferred = () => import('./dynamic.mjs');"), []);
  assert.throws(() => staticModuleDependencies('import {'), /PARSE_FAILED/);
});

test('standalone verifier replays real supported evidence outside checkout and rejects tampering/unshipped providers', async () => {
  const directory = await mkdtemp(path.join(tmpdir(), 'psc-verifier-dist-'));
  try {
    const distribution = await buildVerifierDistribution(path.join(directory, 'verifier'));
    await assert.rejects(buildVerifierDistribution(distribution.directory), /EEXIST/);
    const f = capsuleFixture(), capsulePath = path.join(directory, 'capsule.json'), policyPath = path.join(directory, 'policy.json');
    await writeFile(capsulePath, f.capsule.bytes); await writeFile(policyPath, JSON.stringify(f.policy));
    const invoke = (hash = distribution.manifestSha256) => spawnSync(process.execPath,
      [path.join(distribution.directory, 'pscv-verify.mjs'), '--manifest-sha256', hash, '--capsule', capsulePath, '--policy', policyPath],
      { cwd: directory, encoding: 'utf8', maxBuffer: 1024 * 1024, timeout: 30000,
        env: { ...process.env, NODE_PATH: '', NODE_OPTIONS: '' } });
    const result = invoke(); assert.equal(result.status, 0, result.error?.message ?? result.stderr);
    const record = JSON.parse(result.stdout); assert.equal(record.kind, 'accepted'); assert.equal(record.releaseAccepted, false);
    assert.equal(record.validity.verifiedClaims[0].claimClass, 'wasm-closed-i32-literal-export-behavior');
    assert.equal(record.lockCheck.integrityVerified, true);
    const manifest = JSON.parse(await readFile(path.join(distribution.directory, 'manifest.json')));
    assert.equal(manifest.fullCompilerIncluded, false); assert.equal(manifest.coreProvidersIncluded, false);
    assert.ok(manifest.files.every(file => !file.path.includes('/dist/') && !file.path.endsWith('.lean')));
    const build = createCheckedBuildGraph({ sourceKind: 'lean', sources: ['fictional source'], admissions: 'fictional admissions',
      compilerBytes: Buffer.from('fictional compiler'), compilerKind: 'fixture', provider: { profile: 'fixture' },
      providerSecurity: { profile: 'fixture' }, kernelContract: { id: 'fixture' }, hostSources: [], runtime: { version: 'fixture' } });
    const buildArchive = packObservedBuildArchive(build), buildPath = path.join(directory, 'build.json'), buildPolicyPath = path.join(directory, 'build-policy.json');
    await writeFile(buildPath, buildArchive.bytes);
    await writeFile(buildPolicyPath, JSON.stringify({ contract: 'psc-observed-build-consumer-policy/1', expectedGraphId: build.identity,
      allowedAssumptions: build.graph.entries.find(entry => entry.identity.domain === 'pass-definition').canonicalValue.assumptionIds }));
    const buildResult = spawnSync(process.execPath, [path.join(distribution.directory, 'pscv-verify.mjs'),
      '--manifest-sha256', distribution.manifestSha256, '--build-archive', buildPath, '--policy', buildPolicyPath],
    { cwd: directory, encoding: 'utf8', maxBuffer: 1024 * 1024, timeout: 30000, env: { ...process.env, NODE_PATH: '', NODE_OPTIONS: '' } });
    assert.equal(buildResult.status, 0, buildResult.stderr);
    assert.equal(JSON.parse(buildResult.stdout).acceptanceScope, 'observed-artifact-integrity-only');
    assert.match(invoke('0'.repeat(64)).stderr, /MANIFEST_HASH/);
    f.policy.checkers[0].kind = 'core-proof'; await writeFile(policyPath, JSON.stringify(f.policy));
    assert.match(invoke().stderr, /DISTRIBUTION_CHECKER_UNAVAILABLE/);
    f.policy.checkers[0].kind = 'wasm-literal'; await writeFile(policyPath, JSON.stringify(f.policy));
    const target = path.join(distribution.directory, 'scripts', 'semantic-lock.mjs'), original = await readFile(target);
    original[0] = 106; await writeFile(target, original);
    const changed = invoke(); assert.equal(changed.status, 1); assert.equal(changed.stdout, '');
    assert.match(changed.stderr, /FILE_HASH/);
  } finally {
    assert.equal(path.dirname(path.resolve(directory)), path.resolve(tmpdir()));
    await rm(directory, { recursive: true, force: true });
  }
});

function coreProofFixture(invalidProof = false) {
  // Actual closed proposition: forall P : Prop, P -> P. Its lambda proof uses
  // no imported theorem or axiom. The lock/task metadata is still fictional.
  const name = value => ({ k: 's', p: { k: 'a' }, v: value });
  const variable = i => ({ k: 'b', i });
  const bind = (k, n, t, b) => ({ k, n: name(n), t, b, bi: 'default' });
  const prop = { k: 'sort', l: { k: 'z' } };
  const theorem = { kind: 'constant', declaration: { k: 'theorem', lp: [], n: name('OfflineIdentity'),
    t: bind('forall', 'P', prop, bind('forall', 'h', variable(0), variable(1))),
    v: bind('lam', 'P', prop, bind('lam', 'h', variable(0), variable(0))) } };
  const admissions = value => canonicalBytes({ admissions: [value], format: 'proofscript-checked-admissions', version: 2 }).toString();
  const reference = admissions(theorem), f = semanticLockFixture();
  const theory = canonicalArtifact({ providerProfile: 'lean4.34-core', scope: 'closed-implication-identity-fixture' }, 'theory', 'fixture-theory/1');
  const expected = canonicalArtifact(JSON.parse(reference), 'canonical-admissions', 'proofscript-checked-admissions/2');
  const selected = coreProofCertificateChecker({ theoryBaseId: theory.identity, expectedAdmissions: reference,
    providers: ['lean434-wasm'], securityProfile: 'compatibility-v1' });
  if (invalidProof) theorem.declaration.v = { k: 'nat', v: '0' };
  const certificate = canonicalArtifact({ contract: 'psc-certificate/1', checkerId: 'lean-wasm-proof', subjectId: selected.subject.identity,
    payload: { admissions: admissions(theorem) } }, 'certificate', 'psc-certificate/1');
  const license = canonicalArtifact({ spdx: 'MIT' }, 'license', 'fixture-license/1');
  const context = { semanticIdentity: { semanticLockId: f.lock.identity }, scope: { profile: 'closed-identity-fixture' },
    allowedAssumptions: [], requiredClaims: ['identity'] };
  const knowledge = knowledgeObject({ contract: 'psc-knowledge-object/2', kind: 'proof', semanticIdentity: context.semanticIdentity,
    authorityClass: 'validation-authority', scope: context.scope, dependencies: [], assumptions: [],
    claims: [{ claimId: 'identity', status: 'validated', subjectId: selected.subject.identity, certificateId: certificate.identity }],
    payload: expected.identity, implementationWitnesses: [], evidence: [], provenance: [], resourceEvidence: [],
    license: license.identity, supersedes: [], migrations: [] });
  const manifest = canonicalArtifact({ contract: 'psc-evidence-manifest/1', semanticLockId: f.lock.identity, roots: [knowledge.identity],
    archive: [{ role: 'semantic-lock', artifact: f.lock.identity }, { role: 'certificate', artifact: certificate.identity }] },
  'evidence-manifest', 'psc-evidence-manifest/1');
  const capsule = packOfflineCapsule({ manifest, artifacts: [...f.artifacts, theory, expected, selected.subject, certificate, license, knowledge] });
  const policy = { contract: 'psc-offline-consumer-policy/1', expectedManifestId: manifest.identity, expectedSemanticLockId: f.lock.identity,
    semanticLockPolicy: f.policy, context, publicKeys: [], requiredSignerIds: [], requiredArchiveRoles: ['certificate'],
    checkers: [{ checkerId: 'lean-wasm-proof', kind: 'core-proof', theoryBaseId: theory.identity, expectedAdmissionsId: expected.identity,
      subjectId: selected.subject.identity, providers: ['lean434-wasm'], securityProfile: 'compatibility-v1' }],
    claims: [{ claimId: 'identity', subjectId: selected.subject.identity, checkerId: 'lean-wasm-proof', claimClass: 'kernel-checked-public-interface' }] };
  return { capsule, policy };
}

test('Lean Wasm distribution checks an actual closed proof, rejects an invalid proof and preserves provider policy', async () => {
  const directory = await mkdtemp(path.join(tmpdir(), 'psc-verifier-lean-dist-'));
  try {
    const distribution = await buildVerifierDistribution(path.join(directory, 'verifier'), { profile: 'lean434-wasm-offline/1' });
    const capsulePath = path.join(directory, 'capsule.json'), policyPath = path.join(directory, 'policy.json');
    const invoke = () => spawnSync(process.execPath, [path.join(distribution.directory, 'pscv-verify.mjs'),
      '--manifest-sha256', distribution.manifestSha256, '--capsule', capsulePath, '--policy', policyPath],
    { cwd: directory, encoding: 'utf8', maxBuffer: 1024 * 1024, timeout: 30000, env: { ...process.env, NODE_PATH: '', NODE_OPTIONS: '' } });
    const save = async f => { await writeFile(capsulePath, f.capsule.bytes); await writeFile(policyPath, JSON.stringify(f.policy)); };
    const f = coreProofFixture(); await save(f);
    const run = invoke(); assert.equal(run.status, 0, run.stdout + run.stderr);
    const result = JSON.parse(run.stdout); assert.equal(result.kind, 'accepted');
    assert.equal(result.validity.verifiedClaims[0].claimClass, 'kernel-checked-public-interface');
    assert.equal(result.releaseAccepted, false);
    await save(coreProofFixture(true));
    const invalid = invoke(); assert.equal(invalid.status, 1, invalid.stdout + invalid.stderr);
    assert.equal(JSON.parse(invalid.stdout).kind, 'rejectedInvalid');
    await save(f);
    for (const providers of [undefined, ['lean434'], ['pskernel-core'], ['lean434-wasm', 'pskernel-core']]) {
      f.policy.checkers[0].providers = providers; await writeFile(policyPath, JSON.stringify(f.policy));
      assert.match(invoke().stderr, /DISTRIBUTION_PROVIDER_UNAVAILABLE/);
    }
    f.policy.checkers[0].providers = ['lean434-wasm']; f.policy.checkers[0].securityProfile = 'paranoid-v1';
    await writeFile(policyPath, JSON.stringify(f.policy)); assert.match(invoke().stderr, /PROVIDER_SECURITY_REJECTED/);
    f.policy.checkers[0].securityProfile = 'compatibility-v1'; await writeFile(policyPath, JSON.stringify(f.policy));
    const wasm = path.join(distribution.directory, 'packages/pskernel-lean-wasm/wasm/pskernel-lean.wasm');
    const bytes = await readFile(wasm); bytes[bytes.length - 1] ^= 1; await writeFile(wasm, bytes);
    const changed = invoke(); assert.equal(changed.status, 1); assert.equal(changed.stdout, '');
    assert.match(changed.stderr, /FILE_HASH/);
  } finally {
    assert.equal(path.dirname(path.resolve(directory)), path.resolve(tmpdir()));
    await rm(directory, { recursive: true, force: true });
  }
});
