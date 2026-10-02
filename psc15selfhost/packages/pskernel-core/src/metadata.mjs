/** Package identity only. No declaration-admission API is implemented. */
export const kernelInfo = Object.freeze({
  name: "@proofscript/pskernel-core",
  version: "0.1.0-foundation.0",
  implementation: "new-owned-psc-kernel",
  status: "foundation",
  canCheckProofs: false,
  authoritative: false,
  targetLeanVersion: "4.34.0",
  targetLeanCommit: "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b",
  targetProfile: "lean4.34-proof",
  nativeEvaluation: "excluded-from-target-profile",
  compatibilityEvidence: "none-for-new-implementation",
});
