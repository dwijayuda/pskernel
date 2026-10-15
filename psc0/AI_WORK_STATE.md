# PSCV0 v7 — AI work state / regular-chat handoff

Updated 16 October 2026. This checkpoint supersedes stale pending-run instructions in earlier revisions; original receipts remain in Git history. M2+A is still OPEN.

## Working contract

Repository `dwijayuda/pskernel`, the user's own public compiler/formal-verification project. GitHub connector and cloud Linux CI exclusively: no local files, checkouts, shell, builds, tests or Desktop Commander. Native portable `.lean`; official Lean 4.35.0 kernel at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study corresponding pinned sources/tests before substantial changes and document attribution. Approved logical assumptions: `propext` and `Quot.sound` only. No sorry, unchecked admission, relaxed gates, increased budgets, pskernel-core, self-hosting, compiler-source `.ps` migration or C5 execution. Application `.ps` fixtures are allowed. Wasm GC internally; linear memory only at explicit ABI boundaries.

Research: `psc0/pscv0-v7-platform-words-research`. Development: `psc0/pscv0-v7-native-lean-v1`. Keep PR109 open and draft with base `psc0/pscv0-v7-m1-parser-ownership-v1`; never merge. Use fresh expected-HEAD/non-force updates and preserve both histories. Interleave M2+A -> M3+B -> M4+C/D -> M5/E. Current request: continue remaining M2+A toward completion. Update BOTH this file and `AI_CONTINUE_PROMPT.md` at every completed milestone slice, plus relevant status/design evidence.

## Current slice: platform width's polymorphic result layout

This commit corrects `PsPlatformRuntime.erase` for `System.Platform.getNumBits`. The old caller used `psErasureSingleRuntimeField`, which intentionally rejects every generic layout, even though the caller constructs a `Subtype Nat` record with one type argument. It now obtains the prepared Subtype layout and requires one type parameter, one physical field of that parameter's type, and a non-unboxed representation. Actual prepared names and the explicit Nat type argument are retained. The monomorphic helper remains unchanged.

Studied pinned `Init/Prelude.lean` getNumBits/numBits/numBits_eq and `Lean/Compiler/LCNF/ToImpureType.lean` irrelevance/trivial structures/constructor layout, plus PSC0 preparation. The logical opaque inhabitant is not unfolded or specialized; only the explicit execution profile selects 32/64. The Unit argument remains evaluated once. No new assumptions, registry changes, weakened assertions or increased budgets.

Design/status: `psc0/docs/PSCV0_M2_PLATFORM_SUBTYPE_LAYOUT_2026-10-16.md`. This source change and both handoffs are submitted together. Fetch the resulting implementation SHA and new native run after pushing; compilation/backend qualification of this correction is not yet claimed. Existing tests and workflows are unchanged.

## Latest observed qualification

- Previous executable: `be634b576572ab2fa4ba43962abec67f1ee6eec5`; documentation child/base for this slice: `414f08be74489380b7742c6f062e97aa35749789`.
- Native run: https://github.com/dwijayuda/pskernel/actions/runs/38821837990 ; job `116719998782`; completed FAILURE.
- Compilation, parser/native checked cases, all preceding logical asset steps, checked source/Standard qualification and real three-module emission PASSED.
- GC core/component qualification stopped before Wasm execution when the explicit 32-bit application reported `PSCV0-ERASURE: unsupported runtime term (in checkGetWidth)`.
- Later TypeScript/Rust application, native Wasmtime and performance steps were skipped. This is not full backend qualification, and 1069 planned shared observations are not a confirmed all-backend pass.
- Independent F3/F4/platform replay for that executable: https://github.com/dwijayuda/pskernel/actions/runs/38821837988 . Inspect its status independently; this receipt does not infer it from native asset steps.
- GitHub write actions are available. Use create-tree/create-commit/expected-HEAD update-ref rather than repeating the earlier no-write-access claim.

## Prior completed source correction: tactic-owned synthesis

