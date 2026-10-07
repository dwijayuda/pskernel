import { artifactId, canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';

const copy = value => JSON.parse(canonicalBytes(value));
const text = value => typeof value === 'string' && value.length > 0;

export function createPscvCertification({
  source, admissions, semanticProfile, kernelContract, provider, providerSecurity,
  assumptionPolicy, resourcePolicy, targets, executionBoundary,
}) {
  if (typeof source !== 'string' || typeof admissions !== 'string') throw new Error('PSCV_CERT_SOURCE_OR_ADMISSIONS');
  if (!text(semanticProfile) || !text(assumptionPolicy) || !text(resourcePolicy) || !text(executionBoundary))
    throw new Error('PSCV_CERT_CONTEXT');
  if (!kernelContract?.id || !kernelContract?.sha256 || !provider?.protocol || !provider?.provider ||
      provider.profile !== semanticProfile || providerSecurity?.contract !== 'psc-provider-security/1' ||
      !text(providerSecurity.profile)) throw new Error('PSCV_CERT_AUTHORITY_CONTEXT');
  if (!Array.isArray(targets) || targets.length === 0 || targets.some(target => !text(target)) ||
      new Set(targets).size !== targets.length) throw new Error('PSCV_CERT_TARGETS');

  const sourceBytes = Buffer.from(source, 'utf8');
  const admissionsBytes = Buffer.from(admissions, 'utf8');
  const sourceId = artifactId(sourceBytes, 'source-bytes', 'psc-certified-source-input/1');
  const canonicalAdmissionsId = artifactId(admissionsBytes, 'canonical-admissions', 'proofscript-checked-admissions/2');
  const context = {
    semanticProfile,
    kernelContract: copy(kernelContract),
    provider: copy(provider),
    providerSecurity: copy(providerSecurity),
    assumptionPolicy,
    resourcePolicy,
    targets: [...targets],
    executionBoundary,
  };
  const certificate = canonicalArtifact({
    schemaVersion: 1,
    contract: 'pscv-cert/1',
    sourceId,
    canonicalAdmissionsId,
    context,
    claim: 'kernel-accepted-canonical-admissions-produced-from-exact-source',
    authority: 'serializable-evidence-not-live-capability',
    frontendAndEncodingTrust: 'explicit-current-trust-boundary',
    executablePreservation: 'not-implied',
    globalProofStatus: 'not-claimed',
  }, 'pscv-cert', 'pscv-cert/1');
  const certifiedSource = canonicalArtifact({
    schemaVersion: 1,
    contract: 'psc-certified-source/1',
    certificateId: certificate.identity,
    sourceId,
    canonicalAdmissionsId,
    semanticProfile,
    targets: [...targets],
    authority: 'requires-live-certified-source-capability-for-transformation',
    transformationAssurance: 'separate-explicit-obligations',
  }, 'certified-source', 'psc-certified-source/1');
  return Object.freeze({ certificate, certifiedSource });
}

export function createCertifiedSourceSession(checkedSession, { executionBoundary = 'generated-js-checked-service' } = {}) {
  if (!checkedSession || typeof checkedSession.describe !== 'function' ||
      typeof checkedSession.certificationSubject !== 'function' || typeof checkedSession.revoke !== 'function' ||
      typeof checkedSession.close !== 'function') throw new Error('PSCV_CERT_CHECKED_SESSION');
  if (!text(executionBoundary)) throw new Error('PSCV_CERT_EXECUTION_BOUNDARY');
  const live = new WeakMap();
  let closed = false;
  function requireOpen() { if (closed) throw new Error('PSCV_CERTIFIED_SOURCE_SESSION_CLOSED'); }
  function item(handle) {
    requireOpen();
    const found = handle !== null && typeof handle === 'object' ? live.get(handle) : undefined;
    if (!found) throw new Error('PSCV_CERTIFIED_SOURCE_NOT_LIVE');
    return found;
  }
  return Object.freeze({
    certify(checkedCoreHandle) {
      requireOpen();
      const checkedCore = checkedSession.describe(checkedCoreHandle);
      const subject = checkedSession.certificationSubject(checkedCoreHandle);
      const records = createPscvCertification({
        source: subject.source,
        admissions: subject.admissions,
        semanticProfile: checkedCore.semanticProfile,
        kernelContract: checkedCore.kernelContract,
        provider: checkedCore.provider,
        providerSecurity: checkedCore.providerSecurity,
        assumptionPolicy: checkedCore.assumptionPolicy,
        resourcePolicy: checkedCore.resourcePolicy,
        targets: checkedCore.targets,
        executionBoundary,
      });
      const handle = Object.freeze({
        capability: 'psc-certified-source-capability/1',
        certificateId: copy(records.certificate.identity),
        certifiedSourceId: copy(records.certifiedSource.identity),
        semanticProfile: checkedCore.semanticProfile,
        targets: Object.freeze([...checkedCore.targets]),
      });
      live.set(handle, { checkedCoreHandle, records });
      return handle;
    },
    describe(handle) {
      const found = item(handle);
      return Object.freeze({
        identity: copy(found.records.certifiedSource.identity),
        ...copy(JSON.parse(found.records.certifiedSource.bytes)),
      });
    },
    certificate(handle) {
      const found = item(handle);
      return Object.freeze({ identity: copy(found.records.certificate.identity), bytes: Buffer.from(found.records.certificate.bytes) });
    },
    certifiedSourceArtifact(handle) {
      const found = item(handle);
      return Object.freeze({ identity: copy(found.records.certifiedSource.identity), bytes: Buffer.from(found.records.certifiedSource.bytes) });
    },
    checkedCore(handle) { return item(handle).checkedCoreHandle; },
    revoke(handle) {
      const found = item(handle);
      live.delete(handle);
      checkedSession.revoke(found.checkedCoreHandle);
    },
    close() {
      if (closed) return;
      closed = true;
      checkedSession.close();
    },
  });
}
