# Expression V2: complete-checker bridge and conversion-inclusive performance

Date: 2026-10-21
Repository: dwijayuda/pskernel (PSC1 research)
Lean: leanprover/lean4:v4.35.0, eb6cafb7290e8bd5f2937522d8d804f58f02bafc
Branch: research/psc1-pskernel-expr-v2-lean435-20261020
Status: **read-only research, not a production kernel replacement**

## Scope and trust boundary

The bridge, test/PsKernelExprV2FullCheckerBridge.lean, calls the actual complete PSC1 PSKernel-Core SessionCheck, SessionWhnf and SessionIsDefEq on closed typed zeta fixtures. It also imports the SAME legacy expressions into the V2 paged DAG, applies the restricted beta/zeta/mdata head-reduction machine, and materializes the result for exact legacy structural comparison.

The checker independently ensures the term is well typed, normalizes it, and accepts its positive DefEq. It also rejects an intentionally ill-typed application of Sort as a function, even though the V2 restricted head worker leaves that neutral shape unchanged.

**V2 currently is NOT a type checker, not complete WHNF, not full DefEq, and does not implement the published kernel fuel policy.** The bridge makes comparisons only on the checked semantic subset. No V2 result admits proofs.

## Qualified native Lean 4.35 bridge

- [39491359738](https://github.com/dwijayuda/pskernel/actions/runs/39491359738): qualified source build, full-checker verdict parity at depths 1, 8, 32 and 96, and negative typing rejection.
- [39491732020](https://github.com/dwijayuda/pskernel/actions/runs/39491732020): initial larger batch completed, but pure-import subtests unexpectedly measured 0 ms. They may have been lifted out of the repeated operation since the operand was captured as a constant. DO NOT use those timings as speedup evidence.
- [39492211603](https://github.com/dwijayuda/pskernel/actions/runs/39492211603): reran with **17 separately allocated, preconstructed zeta fixtures**, differing by binder name. Every timed operation chooses its input by the runtime loop index to resist trivial constant-argument hoisting. Production checker and V2 were checked independently on each fixture before timing.

Measured A-B-B-A native milliseconds, both input/output conversions included on the V2 path:

| Closed zeta depth | Calls per phase | Existing full WHNF | V2 paged import + restricted head + materialize |
|---|---:|---|---|
| 32 | 400 | 19 / 19 | 36 / 36 |
| 96 | 160 | 53 / 52 | 51 / 52 |
| 192 | 70 | 86 / 87 | 55 / 55 |

V2 is **~1.9x slower** at depth 32, near parity at depth 96, and **~1.6x faster** at depth 192 on this native synthetic subset. These numbers are not full-kernel, Lean Arena, Mathlib or self-hosting throughput results. The two systems have different fuel accounting.

Additional guarded phase timings, shown in order of depth 32 / 96 / 192:
- V2 import and replay only: 9 / 11 / 10 ms per batch.
- V2 import plus restricted head step sequence: 24 / 29 / 24 ms.
- V2 head on preimported arena: 15 / 17 / 16 ms.
- Published full checker type checking: 30 / 62 / 95 ms.
- Published full checker positive DefEq: 4 / 9 / 14 ms.

The separate measurements are not necessarily additive because of allocation, runtime scheduling and GC. The benchmark primarily varies binder display names, not mathematical structure. The milliseconds are 1-ms resolution. Do not generalize beyond this fixture.

## Generated JavaScript combined-checker bridge

Combined source: packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2CheckerBridgeRoot.lean

It imports both Ps.KernelCore.SelfHost (complete original production kernel closure) and Ps.KernelCore.Research.ExprV2ResearchAll (isolated V2 research closure), making both callable in the same generated TypeScript 7.0.2 / Node 22 artifact.

Test script: scripts/pskernel-expr-v2-full-checker-bridge.mjs

The generated-js-full-checker-bridge CI job checks the combined source, emits JS, TypeScript declarations and source map, executes complete production check/WHNF/positive DefEq plus a negative typing test, compares V2 outputs with validated structural equality, and records import-inclusive order-balanced JS timings.

**Qualification must be read from the successful exact CI run**, not inferred from a pushed source file or the native bridge result. This job is independent of the already-qualified 28-module V2 canonical ProofScript closure.

## Why promotion remains blocked

- The research paged arena is much faster than frozen linked chunks on measured 4k/8k shared-DAG lookup and construction, but not every small checked operation speeds up.
- Legacy-to-V2 import cannot remain an expensive per-expression inner-checker conversion. V2 should eventually be constructed directly and its sharing preserved end-to-end.
- V2 lacks general application-function normalization, environment-sensitive delta, recursor/iota, projections and primitive reductions, full Lean 4.35 universe/DefEq semantics, and exact published fuel accounting.
- Cached metadata must remain exact and fail closed at ingress. Hash collision is never equality; free-variable caches cannot leak across contexts or arenas. Unvalidated on-canonical worker functions must never become unguarded external checker APIs.
- Do not change proof admissions or the 79-module SelfHost kernel until exact semantic parity, qualified generated PS and JS, hostile negative cases, memory and true whole-checker benchmarks are green.

This work is authorized open-source theorem-prover correctness and compiler-performance research, not a completed metatheory/soundness proof.
