# PSCV0 v7 — AI work state / regular-chat handoff

Updated 16 October 2026. This checkpoint supersedes stale pending-run instructions in earlier revisions; the original receipts remain in Git history. M2+A is still OPEN.

## Working contract

Repository `dwijayuda/pskernel`, the user's own public compiler/formal-verification project. GitHub connector and cloud Linux CI exclusively: no local files, checkouts, shell, builds, tests or Desktop Commander. Native portable `.lean`; official Lean 4.35.0 kernel at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study the corresponding pinned source/tests before substantial changes and document attribution. Approved logical assumptions: `propext` and `Quot.sound` only. No sorry, unchecked admission, relaxed gates, increased budgets, pskernel-core, self-hosting, compiler-source `.ps` migration or C5 execution. Application `.ps` fixtures are allowed. Wasm GC internally; linear memory only at explicit ABI boundaries.

Research: `psc0/pscv0-v7-platform-words-research`. Development: `psc0/pscv0-v7-native-lean-v1`. Keep PR109 open and draft, with base `psc0/pscv0-v7-m1-parser-ownership-v1`; never merge it. Use fresh expected-HEAD/non-force updates and preserve both histories. Interleave M2+A -> M3+B -> M4+C/D -> M5/E. Current request: continue remaining M2+A toward completion. Update BOTH this file and `AI_CONTINUE_PROMPT.md` at each completed milestone slice, plus relevant status/design evidence.

## Current executable candidate and live qualification

- Implementation commit: `be634b576572ab2fa4ba43962abec67f1ee6eec5`.
- Native run: https://github.com/dwijayuda/pskernel/actions/runs/38821837990 ; job `116719998782`.
- Independent F3/F4/platform logical replay: https://github.com/dwijayuda/pskernel/actions/runs/38821837988 .
- At this receipt, native compilation passed and the parser/native checked-compiler step was running. Source qualification, backend execution and performance had NOT yet passed. Read fresh status; never promote a pending run or assume a later result.
- A documentation-only child may now be research HEAD. Distinguish its SHA from the tested implementation commit above.
- GitHub create-tree/create-commit/expected-HEAD update-ref were available and successfully used in this continuation. The earlier chat's write-access blocker is no longer current.

## Implemented: tactic-owned term synthesis boundary

Previous native run https://github.com/dwijayuda/pskernel/actions/runs/38818458088 at `0e739c9be7ff81ec4c3982b632f193e66c56ec98` passed compilation, parser/strict-profile checks and every frozen logical asset replay, then failed source semantic case 67: `PSCV0-PROOF: local declaration has unresolved holes (in bad)`, instead of the required nested `rfl` diagnostic. Backend steps were skipped.

The existing case introduces `have x: Nat := 0`, then attempts `have h: x = 0 := by { rfl }`. Postponed annotation/numeral/proof work reached a strict local-hole check before being completed. The invalid proof must still be rejected at the existing expected owner; changing its diagnostic assertion would hide the boundary defect.

Studied pinned `src/Lean/Elab/Tactic/ElabTerm.lean`, especially `runTermElab`, `closeMainGoalUsing`, fresh-hole collection and the deliberately different apply scheduling. New `psProofWithTermSynthesis` in `Ps/Elab/Proof.lean` isolates and drains one tactic-owned pending segment, then restores the caller's pending work/postponement mode while retaining checked assignments and source information. `psProofExact` (including refine mode) and `psProofLocalValue` use it. The annotation and value of a local declaration are completed together. Explicit-hole rejection/goal collection remains unchanged. Outer work is not prematurely defaulted. No new solver, logical asset, assumption or larger budget.

The commit changes only `Proof.lean` (21 added lines, two replaced lines) and its design note. `Pscv0NativeTests.lean`, its phases/prefixes, every workflow and all frozen assets are unchanged. Existing exact/local/refine/focus/case, deferred proof and source-info checks remain the qualification evidence. Full confirmation is pending.

