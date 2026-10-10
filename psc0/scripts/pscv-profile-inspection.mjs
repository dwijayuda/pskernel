/**
 * P1 experimental profile-discovery and selection contract.
 *
 * NOT the product profile loader. It cannot grant compilation capability.
 * The production CLI continues to reject profile other than "checked".
 * Treat descriptor/env assertions as UNTRUSTED candidate metadata, never
 * as signed release approval or as proof of executable correctness.
 */
import {
  normativeSha256, pinnedLeanCommit, pinnedLeanVersion,
  pinnedStandardIdentity, provenanceProtocol,
} from '../packages/pscv/src/lean-provenance.mjs';

export const profileInspectionProtocol = 'psc-profile-inspection/0';
const fail = name => { throw new Error('PSC_PSCV_PROFILE_INSPECTION_' + name); };
const obj = x => x !== null && typeof x === 'object' &&
  !Array.isArray(x) && Object.getPrototypeOf(x) === Object.prototype;
const exact = (x, keys) => obj(x) && Object.keys(x).length === keys.length &&
  keys.every(k => Object.hasOwn(x, k));

const requiredProfileKeys = [
  'schemaVersion', 'kind', 'sourceProfile', 'assurancePolicies',
  'normativeReference', 'referenceSha256', 'leanSemanticReference',
  'standardEnvironment', 'verificationSemantics', 'certificateContract',
  'status', 'allowedToEmitVerifiedExecutable', 'installedPackageGrantsAuthority',
  'runtimeCodeEntry', 'implementationReference', 'operation',
  'packageCapabilities', 'verifiedFeatures',
];
export function inspectPSCVProfile({ rootProjectProfile, assurancePolicy,
  descriptor, provenanceBlueprint } = {}) {
  if (rootProjectProfile !== 'pscv-v1' ||
      !['pscv-closed-v1', 'pscv-boundary-v1'].includes(assurancePolicy)) {
    fail('ROOT_PROFILE_REQUIRED');
  }
  if (!exact(descriptor, requiredProfileKeys) ||
      descriptor.schemaVersion !== 0 ||
      descriptor.kind !== 'psc-profile-candidate/0' ||
      descriptor.sourceProfile !== rootProjectProfile ||
      !Array.isArray(descriptor.assurancePolicies) ||
      descriptor.assurancePolicies.length !== 2 ||
      descriptor.assurancePolicies[0] !== 'pscv-closed-v1' ||
      descriptor.assurancePolicies[1] !== 'pscv-boundary-v1' ||
      descriptor.normativeReference !== 'PSCV-RC-v2' ||
      descriptor.referenceSha256 !== normativeSha256 ||
      !exact(descriptor.leanSemanticReference, ['version','commit']) ||
      descriptor.leanSemanticReference.version !== pinnedLeanVersion ||
      descriptor.leanSemanticReference.commit !== pinnedLeanCommit ||
      !exact(descriptor.standardEnvironment, ['identity','registrySha256','status']) ||
      descriptor.standardEnvironment.identity !== pinnedStandardIdentity ||
      descriptor.standardEnvironment.registrySha256 !== null ||
      descriptor.standardEnvironment.status !== 'not-generated-or-frozen' ||
      descriptor.verificationSemantics !== 'PSCV-VERIFY-v1' ||
      descriptor.certificateContract !== 'PSCV-CERT-v1' ||
      descriptor.status !== 'experimental-preflight-only' ||
      descriptor.allowedToEmitVerifiedExecutable !== false ||
      descriptor.installedPackageGrantsAuthority !== false ||
      descriptor.runtimeCodeEntry !== null ||
      descriptor.implementationReference !== 'PSCVL' ||
      descriptor.operation !== 'offline-preflight-proposal' ||
      !Array.isArray(descriptor.packageCapabilities) ||
      descriptor.packageCapabilities.length !== 0 ||
      !Array.isArray(descriptor.verifiedFeatures) ||
      descriptor.verifiedFeatures.length !== 0) {
    fail('UNAPPROVED_DESCRIPTOR');
  }

  // This flag reports supplied metadata only. It does not establish Git
  // provenance or an authenticated Standard environment by itself.
  let untrustedSourceBlueprintProvided = false;
  if (provenanceBlueprint !== undefined) {
    if (!obj(provenanceBlueprint) ||
        provenanceBlueprint.protocol !== provenanceProtocol ||
        provenanceBlueprint.semanticPin?.leanVersion !== pinnedLeanVersion ||
        provenanceBlueprint.semanticPin?.leanCommit !== pinnedLeanCommit ||
        provenanceBlueprint.standardManifestComplete !== false ||
        provenanceBlueprint.registryOrderFrozen !== false ||
        provenanceBlueprint.executableAuthorization !== false ||
        provenanceBlueprint.sourceReferenceSha256 !== normativeSha256) {
      fail('PROVENANCE_IS_NOT_ENVIRONMENT');
    }
    untrustedSourceBlueprintProvided = true;
  }
  return Object.freeze({
    protocol: profileInspectionProtocol,
    requestedProfile: rootProjectProfile,
    assurancePolicy,
    environmentIdentity: pinnedStandardIdentity,
    leanSemanticVersion: pinnedLeanVersion,
    leanSemanticCommit: pinnedLeanCommit,
    untrustedSourceBlueprintProvided,
    selectedCompilerProfile: null,
    state: 'blocked-unqualified',
    profileActivated: false,
    verifiedExecutableAuthorized: false,
    pscvVerified: false,
    reasons: Object.freeze([
      'normative-registry-snapshot-missing',
      'class-parameter-modes-not-frozen',
      'verification-effect-registry-not-frozen',
      'certification-gate-unqualified',
      'production-compiler-pscv-profile-unsupported',
    ]),
  });
}

export function activatePSCVProfile() {
  throw new Error('PSC_PSCV_PROFILE_ACTIVATION_UNQUALIFIED');
}
