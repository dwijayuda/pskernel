import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { artifactKey, canonicalArtifact, passDefinition, recordPassExecution } from './artifact-evidence.mjs';
import { storeEvidenceCache } from './evidence-cache.mjs';
import {
  certifiedModuleInterfaceArtifact,
  moduleInterfaceReuseRuleArtifact,
} from './module-interface-evidence.mjs';
import {
  semanticReuseCandidateArtifact,
  readSemanticEvidenceCache,
} from './semantic-query-cache.mjs';

const artifact = (value, domain, contract) => canonicalArtifact(value, domain, contract);

function interfaceFixture(label, subjects) {
  const certificate = artifact({
    checkerId: 'test-interface-checker',
    label,
    structuralInterface: subjects.structural.identity,
    behavioral: Object.fromEntries(['specification','effects','resources','assumptions']
      .map(field => [field, subjects[field].identity])),
  }, 'certificate', 'test-interface-evidence/1');
  const iface = certifiedModuleInterfaceArtifact({
    structuralInterface: subjects.structural.identity,
    behavioral: Object.fromEntries(['specification','effects','resources','assumptions']
      .map(field => [field, subjects[field].identity])),
    evidence: [certificate.identity],
  });
  return { iface, certificate };
}

function cacheFixture() {
  const implementation = artifact({ op: 'compile' }, 'implementation', 'test-implementation/1');
  const input = artifact({ input: 1 }, 'input', 'test-values/1');
  const output = artifact({ output: 1 }, 'output', 'test-values/1');
  const certificate = artifact({ value: 1 }, 'certificate', 'test-pass-certificate/1');
  const definition = passDefinition({ passId: 'test-semantic-cache/1', version: 1,
    inputContract: input.identity.contract, outputContract: output.identity.contract,
    semanticRelationId: 'test-pass-relation/1', resourceContractId: 'test-resource/1',
    determinismClass: 'deterministic', totalityClass: 'total', implementationId: implementation.identity,
    validatorId: 'test-pass-checker', theoremIds: [], assumptionIds: [] });
  const record = recordPassExecution({ definition, inputs: [input], outputs: [output],
    parameters: { inputClosureComplete: true }, semanticIdentity: { contract: 'test/1' },
    resourcePolicy: { maxSteps: 1 }, evidence: [{ kind: 'translation-validation',
      checkerId: 'test-pass-checker', artifact: certificate.identity }] });
  return { record, output, artifacts: [implementation,input,output,certificate,definition,record.action] };
}

