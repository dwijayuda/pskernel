import assert from 'node:assert/strict';
import { test } from 'node:test';
import { canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { comparatorAdmissionsInterface, decodeComparatorExport, decodeComparatorJson } from './comparator-export.mjs';

const encode = admissions => canonicalBytes({ admissions, format: 'proofscript-checked-admissions', version: 2 }).toString();
const theorem = { kind: 'constant', declaration: { k: 'theorem', lp: [], n: { k: 'anonymous' },
  t: { k: 'sort', l: { k: 'zero' } }, v: { k: 'nat', v: '0' } } };

test('trusted projection permits a different proof but forbids a different statement or an added axiom', () => {
  const reference = encode([theorem]);
  const source = canonicalArtifact({ source: 'fixture' }, 'source', 'test-source/1');
  const value = { nonce: 'trusted-challenge', sourceClosureId: source.identity,
    expectedInterfaceId: comparatorAdmissionsInterface(reference).identity };
  const challenge = { value, ...canonicalArtifact(value, 'challenge', 'psc-comparator-challenge/1') };
  const changedProof = structuredClone(theorem); changedProof.declaration.v = { k: 'nat', v: '1' };
  const envelope = admissions => canonicalBytes({ contract: 'psc-comparator-export/1', challengeId: challenge.identity,
    sourceClosureId: source.identity, admissions });
  assert.equal(decodeComparatorExport(envelope(encode([changedProof])), challenge).admissions, encode([changedProof]));
  const changedStatement = structuredClone(theorem); changedStatement.declaration.t = { k: 'nat', v: '42' };
  assert.throws(() => decodeComparatorExport(envelope(encode([changedStatement])), challenge), /statement-or-interface/);
  assert.throws(() => comparatorAdmissionsInterface(encode([{ kind: 'constant', declaration: { k: 'axiom' } }])), /axiom-forbidden/);
  // These fixtures are decoder/projection data, not valid Lean proofs. Kernel
  // acceptance is deliberately outside this test and remains mandatory.
});

test('decoder rejects duplicate keys, malformed UTF-8, unknown forms and structural exhaustion', () => {
  assert.throws(() => decodeComparatorJson(Buffer.from('{"x":1,"x":2}')), /not-canonical/);
  assert.throws(() => decodeComparatorJson(Buffer.from([0xff])), /export-json/);
  assert.throws(() => comparatorAdmissionsInterface(encode([{ kind: 'future-admission', declaration: {} }])), /unsupported/);
  assert.throws(() => decodeComparatorJson(canonicalBytes([[[1]]]), { maxDepth: 1 }), error => error.kind === 'resourceExhausted');
  assert.throws(() => comparatorAdmissionsInterface(encode([theorem]), { maxAdmissions: 0 }), error => error.kind === 'resourceExhausted');
});
