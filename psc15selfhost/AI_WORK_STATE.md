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

## Checkpoint P1/P4/P5/P6

- public Node `psc build` now routes through checked-build; `build-unchecked` is explicit bootstrap/internal
- algorithmic-defeq cache contract registered; non-transitive relation forbids union-find/transitive closure without proof
- VerifiedIR v1 gap registry is machine-readable
- PsSpecializedIrModule added in PSC1-selfhost-compatible Lean source
- validated JS/Wasm specialization paths now construct the explicit SpecializedIR capability
- next: open PR/cloud CI, then pass/build evidence + ModuleInterface semantic fingerprint prototype

## Checkpoint P7/P8/P12/P13

- generic PSC1-compatible PassDefinition/PassExecution model added
- specialization now has explicit current assurance metadata and can emit PassExecution
- typed structural ModuleInterface fingerprint replaces untyped QueryGraph interfaceKey
- current host extraction remains conservative canonical-admissions semantics, now versioned by contract
- Comparator-v1 challenge/replay scaffold added; current status is process-isolated prototype, not yet a production sandbox
- next: cloud validation, then declarative theory seed, defeq/cache source enforcement, SAVEF object format and verifier capsule

## Checkpoint P9/P16/P17/P18

- declarative Core theory seed registered with explicit target-unproved theorem status; no proof claim fabricated
- minimal local SAVEF KnowledgeObject format implemented with deterministic canonical hashing and fail-closed tamper detection
- specialization pass contract exported as the first SAVEF knowledge object
- offline pscv-verify prototype validates architecture/trust/provider-security/SAVEF closure without the full compiler
- FactoryBench-v4 holdout policy scaffold frozen with searchableByFactory=false; task corpus remains intentionally pending/sealed
- next: strengthen defeq cache source audit, add theory definitions/proof skeletons where self-host-compatible, then Wasm validation evidence
