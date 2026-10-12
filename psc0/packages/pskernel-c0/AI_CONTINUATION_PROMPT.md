# New-chat prompt — continue PSKernel-C0 native Lean performance redesign

Continue my own public open-source compiler/kernel project, **PSKernel-C0**, autonomously.

**Repository:** https://github.com/dwijayuda/pskernel
**Working branch:** `perf/pskernel-c0-v7-rust-20261012`
**Work directory:** `psc0/packages/pskernel-c0/`
**Primary code:** `src/Ps/KernelCore/**/*.lean`
**Pinned toolchain:** Lean 4.34.0 in `psc0/packages/pskernel-c0/lean-toolchain`

## Read before changing source

1. [AI_WORK_STATE.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/AI_WORK_STATE.md) — current handoff and exact benchmark/CI qualifications.
2. [C0_WORK_STATE.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/C0_WORK_STATE.md) — chronological implementation details.
3. [C0_BENCHMARKS.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/C0_BENCHMARKS.md) — measured costs and rejected optimizations.
4. [C0_LEAN_ARCHITECTURE.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/C0_LEAN_ARCHITECTURE.md), [PERFORMANCE_REDESIGN.md](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/psc0/packages/pskernel-c0/PERFORMANCE_REDESIGN.md).
5. [.github/workflows/pskernel-c0-lean.yml](https://github.com/dwijayuda/pskernel/blob/perf/pskernel-c0-v7-rust-20261012/.github/workflows/pskernel-c0-lean.yml), `test/C0CheckerComparison.lean`, `test/C0Ablation.py`, `test/C0ProofIrrelevanceRegression.lean`, and `test/C0PerfMicrobench.lean`.

Resolve **current branch HEAD and all latest GitHub Actions results** before editing. Do not assume the checkpoint here is still HEAD. As of this handoff, source commit `688315d51870dd34a2b602771061136a136f2eda` fixed a Python escaped-newline delimiter in the opt-in local-index ablation. CI [38230646350](https://github.com/dwijayuda/pskernel/actions/runs/38230646350) was running when this handoff was prepared. Last fully green prior native workflow: [38225028395](https://github.com/dwijayuda/pskernel/actions/runs/38225028395).

## Nonnegotiable priorities

- **Major architectural redesign and maximum realistic performance in actual native `.lean` PSKernel-C0 checker**, not the separate experimental Rust crate.
- Do **not** run self-hosting, bootstrapping, fixed-point, generated Rust self-host, or metatheory/consistency proof tests. These are explicitly deferred.
- Preserve kernel semantic acceptance, exact Lean reduction order, soundness-sensitive negative conformance, resources/fuel classification, environment/context cache scope, and declaration admission.
- Keep `psc0/packages/pskernel-core`, `psc0/packages/backend-rust`, active PSC0 compiler, and other branches **unchanged**. Do not force push/delete history.
- Work GitHub-first/cloud-only, **do not use Desktop Commander**. Commit/push meaningful incremental changes.
- Inspect architecture and subsystem invariants before edits; solve general causes rather than patching individual tests. Benchmark real full checker operations, not only microbench helpers.

## Verified performance state

Native Lean C0 has persistent radix indexes, local-context shadowing-safe lookup, an auxiliary canonical indexed term DAG, exact encode/decode, memoized indexed beta substitution, and a fragmentary indexed WHNF. The **accepting** checker still uses recursive `PsKernelExpr` for full WHNF, DefEq, inference and admission. Improvements already implemented in accepting source include demand-driven WHNF head probing, guarded quick DefEq, Unicode hashing, hybrid substitution, direct lifting, and cheaper infer-only application spines.

Controlled full-checker comparisons have ruled out several overclaims. The opt-in indexed session wrapper was slower and is not production default; a no-list direct projection selector was slower and its accepting integration was reverted. A measured hybrid substitution path eliminated a previous fully checked application regression while preserving large infer-only gains. Latest matched run [38225028395](https://github.com/dwijayuda/pskernel/actions/runs/38225028395) showed:
- 200 infer-only 48-argument applications: C0 19–20 ms, unchanged original 82–83 ms.
- 80 fully checked 48-argument applications: C0 39–40 ms, original 39 ms.
- Varied 160 infer-only applications: C0 16 ms, original 66 ms.
- Varied 160 checked applications: both ~82–83 ms.
- Replacing just the C0 environment index with original code changed none of these outcomes materially.

These are matched native benchmark fixtures, **not** evidence that complete real-world Lean kernel checking is faster overall. Full Init/Std/Mathlib or representative library throughput, memory and realistic resource behavior remain unqualified.

## Immediate work

1. Check [local-index-disabled diagnostic CI 38230646350](https://github.com/dwijayuda/pskernel/actions/runs/38230646350) and investigate its result. The preceding failed [38225068179](https://github.com/dwijayuda/pskernel/actions/runs/38225068179) was a Python ablation delimiter bug, not failure of Lean conformance.
2. Use controlled source-family ablations to locate meaningful costs in *full checked inference, DefEq, large local contexts, recursor validation, and declaration admission*. Distinguish binder-index construction from lookup savings and memory overhead.
3. Design and implement systemic performance changes **in .lean** using correct ownership, shared representations, exact checked behavior and context-safe cache keys. The opt-in indexed term store is staging, not currently a qualified accepting engine.
4. Run only native Lean `lake build PsKernelC0`, negative/differential checker suite, native benchmark suite and matched unchanged original-core checking. Update benchmark evidence and preserve negative/failed findings.
5. Push all valid improvements to the existing branch and update `AI_WORK_STATE.md`, `C0_BENCHMARKS.md`, and this prompt. Keep going without routine permission requests.

**Do not declare redesign complete** until full checked-path performance across representative workloads improves measurably without semantic regressions. If the work cannot finish in this chat, leave an exact, independently usable checkpoint.
