# PSKernel-Fast G6 — Bounded Evaluator Performance Evidence

> **Status:** cloud-measured **toy beta/let evaluator only**, not a Lean kernel speed benchmark, proof checker, semantic completeness claim or model soundness theorem.
>
> **Date:** 2026-10-11, source `80506642c3f2b8cb778d99de4265a12efc3cc29a`.
>
> **Run:** [PSKernel-Fast G6 benchmark 38095648308](https://github.com/dwijayuda/pskernel/actions/runs/38095648308), completed successfully on GitHub-hosted `ubuntu-latest`. The exact CPU model was not logged.
>
> **Toolchain:** `leanprover/lean4:v4.35.0-rc4` at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`, native Lake executable.

## 1. The engineering question

Can the first closure-view design avoid the large intermediate term allocations of eager beta/let substitution on a controlled, identical input workload **when closure reification cost is counted too**?

Compared engines:

- `reference`: structural capture-avoiding de Bruijn substitution, followed by WHNF reduction.
- `closure`: lazy lexical closures and thunk-like environments, reduction to head, **then full bounded reification** back to the identical raw closed result.

These are both deliberately **untyped toy evaluator fragments**. They perform no Lean theorem checking, no real DefEq (proof irrelevance, eta, constant delta, recursors, quotients, etc.) and no kernel declaration admission.

## 2. Reproducible workload

Program: `psc0/packages/pskernel-fast/Bench.lean`.

- 128 distinct **closed raw expressions**, sharing a form of 64 alternating beta/let steps applied around indexed constant leaves.
- Input construction occurs before each timed evaluator loop, but process startup and runtime initialization remain inside the measured process time.
- 25,000 normalizations per process.
- Three independent process samples per mode; both modes ran on the same hosted CI workflow and same compiled toolchain.
- Each result was required to be a leaf constant with the expected general shape, and both modes produced the same deterministic checksum **1,610,740** in every sample.
- Time from GNU `/usr/bin/time` `%e`: elapsed wall seconds rounded to 0.01; memory from `%M`: maximum resident kilobytes.
- Execution order was sequential reference first, closure second; scheduling, CPU model and thermal conditions were not controlled or recorded.

These limitations preclude general statistical or cross-hardware claims.

## 3. Exact run results

| Sample | Reference elapsed (s) | Reference peak RSS (KB) | Closure elapsed (s) | Closure peak RSS (KB) |
| --- | ---: | ---: | ---: | ---: |
| 1 | 0.90 | 10,316 | 0.08 | 10,164 |
| 2 | 0.88 | 10,108 | 0.08 | 10,244 |
| 3 | 0.85 | 10,144 | 0.07 | 10,284 |
| **Median** | **0.88** | **10,144** | **0.08** | **10,244** |

**Arithmetic diagnostic:** median wall times indicate **~11x less elapsed time** for the closure-with-reification evaluator on this one synthetic closed beta/let workload. The median RSS difference is **100 KB higher** for closure in these samples, a negligible process-level difference compared with runner/runtime noise. No peak live-heap or allocation-volume measurements were recorded.

**Important:** ~11x is NOT an actual PSKernel or official Lean proof-checking speedup. It is a scoped microbenchmark result. Real DefEq, universe checks, proof irrelevance and admission will change the cost balance, and the result might not generalize beyond this test.

## 4. Earlier inconclusive run (preserved)

[Run 38095544825](https://github.com/dwijayuda/pskernel/actions/runs/38095544825) passed the 24-depth / 1,200-evaluation, 16-input workload, with identical checksum 10,200 but **all measured elapsed values rounded to 0.00 seconds**. No speed ratio was reported from that run. The workload was increased to produce a resolvable comparison, and the initial run remains in the historical log.

[Failed run 38095463586](https://github.com/dwijayuda/pskernel/actions/runs/38095463586) did not produce measurements because the benchmark mistakenly used nonexistent `IO.getArgs` on this pinned Lean version. Its CLI entry was changed to `main (cliArgs : List String)`. No evaluator rule was changed.

## 5. Interpretation and architectural choice

- **Provisionally prioritize compact DAG + lazy closures (V3 candidate A)** for further WHNF research; preserve substitution (candidate B) as an independent test reference.
- Do NOT replace a checked accepting kernel with this toy evaluator.
- Extend to the **same well-typed input corpus and real Lean 4.35 conversion rules**, including binder/let depth, universe substitutions, proof irrelevance, delta, recursor/quotient computation and checked stage/axiom policy.
- Separate parser/loader, evaluator, typed inference, DefEq, recursor admission and full end-to-end costs in the next benchmark.
- Sample order should be balanced/randomized and machine metadata recorded for future timing measurements.
- Formally justify every new accepting positive equality/cached result before qualifying a trusted runtime, and compare against pinned official Lean at the same semantic version.

## 6. Validation cross-reference

The broader [G7 closed-term run 38095713290](https://github.com/dwijayuda/pskernel/actions/runs/38095713290) passed **256 deterministic generated closed expressions** using both evaluators and exact intern/erasure agreement. This remains finite untyped testing, not a formal proof.

## 7. Reproduction

~~~sh
cd psc0/packages/pskernel-fast
lake build pskernel_fast_bench
/usr/bin/time -f 'elapsed_s=%e peak_rss_kb=%M' \
  .lake/build/bin/pskernel_fast_bench reference 64 25000
/usr/bin/time -f 'elapsed_s=%e peak_rss_kb=%M' \
  .lake/build/bin/pskernel_fast_bench closure 64 25000
~~~

For reproducible cloud controls and the exact six-sample evidence, inspect [the G6 GitHub workflow](https://github.com/dwijayuda/pskernel/blob/research/pskernel-fast-v3-greenfield-20261011/.github/workflows/pskernel-fast-benchmark.yml) and its [run logs](https://github.com/dwijayuda/pskernel/actions/runs/38095648308).
