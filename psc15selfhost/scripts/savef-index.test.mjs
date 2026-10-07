import assert from 'node:assert/strict';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { canonicalArtifact } from './artifact-evidence.mjs';
import { knowledgeObject } from './savef-graph.mjs';
import { buildSavefSemanticIndex, querySavefSemanticIndex } from './savef-index.mjs';

const semanticIdentity = { language: 'proofscript', profile: 'psc-v3' };
const scopeA = { package: 'a', version: 1 };
const scopeB = { package: 'b', version: 1 };
const payload = canonicalArtifact({ value: 1 }, 'payload', 'fixture/1');
const license = canonicalArtifact({ spdx: 'MIT' }, 'license', 'fixture-license/1');
function object(kind, scope, assumptions = [], claims = []) {
  return knowledgeObject({
    contract: 'psc-knowledge-object/2', kind, semanticIdentity, authorityClass: 'empirical-evidence', scope,
    dependencies: [], assumptions, claims, payload: payload.identity, implementationWitnesses: [], evidence: [],
    provenance: [], resourceEvidence: [], license: license.identity, supersedes: [], migrations: [],
  });
}

test('persistent semantic index returns candidates but never authority', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'psc-savef-index-'));
  try {
    const a = object('specification', scopeA, ['host'], [{ claimId: 'shape', status: 'empirical',
      subjectId: payload.identity, certificateId: null }]);
    const b = object('artifact', scopeB);
    const built = await buildSavefSemanticIndex({ root, records: [b, a] });
    assert.equal(built.objectCount, 2);
    assert.equal(built.authority, 'derived-non-authoritative');
    const exact = await querySavefSemanticIndex({ root, semanticIdentity, scope: scopeA,
      kinds: ['specification'], requiredClaimIds: ['shape'], allowedAssumptions: ['host'] });
    assert.equal(exact.candidates.length, 1);
    assert.deepEqual(exact.candidates[0], a.identity);
    assert.equal(exact.authority, 'untrusted-derived-index');
    assert.equal(exact.requiresValidUnderBeforeReuse, true);
    const denied = await querySavefSemanticIndex({ root, semanticIdentity, scope: scopeA, allowedAssumptions: [] });
    assert.equal(denied.candidates.length, 0);
    await writeFile(path.join(root, 'semantic-index.json'), '{"contract":"tampered"}');
    await assert.rejects(querySavefSemanticIndex({ root, semanticIdentity }), /PSC_SAVEF_INDEX_/);
  } finally { await rm(root, { recursive: true, force: true }); }
});
