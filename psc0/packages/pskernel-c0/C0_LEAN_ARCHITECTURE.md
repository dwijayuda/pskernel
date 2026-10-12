# PSKernel-C0 — Lean-native performance architecture

**Scope:** `psc0/packages/pskernel-c0/src/Ps/KernelCore/**/*.lean` on
`perf/pskernel-c0-v7-rust-20261012`.
**Semantic target:** Lean 4.34.0. **Authoritative verdicts:** the existing
PSKernel checker, not the experimental Rust engine or an incomplete indexed
evaluator. The original `pskernel-core`, the PSC0 compiler, and the Rust backend
are not modified in this workstream.

## Architecture and invariants

The accepting checker still uses recursive `PsKernelExpr` throughout its
resource-bounded WHNF, DefEq, inference, projection/recursor reduction and
declaration-admission operations. Its environment lookup, local-context
shadowing, universe levels, proof irrelevance, native primitives and rejection
behavior remain authoritative. An optimization must never interpret a cache
miss, unsupported reduction or depleted fuel as a successful check.

The current native architecture has three distinct layers:

1. **Checked operations:** `Checker/Knot.lean` owns recursive orchestration;
   `Checker/Inference/Core.lean` and `Checker/Reduction/{Whnf,WhnfCore}.lean`
   preserve the checked semantics. C0's demand-driven stuck-application head,
   pre-guarded DefEq quick checks, family-aware single-variable substitution,
   and once-per-spine infer-only arity calculation reduce specific repeated work.
2. **Persistent acceleration:** `Runtime/Acceleration/Cache.lean` uses
   collision-checked radix-16 expression/pair indexes. The global declaration
   index and the local declaration index are separate, and are not a
   substitute for exact name or expression comparisons.
3. **Opt-in canonical DAG:** `Core/{IndexedExpr,IndexedReduction}.lean` and
   `Checker/Reduction/IndexedWhnf.lean` implement exact term sharing, capture-
   avoiding indexed substitution and a context-free WHNF fragment.
   `Checker/IndexedSession.lean` can retain syntax across session operations
   without exposing raw arena IDs. It still delegates **all acceptance
   decisions** to the recursive checker, and is slower on the measured small
   warm-WHNF workload. Do not enable it in production on present evidence.

### Local-context cost model

`Core/LocalContext.lean` keeps the ordered declaration list authoritative.
Short-lived binder contexts use direct list lookup and do not maintain a trie.
Deep contexts may build an immutable radix snapshot and collect later bindings
in a small, newest-first pending overlay. Lookup checks pending entries before
the snapshot, preserving correct shadowing. Publication adds older pending
entries first, so the newest exact-name match wins. Old context snapshots
remain immutable; `nextIndex` continues to determine fresh-name identity.

The former eager promotion after eight local declarations was measured to
regress complete checked admission. Isolated diagnostic builds showed that
suppressing the optional local index recovered the time without changing
accept/reject outcomes. Deferred promotion and batch publication recovered
near parity on a 160-declaration library chain while maintaining a substantial
512-local lookup advantage. See
[CI 38233818758](https://github.com/dwijayuda/pskernel/actions/runs/38233818758)
and `C0_BENCHMARKS.md`.

**Current candidate:** defer promotion through 128 declarations, with a
16-entry pending overlay once indexed. A checked 96-binder benchmark with
actual local references exposed roughly 10% overhead when promotion began at
depth 65; a matched 192-binder comparison has been added to confirm that
deep lookup still justifies index construction. Until the latest CI finishes,
this 128-entry policy is **under qualification**, not a proved global optimum.
Threshold is a performance policy, never a semantic condition.

### Substitution cost model

A controlled full-checker ablation showed that the original general-purpose
`instantiate1` removed an observed checked-application slowdown, despite
synthetic C0 substitution microbenchmarks favoring one-pass traversal.
The accepted hybrid now probes loose variables for binder-headed
lambda/forall/let expressions and returns closed terms unchanged. Other
expression families retain the specialized capture-avoiding one-pass worker.
On the admitted 48-argument application benchmark, this restored fully
checked time to parity while keeping the infer-only gain.
See [CI 38222841665](https://github.com/dwijayuda/pskernel/actions/runs/38222841665).

## Measurement and release gates

The repository-owned native CI does **not** run self-host, bootstrap/fixed-point,
generated Rust or metatheory tests. It performs:

- Full native Lake build, resource/soundness-sensitive negative and differential
  conformance tests, and native Lean microbenchmarks.
- Matched complete-checker tests against the **unchanged original
  `pskernel-core/src`**, built in a temporary package on the same runner with
  Lean 4.34.0. Checked workloads include WHNF, positive/negative DefEq,
  infer-only and fully checked applications, nested definitions and growing
  declaration environments. These are still generated fixtures, not qualified
  full Lean libraries.
- Optional private source-family ablations which change **only** the copied
  diagnostic package, never the original core. A diagnostic is not adopted
  merely because an isolated helper microbenchmark is favorable.

Record source commit, exact CI run, workload, elapsed time, failed as well as
passed cases, and process-wide peak RSS separately from isolated allocations.
Interpret sub-millisecond/integer-millisecond samples cautiously and preserve
regressions in `C0_BENCHMARKS.md`.

## Remaining architectural milestones

1. Quantify representative complete-module/library checking, cold and warm
   effects, allocation/peak memory, stack/fuel behavior and p50/p95 throughput
   across unchanged original and C0 builds.
2. Make canonical term ownership and environment/context provenance explicit
   within the **real** checker so that indexed WHNF, DefEq and inference can
   avoid round-trip reconstruction. No handle from another arena can be a
   trusted equality assertion; no cache result may cross environment/local
   scopes or forget resource costs.
3. Complete context- and environment-dependent indexed reduction families
   (delta, projections, recursors/iota, primitives, quotient, universes) with
   identical reduction priority, checked inference and exhaustion behavior.
4. Optimize full declaration admission and restored recursor/nested-inductive
   validation without shortcutting obligations.
5. Promote a new accepting execution path only after extensive positive,
   negative, resource-budget and original-kernel differential qualification,
   with **measurable** end-to-end performance and memory benefits.

**Status:** performance architecture in progress; no complete indexed
accepting kernel or whole-library superiority has been established.
