# PSC1 PSKernel-Core versus Lean 4.35.0: source and performance gap

**Research date:** 2026-10-20
**Repository:** dwijayuda/pskernel, PSC1 79-module portable kernel
**Research branch:** research/psc1-pskernel-lean435-performance-20261020
**Lean pin:** leanprover/lean4:v4.35.0, upstream commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc

## Actual upstream kernel differences

Compared the official Lean 4.34.0 and Lean 4.35.0 sources. The C++ kernel type_checker.cpp changed: Lean 4.35 removed Lean.reduceBool, Lean.reduceNat, and their old native compiler-evaluation hook from WHNF and lazy-delta DefEq. The accompanying Lean.trustCompiler axiom was removed (upstream #14953). Across these two release tags, the examined kernel expression representation, substitution, replacement, inductive admission, local context, and type-checker header files were byte-identical. Therefore the upgrade is not itself a new expression-layout or substitution optimization.

References:
- https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/type_checker.cpp
- https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/expr.h
- https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/instantiate.cpp
- https://github.com/leanprover/lean4/blob/v4.35.0/src/kernel/replace_fn.cpp
- https://lean-lang.org/doc/reference/latest/releases/v4.35.0/

## PSC1 migration and qualification

PSC1 now pins Lean 4.35.0 in psc1/lean-toolchain and kernel target identity. The obsolete native reduction callback has been disabled on the trusted WHNF and DefEq paths, with a native regression that fails if the retired evaluator is invoked. The host compiler replaced String.dropRight with the verified current equivalent String.dropEnd plus copy.

The **baseline** qualification is fully green: [GitHub Actions 39365650537](https://github.com/dwijayuda/pskernel/actions/runs/39365650537). The native kernel regression, portable 79-module profile, PSC1 checks of all 991 original Lean declarations, canonical generation/rechecking of 79 PS files and 991 declarations, TypeScript declaration generation, JS build and JS semantic smoke passed. This is not proof of a repeated compiler/kernel fixed point or full Lean Arena conformance.

## Measured difference in expression metadata

The official Lean Expr stores cached hash, loose-bound-variable range, free-variable flags, and other metadata. PSC1 Core/Expr.lean traverses the term to compute free-variable and loose-bvar results. PSC1 Runtime/Acceleration/Cache.lean recursively hashes expression trees, then looks up cache entries using an immutable 16-level binary trie with Nat division and modulo and structural key comparison.

The first qualified native hotpath benchmark was [GitHub Actions 39365631120](https://github.com/dwijayuda/pskernel/actions/runs/39365631120): 12,000 queries per operation on the same preallocated application-spine shapes. It uses a one-millisecond clock and fixed order.

| Native operation, 12,000 calls | Depth 32, PSC1 / Lean | Depth 128, PSC1 / Lean | Depth 512, PSC1 / Lean |
|---|---|---|---|
| Hash | 7 / 0 ms | 21 / 0 ms | 84 / 0 ms |
| Has free variable | 3 / 0 ms | 6 / 0 ms | 20 / 1 ms |
| Has loose bound variable | 4 / 0 ms | 7 / 1 ms | 33 / 0 ms |
| Structural equality | 5 / 0 ms | 9 / 0 ms | 50 / 1 ms |

Zero milliseconds means below timer resolution, NOT mathematically free. These are isolated metadata operations, not matched complete-kernel checker timings, and establish no universal Lean-versus-PSC1 speed ratio. The scaling strongly supports the repeated structural-traversal diagnosis.

## Other source-confirmed gaps

- PSC1 Checker/Knot.lean checks equality and successful DefEq cache, then Checker/DefEq/Quick.lean repeats those scans on its initial entry. A research optimization passes a flag to skip only already-performed checks, while retaining full checks for newly reduced operands. That change must pass separate source/JS/whole-kernel gates.
- PSC1 Core/LocalContext.lean uses linear list lookup, while Lean 4 LocalContext uses PersistentHashMap.
- PSC1 Checker/State.lean threads immutable records, cache tries, and Except results. Lean uses reusable native state and mutable lookup structures.
- PSC1 generated TypeScript uses BigInt for Nat and a generator-based stack-safe execution scheduler for general recursive functions. Existing specialized direct loops are retained. No percentage of total JS runtime has yet been attributed to this scheduler.
- Earlier C0 substitution helper speedups produced severe workload-specific generated-JS memory regressions, so PSC1 keeps the bounded, qualified production substitution. Do not re-enable without controlled evidence.

## Priority order

1. Matched Lean 4.35 native complete-checker A-B-B-A experiments and generated-JS benchmarks. Keep the original and candidate toolchain identical.
2. Eliminate redundant DefEq entry probes without changing successful/rejected outcomes, cache-scope policy, fuel, or universe rules.
3. Prototype validated expression metadata for hash/flags/loose-bvar range in an isolated internal representation. Every constructor and transformation must preserve metadata correctness; never treat metadata as unchecked authority.
4. Profile native and JS cache calls, bucket collisions, allocation and local-context lookup depth before a data-structure redesign.
5. Specialize direct JavaScript call paths where stack safety is provable, and preserve a trampoline where required.
6. Evaluate new Lean 4.35 lake check / comparator and bundled external kernels for optional independent cross-checks, not as a replacement for PSC1 correctness.

All source changes must preserve portable 79-module self-hostability and be verified through Lean, PSC1 .lean checking, generated .ps checking, JS/TS builds, full runtime smoke, and resource policy. Do not merge an unqualified optimization.


## Follow-up qualified results (20 October 2026)

### Lean 4.35 DefEq de-duplication

The scoped DefEq change skips the redundant initial equality and positive-cache checks only after Knot.lean has already performed them. Post-WHNF and lazy-delta terms receive the ordinary checks. The change preserves the existing cache eligibility, fuel, semantics and previously qualified substitution path.

- [Correctness and source-portability CI 39366453993](https://github.com/dwijayuda/pskernel/actions/runs/39366453993) **PASSED**, including the 79-module Lean → canonical PS → JS source closure.
- [Native whole-checker A-B-B-A 39367386431](https://github.com/dwijayuda/pskernel/actions/runs/39367386431) **PASSED**. Wide checked-library admission was 12/12 ms; varied checked applications 7/7 ms; cold zeta-WHNF depth 192 was 30.5/30 ms (baseline/candidate medians). This demonstrates parity, NOT a general native speedup.
- [Controlled generated-JS A-B-B-A 39366767269](https://github.com/dwijayuda/pskernel/actions/runs/39366767269) **PASSED**, under one identical Lean 4.35-based PSC1 compiler. Positive DefEq was 1299.5/1294.1 ms, inferred 16-argument application 277.4/252.5 ms, and beta WHNF 1299.2/1311.9 ms. Full-suite RSS baseline 281.3/265.9 MiB, candidate 275.5/273.6 MiB. These mixed results do not support a broad improvement, nor a severe memory regression.
- The older reporter incorrectly hardcoded the text "Lean 4.34" for this 4.35 run. The research-branch reporter now reads the actual lean-toolchain source file. The original raw measurements remain valid.

### Matched native official Lean 4.35 versus PSKernel-Core

[GitHub Actions 39368357466](https://github.com/dwijayuda/pskernel/actions/runs/39368357466) **PASSED**. Both kernels evaluated equivalent closed, preconstructed Sort and zeta/let expression shapes, and agreed on checked types, WHNF, and DefEq. A-B-B-A execution runs two batches per implementation, each with separately guarded verdicts.

| Operation | Depth; calls per phase | Lean official 1st/2nd ms | PSC1 native 1st/2nd ms |
|---|---:|---:|---:|
| Zeta WHNF | 32; 100 | 0/0 | 4/5 |
| Zeta WHNF | 96; 50 | 1/0 | 14/14 |
| Zeta WHNF | 192; 20 | 0/1 | 20/20 |
| Positive DefEq | 96; 50 | 1/1 | 2/3 |
| Positive DefEq | 192; 20 | 0/0 | 4/4 |
| Fully checked zeta type | 96; 50 | 3/4 | 17/16 |
| Fully checked zeta type | 192; 20 | 6/3 | 27/22 |

A zero-millisecond result means BELOW the timer resolution, never zero computational cost. The checked zeta types show a roughly 4–9x native gap on this particular fixture. WHNF also has a substantial gap but cannot be given a reliable ratio with this clock. This is NOT a generalized benchmark for Lean Arena, Mathlib or full libraries; the implementations use their own resource and memoization policies and only operand shapes and verdicts are matched.

### Generated-JavaScript expression hotpath profiling

[CI 39368080745](https://github.com/dwijayuda/pskernel/actions/runs/39368080745) **PASSED**, after fixing the probe to correctly apply both argument stages of the generated curried expression-equality function. Node 22, 120 calls per operation and depth:

| Operation | Depth 32 | Depth 128 | Depth 256 |
|---|---:|---:|---:|
| Recursive expression hash | 25.508 ms | 66.671 ms | 117.837 ms |
| Free-variable tree scan | 18.142 ms | 53.415 ms | 89.342 ms |
| Loose-bound-variable tree scan | 33.706 ms | 124.364 ms | 208.777 ms |
| Structural expression equality | 79.905 ms | 178.279 ms | 342.715 ms |

Generated JS size: 4,991,405 bytes. The test process had peak RSS 196,604 KiB and 19,309,872 bytes of V8 heap after forced garbage collection. Do not confuse peak process memory with permanent retained memory, or compare these JS numbers against native Lean as if only expression representation differed.

### Experimental metadata-carrying expression wrappers

The new test-only source psc1/test/PsKernelMetadataExperiment.lean computes and carries subtree hash, has-FVar and loose-bvar range alongside an original PsKernelExpr. It implements sample BVar, Sort, FVar, App, Lambda and Let smart constructors. Every sample is checked against the existing full recursive implementations BEFORE timing. No production kernel or portable source module is changed.

Both jobs at [CI 39369351773](https://github.com/dwijayuda/pskernel/actions/runs/39369351773) **PASSED**. The native job validated the metadata prototype on lambda, open/closed let, free-variable apps, and application spines to depth 512. The generated-JS job independently rebuilt and ran the existing 4.35 source kernel; it did NOT compile the new metadata wrapper into JavaScript or demonstrate metadata speedups in that backend.

| Native operation, 12,000 queries | Original, depth 32/128/512 | Precomputed field, depth 32/128/512 |
|---|---|---|
| Hash | 6/23/101 ms | 0/0/0 ms |
| Free-variable presence | 2/7/19 ms | 0/0/0 ms |
| Loose-bound-variable presence | 2/7/33 ms | 0/0/0 ms |

Zero milliseconds means below 1 ms granularity. The precomputed-field query time EXCLUDES metadata creation cost and memory overhead. The sample wrapper only retains metadata at its root; it is NOT a full sharing-aware kernel expression representation and does not establish a whole-checker speedup.

### Non-negotiable promotion conditions

1. Cache eligibility needs an exact or conservatively true may-contain-FVar flag. A false negative could leak context-dependent checking results.
2. Any loose-bvar range used for substitution pruning must never UNDERESTIMATE the real range, or incorrect capture-avoiding substitution could be skipped.
3. Hashes are indexing hints, NOT equality/proof certificates: collisions must still be resolved by correct equality checks.
4. Every expression constructor and update, binder traversal, substitution, level instantiation, recursor and projection must preserve the metadata invariant. Sample testing alone is not a formal proof.
5. Kernel fuel, scoped cache restoration, the 79-module portable source closure, and generated JavaScript correctness and memory gates must remain intact.

**Final correctness qualification:** [CI 39369192351](https://github.com/dwijayuda/pskernel/actions/runs/39369192351) PASSED both native and full PSC1 portability jobs after the research benchmark additions. [Metadata profiling CI 39369351773](https://github.com/dwijayuda/pskernel/actions/runs/39369351773) PASSED both native and generated-JS jobs. Since the earlier optimized semantic source at commit 2250558d5d5223f3de53cd27cf0b566c4872c253, later commits affect only research tests, benchmark workflows, report scripts, kernel-lakefile benchmark target registration and documentation; **production kernel source is unchanged**.

**Disposition:** the Lean 4.35 migration and DefEq first-entry cleanup have qualified native/portable checking; native-vs-official slowdown is measured on deep zeta cases; an isolated metadata prototype validates the architectural hypothesis. Production metadata, general speedups, formal metatheory and full Lean Arena remain unresolved research work.


## Concrete quadratic work in cold zeta-WHNF

The source-level hot path establishes a stronger complexity explanation for nested let terms, not merely "functional language overhead":

- In Checker/Reduction/WhnfCore.lean, for each let expression the core first invokes psKernelSemanticCacheEligible and psKernelExprMapGet (around lines 245–255). On a cold miss it instantiates the let body, recursively reduces the remaining nested term, and calls psKernelWhnfCoreFinish (around lines 258–279).
- psKernelWhnfCoreFinish again calls psKernelSemanticCacheEligible and then psKernelExprMapInsert for cacheable closed terms (lines 71–95).
- Runtime/Acceleration/CachePolicy.lean implements eligibility by recursively walking psKernelExprHasFVar over the full expression (Core/Expr.lean lines 739–771). Runtime/Acceleration/Cache.lean recomputes the recursive expression hash for indexed lookup/insertion and uses further structural comparison for collisions.
- A cold let chain of depth D makes this process operate on subtree sizes D, D−1, ..., 1. Just the full-subtree eligibility scans can therefore cost proportional to D(D+1)/2. Indexed hashes contribute similar traversal costs. This gives a plausible **quadratic cold-path repeated-work term** even when every individual substitution is correct and efficient.
- The measured native WHNF cost per call rose from roughly 0.28 ms at depth 96 (14 ms for 50 calls) to 1 ms at depth 192 (20 ms for 20 calls), consistent with this structural amplification. This ratio is NOT proof of exact quadratic runtime, since there are other costs and 1 ms timing resolution.

A safe acceleration must preserve correct cache-key equality, scope-sensitive eligibility, and resource/fuel outcomes. Simply removing the memo table may trade repeated hashing for repeated reductions and increase total work or rejection under fixed fuel. A metadata-aware cache prototype must separately measure one-shot versus genuinely reusable subtrees, allocation and checking outcomes; do not change the production cache policy based on this one synthetic benchmark.
