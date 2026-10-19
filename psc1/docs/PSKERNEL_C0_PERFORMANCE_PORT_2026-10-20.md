# PSC1 PSKernel-Core: qualified C0 beta-path performance port

**Date:** 2026-10-20 (Asia/Jakarta)
**Branch:** `fix/psc1-pskernel-core-cross-branch-20261020`
**Qualified source commit:** `893527ec9d082bddbe0c20db4b71e0eadefb0c26`
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
