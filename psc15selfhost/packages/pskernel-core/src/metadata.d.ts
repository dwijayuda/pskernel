/** Identity and target metadata; no proof-checking API exists in this foundation release. */
export declare const kernelInfo: Readonly<{
  name: "@proofscript/pskernel-core";
  version: "0.1.0-foundation.0";
  implementation: "new-owned-psc-kernel";
  status: "foundation";
  canCheckProofs: false;
  authoritative: false;
  targetLeanVersion: "4.34.0";
  targetLeanCommit: "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b";
  targetProfile: "lean4.34-proof";
  nativeEvaluation: "excluded-from-target-profile";
  compatibilityEvidence: "none-for-new-implementation";
}>;
