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



### 2026-10-12 validated root-cause architecture checkpoint

A standalone private-copy original-instantiation ablation, [CI 38222241004](https://github.com/dwijayuda/pskernel/actions/runs/38222241004), established a clear cause of the whole-checked-application performance regression: C0 fully checked 65/65/66 ms vs original core 40/39/39 ms, while C0 with **only** original instantiate1 substituted returned 40/40/40 ms on the same 48-argument, 80-check fixture. This overturned earlier implications from fixed-input helper microbenchmarks.

C0 `Core/Substitution/Instantiate.lean` now uses a systemic two-strategy single-binder policy: exact closed-term precheck for binder-headed lambda/Pi/let trees avoids changed-flag pair construction; genuinely open binder trees and application-headed terms continue specialized capture-avoiding one-pass substitution. There is no new acceptance shortcut; generic substitution and checking semantics are preserved. Open/closed binder-family differential tests were added.

[CI 38222841665](https://github.com/dwijayuda/pskernel/actions/runs/38222841665) at source `09e68c27822eb45e93e071dc124b81e373383c4d` passed native C0 full build (85 jobs), negative/differential suite, microbenchmarks, original-core matched benchmark, and ablation. C0 hybrid infer-only 19/19/19 ms vs original 82/81/82; fully checked C0 39/40/39 vs original 38/39/39; original-substitution ablation fully checked 40/39/39. All are per-round observations from a single hosted runner, not proof of complete checker superiority. The original core and Rust backend are intact. No self-host or metatheory tests.

An optional workflow_dispatch ablation tool is retained for investigating related regressions; it no longer runs on every source push. **Still pending:** accepting indexed WHNF/DefEq, provenance-safe session term caches, real library checking, memory attribution, and broader conformance.



## 2026-10-12 — local-context performance family root cause

Native original-vs-C0 and private no-local-index measurements [38230646350](https://github.com/dwijayuda/pskernel/actions/runs/38230646350) showed eager radix maintenance at just nine binders made 16-binder checked admission 61/62/61 ms vs 47/47/47 ms with indexing disabled and 49/49/49 ms original. An initial delayed threshold of 32 recovered shallow cases [38232026730](https://github.com/dwijayuda/pskernel/actions/runs/38232026730), but deeper depth-48 admission remained slow [38232378403](https://github.com/dwijayuda/pskernel/actions/runs/38232378403): C0 75/77/76 ms vs original 62/62/62 ms.

Replaced unconditionally eager local radix updates by an adaptive **short-context list plus persistent indexed snapshot and sixteen-entry pending overlay** in `Core/LocalContext.lean`. The ordered decl list remains authoritative; lookups prefer newest pending declarations before checking structural name equality in indexed collision buckets; commit adds oldest pending first so shadowing cannot invert. On explicit inductive continuation snapshots, `Admission/Inductive/Ordinary/Constructor.lean` and `Admission/Inductive/Mutual/Analysis.lean` carry overlay/count together with the base index. The negative suite checks promotion, exact lookup equivalence, immutable predecessors, and shadowed names across a batch commit.

[CI 38233477973](https://github.com/dwijayuda/pskernel/actions/runs/38233477973) passed production Lean build and regressions, microbenchmarks and matched original-core checker. It measured 20k deep lookups at 76 ms vs linear 1279 ms, and bounded real checked admission at parity (C0 vs original: depth16 28/28/27 vs 28/28/27 ms; depth48 45/44/45 vs 44/44/43 ms). The **overall CI run** was red solely because a *private diagnostic ablation* still returned `Option` instead of the new local-index update structure; corrected in `fd622395` and moved behind manual workflow_dispatch in `593f83df`. Confirm newest regular CI before calling the complete workflow green.

Performance architecture remains incomplete: production still uses recursive expressions for all accepting WHNF, DefEq, inference and admission; indexed arena is opt-in experimental, self-host/metatheory deferred. Need representative module-level throughput, memory attribution and safe indexed acceptance integration.



### Native CI closure: batched local index qualification

[CI 38233818758](https://github.com/dwijayuda/pskernel/actions/runs/38233818758), source `fd622395f03e1af40e7e4d18865fd1171aba6de2`, finished **successfully** with complete C0 Lean build (85 jobs), negative/differential tests (including batched shadowing), native microbenchmarks, matched independently built original core (81 jobs), and the corrected optional no-local-index private diagnostic (85 jobs). Same-run full checker declaration admission in that run: depth-16 chain C0 24/27/25 ms vs original 25/25/27 ms; depth-48 chain C0 41/42/41 ms vs original 41/40/43 ms; local-index-disabled C0 24/24/24 ms depth16 and 40/40/40 ms depth48. The net advantage of local indexed storage is lookup-dependent, **not** demonstrated across all declaration workloads.

[CI 38233883497](https://github.com/dwijayuda/pskernel/actions/runs/38233883497) at source/workflow commit `593f83df4d75a72ec17202e8cd04476a068e08a8` also **completed successfully**, with ordinary native Lean build, negative conformance/differential tests, native microbenchmarks and original-core matched checker. The private `local_index_disabled` ablation is available only on manual workflow_dispatch because its performance and the structural impact have already been isolated. All mandatory production checks are green; there were no self-hosting, bootstrap/fixed-point, Rust-generated, or metatheory tests.

**Current trustworthy baseline:** local-context short-list threshold 64, 16-local staged radix updates, immutable snapshots, separate original-core matched checking. Deep index construction still costs more than raw lists; 512-local repeated lookups are measurably faster. Avoid promoting opt-in indexed expression WHNF/DefEq to accepting verification before environment-dependent semantics, exact fuel and safe cache ownership are qualified. This project is not complete; representative large-library whole-checker speed/memory and indexed accepting-engine coverage remain open.



## Further native Lean redesign: demand-driven local index snapshots — October 12, 2026

The previous adaptive 64-binder + 16-element overlay design recovered performance for 16/48-binder admission, but [native CI 38234300832](https://github.com/dwijayuda/pskernel/actions/runs/38234300832) showed **96-binder** local-reference checking remained slower (~178–182 ms per 20 declarations) than unchanged original core (~162–165 ms). Deferring eager promotion to 129 locals [`45f4474f`](https://github.com/dwijayuda/pskernel/commit/45f4474fcd6f0ff9022ada08f15a9842dbfc19b3) recovered near-parity at depth 96 ([CI 38234744764](https://github.com/dwijayuda/pskernel/actions/runs/38234744764)), but source checks with 192 binders still showed ~186–190 vs ~175–178 ms.

**Design response:** `Core/LocalContext.lean` now holds its radix snapshot as an immutable, memoized Lean `Thunk`, with pending overlay and exact list retained. Source [`8d72f7fb`](https://github.com/dwijayuda/pskernel/commit/8d72f7fb116c9eb9d4d2b9da71cce1aa34c92116) changes indexing so binder extension *does not eagerly allocate radix nodes*. The index becomes available after 128 bindings but is **not forced** for lookup until the deep lookup policy (256). Pending overlay is checked newest-first before forcing the snapshot. A persistent context's thunk is pure/deterministic from its own immutable declarations; no cross-environment equality or type-acceptance cache is introduced. The checker still makes every typing/DefEq/admission decision on recursive `PsKernelExpr` and enforces the same fuel/resource rules. [`078ea101`](https://github.com/dwijayuda/pskernel/commit/078ea1013bc18d2a750ba49dd68ba08a3edba798) added memoized deep-local lookup, shadowing and snapshot differential regressions.

[CI 38235717690](https://github.com/dwijayuda/pskernel/actions/runs/38235717690), source `62fb1d34f4a8835b18d61b67621cc9f94e082643`, **passed the production native Lean build, negative/differential suite, native microbenchmarks and matched unchanged original-core full checker**. It failed only in an opt-in private `local_index_disabled` diagnostic because the source implementation had moved its lookup policy definition; the private script had stale delimiters. The workflow was corrected and this already-answered diagnostic is manual workflow_dispatch only as of `cc4f620a` and `1f5d783e`. Check the latest workflow for a fully green aggregate result before citing one.

Three-round *complete checked declaration* timings from that run: 20 checked declarations at depth 96 were ~163–168 ms in C0 vs ~161–165 ms original depending on reference position; six checked declarations at depth 192 were ~177–181 ms in C0 vs ~177–180 ms original; three checked declarations at depth 320 were ~237–247 ms C0 vs ~236–240 ms original. This is **near parity**, not evidence of generalized faster full-library checking. The 512-local lookup microcase still favors indexed access (139 ms vs linear 2054 ms for 20k lookups); it is slower than the formerly eagerly materialized radix on some matched microcases because of policy/overlay costs. Process memory attribution remains unresolved.

A separate binary-trie vs radix-16 diagnostic in native Lean (CI [38235530285](https://github.com/dwijayuda/pskernel/actions/runs/38235530285), all mandatory native steps passed, only optional diagnostic red) measured binary path-copy **77 ms** vs radix **35 ms** for constructing 25×512 locals, and binary **75 ms** vs radix **35 ms** for 20k lookups; no reason to replace the radix. The rejected binary diagnostic was removed from the benchmark source at `4cab1974`.

**Remaining main objective:** full environment-dependent indexed WHNF, DefEq, inference and admission in the trusted checking pipeline, with session-owned provenance, exact reduction priority/fuel, negative conformance, real representative library throughput, peak memory and repeated matched baseline checks. Opt-in indexed session still incurs overhead and should not be promoted on helper timings alone. Keep original `pskernel-core` and PSC0 Rust backend unchanged. No self-host, bootstrap, fixed-point or metatheory tests.



### Current 12 October native substrate milestone

At source `c8d63e109247fd28b9608cb045562e5699583870`, [CI 38239387122](https://github.com/dwijayuda/pskernel/actions/runs/38239387122) passed full native Lean build, negative/fuel/differential tests, indexed microbenchmarks, and matched original PSKernel-Core. Introduced O(1)-per-node exact `looseBVarRange` in the source-owned indexed term DAG; indexed lift and memoized one-binder instantiation skip entire unaffected subtrees. Tested against independent recursive de Bruijn predicate and indexed reference substitution/lift on open/closed terms. Closed shared DAG indexed instantiation 885 ms recursive vs 1 ms cached-range memo for 100 calls (isolated, one runner; not the accepting checker). No cross-store handles may be compared for identity.

A direct-recursion rewrite of recursive syntax equality was rejected by measured regression and production source restored at `bdec38c4`. Matched public checking remains near parity vs original, with no claim of full-kernel or memory superiority. The original kernel/Rust backend remain intact and no selfhost/bootstrap/metatheory testing occurred.

**Next:** integrate metadata and indexed representation only at an accepting session boundary that preserves declaration/environment and local-context provenance, exact resource budgets, universe/recursor/quotient/native rules and rejection behavior. Benchmark real full libraries and cold/warm memory. The opt-in indexed session wrapper still adds overhead until it avoids recursive-source↔indexed rematerialization. Do not treat indexed fragment results as soundness or accepted executable artifacts.


## October 12: exact local count with independent recursor fresh names

Native source commit [e8952b95](https://github.com/dwijayuda/pskernel/commit/e8952b95a279f5bf82aa7b2c664d17430308bbd7) replaced pre-promotion repeated linked-list `.length` with an incrementally maintained `declCount`. The independent `nextIndex` is still used for fresh local names; it can be larger than live declaration count after an inductive recursor analysis. Continuations now use a snapshot-preserving one-field helper instead of rebuilding five structural fields. Exact-count/fresh-index divergence and lookup regressions passed [native CI 38240821497](https://github.com/dwijayuda/pskernel/actions/runs/38240821497), along with complete build, negative/differential checks, microbenchmarks, and matched original-core checking. This is a verified **correctness-neutral cost removal**, not a demonstrated full-checker acceleration: matched fully checked application/admission cases remain near parity. A dedicated single-family private `decls.length` ablation was prepared in [e2fea7fe](https://github.com/dwijayuda/pskernel/commit/e2fea7feac956c0197cb71edfed1770841f3c161), [run 38241386784](https://github.com/dwijayuda/pskernel/actions/runs/38241386784). Check and record its result before calling the cached count a measured performance winner. Original core, compiler and Rust backend stay untouched.


### Final diagnostic outcome — cached declaration count

[Native run 38241386784](https://github.com/dwijayuda/pskernel/actions/runs/38241386784) was fully **green**, including separate private C0 build with only the promotion test reverted to `context.decls.length`. Same-run 160 checked declaration chain measured **37/38/38 ms** with cached count versus **37/38/38 ms** with historical scan. Depth-192 and depth-512 cases also stayed near parity; depth-320 improved only by ~0–5 ms on the three index-0 samples, not a broad speedup. Whole checker remained near unchanged original. No observable memory benefit is established from process-wide RSS. The live count is therefore retained only as exact O(1) internal bookkeeping with an independent fresh-name invariant, **not** as a qualified checker performance win; revisit representation cost when profiling real modules. All non-C0 source and self-hosting/metatheory targets remain untouched.


### Native wide checked-spine redesign, verified 12 October 2026

`Checker/Inference.lean` now has a source-checked frame traversal for root applications with at least 64 arguments, retaining original recursive acceptance on smaller expressions. Frames capture original fuel and context depth; all head and argument typing, WHNF, DefEq and dependent substitution use the unchanged semantics. `Core/Expr.lean` supplies bounded loose-variable ranges, summarized once across Pi bodies. Only syntactically closed Pi bodies (range zero) bypass unchanged-result substitution; a dependent body or unsupported/bounded analysis falls back. This avoids O(n²)-like repeated body scans for long non-dependent checked spines. Differential tests cover low fuel, exact error class, binder shifts, context recursion limits and negative arguments. [CI 38246930574](https://github.com/dwijayuda/pskernel/actions/runs/38246930574) passed build, conformance, microbenchmarks and unchanged original checker.

Production matched 192-argument fully checked applications: C0 9/7/7 ms vs original 33/34/34 ms (12 calls, three rounds), not whole-library speed. 192-arg full-operation C0 recursive reference 158 ms vs framed 31 ms for 60 calls. The varied checked 48-argument path remains 52/50/50 vs 48/48/48 ms; deep checked admission near parity/slower on several regimes. Peak process-wide RSS C0 844060 kB vs original 841284 kB is not per-operation allocation evidence. This is a qualified production milestone; indexed environment-dependent evaluator and admission are **not** complete. Failed `ptrEq` unsafe comparator compile was reverted at `6769e7c2`; no unsafe code remains.


## Qualified compact checked frames and whole admission fixture — 12 October 2026

[Source commit 0859097f](https://github.com/dwijayuda/pskernel/commit/0859097f6c1f8bdd6b869d477db829575bc2823c), [all-green native CI 38248015655](https://github.com/dwijayuda/pskernel/actions/runs/38248015655). A checked frame now retains only `PsKernelExpr` argument, original remaining `Nat` fuel, and exact depth reached through `psKernelCheckerContextEnterRecDepth`; each frame reconstructs the shared immutable parent context with that depth. This avoids storing whole context snapshots in each frame and preserves native evaluator, environment/local scope, safety, eager reduction, fuel and ordering. Wide-frame differential checking now directly calls the **independent recursive core** at 63/64/65/192/320 and bounded low-fuel/error/recursion-depth cases, rather than comparing against the public route that may itself choose frames.

The benchmark added a sequential 32-declaration fully checked library using the safe admitted 192-argument function. C0 32/32/32 ms against unchanged original 130/131/132 ms across three rounds. This is genuine accepting admission but an engineered wide non-dependent Pi workload, not Init/Std/Mathlib coverage. The improvement belongs to the **combined existing bounded Pi-range/frame architecture**; no isolated speed or peak-memory benefit was established solely for frame payload compaction. Short fully checked workloads still show slight cost. Separate indexed DAG remains non-accepting. No self-host, bootstrap or metatheory suites.


### 2026-10-12 — recursive Pi-metadata root engine qualified and promoted

After [CI 38251853231](https://github.com/dwijayuda/pskernel/actions/runs/38251853231) passed independent three-way complete-checking and exact resource/error tests, source [5c8a1e83](https://github.com/dwijayuda/pskernel/commit/5c8a1e83e22debd4fd6c365ba9666e834e8c5d66) made the fuel-indexed metadata-carrying check the only accelerated **root** application route for 16+ arguments. It retains exact structural `Nat.succ remaining` recursion, the actual depth policy, head-before-argument order, full checked argument typing/DefEq/eager policy, and original dependent substitution; only fully validated syntactically closed Pi bodies skip repeated no-op scans. The 32+-frame route remains an independent reference; the recursive source checker handles smaller and other shapes. No arena handles or session-global equality shortcuts are trusted.

[All-green native CI 38252783408](https://github.com/dwijayuda/pskernel/actions/runs/38252783408) measured whole accepting checked applications and safe sequential admitted declaration families at widths 16, 24, 32, 48, 192. Full checked 24-arg operations C0 24/25/25 vs original 32/33/33 ms across 200 calls; varied 48-arg checked C0 39/41/41 vs original 65/67/74 ms across 160 calls. 64 safe admitted 48-arg definitions C0 20/19/20 vs original 31/31/31 ms. Negative, malformed, exact fuel/depth, standard native suites and original-core matched checking passed. Ordinary smaller admission and inductives still near parity. Full indexed environment-sensitive WHNF/DefEq is not integrated; no qualified whole Init/Std/Mathlib or attribution of memory savings. **Do not declare final redesign complete.**


### Nested checked core hook and wide checked argument recursion — validated 12 October

[CI 38264313583](https://github.com/dwijayuda/pskernel/actions/runs/38264313583), source `10974c2d`, passed entire C0 native qualification. The single `psKernelInferCoreWithFuelUsing` recursively propagates an *optional* checked application callback, while the old `psKernelInferCoreWithFuel` remains the explicit hook-free source oracle. Checked lambdas, Pi, let, metadata and projection recursion now benefit from the already-validated bounded Pi metadata worker without copying typing rules. Negative/fuel/fresh counter equivalence and real 64-definition lambda/metadata admission passed. Matched original core: metadata-wrapped 48-arg admission C0 15/14/16 vs original 23/22/26 ms, lambda-wrapped C0 17/17/17 vs original 24/24/26 ms.

[CI 38265144787](https://github.com/dwijayuda/pskernel/actions/runs/38265144787), source `7d2c6708`, passed full native build, negative/differential and matched original checks. The fuel-indexed optimized worker now recursively verifies a wide checked application as another application's argument with its **same remaining fuel and context**, rather than calling the general historical worker. Short/non-application arguments still use original inference; checked side conditions and state/error rules remain intact. New 48-definition complete nested-argument library measured C0 51/51/50 ms versus original 63/62/62. The isolated incremental gain and memory savings are unqualified; original core/Rust backend/PSC0 unchanged. Full environment-dependent indexed WHNF/DefEq and large-real-library benchmarks remain unfinished.


### 2026-10-12 native accepting dependent Pi summary refresh

Source [e8f96f92](https://github.com/dwijayuda/pskernel/commit/e8f96f92e1903e1df3c9997f3463d42c9c2e85dc) split the exact fuel-indexed checked application worker into immutable diagnostics: prior invalidation-only and opt-in bounded post-dependency Pi-suffix resummarization. After a genuine substitution changing a dependent codomain, a bounded Pi-prefix probe of 12 binders decides whether the newly substituted type is long enough to amortize exact suffix analysis. All shorter/failed/dependent cases use previous substitution, exact head/argument checking and original reductions; the metadata never determines well-typedness. Source [20200e59](https://github.com/dwijayuda/pskernel/commit/20200e59c7c9064a14c9e13d77f5474554d45b4d) added a genuine `∀ A : Sort 1, ∀ x : A, ...` acceptance fixture and exact low-fuel/negative original-oracle comparisons. [CI 38267242015](https://github.com/dwijayuda/pskernel/actions/runs/38267242015) fully passed opt-in qualification.

[Promotion b5e0472b](https://github.com/dwijayuda/pskernel/commit/b5e0472b1ec4cd6f62229a239f30179f576317f7) routes the existing public root and nested checked application paths through the qualified syntax-only resummarization mode. [CI 38267860486](https://github.com/dwijayuda/pskernel/actions/runs/38267860486) **passed** all required Lean 4.34 native stages and separately built original core. Three rounds of 80 *complete* dependent checked operations C0 30/31/32 ms vs original 52/52/51 ms; 48 safe sequential dependent checked admissions C0 23/23/23 vs original 37/37/36 ms. Internal old-vs-new C0 paired 30 checks of tail192 114 vs 27 ms. Memory reduction is not established. The original `pskernel-core`, PSC0 compiler, Rust backend and deferred selfhosting/metatheory remain untouched. Accepting indexed WHNF/DefEq coverage and realistic whole-library qualification remain open.


### Qualified native DefEq lambda/Pi spine linearization — 12 October

[Source 3b082900](https://github.com/dwijayuda/pskernel/commit/3b082900184d47109895c4e4e78eae1f6fce8ce8) replaces oldest-first append-and-reverse substitution lists in both binder-spine engines with newest-first `List.cons` and direct exact de Bruijn instantiation. Each sufficiently deep binder chain gets optional exact bottom-up loose-body ranges computed once using `Core/Expr.lean`; short or failed summaries retain original per-body scan. This removes two sources of quadratic binder-depth work without altering DefEq acceptance, fresh names, recursion fuel, local-context introduction, callback order or original error messages.

[Native CI 38270573104](https://github.com/dwijayuda/pskernel/actions/runs/38270573104) completed successfully: fixed Lean 4.34 build, negative and independent metadata/source-domain checks, binder comparisons for explicitly dependent de Bruijn `bvar 1` under multiple binders, microbenchmarks and matched independently built original kernel. For six complete depth-256 Pi checks, C0 **6/6/5 ms** over three rounds vs original **158/156/156**; corresponding lambdas **6/5/5** vs **157/155/155**. Complete ordinary declaration/inductive checks near parity; process-wide high-water memory not improved. The original `pskernel-core` and all deferred self-host/metatheory tests remain out of scope. Canonical indexed WHNF/DefEq acceptance still unfinished.
