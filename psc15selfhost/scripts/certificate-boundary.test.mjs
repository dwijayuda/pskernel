import assert from 'node:assert/strict';
import { test } from 'node:test';
import { canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { createCertificateBoundary, coreProofCertificateChecker } from './certificate-boundary.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';

// Mock kernel decisions test routing and ownership, not theorem validity.
const reference = canonicalBytes({ admissions: [], format: 'proofscript-checked-admissions', version: 2 }).toString();
const theory = canonicalArtifact({ theoryId: 'fixture' }, 'theory', 'test-theory/1');
function fixture(check = async (_source, selector) => ({ result: { ...checkedKernelIdentity(selector), accepted: true } })) {
  const { checker, subject } = coreProofCertificateChecker({ theoryBaseId: theory.identity, expectedAdmissions: reference, check });
  const boundary = createCertificateBoundary({ checkers: new Map([['core-proof', checker]]) });
  const certificate = canonicalArtifact({ contract: 'psc-certificate/1', checkerId: 'core-proof',
    subjectId: subject.identity, payload: { admissions: reference } }, 'certificate', 'psc-certificate/1');
  return { boundary, subject, certificate };
}

test('registered Core checker binds actual proof interface and creates only a live scoped certificate handle', async () => {
  const { boundary, subject, certificate } = fixture();
  const result = await boundary.check({ subject, certificate });
  assert.equal(result.kind, 'accepted');
  const receipt = boundary.describe(result.value);
  assert.equal(receipt.claimClass, 'kernel-checked-public-interface');
  assert.equal(receipt.executablePreservation, 'not-implied');
  assert.throws(() => boundary.describe(JSON.parse(JSON.stringify(result.value))), /NOT_LIVE/);
  boundary.revoke(result.value); assert.throws(() => boundary.describe(result.value), /NOT_LIVE/);
});

test('solver assertions, unknown checker IDs and wrong subjects cannot create evidence', async () => {
  const { boundary, subject, certificate } = fixture();
  const raw = canonicalArtifact({ solver: 'external', status: 'unsat', verified: true }, 'certificate', 'psc-certificate/1');
  assert.equal((await boundary.check({ subject, certificate: raw })).kind, 'rejectedInvalid');
  const unknown = JSON.parse(certificate.bytes); unknown.checkerId = 'https://untrusted.invalid/checker';
  assert.equal((await boundary.check({ subject, certificate: canonicalArtifact(unknown, 'certificate', 'psc-certificate/1') })).kind, 'declinedUnsupported');
  const other = canonicalArtifact({ statement: 'unrelated' }, 'proof-subject', 'psc-core-proof-subject/1');
  assert.equal((await boundary.check({ subject: other, certificate })).kind, 'rejectedInvalid');
});

test('infrastructure and inconclusive checker failures are not false semantic rejections', async () => {
  const failed = fixture(async () => { throw Object.assign(new Error('checker missing'), { code: 'ENOENT' }); });
  assert.equal((await failed.boundary.check(failed)).kind, 'infrastructureUnavailable');
  const unknown = fixture(async (_source, selector) => ({ result: { ...checkedKernelIdentity(selector), accepted: false,
    errorKind: 'kernel-rejection', message: 'resource budget exhausted', declarationIndex: 0 } }));
  assert.equal((await unknown.boundary.check(unknown)).kind, 'declinedUnsupported');
});
