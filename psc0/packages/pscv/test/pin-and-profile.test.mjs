import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import {
  normativeSha256, pinnedLeanCommit, pinnedLeanVersion,
  extractLeanProvenanceBlueprint, evaluateLeanProvenance, canonicalJSON,
} from '../src/lean-provenance.mjs';
import {
  inspectPSCVProfile, activatePSCVProfile, profileInspectionProtocol,
} from '../../../scripts/pscv-profile-inspection.mjs';

const root = path.resolve(fileURLToPath(new URL('../../../../', import.meta.url)));
const profileFile = new URL('../profile.json', import.meta.url);
// Git's committed blob is the canonical normative byte sequence.
// Windows worktree line-ending conversion must not redefine that SHA256.
const ref = async () => execFileSync('git', [
  '-C', root, 'show', 'HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md',
], { encoding: 'utf8', timeout: 15000, maxBuffer: 2 * 1024 * 1024 });
const descriptor = async () => JSON.parse(await readFile(profileFile, 'utf8'));
const req = async () => ({
  rootProjectProfile: 'pscv-v1',
  assurancePolicy: 'pscv-closed-v1',
  descriptor: await descriptor(),
});

test('the exact normative RC3 reference owns all 40 Appendix K source roots', async () => {
  const source = await ref();
  const blueprint = extractLeanProvenanceBlueprint(source);
  assert.equal(blueprint.semanticPin.leanCommit, pinnedLeanCommit);
  assert.equal(blueprint.semanticPin.leanVersion, pinnedLeanVersion);
  assert.equal(blueprint.sourceReferenceSha256, normativeSha256);
  assert.equal(blueprint.roots.length, 40);
  assert.equal(blueprint.roots.filter(x => x.category === 'semantic').length, 23);
  assert.equal(blueprint.roots.filter(x => x.category === 'prover').length, 17);
  assert.equal(new Set(blueprint.roots.map(x => x.path)).size, 40);
  assert.match(blueprint.provenanceBlueprintSha256, /^[a-f0-9]{64}$/u);
  assert.equal(blueprint.standardManifestComplete, false);
  assert.equal(blueprint.registryOrderFrozen, false);
  assert.equal(blueprint.classParameterModesFrozen, false);
  assert.equal(blueprint.verificationRegistryFrozen, false);
  assert.equal(blueprint.activatedRegistries, null);
  assert.equal(blueprint.executableAuthorization, false);
  assert.equal(blueprint.pscvVerified, false);
  assert.equal(canonicalJSON(blueprint), canonicalJSON(JSON.parse(canonicalJSON(blueprint))));
});

test('normative source drift cannot masquerade as the frozen reference', async () => {
  const reference = await ref();
  assert.throws(() => extractLeanProvenanceBlueprint(reference.replace(
    'Lean 4.35.0-rc3', 'Lean 4.35.0-rc4')), /PSC_PSCV_PIN_AUDIT_NORMATIVE_REFERENCE_IDENTITY/u);
  assert.throws(() => extractLeanProvenanceBlueprint(reference + '\n'),
    /PSC_PSCV_PIN_AUDIT_NORMATIVE_REFERENCE_IDENTITY/u);
});

