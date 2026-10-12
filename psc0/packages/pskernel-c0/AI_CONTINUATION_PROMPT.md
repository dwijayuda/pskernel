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



## Latest verified native Lean checkpoint — indexed loose range

**Last verified source commit:** `c8d63e109247fd28b9608cb045562e5699583870`; [native CI 38239387122](https://github.com/dwijayuda/pskernel/actions/runs/38239387122) passed complete C0 Lake build, negative/differential regression, native microbenchmarks and unchanged-original matched full checker. The prior direct recursion replacement for expression equality was slower and explicitly reverted to baseline in `bdec38c4`.

**New indexed-term invariant:** `PsKernelC0StoredNode.looseBVarRange` stores maximum *loose* index + 1 from exact canonical children, including binder-body decrement. `Core/IndexedReduction.lean` prunes lifting and memoized single-binder substitution for sub-DAGs where the range is no greater than the current cutoff. The old indexed reference worker remains a differential oracle. `C0ProofIrrelevanceRegression.lean` checks range against recursive syntax across offsets and exact lift/substitution values. Same-run isolated closed shared DAG reference 885 ms versus pruned memo 1 ms for 100 calls; **not** an accepted checker result. Complete C0 checker remained near parity with original on qualified fixtures; no memory improvement established.

**Next engineering priority:** unify cached term metadata and session-owned arena provenance with the *real* WHNF/DefEq/inference checker, without repeated recursive/indexed conversion. Audit exact environment/context/resource-sensitive reduction families (including iota/recursors/quotient/projection/native/universe levels) before enabling an accepting indexed path. Preserve the original kernel, Rust backend, soundness-sensitive negative tests and fixed Lean 4.34 semantics. Continue native builds and original-core matched full-checker benchmarks; do NOT run self-host/bootstrap/fixed-point or metatheory tests. All future performance claims must explicitly distinguish isolated indexed DAG benchmarks from full checker speed and memory.


## Latest continuation checkpoint — exact local-context count and private ablation

As of 2026-10-12, branch source commit [`e8952b95`](https://github.com/dwijayuda/pskernel/commit/e8952b95a279f5bf82aa7b2c664d17430308bbd7) passed [native Lean CI 38240821497](https://github.com/dwijayuda/pskernel/actions/runs/38240821497), all mandatory steps. Local-context additions now maintain exact cached `declCount` rather than rescanning the linked list on each index-promotion decision. Fresh-name `nextIndex` is independently advanced by inductive recursor analysis; the two continuation sites use a snapshot-preserving helper. Regression verifies an offset fresh-name counter does not trigger wrong promotion, without changing local typing or lookup. The full checker remained near parity with unchanged core: checked 48-argument applications 73 ms C0 vs 72 ms original; growing 160 checked declarations 41 vs 43 ms; deep-local results mixed. No claimed general speed or memory win.

Current branch also includes workflow-only [`e2fea7fe`](https://github.com/dwijayuda/pskernel/commit/e2fea7feac956c0197cb71edfed1770841f3c161), which only runs a **private copied C0** one-family historical list-length ablation when the commit message contains `[c0-local-count-ablation]`. Inspect [run 38241386784](https://github.com/dwijayuda/pskernel/actions/runs/38241386784) and record its measured outcome and all relevant CI gates before any further optimization claims. Normal CI runs remain unchanged. Do not edit original `pskernel-core`, Rust backend or PSC0; do not run self-host/bootstrap/fixed-point or metatheory tests. Remain focused on soundness-preserving native Lean WHNF/DefEq/inference/admission and session-indexed representation/provenance. **The major redesign is not complete.**


### Current, fully qualified result of the tagged source-family ablation

[CI 38241386784](https://github.com/dwijayuda/pskernel/actions/runs/38241386784) at `e2fea7fe` **completed successfully**: native C0 build, negative/differential regression, native microbenchmarks, unchanged-original full checking and an isolated private C0 length-scan restoration all passed. Native C0 cached-count source remains `e8952b95`; the workflow diagnostic changed no production source. Full checked 160-declaration chain C0 **37/38/38 ms** versus length-scan ablation **37/38/38 ms**. Depth-96/192/320/512 check paths were near parity, process-wide memory not improved; do not claim a material speedup for cached count. Source semantics and all user-deferred boundaries remain unchanged.

**Next work:** identify a meaningful *full checked-path* cost via same-run ablation; design provenance-safe persistent term ownership so WHNF, DefEq and inference can share canonical handles without repeated encode/decode, preserving reduction priority, fuel, local/environment scopes, native evaluator and declaration admission. Do not route an incomplete indexed WHNF fragment into acceptance or run self-host/bootstrap/fixed-point/metatheory tests. Continue on current HEAD; first resolve branch and latest CI, rather than assuming a previous checkpoint is still current. Performance architecture **still incomplete**.


## Latest continuation checkpoint — production checked spine win

As of 2026-10-12, working branch `perf/pskernel-c0-v7-rust-20261012` has source [`501cd77c`](https://github.com/dwijayuda/pskernel/commit/501cd77ce5d600115c7e82b3efa30b3a2e75657a) with **all-green** [native CI 38246930574](https://github.com/dwijayuda/pskernel/actions/runs/38246930574). The accepting native Lean `psKernelCheckWithFuel` routes only top-level application roots of 64+ arguments to a validated explicit-frame engine. A bounded bottom-up exact Pi-body loose-de-Bruijn summary avoids repeated substitution on syntactically closed Pi suffixes; all dependent, unusual or exhausted metadata cases use original substitution. Fuel, recursion-depth contexts, WHNF/DefEq, inference, eager reduction, checker-state propagation and resource errors are retained; differential tests include exact range oracle, low fuel, context bounds and negative typing. Original `pskernel-core` remains unchanged.

Measured complete public checking in one matched run: 12 typed 192-argument checked applications, three rounds C0 **9/7/7 ms**, original **33/34/34 ms**, about 4–5× on this engineered workload. The separately measured 60-call C0 recursive-vs-framed checked-operation pair was 158 ms versus 31 ms. Fully checked 48-argument variants still show slight regression (52/50/50 vs 48/48/48), and the checked declaration chains do not demonstrate broad improvement; process-wide memory reduction not established. The direct `ptrEq` attempt failed safe-kernel compilation and was reverted. **Do not mark project complete.**

Immediate priority: profile smaller checked DefEq/inference and admission, examine real representative Lean library extraction/checked module throughput and memory, then design safe session-owned indexed WHNF/DefEq across delta/iota/recursor/projection/quotient/primitives and exact universe/resource rules **without repeated indexed/recursive conversions**. Keep Rust/backend/compiler/other branches unmodified; do not run self-host/bootstrap/fixed-point/generated Rust/metatheory tests. Preserve negative findings. First refresh current HEAD and latest native CI on each continuation.


## Latest verified independent checkpoint — 12 October 2026

**HEAD source commit:** [0859097f](https://github.com/dwijayuda/pskernel/commit/0859097f6c1f8bdd6b869d477db829575bc2823c). **Native Linux workflow:** [38248015655](https://github.com/dwijayuda/pskernel/actions/runs/38248015655) completed **successfully**: Lean 4.34 native library, negative/differential soundness and exact low-fuel/resource checks, native full-operation benchmarks and independently staged original-core matched checks. Source changed only C0 native `Checker/Inference.lean` plus regression and matched-benchmark test files.

The accepting wide-application (>=64 root args) frame engine now retains only each argument, exact per-application remaining fuel and recursion depth; the checked operation shares the immutable base context including local/global environments, safety, level parameters, native evaluator and resource policy. Each frame rebuilds only its depth field. The original recursive type-inference worker remains authoritative, and the **independent regression oracle** now calls it directly (the public session route would otherwise self-compare on wide spines). Regression spans the 63/64/65 routing boundary, 192/320 arities, low fuel and exact errors, recursion-depth limits, and fresh names.

New matched entire checked-library admission fixture: safely admit one 192-arg function axiom, then 32 separate typed checked definitions invoking it, extending the immutable environment each time. C0 **32/32/32 ms** vs original **130/131/132 ms**. Standalone 192-arg checked calls 11/11/11 vs 48/47/48 ms. Varied 48-arg checked and normal depth-16/depth-48 library workloads remain near parity or slightly slower. This qualifies the **combined metadata/framed path on one wide library family**. It does not prove general checked-library or kernel superiority, and process-wide RSS does not establish a memory win; there is no source-family ablation isolating the compact frame payload effect.

**Next engineering phase:** design/implement nested checked application use across recursive expression contexts with exact fuel, root/nonroot caches and context provenance, then cover environment-dependent indexed WHNF/DefEq families (delta, iota/recursors, projections, quotient, native primitives, universe handling) without repeated recursive↔indexed bridging. Measure representative whole libraries, cold/warm performance, p95, memory/allocations and resource exhaustion. Keep source in native `.lean`, implement coherent subsystems before milestone tests, do not weaken typing or acceptance, do not run self-host/bootstrap/fixed-point/generated Rust or metatheory/consistency suites. Keep original `pskernel-core`, Rust backend, active compiler and other branches unchanged. **Major redesign NOT COMPLETE.**