test('behaviorally equal independently checked interfaces permit a validated cache hit', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'pscv-semantic-cache-'));
  try {
    const subjects = {
      structural: artifact(['runtime-interface'], 'runtime-interface', 'psc-runtime-interface-json/1'),
      specification: artifact({ spec: 'same' }, 'specification', 'test-spec/1'),
      effects: artifact({ effects: [] }, 'effects', 'test-effects/1'),
      resources: artifact({ budget: 'same' }, 'resources', 'test-resources/1'),
      assumptions: artifact({ assumptions: [] }, 'assumptions', 'test-assumptions/1'),
    };
    const previous = interfaceFixture('old-proof', subjects);
    const current = interfaceFixture('new-proof', subjects);
    assert.notEqual(artifactKey(previous.iface.identity), artifactKey(current.iface.identity));
    const rule = moduleInterfaceReuseRuleArtifact();
    const cached = cacheFixture();
    await storeEvidenceCache({ root, record: cached.record, artifacts: cached.artifacts });
    const objects = [rule, previous.iface, current.iface, previous.certificate, current.certificate,
      ...Object.values(subjects)];
    const blobs = new Map(objects.map(item => [artifactKey(item.identity), item.bytes]));
    const evidenceCheckers = new Map([
      ['test-interface-checker', async (bytes, context) => {
        const value = JSON.parse(bytes);
        const expected = context.interfaceValue;
        const same = artifactKey(value.structuralInterface) === artifactKey(expected.structuralInterface) &&
          ['specification','effects','resources','assumptions'].every(field =>
            artifactKey(value.behavioral[field]) === artifactKey(expected.behavioral[field]));
        return { verified: same };
      }],
      ['test-pass-checker', async (bytes, subject) => {
        const value = JSON.parse(bytes);
        return { verified: value.value === 1 && subject.semanticRelationId === 'test-pass-relation/1',
          kind: 'translation-validation', subject };
      }],
    ]);
    const candidate = semanticReuseCandidateArtifact({
      actionId: cached.record.action.identity,
      obligations: [{ previousInterface: previous.iface.identity,
        currentInterface: current.iface.identity, rule: rule.identity }],
    });
    const hit = await readSemanticEvidenceCache({
      root, candidate, expectedCandidateId: candidate.identity, expectedActionId: cached.record.action.identity, resolveArtifact: async id => blobs.get(artifactKey(id)),
      evidenceCheckers, requiredEvidenceKinds: ['translation-validation'],
    });
    assert.equal(hit.hit, true);
    assert.equal(hit.semanticReuse.length, 1);
    assert.equal(hit.semanticReuse[0].verified, true);
    assert.equal(hit.authority, 'validated-semantic-reuse-and-pass-data-not-kernel-capability');
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('changed behavioral subject or absent evidence checker rejects before reuse', async () => {
  const structural = artifact(['runtime-interface'], 'runtime-interface', 'psc-runtime-interface-json/1');
  const common = {
    structural,
    effects: artifact({ effects: [] }, 'effects', 'test-effects/1'),
    resources: artifact({ budget: 'same' }, 'resources', 'test-resources/1'),
    assumptions: artifact({ assumptions: [] }, 'assumptions', 'test-assumptions/1'),
  };
  const oldSubjects = { ...common, specification: artifact({ spec: 'old' }, 'specification', 'test-spec/1') };
  const newSubjects = { ...common, specification: artifact({ spec: 'new' }, 'specification', 'test-spec/1') };
  const previous = interfaceFixture('old', oldSubjects);
  const current = interfaceFixture('new', newSubjects);
  const rule = moduleInterfaceReuseRuleArtifact(), cached = cacheFixture();
  const candidate = semanticReuseCandidateArtifact({ actionId: cached.record.action.identity,
    obligations: [{ previousInterface: previous.iface.identity, currentInterface: current.iface.identity, rule: rule.identity }] });
  const all = [rule, previous.iface, current.iface, previous.certificate, current.certificate,
    ...Object.values(oldSubjects), ...Object.values(newSubjects)];
  const blobs = new Map(all.map(item => [artifactKey(item.identity), item.bytes]));
  const root = await mkdtemp(path.join(tmpdir(), 'pscv-semantic-cache-negative-'));
  try {
    await storeEvidenceCache({ root, record: cached.record, artifacts: cached.artifacts });
    await assert.rejects(readSemanticEvidenceCache({
      root, candidate, expectedCandidateId: candidate.identity, expectedActionId: cached.record.action.identity, resolveArtifact: async id => blobs.get(artifactKey(id)),
      evidenceCheckers: new Map(), requiredEvidenceKinds: ['translation-validation'],
    }), /EVIDENCE_CHECKER/);
    const checker = new Map([['test-interface-checker', async () => ({ verified: true })]]);
    await assert.rejects(readSemanticEvidenceCache({
      root, candidate, expectedCandidateId: candidate.identity, expectedActionId: cached.record.action.identity, resolveArtifact: async id => blobs.get(artifactKey(id)),
      evidenceCheckers: checker, requiredEvidenceKinds: ['translation-validation'],
    }), /BEHAVIORAL_CHANGED/);
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('a cached proposal cannot select its own action or erase consumer obligations', async () => {
  const cached = cacheFixture();
  const candidate = semanticReuseCandidateArtifact({ actionId: cached.record.action.identity });
  const otherAction = artifact({ unrelated: true }, 'action', 'psc-action/1');
  const altered = semanticReuseCandidateArtifact({ actionId: otherAction.identity });
  const policy = { root: 'must-not-read', candidate, expectedCandidateId: candidate.identity,
    expectedActionId: cached.record.action.identity, requiredEvidenceKinds: ['translation-validation'],
    resolveArtifact: () => { throw new Error('must reject before resolving'); } };
  await assert.rejects(readSemanticEvidenceCache({ ...policy, expectedCandidateId: undefined }), /CONSUMER_SELECTION_REQUIRED/);
  await assert.rejects(readSemanticEvidenceCache({ ...policy, candidate: altered }), /CANDIDATE_SELECTION/);
  await assert.rejects(readSemanticEvidenceCache({ ...policy, expectedActionId: otherAction.identity }), /ACTION_SELECTION/);
  const omitted = semanticReuseCandidateArtifact({ actionId: cached.record.action.identity,
    obligations: [{ previousInterface: otherAction.identity, currentInterface: otherAction.identity, rule: otherAction.identity }] });
  await assert.rejects(readSemanticEvidenceCache({ ...policy, expectedCandidateId: omitted.identity }), /CANDIDATE_SELECTION/);
});
