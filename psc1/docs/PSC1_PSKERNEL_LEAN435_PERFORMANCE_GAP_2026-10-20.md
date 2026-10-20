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
