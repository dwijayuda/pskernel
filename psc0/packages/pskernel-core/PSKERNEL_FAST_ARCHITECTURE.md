# PSKernel-Fast — Research and Architecture for a Fast, Small, Lean 4.35-Compatible Kernel

> **Status:** research and architecture proposal, NOT a completed implementation or a proof of full Lean compatibility.
>
> **Date:** 11 October 2026. Source study: GitHub and Lean Kernel Arena.
>
> **Project:** https://github.com/dwijayuda/pskernel
>
> **Implementation baseline:** `psc0/pskernel-core-lean435-arena-v1` at observed commit `69b3482adb365df35bf3f9c77da87ee4f3df5eca`.
>
> **Lean semantics authority:** Lean 4.35.0-rc4 at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
>
> **Change isolation:** `research/pskernel-fast-architecture-20261011`; do not modify or merge the active kernel proof branch as part of this research.

## 0. Executive decision

Build **one small, self-hostable semantic kernel with an optimized evaluation strategy**, not an independent second Rust or C++ kernel. `pskernel-fast` is the name of an opt-in high-performance **profile of the current PSKernel Core** (or a thin distribution wrapper for that profile). It must not own a second declaration checker, recursor validator, definitionally-equal oracle, source of truth, or independent trust policy.

Combine seven lessons:

1. **Official Lean 4.35:** normative inference, definitional equality, WHNF, universes, inductives, quotients, primitive operations, admission rules.
2. **sokonanoda and MathGraph:** closure/semantic-value evaluation avoids repeated term substitution; carefully scheduled comparison can be enormously faster on current large proof exports.
3. **nanoclo:** lazy immutable environments and expression read-set pruning reduce repeated context work.
4. **nanobruijn:** lazy uniform de Bruijn shifts and canonical shared syntax can reduce reallocation, but demand an expensive representation proof.
5. **lazylean:** call-by-need benefits exceptionally computation-heavy proofs; its newer 0.5.1 measurements must not be confused with the older 0.3.0 Arena version.
6. **con-ron:** compact tagged handles, constructor-specific storage and scratch/permanent arenas; also a template for implementation-refinement proof methodology.
7. **con-leche and existing PSKernel metatheory:** model, axiom interpretation, actual acceptance and environment extension must meet in an end-to-end conditional theorem; test parity alone is not soundness.

**Recommended sequence:** P0 profile the current checker; P1 optimize exact caches, spines and cheap WHNF/DefEq; P2 pilot a minimal closure view only if measured; P3 consider compact handles and context pruning; P4 qualify formal refinement and portable backends; P5 consider a specialized call-by-need machine only on proven high-value reflective workloads.

The rest of this document distinguishes **verified source observations**, **external measurements**, **unreplicated author claims**, **engineering hypotheses**, and **outstanding proof obligations**.

## 1. Success criteria and non-goals

| Requirement | Exact working definition | Insufficient substitute |
| --- | --- | --- |
| Semantic compatibility | Compare with a pinned official Lean 4.35 export and kernel; every supported check preserves official verdict and explicit resource / decline status | Pass a subset of old 4.34 tests |
| Soundness | Actual public acceptance implies modeled validity under explicitly stated set-theory and admissible-axiom assumptions | “All Arena tests green”, historical flawed judgments |
| Performance | Matched kernel-only instruction/wall-time cost and peak RSS improve; parse/import costs reported separately | Comparing different toolchains or exports |
| Smallness | Few semantic TCB rules, few trusted native primitives and minimal net maintained semantic LOC | Merely moving code into numerous helper packages |
| Portability | One semantic source; native and generated JS/Wasm qualify separately | Unreviewed handwritten Rust or JavaScript checker |
| Reliability | Rejection, unsupported, resource exhaustion and internal error are distinct, fail-closed outcomes | Retrying a decline with another checker and accepting its verdict |

