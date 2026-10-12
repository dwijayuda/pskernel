# PSKernel-C0 — performance architecture work state

## Branch and isolation

- Source: `psc0/pscv0-v7-native-lean-v1` at `a8fbc17f1ad2d24efbde14a7cbe993a4400d4c01`.
- Development: `perf/pskernel-c0-v7-rust-20261012`.
- Original `psc0/packages/pskernel-core` and working PSC0 Rust backend are not changed.
- C0 Lean source remains in `src/`. The independent Rust experiment lives in `experimental/arena-engine/` and does not issue kernel acceptance verdicts.

## Implemented architecture

- Expression/universe/name hash-consing and compact 32-bit arena-local term references.
- Exact hierarchical names (`anonymous`, string, arbitrary-size numeric components) rather than ambiguous dotted strings.
- Cached expression-tree depth metadata for O(1) shallow/deep algorithm dispatch.
- Iterative, DAG-memoized de Bruijn substitution for deep inputs, with recursive reference implementation used for bounded shallow terms and differential tests.
- Iterative application-spine beta/zeta/metadata WHNF for a restricted context-free fragment.
- WHNF cache storing both results and exact node-visit costs, preserving fuel exhaustion when a cached result would require more work.
- Positive-only `Equal/Unknown` conversion precheck, not a full definitional-equality checker.
- Dedicated GitHub Actions unit tests, Clippy, release build and microbenchmarks.

## Actual evidence (October 12, 2026 Jakarta time)

