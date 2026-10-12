# PSKernel-C0: Lean 4.35 architecture redesign and qualification program

## Phase B external source-byte conformance — incremental checkpoint

**Qualified:** version-pinned official Lean 4.35 `leanchecker --from-export` and strict C0 source-byte NDJSON parser agreed on the twelve-fixture accepted/rejected corpus (sort, lambda/forall, let, universe, app and two-definition dependency) under **[CI 38316177332](https://github.com/dwijayuda/pskernel/actions/runs/38316177332)**. Source [`51f32f59`](https://github.com/dwijayuda/pskernel/commit/51f32f5982f29919ac290c726cac36a5da750836) added 128 checked sequential definitions and a late rejection counterpart. The official/C0 exact input replay stages both passed in [CI 38316694316](https://github.com/dwijayuda/pskernel/actions/runs/38316694316); the full performance/original stage was still running at document time.

**Scope warning:** generated repeated-definition streams demonstrate late rejection under growing dependency environments, **not** coverage of real Init, Std or Mathlib, and the direct adapter is a test-only strict subset. Extend to actual exported declaration forms with explicit decline before designing a trusted importer. Still no full indexed accepting kernel, model-consistency theorem, full-corpus compatibility or con-ron competitive memory/throughput evidence.

## Phase A and early Phase B — verified progress, 2026-10-13

The stable v4.35.0 pin and deletion of Lean 4.34 compiler-evaluated reduceBool/reduceNat callbacks have been qualified by [CI 38313664552](https://github.com/dwijayuda/pskernel/actions/runs/38313664552). The imported project-local original baseline now regenerates its own Lake roots from its unchanged source tree, rather than reusing C0's roots; this is essential when old capability modules are deleted from redesigned C0.

Full canonical store/radix replay including malformed/duplicate/ghost reference rejection passed [CI 38314757371](https://github.com/dwijayuda/pskernel/actions/runs/38314757371). A **non-accepting** prototype of persistent/scratch indexed term stores with selective memoized promotion, immutable abort and cross-prefix integrity passed [CI 38315348542](https://github.com/dwijayuda/pskernel/actions/runs/38315348542). The [CI 38315455947](https://github.com/dwijayuda/pskernel/actions/runs/38315455947) comparison measured 24 source reencodes **525 ms** versus selective indexed promotion **79 ms**, 76 staged/12 committed nodes. This is *syntax-only*; no full-checker or memory win follows. Checked 24 × 12 synthetic C0 batches p50/p95 **26/26 ms**, unchanged original **49/50 ms**, and C0 uses more small allocations.

Official Lean 4.35 `leanchecker --from-export` accepts/rejects pinned NDJSON fixtures with the *exact same bytes* parsed by C0's new strict test-only subset importer. A further [`4f74295e`](https://github.com/dwijayuda/pskernel/commit/4f74295e518d16bc797f56585233e84a47a54b0f) expands the set to 12, including dependent sequential definitions; its [CI 38316177332](https://github.com/dwijayuda/pskernel/actions/runs/38316177332) was in progress at writing and must be rechecked. Unsupported metadata/inductives explicitly fail parsing, not a checker verdict.

**Current quality gap remains:** no full indexed *accepting* source-equivalent v4.35 WHNF/DefEq/inference/admission, no sealed native StoreWF/denotation theorem, no official full Init/Std/Mathlib corpus, and no con-leche/con-ron consistency assurance for C0. Phase B/C must prioritize official semantically identical exported inputs, exact decline/accept distinctions and selected full-workload architectural ablations.

**Date:** 2026-10-13  
**Target compiler and trusted semantic oracle:** `leanprover/lean4:v4.35.0` (stable, released 2026-10-12); [tag commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`](https://github.com/leanprover/lean4/commit/eb6cafb7290e8bd5f2937522d8d804f58f02bafc).  
**Repository:** [dwijayuda/pskernel](https://github.com/dwijayuda/pskernel); branch `perf/pskernel-c0-v7-rust-20261012`; package `psc0/packages/pskernel-c0/`.  
**Starting source:** `cd270db1458c2dd93d5f08907a5969ae69d5e1cc`; [last complete native v4.34 CI 38305932773](https://github.com/dwijayuda/pskernel/actions/runs/38305932773).  
**Immediate toolchain pin commit:** [`46e1bcf2`](https://github.com/dwijayuda/pskernel/commit/46e1bcf2290e419fdb7b5713b53dae1fd951a50a).  
**Scope:** native Lean source, dedicated C0 testing/benchmarks/CI and documents. Not original `pskernel-core`, PSC0 compiler, generated Rust, selfhost/bootstrap, or metatheory test runs.

## 1. Executive judgment: no unjustified quality or performance claims

The desired end state is a fully checked, sound, high-throughput native Lean checker at least competitive with the **official Lean 4**, **con-leche**, and **con-ron**, not an optimised syntax-only reducer. Achieving the quality of the latter verified checkers additionally requires formal soundness/refinement evidence or an equivalent independent verified acceptance gate. **It cannot be achieved by refactoring code or matching their benchmark times alone.** The present C0 has no qualified Mathlib corpus and no C0 consistency theorem; neither is implied by its successful local native CI.

C0's current production verdicts still come from recursive `PsKernelExpr` typing/WHNF/DefEq/declaration admission. Its indexed DAG, memoized substitution/lifting/universe rewriting/decoding, direct constructor projection, direct Quot.mk iota, delta/local let and session work are opt-in candidates. They **must not determine acceptance** until the complete official reduction/typing context and resources are implemented and independently qualified.

The redesign is **not** “rewrite C0 in Rust” or “copy all of con-ron.” Keep native Lean for this phase, and use disciplined, measured architectural experiments with the freedom to delete losing designs.

## 2. Research: pinned primary source material

| Kernel | Inspected artifact | Distinguishing architecture | Assurance scope |
| --- | --- | --- | --- |
| Lean 4 official 4.35.0 | [type_checker.cpp](https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/type_checker.cpp), [expr.cpp](https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/expr.cpp), [environment.cpp](https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/environment.cpp), [inductive.cpp](https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/inductive.cpp) | Runtime shared immutable expressions; cached packed node metadata, pointer-sensitive fast equality, separate infer/check/WHNF/DefEq caches, checked atomic admission | Official compatibility reference; not automatically proved consistent by these implementation techniques |
| con-leche | [Kernel/Expr.lean](https://github.com/leanprover/con-leche/blob/master/ConLeche/Kernel/Expr.lean), [Kernel/Core.lean](https://github.com/leanprover/con-leche/blob/master/ConLeche/Kernel/Core.lean), [Cached/StateC.lean](https://github.com/leanprover/con-leche/blob/master/ConLeche/Cached/StateC.lean), [MainTheorem.lean](https://github.com/leanprover/con-leche/blob/master/ConLeche/MainTheorem.lean) | Independent locally nameless term, per-node packed computed fields, pure/cached implementation refinement, **no mandatory global hash-consing** | Set-theoretic model/consistency for specified **verified** mode and limited axiom policy |
| con-ron | [README](https://github.com/leanprover/con-ron/blob/master/README.md), [OVERVIEW §4–9](https://github.com/leanprover/con-ron/blob/master/OVERVIEW.md), [arena/store.rs](https://github.com/leanprover/con-ron/blob/master/crates/con-ron-core/src/arena/store.rs), [arena/handle.rs](https://github.com/leanprover/con-ron/blob/master/crates/con-ron-core/src/arena/handle.rs), [proof/ConRon/Arena](https://github.com/leanprover/con-ron/tree/master/proof/ConRon/Arena), [proof/ConRon/Refine2](https://github.com/leanprover/con-ron/tree/master/proof/ConRon/Refine2) | Rust checker over canonical **tagged u32 handles**, per-constructor structure-of-arrays, persistent + scratch tiers, operation-local memos, per-declaration caches | Lean twin refines con-leche pure; Aeneas-modeled Rust refines twin, yielding qualified inherited verified-mode consistency under explicit trusted assumptions |
| Lean4Lean | [source](https://github.com/digama0/lean4lean/blob/master/Lean4Lean/TypeChecker.lean), [divergences](https://github.com/digama0/lean4lean/blob/master/divergences.md) | Close Lean implementation of official algorithm plus verification work | Some semantic divergences; **not exact v4.35 oracle by default** |
| Sokonanoda / MathGraph | [Sokonanoda](https://github.com/intgrah/sokonanoda/tree/master/src/checker), [MathGraph](https://github.com/metalogiclabs/mathgraph-lean-kernel/tree/flash/src) | Closure/neutral-value conversion and demand-driven evaluation; profiling-led implementation | Independent checker/differential evidence; not a directly transferable con-leche proof |
| Current C0 | [C0 source](https://github.com/dwijayuda/pskernel/tree/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/src/Ps/KernelCore) | Recursive accepting checker + optional globally interned indexed syntax and radix caches | Local conformance and sibling-original tests; no independent 4.35 whole-corpus or consistency proof |

**Important con-ron insight:** unlike con-leche, canonicalization is a *correctness assumption* for con-ron's bare-handle equality. It proves well-formed cons tables are an inverse of node arrays and readback/denotation is injective. Persistent nodes may only refer to persistent children. Pinned con-ron handles encode constructor tag in 4 bits, scratch/persistent tier in 1 bit, and index in 27 bits. Per-constructor node arrays store only their fields; an application is two u32 words, not a sum-type tag plus maximal-variant allocation. That compact layout and scratch reclamation are likely larger wins than C0's globally allocated `Array PsKernelC0StoredNode` alone.

**Critical difference:** C0's `Nat` handles live inside an externally constructible `PsKernelC0TermStore`. Syntactically equal nodes may receive the same ID *within the same healthy canonical store*, but numerical IDs are neither proof judgments nor safe across stores. Unlike con-ron, there is no sealed `StoreWF` and denotation-injectivity proof. Before any indexed acceptance, require a fresh arena ownership identity/scope discipline, validated acyclic intern state, collision-checked exact equality, and persistent-vs-scratch write constraints; otherwise fall back to source checking.

**Alternative from con-leche:** it uses a single independent Lean expression type, `@[computed_field]` packing per-node hash, loose-BVar bounds, FVar range and has-level-param flag in a machine word. Cache keys compare pointer first, then hash, then exact structure. The code intentionally avoids a central hash-cons index. C0 should evaluate this approach in native Lean before assuming the con-ron Rust data layout will be equally performant with Lean persistent arrays.

**Alternative from Sokonanoda/MathGraph:** `Value` closures keep expression + environment, neutrals hold rigid heads and elimination spines, and normalization delays substitution. This may reduce repeated source reconstruction versus both C0 recursive source and its indexed DAG. But its additional cache/context complexity must be qualified with official typing/resource semantics.

## 3. Semantic migration: Lean 4.34.0 → **4.35.0**

**Decision:** pin `lean-toolchain` to `leanprover/lean4:v4.35.0` and target the stable tag commit. Do **not** pin the superseded v4.35.0-rc4 candidate now that stable is published. The target identity (`PsKernelTargetIdentityV1.leanVersion` and `leanCommit`) must change atomically with the source semantics. `KernelContract-v1` may remain the schema name while `leanVersion` and commit identify the changed semantics; an old provider identity must fail compatibility checking.

### 3.1 Removal of trusted native evaluation shortcuts (P0 correctness)

[Official 4.35 release notes](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/), change #14953: remove `Lean.reduceBool`, `Lean.reduceNat`, `Lean.ofReduceBool`, `Lean.ofReduceNat` and `Lean.trustCompiler` along with the kernel's execution of the first two via the compiler. This is **the decisive concrete v4.34 → v4.35 compatibility change** in C0's own source. Official [type_checker.cpp v4.35.0](https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/type_checker.cpp) no longer has `reduce_native` or the `lean_reduce_bool/nat` markers.

C0 v4.34's `Runtime/Capability/Lean434NativeReduction.lean`, `PsKernelNativeEvaluator`, environment and context `nativeEvaluator`, `psKernelReduceNativeWith` in public WHNF and lazy DefEq, and provider API allowing custom runtime callbacks are **not valid trusted 4.35 reductions**. **Replace/remove the entire obsolete capability subsystem**, not an inert compatibility callback. The official WHNF priority becomes `core → Nat primitives → delta`; DefEq lazy delta does Nat/eager handling and comparison without native branches. Do not remove ordinary checked Nat operations, which remain kernel reductions with exact size limits and zero/division semantics.

A syntactically constructed expression headed by old `Lean.reduceBool`/`Lean.reduceNat` must not become `Bool.true` or a Nat literal through a custom evaluator. If its constant is undeclared, checking must reject it under the existing error contract. If a user independently declares that constant in an allowed environment, it is an *ordinary* checked constant, with no compiler-trust shortcut. Preserve precise resource/error/fresh-state effects.

### 3.2 More Lean 4.35 kernel-facing changes to characterize

Release notes describe improvements to cross-module kernel reduction for `Array.map`, `Array.ofFn`, `Array.zipWith`, `Vector` operations and array equality. These mainly exercise environment unfolding and reducibility semantics, not extra magic native kernel calls. C0 must qualify these through **whole checked declarations imported from v4.35** rather than special-case compiler behavior.

Change #15050 adds `leanchecker --from-export file.ndjson`. This is particularly valuable for C0: it enables an official kernel reference on exactly the **same version-pinned exported declaration stream**. An external adapter must map C0's current AST and unsupported constructs explicitly; do not infer success from the official acceptance of a different source AST.

The 4.34.1 runtime fixes for reference-counting edge cases are included in the stable 4.35 release line and matter to runtime trust. A con-ron Rust checker offers diversity of compiler/runtime trust, but copying its Rust implementation into native Lean would not produce that benefit.

### 3.3 Known exact-transport gaps not resolved by changing the compiler

C0 `PsKernelBinderInfo` contains default/implicit/strictImplicit/instImplicit but not official `Rec`; C0 `mdata` is `Nat` instead of official arbitrary structured metadata. A general lossless v4.35 `Lean.Expr` bridge does not exist. Define a supported profile and exact, fail-closed import rules before claiming full compatibility. Do not weaken type- or proof-related metadata checks merely to make imports succeed.

## 4. Clean target architecture: separable concerns, no duplicated trusted checker

```text
            v4.35 NDJSON / checked declarations / source AST
                              |
                  Versioned semantic importer
              exact supported syntax / DECLINE otherwise
                              |
                Immutable validated declaration graph
                    explicit trust + axiom policy
                              |
        +---------------------+---------------------+
        |                                           |
        |                Term storage                |
        |    immutable shared native Lean terms      |
        |    optional compact indexed arena          |
        |      (persistent + per-decl scratch)       |
        |                                           |
        +---------------------+---------------------+
                              |
        One semantic checking machine / rule dispatcher
     fuel + local context + universes + reduction order + error
             /               |                 \
      WHNF/evaluation     DefEq/conversion     checked inference
            \                |                 /
             --------- checked declaration ----------
                     atomic environment commit
                              |
           accept / reject / decline / resource / error
                              |
     official v4.35 + independent checker differential
                              |
     optional verified refinement of accelerated representation
```

### Architectural decision A: immutable syntax and candidate stores

The long-term syntax contract must distinguish **exact display syntax** (binder names/info, metadata), **algorithmic equality** (alpha semantics), **typed context**, and **interned storage identity**. These equivalences are not interchangeable.

Prototype three native-Lean candidates against one checker workload:

1. **Lean-native structurally shared expression nodes**, cached per-node hash/loose-range/hasFvar/hasLevelParam via computed fields, preserving copy-on-write semantics and no global cons table.
2. **Compact optional indexed terms**. Design tagged handles and per-constructor arrays akin to con-ron, but avoid unproven assumption that Lean `Array` plus persistent snapshots beats Lean's GC/runtime. Maintain two tiers; own the persistent environment subset and free scratch per declaration. Only promote validated declaration-term roots; never persistent→scratch edges. Hash-cons exact nodes or *do not* infer syntax equality from numeric handles.
3. **Closure/neutral-value evaluation** on an immutable syntax substrate: closures capture scoped binder environment, application spines remain explicit; reify only at the public boundary. Evaluate beta/zeta/projection/quot/recursor and universe-aware delta without repeated full source instantiation.

Use the same native front-end, accepted judgments and exact differential corpus for all three; delete losing/duplicate implementation families instead of sustaining compatibility layers.

### Architectural decision B: semantics-first accepting evaluator

One kernel semantics specification is authoritative. Operations should share a clear reducer and typed-state interface rather than independently duplicating rule families. Keep existing accepted recursive source path until the new worker is complete; then replace, not permanently wrap it.

Preserve exactly:
- source v4.35 WHNF stages and cheap-projection/cheap-recursor phases, quotient/inductive iota/K/eta and standard Nat primitives;
- two graded inference modes (`inferOnly` versus fully checked); fully checked argument type comparison and safety restrictions;
- definitional equality's quick, proof-irrelevance, lazy delta, projection, eta, string literal, unit-like and universe rules; its **sound but incomplete, potentially non-transitive operational decision procedure** means **do not copy Lean4Lean union-find as an unconditional trusted equivalence closure**;
- recursion/fuel/heartbeats, size caps, local name freshness, cache failure/success context and exact error category/precedence;
- atomic theorem, definition, partial/unsafe, mutual/nested inductive, recursor and quotient admission.

### Architectural decision C: cache ownership and provenance

Declare the cache matrix explicitly:

| Cached operation | Key | Lifetime | Invalidation |
| --- | --- | --- | --- |
| Syntax hash / exact child metadata | validated immutable node | node lifetime | never, if immutable |
| Substitution / lift / level instantiation | (term, cutoff, fixed substitution environment) | **one walk** | at walk exit or changed parameters |
| `whnfCore`, `whnf`, `inferOnly`, `check`, `DefEq`, `unfold` | exact term(s) in owning env/local/universe/safety/evaluator/fuel policy | declaration/checker session | environment/local-context/scoping change or unsupported resource optimization |
| Recursor rule RHS / constant type instantiation | (declaration, universe arguments) | immutable environment revision | declaration environment change |
| Indexed scratch handles | tier, store-ownership ID, constructor tag and index | one checked declaration | scratch dropped and every dependent cache flushed |

**Fail closed on all malformed handles, incorrect derived metadata and stale-context cached judgments.** Resource and error behavior may prohibit caching decisions across different budgets even when their denotations agree. Use exact equality after hash-bucket hit; hashes are neither proofs nor trusted typing evidence.

### Architectural decision D: verification quality comparable to con-leche/con-ron

The high-assurance goal is not “C0 adopts con-leche's theory by copying source.” A plausible native Lean proof plan is:
- define a small **pure kernel rule interface** over closed expressions and explicit environments, separate from optimized execution;
- specify denotation of indexed terms and `StoreWF` (acyclic, distinct canonical handles, correct derived columns, persistent/scratch edges, valid names/levels, well-scoped imports);
- prove source/optimized operation **partial correctness** including typed acceptance and error-fail-closed properties under `StoreWF`;
- prove or reuse a **semantic consistency/model argument** at the correct axiom policy, or integrate con-leche verified checker as a separate certificate gate;
- treat Lean's compiler/runtime and connected external checker as distinct trust boundaries, not hidden assumptions.

Formal proofs are **deferred in this performance workstream** under prior user scope; this architecture should be proof-friendly without claiming con-leche's results. Con-ron's Aeneas bridge validates its particular Rust implementation, not native C0.

## 5. Performance: thresholds and controlled experiments

Verified native C0 v4.34 evidence from [CI 38305932773](https://github.com/dwijayuda/pskernel/actions/runs/38305932773):

- 24 independent *within-run* samples of 12 accepted mixed declarations: C0 p50/p95 **25/25 ms**, unchanged project-local `pskernel-core` **47/47 ms**, both 288/288 accepted.
- Thread-local small-allocation event count **36,206 C0 versus 34,971 original**, ~3.5% **more** events in C0; not allocated bytes.
- Complete checked 120-definition source/lazy-indexed/eager-indexed **16/17/24 ms**; 1200 checked WHNF **26/27/43 ms**.
- Same-run VmHWM **1,165,716 kB versus 1,165,844 kB**, near parity and not an attributable memory win. Other runs vary.
- 30 synthetic depth-11 shared-DAG universe instantiations **523 ms source versus 7 ms indexed**; this is a pathological **single helper**, not complete-checker throughput.

**All these were measured under Lean 4.34, and the target is now 4.35.** They remain historical controls, not performance claims for the newly pinned build. The unchanged project-local original checker shares lineage with C0, so its success does not prove official parity.

Con-ron's [OVERVIEW §9](https://github.com/leanprover/con-ron/blob/master/OVERVIEW.md#9-performance) documents a 2026-10-05 **different** Lean 4.35.0-rc3 export experiment: `Init` with ~57,919 declarations and Mathlib with ~703,103; con-ron (1 worker) **211.5G / 3,848G instructions** versus con-leche **488.94G / 8,853G**; con-ron's Mathlib max RSS ~7.26 GB, con-leche ~7.31 GB. Con-ron's eight workers used ~5.4–5.6 s on Init, versus one-worker ~21.8–22.0 s. These are **not** direct comparisons to C0's synthetic workloads. Their controlled corpus/allocations/worker settings are the benchmark standards to reproduce.

**Acceptance benchmark gate:** each design must have the same external v4.35 export corpus, accepted/declined/rejected categories, compiler pin, hardware/worker count, warm/cold start, fault/resource policy, and complete checker scope. Record:
- 100% correct accept/reject on the *supported* corpus and no false acceptance; explicit decline for unimplemented semantics;
- Init and then Std/Mathlib (where feature complete), plus deep binder, large-shared-DAG, negative recursor, quot and native-removal cases;
- throughput (decl/sec and true wall-clock), p50/p95/p99, independent CI runners, CPU instructions if measurable, allocated bytes, peak RSS, total cache/arena nodes and promotion cost;
- evidence against official v4.35 C++ `leanchecker --from-export`, con-leche, con-ron and unchanged C0 original source, always labeling cross-version policy differences.

**Never select a final execution representation solely on synthetic DAG speedups, or weaken error/timeout semantics to make perf tests pass.**

## 6. Coherent execution phases and explicit gates

| Phase | Work product | Acceptance gate |
| --- | --- | --- |
| **A: stable 4.35 migration (start now)** | Pin toolchain/identity; delete trusted native-reduction provider/marker path; simplify WHNF and DefEq; update CI/reference; add negatives for obsolete native markers | Full native build + malformed/negative/resource regression, old native marker cannot emit a computed result, unchanged sibling-source benchmark on unaffected subset, no accepted semantics weakened |
| **B: official compatibility & corpus** | Pinned `leanchecker --from-export` v4.35 comparison, con-leche/con-ron export-runner adapter, feature inventory and strict decline | Versioned accept/reject/decline corpus, no false acceptance, exact Lean feature matrix and error/resource taxonomy |
| **C: representation + caching redesign** | A unified immutable syntax/metadata model, optional con-ron-like two-tier arena with sealed handles, explicit `StoreWF` invariants and per-decl scratch lifecycle | Exact syntax and level import, ID/store isolation, no stale cache, independent differential proof obligations and measured allocation/RSS |
| **D: closure-based value execution candidate** | Native Lean evaluator with env-carrying closures/neutral heads and source-equivalent v4.35 rules; no source rebuild per beta step | Whole WHNF/DefEq/typed inference differential (including recursors/iota/quot/Nat, local freshness, resource/error) |
| **E: one accepting checker** | Consolidate typed core, DefEq, checked inference, declaration admission through selected execution model; remove obsolete double implementation | Atomic checked declarations, whole-corpus parity, no false acceptance, type/error/fuel preservation |
| **F: independent throughput qualification** | Repeated Init/Std/Mathlib benchmarks against official/con-leche/con-ron, controlled worker limits and memory/allocs | Measured **competitive or better** performance and memory without a weaker acceptance contract |
| **G: assurance (deferred)** | Verified semantics, `StoreWF` and refinement or a separate verified checker gate | Machine-checked properties and documented axiom/translator/runtime assumptions, not empirical CI alone |

Do not declare Phase A or any other phase complete on the strength of a **documentation** commit. Only code plus successful pinned CI and matched negative tests count.

## 7. Practical next code actions

1. Update `PsKernelTargetIdentityV1` to stable Lean 4.35.0 and tag SHA; preserve `KernelContract-v1` as schema identifier if external API shape remains unchanged, but fail any mismatched version/commit.
2. Remove `Runtime/Capability/Lean434NativeReduction.lean`, `PsKernelNativeEvaluator`, the provider/native-runtime field and its context propagation; remove all `psKernelReduceNative` paths from the accepting WHNF and lazy DefEq. Do **not** replace with another trusted shortcut.
3. Keep standard Nat arithmetic reduction and size protection as source/4.35 semantic contract. Add explicit native marker **negative** tests and stale-provider-version decline tests. Test on new pin **before** deeper architecture changes.
4. Turn the v4.35 `leanchecker --from-export` option into an independent official verifier harness, with a documented input format and a small committed corpus. Cross-check export fingerprints and policies; never compare different source declarations as if identical.
5. Benchmark the first two coherent representation families before a costly full trusted indexed/closure rewrite; continue autonomously through verified architectural milestones, not per-test patch hunting.

## 8. Research references

- [Lean stable v4.35.0 release](https://github.com/leanprover/lean4/releases/tag/v4.35.0) and [release notes (candidate feature record, #14953 and #15050)](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/)
- [Official kernel v4.35.0](https://github.com/leanprover/lean4/tree/v4.35.0/src/kernel)
- [con-leche source, set-model theorem and cached checker](https://github.com/leanprover/con-leche)
- [con-ron README, two-tier arrays, Lean twin, Aeneas verification and benchmarks](https://github.com/leanprover/con-ron)
- [Lean4Lean source and documented divergences](https://github.com/digama0/lean4lean)
- [Sokonanoda and MathGraph evaluation architectures](https://github.com/intgrah/sokonanoda)
- [PSKernel-C0 earlier comparative research](C0_LEAN4_KERNEL_COMPARATIVE_SOURCE_RESEARCH_2026-10-13.md)
- [Native C0 workflow](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/.github/workflows/pskernel-c0-lean.yml)
