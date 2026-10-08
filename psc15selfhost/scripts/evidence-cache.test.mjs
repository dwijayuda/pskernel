import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { artifactKey, canonicalArtifact, passDefinition, recordPassExecution } from './artifact-evidence.mjs';
import { storeEvidenceCache, readEvidenceCache } from './evidence-cache.mjs';

function fixture(outputValue = 7, complete = true) {
  const implementation = canonicalArtifact({ operation: 'identity' }, 'implementation', 'test-implementation/1');
  const input = canonicalArtifact({ value: 7 }, 'input', 'test-values/1');
  const output = canonicalArtifact({ value: outputValue }, 'output', 'test-values/1');
  const certificate = canonicalArtifact({ value: 7 }, 'certificate', 'test-identity-certificate/1');
  const definition = passDefinition({ passId: 'test-identity/1', version: 1, inputContract: 'test-values/1',
    outputContract: 'test-values/1', semanticRelationId: 'test-identity-relation/1', resourceContractId: 'test-resource/1',
    determinismClass: 'deterministic', totalityClass: 'total', implementationId: implementation.identity,
    validatorId: 'test-identity-checker', theoremIds: [], assumptionIds: [] });
  const record = recordPassExecution({ definition, inputs: [input], outputs: [output],
    parameters: { inputClosureComplete: complete }, semanticIdentity: { contract: 'test-values/1' },
    resourcePolicy: { maxSteps: 1 }, evidence: [{ kind: 'translation-validation',
      checkerId: 'test-identity-checker', artifact: certificate.identity }] });
  const evidenceCheckers = new Map([['test-identity-checker', async (bytes, subject) => {
    const data = JSON.parse(bytes);
    const expectedInput = canonicalArtifact(data, 'input', 'test-values/1');
    const expectedOutput = canonicalArtifact(data, 'output', 'test-values/1');
    const verified = subject.semanticRelationId === 'test-identity-relation/1' &&
      subject.inputs.length === 1 && subject.outputs.length === 1 &&
      artifactKey(subject.inputs[0]) === artifactKey(expectedInput.identity) &&
      artifactKey(subject.outputs[0]) === artifactKey(expectedOutput.identity);
    return { verified, kind: 'translation-validation', subject };
  }]]);
  return { record, artifacts: [implementation, input, output, definition, certificate, record.action], output,
    options: { actionId: record.action.identity, requiredEvidenceKinds: ['translation-validation'], evidenceCheckers } };
}

test('untrusted cache checks evidence on every hit and rejects a hash-consistent forged result', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'pscv-evidence-cache-'));
  try {
    const good = fixture();
    await storeEvidenceCache({ root, ...good });
    const hit = await readEvidenceCache({ root, ...good.options });
    assert.equal(hit.hit, true);
    assert.deepEqual(hit.outputs[0].bytes, good.output.bytes);
    assert.equal(hit.authority, 'validated-data-not-kernel-capability');
    assert.equal((await readEvidenceCache({ root, ...good.options, evidenceCheckers: new Map() })).hit, false);
    // Re-hash and publish a false output, along with a consistent new execution
    // record. The requested action is unchanged; hashes alone would accept it.
    const forged = fixture(8);
    assert.equal(artifactKey(forged.record.action.identity), artifactKey(good.record.action.identity));
    await storeEvidenceCache({ root, ...forged });
    const rejected = await readEvidenceCache({ root, ...good.options });
    assert.equal(rejected.hit, false);
    assert.match(rejected.reason, /EVIDENCE_REJECTED/);
    await storeEvidenceCache({ root, ...good });
    await writeFile(path.join(root, 'blob-' + artifactKey(good.output.identity)), 'corrupt');
    assert.equal((await readEvidenceCache({ root, ...good.options })).hit, false);
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('incomplete closure, wrong action, absent evidence policy and resource limits fail closed', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'pscv-evidence-budget-'));
  try {
    const incomplete = fixture(7, false);
    await storeEvidenceCache({ root, ...incomplete });
    assert.match((await readEvidenceCache({ root, ...incomplete.options })).reason, /CLOSURE_INCOMPLETE/);
    const good = fixture();
    assert.equal((await readEvidenceCache({ root, ...good.options })).hit, false);
    await storeEvidenceCache({ root, ...good });
    assert.equal((await readEvidenceCache({ root, ...good.options, limits: { maxTotalBytes: 10 } })).hit, false);
    assert.equal((await readEvidenceCache({ root, ...good.options, limits: { maxArtifacts: 1 } })).hit, false);
    await assert.rejects(readEvidenceCache({ root, ...good.options, requiredEvidenceKinds: [] }), /POLICY_REQUIRED/);
  } finally { await rm(root, { recursive: true, force: true }); }
});
