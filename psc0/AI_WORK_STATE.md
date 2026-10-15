# PSCV0 v7 — AI work state / regular-chat handoff

Updated 16 October 2026. This checkpoint supersedes stale pending-run instructions in earlier revisions; original receipts remain in Git history. M2+A is still OPEN.

## Working contract

Repository `dwijayuda/pskernel`, the user's own public compiler/formal-verification project. GitHub connector and cloud Linux CI exclusively: no local files, checkouts, shell, builds, tests or Desktop Commander. Native portable `.lean`; official Lean4.35.0 kernel at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study corresponding pinned source/tests before substantial changes and document attribution. Approved logical assumptions: `propext` and `Quot.sound` only. No sorry, unchecked admission, relaxed gates, increased budgets, pskernel-core, self-hosting, compiler-source `.ps` migration or C5 execution. Application `.ps` fixtures allowed. Wasm GC internally; linear memory only at explicit ABI boundaries.

Research `psc0/pscv0-v7-platform-words-research`; development `psc0/pscv0-v7-native-lean-v1`. Keep PR109 open/draft with base `psc0/pscv0-v7-m1-parser-ownership-v1`; never merge. Fresh expected-HEAD/non-force updates and preservation of both histories are mandatory. Order M2+A -> M3+B -> M4+C/D -> M5/E. Update BOTH this file and `AI_CONTINUE_PROMPT.md` after every completed milestone slice, plus relevant status/design evidence.

## Exact current implementation and CI

Implementation: `3405c32a7a0fdadb930b8f72c8c95f7ff7c31f53` (parent `414f08be74489380b7742c6f062e97aa35749789`). Successfully pushed to research with expected-HEAD/non-force update. This receipt is documentation-only; distinguish its HEAD from the implementation under test.

- Native https://github.com/dwijayuda/pskernel/actions/runs/38823906652 ; job `116726744360`.
- Independent F3/F4/platform https://github.com/dwijayuda/pskernel/actions/runs/38823906736 ; job `116726744576`; completed SUCCESS, including scientific/numeric, display/cross-width and abstract-platform reviews.
- Latest observed native state at this receipt: compilation, parser/native foundation checks and all preceding frozen logical asset regeneration steps PASSED. Checked source/Standard qualification was RUNNING. Module, backend, native Wasmtime and performance results were pending. Fetch fresh status; never promote a pending run.
- The existing workflow was triggered by the source push; no dispatch capability was needed. GitHub tree/commit/ref writes are verified working. Earlier no-write-access statements were wrong.

### What the implementation changes

`PsPlatformRuntime.erase` previously called `psErasureSingleRuntimeField` for `System.Platform.getNumBits`. That helper intentionally rejects generic layouts, but the caller constructs `Subtype Nat` with a type argument. The replacement inspects the existing prepared Subtype layout: exactly one type parameter, exactly one physical field of that parameter type, and non-unboxed representation. It retains actual prepared names, Nat type argument and once-only Unit evaluation. The strict monomorphic helper is unchanged for Fin/BitVec/scalar adapters. Logical opacity and explicit target32/64 selection are unchanged. No assumption, registry, frozen asset, test, workflow, expectation or budget changes.

The inspected source diff is nine additions and one deletion in `psc0/packages/erasure/src/Ps/Erasure/Platform.lean`; other changes are documentation. Studied pinned `Init/Prelude.lean` getNumBits/numBits/numBits_eq and `Lean/Compiler/LCNF/ToImpureType.lean` irrelevance/trivial structures/constructor layout, together with PSC0 layout preparation. Design: `psc0/docs/PSCV0_M2_PLATFORM_SUBTYPE_LAYOUT_2026-10-16.md`.

### Previous qualification, not a substitute for current gates

Previous executable `be634b576572ab2fa4ba43962abec67f1ee6eec5`; docs child414f08be. Native https://github.com/dwijayuda/pskernel/actions/runs/38821837990 , job116719998782, completed FAILURE. Compilation/parser/assets, checked source/Standard and real three-module emission PASSED. GC core/component qualification stopped before Wasm execution: explicit32-bit `--emit-all` reported `PSCV0-ERASURE: unsupported runtime term (in checkGetWidth)`. Later TS/Rust app, native Wasmtime and performance steps were skipped. The new code must demonstrate that this path now executes successfully.

