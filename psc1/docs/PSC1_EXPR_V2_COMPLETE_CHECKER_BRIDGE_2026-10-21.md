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

[Combined-checker generated-JS CI 39492950104](https://github.com/dwijayuda/pskernel/actions/runs/39492950104) **PASSED all five jobs**, including the complete checker/V2 combined bridge. The real PSC1 compiler checked **1,234 declarations**. Generated JS agreed on Sort checking, WHNF, positive DefEq and restricted V2 reduction for all guarded depths; the original kernel rejected an ill-typed application, while the V2 subset left its neutral head alone.

Node22 timing evidence, two A-B-B-A samples per implementation, is below. V2 includes legacy expression import, replay validation, restricted head reduction, a checked sort construction and fully validated structural equality of the result. Full production WHNF invokes broader kernel semantics and uses its original fuel accounting; this is a *supported-subset* comparison.

| Zeta depth; calls | Complete production WHNF | V2 paged restricted head with checked conversions |
|---|---|---|
| 8; 4 | 207.880 / 180.117 ms | 32.436 / 27.420 ms |
| 24; 3 | 220.682 / 206.107 ms | 59.087 / 74.530 ms |
| 48; 2 | 219.692 / 214.465 ms | 89.142 / 94.249 ms |

The observed V2 advantage on this narrow generated-JS fixture ranges roughly **2x to 8x**; the specific ratios depend on depth and execution order. It is not an overall kernel speedup. The reported heap after forced GC rose modestly across the complete process as measurements accumulated; this single mixed-workload run does not establish a per-variant allocation or memory advantage.

The separate native and JS source code remain directly comparable only within this correctly guarded zeta subset, not on unsupported recursors, delta unfolding, primitive reductions, proofs or negative DefEq.

## Why promotion remains blocked

- The research paged arena is much faster than frozen linked chunks on measured 4k/8k shared-DAG lookup and construction, but not every small checked operation speeds up.
- Legacy-to-V2 import cannot remain an expensive per-expression inner-checker conversion. V2 should eventually be constructed directly and its sharing preserved end-to-end.
- V2 lacks general application-function normalization, environment-sensitive delta, recursor/iota, projections and primitive reductions, full Lean 4.35 universe/DefEq semantics, and exact published fuel accounting.
- Cached metadata must remain exact and fail closed at ingress. Hash collision is never equality; free-variable caches cannot leak across contexts or arenas. Unvalidated on-canonical worker functions must never become unguarded external checker APIs.
- Do not change proof admissions or the 79-module SelfHost kernel until exact semantic parity, qualified generated PS and JS, hostile negative cases, memory and true whole-checker benchmarks are green.

This work is authorized open-source theorem-prover correctness and compiler-performance research, not a completed metatheory/soundness proof.


## Next semantic extension: normalization of application functions

New isolated module: packages/pskernel-core/src/Ps/KernelCore/Research/ExprV2PagedWhnfSubset.lean.

This bounded research operation normalizes an application's function position before attempting beta reduction. It handles a lambda hidden behind a typed let or transparent metadata, in addition to direct beta and zeta. If the reduced function is not a lambda, it preserves the neutral application (rebuilding it only when the function expression changed).

[Native checker comparison CI 39494159712](https://github.com/dwijayuda/pskernel/actions/runs/39494159712) **PASSED its WHNF-subset regression job**: five positive cases agree with the original complete PSC1 checker on type, WHNF and positive DefEq (direct beta, let-function beta, metadata-function beta, metadata-let-function beta, and zeta). Negative tests reject forged cached metadata, invalid node IDs, zero fuel and typing-invalid applications through the original checker. The research subset never claims that a stuck neutral application is well typed.

Portable PSC1 .lean/.ps and generated JS gates for this new module are separate. Do not claim them as qualified until they pass on the current exact source commit.

This operation is still not full Lean 4.35 WHNF: delta, recursor/iota, projections, primitives, proof irrelevance, universe checking, state-sensitive caches and exact production resource policy remain unimplemented in V2.
