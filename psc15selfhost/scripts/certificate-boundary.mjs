import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson, comparatorAdmissionsInterface } from './comparator-export.mjs';
import { checkAdmissionsWithKernel } from './checked-kernel-provider.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';
import { assertProviderSecurity } from './provider-security.mjs';
import { semanticDecision } from './checked-kernel-dual.mjs';

const copy = value => JSON.parse(canonicalBytes(value));

/** Only host-registered checkers may interpret certificates. Solver success,
 * checker URLs and serialized verified flags have no authority here.
 */
export function createCertificateBoundary({ checkers, limits = {} }) {
  if (!(checkers instanceof Map)) throw new Error('PSC_CERTIFICATE_CHECKER_REGISTRY');
  limits = copy(limits);
  const selected = new Map([...checkers].map(([id, checker]) => [id, Object.freeze({
    verify: checker.verify, claimClass: checker.claimClass, identity: copy(checker.identity),
  })])), handles = new WeakMap();
  let closed = false;
  return Object.freeze({
    async check({ certificate, subject }) {
      if (closed) throw new Error('PSC_CERTIFICATE_SESSION_CLOSED');
      let phase = 'decode';
      try {
        const byteLimit = limits.maxBytes ?? 16 * 1024 * 1024;
        if (certificate.bytes.byteLength > byteLimit || subject.bytes.byteLength > byteLimit) return { kind: 'resourceExhausted', resource: 'certificateBytes' };
        subject = { bytes: Buffer.from(subject.bytes), identity: copy(subject.identity) };
        certificate = { bytes: Buffer.from(certificate.bytes), identity: copy(certificate.identity) };
        verifyArtifact(subject.bytes, subject.identity);
        verifyArtifact(certificate.bytes, certificate.identity);
        if (certificate.identity.domain !== 'certificate' || certificate.identity.contract !== 'psc-certificate/1') {
          return { kind: 'rejectedInvalid', code: 'certificate-artifact-contract' };
        }
        const envelope = decodeComparatorJson(certificate.bytes, limits);
        if (envelope.contract !== 'psc-certificate/1' ||
            Object.keys(envelope).sort().join(',') !== 'checkerId,contract,payload,subjectId') return { kind: 'rejectedInvalid', code: 'certificate-schema' };
        if (artifactKey(envelope.subjectId) !== artifactKey(subject.identity)) return { kind: 'rejectedInvalid', code: 'certificate-subject' };
        const checker = selected.get(envelope.checkerId);
        if (!checker || typeof checker.verify !== 'function') return { kind: 'declinedUnsupported', feature: 'certificate-checker' };
        const payload = canonicalBytes(envelope.payload, limits);
        phase = 'checker';
        const result = await checker.verify(payload, { bytes: Buffer.from(subject.bytes), identity: copy(subject.identity) });
        if (closed) return { kind: 'resourceExhausted', resource: 'cancelled' };
        if (result?.kind !== 'accepted') return ['rejectedInvalid', 'declinedUnsupported', 'resourceExhausted', 'internalError', 'infrastructureUnavailable'].includes(result?.kind)
          ? result : { kind: 'internalError', code: 'certificate-checker-result' };
        if (result.claimClass !== checker.claimClass || artifactKey(result.subjectId) !== artifactKey(subject.identity)) {
          return { kind: 'internalError', code: 'certificate-checker-subject' };
        }
        const receipt = canonicalArtifact({ contract: 'psc-certificate-validation/1', subjectId: subject.identity,
          certificateId: certificate.identity, checkerId: envelope.checkerId, checkerIdentity: checker.identity,
          claimClass: checker.claimClass, evidence: result.evidence, executablePreservation: 'not-implied' },
        'certificate-validation', 'psc-certificate-validation/1');
        const handle = Object.freeze({ capability: 'psc-live-certificate-validation/1', receiptId: receipt.identity });
        handles.set(handle, copy(JSON.parse(receipt.bytes)));
        return { kind: 'accepted', value: handle, receipt };
      } catch (error) {
        return { kind: error.kind === 'resourceExhausted' || /EXHAUSTED/u.test(error.message) ? 'resourceExhausted' :
          error.kind === 'inconclusive' ? 'declinedUnsupported' : phase === 'checker' ? 'internalError' : 'rejectedInvalid', code: error.code ?? error.message };
      }
    },
    describe(handle) {
      if (closed || !handles.has(handle)) throw new Error('PSC_CERTIFICATE_NOT_LIVE');
      return copy(handles.get(handle));
    },
    revoke(handle) {
      if (closed || !handles.has(handle)) throw new Error('PSC_CERTIFICATE_NOT_LIVE');
      handles.delete(handle);
    },
    close() { closed = true; },
  });
}