The preceding tactic correction `psProofWithTermSynthesis` isolates/drains tactic-owned pending work before exact/refine/local-value strict hole handling, restores caller pending work/postponement mode and retains assignments/source info. It follows pinned `Lean/Elab/Tactic/ElabTerm.lean`. Existing semantic case67 at0e739c9b previously reported local holes instead of the required nested rfl diagnostic; be634b5 now passes the source gate without rewriting its assertion. Design: `PSCV0_M2_TACTIC_TERM_SYNTHESIS_2026-10-16.md`.

## M2+A exit review: do not repeat the whole inventory

Read new `psc0/docs/PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md`. It maps the existing roadmap's criteria to inspected owners/tests and distinguishes implementation inventory, prior evidence, current pending gates and later-phase work. It is NOT a completion declaration.

Inspected: exact five-handler deriving dispatch and independent parser/handler roster checks; deriving refusal tests; source-information containment and exactly-one resumed projection checks; synthetic freshening/scope/default/budget rollback assertions; instance-key structural indexing; StandardManifest's live notation/tactic/effect/class-key checks, both strict declaration hashes and surface-v3 hash, selected assumption/proof-prerequisite inventory; actual compiled project-interface encoding; the existing35-probe platform family per profile; native workflow ordering and explicit ABI lanes.

Native completion, final observed counts/metrics, whole exit reconciliation and history-preserving exact integration qualification remain mandatory. General backend preservation is not established by runtime observations. The manifest's `notYetQualified` descriptions are not permission to widen the selected scope or declare release completion.

## Selected profile and last fully qualified baseline

Research `pscv0-v7-native-bounded/73`:3599 declarations independently observed in strict audit. Declaration FNV `10704736494700616048`; declaration SHA256 `a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f`; selected surface v3 SHA256 `117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8`. Obtain class/instance/default counts from the final manifest, not guesses.

Last fully qualified development executable `f1bb4bb810b2397a42ee5d04e4cc2af7dfc4c9d3`; receipt `4fedd6cab8236c5f0f0a16dcffe8f7e10402972e`. Native https://github.com/dwijayuda/pskernel/actions/runs/38793307283 ; exact-executable F1/F2/F3-F4 runs38793307234/38793307180/38793307143 passed. 978 shared JS/TS/Rust observations, GC Wasm/core/components, native Wasmtime/postreturn, source/kernel/module/assets/performance. Bounded qualification, not full v7 or a global semantic-preservation theorem.

Earlier independent F3/F4/platform38815020141 passed at515894a39e6c272dd472f64f6cef5f247cfd705f. Changes through0e739c9b were fixtures/docs; be634b5 and3405c32a are compiler changes requiring their own qualification. Planned1069 shared observations remain NOT a confirmed all-backend pass at this receipt.

## Coherent research implementation awaiting complete qualification

1. Explicit target32/64 words in API/CLI/IR/origins; abstract logical width, shared dictionaries/casts/order/shifts/power/abs, native64/fixed32 oracles and readable/GC/component paths.
2. Checked universe-polymorphic Array.filter with predicate-first default start/stop API, one-pass backends and GC persistence.
3. Structural scoped instance keys based on pinned MkTableKey: masked outputs, bounded beta/zeta/permitted delta/level normalization, collision checks and fresh checked replay; scheduling/priorities/rollback/budgets retained.
4. Checked total strict UTF8/String/ByteArray APIs, shared readable/GC/explicit-ABI validation,19 native vectors and48 shared observations.
5. Constructive logic/order/Int equality with checked definitions/dictionaries; conditionals and Prop-to-Bool use the common scoped queue.
6. Source operator identity; leaves elaborate once, read-only maximal-type/direct-Coe analysis, homogeneous/heterogeneous-default guards, ordered application engine, typed Nat-shift/Int-pow across readable backends.
7. Actual live notation/deriving/tactic/effect dispatch audits and strict independent ledger.
8. Ordered binder groups, resolved occurrences/projections, inserted arguments/dictionaries, saved local contexts and final assignments, independent declaration/constructor/project receipts outside Core identity. No C5 execution.
9. Actual compiled interfaces/public APIs/private identities/body exposure/import visibility/ordered instances/defaults, checked-project receipts, source graph v2, surface-v3 policy/foundation/proof prerequisites and proof-hole scan.