[GitHub Actions 38180969202](https://github.com/dwijayuda/pskernel/actions/runs/38180969202) at `cf0ef867c008b0920444f70369a988552f937549`:
- 21 unit tests passed; Clippy, release build and microbenchmark smoke passed.
- Application spine depth 1,024, 1,000 repetitions: 2.169 ms total.
- WHNF on the *same* 1,024-application stuck term, 1,000 repetitions: uncached 32.905 ms; repeated cached 0.014668 ms.
- 128-node substitution, 300 repetitions: recursive 4.824 ms, hybrid 4.623 ms.
- Rust CI runner uses rustc 1.99.0; numbers are single-run microbenchmarks with shared runner variability, not reproducible production throughput claims.
- Prior run [38180720840](https://github.com/dwijayuda/pskernel/actions/runs/38180720840) showed the fully iterative substitution was *slower* than recursive on a shallow case (6.649 vs 4.861 ms); hybrid dispatch exists because of this evidence.

## Serious remaining limitations

The Rust engine is **NOT** a complete Lean kernel. It does not implement full Lean-compatible universe comparison, delta/iota/native/quotient/recursor reductions, complete WHNF/DefEq, inference, or declaration admission. No lossless Lean-AST bridge or Arena differential qualification exists. Its 32-bit handles are only safe within their owning arena, and the source-facing API must enforce that boundary before integration. The precise semantic equivalence of the fragment has tests, not a whole-language proof. No baseline comparison to the current original PSKernel-Core on real workloads has been performed.

## Next milestone order

1. Implement an explicit, lossless or fail-closed Lean AST/level/name bridge with hierarchical names, arbitrary-size naturals, validated arena provenance and round-trip tests.
2. Build a real checker-facing API with immutable declaration environments, context-specific caches, and safe resource accounting.
3. Implement complete native kernel WHNF and conversion family by family, each with positive/negative differential tests and real library exports.
4. Implement inference and admission, then qualify end-to-end with Lean 4.35 and current PSKernel-Core.
5. Compare cold/warm time, allocated bytes, peak memory and throughput on identical hardware before deciding whether to switch PSC0 consumers.

The metatheory and consistency-proof program is deferred. False acceptance is not an acceptable performance optimization.

## Lean-owned performance architecture and proof-risk checkpoint (2026-10-12)

- Lean C0 runtime cache indexes were converted from duplicated 16-level binary tries to a shared 4-level radix-16 trie. Collisions continue to be checked structurally.
- Removed a redundant loose-variable prepass before instantiation; WHNF lambda counting no longer walks an entire expression tree to calculate a lambda-spine bound.
- Replaced old full-node-count + repeated argument-list-length lambda consumption with linear, argument-driven consumption in `src/Ps/KernelCore/Core/Substitution/Beta.lean`.
- Fixed `Core/IndexedExpr.lean` native Lean accessor and trie name collision; the dedicated standalone C0 Lake build now compiles all 80 Lean modules, with 82 native Lake jobs passing.
- Audited the proof branch and later model work in `C0_PROOF_FINDINGS_AUDIT.md`. Confirmed the legacy formal judgment permits arbitrary equality, but the runtime proof-irrelevance branch retains actual type inference for both terms and type comparison. This is a specification defect, **not** a demonstrated C0 executable false acceptance.
- [Native CI 38183611788](https://github.com/dwijayuda/pskernel/actions/runs/38183611788) at `aeae35159c694b8e196c9149b4f72845785e2797` passed 82 jobs and targeted negative equality/unbound variable/beta differential tests. **No self-host tests were run.**
- Remaining unverified proof-guided risks: annotation coherence, binder-local semantic cache scope, and additional checked lambda codomain evidence. Do not claim they are fixed or proven harmless. The new radix-index and beta changes still lack same-run comparison benchmarks against original PSKernel-Core.

## Native Lean architecture redesign — 2026-10-12

Primary optimization work has moved into the **real C0 `.lean` checker**. No self-hosting tests are requested or run here.

- `Core/IndexedExpr.lean`: share the four-level radix-16 persistent fingerprint index already used by the kernel caches; retain exact collision comparisons and cached child fingerprints.
- `Runtime/Acceleration/EnvironmentIndex.lean`: use the same persistent radix trie for new global declaration indexes, preserving historical binary lookup for old values; use native Unicode codepoint folding for name hashing.
- `Core/LocalContext.lean`: add a list-first/indexed-after-eight local-context representation. Preserve shadowing and old persistent snapshots. Explicit continuation constructors in inductive admission now preserve the matching index.
- `Core/Substitution/Instantiate.lean`: dedicated single-variable beta/zeta traversal without repeated list get/length on BVars; preserve generic simultaneous substitution.
- `Core/Substitution/Lift.lean`: direct structural lift without a whole-term node-count prepass, retaining the fuel-based reference for native differential checks.
- `Core/Expr.lean`: head-first expression comparison with the proven reference comparator on matching recursive children; keep both legacy oracles for differential testing.
- `Runtime/Acceleration/Cache.lean`: native Unicode `String.foldl` hashing instead of the full UTF-8 length+fuel prepass, retaining the previous worker as oracle.

The `test/C0ProofIrrelevanceRegression.lean` native suite now checks index interning, declaration collisions/replacements, local-variable shadowing, single substitution, lift, exact and kernel-semantic equality, Unicode fingerprints, and selected negative kernel decisions. The Lean workflow also measures these paths using `test/C0PerfMicrobench.lean`. These are **native Lean checks**, not self-hosting checks.

### Verified prior checkpoint

- [Native CI 38185426527](https://github.com/dwijayuda/pskernel/actions/runs/38185426527): success, with 30,000 varied-input iterations on a 512-application test term.
- Direct lifting measured 7,717 ms vs 10,558 ms for the old fuel-based path (single hosted runner); specialized instantiate1 measured 11,244 ms vs 19,841 ms generic. Both are workload-specific.
- The first paired equality measured 2,646 ms versus 2,458 ms for the old comparator and was replaced by a **hybrid paired-head/legacy-recursive design**, whose final benchmark is a separate pending observation.
- These measurements are not full Init/Std/Mathlib proof-checking benchmarks and are not a complete kernel performance certification.

### Open architectural work

The checker still uses recursive `PsKernelExpr` values at the public acceptance boundary; the indexed term store is an auxiliary representation, not a universal replacement. Full integration requires a lossless representation bridge, end-to-end benchmarks, environment/context provenance and resource-limit review, and compatibility qualification. Metatheory is deferred; soundness-sensitive negative tests remain in place.

- [Native CI 38185618064](https://github.com/dwijayuda/pskernel/actions/runs/38185618064) additionally passed native compilation and the indexed-local shadowing checks; 20,000 deep-local lookups measured **2,048 ms linear / 66 ms indexed** for 512 declarations. Narrow microbenchmark only, not full-checker throughput.

### Verified latest full source checkpoint

[Native CI 38185687752](https://github.com/dwijayuda/pskernel/actions/runs/38185687752) at `699ec13a3e3ec785d5e94b85211a29da06a8b84e` **passed** compilation of the full `PsKernelC0` Lean library, negative checker regression, native differential tests and performance microbenchmarks. No self-hosting tests. Varied-input results: exact paired-head semantic equality near parity (2,078 vs 2,055 ms); direct lift 8,948 to 6,640 ms; single substitution 16,694 to 9,358 ms; 512-local context lookup 1,691 to 54 ms. These are one-run subsystem measurements, not whole-kernel throughput or memory qualification.


## Native Lean indexed execution and demand-driven WHNF checkpoint (2026-10-12)

Implementation within `src/Ps/KernelCore/**.lean`, **not** Rust-only:
- `Core/IndexedExpr.lean` now provides an exact recursive-expression ↔ canonical term-ID bridge, including binder names/info, metadata, universe arguments, literals and let flags. Invalid IDs are rejected during decode.
- `Core/IndexedReduction.lean` adds full-binder-depth indexed lifting and beta substitution. The optimized worker memoizes by (term ID, binder depth) in a collision-checked persistent radix trie. The prior indexed recursive worker remains a differential oracle.
- `Checker/Reduction/IndexedWhnf.lean` runs context-free beta/zeta/metadata head reduction and application-spine assembly directly on indexed handles. **Not** full Lean WHNF: delta, recursors, quotient, projections, native primitives, environment and kernel admission are not included.
- `Checker/Reduction/WhnfCore.lean` routes the *accepting* recursive-expression WHNF through demand-driven application-head inspection, avoiding argument-list construction for stuck application heads. This is a direct Lean checker optimization.
- `Core/Substitution/Beta.lean` now dispatches one-argument beta-spines to the specialized source-owned instantiate1. The multi-argument path remains unchanged; regression is required before performance claims.

Evidence:
- [Native CI 38189942349](https://github.com/dwijayuda/pskernel/actions/runs/38189942349) passed complete library build, differential regressions and benchmarks.
- [Native CI 38189961428](https://github.com/dwijayuda/pskernel/actions/runs/38189961428) passed the indexed-WHNF test and complete native workflow.
- On a single CI runner, 30,000 eager spine decodings required 3,152 ms versus 368 ms for head-only probing (8.6×). This measures the head probe, **not** complete WHNF.
- A depth-11 shared DAG rewritten 70 times took 903 ms with recursive indexed substitution and 11 ms with memoized indexed substitution (~82×). This is an engineered shared-DAG stress case, **not** an end-to-end kernel throughput result.
- No self-hosting tests were executed. Full checked inference/DefEq and production indexed acceptance remain future integration steps. Metatheory/consistency proof work remains deferred.

Next: benchmark complete WHNF and definitional-equality workloads using a persistent indexed store, establish provenance-safe scopes for environment-sensitive caches, and integrate the indexed representation into the accepting core only when native differential and resource-policy gates pass.


## Indexed WHNF unchanged-spine architecture checkpoint (2026-10-12)

- `src/Ps/KernelCore/Checker/Reduction/IndexedWhnf.lean` now tracks whether a head traversal performed metadata erasure, beta or zeta reduction. When no reduction occurs, the indexed engine returns the original canonical handle directly instead of re-interning every application on the spine.
- The previous public `psKernelC0IndexedWhnfWithFuel` signature is preserved. The internal worker carries the initial handle and a change flag; externally supplied partial-spine arguments force reconstruction rather than a false identity shortcut.
- `test/C0ProofIrrelevanceRegression.lean` checks unchanged stuck-spine handle identity and store size as well as metadata-head reduction, which must not reuse the original handle.
- `test/C0PerfMicrobench.lean` now separately times eliminated indexed-spine reassembly and unchanged-handle WHNF, and adds a cold end-to-end native checker WHNF sample with a fresh state on each call.
- Native tests and benchmarks are intentionally separate from self-hosting. No self-hosting test was run or requested.
- The indexed WHNF engine is still an experimental context-free subset; full checked delta, recursive and native reductions, definitional equality, type inference and admission remain in the original Lean checker. These changes do not claim that indexed WHNF itself is a complete proof-checking engine.

The first [native Lean workflow 38191236078](https://github.com/dwijayuda/pskernel/actions/runs/38191236078) at `8d52cd385e40654fb25f56d9113bcab69ffd7515` passed the library build, native negative checks and existing microbenchmarks. The newer benchmark observations must be read from their own workflow run before claiming speedups.


## Accepting DefEq guard sharing checkpoint (2026-10-12)

- `Checker/DefEq/Quick.lean` now exposes a shape-only `psKernelDefEqQuickAfterCommon` entry for callers that have already checked exact structural equality and the successful conversion-pair cache. The original `psKernelDefEqQuick` API still performs both guards for other callers.
- `Checker/Knot.lean` directly uses the guarded entry after its existing checks. This removes one redundant full syntax-equality traversal and one duplicate successful-pair cache lookup on every missed top-level quick comparison without changing the reduction/conversion decision ordering.
- `test/C0ProofIrrelevanceRegression.lean` differentially checks the general and guarded paths on mismatching sorts, bound variables and applications, alongside all earlier native negative rules.
- `test/C0PerfMicrobench.lean` includes deep-sort comparison timing to isolate the removed repeated guard work and cold session DefEq/WHNF baselines.
- [CI 38191752791](https://github.com/dwijayuda/pskernel/actions/runs/38191752791) at `c02a60a5906324ce80c2ad895ae30e82ae484f93` passed the native Lean build, regressions and existing performance suite. No self-host tests were run.
- This is a direct production checker-path optimization in Lean, unlike the separately gated indexed-WHNF engine. End-to-end multi-library performance remains unqualified.


### Verified latest guarded-DefEq and indexed-WHNF evidence

[Native CI 38192040598](https://github.com/dwijayuda/pskernel/actions/runs/38192040598) at `06532eac5b8f9cfa2df8b810887ab3f42ba809cb` passed the complete C0 native Lean library build, negative/differential regressions and microbenchmarks, without self-hosting tests.

- `Checker/Knot.lean` uses `psKernelDefEqQuickAfterCommon` only after structural equality and success-cache miss have been established. The public `psKernelDefEqQuick` still performs its own guards for independent callers.
- A 12,000-iteration, 512-application mismatch benchmark measured 516 ms for general quick checks and 6 ms for the pre-guarded shape check. This is an **isolated helper** win; complete DefEq still incurs the mandatory first scan, so it is not an 86× full-checker speedup.
- Indexed WHNF unchanged-stuck-spine preservation measured 73 ms for 600 iterations, versus 601 ms for the isolated spine-reassembly operation being avoided (not equivalent end-to-end timings). 
- Cold accepting WHNF measured 20 ms for 400 fresh-state, 128-application terms; no matched prior kernel baseline yet.
- The original `psc0/packages/pskernel-core` and `psc0/packages/backend-rust` remain untouched; C0 does not emit independent Rust artifacts or run self-host validation in this workflow.

**Next major architectural step:** reduce recursive syntax↔indexed conversion overhead, introduce owned handle identities within the checker session with context-sensitive cache provenance, and compare complete WHNF/DefEq/checking workloads against the original kernel before promoting indexed execution to the accepting path. Preserve negative-conformance and resource-exhaustion checks.



## Lean-native continuation checkpoint — 2026-10-12

Production `Checker/Context.lean` delta/projection helpers now defer allocating application argument spines until meaningful unfold/constructor decisions; `Core/Expr.lean` adds a direct position-from-head selector used by constructor projection, reducing intermediate list pressure for single field lookup. Differential tests retain the exact pre-change implementations as independent regression oracles, and test direct selection across arities and out-of-range indices. Changes in `717dfeb8`, `e6e00554`, `641b57aa`; paired benchmark commit `a96a4f1f`.

Completed native CI [38194277302](https://github.com/dwijayuda/pskernel/actions/runs/38194277302) (full build/test/benchmark), and [38194545945](https://github.com/dwijayuda/pskernel/actions/runs/38194545945) (full build/test/expanded inference and admission benchmark). Lazy delta measurements were near parity, **not a proven speedup**. Full inference 180× and admission 120× elapsed 0–7ms in simple fixtures; too short for production claims. Full benchmark-process peak RSS 612868 kB cannot be assigned to checker alone.

The direct selector's dedicated differential/benchmark run is being qualified; no hypothetical gains have been recorded. Remaining major milestone is persistent provenance-safe session-owned indexed storage and accepting WHNF/DefEq/inference/admission with robust complete-workload baseline and memory measurements. No self-host, bootstrap or metatheory activities in this checkpoint.



### Negative performance selection: direct expression argument retrieval

Native [run 38194880437](https://github.com/dwijayuda/pskernel/actions/runs/38194880437) successfully validated the added direct-selector differential regression and all other negative checker tests. However the paired 18,000-query depth-512 microbenchmark reported 560 ms for historical full argument list + selection versus 1298 ms for the proposed direct two-pass traversal. Consequently **commit `5de4773f8fdbbfcc2e4acc0377524c1a92231683` restored the production projection path to historical single-pass list selection**; the new `Expr.lean` helper remains experimental for its tested API and historical performance record. It is not a reported speedup. Continue verifying the final commit's native workflow and prioritize measured systemic throughput over unmeasured allocation hypotheses.



### Final post-rollback native validation (2026-10-12)

[PSKernel-C0 native Lean CI 38195084646](https://github.com/dwijayuda/pskernel/actions/runs/38195084646) at source commit `5de4773f8fdbbfcc2e4acc0377524c1a92231683` **passed all three gates**: 84-job full native Lean build; negative and differential semantic checker regression; native Lean performance benchmark suite. The production constructor-projection path again uses list-backed application-field selection. The direct selector remains an experimental helper, never a checked shortcut. Its paired same-run reference-vs-direct result still regressed: 396 ms list / 911 ms direct over 18,000 depth-512 queries (~2.30× slower). Delta eager/lazy miss results 112/111 ms are near parity, not a reliable checker speedup. Native Linux entire benchmark process VmHWM 633996 kB. This validation includes **no self-host/bootstrap or metatheory tests**. Representative entire-library baseline and session-indexed acceptance work remain open.



## October 12 — matched baseline, persistent indexed staging, binder hashing, inference arity

- Built a native same-run baseline against unchanged `pskernel-core/src` using `test/C0CheckerComparison.lean`; [CI 38213558411](https://github.com/dwijayuda/pskernel/actions/runs/38213558411) passed. The full cold-WHNF benchmark was close to parity (C0 112/102/103 vs original 109/107/104 ms for three rounds of 1,600 calls). This is the first explicit matched original implementation observation, not proof of broad faster checking.
- Implemented `Checker/IndexedSession.lean` around authoritative `Checker/Session.lean`. Canonical term nodes persist across immutable checker session snapshots, but raw IDs are private to the arena; no environment-dependent positive verdicts are memoized in this layer. Root memo uses exact syntax comparisons and small-list-to-radix promotion after eight roots. [CI 38214198674](https://github.com/dwijayuda/pskernel/actions/runs/38214198674) passed 40-root/share/snapshot regressions. The opt-in wrapper is **slower** than the ordinary accepting checker in small warm-WHNF benchmark (27 vs 53 ms).
- Fixed node hashing to account for all binder identity fields in `Core/IndexedExpr.lean`. [CI 38214477987](https://github.com/dwijayuda/pskernel/actions/runs/38214477987) passed; legacy/current binder interning 60 vs 8 ms for eight runs of 160 distinct binders. Purely indexed-substrate improvement, no acceptance-path speedup claim.
- Eliminated repeated argument-list length traversal in **production** `Checker/Inference/Helpers.lean`; retained old exported signature while passing constant count inside the recursive worker. [CI 38214789693](https://github.com/dwijayuda/pskernel/actions/runs/38214789693) passed; isolated old/new 192-argument helper 5 vs 1 ms over 350 calls. Added fuel/error differential tests and a public full-application comparison against original core; latest runs are to be checked separately before making final claims.
- Original core, backend-rust, other PSC0 packages, all branches and history remain intact. No self-hosting, fixed-point, or metatheory tests.

**Not done:** indexed acceptance for full environment-sensitive WHNF/DefEq/checked inference/admission; representative entire-library speedups; proven memory reduction; cross-store handle transport. Do not call the performance redesign complete.



### Final matched performance checkpoint and outstanding checked inference bottleneck

- [38214964079](https://github.com/dwijayuda/pskernel/actions/runs/38214964079) passed a same-run baseline with an admitted, well-typed 48-argument application against original unchanged `pskernel-core`: C0 infer-only 16/19/15 ms vs original 66/65/65 ms (200 fresh sessions each round); C0 fully checked 50/50/50 ms vs original 31/31/30 ms (80 fresh sessions each round). **Significant checked-path regression remains open.** Peak benchmark-process RSS 563564 vs 562540 kB is not proof of memory savings.
- [38215126574](https://github.com/dwijayuda/pskernel/actions/runs/38215126574) passed negative/fuel differential tests for the once-per-spine argument count.
- [38215639174](https://github.com/dwijayuda/pskernel/actions/runs/38215639174) at `30ba64034dc52e3a6a18344a2f5d220a9a5eb9ba` passed full native Lean build (85 Lake jobs), native conformance, C0 benchmarks and independent original-core comparison. On synthetic 48-binder instantiation, C0 specialization outperformed historical precheck on *both* closed and open terms (186/2 ms over 9000 closed, 71/1 ms over 4000 open), so the checked-path slowdown is not explained by the changed single-argument substitution in this evidence.
- The indexed session remains opt-in and non-authoritative; root memo is persistent, small-first, collision-checked radix after eight entries; no raw ID crosses the accepted API.
- Original package and Rust backend untouched; no selfhost, bootstrap, fixed-point, or metatheory tasks were run.

**Next engineering work:** instrument the checked application dependency graph and design a family-wide resource-semantics-preserving checked-spine optimization or safe session-canonicalized checker operations only with robust positive/negative differential and matched library evidence. Avoid rewriting acceptance around experimental indexed WHNF until its environment-dependent reduction and exact fuel decisions are complete.
