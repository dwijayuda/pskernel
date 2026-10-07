import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import {
  certifiedModuleInterfaceArtifact,
  moduleInterfaceReuseRuleArtifact,
  verifyCertifiedModuleInterface,
  verifyExactBehavioralInterfaceReuse,
} from './module-interface-evidence.mjs';

const artifact = (value, domain, contract) => canonicalArtifact(value, domain, contract);

function fixture(label = 'proof') {
  const structural = artifact(['runtime-interface'], 'runtime-interface', 'psc-runtime-interface-json/1');
  const subjects = {
    specification: artifact({ specification: 'stable' }, 'specification', 'fixture-spec/1'),
    effects: artifact({ effects: [] }, 'effects', 'fixture-effects/1'),
    resources: artifact({ resources: 'bounded' }, 'resources', 'fixture-resources/1'),
    assumptions: artifact({ assumptions: [] }, 'assumptions', 'fixture-assumptions/1'),
  };
  const evidence = artifact({
    checkerId: 'fixture-interface-checker',
    label,
    structuralInterface: structural.identity,
    behavioral: Object.fromEntries(Object.entries(subjects).map(([key,item]) => [key,item.identity])),
  }, 'certificate', 'fixture-interface-evidence/1');
  const iface = certifiedModuleInterfaceArtifact({
    structuralInterface: structural.identity,
    behavioral: Object.fromEntries(Object.entries(subjects).map(([key,item]) => [key,item.identity])),
    evidence: [evidence.identity],
  });
  const objects = [structural, evidence, iface, ...Object.values(subjects)];
  return { structural, subjects, evidence, iface,
    blobs: new Map(objects.map(item => [artifactKey(item.identity), item.bytes])) };
}

const checker = new Map([['fixture-interface-checker', async (bytes, context) => {
  const value = JSON.parse(bytes);
  return { verified: artifactKey(value.structuralInterface) ===
    artifactKey(context.interfaceValue.structuralInterface) };
}]]);

test('certified interface replay checks structural, behavioral and evidence bytes', async () => {
  const value = fixture();
  const result = await verifyCertifiedModuleInterface(value.iface, {
    resolveArtifact: async id => value.blobs.get(artifactKey(id)),
    evidenceCheckers: checker,
    requireBehavioral: true,
  });
  assert.equal(result.authority, 'validated-interface-data-not-kernel-capability');
  assert.equal(result.verifiedEvidence.length, 1);
  await assert.rejects(verifyCertifiedModuleInterface(value.iface, {
    resolveArtifact: async id => value.blobs.get(artifactKey(id)),
    evidenceCheckers: new Map(),
    requireBehavioral: true,
  }), /EVIDENCE_CHECKER/);
});

test('reuse permits new proof bytes for identical subjects and rejects changed structure', async () => {
  const left = fixture('old-proof'), right = fixture('new-proof');
  const rule = moduleInterfaceReuseRuleArtifact();
  const blobs = new Map([...left.blobs, ...right.blobs, [artifactKey(rule.identity), rule.bytes]]);
  const accepted = await verifyExactBehavioralInterfaceReuse({
    previous: left.iface, current: right.iface, rule,
    resolveArtifact: async id => blobs.get(artifactKey(id)), evidenceCheckers: checker,
  });
  assert.equal(accepted.verified, true);
  const changedStructural = artifact(['changed'], 'runtime-interface', 'psc-runtime-interface-json/1');
  const changedEvidence = artifact({
    checkerId: 'fixture-interface-checker',
    label: 'changed-structure-proof',
    structuralInterface: changedStructural.identity,
    behavioral: Object.fromEntries(Object.entries(right.subjects).map(([key,item]) => [key,item.identity])),
  }, 'certificate', 'fixture-interface-evidence/1');
  const changed = certifiedModuleInterfaceArtifact({
    structuralInterface: changedStructural.identity,
    behavioral: Object.fromEntries(Object.entries(right.subjects).map(([key,item]) => [key,item.identity])),
    evidence: [changedEvidence.identity],
  });
  blobs.set(artifactKey(changedStructural.identity), changedStructural.bytes);
  blobs.set(artifactKey(changedEvidence.identity), changedEvidence.bytes);
  blobs.set(artifactKey(changed.identity), changed.bytes);
  await assert.rejects(verifyExactBehavioralInterfaceReuse({
    previous: left.iface, current: changed, rule,
    resolveArtifact: async id => blobs.get(artifactKey(id)), evidenceCheckers: checker,
  }), /STRUCTURAL_CHANGED/);
});
