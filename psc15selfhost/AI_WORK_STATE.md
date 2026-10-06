# AI Work State

Master plan: THE_PSCV_COMPILER_REFERENCE_VERSION_3.md
Branch: psc2/selfhost-lean-kernel

## Active execution

Checkpoint P0/P2/P3:
- architecture/contract registry: implemented in this checkpoint
- ProviderSecurityProfile: implemented in this checkpoint
- compiler-wide TrustManifest: implemented in this checkpoint
- checked host capability identity: strengthened in this checkpoint
- PSC1 self-host rule: all future portable Lean/ProofScript compiler code must pass PSC1-selfhost-stable/1 and PSC1-portable-selfhost/1 where applicable

## Next

1. close production AdmissionReady -> erasure bypass without breaking the bootstrap-only self-host path
2. make algorithmic-defeq/cache contracts machine-readable
3. finish VerifiedIR invariant gap registry
4. introduce explicit SpecializedIR capability using PSC1-compatible source patterns
