# PSKernel Core Arena compatibility profile

This branch integrates canonical `packages/pskernel-core` with the Lean Kernel
Arena transport boundary. The Arena adapter is host-only: it parses
`lean4export` NDJSON and reconstructs KernelContract-v1 requests. All semantic
accept/reject decisions remain in `pskernel-core`.

## Semantic target

The kernel's semantic identity remains:

- Lean 4.34.0
- git commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`
- KernelContract-v1

The Arena adapter additionally accepts Lean 4.34.1 export metadata at commit
`5045d0056413266e57c625dcd7c365b10e377c52`.

This is an explicit compatibility bridge, not a relabeling of the kernel
contract. A source comparison of Lean v4.34.0..v4.34.1 shows no changes under
`src/kernel/**`; the six release commits change runtime reference-counting,
BitVec/meta tooling, and related tests. Therefore the declaration acceptance
algorithm targeted by PSKernel is unchanged across these two releases. Runtime
hardening in 4.34.1 remains relevant to the host TCB and is not claimed to be
proved by the 4.34.0 semantic metatheory.

Any later Lean release or any 4.34.x release that changes `src/kernel/**`
requires a new semantic delta audit before its export identity can be accepted.

## Transport boundary

The first implementation reuses `PSC1Kernel.ReplayJson` only for the
Lean4Export 3.1.0 record grammar and intern-table transport representation.
It does not call the archived PSC1Kernel declaration checker.

Records are converted to canonical `PsKernelName`, `PsKernelLevel`,
`PsKernelExpr`, and `PsKernelDeclarationRequest` values, then admitted only
through `psKernelV1AdmitDeclaration`.

The old replay parser remains outside the portable semantic kernel and does not
mint checked authority.

## Arena exit contract

- 0: accepted
- 1: rejected invalid input/declaration
- 2: declined unsupported/resource bound
- 3: adapter/internal failure

## Current limitations

- Generated inductive metadata is trusted only as transport redundancy and is
  not yet compared field-by-field against the export record. The actual
  inductive declaration is regenerated and checked by PSKernel Core.
- Arena/Std/Mathlib evidence must be recorded against an exact PSKernel commit,
  Lean/lean4export identity, Arena revision, corpus revision, elapsed time and
  peak memory.
- This branch is an empirical compatibility lane. It does not weaken or replace
  the separate metatheory acceptance criteria.


## Arena readiness foundation gate

The Arena readiness workflow also executes the portable PSKernel Core foundation
differential suite before replaying the pinned `Init.Prelude` stream. This gate is
intended to catch semantic regressions (including DefEq directionality) before
large-corpus replay. Contract-gate failures are reported by subfamily
(diagnostics, admission, expression, resource policy, provider identity) so a
failure is classified before any production semantic change is considered.
- Foundation readiness now reports expression-contract result categories explicitly when that boundary fails.
- KernelContract-v1 outcome adaptation recognizes stable diagnostic families with appended `;` details, preserving invalid-vs-internal classification for enriched checker diagnostics.
- Foundation recursor differential now enforces the production cache invariant: local-fvar expressions must not be published in semantic inference caches.
- Foundation DefEq differentials now require success-cache publication only for cache-eligible expression pairs; fvar-containing successful comparisons are validated semantically without contradicting the scoped-cache policy.
