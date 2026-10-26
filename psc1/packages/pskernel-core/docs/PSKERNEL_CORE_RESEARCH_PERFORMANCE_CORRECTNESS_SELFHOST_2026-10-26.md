# PSKernel-Core: research-backed implementation priorities

26 October 2026, Asia/Jakarta. Authorized open-source implementation research for `dwijayuda/pskernel`; pinned Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. External references were checked on this date. Recommendations below are engineering inferences; measured project results and external findings are distinguished explicitly.

## Decision

Finish the owning DAG execution path, establish its semantic invariants, and qualify the actual compiler-produced programs. Optimize the measured dominant work in that path. Do not adopt another cache representation change merely because a local refinement proof passes.

The adopted production tree is `cada4884b4250a708dccadca42b8ef5bddbd04a3`. The independently reproduced original nested free-variable capture mismatch is corrected there. The newer complete nested owning public route remains isolated. Global gates remain **B OPEN / C FAIL / D OPEN**. There is no claim of complete kernel soundness, end-to-end backend preservation, release readiness or statistically established whole-kernel speedup.

## What the current evidence actually says

| Axis | Verified evidence | Remaining limitation |
|---|---|---|
| Correctness | Isolated source `f2ffc9d7bd5219c51956c13e11c7f2bee3ccd220`: 806 distinct native proof reports, 60 proof source modules, 1,795 controls; all 364 actual Git snapshots and all 452 archive digests verified | Many reports establish structural correspondence or conditional protocols; their count is not a global soundness theorem |
| Nested execution | All seven complete original-environment fixtures match; five corrupted restored-rule fixtures are rejected by both original and owning validators; public atomicity, resources, original bounds and no-reimport ownership pass | Its fresh complete generated and canonical programs both encountered a PSC1 parser portability failure, so this source is not paired-qualified |
| Compiler portability | Earlier overlay source `abdce8b4a22eb5b5037611746689a2baea856b68` passed fresh compilation of 173 modules/2,070 declarations, 999 native-equal controls and 21 retained runtime harnesses; raw archive/Git/closure verification passed | This earlier program does not contain the newer complete transaction |
| Current adopted String | All six generated raw shard archives independently read and checked: 8,400 assertions; same complete program and authentic 294-declaration/377-metadata fixture | Canonical mixed-Unicode sample 5 hit the unchanged 1,500-second deadline; five other canonical samples passed |
| Full Arena | All 193 classifications/adaptations and 176 completed raw semantic envelopes retained exactly by the scalar experiment | 174 strict passes, 17 timeouts and two separately classified safety-contract differences; strict gate remains failed |
| Scalar cache experiment | Both complete compiler routes and 2,400 comparisons with the actual old worker passed; original worker preserved; native refinement and independent artifact audit passed | Real same-runner A-B-B-A did not establish a performance win; do not adopt |

The new portability correction is source `94ffdcb92d74a3a7d95a1a0d6f2d625efe0aeda8`: introduce a named local before a projected field access in `DagNestedValidation.lean`. The corresponding all-state equality lemma is added without changing earlier statements. It requires a new **807-report** cohort and a new complete paired build; old 806 results cannot qualify changed production bytes.

### The completed scalar A-B-B-A

The actual 17-member, 16,587,898-byte archive `12651426975` has SHA-256 `93fae7a049235b86216514ab8190eca58d8d4b3b0b227c2561d0410a21da02d8`. Every manifest member, both nested qualified-program archives, the authentic fixture archive and the unchanged runner were read and verified.

| Order | Variant | Observed seconds | Result |
|---|---|---:|---|
| A1 | Corrected adopted baseline | 1,484.40 | All 1,400 assertions pass |
| B1 | Scalar candidate | 1,485.15 | All 1,400 assertions pass |
| B2 | Scalar candidate | At least 1,500 | Deadline; exit 137; no complete receipt |
| A2 | Corrected adopted baseline | At least 1,500 | Deadline; exit 137; no complete receipt |

