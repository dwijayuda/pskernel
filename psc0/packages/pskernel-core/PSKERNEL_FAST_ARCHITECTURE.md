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

## 6. Optimization selection matrix: gain versus semantic and size cost

These ratings are **architectural hypotheses**, not PSKernel measurements.

| Optimization | Potential benefit | New TCB/LOC burden | Semantic proof risk | Portability risk | Decision |
| --- | --- | --- | --- | --- | --- |
| Observation-only instruction/alloc/cache counters | Identifies real hotspots | Very low | None if fully observational | Low | **P0: adopt now** |
| Faster existing expression lookup/index | Fewer repeated traversals | Low | Low/medium: exact key comparison | Low | P1 if measured |
| Cache boundedness and session lifetimes | Less retained memory | Low/medium | Medium: scope/expiry | Low | P1 |
| Same-head app spine inspection before expensive expansions | Less DefEq work | Low/medium | Medium: official ordering | Low | P1 |
| Avoid unnecessary beta/let syntax rebuilding | Fewer allocations | Medium | Medium/high: scope/erasure | Low/medium | P1/P2 |
| Small internal closure view | Faster beta/let-heavy work | Medium | High: evaluator equivalence | Medium | P2 pilot |
| Memoize with exact free-variable environment projection | Higher cache hit rate | Medium/high | High: mask/scope proof | Medium | P2/P3 |
| Tagged compact DAG handles and scratch pools | Lower memory/allocations | High | High: alias/lifetime | High | P3 if RSS bound |
| Shift-homomorphic de Bruijn / OSNF | Sharing across binder depths | High | Very high | High | Research only |
| Full NbE + call-by-need machine | Huge potential for reflective proofs | Very high | Very high | Very high | P5 only |
| Separate handwritten Rust/C++ proof checker | May be fast | Duplicates semantics | Very high | Violates target | **Reject** |

**Optimization priority law:** first remove duplicated work, then avoid allocation, then reduce retained memory, then specialize computation. Every extra table or runtime representation has a continuing code, maintenance, portability and formal-proof cost.

## 7. PSKernel-Fast architecture

### 7.1 One checker, separate non-authoritative acceleration

~~~text
Untrusted Lean export / ProofScript proof terms
                     |
             host reader/decoder
                     |
       validated typed request and axioms
                     |
       existing checked admission/session API
                     |
              Checker/Knot.lean
              /           \
       inference       DefEq + WHNF
                             |
                 optional Fast acceleration
                   /        |        \
               cheap       exact     optional
               spines      caches    closure view
                             |
                  one canonical semantic result
                             |
                atomic successful admission
~~~

No optimizer or npm extension may issue proof acceptance independently, introduce a new trusted DefEq rule, define new kernel axioms, approve a foreign native evaluator, or change result classification without an explicit semantic-version and TCB decision.

**Suggested layout (conditional additions, not new required packages):**

