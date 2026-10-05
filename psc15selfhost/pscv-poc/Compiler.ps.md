# PSCV self-host proof-of-concept specification

Status: **experimental proof-of-concept**  
Profile: `pscv-selfhost-poc-v1`

This document is intentionally small. It tests whether the current PSC2 self-host
compiler can gain a PSCV-style specification/proof layer without rewriting the
runtime compiler or importing proof modules into the executable closure.

## PSCV-POC-COMP-001 — current check/preparation boundary

The current compiler API's `psCompilerCheckElaborated` operation is definitionally
the same operation as `psCompilerPrepareElaborated`.

This is **not** a claim that preparation is kernel checking. The opposite is the
architectural lesson of the proof: the current API still needs a future
`AdmissionReady -> Checked -> VerifiedExecutable` transition for PSCV.

Formal claim:

```proofscript spec
forall elaborated : PsElabModuleResult,
  psCompilerCheckElaborated(elaborated)
    =
  psCompilerPrepareElaborated(elaborated)
```

Evidence declaration:

- proof module: `packages/compiler/proofs/Ps/Compiler/PscvPoc.lean`
- theorem: `pscvPocCheckElaboratedIsPrepare`
- proof style: direct equality proof term (`Eq.refl`)
- runtime dependency: **none**; the proof module is outside the bootstrap runtime root
- intended checked path: canonical Lean -> ProofScript translation, then
  `KernelContract-v1` checked admission of the generated homogeneous `.ps` workspace

## What this PoC does not prove

It does not prove parser correctness, elaborator correctness, compiler semantic
preservation, erasure correctness, backend correctness, or PSCV completeness.

It also does not yet satisfy the PSCV RC-v2 Lean 4.35.0-rc3 semantic pin: the current
repository checked provider is still the existing Lean 4.34 WASM lane. Repinning the
checker is a separate migration step.

## Success criterion

The PoC succeeds only if all of the following hold:

1. the proof module stays outside the runtime self-host import closure;
2. the existing compiler translates the proof and dependencies into a homogeneous
   generated ProofScript workspace;
3. the generated theorem elaborates using the small ProofScript proof surface;
4. the canonical admissions containing that theorem are accepted by the selected
   checked kernel provider;
5. check mode emits no executable proof artifact.
