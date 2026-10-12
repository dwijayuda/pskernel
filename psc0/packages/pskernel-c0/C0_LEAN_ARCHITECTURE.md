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

**Under native qualification:** local contexts retain the ordered declaration
list as the independent lookup reference. After 128 declarations a
`Thunk` may represent an immutable radix snapshot, with a 16-entry pending
overlay for later bindings. Constructing a deeper context records a lazy
computation rather than eagerly materializing or copying the trie. For
lookup contexts with `nextIndex` below 512, direct list lookup does not
force the index at all. Above that heuristic, a lookup checks pending entries
first and, if needed, forces the memoized snapshot with `Thunk.get`.
This moves potentially expensive index allocation from binder introduction
to the deep lookup that could amortize it.

Lean's `Thunk` has a pure logical model as a delayed computation and runtime
call-by-need memoization; repeated forcing of the same snapshot computes it
once. Its caching is **not** a kernel equality or acceptance rule. The
`nextIndex` threshold is a performance heuristic, not an assumption that the
fresh-name counter equals the number of declarations. Every lookup branch
uses the same exact-name/shadowing semantics.

This design avoids eagerly building an index for one-shot 192- and
320-binder declarations while retaining an indexed representation for heavily queried
512-local contexts. The native build, negative/differential tests, matched
benchmark, and memory results for the lazy strategy must pass before it can
be called a performance improvement. Any future non-Lean backend must
implement equivalent lazy snapshot caching or transparently fall back to
the original exact list lookup without changing acceptance.

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



## Indexed loose de Bruijn range metadata — qualified experimental substrate

The immutable source-owned canonical indexed store now retains three independent
node metadata fields: `hash` (candidate index only), `depth` (bounded decoder
and rewrite recursion) and `looseBVarRange` (maximum free de Bruijn index + 1).
Every node is interned after its children; the range is computed from child
metadata in O(1) per constructor. Lambda/Pi/let body ranges shift down one
after binding; domains and let values remain at the parent depth.

Indexed lifting skips subterms when `range <= start`. Indexed one-binder
substitution at binder offset `offset` skips subterms when `range <= offset`.
These shortcuts are exact for capture-avoiding substitution and preserve
canonical IDs of unchanged subterms. The unoptimized indexed reference
remains an executable differential oracle; positive/negative/metadata and
multi-offset tests protect correctness.