Design: `psc0/docs/PSCV0_M2_TACTIC_TERM_SYNTHESIS_2026-10-16.md`.

## Selected profile and last fully qualified baseline

Current research profile: `pscv0-v7-native-bounded/73`; 3599 declarations independently observed in the strict audit. Declaration FNV `10704736494700616048`; declaration SHA256 `a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f`; selected surface v3 SHA256 `117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8`. Obtain class/ordinary-instance/default counts from the final manifest, not by guessing.

Independent F3/F4/platform replay https://github.com/dwijayuda/pskernel/actions/runs/38815020141 passed at `515894a39e6c272dd472f64f6cef5f247cfd705f`. Later changes through `0e739c9b` were qualification fixtures/docs; `be634b5` is a real elaborator change and requires its own qualification.

Last fully qualified development executable: `f1bb4bb810b2397a42ee5d04e4cc2af7dfc4c9d3`; receipt `4fedd6cab8236c5f0f0a16dcffe8f7e10402972e`. Native all32 https://github.com/dwijayuda/pskernel/actions/runs/38793307283 ; F1/F2/F3-F4 `38793307234/38793307180/38793307143` all passed at that executable. 978 shared JS/TS/Rust observations, GC Wasm/core/components, native Wasmtime/postreturn, source/official kernel/module/assets/performance. This is bounded qualification, not full v7 or global backend preservation.

## Coherent research implementation still awaiting full qualification

1. Explicit target32/64 words in API/CLI/IR/origins; abstract logical platform width, common dictionaries/casts/order/shifts/power/abs, native64 and fixed32 oracles, readable and GC/component runtime paths.
2. Checked universe-polymorphic `Array.filter`, predicate-first API with default start/stop, one-pass backends and GC persistence.
3. Structural scoped instance keys based on pinned SynthInstance MkTableKey: masked outputs, bounded beta/zeta/permitted delta/level normalization, exact collision checks and fresh checked answer replay. No pairwise same-class DefEq scan; scheduling, priorities, rollback and budgets retained.
4. Checked total strict UTF8 model and String/ByteArray APIs, shared readable/GC/explicit-ABI validation; 19 native vectors and 48 shared observations.
5. Constructive logic/order and Int equality with checked definitions/dictionaries; conditional Decidable and Prop-to-Bool use the common scoped queue.
6. Unary/binary/right-action/relation operator identity; leaves elaborated once, read-only maximal-type/direct-Coe analysis, homogeneous/heterogeneous-default guards, existing ordered application engine; typed Nat-shift/Int-pow IR across readable backends.
7. Actual live notation/deriving/tactic/effect dispatch-table audits and strict independent ledger.
8. Ordered binder groups, resolved occurrences/projections, inserted arguments/dictionaries, saved locals/final assignments; declaration/constructor/project source receipts remain outside Core identity. No C5 execution.
9. Actual compiled module interfaces/public APIs/private identities/body exposure/import visibility/ordered instances/defaults; checked-project receipts, source-graph v2 edges, selected-surface v3 policies/foundation/proof prerequisites and proof-hole scan.

Design notes under `psc0/docs/`: `PSCV0_M2_{OPERATOR_PROTOCOL,SOURCE_INFO,PROFILE_PROVENANCE,LIVE_SURFACE,INSTANCE_KEYS}_2026-10-16.md` and `PSCV0_M2_A_{TARGET_WORDS,ARRAY_FILTER,UTF8,LOGIC_INSTANCES}_2026-10-16.md`. Planned shared observation count: 1069, NOT yet a confirmed all-backend pass.

The roadmap's Phase A exit requires checked selected deriving handlers, scalar/collection coverage and comprehensive selected environment ownership, not just a declaration digest. M2 solver scheduling/retention and complete integration remain to be evidenced. Read `PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md`; dated historical counts/pins do not supersede current receipts. General indexed/recursive/dependent deriving, broader data/termination, full effects/proof automation and C5 publication remain later work.