There are **2,800 completed assertions**, not 5,600. The completed candidate observation is about 0.75 seconds longer, which is not evidence of a stable regression or improvement. Two right-censored observations prevent the intended complete four-run comparison. Do not compute a passing median or infer a speedup by dropping them. The killed timeout wrapper's tiny RSS and `exit=0` text are not Node peak-memory measurements. The actual process result and missing completion receipts govern classification.

## Findings from primary sources

### Keep semantics small; prove the optimized implementation refines it

The pinned reference Lean kernel separates checked inference from infer-only work and uses different inference, core-WHNF and equality caches. Its implementation also orders cheap equality tests before more expensive reduction. These are useful comparison points for scope and evaluation order, not authority to share caches across unrelated owners. See the exact pinned [`type_checker.cpp`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/type_checker.cpp), Git blob `a735a6e42febcc94b45808cbcf30afa4e4af1ca2`.

Con-leche provides a particularly relevant architecture: an executable cached checker is related to a simpler checker by refinement, with a whole-environment model theorem above the declaration fold. Read its actual code at pinned commit `0d2f467bbe576f21e42ea861d246abef718f1c13`: [`Kernel/Core.lean`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/Kernel/Core.lean), [`Cached/CoreC.lean`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/Cached/CoreC.lean), and [`MainTheorem.lean`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/ConLeche/MainTheorem.lean). Their inspected Git blobs are respectively `89197201f6d82c543e567555d7c1061e2f64c114`, `b05561b3f301d85cc16237eafaa360dcdb346b2c`, and `cf51f3f10e5a702bd32ff58e4f89463c8bee821b`.

**Application to PSKernel:** use existing validation-to-`ArenaModel` and decoded-prefix theorems as established foundations. Extend their preservation through every generated continuation and checker transition. Do not restart the metatheory from an unconnected toy arena, or count a desired output invariant as a premise and then call the result global correctness.

### Partial correctness is the right logical target for a bounded checker