~~~text
src/Ps/KernelCore/
  Checker/
    Knot.lean                       # current ONE recursion/semantic owner
    DefEq/*                         # optimize existing rules, not FastDefEq clone
    Reduction/*                     # optimize existing WHNF, not a new reducer
  Runtime/Acceleration/
    Cache.lean                      # current exact-key cache
    CachePolicy.lean                # current reference/cached policy
    EnvironmentIndex.lean          # current
    Fast/
      Counters.lean                 # P0 optional, semantic-neutral
      SpineView.lean                # P1 non-owning application spine
      ClosedMemo.lean               # P1 exact closed-term memo
      ClosureView.lean              # P2 scoped delayed substitution
      SessionStorage.lean           # P3 conditional scratch storage
      Profile.lean                  # bounded strategy flags, no proof rules
  API/
    Fast.lean                       # OPTIONAL thin preset of existing API
~~~

The **`pskernel-fast` name** denotes the fast execution profile. A future `@proofscript/pskernel-fast` npm package may be a thin deployment wrapper over `@proofscript/pskernel-core`, not a metapackage of all ProofScript packages and not a second semantic checker. A fast-profile wrapper may change memory limits, diagnostics and acceleration flags, but may not redefine the checked admission judgment.

### 7.2 Evaluate a closure **view**, not an independent kernel

Minimal internal view:

~~~text
ClosureView = {
  term: RawExpr,
  values: ScopedImmutableEnvironment,
  levelSubstitution: ExactUniverseParameters,
  binderDepth: Nat,
  originatingEnvironmentGeneration: EnvGeneration,
  checkedContextIdentity: ContextIdentity
}
~~~

Conceptual code only; this is NOT a claim about currently accepted PSC0 syntax.

~~~text
inspectHead(view):
  check fuel, recursion, stack and memory policy
  if head == bound variable:
       use exact binder-indexed environment lookup
  if head == application:
       flatten spine without eagerly rebuilding syntax
  if head == lambda applied to argument:
       extend environment lazily
  if head == let:
       extend environment lazily, forcing only when needed
  if head == constant:
       stay folded unless official-style unfolding is demanded
  if head == recursor / projection / literal:
       invoke canonical rule owner with exact checked arguments
  otherwise:
       yield neutral/unknown head
~~~

The view must be **internally scoped and opaque to untrusted callers**. Terms/values exposed at admission boundaries must use the validated raw expression representation or a proved erasure. An accelerator that cannot establish a fact returns **UNKNOWN**, not “equal”.

An unconditional alternative semantic evaluator used to accept declarations would create a second kernel in effect, even if placed in a helper module. Stage P2 should use the view either to produce results rechecked by canonical code or to replace a raw operation only after a semantic refinement theorem supports it.

### 7.3 Conversion scheduling without changing the kernel's rules

Official 4.35 behavior has precisely ordered cheap and expensive operations. P1 should be a **surgical improvement of existing `Checker/DefEq` and `Reduction` owners**, not a brand-new algorithm that tries “faster” shortcuts by guessing validity.

Conceptual outline:

~~~text
defeq(a, b, context):
  check resource and version policy
  if exact_proven_raw_identity(a,b): return Equal
  if exact_checked_positive_cache(context,a,b): return Equal

  a0 = cheap_weak_head(a)
  b0 = cheap_weak_head(b)

  if guarded_quick_equality(a0,b0): return Equal
  if type_justified_proof_irrelevance(a0,b0): return Equal

  # Continue precisely the pinned official-compatible rules:
  # permitted lazy delta; recursor/projection computation;
  # rigid same-head spine; full WHNF when needed;
  # function and structure eta; literals; unit-like structures.
  r = canonical_remaining_defeq(a0,b0,context)

  if r == Equal:
     store a positive entry only under valid exact keys
  return r
~~~

A **quick false** is *not* a safe reason to declare unequal: another valid Lean reduction may make the expressions convertible. Preserve the existing DefEq continuation, local context, reduction hints, and fuel outcomes. A quick **true** is trustworthy only if structural equality is exact and properly guarded, proof irrelevance is type-justified, or a verified refinement covers the branch.

**Annotation warning:** the current `UniverseRegime.check` work matters here. Raw structural equality and hereditary validity alone cannot justify equating differently interpreted binder annotations over an empty domain. Any shortcut must preserve the current exact annotation/universe-regime invariant.

### 7.4 Cache law: indexes are not proofs

Proposed per-cache identity, assuming any optimization is adopted:

| Cache entry | Required stable identity / premises | Lifetime |
| --- | --- | --- |
| Interned raw expression | Constructor tag, exact child IDs, binder/level/literal metadata; collision-checked equality | Permanent or uniquely tagged scratch |
| Infer-only type | Term, local context/scope, universe parameters, environment generation, *infer-only mode* | Proven context/session |
| Fully checked type | All above plus actual checked judgment; never infer-only-as-checked | Proven checked session |
| WHNF / constant unfolding | Expr or closure environment, level substitution, transparency/opaque policy, target version, environment generation | Controlled immutable environment epoch |
| Positive DefEq | Both terms, exact well-typed context, checking mode, universe/transparency rules, valid positive reasoning | Context-safe, bounded |
| Negative DefEq | **Do not enable initially**; negative results can be strategy/incompleteness/resource-dependent | Off unless separately proved |
| Inductive metadata | Checked constructor/recursor info, declaration fingerprint, generated identity and target version | After atomic checked admission |
| Proof-irrelevant argument relevance | Type and annotation provenance established by checked inference | Exact typed environment and term |

Machine hashes only accelerate lookup. Equal hash values do **not** establish equal kernel expressions. Pointer equality is only meaningful if unique canonicalization of *live* interned values has already been proven and each handle carries a valid lifetime/generation.

Cache eviction, missing entries, capacity caps, hash collisions, timeouts or host GC events must not change which proof is accepted. A poisoned cache is a semantic hazard, not an optional “optimization result”. A cache-disabled reference specialization remains essential as an executable differential baseline.

**Acceptance caveat:** the checker must not switch to a different provider after a declined/failed check and announce an accepted proof. An internal speculative optimization may return UNKNOWN so the **same canonical checker call** continues ordinary checking, but an unsupported target/resource failure cannot be turned into acceptance by an ad-hoc provider fallback.

### 7.5 Resource and memory lifecycle

Suggested storage separation:

1. **Immutable admitted environment:** validated declarations, canonical name/level/expression IDs, checked recursor metadata; commit only after all checks complete.
2. **Session-local exact caches:** WHNF/inference/DefEq values with immutable environment identity and bounded size; evict only where correctness says absence is harmless.
3. **Per-declaration scratch:** closure values, reconstructed app spines, provisional recursor metadata and allocated intermediate terms; reclaim after accepted transaction or failure.

For P0/P1 use existing Lean arrays/maps and GC unless a profile proves they are a bottleneck. A custom arena in P3 must prove ID bounds, constructor tag, arena generation, no stale alias and no scratch object escaping into an admitted environment.

Compact handles or separate arrays may be useful in native builds, but must not require handwritten per-backend semantics. If current PSC0 self-host language cannot qualify the new representation, defer it or keep it in a clearly **non-production native experiment**.

### 7.6 What the fast profile must never control

- Axiom whitelist or verified consistency policy.
- Kernel semantic version or exporter protocol without a pinned migration.
- Proved-versus-unchecked annotations and inference grade.
- Recursor positivity, constructor types, quotient or induction admission.
- Declaration transaction commit/rollback.
- The trusted status of a foreign evaluator or kernel extension.
- Proof acceptance after internal errors, unsupported input or exhausted resources.

This security boundary keeps extensibility outside soundness-critical authority while still allowing source-to-source compiler plugins, nontrusted tactics, package-specific diagnostics, or alternative backend packaging.

## 8. Semantic compatibility and negative-conformance matrix

Each row should have: pinned official 4.35 source locator, at least one valid and one invalid term, current PSKernel owner, reference/cached/fast verdicts, resource outcome and the corresponding proof or assumption status.

| Semantics | Mandatory detail | Optimization failure mode |
| --- | --- | --- |
| Universes and `Prop` | Impredicative `Prop`, `imax`, `max`, level equality, proper substitution | Treating zero and positive universe assignments as interchangeable |
| Bindings and scope | de Bruijn shifts, capture-avoiding substitutions, free/local variables | Wrong environment projection, shift overflow |
| Checked vs infer-only | Separate cache grades and infer-only assumptions | False acceptance by treating inferred type as verified |
| Beta, zeta, delta, iota | Exact reductions, transparency, recursors and resource behavior | Eager unfolding that changes termination or consistency |
| DefEq | Rigid heads, eta, structure eta, proof irrelevance, special unit-like and string cases | Early false/true shortcut bypassing canonical checks |
| Inductive declarations | Strict positivity, uniform parameters, constructor typing | Accepting unvalidated exported recursor tables |
| Mutual/nested inductives | Verified generation and elimination conditions | Partially committing generated declaration auxiliaries |
| Quotients | Exact permitted eliminators and quotient reduction | Treating quotient proof as unrestricted data |
| Primitive computation | Actual Lean 4.35 Nat/String/literal semantics and size limits | Deleting all Nat reduction because old compiler-backed op was removed |
| Axioms and unsafe declarations | Explicit policy, no unsafe evaluator as logical rule | Untrusted foreign computation certifying proofs |
| Environment | Fresh names, opaque definitions, source/policy epochs and atomic commit | Reusing cached type/DefEq for a changed declaration |
| Resource failure | Separate declinedUnsupported, rejectedInvalid, resourceExhausted, internalError | Retrying as success, ignoring budget |

**Full compatibility is different from modeled-axiom safe mode.** The latter may intentionally decline a valid Lean proof relying on arbitrary foreign axioms. Advertise separately; neither a full-score Arena suite nor con-leche's limited axiom profile establishes “all Lean proofs supported”.

## 9. Formal assurance: required actual theorem chain

The goal is a theorem about the ACTUAL executable public checker, not a diagram that purports to show proof completion:

~~~text
Untrusted export -> validated term and declaration input
        |
optional optimized representation and safe cache
        |  (erasure + positive-result refinement)
        v
ONE reference Checker/Knot checking semantics
        |  (joint infer/WHNF/DefEq soundness)
        v
modeled expression / type judgment
        |  (complete declaration admission)
        v
constructively extended model for fresh declarations
        |  (explicit assumptions about axioms and set theory)
        v
conditional no derived proof of False
~~~

**None of the full end-to-end arrows is currently claimed as complete** on the active PSKernel branch. A theorem about one metadata, sort, constant, binder or application case does not certify every recursive branch. Adding closures or caching adds proof obligations rather than replacing the existing soundness work.

| Fast component | Required result | Unsoundness or compatibility defect to exclude |
| --- | --- | --- |
| Positive infer/WHNF/DefEq cache | Every hit has same expression, exact context, target, environment, mode and admissible interpretation | Stale context/universe cache false success |
| Spine view | Application flatten/reconstruct is exact, preserving arity and binder metadata | Dropped argument or wrong level instantiation |
| Closure view | Forcing/erasure matches canonical WHNF under correct scoped substitutions | Captured or shifted variable interpreted incorrectly |
| Context pruning | Projection includes every variable the term actually reads | Free-variable mask overflow or omission |
| Positive equality shortcut | Fast Equal implies reference/model Equal under identical typing and annotation premises | Unproved proof-irrelevance acceptance |
| Interned compact handle | Live handle decoding is injective and generation-safe; no scratch escape | Old allocation reused as another term |
| Optimized literals | Numerals and strings match the pinned 4.35 behavior and size limits | Foreign arithmetic shortcut changes truth |
| Generated self-host backend | Compiled output preserves source checked semantics and failure classification | JS/Wasm omits a guard |

**Safety versus completeness:** affirmative fast equality must imply correct kernel equality; conversely, if the fast path cannot decide, the same canonical checker should continue and not falsely reject a valid case. An unsupported operation, exhausted resource or failed checker cannot be transformed into successful admission by a fallback authority.

In the current formal work, respect two crucial facts. First, checked annotations and universe zero/positive regime coherence are required for any positive structural comparison. Second, the model interpretation of a newly admitted fresh constant must be constructed, rather than assumed for an arbitrary fixed model. Never use an upstream con-leche theorem as a substitute for proving PSKernel's executed path correct.

## 10. Benchmarks: distinguish kernel throughput and parse speed

For each workload record:

~~~text
source commit, Lean SHA, exporter and protocol SHA
axiom/profile modes, checker flags, memory and resource limits
corpus hash, full input size and declaration count
CPU/memory/OS/compiler flags, number of samples
parse/import time, kernel-only time, total wall time
retired instruction count / normalized virtual CPU
peak RSS, allocations, retained memory, scratch high water
cache hits/misses, WHNF/beta/let/delta/recursor counts
accepted, rejected, declined, exhausted, internal-error totals
~~~

Measure at least three matched samples and report medians/ranges. Compare identical semantic versions and hardware; cache warmness must be specified. Never convert parser speedups into claimed semantic kernel speedups.

| Workload | Performance reason | Mandatory correctness case |
| --- | --- | --- |
| Arena tutorial and scored negative corpus | Cheap broad conformance | No known-invalid accepted |
| Fresh pinned Lean 4.35 Prelude / focused Std | Typical program proofs | Same version/export and correct result |
| Int64 and large Nat computation | Historically expensive/timed-out case | Numeral limits, failure semantics |
| Beta and let ladders | Eager substitution allocator cost | Capture avoidance |
| Deep dependent binders and shift cascades | Scope/shift workload | Exact context identity |
| Same-head applications and opaque definitions | Delta/DefEq scheduling | No premature unequal result |
| Expensive expressions in proofs erased by proof irrelevance | Avoid unnecessary evaluation | Type is checked as Prop first |
| Mutual/nested inductives and recursors | Admission and iota | Recheck generated recursors |
| Repeated shared expression DAGs | Hashcons/cache reuse | No hash collision or scratch alias |
| Reflective computation and decide tactics | Lazy evaluation potential | Exact reduction, bounded memory |
| Full fresh Init/Std/Mathlib | Large-scale qualification | Later RELEASE milestone only |

A full suite timeout is **not** a pass; a green focused workflow with the full Mathlib job deliberately skipped is **not** a Mathlib conformance certificate.

### Suggested P1 targets, explicitly not measured facts

The following are proposed thresholds to decide whether new complexity is worthwhile. They can be revised based on P0 profiling.

- At least **1.25x median kernel-only speedup** on a pinned named hot workload.
- No more than **10% matched peak-RSS regression** and no more than **5% overall focused-mix slowdown**, unless a documented tradeoff is accepted.
- Exact parity in the supported positive/negative suites and no new accepted invalid proof.
- For a P2 closure-view pilot, seek **2x on beta/let-dominated cases** and meaningful allocation savings; otherwise prefer the simpler P1 checker.
- Do not promise 15x or 24x faster performance against Lean based on unlike export versions or parser-inclusive whole-checker benchmarks.

## 11. Implementation roadmap and acceptance gates

### P0 — source and performance baseline without behavior changes

1. Re-fetch the current active branch and pinned 4.35 toolchain; inspect completed CI and the exact export corpus.
2. Trace current `Checker/State`, `Runtime/Acceleration/Cache`, `EnvironmentIndex`, `Checker/Reduction/WhnfCore`, `Checker/DefEq/Quick`, `DeltaStep` and `Checker/Knot`.
3. Use host-side or disabled-by-default counters where possible, recording actual time, allocations, cache hits, type inference, WHNF, delta unfolding and DefEq steps.
4. Analyze *bounded, reproducible* 4.35 Int64, Prelude, Std/Init-prefix and beta/let cases before costly full-corpus runs.
5. Produce a **hotspot ledger** linking measured costs to one semantic code owner, candidate optimization, expected extra trusted code and required formal invariant.

**Exit:** reproducible reference/cached baseline plus top-five costs. No semantic edit required; no speedup claimed yet.

### P1 — surgical existing-core improvements

- Pick **one highest-payoff measured family**: raw expression lookup, lazy app spine inspection, validated positive caching, or avoiding pointless term reconstruction.
- Preserve the existing shared `Checker/Knot` and reference/cached result classification; do not add a cloned FastDefEq implementation.
- Specify the applicable source-to-official-rule mapping and proof obligation before changing checked code.
- Keep the reference cache-disabled mode as an independent path through the *same* implementation.
- Run focused negative, tutorial, typed, version-pinned and supported portability gates, followed by a matched benchmark.
- Coordinate with the active metatheory authors before modifying recursion that current proofs target.

**Exit:** P1 proposed speed and resource goals, exact verdict parity, no extra trust capability and an audited proof/TCB delta. Revert ineffective optimizations, not individual tests.

### P2 — a small closure-view pilot

- Add an immutable term+environment view to reduce unnecessary beta/let reconstruction *inside the current WHNF rules*.
- Initially support only exact-scoped cases, reifying to the canonical raw expression at any unchecked boundary.
- Do not allow an unproved closure comparison to return an authoritative success; prove refinement or validate the result through the existing rule.
- Benchmark time, allocations, peak RSS, recursion behavior and portability with a bounded beta-heavy suite.

**Exit:** real beta/let win, exact scope/erasure evidence, no wider TCB without commensurate benefit; otherwise revert.

### P3 — representation compaction, only if profiles justify it

- Consider small tagged IDs, per-constructor storage, permanent/scratch arenas and exact free-variable read-set pruning.
- Prove generation/tag/bounds validity, collision-checked interning and no scratch reference escaping into an admitted declaration.
- Keep experiments non-authoritative until the current PSC0 compiler can accept/qualify their source semantics.

**Exit:** material memory improvement and reviewed source-size, proof and portability cost. Do not replace the canonical public Expr form merely for aesthetic uniformity.

### P4 — soundness refinement and portable release

- Let the ongoing active 4.35 program complete the **actual reference checker** recursive and modeled-admission obligations.
- Prove cached/fast positive-result refinement with explicit axiom/model assumptions, or mark the result unverified.
- Qualify exact native and generated JS/Wasm artifacts from the same semantic source with version-locked acceptance evidence; the generated outputs may have different performance but **must not have different semantics**.
- Use independent external checkers for optional release assurance, never as an authority that turns internal declines into acceptances.

**Exit:** precise proof status, full supported pinned compatibility and artifact identity; no fake “fully verified” badge based on unproved links.

### P5 — computation-specialized evaluation (deferred)

Study a lazylean-style call-by-need evaluator only if P0–P3 still show real, unacceptable reflective-computation costs. Preserve one admission checker and prove any alternate evaluator's effect on successful WHNF/DefEq. Do not include a second unreviewed computational oracle in MVP.

## 12. The smallness budget and opportunity cost

There is no valid measured estimate yet of exact added PSKernel LOC. The bands below are **planning scenarios**, not empirical implementation estimates; measure **net versus gross additional semantic LOC**, trusted dependencies, proof obligations and generated backend burden separately.

| Scope | Illustrative additional semantic Lean LOC | Relative complexity |
| --- | ---: | --- |
| P0 profiling (prefer host-only) | 0–300 | Very low |
| P1 cache/spine/hot-path changes | 300–1,500 | Low to medium |
| P2 closure view and correspondence | 800–2,500 | Medium/high |
| P3 compact arenas/context pruning | 1,000–3,000 | High |
| P5 full lazy machine | 2,000–6,000+ | Very high |

For every milestone report the transitive code that can change acceptance, including runtime/foreign primitives; don't reduce the reported TCB by moving semantics into an NPM package. Track total maintained kernel implementations (must be **one**), proof-module count separately, source lines, generated artifact size, peak RSS, cold-start cost, and speedup per added complexity. Net deletion of repeated substitution or duplicated cache code is better than a large extra graph-reduction framework.

### Hard stop/revert criteria

Stop when an optimization causes any of the following:

- known-invalid input accepted, stale positive DefEq entry, invalid inductive auxiliary committed or unmodeled native primitive trusted;
- a new `sorry`, custom soundness axiom or opaque assumed result used to disguise incomplete proof;
- cache or fast-path result acceptance without an exact semantic invariant, or swallowed resource/unsupported/internal failures;
- a parallel maintained checker or backend-specific handwritten kernel semantics;
- reducing a conformance gate, ignoring timeout, or reporting skipped full corpus as passed;
- breaking checked annotation/model obligations, or claiming self-hostability without a current generated backend qualification;
- performance benefit too small to justify source size/proof/maintenance.

## 13. Concrete next engineering work item

**Deliverable:** one bounded performance baseline and a top-five hotspot ledger for the active 4.35 checker. It should contain:

- exact branch HEAD, exporter SHA, runner, resource profile and small corpus hashes;
- separate parser/import versus kernel-only timing and memory measurements;
- reference and cached mode verdict parity, with typed resource/declaration errors;
- hot function names and their current source owners, including `WhnfCore`, `DeltaStep` and `State`;
- one lowest-risk P1 algorithm-family optimization and its exact theorem/conformance impact;
- a verdict: implement P1, profile more, or preserve current implementation.

Do **not** start with a full Mathlib run, rewrite all source modules, merge active PR #89, or attempt expensive full compiler/kernel selfhost qualification. Keep GitHub and cloud CI canonical.

## 14. Primary source and verification map

**Official source and benchmark methodology**

- [Lean 4.35.0-rc4 release notes](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/) — explicit removal of compiler-backed Lean.reduceBool and Lean.reduceNat, not general Nat arithmetic.
- [Official C++ type checker](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.cpp), [type checker state](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.h).
- [Official inductive checking](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/inductive.cpp), [universe levels](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/level.cpp), [declarations](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/declaration.cpp).
- [Live Lean Kernel Arena](https://arena.lean-lang.org/), [Arena checker interface](https://github.com/leanprover/lean-kernel-arena), [Lean4export interchange](https://github.com/leanprover/lean4export).

**Independent implementation algorithms**

- [sokonanoda](https://github.com/intgrah/sokonanoda).
- [MathGraph evaluation](https://github.com/metalogiclabs/mathgraph-lean-kernel/blob/main/src/eval.rs), [MathGraph conversion](https://github.com/metalogiclabs/mathgraph-lean-kernel/blob/main/src/conv.rs), [MathGraph values](https://github.com/metalogiclabs/mathgraph-lean-kernel/blob/main/src/value.rs).
- [nanoclo closure/env nodes](https://github.com/sgraf812/nanoclo/blob/main/src/closure.rs).
- [nanobruijn OSNF](https://github.com/nomeata/nanobruijn/blob/main/README.md) and [representation theory](https://github.com/nomeata/nanobruijn/blob/main/Theory.lean).
- [lazylean README](https://github.com/corun1024/lazylean/blob/main/README.md), [NbE code](https://github.com/corun1024/lazylean/blob/main/src/nbe.cpp), [Krivine-style evaluator](https://github.com/corun1024/lazylean/blob/main/src/kam.cpp): do not confuse its 0.5.1 claims with Arena 0.3.0.
- [con-ron README](https://github.com/leanprover/con-ron/blob/master/README.md), [refinement methodology](https://github.com/leanprover/con-ron/blob/master/OVERVIEW.md).
- [con-leche](https://github.com/leanprover/con-leche) and [lean4lean](https://github.com/digama0/lean4lean).

**Existing canonical PSKernel evidence**

- [Active 4.35 kernel code](https://github.com/dwijayuda/pskernel/tree/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core).
- [Architecture](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/PSKERNEL_CORE_ARCHITECTURE.md).
- [Proof work state](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/AI_WORK_STATE.md).
- [Reference checker correctness roadmap](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/REFERENCE_CORRECTNESS_PLAN.md).
- [Proof-guided relative soundness plan](https://github.com/dwijayuda/pskernel/blob/psc0/pskernel-core-lean435-arena-v1/psc0/packages/pskernel-core/PROOF_GUIDED_FULL_SOUNDNESS_AND_LEAN435_COMPATIBILITY.md).

## 15. Final architecture ruling

**Adopt PSKernel-Fast as an optional optimized execution profile of the current PSKernel Core**, not a second checker. Preserve one canonical semantics and Lean 4.35.0-rc4 as an exact authority, protect the live proof-guided development, optimize the costs actually measured, and prove/refine every soundness-affecting positive fast path.

The engineering goal is **official Lean-compatible behavior + small inspectable semantic TCB + one portable self-hosted source + explicit relative proof assumptions + competitive measured speed and memory**.

**Research status only:** this document does not claim a completed fast kernel, current full Mathlib acceptance, an executed new benchmark, finished relative consistency, backend equivalence, or production provider promotion.
