import { createHash } from 'node:crypto';
import { selectExtensionSet } from '@proofscript/pscv-extensions';
import { checkWithLeanKernel } from '@proofscript/pscv-kernel';

const PROFILES = Object.freeze(['ps-standard-0.9-r3', 'ps-lean-extensible-0.9-r3', 'pscv-v1']);
const MAX_SOURCE_BYTES = 16 * 1024 * 1024;

export function createCompilerCore({
  profile = 'ps-standard-0.9-r3',
  availableExtensions = [],
  enabledExtensions = [],
} = {}) {
  if (!PROFILES.includes(profile)) throw new Error('PSCV_CORE_PROFILE_UNSUPPORTED');
  const extensions = selectExtensionSet({
    profile, available: availableExtensions, enabled: enabledExtensions,
  });
  const description = Object.freeze({
    contract: 'pscv-v6-minimal-core/0',
    phase: 'kernel-admission-foundation',
    profile,
    extensionSetSha256: extensions.fingerprint,
    implementationComplete: false,
    pscvCertificationImplemented: false,
    sourceFrontendImplemented: false,
    fourBackendEmissionImplemented: false,
    trustedExtensionExecutionImplemented: false,
  });
  return Object.freeze({
    describe() { return description; },
    extensionPlan() { return extensions; },
    inspectSource({ source, path = 'Main.ps' } = {}) {
      if (typeof path !== 'string' || !path.endsWith('.ps') ||
          typeof source !== 'string' || Buffer.byteLength(source, 'utf8') > MAX_SOURCE_BYTES) {
        throw new Error('PSCV_SOURCE_ARTIFACT_INVALID');
      }
      return Object.freeze({
        kind: 'source-identity-only',
        path, profile, extensionSetSha256: extensions.fingerprint,
        sourceSha256: createHash('sha256').update(source, 'utf8').digest('hex'),
        parsed: false, elaborated: false, kernelChecked: false,
        pscvCertified: false,
      });
    },
    async checkCanonicalAdmissions(text, options = {}) {
      // Accepts a Core admission candidate, NOT a compiled .ps SourceArtifact.
      // This result cannot bind source semantics or authorize code emission.
      return checkWithLeanKernel(text, options);
    },
    build() { throw new Error('PSCV_CORE_BUILD_NOT_IMPLEMENTED'); },
    verify() { throw new Error('PSCV_CORE_VERIFICATION_NOT_IMPLEMENTED'); },
  });
}
