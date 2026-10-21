# PSKernel-Core — Lean 4.35 architecture, correctness and performance audit

Audit baseline: `3aa077cb64ff06f76727decd01c43ad6c33f351d` on `integration/psc1-pskernel-expr-v2-lean435-20261021`, repository `dwijayuda/pskernel`. Reference Lean is exactly `eb6cafb7290e8bd5f2937522d8d804f58f02bafc` (`v4.35.0`). Dates use Asia/Jakarta; Actions timestamps use UTC.

This document records inspected source, observed failures and selected corrections. The [completion plan](PSKERNEL_CORE_COMPLETION_PLAN.md) owns execution order; the [progress matrix](PSKERNEL_CORE_PROGRESS_MATRIX.md) records implementation separately from qualification. Read the newest `../AI_WORK_STATE.md` entry and exact-source Actions before using a later checkpoint. Local equations and finite differential tests are not a global soundness or backend-preservation theorem.

## 1. Exact baseline and trust contract

At **3aa077c**, [integration 39622318383](https://github.com/dwijayuda/pskernel/actions/runs/39622318383) passed native job 119298737696 and generated job 119298738193. [Correctness 39622318348](https://github.com/dwijayuda/pskernel/actions/runs/39622318348) passed native 119298737337 and canonical-source 119298737884. All six [research 39622318349](https://github.com/dwijayuda/pskernel/actions/runs/39622318349) jobs passed. These establish the scoped developer-provider A contract at this exact baseline. They do not qualify a child correction.

The provider starts with an empty session, admits every dependency through `psKernelV1AdmitDeclaration`, and executes independently in native Linux or authentic PSC1 → TypeScript 7.0.2 → Node 22. Both generated routes are tested detached with an empty PATH. Full-kernel DirectJS remains unsupported. The canonical wire supports safe regular definitions, checked theorem proofs and checked inductive groups; broader typed library operations have their separately documented contract. See `../PROVIDER.md` and `../KERNEL_CONTRACT_V1.md`.

Public untrusted DAG ingress is `API/Dag.lean::psKernelV1RunDag`: replay metadata and topological references, decode once, then execute ordered commands. Exported constructors, indexes, receipts and internal helper results are forgeable implementation values, not admission authority. Checked generated rules must come from a fully admitted private environment. Failed batches publish no partial session. The default fuel remains 4096, with the existing depth/numeral/host policies.

**Baseline milestone status: A qualified for that scope; B incomplete; C failed; D open.** A useful independent V1 provider already exists. Complete V2, full Lean compatibility, performance promotion and global metatheory are separate obligations.

## 2. Lean versus PSKernel architecture

PS paths in this section are relative to `psc1/packages/pskernel-core/src/Ps/KernelCore/`. Lean paths refer to the pinned [kernel source](https://github.com/leanprover/lean4/tree/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel).

| Area | Pinned Lean mechanism | Inspected PSKernel mechanism and consequence | Decision |
| --- | --- | --- | --- |
| Expression identity and allocation | `expr.h`, `expr.cpp`: reference-counted shared immutable expressions, cached hash/metadata, pointer fast paths plus structural equality | `Core/ExprV2/Node.lean`, `Builder.lean`, `Paged.lean`: arena IDs, cached hash/loose range/FVar/MVar/depth; public replay reconstructs metadata. Paged arrays mitigate generated immutable append copying but retain copying at page-directory growth. Recursive V1 remains a second representation | Retain checked IDs and exact metadata; improve indexing and lifetime, rather than replace the representation again |
| Equality and sharing | `expr_eq_fn`, `type_checker` caches use structural/pointer identity safely | `Core/ExprV2/Equality.lean`, `PairMemo.lean`: collision-safe structural comparisons; memo lookup is a list. Each candidate comparison can start a fresh memo | Hashes remain filters. Introduce an exact-key index with collision buckets; no hash-only acceptance |
| WHNF and lazy delta | `type_checker.cpp::whnf_core`, `whnf`, ordered cheap/full normalization and lazy unfolding | `Checker/ExprV2/WhnfOwned.lean`, `Knot.lean`, `DefEq/LazyDelta.lean`: one full-state callback owner preserves returned state and predecessor fuel. String-literal projection still declines at baseline | Complete bounded missing rules while preserving rule order, cache mode and state |
| DefEq, irrelevance and eta | `type_checker.cpp`, `type_checker.h`: quick checks, normalization, proof irrelevance, unfolding, full-shape and symmetric eta/structure rules | `Checker/ExprV2/DefEq.lean`, `DefEq/ProofIrrelevance.lean`, `FullShape.lean`, `FinalRules.lean` now implement these ordered stages. General DefEq is no longer wholly missing | Preserve the existing owner; do not build another partial equality checker |
| Universes | `level.cpp::is_equivalent`: normalized level equality | `Core/Level.lean::psKernelLevelEquivalent` compares normalized levels, including successor offsets across max | Retain semantics and conformance controls; no new defect reproduced in inspected rules |
| Substitution, lifting and binders | `instantiate`, `abstract`, `lift_loose_bvars` exploit sharing and metadata | `Core/ExprV2/Transform*.lean`, `Lift.lean`: direct ID transforms, memoized by source/offset/budget or source/cutoff/amount. Memos are linear lists | Preserve effective-budget key and binder scope. Replace lookup cost before changing substitution semantics |
| Inductives, K and iota | `inductive.cpp`, `inductive.h::to_cnstr_when_K`, nested-inductive compilation/checking | `RecursorK.lean`, `RecursorMajor.lean`, `Recursor.lean` preserve infer → type-WHNF → family/index guard → candidate infer → DefEq; K uses major-type universes and precedes constructor shortcut. Ordinary owned recursors work; mutual/nested generated ownership is incomplete | Extend metadata only after checked admission. Migrate ordinary admission before mutual/nested DAG admission |
| Environment and admission | `environment`, `declaration`, `inductive`: privately checked declaration construction and atomic publication | `Admission/**`, `API/DagAdmission.lean`: checked private environments and atomic results; ordinary/mutual/nested inductive and Quot admission still use V1 whole-operation path. `DagGenerated.lean` imports checked ordinary recursor metadata recursively | One checked metadata bridge; no exporter metadata as authority. Complete ownership before removing fallback |
| Semantic caches and local context | Separate checked/infer-only caches, mode-sensitive WHNF, scoped environment ownership | `CheckState.lean` carries seven fields, restores semantic caches on scope exit, excludes FVars and checked app/lam/forall from inference caching. Safe but loses reuse on shared checked binder terms. All V2 semantic indexes are lists | Specify owner/context/mode keys before expanding cache eligibility. Never simply enable caching by ID |
| Fuel, stack and runtime | Native kernel has its own recursion/resource controls; no claim of identical bounded procedure | PS fuel is a recursive bound, not an instruction counter; each owning callback has fixed predecessor fuel. Generated TypeScript execution adds generator/closure/WeakMap costs and host failure modes | Do not raise/reset fuel to accept Church. Attribute the first exhausted owning operation; optimize a justified path |

Lean's `type_checker.h` explicitly explains why successful DefEq pairs must **not** be promoted to a transitive union-find relation: its bounded/incomplete procedure is not transitive as a decision result. PS's symmetric pair cache should remain pairwise. A false shortcut cache only suppresses repeating that shortcut; it is not evidence of inequality.

### Inspected semantic alignments

`DefEq/ProofIrrelevance.lean` follows infer(left), test normalized-zero proposition type, infer(right), then DefEq(types), preserving infer-only versus checked judgments. `DefEq/FullShape.lean` and `FinalRules.lean` implement symmetric function and structure eta. `CheckProjection*.lean` retains family, index, Prop/data-extraction and owning-constructor checks. The inspected K conversion retains all callback state even after false equality, uses universes from the normalized major type, and separately guards expression metavariables in indices. No new false acceptance or rejection was reproduced in these inspected stages. This is a review finding, not a proof that every kernel rule is sound.

## 3. Confirmed remaining representation boundaries

There are exactly four **public whole-operation fallback families**, rather than one missing feature per textual `none`:

| Family | Production restart | Baseline triggers |
| --- | --- | --- |
| Checked inference | `API/Dag.lean::psKernelDagCheckTerminalOrOriginal` → `psKernelV1CheckExpression` | Missing/mismatched owning constant or constructor types; unsupported descendant; legacy scalar locals |
| WHNF | `API/Dag.lean::psKernelDagWhnfExpression` → `psKernelSessionWhnf` | Missing delta body or recursor ownership, String-literal projection branch, unsupported descendant |
| DefEq | `API/Dag.lean::psKernelDagIsDefEq` → `psKernelSessionIsDefEq` | Descendant WHNF/inference decline or absent environment ownership; the general ordered DefEq algorithm itself exists |
| Admission | `API/DagAdmission.lean::psKernelDagAdmitDeclaration` → `psKernelV1AdmitDeclaration` | Inductive/Quot admission and unsupported descendants during otherwise direct admission |

Specific ownership triggers live in `Checker/ExprV2/Constant.lean`, `Delta.lean`, `CheckProjection.lean`, `Recursor.lean`, and `RecursorMajor.lean`. `API/DagGenerated.lean::psKernelDagGeneratedAfterCommand` installs only ordinary-inductive recursor type/rule IDs. `API/DagDeclaration.lean` retains ordinary/mutual input IDs but not restored nested declarations. A new call starts with no refs for a preexisting checked session; that needs an explicitly checked environment-to-owner importer.

The boundary eagerly creates a recursive-expression table even for successful direct DAG work. Result nodes may be decoded again for the public recursive result type. `DagGeneratedImport` traverses source occurrences recursively without an identity memo and can expand physically shared metadata. These are confirmed costs by algorithm inspection; their individual contribution on authentic inputs is not yet isolated.

Outer `Option.none` means an unsupported complete attempt. Inner `some (.ok (state, none))` can mean a supported no-reduction/undecided stage. Old raw WHNF ABI helpers intentionally have narrower callbacks; their declines do not imply the production complete owner lacks K. Defensive `CheckLet` loose-range refusal has not been established reachable for valid closed public inputs. Stale API comments and benchmark summary strings that call all general DefEq/proof-irrelevance paths missing must not override the actual dispatch.

## 4. Selected implementation corrections

The containing correction must acquire fresh native/generated/canonical/proof/provider evidence. Parent PASS is not inherited.

### String-literal projection WHNF

At baseline `WhnfOwned.lean` normalizes a projection major, recognizes a String literal, and returns an unsupported attempt. V1 `Checker/Reduction/WhnfCore.lean` instead constructs the canonical String expression, invokes the owning public-WHNF callback, and continues ordinary projection selection.

Reuse `Checker/ExprV2/String.lean` and the existing projection selector. Thread the complete CheckState/arena and exact callback predecessor; never replace the public callback with a cheap local shortcut. Regressions must check direct `some` completion, public/core V1 differential results at small fuel/depth limits, callback errors/declines and all seven state fields. Real Init String fixtures provide official validation controls. Minimal PS fixtures without the full `String.ofList` body establish branch/state/refusal parity, not full real-prelude String normalization; retain the complete-environment conformance obligation.

### DefEq pair-list lookup closure construction

`Checker/ExprV2/DefEqPair.lean::psKernelExprV2DefEqPairFindIn` recursively builds curried argument closures for every cache candidate. `WhnfState.lean` already uses an explicit-argument worker. Introduce the same worker pattern beneath the unchanged curried ABI, preserving candidate order, symmetric structural collision checks, first error and empty-list behavior.

A frozen exact copy of the pre-change recursion supports all-input worker/ABI equality theorems. Native and generated regressions cover hits, reversed pairs, hash collisions/misses, invalid references, scope restoration, FVar exclusion and zero-fuel entry guards. The native ABBA microbenchmark measures only list scans. It does not change O(M) lookup or establish a whole-kernel speedup. A non-improving microbenchmark must be reported honestly.

### Cheap/full WHNF cache-mode isolation

Source review found a separate potential normal-cache pollution path: finish helpers in **both** V1 `Checker/Reduction/WhnfCore.lean` and V2 `Checker/ExprV2/WhnfOwned.lean` suppress publication for cheap projection mode but omit cheap recursor mode. A beta/let wrapper can therefore publish a recursor result whose major was deliberately not unfolded, then a full query can reuse it. Lean `type_checker.cpp::whnf_core` publishes only when neither cheap flag is set.

Suppress normal-core cache publication when either cheap flag is true, while preserving the helper ABI, actual reduction flags, callback sequence and default full-mode behavior. Reproduce on checked declarations using a transparent major alias, cheap warm query and full warm/cold query in one owner. Require the new regression to fail against the exact parent implementation and pass after correction. Distinguish this internal mode-crossing defect from a demonstrated public false acceptance: current production DefEq ordinarily fixes cheapRec=false, so public exploitability has not been shown.

## 5. Why performance remains behind Lean

The source supports several independent mechanisms:

1. Semantic caches, declaration refs, transform/lift memos and equality pair memos use linear lists. M distinct misses can cause O(M²) total lookup work, even when hashes differ. Collisions add structural comparisons. Replacing closures alone does not fix this complexity.
2. Checked app/lam/forall inference and FVar-dependent results are deliberately excluded from caching, while scope exit restores all semantic caches. This prevents context leaks but repeats shared binder work. A richer scoped exact-ID key is necessary before expanding eligibility.
3. Validation plus eager decode retains two representations. Generated immutable paged arrays still copy references when appending page directories; native Lean copy-on-write cannot be assumed for generated JavaScript.
4. Recursive metadata import and repeated public operations reconstruct work. Whole-batch ownership can be reused only with an explicit environment/context boundary.
5. Generated profiles show generator/closure dispatch, WeakMap/WeakCollection, megamorphic loads and DAG transform/find work. Profiles are samples, not allocation counts or independent phase timings.

Use a persistent exact-key trie/bucket index patterned after existing `Runtime/Acceleration/EnvironmentIndex.lean` and `API/DagAdmissionGuards.lean`, preserving candidate order, collision checks and scope. Reject a single growing immutable array as the general index: it trades lookup cost for generated append copying. Do not add hash-consing solely because another kernel has arenas; Lean and con-leche do not require a universal interning table to obtain sharing.

### Measured baseline regressions

The permanent `../PERFORMANCE_2026-10-21.md` preserves source4894 same-run observations, not a causal before/after comparison with3aa:

| Complete workload | V1 ms | DAG ms | Interpretation |
| --- | ---: | ---: | --- |
| Generated binder32 admission, 1 call | 260.326 | 554.792 | 2.13× slower |
| Generated chain32 admission, 2 calls | 274.984 | 414.308 | 1.51× slower |
| Generated projection8 WHNF, 3 calls | 34.584 | 52.454 | 1.52× slower |
| Generated shared-function128 WHNF, 1 call | 752.501 | 156.881 | Selected 4.80× gain |
| Native collision128 WHNF, 10 calls | 42.409 | 76.316 | 1.80× slower |

Binder32 construction costs87.211ms DAG versus0.730ms V1; peak RSS357948 versus340360KiB. Mixed gains and regressions preclude a whole-kernel speed claim. Earlier8–16× selected claims belong to their own old source.

Benchmarks use isolated ABBA workers, fresh state, actual complete public operations and separate construction/cold/warm/RSS/retained-heap observations. The admission benchmark's separate untimed direct-path check does not prove which route every timed call took. Add diagnostic route/probe attribution separately; instrumentation must not silently alter timed source. Negative retained-heap deltas are not negative allocation. Compare source-pinned baseline/candidate on the same runner before assigning causation.

## 6. Authentic Arena discrepancies and next experiments

[Full3aa Arena39622318341](https://github.com/dwijayuda/pskernel/actions/runs/39622318341) is terminal **FAIL**: all193 identities evaluated,172 matching outcomes (105 acceptance,59 kernel refusal,1 metadata refusal,7 transport refusal),2 safety-contract agreements,17 host timeouts,1 fuel exhaustion and1 unsupported nested occurrence. Official reference119298737350 passed122 acceptance/71 rejection. No false_accept/false_reject class was recorded in this finite run; incomplete outcomes cannot demonstrate correct behavior.

The machine-readable evidence is `../evidence/2026-10-21-3aa-deep-audit.json`. Full comparison artifact12358401174 zip SHA256 is `072aa1918dac0dc1911cf0ce2a10c33e630180874eab958620c7d8902f869146`. Diagnostic profile artifact12357301634 zip SHA256 is `c689498ca3da131377679c284b2a57affdc6db64a22ab3569b2131f72241f334`.

Zero-based timeout identities:23 refute-cheap-last;72 init-prelude;78 app-lam;80 beta-ladder;82 discarded-argument-match;83 discarded-argument;84 folded-constant-first;85 folded-constant-last;86 fueled-chain;87 grind-ring-5;90 let-ladder;91/92 magma-list-deep-n21/n36;93/94 magma-list-pair-n21/n7;96 shared-subterm;98 unroll-versus-evaluate. Index81 Church exhausts fuel; index16 rec-missing-ih reports unsupported nested recursive occurrences. Console case numbers are one-based.

All17 timeouts reached kernel admission. Init entered at2.832s with54535 nodes/1774 commands; grind-ring-5 at7.888s with180991 nodes/2182 commands. Construction matters, but it is not the sole timeout cause. Diagnostic39622318432 successfully collected profiles; repeated-subproblem accepted, stuck-Prop projection rejected, Church exhausted fuel and Init timed out in both profiled/unprofiled runs. This collection PASS is not Arena qualification. The2048MiB V8 old-space cap is not an operating-system RSS cap.

### Church: do the narrower native experiment next

Historical native diagnostic39620233494/job119291437634 uses harness44ca03e and exact production369bee. It admits the first three original requests, then theorem request index3 returns actual fuel exhaustion at4096 in0.690s including launch. Official Lean accepts the unchanged case. This rules out a solely generated-runtime cause, but the identical error text from `Whnf.lean` and `WhnfCore.lean` does not identify the native failure stage.

Reuse the authenticated `NativeChurchInput.lean` on `research/psc1-arena-logical-20261021`. Replay requests0..2 unmodified; mirror theorem admission's header, isProp, no-MVar/FVar, universe parameters, body-check and final-DefEq stages through the existing APIs at4096 while retaining their actual returned sessions. Compare final staged result with unmodified `psKernelV1AdmitDeclaration`. Trace only the first failing stage, preserving original body hashes and exact callbacks. The older DAG trace shows deep recursive argument descent, not an unchanged-root retry; it is not proof of a captured-callback defect or a current-carrier diagnosis. Do not reset callback fuel to force acceptance.

### Unsafe/partial contracts are a separate release blocker

`scripts/pskernel-arena435-compare.py::classify` deliberately assigns both unsafe/partial-tagged agreements to a separate contract class; `complete` requires193 `matched_` classifications. Even fixing19 resource/unsupported outcomes cannot pass this strict gate. Compare official replay's unsafe/partial policy with the independent safe-use checks on the original cases; establish the same supported typed contract or retain the blocker. Do not remove either negative case, reinterpret a timeout as rejection, or relabel the two agreements merely to turn the gate green.

## 7. Independent-kernel lessons and rejected alternatives

Pinned [con-leche b47ea19d](https://github.com/leanprover/con-leche/tree/b47ea19d6864a1fd09db6144528f91baa5c550dd) uses cached hash and pointer-fast structural comparison; `ConLeche/Cached/StateC.lean` explicitly avoids a global hash-cons table. Separate checked/infer-only and cheap/eager caches and flush environment-sensitive caches provide useful ownership lessons. This is not evidence that its full compatibility or performance equals Lean.

Pinned con-ron `4c9eaf788669f767c8242585243f0f11af27a6ad` uses compact typed/tiered arena handles, persistent/scratch lifetimes, per-operation transform memos and per-declaration semantic caches (`crates/con-ron-core/src/arena/{handle,core_state,intern}.rs`). Its FVar handles carry types; PS FVars depend on an external local context, so its cache eligibility cannot be copied unchanged.

Selected direction: retain PS's portable checked arena and full-state owner; fix missing branches and mode isolation; add exact scoped indexing; complete environment ownership; migrate admission; then remove decode/fallback and qualify performance. Rejected alternatives are a second broad representation rewrite, blanket cache eligibility, transitive DefEq caching, trusting exported recursors, fuel increases, and replacing unresolved operations with unsupported exits. Each either lacks measured justification, crosses a trust/context boundary, changes bounded semantics or weakens the supported contract.

## 8. Remaining proof and release obligations

Selected metadata, cache/scope, fuel, callback and worker equations are checked locally with explicit premises and axiom output. Full replay-validity/metadata correspondence, capture-avoiding transform refinement, ordered WHNF/DefEq correspondence, admission correctness and global logical soundness remain open. Compiler erasure/backend/runtime preservation is independent of kernel checking. No finite matrix or artifact digest substitutes for those theorems.

Release requires an explicit supported contract, exact-source terminal native/portable/canonical/generated/proof/provider gates, honest all193 Arena disposition, measured major-regression resolution and reproducible native/generated packages including readable source, declarations/maps/map sources and SHA256 manifests. Milestone A may remain available while B/C/D proceed. Follow the finite completion plan rather than restart this audit absent new evidence.