The preceding `be634b5` change introduced `psProofWithTermSynthesis` in `Ps/Elab/Proof.lean`. It isolates and drains a tactic-owned pending segment, restores caller pending work/postponement mode, and retains checked assignments/source information. `psProofExact` (including refine) and `psProofLocalValue` use it; local annotation/value work completes together. Explicit-hole rejection and goal collection remain unchanged, and outer work is not prematurely defaulted.

Reference: pinned `Lean/Elab/Tactic/ElabTerm.lean` runTermElab/closeMainGoalUsing and fresh-hole collection. Previous native38818458088 at0e739c9b failed existing semantic case67 with local unresolved holes instead of the required nested rfl diagnostic. Native38821837990 now passes the full source step without rewriting that test. Design: `psc0/docs/PSCV0_M2_TACTIC_TERM_SYNTHESIS_2026-10-16.md`. This does not imply the later backend gates passed.

## Selected profile and last fully qualified baseline

Research profile `pscv0-v7-native-bounded/73`: 3599 declarations independently observed in the strict audit. Declaration FNV `10704736494700616048`; declaration SHA256 `a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f`; selected surface v3 SHA256 `117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8`. Obtain class/ordinary-instance/default counts from the final manifest, not guesses.

Independent F3/F4/platform replay https://github.com/dwijayuda/pskernel/actions/runs/38815020141 passed at `515894a39e6c272dd472f64f6cef5f247cfd705f`. Later changes through `0e739c9b` were fixtures/docs; `be634b5` and this platform correction are real compiler changes requiring their own qualification.

Last fully qualified development executable: `f1bb4bb810b2397a42ee5d04e4cc2af7dfc4c9d3`; receipt `4fedd6cab8236c5f0f0a16dcffe8f7e10402972e`. Native all32 https://github.com/dwijayuda/pskernel/actions/runs/38793307283 ; exact-executable F1/F2/F3-F4 runs `38793307234/38793307180/38793307143` passed. 978 shared JS/TS/Rust observations, GC Wasm/core/components, native Wasmtime/postreturn, source/kernel/module/assets/performance. Bounded qualification, not full v7 or global backend preservation.

## Coherent research implementation awaiting complete qualification

1. Explicit target32/64 words in API/CLI/IR/origins; abstract logical width, common dictionaries/casts/order/shifts/power/abs, native64/fixed32 oracles and readable/GC/component paths.
2. Checked universe-polymorphic Array.filter, predicate-first default start/stop API, one-pass backends and GC persistence.
3. Structural scoped instance keys based on pinned SynthInstance MkTableKey: masked outputs, bounded beta/zeta/permitted delta/level normalization, exact collision checks and fresh checked answer replay. No pairwise same-class DefEq scan; scheduling/priorities/rollback/budgets retained.
4. Checked total strict UTF8 and String/ByteArray APIs, shared readable/GC/explicit-ABI validation; 19 native vectors and 48 shared observations.
5. Constructive logic/order/Int equality with checked definitions and dictionaries; conditional Decidable and Prop-to-Bool use the common scoped queue.
6. Unary/binary/right-action/relation operator identity; leaves elaborate once, read-only maximal-type/direct-Coe analysis, homogeneous/heterogeneous-default guards, existing ordered application engine; typed Nat-shift/Int-pow across readable backends.
7. Actual live notation/deriving/tactic/effect dispatch-table audits and strict independent ledger.
8. Ordered binder groups, resolved occurrences/projections, inserted arguments/dictionaries, saved locals/final assignments; declaration/constructor/project source receipts outside Core identity. No C5 execution.
9. Actual compiled module interfaces/public APIs/private identities/body exposure/import visibility/ordered instances/defaults, checked-project receipts, source graph v2, selected surface v3 policy/foundation/proof prerequisites and proof-hole scan.