Design notes: `psc0/docs/PSCV0_M2_{OPERATOR_PROTOCOL,SOURCE_INFO,PROFILE_PROVENANCE,LIVE_SURFACE,INSTANCE_KEYS}_2026-10-16.md` and `PSCV0_M2_A_{TARGET_WORDS,ARRAY_FILTER,UTF8,LOGIC_INSTANCES}_2026-10-16.md`. Read the unchanged `PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md` detailed Phase A exits; historical counts/pins there do not supersede current receipts. General dependent/recursive deriving, broader data/termination, full effects/proof automation and C5 publication remain later phases.

## Earlier resolved diagnoses: do not repeat

- Native38815020011 at515894a3: the shared global priority1100 HMul Nat Bag Bag fixture redirected arithmeticModulo. Namespace membership does not scope defaults; pinned Lean reproduced OfNat Bag/HAdd failure.
- Native38817100562 at990fba97: equalityFalse still encountered global-default interference despite a dedicated Scale operand. Shared operatorHeterogeneousScale now uses an explicit scalar, retaining value22. Unknown-literal selection has a separate checked source/rfl theorem; isolated negative interference/native oracle remain.
- Native38818184051 at eece105: nested Option/Except patterns lacked expected types. 0e739c9b uses the established batch/optional/Except pattern and compiles.
- Old oracle attempts38816403714/38816737192 failed due recovery/global leakage and invalid local-default/run_meta usage. Retain run_elab, temporary addDefaultInstance, finally environment restoration, no-recovery synthesis and diagnostic guard.
- Int.decEq stays fully checked in Standard and lowers via exact-signature intEq. Only its redundant native-body runtime root was removed, as for Int.decLt/decLe; Int.instDecidableEq remains executable. Do not bring private match-proof closure into erasure.

## Concurrent development: actual comparison completed

Inspected development HEAD `e6183db9ddeeb532cdad3c3aae8c3396c99574b9`. Compared with prior `da16d1ddea0a27d1f3b0549146ac6c665683edbb`: two documentation commits modify README and add `psc0/docs/PSCV0_V72_ITERATIVE_CONSISTENCY_AUDIT_2026-10-16.md` (122 lines). Earlier nine v7.2 commits and24 v7.1/README/audit commits remain required.

Actual research3405c32a/developmente6183db9 merge base: `ac3887d173347d6f39356f93b646976941212b3f`. Research was36 commits ahead/37 behind. Development changes from this base are documentation-only across TEN paths: both handoffs, v7.1 reference, v7.2 reference, README, scalar-completion note, roadmap and three audit files. Preserve the SIX current language/reference/README/audit files and reconcile the four status/handoff documents without discarding qualified F4 receipts. Preserve BOTH histories. Re-fetch and compare before integration; this list is not a license to discard future changes.

Newer v7.1/v7.2 partial/fixpoint/unsafe proposals do not automatically expand the selected profile/foundation. No development ref or PR setting was changed in this slice.

## Resume sequence

1. Fetch fresh research/development HEADs. Inspect native38823906652/job116726744360, not the older failed run. Independent38823906736 is already green. Retrieve completed logs once and extract exact failing owner or actual metrics. Do not infer native backend success from independent logical review.
2. Complete coherent source/kernel/solver/default/source-info/module/target32-64/readable/GC/component/Wasmtime/performance qualification. Resolve actual root causes against pinned Lean; preserve existing refusal/expectation/budget policy.
3. Use the new exit review to finish code/evidence reconciliation. Obtain final measured manifest/graph/runtime metrics. M2+A remains open until supported.
4. On green research, record exact evidence in BOTH handoffs/status, integrate both histories and all current development documentation with fresh expected-HEAD/non-force writes. Never merge PR109.
5. Requalify the exact integration HEAD with native and applicable independent F1/F2/F3-F4 replays before publishing completion/PR qualification claims. Continue later phases only on their documented dependencies.

All builds/tests stay in cloud Linux CI. Documentation-only handoff/design changes do not trigger the native workflow. Original detailed history remains in Git, including the preceding complete checkpoint at414f08be and the implementation-stage checkpoint at3405c32a.