[Lean4Lean](https://arxiv.org/html/2403.14064v3) distinguishes an executable expression representation from its logical model and makes freshness/local-context relations explicit. It also explains why unrestricted normalization/definitional-equality termination is not an appropriate general promise for Lean's theory. Its metadata-overflow example illustrates why a failed bound cannot safely become metadata that falsely signals a closed term.

**Application to PSKernel:** prove that every successful checking result is justified, independently of whether all inputs terminate. Separately preserve public resource/error semantics for the finite qualified workloads. The 17 observed timeouts remain actionable performance failures under the existing acceptance policy; theoretical partiality is not a reason to hide or relabel them. Continue using unbounded logical `Nat` metadata or explicitly checked representations; never use an overflow default to enable a fast path.

### Review nested restoration as an independent checking boundary

The official [Lean 4.33 release notes](https://lean-lang.org/doc/reference/latest/releases/v4.33.0/#kernel-soundness-fixes-and-further-improvements) record fixes around nested-inductive phantom parameters, free variables, reserved names, post-elimination checking and projection structure names. These establish a focused conformance-review checklist; they do not by themselves prove PSKernel correct.

**Application already implemented:** transformed success is followed by separate restored-template, constructor, recursor-type/EnsureSort, rule and restored-type DefEq checks through owning callbacks. Pure syntax restoration supplies no checking authority. The original projection-name comparison is present in the inspected PSKernel ID equality worker and existing projection-name controls; preserve it during optimization.

### Profile the actual runtime, including allocation and boundary work

Con-leche's [`PERF.md`](https://github.com/leanprover/con-leche/blob/0d2f467bbe576f21e42ea861d246abef718f1c13/PERF.md) separates parse/install/check costs and warns against treating shared-machine wall times as controlled comparisons. Its profiles also identify allocation/reference counting as substantial work. Those measurements use a different implementation/runtime and do not predict a PSKernel JavaScript speed ratio.

**Application:** obtain PSKernel's own CPU samples, allocation/GC evidence, phase costs and decline/restart counts before choosing another optimization. A source-preserving V8 diagnostic branch `1e39dde7f939291ffc9df4d422b1a42b02c9384d` is submitted against the exact adopted complete program and sample-5 fixture. It retains all original 1,400 assertions and the 1,500-second/4,096-fuel/2,048-MiB/empty-PATH policy. Profiling changes timing, so its output cannot qualify performance. [Node 22.23.3 documents `--prof`/`--prof-process`](https://nodejs.org/download/release/v22.23.3/docs/api/cli.html#--prof); tick-log processing is confined to Linux Actions.

### Source proofs, compiled behavior and bootstrapping need separate evidence

The [CakeML backend paper](https://cakeml.org/jfp19.pdf) connects compiler passes and runtime behavior through preservation proofs and bootstrapping within a theorem prover. [CompCert's TCB analysis](https://arxiv.org/abs/2201.10280) explains why source-level verification still depends on accurate models and trusted surrounding components. Neither result transfers automatically to PSC1.

**Application:** distinguish compiling PSKernel's `SelfHost.lean` closure, executing the emitted checker, using that checker to replay the compiler's declarations, obtaining compiler fixed points, and proving backend semantic preservation. An entry module named `SelfHost.lean`, a boolean semantic-root declaration, a stable binary hash or matching outputs on examples is insufficient to close all of these obligations.

[Lean's proof-validation guidance](https://lean-lang.org/doc/reference/latest/ValidatingProofs/) also distinguishes checking a proof from establishing that its statement means the intended claim. PSKernel's strict axiom allowlist already rejects every additional axiom; it must not depend only on searching for a few historical native-evaluation axiom names.

## Implementation order and exit criteria

| Order | Concrete work | Evidence required to finish |
|---|---|---|
| 1 | Finish the portable complete nested owning public route | New 807 native reports/1,795 controls; actual 364 Git bindings; both fresh complete compiler routes; all 1,188 native-equal compiled controls and 21 unchanged legacy harnesses; independent raw-artifact audit |
| 2 | Profile the adopted mixed-Unicode workload | Authenticated original program/fixture/runner; retained full assertions; actual tick log and processed CPU summary; censored/diagnostic status explicit |
| 3 | Remove repeated original-operation work where profiling demonstrates it | Per-entry-path decline reason/coverage inventory; implement supported missing cases; preserve exact owner, error order, fuel and external-ID boundaries; original-state restart only where still required |
| 4 | Reduce materialization/import cost | Preserve full required input validation; demand-based expression materialization and one-owner metadata worklists; no repeated recursor import; reference parity on shared and deeply nested inputs |
| 5 | Close the checker refinement chain | Every transition preserves arena/decoded/declaration/cache/local-context relations; successful Check/WHNF/DefEq/admission implies the intended logical judgment; no unproved global output premise |
| 6 | Qualify kernel-assisted self-hosting and backends | Exact compiler-source closure; actual kernel replay of exported compiler declarations; independent runtime executions; documented compiler/runtime assumptions; coherent self-application/fixed-point receipts and separate preservation obligations |
| 7 | Re-run final finite acceptance matrix | All 193 original Arena cases retained; both full String routes; no excluded failures, changed reference bodies, relaxed budgets or unsupported release claims |

### Highest-value performance hypotheses to test

These are hypotheses, not measured conclusions:

1. Repeated decoding, generated metadata import and original-operation restarts may dominate the benefit available from scalar hash-analysis allocation changes. Profile these boundaries separately and count them on the actual workload.
2. DAG traversal should do work proportional to distinct reachable nodes/edges whenever the operation permits memoization. Deep sharing must not silently become traversal of an exponentially expanded tree. Keep structural budgets and logical expression-size checks distinct.
3. Binder telescopes and application spines can accumulate substitutions and rebuild once rather than traverse a growing spine repeatedly. Require a whole-input refinement statement covering binder indices, fresh names, errors and fuel before considering adoption.
4. Cache hits must be scoped to the correct immutable environment, local context and operation mode. Infer-only results cannot become checked-inference certificates; hash equality cannot replace exact key equality.
5. Parallel execution is a later throughput experiment after serial semantics and memory use are stable. It cannot repair a false acceptance or justify changing the serial reference workload.

### Proof obligations to make explicit

Use the real production transition functions and established public-validation invariants. Candidate theorem shapes below describe required properties, not already proved declarations:

- Smart construction and transformations extend the canonical arena while retaining every earlier node's meaning and metadata.
- Synchronization extends the actual decoded prefix; a same-size forged record is not sufficient correspondence evidence.
- Declaration references decode to the types, bodies and recursor rules of the actual admitted immutable environment, including renamed restored declarations.
- Local-context/freshness relations are preserved across binder entry, exit and fresh closed sessions; cached answers remain valid in their own scope.
- Full checking success implies a typing judgment; infer-only success requires its separate well-typed-input premise.
- WHNF success preserves definitional equality; positive DefEq success is sound; a timeout is neither an equality proof nor a definitive negative.
- Complete declaration admission preserves the logical environment invariant; publication preserves resources, original external bounds and atomic failure.

The existing `validate_ok_establishes_arena_models` and `decode_checked_ok_establishes_arena_model` bridges already connect successful production validation/decoding to a structural model. Build on them. They do not yet establish all generated checker continuations, complete logical environment soundness or target-runtime preservation.

## Benchmark and release discipline

Measure the same source-bound complete programs on the same authentic workload and keep cold startup, admission, metadata, checking, reduction/equality, allocation/GC and whole-process totals distinguishable. Preserve every assertion in qualification runs. Use fresh processes and matched ordering; use enough complete repetitions to assess variability. Treat the 1,500-second observations above as right-censored, and include every failure in the denominator.

Separate operational conformance, logical soundness, implementation refinement, backend behavior and package/installability. None is a substitute for the others. The [Lean Kernel Arena](https://github.com/leanprover/lean-kernel-arena) supplies standardized cases and real-workload comparisons; our existing fixed 193-case cohort remains the project gate until a separately recorded versioned change is justified.

The [Lean project's October 2026 verified-kernel update](https://leodemoura.github.io/blog/2026-10-15-lean-now-ships-with-verified-kernels/) makes the remaining compiler/runtime boundary explicit and describes rechecking through independently implemented kernels. Use independent checking to strengthen evidence; retain PSKernel's own implementation and proof obligations rather than treating another checker's theorem as a theorem about this code.

## Evidence and active work

- Public native806 archive: `12650804167`, 1,070,413 bytes, SHA-256 `49f685c64423b234e6439abdefb0c5cb051f54c36f00ab85b5d4b40ef5381952`; all 453 members/452 manifest entries actually read. A new 807 cohort is required for the named-projection change.
- Earlier overlay complete archive: `12650870720`, SHA-256 `d8cee1cc2d6cf4b9e84768f931e1e91c60e3f30f25c064875790d52290816a45`.
- Scalar A-B-B-A: run `40314241978`; static root audit records no adoption and no performance qualification.
- Failed first complete public pair: source `5a4a3471ec56f8a443df511fdd43fe9b49c37f1b`, run `40328260710`; both failed on the same parenthesized-projection parser limitation. A passing native cohort cannot substitute for these failures.
- Named-projection native continuation: `94ffdcb92d74a3a7d95a1a0d6f2d625efe0aeda8`; next full pair must authenticate its exact successful native artifact.
- V8 diagnostic continuation: `1e39dde7f939291ffc9df4d422b1a42b02c9384d`, run `40329883587`; never a qualification-timing result.

All execution remains GitHub Linux Actions only. Research and evidence updates do not authorize a main-branch merge, package publication, forced ref update or a relaxed correctness/resource gate.