Design notes: `psc0/docs/PSCV0_M2_{OPERATOR_PROTOCOL,SOURCE_INFO,PROFILE_PROVENANCE,LIVE_SURFACE,INSTANCE_KEYS}_2026-10-16.md` and `PSCV0_M2_A_{TARGET_WORDS,ARRAY_FILTER,UTF8,LOGIC_INSTANCES}_2026-10-16.md`. Planned shared observation count1069 is not yet confirmed across all backends.

Read `psc0/docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md`. Phase A exit requires checked selected deriving handlers, scalar/collection coverage and selected-environment ownership, not just a declaration digest. M2 scheduling/retention and complete integration remain to be evidenced. Dated roadmap counts/pins do not supersede current receipts. General indexed/recursive/dependent deriving, broader data/termination, full effects/proof automation and C5 publication remain later work.

## Earlier resolved diagnoses: do not repeat

- Native38815020011 at515894a3: the shared fixture's global priority1100 HMul Nat Bag Bag interfered with arithmeticModulo. Namespaces do not scope instances; pinned Lean reproduced OfNat Bag/HAdd failure.
- Native38817100562 at990fba97: equalityFalse still encountered global-default interference despite a dedicated Scale operand.
- Shared operatorHeterogeneousScale now uses an explicit scalar, retaining value22. Unknown-literal default selection has an independent checked source program and official-kernel rfl theorem; isolated negative interference/native oracle remain.
- Native38818184051 at eece105: nested Option/Except patterns lacked expected types; 0e739c9b uses established batch/optional/Except handling and compiles.
- Old oracle attempts38816403714/38816737192 failed due recovery/global leakage and invalid local-default/run_meta usage. The retained run_elab oracle uses temporary addDefaultInstance, finally environment restoration, no-recovery synthesis and diagnostic guard. Do not restore old approaches.
- Int.decEq remains checked in Standard and lowers via exact-signature intEq. Only its redundant native-body runtime root was removed, as for Int.decLt/decLe; Int.instDecidableEq stays executable. Do not pull private match-proof closure into erasure.

## Concurrent development and integration

Freshly observed development HEAD: `e6183db9ddeeb532cdad3c3aae8c3396c99574b9`. Changes since previously inspected `da16d1ddea0a27d1f3b0549146ac6c665683edbb` have not yet been compared in this slice. Do not assume documentation-only or overwrite them. The prior comparison from ab29c91a to da16d1dd contained nine commits adding v7.2; earlier24 docs commits remain required.

Preserve all current development changes, including known files `psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md`, `psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md`, `psc0/README.md`, and BOTH `psc0/docs/PSCV0_V71_ITERATIVE_CONSISTENCY_AUDIT_2026-10-16.md` and `PSCV0_V71_REVISION_REAUDIT_2026-10-16.md`. Keep both parent histories. Newer design documents do not automatically enable partial/fixpoint/unsafe policies or widen the selected foundation. Re-fetch and compare before integration.

## Resume sequence

1. Read fresh research/development HEADs and find the new native run for this platform-layout correction; do not reuse be634b5's result as its qualification. Inspect independent38821837988 separately. Retrieve completed job logs once and extract exact errors/metrics.
2. Finish coherent source/kernel/solver/default/source-info/module/target32-64/readable/GC/component/Wasmtime/performance qualification. Resolve root causes against pinned Lean without altering refusals or budgets merely to pass.
3. Audit M2+A exits against code and evidence, including selected deriving/registry/provenance and retention. Keep M2+A open until supported.
4. On green research, record exact evidence in status/design and BOTH handoffs; integrate both histories and concurrent docs with fresh expected-HEAD/non-force updates. Never merge PR109.
5. Requalify exact integration HEAD with native and applicable F1/F2/F3-F4 replays before updating draft PR qualification claims. Runtime observations are not general semantic-preservation proofs.

## Execution notes

Use connector file/ref/compare/action/log reads and tree/commit/expected-ref writes. The native workflow operates in psc0/v7-native and excludes handoff/design-only updates from path triggers. All tests/builds run in cloud Linux CI; never use local fallbacks. Original detailed receipts remain in Git history, including the complete preceding handoff at414f08be.
