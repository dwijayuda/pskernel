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


## Verified newer native checkpoint — 12 October 2026

**Working branch:** `perf/pskernel-c0-v7-rust-20261012`; [source `5c8a1e83`](https://github.com/dwijayuda/pskernel/commit/5c8a1e83e22debd4fd6c365ba9666e834e8c5d66), [all-green native CI 38252783408](https://github.com/dwijayuda/pskernel/actions/runs/38252783408). Complete pinned Lean 4.34 library, native negative/error/fuel/context/resource/differential tests, full-checker microbenchmarks and separately compiled unchanged-original source were all successful. No self-host/bootstrap/fixed-point/generated Rust/metatheory tests.

`Checker/Inference.lean` now routes accepted root application spines with 16+ arguments to **source-native structurally fuel-indexed Pi-metadata recursion**. No explicit frame list is needed; exact checked original WHNF, argument inference, eager DefEq, rec-depth policy and dependent substitution remain, and only a bounded exact range-zero unchanged Pi body can avoid no-op work. Below 16 and for other root shapes, the historical recursive core remains unchanged. The older frame runner is retained only as an independent comparison worker. Regression tests compare actual public checking to the separate historical core across 15/16/17, 31/32/33, 48,64,192 widths, low fuel, exact errors and fresh names; malformed heads/arguments and metadata oracle are also covered.

Qualified matched public checked applications (C0 vs original, ms per round, three rounds): 200×16 **18/17/17 vs 20/20/20**, 200×24 **24/25/25 vs 32/33/33**, 160×32 **25/25/25 vs 36/37/37**, 160 varied×48 **39/41/41 vs 65/67/74**. Sequential admission of 64 checked definitions with 24 arguments **13/12/12 vs 16/15/15**, 48 arguments **20/19/20 vs 31/31/31**. 32 definitions with 192 arguments **31/32/32 vs 123/124/124**. These are engineered fixtures, not full library superiority; process peak C0 844628kB vs original 843588kB gives no memory win.

**Next complete subsystem**: plan/refactor the fuel-indexed core to share checked Pi-body metadata through nested application inference inside binder and metadata terms, without duplicating acceptance paths or compromising exact local/environment/fuel provenance. Build representative checked-module/library workloads, recursor/inductive and dependency-heavy non-fast cases, measure memory and repeated runs. Only then attempt full accepting environment-dependent indexed WHNF/DefEq across Lean 4.34 delta/iota/recursor/projection/quotient/native/universe rules. Original kernel, PSC0 compiler, Rust backend and other branches must remain unchanged. **Redesign not complete.**


## Verified next-chat checkpoint — nested checked C0 native Lean

**Current validated source:** [7d2c6708](https://github.com/dwijayuda/pskernel/commit/7d2c6708982fa1c1629976d7d6272c5cc78cfe15). Native Linux [CI 38265144787](https://github.com/dwijayuda/pskernel/actions/runs/38265144787) **success** for Lean 4.34 package build, negative/differential suite, microbenchmarks and matched unchanged original checker. Previous source [10974c2d](https://github.com/dwijayuda/pskernel/commit/10974c2d0cc31c8a79ec5bd93de9e91e14f1ed12), native [CI 38264313583](https://github.com/dwijayuda/pskernel/actions/runs/38264313583), also all green.

`Checker/Inference/Core.lean` now owns both the original infer-only/checked syntax-directed rules and an optional checked-application callback through a structurally recursive `psKernelInferCoreWithFuelUsing`. Historical `psKernelInferCoreWithFuel` calls it with `none`, remaining independently callable and preserving original acceptance. `Checker/Inference.lean` installs the already-qualified Pi-metadata checked worker for checked nested applications of 16+ arguments inside lambda/forall/let/metadata/projection roots. The checked Pi worker additionally routes 16+-arity checked application arguments into itself with the exact remaining fuel, context and error order. All head/argument typing, DefEq, WHNF, universe and resource decisions remain authoritative; only syntactically closed Pi suffixes skip known no-op substitution. The experimental indexed DAG is still **non-accepting**.

New matched full-checker declaration evidence: 64 metadata-wrapped 48-argument definitions C0 15/14/16 ms vs original 23/22/26; 64 lambda-wrapped 48-arg defs 17/17/17 vs 24/24/26; 48 safe definitions whose outer 48-arg app contains one 24-arg app argument 51/51/50 vs original 63/62/62. All are one-run 3-round same-run fixtures, **not** complete real-library performance/memory evidence. Process-wide VmHWM still shows no memory improvement. Document the non-isolated incremental nested-argument branch; do not claim it alone caused the full C0-to-original speed gain.

**Next coherent phase:** complete checked recursive routing when a wide application appears inside nested *head* or more complex dependent contexts; qualify live declaration environments and recursor/quotient/native reductions; and design a session-owned accepted indexed term DAG with arena/environment/local/fuel provenance before promoting indexed WHNF/DefEq. First inspect live HEAD and current workflow. Work GitHub-first, commit/push valid native Lean changes with exact evidence, maintain negative cases and unmodified core/Rust/compiler branches; **no** self-host/bootstrap/fixed-point/generated Rust or metatheory/consistency tests. The larger redesign is **not complete**.


## Latest independent verified native checkpoint — 12 October 2026

Resolve current HEAD before changes. Last qualified source: [b5e0472b](https://github.com/dwijayuda/pskernel/commit/b5e0472b1ec4cd6f62229a239f30179f576317f7); [native CI 38267860486](https://github.com/dwijayuda/pskernel/actions/runs/38267860486) fully **green** (pinned Lean 4.34.0 C0 build, negative/differential/fuel, microbenchmarks and unchanged-original matched checker). The two-phase work [e8f96f92](https://github.com/dwijayuda/pskernel/commit/e8f96f92e1903e1df3c9997f3463d42c9c2e85dc), [20200e59](https://github.com/dwijayuda/pskernel/commit/20200e59c7c9064a14c9e13d77f5474554d45b4d) added a bounded exact Pi tail reanalysis candidate after dependent substitution, with a true dependent function/proposition argument and three-way independent acceptance/error/fuel tests; promotion `b5e0472b` only after measured paired C0 end-to-end benefits.

The accepted checked native `.lean` pipeline currently uses source-recursive Pi metadata across medium/wide root, nested binder/metadata and application-argument cases, with the **new resummarized** worker for root/nonroot wide checked applications. A genuine dependent binder may invalidate previous Pi suffix ranges, but after exact substitution it can rebuild an exact read-only summary when the new Pi syntax has >=12 remaining binders. All cases with short tails, dependent substitutions, dynamic exposure, resource exhaustion or failed analysis preserve original checking/DefEq/WHNF rules; no source syntax metadata is a proof or type-acceptance cache. Original `psKernelC0CheckAppRecursive` without reanalysis, original `psKernelInferCoreWithFuel` and frame route remain separately callable as oracles.

Same-run native whole-checker: 80 dependent-tail64 checked calls C0 **30/31/32 ms**, unchanged original **52/52/51 ms**; 48 safely admitted dependent-tail64 definitions C0 **23/23/23**, original **37/37/36**. Paired 30 dependent-tail192 *complete* checked operations old C0 **114 ms**, rebuilt C0 **27 ms** on one runner. Ordinary/short/deep/inductive tests near parity; process peak provides no memory claim.

**Next priority:** Move beyond source syntax summary into acceptance-correct, session-owned indexed WHNF/DefEq/inference/admission with exact Lean 4.34 environment/context/provenance/fuel and native/recursor/quotient/projection/level semantics, avoiding repeated encoding/decoding. Design and qualify this subsystem as a coherent architectural phase, not a test-by-test patch. Measure representative full-library source checking, per-operation memory/allocations, p95 and repeated independent runner samples. Do not run deferred selfhost/bootstrap/fixed-point/generated-Rust/metatheory suites; keep original `pskernel-core`, Rust backend, PSC0 compiler and other branches untouched. **Major redesign is not complete.**


## Latest verified native DefEq architecture checkpoint — October 12, 2026

**Working branch:** `perf/pskernel-c0-v7-rust-20261012`. Qualified source commits [3b082900](https://github.com/dwijayuda/pskernel/commit/3b082900184d47109895c4e4e78eae1f6fce8ce8), [b6205d34](https://github.com/dwijayuda/pskernel/commit/b6205d34b6d4b3f44477d0bae725a1a424db1296) and [4007d03c](https://github.com/dwijayuda/pskernel/commit/4007d03ce4a63e9ea10d51c9052fc95a348beb72). [Latest required native CI 38270573104](https://github.com/dwijayuda/pskernel/actions/runs/38270573104) passed all Lean 4.34 C0 build, negative/exact-range/dependent-domain regression, native benchmark and unchanged-original matched checker. No other packages or branches changed and no bootstrap/selfhost/metatheory tests.

**Implementation:** The two source `Checker/DefEq/BinderSpines.lean` workers now retain newest-first de Bruijn substitutions (constant-time `List.cons`) and instantiate directly, instead of repeatedly appending and reversing growing lists. `Core/Expr.lean` computes an optional exact loose-binder-range list in one bottom-up traversal for sufficiently deep matching lambda or Pi spines; each recursion uses the saved range to decide local opening, or falls back to the exact original scan if the analysis is absent/exhausted. Explicitly dependent Pi domains referencing an outer binder have been qualified against the unchanged original checker. Fuel, local contexts, name freshness, DefEq callbacks and rejection decisions are not weakened.

**Measured complete matched DefEq:** at depth64, 12 calls C0 Pi 4/3/3 ms vs original 22/22/22; at depth128, C0 5/6/6 vs original 82/81/81; at depth256, six calls C0 6/6/5 vs original 158/156/156. Lambda depths show comparable results. Ordinary library/inductive remains near parity; no memory reduction proven. These are artificial deep binder fixtures rather than representative entire packages.

**Next architecture:** independent environment-dependent indexed WHNF/DefEq/inference/admission with session-owned DAG provenance, exact Lean 4.34 reduction ordering, fuel and native/quotient/recursor/projector semantics; then realistic full-library throughput, allocations, p50/p95 across independent runs. The indexed session wrapper is currently source retention around the recursive accepting checker, not a complete trusted indexed kernel. Do not preserve obsolete implementation merely for compatibility, but preserve intended public checker semantics and negative conformance. **The larger redesign is not complete.**
