import assert from 'node:assert/strict';

export const compilerExecutionPolicyContract = 'psc-compiler-execution-policy/1';
export const hostedCompilerProfile = 'pscv-hosted-lean/1';
export const requiredCompilerValidation = Object.freeze([
  'language-authority', 'native-compilation', 'frontend-semantics', 'runtime-and-target-ir',
  'backend-behavior', 'production-authority', 'artifact-and-archive-replay', 'resource-and-failure-boundaries',
]);

/** Development scope is separate from the source language and its authority.
 * This policy permits host implementation facilities; it grants no program
 * acceptance, source-fidelity, preservation or verified-executable capability.
 */
export function validateCompilerExecutionPolicy(policy, { languageAuthority, config, toolchain }) {
  const equal = (actual, expected, name) => assert.deepEqual(actual, expected, 'PSCV_EXECUTION_POLICY_' + name);
  equal(policy?.schemaVersion, 1, 'SCHEMA');
  equal(policy.contract, compilerExecutionPolicyContract, 'CONTRACT');
  equal(policy.implementationProfile, hostedCompilerProfile, 'IMPLEMENTATION');
  equal(policy.architecture, 'THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md', 'ARCHITECTURE');
  equal(policy.kernelScope, 'consume-contracts-and-evidence-only', 'KERNEL_SCOPE');
  equal(policy.decision?.execution, 'github-cloud-only', 'EXECUTION');
  equal(policy.selfHosting?.goal, false, 'SELFHOST_GOAL');
  equal(policy.selfHosting.requiredForImplementation, false, 'SELFHOST_REQUIRED');
  equal(policy.selfHosting.psc1PatternsRequired, false, 'PSC1_CONSTRAINT');
  equal(policy.selfHosting.historicalEvidence, 'preserve-exact-recorded-identities', 'HISTORY');
  equal(policy.selfHosting.optionalProfiles, ['PSC1-selfhost-stable/1', 'PSC1-portable-selfhost/1'], 'HISTORICAL_PROFILES');
  equal([...policy.requiredValidation].sort(), [...requiredCompilerValidation].sort(), 'VALIDATION');
  equal(policy.conformance, { implementationComplete: false, pscvLanguageConformant: false,
    globalPreservationProved: false, assuredRelease: false }, 'NO_CONFORMANCE_UPGRADE');

  // These identities describe the target semantics, not the host's accepted
  // syntax. A host compiler upgrade cannot silently change the PSCV profile.
  for (const field of ['document', 'sha256', 'verificationProfile', 'verificationSemantics',
    'certificatePolicy', 'normativeLeanVersion', 'normativeLeanCommit'])
    equal(policy.languageAuthority?.[field], languageAuthority[field], 'LANGUAGE_' + field);
  equal(policy.languageAuthority.document, 'PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md', 'LANGUAGE_DOCUMENT');
  equal(policy.languageAuthority.verificationProfile, 'pscv-v1', 'VERIFICATION_PROFILE');
  equal(policy.languageAuthority.verificationSemantics, 'PSCV-VERIFY-v1', 'VERIFICATION_SEMANTICS');
  equal(policy.languageAuthority.certificatePolicy, 'PSCV-CERT-v1', 'CERTIFICATE_POLICY');
  equal(policy.hostToolchain, { language: 'Lean', version: languageAuthority.bootstrapLean.version,
    commit: languageAuthority.bootstrapLean.commit }, 'HOST_PIN');
  equal(toolchain.trim(), 'leanprover/lean4:v' + policy.hostToolchain.version, 'HOST_TOOLCHAIN');
  equal(languageAuthority.implementationProfile, hostedCompilerProfile, 'AUTHORITY_IMPLEMENTATION');
  equal(config.implementationProfile, hostedCompilerProfile, 'CONFIG_IMPLEMENTATION');
  equal(languageAuthority.historicalImplementationProfile, 'PSC1-selfhost-stable/1', 'AUTHORITY_HISTORY');
  equal(config.historicalSelfhostProfile, languageAuthority.historicalImplementationProfile, 'CONFIG_HISTORY');
  equal(languageAuthority.executionPolicy, 'contracts/compiler/COMPILER_EXECUTION_POLICY_V1.json', 'POLICY_PATH');
  return Object.freeze({ implementationProfile: hostedCompilerProfile, selfHostingRequired: false,
    sourceLanguage: languageAuthority.document, verifiedExecutableAuthority: false });
}