## Earlier resolved diagnoses: do not repeat abandoned approaches

- Native `38815020011` at `515894a3`: shared fixture's global priority-1100 `HMul Nat Bag Bag` interfered with `arithmeticModulo`. Namespace membership does not scope instances. Pinned Lean reproduced the OfNat Bag/HAdd failure.
- Native `38817100562` at `990fba97e4a196736147460aceb780242644a244`: `equalityFalse` still encountered the same global-default interference, despite a dedicated Scale operand type.
- The shared application now uses ordinary heterogeneous multiplication with an explicitly typed scalar, retaining value22 as `operatorHeterogeneousScale`. Unknown-literal default selection lives in an independent checked source program with an official-kernel-checked `rfl` theorem. The isolated negative interference case and independent Lean oracle remain.
- Native `38818184051` at `eece105251afef55109fba859222130fd8e1c078`: anonymous nested Option/Except result patterns lacked inferred inner types. `0e739c9b` uses the established ordered batch/optional/Except handling and compiles.
- Earlier oracle attempts `38816403714`/`38816737192` failed due recovery/global default leakage and invalid local-default/run_meta usage. The retained oracle uses `run_elab`, temporary `addDefaultInstance`, environment restoration in finally, no-recovery full synthesis and an expected-diagnostic guard. It compiled in `0e739c9b`; do not reintroduce local default attributes or the old harnesses.
- Int.decEq stays checked in Standard and lowers through exact-signature intEq. Only its redundant native-body runtime root was removed, as with Int.decLt/decLe. Int.instDecidableEq remains executable; do not drag private match-proof closure into erasure.

## Concurrent development: preserve five files and both histories

Latest inspected development HEAD: `da16d1ddea0a27d1f3b0549146ac6c665683edbb`; may advance. Compare from `ab29c91a21fa3b3d3ab0a5ba58804a3931bd08a0` shows nine new commits, adding only `psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md` (4347 lines). The earlier 24 documentation-only commits and all of their changes remain required.

Preserve current versions of `psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md`, `psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md`, `psc0/README.md`, and BOTH `psc0/docs/PSCV0_V71_ITERATIVE_CONSISTENCY_AUDIT_2026-10-16.md` and `PSCV0_V71_REVISION_REAUDIT_2026-10-16.md`. Do not implicitly adopt proposed partial/fixpoint/unsafe policies or change the selected foundation from these newer documents. Design revisions are not implementation or qualification evidence. Fetch fresh HEADs and compare again before integration.

## Resume sequence

1. Read fresh research/development HEADs and native38821837990/job116719998782 plus independent38821837988. Fetch completed job logs once and extract the exact diagnostic or qualification metrics. Do not repeatedly dump the old giant logs.
2. Finish coherent source/kernel/solver/default/source-info/module/target32-64/readable/GC/Wasmtime/performance qualification. Resolve genuine root causes against pinned Lean without changing expected refusals or budgets merely to pass.
3. Audit the actual M2+A exit criteria against code and evidence, including selected deriving/registry/provenance and source-retention obligations. M2+A remains open until its exits are supported.
4. On green research, publish exact evidence in design/status and BOTH handoffs. Integrate both parent histories and all concurrent docs into development using a fresh expected-HEAD/non-force update. Do not merge PR109.
5. Requalify exact integration HEAD with native and applicable F1/F2/F3-F4 replays. Only then update the draft PR's qualification claims. Continue the interleaved roadmap; never equate runtime tests with general semantic-preservation proofs.

## Tool and execution notes

GitHub tools available in this continuation include `fetch`, `fetch_file` with source line ranges, compact workflow job/step reads, completed job logs, `create_tree`, `create_commit`, `compare_commits`, and `update_ref` with expected SHA and force=false. Work through the connector, not local tools. The native workflow uses `psc0/v7-native`, builds the existing compiler/check targets, and its path filters exclude handoff/design-only updates. Report actual connector blockers rather than pretending a write or test occurred.