test('audit data contract rejects forged roots, commits and pseudo-Standard activation', async () => {
  const reference = await ref();
  const blueprint = extractLeanProvenanceBlueprint(reference);
  const good = {
    commit: pinnedLeanCommit,
    entries: blueprint.roots.map(row => ({
      path: row.path, gitBlobSha1: row.gitBlobSha1, sizeBytes: 100, lineCount: 3,
    })),
  };
  // Mocked rows test the schema validator; only the separately qualified
  // Git checkout auditor establishes that those bytes actually exist.
  const result = evaluateLeanProvenance(blueprint, good, reference);
  assert.equal(result.immutableSourceBlobsChecked, 40);
  assert.equal(result.registrySnapshotGenerated, false);
  assert.equal(result.registrySnapshotCanonicalSha256, null);
  assert.equal(result.verifiedExecutableAuthorized, false);
  assert.equal(result.fullPSCVConformance, false);
  assert.equal(result.pscvCertificateIssuerAvailable, false);
  assert.throws(() => evaluateLeanProvenance(blueprint, {
    ...good, commit:'0'.repeat(40),
  }, reference), /SOURCE_CHECKOUT_IDENTITY/u);
  assert.throws(() => evaluateLeanProvenance(blueprint, {
    ...good, entries: [...good.entries.slice(0, 39), {
      ...good.entries[39], gitBlobSha1:'0'.repeat(40),
    }],
  }, reference), /GIT_PROVENANCE_ENTRY/u);
  assert.throws(() => evaluateLeanProvenance({
    ...blueprint, activatedRegistries: {simp:['unsafe']},
  }, good, reference), /BLUEPRINT_IS_NOT_NORMATIVE/u);
  assert.throws(() => evaluateLeanProvenance({
    ...blueprint, executableAuthorization:true,
  }, good, reference), /BLUEPRINT_IS_NOT_NORMATIVE/u);
  assert.throws(() => evaluateLeanProvenance({
    ...blueprint, roots:[...blueprint.roots.slice(0,39)],
  }, good, reference), /BLUEPRINT_IS_NOT_NORMATIVE/u);
});

test('profile inspection is exact, pinned, explicit and ALWAYS refuses activation', async () => {
  const selected = await req();
  const blue = extractLeanProvenanceBlueprint(await ref());
  for (const assurancePolicy of ['pscv-closed-v1', 'pscv-boundary-v1']) {
    const output = inspectPSCVProfile({ ...selected, assurancePolicy, provenanceBlueprint:blue });
    assert.equal(output.protocol,profileInspectionProtocol);
    assert.equal(output.requestedProfile,'pscv-v1');
    assert.equal(output.assurancePolicy,assurancePolicy);
    assert.equal(output.state,'blocked-unqualified');
    assert.equal(output.profileActivated,false);
    assert.equal(output.verifiedExecutableAuthorized,false);
    assert.equal(output.pscvVerified,false);
    assert.equal(output.untrustedSourceBlueprintProvided,true);
    assert(output.reasons.includes('normative-registry-snapshot-missing'));
    assert(output.reasons.includes('certification-gate-unqualified'));
    assert(Object.isFrozen(output));
    assert(Object.isFrozen(output.reasons));
  }
  assert.throws(() => activatePSCVProfile({ profile:'pscv-v1' }),
    /PSC_PSCV_PROFILE_ACTIVATION_UNQUALIFIED/u);
});

test('untrusted metadata cannot weaken a closed profile or add loader authority', async () => {
  const base = await req();
  const variations = [
    { ...base, rootProjectProfile:'checked' },
    { ...base, assurancePolicy:'none' },
    { ...base, descriptor:{...base.descriptor,main:'./unsafe.js'} },
    { ...base, descriptor:{...base.descriptor,
      allowedToEmitVerifiedExecutable:true} },
    { ...base, descriptor:{...base.descriptor,
      installedPackageGrantsAuthority:true} },
    { ...base, descriptor:{...base.descriptor,
      runtimeCodeEntry:'./native-addon.node'} },
    { ...base, descriptor:{...base.descriptor,
      verifiedFeatures:['everything']} },
    { ...base, descriptor:{...base.descriptor,
      leanSemanticReference:{version:'4.35.0-rc4',commit:'0'.repeat(40)}} },
    { ...base, descriptor:{...base.descriptor,
      standardEnvironment:{identity: 'faked', registrySha256:'0'.repeat(64), status:'complete'}} },
    { ...base, descriptor:{...base.descriptor,
      sourceProfile:'ps-standard-0.9-r3'} },
  ];
  for (const item of variations) {
    assert.throws(() => inspectPSCVProfile(item),
      /PSC_PSCV_PROFILE_INSPECTION_/u);
  }
});

test('a simulated source audit can never activate the profile or certify a program', async () => {
  const valid = await req();
  const x = extractLeanProvenanceBlueprint(await ref());
  assert.equal(inspectPSCVProfile({ ...valid, provenanceBlueprint:x }).state,
    'blocked-unqualified');
  assert.throws(() => inspectPSCVProfile({
    ...valid, provenanceBlueprint:{...x, standardManifestComplete:true},
  }), /PROVENANCE_IS_NOT_ENVIRONMENT/u);
});
