/** Package identity only. No public declaration-admission API is exposed. */
export const kernelInfo = Object.freeze({
  name: "@proofscript/pskernel-core.old2",
  version: "0.1.0-checker.14",
  implementation: "archived-owned-psc-kernel-old2",
  status: "experimental-term-checker",
  canCheckProofs: false,
  authoritative: false,
  targetLeanVersion: "4.34.0",
  targetLeanCommit: "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b",
  targetProfile: "lean4.34-proof",
  nativeEvaluation: "excluded-from-target-profile",
  compatibilityEvidence: "bounded-checker-fragment-not-full-compatibility",
});
