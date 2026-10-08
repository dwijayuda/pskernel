/** Identity and target metadata; no public proof-checking API exists in this experimental checkpoint. */
export declare const kernelInfo: Readonly<{
  name: "@proofscript/pskernel-core";
  version: "0.1.0-checker.14";
  implementation: "new-owned-psc-kernel";
  status: "experimental-term-checker";
  canCheckProofs: false;
  authoritative: false;
  targetLeanVersion: "4.34.0";
  targetLeanCommit: "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b";
  targetProfile: "lean4.34-proof";
  nativeEvaluation: "excluded-from-target-profile";
  compatibilityEvidence: "bounded-checker-fragment-not-full-compatibility";
}>;