Do not try to replace the official Lean 4 kernel everywhere, invent a new type theory, split the kernel into per-NPM-plugin trust decisions, or hide soundness work behind speed experiments. General Lean-compatible mode may allow arbitrary user axioms: there is **no unconditional theorem that it cannot derive False** when users may directly assume False. Verified consistency must expose a modeled-axiom policy.

## 2. Quantitative evidence: Lean Kernel Arena current round

Source: https://arena.lean-lang.org/ — live results observed on 2026-10-11.

The metric is **virtual CPU minutes** from instruction counts using 6 billion instructions per second, **not wall-clock duration**. The complete scored set here has 71 invalid and 134 valid tests; decline does not equal a wrong acceptance. Memory is the scoreboard peak RSS for the whole Mathlib test including any loader/runtime cost. **The official baseline on the scoreboard is Lean 4.34.1, not the 4.35-rc4 target.** Results are comparable only within the same Arena round. Figures rounded from the display.

| Checker (Arena version/profile) | Virtual CPU min, Mathlib | Approx speed vs official | Peak RSS | Invalid correct / 71 | Valid correct / 134 | Scope caveat |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| sokonanoda (7645b1e) | 1.4 | 23.1x | 7.3 GB | 69 | 134 | 2 invalid tests declined |
| MathGraph (flash) | 2.2 | 14.7x | 6.7 GB | 71 | 134 | Complete scored coverage |
| nanoclo (a2aa37e) | 8.2 | 3.9x | 7.4 GB | 71 | 134 | Complete scored coverage |
| con-ron (328307e) | 10.8 | 3.0x | 7.1 GB | 68 | 128 | 3 invalid + 6 valid declines |
| nanobruijn (4f9b955) | 13.2 | 2.4x | 6.7 GB | 71 | 134 | Complete scored coverage |
| lazylean **0.3.0** | 16.4 | 2.0x | 7.0 GB | 71 | 134 | NOT its newer 0.5.1 |
| nanoda (4c544ed) | 16.6 | 1.9x | 6.0 GB | 71 | 132 | 2 valid declines |
| con-leche (67f0463) | 24.7 | 1.3x | 7.1 GB | 68 | 128 | Verified axiom scope declines |
| eink0rn (1.1.6) | 28.4 | 1.1x | 11.6 GB | 71 | 134 | Independent Haskell implementation |
| official Lean **4.34.1** | 32.3 | 1.0x | 9.9 GB | 71 | 134 | Compatibility reference for this round |
| lean4lean (arena) | 38.8 | 0.83x | 11.6 GB | 71 | 134 | Lean port, metatheory effort |

**Two supported rankings:** sokonanoda is the fastest scored checker by this virtual CPU metric; MathGraph is the fastest *among checkers with no declines* on the current scored tests. Neither fact alone proves formal soundness, general Lean 4.35 compatibility, kernel-only speed, or small compiled binary size.

**Lazylean version caveat:** its current upstream README discusses **0.5.1**, claiming around 0.48 trillion instructions, 4.7 GB and strong computation-heavy results. The Arena still scores **0.3.0**. Do not put 0.5.1 figures in this comparison table or assert it wins without rerunning on the identical export/version/hardware.

Arena test archive: https://arena.lean-lang.org/lean-arena-tests.tar.gz (the site currently advertises 125 small good and 71 small bad tests; giant good tests are excluded from the archive). The live scored total is larger because large inputs remain part of the server suite.

## 3. Reading the official Lean 4.35 kernel

Reference: https://github.com/leanprover/lean4/tree/v4.35.0-rc4/src/kernel

The official kernel is *not* just a small one-file checker. Its kernel sources include `expr.cpp`, `instantiate.cpp`, `level.cpp`, `local_ctx.cpp`, `environment.cpp`, `declaration.cpp`, `inductive.cpp`, `quot.cpp` and `type_checker.cpp`; expression implementation also relies on the Lean runtime via `lean_expr_*`. Report transitive code/runtime dependencies in any future TCB size comparison.

### 3.1 Type checking and definitional equality

