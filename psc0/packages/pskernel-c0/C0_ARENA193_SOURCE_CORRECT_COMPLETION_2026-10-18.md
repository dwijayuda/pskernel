# PSKernel-C0 — Source-correct plan for full Lean Kernel Arena 193/193

**Date:** 18 October 2026. **Repository:** `dwijayuda/pskernel`. **Lean pin:** 4.35.0 at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
**Research development:** `research/pskernel-c0-arena193-mvar-undef-20261018` from isolated C0 performance experiment PR #140 at `4cf7c24c08101d52cf3628dbe86a64ac70d8c79a`, NOT production.
**Trust policy:** unchanged checker fuel 4096, same allowed logical axioms, no skipped exported declaration, no source acceptance from a timeout, no kernel admission bypass, no version-mismatch masquerading as semantic acceptance.

## 1. Ground truth: 177 genuine comparisons, 16 unqualified

The [exact PR #140 193-case workflow 39090758187](https://github.com/dwijayuda/pskernel/actions/runs/39090758187) completed all four shards plus aggregate with `correct=177`, `c0_timeout=13`, `c0_resourceExhausted=2`, `official_timeout=1`. There were no **observed** false accepts or false rejects in 177 *actual both-sided* verdict comparisons. No soundness theorem follows from these finite tests.

The tests are [September 2026 Arena exports](https://github.com/leanprover/lean-kernel-arena/releases/tag/round-2026-09) originally pinned to Lean 4.29.1. `test/arena_lean435_compat.py` authenticates the archive, retains every byte of the declaration body, rewrites only the first header's provenance in an explicitly adapted copy, then separately queries pinned official Lean **4.35.0** and C0 on the identical adapted copy. **This is not native 4.35 re-export of all 193 original sources.** The default independently checking official/native timeout is **20 seconds per case** on GitHub. A timed out official reference cannot provide a positive/negative oracle result.

### Exact unresolved case ledger (no invented defects)

| Arena source | Latest 4.35-adapted result | Underlying characteristic / next investigation |
| --- | --- | --- |
| `perf/app-lam` | C0 host timeout | Alternating application/lambda and shared DAG; typed inference, preflight MVar and universe-param scans, context-safe inference sharing |
| `perf/beta-ladder` | C0 resource exhaustion | 2,000 beta-redex ladder; binder-substitution and resource recursion, requires source-correct closure evaluation |
| `perf/church-numerals` | C0 resource exhaustion | Church multiplication/definitional equality under binders; fuel consumption and shared reduction |
| `perf/discarded-argument-match` | C0 host timeout | Reduction through generated structurally recursive `brecOn`; irrelevant argument should be discarded only via real delta/iota/WHNF |
| `perf/discarded-argument` | C0 host timeout | Delta control order and ignored arguments; do not eagerly normalize irrelevant operands |
| `perf/folded-constant-first` | C0 host timeout | Order-sensitive unfolding and reusable reduced constant |
| `perf/folded-constant-last` | C0 host timeout | Same convertibility with reversed evaluation order |
| `perf/fueled-chain` | C0 host timeout | Exponential proof-irrelevance/type comparison under binder sharing and repeated guarded binds |
| `perf/grind-ring-5` | C0 host timeout | Large elaborator-produced proof/DefEq, rich ring certificates |
| `perf/let-ladder` | C0 host timeout | 2,000 dependent nested let bindings; repeated substitution vs shared closure environments |
| `perf/magma-list-deep-n21` | C0 host timeout | Deep nested finite-table `List` calculations in `by decide` proofs |
| `perf/magma-list-deep-n36` | Official 4.35 reference 20-second timeout | Reference verdict unqualified; official Lean's 4.29 Arena round itself took about 29 seconds in this example, so a strict 20-second oracle cannot determine the result; C0 also needs independent verdict |
| `perf/magma-list-pair-n21` | C0 host timeout | Finite model large pair/universal certificate |
| `perf/magma-list-pair-n7` | C0 host timeout | Smaller finite model, still repeated checked reduction |
| `perf/refute-cheap-last` | C0 host timeout | Cheap contradiction only encountered after an expensive comparison |
| `perf/shared-subterm` | C0 host timeout | Original archived source builds 1,000-layer perfect tree in DAG form; the previously **qualified n32 scaled** genuine 4.35 example is NOT equivalent to accepting the original full depth |

The names and categories above come from the latest actual per-shard [39090758187](https://github.com/dwijayuda/pskernel/actions/runs/39090758187) logs and `test/arena_435_known_gaps.json`, not extrapolations. The round's own descriptions (e.g. [app-lam](https://arena.lean-lang.org/round/2026-09/test/perf/app-lam/)) and immutable upstream [`tests/perf` source](https://github.com/leanprover/lean-kernel-arena/tree/5d7ca987618f1136aaa296057b50a2c10c4ce77a/tests/perf) explain the stressors.

## 2. Kernel architecture: what Lean 4 actually does

- **Expression representation:** pinned [Lean C++ `src/kernel/expr.cpp`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/expr.cpp) and [`expr.h`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/expr.h) store hash, bounded de Bruijn range, approximate depth and expression/level metavariable/free-variable flags on immutable shared nodes. These flags make many syntax checks O(1) without recursively expanding a DAG. The source implementation verifies/cross-checks important flags against structural functions. An immutable syntax address is never itself a typing judgment.
- **Inference/cache and local context:** pinned [`type_checker.h`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/type_checker.h) has distinct checked and infer-only caches, core/full WHNF caches, success/failure DefEq pairs, unfolding cache and scoped local contexts. Lean warns that positive DefEq cached pairs must NOT be treated as transitive equivalence closure: its sound but incomplete decision procedure can be evaluation-order sensitive.
- **WHNF and DefEq:** pinned [`type_checker.cpp`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/type_checker.cpp) evaluates head-spine beta/zeta/iota/projection, leverages independently cached reduction, unfolds lazily, compares binders under local contexts and handles proof irrelevance. It does not simply normalize all subterms before comparing.
- **ConLeche:** pinned [`ConLeche/Kernel/Expr.lean`](https://github.com/leanprover/con-leche/blob/b47ea19d6864a1fd09db6144528f91baa5c550dd/ConLeche/Kernel/Expr.lean) uses `@[computed_field] data` for immutable per-node hashes/bvar/FVar bounds; [verified-mode model theorem](https://github.com/leanprover/con-leche/blob/b47ea19d6864a1fd09db6144528f91baa5c550dd/ConLeche/MainTheorem.lean) applies to its own verified checker with explicit set-theoretic axioms, **not to arbitrary C0 native caches**.
- **Lean4Lean:** [source and documented divergences](https://github.com/digama0/lean4lean/blob/67f63b0c818920dfaed2ad07ccff187a6a8fe1e3/divergences.md) show deliberate universe/primitive/recursor discrepancies; copying such behavior without independent matching Lean-4.35 and soundness evidence can produce genuine false acceptance/rejection.
- **Recent alternative:** Courant & Leroy's [POPL 2026 lazy concurrent convertibility research](https://doi.org/10.1145/3776695) supplies a proof-based model for sharing evaluation of competing expensive problems. It motivates *lazy, source-refined evaluation* rather than racing unchecked answers or introducing a new kernel axiom.

## 3. Critical problems in C0 and correct solutions

### P0 — admissibility preflight on DAGs (this research branch)

`Admission/Declaration/Validation.lean` currently recursively rescans expressions through `psKernelExprHasMVar` and `psKernelFindUndefExprLevelParam`. Profiler [39026004526](https://github.com/dwijayuda/pskernel/actions/runs/39026004526) found 11/11 native samples of `app-lam` in MVar scanning. Source-proved candidate [PR #119](https://github.com/dwijayuda/pskernel/pull/119) replaced each scan by per-query proof-carrying DAG memo, preserving all-input Boolean and the exact *first offending universe name*, including the allowed-universe-parameter list. It also preserves strict MVar-before-FVar error precedence. Its standalone 90s A/B **still timed out** at PR #119's earlier stage, so it was never promoted.

This branch composes that *exact proven source implementation* onto the materially faster PR #140 parent and requalifies its existing independent Lean proofs and regressions. It can only become production if the actual same-runner full `app-lam` accepted verdict or demonstrable useful progress and all negatives are verified. A source-equality theorem is necessary but not a theorem about whole C0 type-system soundness.

### P1 — checked inference cache for shared lambdas

Source `Checker/Inference/Core.lean` checks `psKernelInferCacheEligible inferOnly expr` before looking up `state.checkedInfer`. The source policy intentionally refuses caching *checked* app/lambda/forall and restricts FVar-containing source. That avoids overhead and scope escape in ordinary checked programs, but structurally guarantees repetitive work for `app-lam` shared argument subtrees. **Do not blindly enable checked infer-cache:** results may depend on bound/free locals, level parameters, environment revision, inferred type and resource state.

Correct design: a checker-owned, immutable, fresh-context-sealed cache entry with a dependent certificate tying its exact source expression, type, environment identity, complete local context or proven context-free status and resource cost to the original checked inference. Scope entry/exit must prove no stale type transport and must preserve the same source resource-exhaustion contract. Alternatively, a closure/value machine can share the body and its local environment without creating a global checked inference cache.

### P2 — binder/let beta and resource accountability

The `beta-ladder` and `let-ladder` upstream [source](https://github.com/leanprover/lean-kernel-arena/tree/5d7ca987618f1136aaa296057b50a2c10c4ce77a/tests/perf) has 2,000 nested binds; repeated source-expression instantiation copies O(n) remaining body at each layer. A real closure evaluator should represent a term plus an immutable substitution/environment and make variable lookups on demand. Evaluation must maintain de Bruijn scoping, fresh variable names and let transparency.

**No fuel cheating:** prove a bounded simulation between source redex/recursor operations and closure-machine steps, and a separate theorem for the exact resource policy or specify a well-founded operational cost relation justified by Lean semantics. Changing source fuel 4096, classifying exhaustion as accepted, or merely skipping decrement is forbidden. Separate the genuinely finite proof's computational progress from current recursive call depth. The diagnostic `test/C0Arena435ResourceRootDiagnostics.py` identifies exact failure messages first.

### P3 — lazy delta/DefEq and proof irrelevance

The `folded-constant-*`, `discarded-argument*`, `refute-cheap-last`, `fueled-chain` and `church-numerals` cases demand early decisions that are semantically valid: beta/structural comparison, proof-irrelevance at proper types, source-correct staged WHNF before expensive delta and recursor unfolding, and memoized known equalities under the proper context. It must retain Lean's negative equivalence-set semantics and avoid a transitive closure of success pairs.

### P4 — large arithmetic/certificate workloads

`magma-list-*` and `grind-ring-5` spend runtime checking huge `decide` elaborated terms, `Fin`, `List`, `Nat`, `brecOn` and dependent recursor conversions. Optimize the **original checked reduction** through source-proved exact Nat and list reduction fast paths, shared constructor heads and cached values in a sealed environment. Never add an axiom for `decide`, trust exported proof hashes, or mark an old timeout as success.

### P5 — independent oracle and version-completeness

One official Lean 4.35 oracle case, `magma-list-deep-n36`, times out under the harness's 20s timeout (the original official 4.29 round reported ~29s on this family). A longer *explicitly separate diagnostic oracle* may produce the actual official verdict; it must not be counted as a pass under the unchanged 20-second suite. For a truthful 193/193 claim under 20s **both** official and C0 need decisions in that limit. For source-compatibility conformance independently declare and publish another comparable time budget (for BOTH checkers), while preserving the 20s performance scoreboard. Neither approach authorizes changing test bodies, skipping the oracle or expanding permitted axioms.

## 4. Mandatory acceptance protocol

1. Pin every target: Lean4 `eb6cafb7`, export archive SHA `98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d`, source 3.1.0, exact 193 identity/body checks. Preserve the separate original 4.29.1 labels and actual official 4.35 decisions.
2. **Same SHA, same source, same checker fuel 4096:** strict accepted/rejected verdict for each case; classify host timeout, source resource, parser error, official timeout and unsupported separately. The existing 20s harness is an objective PERFORMANCE gate.
3. Add Lean all-input proofs for pure/cached algorithms, constructor metadata, trust-scoped receipts and exact source errors. Do not use `sorry`, `admit`, `native_decide` to prove trust properties, fabricated axioms or unsafe pointer equality for acceptance.
4. Run original-vs-candidate genuine per-case A/B, complete adapted Arena, native adversarial negatives and independently accepted real Init/Array/Std/Mathlib subset. A green aggregate can still have unqualified outcomes — the new **strict 193 gate explicitly fails** unless all 193 have real matched verdicts.
5. For especially expensive cases, do bounded focused experiments *outside* the standard Arena scoreboard; distinguish a diagnostic with larger host horizon from matching standard performance.
6. Do not merge until exact final GitHub HEAD passes all relevant gates, including no new false accept/reject. Real source acceptance is distinct from full mathematical soundness and native compiler correctness.
7. Subsequent independent kernel model/metatheory and proof-carrying self-host portability are separate research programs, not assumed to be completed by 193 finite tests.

## 5. Work status and next critical path

**Implemented here:** isolated integration of PR #119's prior all-input source-certified MVar and first-undefined-universe scans, with original source predicates retained and prior Lean regression code; exact original PR #140 checks left unchanged. GitHub-only CI for (i) pinned `app-lam` full-checker A/B, (ii) full adapted Arena **strict 193** result, and (iii) diagnostic beta/Church resource roots and the official `magma-list-deep-n36` timeout. **No performance/correctness qualification for this new combined HEAD is claimed before terminal runs.**

Then implement (in prioritized order): source-certified checked inference locality/closedness facts, genuine closure machine and step correspondence for beta/let, then DefEq lazy-delta path, then large `Fin/List/Nat` reduction. This is the shortest correctness-preserving route to the real 193 goal, not a promise of immediate completion.

**Links:** [PSKernel-C0 active work state](AI_WORK_STATE.md), [older assurance audit](C0_INDEPENDENT_KERNEL_ASSURANCE_AUDIT_2026-10-17.md), [Arena 4.35 differential](../../../../.github/workflows/pskernel-c0-arena-lean435-compat.yml).
