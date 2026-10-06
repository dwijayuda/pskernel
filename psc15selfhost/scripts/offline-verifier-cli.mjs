import { artifactId, artifactKey } from './artifact-evidence.mjs';
import { compareSemanticLocks } from './semantic-lock.mjs';
import { wasmLiteralCertificateChecker } from './wasm-literal-certificate.mjs';
import { createCertificateBoundary, coreProofCertificateChecker } from './certificate-boundary.mjs';
import { readOfflineCapsule, unpackOfflineCapsule, verifyOfflineCapsule } from './offline-capsule.mjs';
import { verifyObservedBuildArchive } from './observed-build-archive.mjs';

export async function verifyBuildArchiveCommand(archivePath, policyPath) {
  const policyBytes = await readOfflineCapsule(policyPath, { maxCapsuleBytes: 4 * 1024 * 1024 });
  const policy = JSON.parse(policyBytes);
  if (policy.contract !== 'psc-observed-build-consumer-policy/1') throw new Error('PSC_BUILD_ARCHIVE_POLICY');
  const bytes = await readOfflineCapsule(archivePath, { maxCapsuleBytes: policy.resourceLimits?.maxArchiveBytes ?? 256 * 1024 * 1024 });
  return verifyObservedBuildArchive(bytes, policy);
}

export async function compareSemanticLockFiles(leftPath, rightPath) {
  const locks = [];
  for (const file of [leftPath, rightPath]) {
    const bytes = await readOfflineCapsule(file, { maxCapsuleBytes: 8 * 1024 * 1024 });
    locks.push({ bytes, identity: artifactId(bytes, 'semantic-lock', 'psc-semantic-lock/1') });
  }
  return compareSemanticLocks(...locks);
}

/** Policy is an explicitly selected, trusted LOCAL file. The capsule never
 * supplies it. Only built-in checker adapters are selectable, never module URLs.
 * Kernel providers require their pinned local assets; no compiler is loaded.
 */
export async function verifyCapsuleCommand(capsulePath, policyPath,
  { allowedCheckerKinds = ['core-proof', 'wasm-literal'], allowedCoreProviders = null } = {}) {
  const supported = new Set(allowedCheckerKinds);
  const providers = allowedCoreProviders === null ? null : new Set(allowedCoreProviders);
  // A policy is trusted configuration, but a mistyped large file still gets a cap.
  const policyBytes = await readOfflineCapsule(policyPath, { maxCapsuleBytes: 4 * 1024 * 1024 });
  const policy = JSON.parse(policyBytes);
  if (policy.contract !== 'psc-offline-consumer-policy/1' || !Array.isArray(policy.checkers) ||
      !Array.isArray(policy.claims) || !Array.isArray(policy.publicKeys)) throw new Error('PSC_OFFLINE_POLICY');
  const bytes = await readOfflineCapsule(capsulePath, policy.resourceLimits);
  const capsule = unpackOfflineCapsule(bytes, { expectedManifestId: policy.expectedManifestId,
    resourceLimits: policy.resourceLimits });
  const checkers = new Map();
  for (const entry of policy.checkers) {
    if (typeof entry.checkerId !== 'string' || !entry.checkerId || checkers.has(entry.checkerId)) throw new Error('PSC_OFFLINE_CHECKER_POLICY');
    if (!supported.has(entry.kind)) throw new Error('PSC_OFFLINE_DISTRIBUTION_CHECKER_UNAVAILABLE: ' + entry.kind);
    let selected;
    if (entry.kind === 'core-proof') {
      if (providers && (!Array.isArray(entry.providers) || !entry.providers.length || entry.providers.some(value => !providers.has(value)))) {
        throw new Error('PSC_OFFLINE_DISTRIBUTION_PROVIDER_UNAVAILABLE');
      }
      capsule.resolveArtifact(entry.theoryBaseId);
      const expectedAdmissions = new TextDecoder('utf-8', { fatal: true }).decode(capsule.resolveArtifact(entry.expectedAdmissionsId));
      selected = coreProofCertificateChecker({ theoryBaseId: entry.theoryBaseId, expectedAdmissions,
        providers: entry.providers, securityProfile: entry.securityProfile, timeoutMs: entry.timeoutMs });
    } else if (entry.kind === 'wasm-literal') {
      selected = wasmLiteralCertificateChecker({ binary: { identity: entry.binaryId, bytes: capsule.resolveArtifact(entry.binaryId) },
        expectation: { identity: entry.expectationId, bytes: capsule.resolveArtifact(entry.expectationId) }, resourceLimits: entry.resourceLimits });
    } else throw new Error('PSC_OFFLINE_CHECKER_POLICY');
    if (artifactKey(selected.subject.identity) !== artifactKey(entry.subjectId)) throw new Error('PSC_OFFLINE_CHECKER_SUBJECT');
    checkers.set(entry.checkerId, selected.checker);
  }
  const claimPolicies = new Map(), publicKeys = new Map();
  for (const claim of policy.claims) {
    if (claimPolicies.has(claim.claimId)) throw new Error('PSC_OFFLINE_DUPLICATE_CLAIM');
    claimPolicies.set(claim.claimId, { subjectId: claim.subjectId, claimClass: claim.claimClass, checkerId: claim.checkerId });
  }
  for (const entry of policy.publicKeys) {
    if (publicKeys.has(entry.signerId)) throw new Error('PSC_OFFLINE_DUPLICATE_SIGNER');
    publicKeys.set(entry.signerId, entry.pem);
  }
  const certificateBoundary = createCertificateBoundary({ checkers });
  try {
    return await verifyOfflineCapsule(bytes, { expectedManifestId: policy.expectedManifestId,
      expectedSemanticLockId: policy.expectedSemanticLockId, context: policy.context, claimPolicies,
      semanticLockPolicy: policy.semanticLockPolicy,
      certificateBoundary, publicKeys, requiredSignerIds: policy.requiredSignerIds,
      requiredArchiveRoles: policy.requiredArchiveRoles, resourceLimits: policy.resourceLimits });
  } finally { certificateBoundary.close(); }
}