At pinned [type_checker.cpp](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.cpp):

- `infer_type_core` near line 325 dispatches expressions and maintains **separate inference-only and checked** caches. Infer-only is not an automatically checked proof.
- `whnf_core` near line 468 handles structural/head reductions with a limited unfolding strategy; `whnf` near line 706 handles further unfolding / primitive reduction.
- `reduce_nat` near line 672 remains in 4.35: **removing the historical compiler-backed Lean.reduceBool/Lean.reduceNat capabilities does not remove all primitive numeric kernel computation**.
- `quick_is_def_eq` near line 802, application/spine comparison near 878, proof irrelevance near 899, lazy δ near 1055 and `is_def_eq_core` near 1132 are major fast-path targets.
- The main DefEq procedure tries cheap syntactic equivalence; selected boolean reflection; cheap β/ι/projection normalization; guarded proof irrelevance; lazy delta reduction; rigid same-head comparison and projection heuristics; full WHNF if needed; application comparison; function eta; structure eta; string literal and unit-like comparison. **The fallback and order matter.**
- [type_checker.h](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.h) holds infer caches, WHNF caches and positive/negative DefEq memoization. A failed speculative check cannot be treated as a permanent fact without its exact assumptions.

Other essential sources:
- [inductive.cpp](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/inductive.cpp): parameter and constructor checks, strict positivity, elimination restrictions, inductive/recursor generation; derived export recursors cannot simply be trusted.
- [level.cpp](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/level.cpp): universe equalities, `max`, `imax` and normalization.
- [declaration.cpp](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/declaration.cpp) and [quot.cpp](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/quot.cpp): declaration admission and quotient rules.

### 3.2 Normative Lean version change

`psc0` current work targets **Lean 4.35.0-rc4**. It must not silently treat the retired 4.34 compiler-backed reduction machinery as still trusted. Maintain separately named/version-gated rules for 4.34 historical conformance if needed, but require exact 4.35 behaviour in the new active target. Primitive `Nat`/literal reduction in `type_checker.cpp` still exists and must be accounted for.

### 3.3 Lesson

Official Lean avoids full normalization whenever a cheaper DefEq path can prove equality. **Do less work before unfolding more**. Preserve its actual logical checks and precise version-specific semantics while changing storage, lookup, and evaluation scheduling.


## 4. Fast checker algorithms and what PSKernel should borrow

### 4.1 sokonanoda — closure-based high throughput

Repo: https://github.com/intgrah/sokonanoda

Rust implementation derived from nanoda, influenced by semantic-value/closure-based conversion. On the current Arena Mathlib export: 1.4 virtual minutes and 7.3 GB peak, with two declined negative cases rather than observed incorrect acceptance.

**Transfer:** avoid allocating a fully instantiated syntax tree at every beta or let step. Keep a closure consisting of a term and scoped environment, expose only the needed WHNF head, and compare rigid spines before expensive delta expansion. **Caution:** the closure engine must preserve proof irrelevance, eta, recursor and universe behavior; speed is not itself a proof.

### 4.2 MathGraph — fastest complete scored coverage

Repo: https://github.com/metalogiclabs/mathgraph-lean-kernel

A Rust improvement of sokonanoda, **not an independent clean-room checker**. All 71 invalid and 134 valid scored tests are handled in the current Arena, at 2.2 virtual minutes and 6.7 GB. Inspected files:

| Source | Observed implementation | Transfer question |
| --- | --- | --- |
| [eval.rs](https://github.com/metalogiclabs/mathgraph-lean-kernel/blob/main/src/eval.rs): `eval` ~445, `eval_no_cache` ~470 | Evaluate syntax into shared values with closed/open caches | Which PSKernel subterms are repeatedly evaluated under equivalent environments? |
| `eval.rs`: `force_thunk` ~704 and `whnf_head` ~929 | Deferred evaluation and head forcing | Can substitution be avoided until a head is required? |
| [conv.rs](https://github.com/metalogiclabs/mathgraph-lean-kernel/blob/main/src/conv.rs): `def_eq_core` ~25, `def_eq_at` ~52 | Value-oriented conversion | Which existing DefEq branches cause duplicate WHNF? |
| `conv.rs`: `try_proof_irrel_at` ~594 | Type-sensitive proof irrelevance | Can already validated annotations safely avoid re-inference? |
| [value.rs](https://github.com/metalogiclabs/mathgraph-lean-kernel/blob/main/src/value.rs) | Closures, neutral/rigid heads, environments, thunks/spines | Could a small internal view offer most of the gain? |

It maintains many caches, such as constant-head values/types, environment internings and canonicalized values. These are **not** automatically safe. Cache reuse requires exact target version, checked context, universe instantiation, environment generation and opacity settings. Adopt one measured cache at a time; do not transplant the entire caching apparatus.

### 4.3 nanoclo — delayed substitution, interned environments

Repo: https://github.com/sgraf812/nanoclo

Inspected `src/closure.rs`: interned environment nodes (`EnvNode`), closure representations (`Clo`), cheap environment extension, indexed lookup, and read-set projections that permit equivalent evaluations across contexts containing irrelevant variables. Arena: 8.2 virtual minutes, 7.4 GB, all scored tests handled.

**Transfer:** begin with exact closed-term memoization; later try caching by **precisely proven free-variable projections**. If a read mask is too narrow, too deep, overflows, or cannot be proved correct, conservatively use the entire environment. An internal 64-bit mask is not a bound on Lean binder depth.

### 4.4 nanobruijn — O(1) binder-depth shifts

Repo: https://github.com/nomeata/nanobruijn

Its representation uses `ExprPtr = (CorePtr, u16 shift)` with uniform shifts carried in pointer-offset pairs, plus shift-homomorphic caching and parse-time outermost-shift normal form (OSNF). Equal subgraphs modulo a uniform binder shift can be shared. Arena: 13.2 virtual minutes and 6.7 GB, complete scored coverage.

**Transfer:** possible P3 experiment if profiles prove repeated lifting dominates memory. **Risk:** wholesale representation change; needs proofs of binder capture avoidance, substitution composition, scope, shift overflow, reification and cache equivalence. The repository's `Theory.lean` formalizes representation properties; it is not a complete checker-soundness theorem.

### 4.5 lazylean — computation-heavy normalization

Repo: https://github.com/corun1024/lazylean

The 0.5.1 README describes a C++ checker using semantic closures/neutral spines, a call-by-need Krivine-style computation engine, hash-consing, pruned environments, and bounded long-lived plus scratch evaluation sessions. It reports large gains on computation-heavy verification (including reflective decision procedures). **Those author-reported 0.5.1 numbers were not replicated here. Arena still measures 0.3.0.**

**Transfer:** isolate long-lived immutable imports from reclamable temporary reductions. Treat ordinary Mathlib checking and giant `decide` computations as different performance profiles but not different proof-checker authorities. A second abstract machine would be a substantial source-size and formal-proof cost; **do not include it in the MVP**.

### 4.6 con-ron — compact handles and refinement proof

Repo: https://github.com/leanprover/con-ron, particularly [README](https://github.com/leanprover/con-ron/blob/master/README.md) and [OVERVIEW](https://github.com/leanprover/con-ron/blob/master/OVERVIEW.md).

con-ron connects an optimized Rust checker to a Lean “twin” through Aeneas, and the twin to the pure con-leche algorithm by a simulation/refinement proof under stated assumptions. The driver/export parser and external infrastructure are **not all covered**. Current Arena: 10.8 virtual minutes, 7.1 GB, nine declines in its restricted verified profile.

- Hash-cons names, levels, expressions.
- Use compact, tagged `u32`-style expression handles.
- Separate permanent admitted-environment storage and per-declaration scratch nodes.
- Store variant payloads in **per-constructor arrays**, instead of a large tagged-union object at every node.
- Maintain two explicit refinement steps: optimized representation -> executable checking algorithm -> mathematical/model semantics.

**Transfer:** data-layout and proof architecture, not Rust as a second production semantic source. Any compact PSKernel handle must have checked bounds/generation/tag, collision-checked interned identity, and a proven erasure into the existing raw expression.

### 4.7 con-leche — soundness under explicit model assumptions

Repo: https://github.com/leanprover/con-leche

The Lean checker provides a conditional relative consistency/model theorem with an explicitly restricted verified axiom regime. It declines some otherwise Lean-valid declarations that rely on unmodeled/nonstandard axioms. **Its proof is not a proof of PSKernel's checker.** Copying only pure set-theoretic mathematics (as the active PSKernel proof work does) still requires proving correctness of the actual PSKernel checker.

### 4.8 lean4lean and eink0rn — validation diversity

[lean4lean](https://github.com/digama0/lean4lean) is a Lean port close to the official C++ implementation, useful for semantic source comparison and proof ideas. eink0rn is independently developed in Haskell and offers valuable implementation diversity. Independent checker agreement increases confidence but does not imply soundness or authoritatively resolve a disagreement. On releases, record accepted/rejected/declined separately; never “accept if any checker accepts”.

## 5. Active PSKernel source and soundness constraints

**Active branch:** `psc0/pskernel-core-lean435-arena-v1`, NOT the historical `main` 4.34 implementation.

~~~text
psc0/packages/pskernel-core/
  src/Ps/KernelCore/
    Core/                   expressions, universes, substitutions, annotations
    Environment/            checked environment and derived lookups
    Checker/
      Knot.lean             ONE recursive checker owner
      Inference/            full checking versus infer-only
      Reduction/            beta, let, delta, WHNF, primitive operations
      DefEq/                quick equality, applications, lazy delta, eta
      Recursor/             recursor reduction/validation
      State.lean            inferOnly, checkedInfer, whnfCore, whnf,
                            unfold, success, failure caches
    Admission/              definitions, axioms, ordinary/mutual/nested
                            inductives, quotient
    Runtime/Acceleration/   Cache, CachePolicy, EnvironmentIndex
    Runtime/Capability/     explicitly trusted capabilities
    API/                    checked sessions and reference-mode entry
    SelfHost.lean           one semantic source root
  metatheory/               formal model and correctness work, not runtime
  host/                     exports, Arena integration, diagnostics
~~~

Its reference mode disables semantic caching using **the same checking rules**, while ordinary cached mode still uses the one checker. A dedicated fast profile should do the same: choose a strategy within the current implementation, not clone `Checker/Knot`.

According to active [AI_WORK_STATE](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/AI_WORK_STATE.md), the validated Oct. 11 proof source `f7d00c2c61c78f7148c5f6c9080e72cc3cbf2b01` passed focused metatheory/test CI (283 jobs, 84 companion files, seven native executables). Full Init/Std/Mathlib were deliberately skipped; earlier broad Init and Std replay timed out. **Neither full 4.35 conformance nor full kernel consistency has been proven**.

The old `Judgments.lean` equality/typing model was shown inadequate in `JudgmentAdequacy.lean`: that is a defect in proof specification, **not evidence of executable false acceptance**. New annotated-expression/universe-regime semantic work remains unfinished. In particular, successful admission of a fresh constant needs a **constructive semantic-model extension** preserving previously interpreted constants and the pinned False interpretation. Assuming `StoredConstantModeled` for an arbitrary fixed model would silently bypass this real proof obligation.

**Do not invalidate the proof work.** Keep PR #89, active `AI_WORK_STATE.md` and proof branch unchanged; prototype on an isolated branch. P0 profiling needs no semantic rewrite. P1 implementation in `Checker/Knot` or shared inference should only merge with proof-owner coordination. Lean-native proof/source work is not automatically qualified for the latest PSC0 self-host compiler or generated JS/Wasm; those are separate explicit gates.