[CI 38239387122](https://github.com/dwijayuda/pskernel/actions/runs/38239387122)
passed the native source build, all negative/differential checks, performance
suite and matched original-core checks. On an isolated closed shared DAG,
reference instantiation took 885 ms versus 1 ms for the memoized pruned route
over 100 operations. This does **not** change the accepted checker or prove
complete-kernel speedup. Metadata from an unvalidated external arena, raw
handle equality across stores, and context-free indexed WHNF must **never**
be accepted as checked conversion or declaration admission.

A separate attempt to replace the recursive-source comparator with direct
structural recursion measured slower and was rolled back. In current
production, binder-aware substitution and demand-driven reduction remain
the established accepting-path optimizations; the indexed range is a
prerequisite for future zero-reconstruction evaluation, not permission to
prematurely switch the trusted execution path.


### Incrementally maintained live-local count (October 12 native checkpoint)

The native `PsKernelLocalContext` now tracks `declCount` alongside the authoritative `decls` and independent fresh-name `nextIndex`. AddLocal/AddLet advance the live count once; the lazy radix promotion policy reads it in O(1) instead of traversing a list of up to 128 locals each extension. A recursor continuation must not equate `nextIndex` with binder depth; `psKernelLocalContextWithNextIndex` preserves the entire previous snapshot, its overlay and count while altering only the fresh-name counter. An elevated fresh index over a shallow context must not force index promotion. This field is an internal acceleration invariant, never an acceptance/type judgment.

[CI 38240821497](https://github.com/dwijayuda/pskernel/actions/runs/38240821497) passed native source build, negative/differential regression and full original-core matched checking. Fully checked timings were near parity. The single-family private historical list-scan ablation [38241386784](https://github.com/dwijayuda/pskernel/actions/runs/38241386784) is required before attributing any checker speedup to this field. Additional one-field storage may change memory; process peak is not sufficient attribution.


### Full-checker counter-family qualification

The additional native [three-way ablation CI 38241386784](https://github.com/dwijayuda/pskernel/actions/runs/38241386784) isolated the new exact `declCount` predicate from the prior `decls.length` predicate in a temporary copy. The complete 160-declaration admission sequence was exactly **37/38/38 ms in both versions**; depth-96/192/320/512 and fully checked applications stayed close, with some noise. There is **no significant full-checker speedup or memory reduction** proven for this incremental caching change. Its role is to avoid an O(depth) list scan per pre-promotion extension and to express live declaration count separately from recursor fresh-name counter. It does not change trusted judgments or invalidate any previous negative performance findings.


### Safe accepting Pi-spine metadata and original resource provenance (2026-10-12)

Native C0 now includes a **measured accepting-path** large-application acceleration. `psKernelC0CollectCheckedAppPath` records frames for the precise original nested application traversal, threading the original decreased fuel and entered recursion-depth context into each position; `psKernelC0CheckAppFrames` performs the same fully checked argument inference, Pi exposure, eager reduction, DefEq and state updates as recursive source checking. `psKernelC0SourceLooseRangeWithFuel` / `psKernelC0PiBodyRangesWithFuel` analyze immutable term syntax only, with bounded recursion and a safe fallback. Range zero exactly means no loose de Bruijn variable and therefore no effect of `instantiate1`. After any dependent substitution or context-dependent Pi exposure the cached suffix list is discarded. This metadata is never used to decide well-typedness or DefEq. Only root spines with at least 64 applications take the frame route by default, with original recursive inference retained as both general fallback and independently callable differential oracle.

[Native CI 38246930574](https://github.com/dwijayuda/pskernel/actions/runs/38246930574) passed all required Lean 4.34 native gates; 12 typed 192-argument checked calls completed in C0 9/7/7 ms versus original 33/34/34 ms across 3 rounds; smaller checked paths remained near parity or slightly slower. Retain negative acceptance, fuel, environment/context provenance and admission invariants; the experimental indexed DAG itself remains **non-accepting**, and complete environment-dependent indexed WHNF/DefEq and realistic whole-library qualification are still outstanding.


### Shared checker context, compact frames and accepting declaration evidence

[Commit 0859097f](https://github.com/dwijayuda/pskernel/commit/0859097f6c1f8bdd6b869d477db829575bc2823c), [successful CI 38248015655](https://github.com/dwijayuda/pskernel/actions/runs/38248015655). Instead of retaining `PsKernelCheckerContext` in each `PsKernelC0CheckedAppFrame`, the frame stores exact remaining inference fuel, the checked argument and recorded `recDepth`. The original context remains immutable and shared. Planning still invokes `psKernelCheckerContextEnterRecDepth` per node in source order; each head/argument reconstructs its authorized depth. Critically, `maxRecDepth = 0` remains unlimited and does not advance `recDepth`; no homemade resource rule is substituted. State and error behavior are checked against the independently callable original core, including at the router arity threshold.

A new sequence of 32 *accepted* 192-argument checked definitions demonstrates end-to-end admission improvement, C0 **32/32/32 ms** versus unchanged original **130/131/132 ms** (three CI rounds). This is a large non-dependent application family, not broad representative library coverage; compact frame storage itself has no isolated quantified effect. Whole-process memory did not demonstrate an improvement. General nested checked application routing and full environment-sensitive indexed evaluation remain explicit P0 gaps.


### Production fuel-indexed checked Pi engine — qualified checkpoint

On [5c8a1e83](https://github.com/dwijayuda/pskernel/commit/5c8a1e83e22debd4fd6c365ba9666e834e8c5d66), the accepting `psKernelCheckWithFuel` selects `psKernelC0CheckAppRecursive` for root app spines of 16+ args; fewer use `psKernelInferCoreWithFuel`. The fuel-indexed worker is structurally recursive on `Nat`, reconstructs no frame list, shares context through the original source-level recursion, and carries only checked type, state and exact Pi-body suffix ranges. Every application invokes the original `psKernelCheckerContextEnterRecDepth`, original fully checked head/argument inference, Pi WHNF, eager policy, DefEq and substitution semantics. After any affected dependent codomain, precomputed metadata is invalidated. A bounded failed analysis never becomes acceptance. Unlike a cached trusted indexed evaluator, this never uses cross-arena term IDs for equality.

[CI 38252783408](https://github.com/dwijayuda/pskernel/actions/runs/38252783408) passed full native build, negative/differential suite and matched original-core full checker; accepted 16/24/32/48/192 application + admitted-library fixtures favor C0 on specific source workload families, with other paths around parity. The old frame runner stays independently executable for differential/benchmark use, not production. Memory, p95 and representative libraries remain open. Next architecture design must integrate this benefit into recursively *nested* checked source inference through the same fuel-indexed core (lambda/let/forall/projection/metadata), not bolt on new public-only shortcuts; environment/context/resource-provenance caches and full indexed delta/iota/recursor/quotient/native WHNF/DefEq need exact qualification before trusted adoption.


### Recursively nested accepting application semantics — 12 October 2026

The checked core now has a single `psKernelInferCoreWithFuelUsing` that accepts an optional, *checked-only* application callback and recurses with the same immutable hook. Its public default `psKernelInferCoreWithFuel` calls the same source body with `none` and stays the independent original/reference implementation. In the hooked mode, a checked app of 16+ arguments delegates to `psKernelC0CheckAppRecursive` with the original fuel, checker environment, local/level context, safety and state. The authoritative head-before-argument inference, `psKernelCheckerContextEnterRecDepth`, WHNF, DefEq, eager reduction and resource classifications remain. For ordinary checked applications and infer-only expressions, the original suspended fallback executes unchanged. No raw indexed IDs are compared or cached as trusted equality.

The optimized fuel-indexed checked recursive worker additionally recognizes a nested application used as an argument when it has 16+ arguments, calling its own smaller-fuel worker with the original next context. This closes the most direct missing nested-argument workload without creating a second inference language implementation. [CI 38264313583](https://github.com/dwijayuda/pskernel/actions/runs/38264313583) and [CI 38265144787](https://github.com/dwijayuda/pskernel/actions/runs/38265144787) passed pinned Lean native build, negative/fuel/differential tests and matched original checker. Real safe checked declaration admissions now cover lambda/metadata-wrapped and nested-argument spines. Source-side bounded Pi ranges are still **syntactic no-op substitution metadata**, not an environment-dependent inference or proof cache.

Outstanding: confirm semantic coverage across more complex implicit/dependent/recursor/quotient/native reductions; implement accepting session-owned canonical DAG only with complete environment/context provenance and exact original fuel semantics; benchmark representative entire libraries and per-operation memory. No full indexed accepting redesign completed.