/** An external solver may supply Core proof terms for an exact caller-selected
 * public theorem interface. This adapter never maps an arbitrary theorem to a
 * global compiler-preservation claim. That mapping requires its own contract.
 */
export function coreProofCertificateChecker({ theoryBaseId, expectedAdmissions, providers = ['lean434-wasm', 'pskernel-core'],
  securityProfile = 'compatibility-v1', check = checkAdmissionsWithKernel, timeoutMs = 60000 }) {
  const expected = comparatorAdmissionsInterface(expectedAdmissions);
  const selectors = [...providers];
  if (!selectors.length || selectors.length > 4 || new Set(selectors).size !== selectors.length) throw new Error('PSC_CERTIFICATE_PROVIDER_SET');
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > 2147483647) throw new Error('PSC_CERTIFICATE_TIMEOUT');
  const identities = selectors.map(checkedKernelIdentity);
  for (const selector of selectors) assertProviderSecurity(selector, securityProfile);
  if (identities.some(identity => identity.profile !== identities[0].profile)) throw new Error('PSC_CERTIFICATE_SEMANTIC_PROFILE');
  const subject = canonicalArtifact({ contract: 'psc-core-proof-subject/1', theoryBaseId,
    semanticProfile: identities[0].profile, expectedInterfaceId: expected.identity }, 'proof-subject', 'psc-core-proof-subject/1');
  const checker = Object.freeze({
    claimClass: 'kernel-checked-public-interface',
    identity: { contract: 'psc-core-proof-certificate-checker/1', providers: copy(identities), securityProfile },
    async verify(bytes, requested) {
      if (artifactKey(requested.identity) !== artifactKey(subject.identity)) return { kind: 'rejectedInvalid', code: 'proof-subject-mismatch' };
      const payload = decodeComparatorJson(bytes);
      if (Object.keys(payload).join(',') !== 'admissions' || typeof payload.admissions !== 'string') return { kind: 'rejectedInvalid', code: 'proof-payload' };
      const actual = comparatorAdmissionsInterface(payload.admissions);
      if (artifactKey(actual.identity) !== artifactKey(expected.identity)) return { kind: 'rejectedInvalid', code: 'proof-statement-mismatch' };
      const decisions = [], evidence = [];
      for (let index = 0; index < selectors.length; index++) {
        let checked;
        try { checked = await check(payload.admissions, selectors[index], { securityProfile, timeoutMs }); }
        catch (error) { return { kind: 'infrastructureUnavailable', code: error.code ?? error.message }; }
        for (const [field, value] of Object.entries(identities[index])) {
          if (checked.result?.[field] !== value) return { kind: 'infrastructureUnavailable', code: 'proof-checker-identity' };
        }
        decisions.push(semanticDecision(checked.result, JSON.parse(payload.admissions).admissions.length));
        evidence.push({ provider: identities[index], decision: decisions[index] });
      }
      if (decisions.some(value => value === 'inconclusive') || new Set(decisions).size !== 1) return { kind: 'declinedUnsupported', feature: 'proof-checker-disagreement-or-inconclusive' };
      if (decisions[0] !== 'accepted') return { kind: 'rejectedInvalid', code: 'proof-kernel-rejection' };
      return { kind: 'accepted', claimClass: 'kernel-checked-public-interface', subjectId: subject.identity, evidence };
    },
  });
  return { checker, subject };
}
