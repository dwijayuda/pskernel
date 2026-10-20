# PSC1 PSKernel-Core: qualified C0 beta-path performance port

> **Current production status, 2026-10-20:** The C0 single- and multi-variable structural substitution workers described below remain *experimental differential references*, no longer active in production at [commit e411801](https://github.com/dwijayuda/pskernel/commit/e411801a72389467b79a07c732b8600e20674f2f). [Same-compiler ablation 39352328822](https://github.com/dwijayuda/pskernel/actions/runs/39352328822) linked them to severe operation-specific generated-JS memory regressions despite faster native helper microbenchmarks. Production uses the previously qualified bounded instantiation entry points. Beta-spine and lifting ports remain active. The scoped native, PSC1 canonical generated-PS/JS, and same-compiler JS memory checks **passed** at semantic commit e411801 in [run 39359421956](https://github.com/dwijayuda/pskernel/actions/runs/39359421956) and [controlled run 39359421889](https://github.com/dwijayuda/pskernel/actions/runs/39359421889); [native complete-operation A-B-B-A run 39360528448](https://github.com/dwijayuda/pskernel/actions/runs/39360528448) also passed with the same kernel source. See [whole-kernel performance evidence](PSC1_WHOLE_KERNEL_PERFORMANCE_EVIDENCE_2026-10-20.md) for measured regressions, remaining uncertainty, and integration-review boundaries.


**Date:** 2026-10-20 (Asia/Jakarta)
**Branch:** `fix/psc1-pskernel-core-cross-branch-20261020`
**First qualified beta-spine source commit:** `893527ec9d082bddbe0c20db4b71e0eadefb0c26`
**GitHub Actions:** [run 39327565414](https://github.com/dwijayuda/pskernel/actions/runs/39327565414) — both jobs succeeded
**Upstream research source:** `perf/pskernel-c0-v7-rust-20261012`, `41322875539de66acf9eb9b01ddf73df82a61bf2`
**Target toolchain:** PSC1 / Lean 4.34.0, TypeScript 7.0.2, Linux GitHub Actions

## Ported, on the trusted source path

1. `Core/Substitution/Beta.lean`: C0's linear lambda-spine consumption avoids repeated whole-expression node-counting and argument-count checks. Use `psKernelExprListDrop` rather than `List.drop` to stay within PSC1's portable runtime.
2. `Core/Substitution/Beta.lean`: a one-pass beta spine planner returns the reduced lambda body, reversed selected substitution arguments and remaining arguments. A single selected binder retains the existing `psKernelExprInstantiate1`; otherwise use the original simultaneous substitution operator. This is a source-level optimization, not an independent checker.
3. `Checker/Reduction/WhnfCore.lean`: apply the planner only after the checked source WHNF identifies a lambda head. Keep the same recursive WHNF call, context, state, fuel and failure propagation. The old reference algorithm remains in native regression/benchmark fixtures, not in production code.

The port deliberately does **not** adopt C0's experimental indexed DAG engine, source-hash interned handles, broad context caches, or unchecked reductions. Corrected free-variable cache eligibility, binder scope restoration, constructor checks, universe rules and resource outcomes remain in place. No changes to the accepted language profile or Lean pin.

## Correctness and self-hosting evidence

The [GitHub workflow](https://github.com/dwijayuda/pskernel/actions/runs/39327565414) at the exact source commit completed both native and PSC1 portability jobs successfully:

- Independent native kernel build: **166 jobs**.
- Focused native regressions: **22/22 passed**; these include cache isolation, universe equivalence, String API parity, original-vs-C0 beta results across identity, nondependent, multi-binder, short/excess applications, and old-vs-linear lambda consumption.
- Portable-source profile: **94 modules** across two source roots, including the **79-module kernel**.
- PSC1 check of the original kernel `.lean` closure: **984 declarations**.
- Canonical `.lean` to `.ps` output: **79 verified source files** with a canonical closure manifest.
- PSC1 check of the generated `.ps` closure: **984 declarations**.
- Generated JS/`.d.ts` creation, JavaScript syntax check, and runtime semantic smoke: **passed**.

This is *source self-hostability and executable generation qualification*, **not** a full compiler+kernel regenerated fixed point, full Lean Arena corpus, independent kernel soundness proof, backend semantic preservation proof or release/provider promotion.

## Same-run native microbenchmark

Source: `psc1/test/PsKernelCorePerformance.lean`; same compiled Linux runner and exact source term family with baseline and optimized results compared for parity. Wall clock uses `IO.monoMsNow`, and output checksums must agree.

| Fixture | Calls | Old reference | C0 portable planner | Improvement |
| --- | ---: | ---: | ---: | ---: |
| 24 lambda binders | 120,000 | 66 ms | 32 ms | 2.06x |
| 96 lambda binders | 120,000 | 243 ms | 101 ms | 2.41x |

Timings come from the native job log of [run 39327565414](https://github.com/dwijayuda/pskernel/actions/runs/39327565414). These are two short, order-fixed microbenchmarks **not** an end-to-end kernel/DefEq/inference gain, JVM or JavaScript benchmark, memory win, or proof of statistically generalizable speed. Use repeated order-balanced, same-machine whole-operation checks before wider adoption.

## Performance acceptance and follow-up boundaries

- Retain the conservative FVar cache guard and scoped cache restoration; do not accelerate by reintroducing context-dependent cache leakage.
- Benchmark end-to-end checked WHNF/DefEq/inference, ordinary/mutual/nested admission, malformed rejection paths, and memory on the same runners before any further promotion.
- Treat C0's indexed representation and memoized substitution as independent research until they have independent semantic, provenance, resource and PSC1 portable-source evidence.
- Re-run source, generated `.ps`, JavaScript, native, and differential regressions for any subsequent changes. Do not substitute an old fixed-point receipt for evidence at a new source SHA.


## Second qualified C0 optimization: one-pass single-variable instantiation

**Qualified source commit:** `a048c5d32431a85f21f5381b7525349d4a90aada`
**Workflow:** [GitHub Actions 39331733291](https://github.com/dwijayuda/pskernel/actions/runs/39331733291) — **both native-kernel and psc1-portability passed**.

### Specific change

`Core/Substitution/Instantiate.lean` adopts C0's structurally recursive `psKernelC0ExprInstantiateOneChanged` for `psKernelExprInstantiate1`. It skips the old full loose-bound-variable probe plus expression-node-count prepass on application-shaped/open operands. The existing `psKernelExprHasLooseBVar` check stays for binder-rooted `lam`, `forallE`, and `letE` terms so closed binder expressions are returned unchanged. The general multi-variable instantiation and historical fuel-driven worker remain unmodified and provide a differential oracle.

This is capture-avoiding de Bruijn substitution only. It does **not** change declaration acceptance, kernel axioms, fuel/recursion checking rules, the context-sensitive cache policy, or the default provider. The source is portable in PSC1 and compiled using the pinned Lean 4.34.0.

### Performance evidence

`test/PsKernelInstantiatePerformance.lean` compares the exact previous implementation against the new one in the same native CI process, with equivalent results and checksums required before reporting timing:

| Workload | Previous | One-pass C0 | Same-run speedup |
| --- | ---: | ---: | ---: |
| 25,000 open application substitutions, depth 12 | 15 ms | 9 ms | 1.67x |
| 25,000 open application substitutions, depth 32 | 39 ms | 25 ms | 1.56x |

These measurements are *specific microbenchmarks*. No evidence here establishes an overall WHNF, DefEq, inference, complete-library, JavaScript, memory, or Arena speedup. The earlier qualified beta-spine benchmarks remain a separate optimization and were re-run successfully.

### Correctness and self-hosting evidence

At the exact source SHA above:

- Native Lean build: **169/169 build jobs** passed.
- **34 focused regression cases** passed, including **12 new original-vs-C0 instantiate1 comparisons** spanning free/bound de Bruijn indices, capture avoidance, dependent binders, let, metadata and projections.
- PSC1 all-portable source profile passed across **94 modules**, including the **79 kernel modules**.
- PSC1 elaborated and checked the complete original `.lean` kernel: **986 declarations**.
- Canonical kernel `.ps` closure was generated with **all 79 source files** and validated manifest; PSC1 rechecked **986 declarations** from the generated closure.
- Generated JavaScript and declarations compiled using TypeScript **7.0.2**; runtime smoke passed, including checks for bound-variable substitution, index shifting, open application instantiation and closed application retention.

The complete [CI run](https://github.com/dwijayuda/pskernel/actions/runs/39331733291) is green. These are finite correctness and source-generation qualifications, **not** a full self-host fixed point, independent metatheory proof, or all-case backend semantic proof. Leave this optimization on the isolated fix branch until integration against the current PSC1 development head is reviewed.

### Next measured candidates

Investigate C0's source-substitution/lifting traversal once whole-operation native and JS costs are profiled, especially closed-application regressions and deep binder workloads. Avoid importing experimental indexed DAG interners, session-wide caches or reductions without independent context/fuel/resource evidence and complete portability checks. Always compare against the exact previous native and generated-JS kernel under the same fixture and runner before calling something a net speedup.


## Third qualified C0 optimization: direct multi-variable substitution

**Implementation:** `Core/Substitution/Instantiate.lean` — `psKernelC0ExprInstantiateAtChanged` traverses its expression structurally, avoiding the full node-count prepass before simultaneous capture-avoiding de Bruijn substitution. The original `psKernelExprInstantiateAtChangedWithFuel` remains as a differential reference. No change was made to the semantic cache policy, checker resource/fuel admission rules, axioms or Lean pin.

**Qualification:** [GitHub Actions run 39339554386](https://github.com/dwijayuda/pskernel/actions/runs/39339554386) — success on source commit `c9c70d127c8ad1b5bf4dd3405ef2261db2e2c00e`. Native differential tests compare both resulting expressions **and changed flags** for multiple binders, offsets, `let`, projections and metadata; the full 79-source closure passes PSC1 `.lean`, generated `.ps`, TypeScript 7.0.2, generated JS and the multi-substitution JS smoke test.

**Same-run original-vs-C0 native microbenchmarks** from [initial native run 39338352110](https://github.com/dwijayuda/pskernel/actions/runs/39338352110) (that complete run failed only due to a malformed JS *test fixture*, corrected in the successful run):

| Workload | Original | C0 direct | Speedup |
| --- | ---: | ---: | ---: |
| 25,000 open multi-substitutions, depth 12 | 22 ms | 17 ms | 1.29x |
| 25,000 open multi-substitutions, depth 32 | 62 ms | 50 ms | 1.24x |

This is a microbenchmark, not a complete-checker, JavaScript or memory benchmark.

## Fourth qualified C0 optimization: structural binder-aware lifting

**Implementation:** `Core/Substitution/Lift.lean` — the original bounded `psKernelExprLiftLooseBVarsChangedWithFuel` remains the reference. The optimized source worker `psKernelC0LiftNonzeroChanged` structurally recurses over immediate expression subterms, preserving binder-specific cutoffs, unchanged subtrees and all original de Bruijn semantics. The thin `psKernelC0LiftChanged` wrapper returns unchanged for zero amount. This split is important: PSC1 cannot resolve direct recursion under an outer zero-amount conditional; separating the worker resolves the portable frontend issue. Neither the kernel's admission fuel policy nor cache safety is changed.

**Qualification:** [GitHub Actions run 39343105786](https://github.com/dwijayuda/pskernel/actions/runs/39343105786) — success on implementation commit `d329a70fc07a9ac042ccfdac242f380d77878da1`.

- Native Lean 4.34.0 build: **175** jobs; focused native regressions: **61 passed** (including 13 new lift parity cases for zero shift, cutoffs, binders, `let`, projection, metadata, closed terms).
- PSC1 all-portable source profile: **94 modules**, containing the full 79-module kernel.
- PSC1 check of original `.lean` and canonical generated `.ps` closure: **991 declarations each**, all **79** kernel source files verified.
- Generated JS, `.d.ts`, syntax check, and Node runtime smoke: **passed**, including de Bruijn shifts, cutoff preservation and zero-shift identity.

**Same-run native lifting microbenchmark** on the qualified commit (25,000 operations each):

| Workload | Original | Direct structural lifting | Interpretation |
| --- | ---: | ---: | --- |
| Depth 12 | 18 ms | 19 ms | Small regression on this one run |
| Depth 32 | 44 ms | 36 ms | 1.22x improvement on this run |

Do not hide the depth-12 regression or claim a general speedup. The previous native run of the first lift shape (which PSC1 could not elaborate) showed 19 vs 16 ms at depth 12 and 47 vs 43 ms at depth 32, illustrating the sensitivity of these small timings. Do not compare between-run totals as if from the same runner. Before making lifting the permanent default in an integrated production branch, collect repeated order-balanced complete-operation and generated-JS benchmarks and check memory.

### Trust and self-hosting boundary after four scoped optimizations

All four optimizations are isolated to `fix/psc1-pskernel-core-cross-branch-20261020`, and all source-level PSC1, generated `.ps`, native and JavaScript smoke gates for the exact qualified lifting implementation passed. No merging into another PSC1 development head, full repeated compiler/kernel fixed-point proof, Arena 193/193 result, whole-Mathlib parity, independent metatheory soundness or complete backend preservation proof is claimed. The experimental C0 indexed DAG kernel, session-owned handles and unchecked reductions were **not** imported.

The next priority should be a same-run *whole checked operation* benchmark suite (WHNF, DefEq, checked app, ordinary/mutual/nested admission, malformed rejection), memory and generated-JS performance. A further microscopic substitution gain alone does not establish a production performance win.
