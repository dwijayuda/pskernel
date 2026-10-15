# PSCV0 v7 — AI work state / regular-chat handoff

Updated 16 October 2026, 05:30 Jakarta (15 October 22:30 UTC). User subsequently resumed autonomous work; continue from the latest checkpoint below.

## Working contract


Repository dwijayuda/pskernel. Use GitHub connector and cloud Linux CI exclusively: no local files/checkouts/shell/build/tests/Desktop Commander. Fresh HEAD and relevant CI before writes; expected-HEAD, non-force updates. Native portable .lean and official Lean 4.35.0 kernel (eb6cafb7290e8bd5f2937522d8d804f58f02bafc). Study corresponding pinned sources/tests before each feature; document attribution. Approved foundation: propext and Quot.sound only. No sorry, unchecked admission, weakened gates, increased budgets, pskernel-core, self-hosting, compiler-source .ps migration or C5 execution. Application .ps fixtures are allowed.

Development psc0/pscv0-v7-native-lean-v1; draft PR109 targets psc0/pscv0-v7-m1-parser-ownership-v1. Keep draft, never merge. Research psc0/pscv0-v7-platform-words-research. Preserve both histories and newer development docs when integrating. Update both handoff files and roadmap/status every milestone. Interleave M2+A -> M3+B -> M4+C/D -> M5/E; current user asks to complete M2+A.


## Resumed checkpoint: isolate global operator defaults completely

User resumed work after the low-usage handoff. Native [38817100562](https://github.com/dwijayuda/pskernel/actions/runs/38817100562) at `990fba97e4a196736147460aceb780242644a244` passed compilation (including the independent pinned Lean oracle), parser/strict selected profile and all frozen assets, then stopped at source `equalityFalse`. The original arithmetic case progressed. The same high-priority global operator default still redirects two unknown operands inside relations, which intentionally do not inherit the Boolean expected type. A custom operand type alone cannot isolate a global default.

The shared backend application now contains ordinary heterogeneous multiplication with an explicitly typed scalar, retaining its value-22 runtime observation as `operatorHeterogeneousScale`. Unknown-literal default selection moved to an independent source program with an official-kernel-checked `rfl` theorem proving the selected value is22. The isolated negative default-interference check and independent native Lean oracle remain. This changes qualification ownership, not compiler semantics, supported language, gates or budgets. Full qualification remains pending; M2+A remains open.

## Prior handoff state (superseded by the checkpoint above)

- Repository: https://github.com/dwijayuda/pskernel
- Active research branch: `psc0/pscv0-v7-platform-words-research`.
- Latest implementation/test commit: `990fba97e4a196736147460aceb780242644a244`.
- Current native CI: https://github.com/dwijayuda/pskernel/actions/runs/38817100562 ; job `116704417991`. At 22:30 UTC it was IN PROGRESS at “Regenerate checked Float display and cross-width contracts”, with no failed step. Compilation (including the independent default-instance oracle), parser/strict selected-profile checks and preceding asset regeneration passed. Source/backend/performance qualification remains pending. Read fresh status before claiming success.
- Research HEAD may now be a documentation-only child containing this handoff. Distinguish that receipt from the executable/test commit above.
- Development branch `psc0/pscv0-v7-native-lean-v1` is at `ab29c91a21fa3b3d3ab0a5ba58804a3931bd08a0`, with concurrent documentation changes. Do not overwrite or reset it.
- Draft PR109: https://github.com/dwijayuda/pskernel/pull/109 . Base `psc0/pscv0-v7-m1-parser-ownership-v1`. Keep draft; do not merge.

## Selected profile and last qualified baseline

Current research profile `pscv0-v7-native-bounded/73`: 3599 declarations independently confirmed by strict native audit.
Declaration FNV `10704736494700616048`.
Declaration SHA256 `a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f`.
Selected surface v3 SHA256 `117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8`.
Do not guess remaining class/instance/default counts; obtain them from the final manifest.

Independent F3/F4/platform logical replay https://github.com/dwijayuda/pskernel/actions/runs/38815020141 passed at `515894a39e6c272dd472f64f6cef5f247cfd705f`. Later changes through 990fba97 are qualification fixtures/docs, not compiler implementation or frozen assets.

Last fully qualified development executable: `f1bb4bb810b2397a42ee5d04e4cc2af7dfc4c9d3`; receipt `4fedd6cab8236c5f0f0a16dcffe8f7e10402972e`.
Native all32 https://github.com/dwijayuda/pskernel/actions/runs/38793307283 ; F1/F2/F3-F4 runs `38793307234/38793307180/38793307143` all passed. 978 shared JS/TS/Rust observations, GC Wasm/core/components, native Wasmtime/postreturn, source/official kernel/module/assets/performance. This is bounded qualification, not full v7 or global semantics preservation.

## Coherent research implementation awaiting full qualification

1. Explicit 32/64 target words: target width in API/CLI/IR/origins; logical platform width remains abstract. Shared word dictionaries, casts/order/shifts/power/abs; native 64-bit and fixed 32-bit oracles, JS/TS/Rust/GC/component paths.
2. Array.filter: checked universe-polymorphic model, predicate-first/default start-stop API; one-pass backend implementations, GC persistence.
3. Structural scoped instance keys: pinned SynthInstance MkTableKey approach, masked outputs, bounded beta/zeta/permitted delta/level normalization, exact collision checks, fresh checked answer replay. No pairwise same-class DefEq scan; existing scheduling/priorities/rollback/budgets retained.
4. Strict UTF8: checked total source model and String/ByteArray APIs; shared validator semantics across JS/TS/Rust and GC/explicit ABI boundaries; 19 native vectors and 48 shared observations.
5. Constructive logic/order and Int equality: checked native definitions and dictionary registration; conditional Decidable and Prop-to-Bool work belongs to the common scoped synthetic queue.
6. Operators: source trees retain unary/binary/right-action/relation identity; leaves elaborate once; read-only maximal-type/direct-Coe analysis; homogeneous and heterogeneous-default guards; existing ordered application engine. Pow/shift protocols and typed Nat-shift/Int-pow IR across readable backends.
7. Live surface audits: actual notation, deriving, tactic and selected effect dispatch tables, strict independent ledger.
8. Source info: ordered binder groups, resolved references/projections, implicit/default/inferred-explicit insertions, dictionary evidence, saved local contexts and final assignments. Declaration/constructor/project receipts remain outside Core identity. No C5 execution.
9. Profile provenance: actual compiled module interfaces/public APIs/private identities/body exposure/import visibility/ordered instances and defaults, checked-project receipts, source graph v2 edges, selected surface v3 policies/foundation/proof prerequisites and proof-hole scan.

Design/reference notes: `psc0/docs/PSCV0_M2_OPERATOR_PROTOCOL_2026-10-16.md`, `PSCV0_M2_SOURCE_INFO_2026-10-16.md`, `PSCV0_M2_PROFILE_PROVENANCE_2026-10-16.md`, `PSCV0_M2_LIVE_SURFACE_2026-10-16.md`, `PSCV0_M2_INSTANCE_KEYS_2026-10-16.md`, and `PSCV0_M2_A_{TARGET_WORDS,ARRAY_FILTER,UTF8,LOGIC_INSTANCES}_2026-10-16.md`.
Planned shared observation count is 1069; NOT yet a confirmed all-backend pass.

## Latest diagnosis: do not repeat abandoned harness approaches

Native https://github.com/dwijayuda/pskernel/actions/runs/38815020011 at 515894a3 passed compile, strict manifest and all assets, then source qualification failed at `arithmeticModulo`. Root cause was the NEW TEST FIXTURE's global priority-1100 `HMul Nat Bag Bag`: its heterogeneous-default guard protects an unknown right operand and can choose Bag before `OfNat Bag 2` fails. Namespace membership does not scope instances. Pinned Lean reproduced the same `OfNat Bag 2` / `HAdd Bag Nat Nat` failure.

The shared runtime fixture now uses a dedicated checked `Scale` numeral type on the left of its heterogeneous default. It still tests unknown-literal default selection without redirecting unrelated Nat arithmetic. Original interference remains a separate portable refusal and independent native check. Compiler semantics and acceptance were not weakened.

The initial native rejection harnesses failed, not the compiler:
- 38816403714 at dcae2c8: tactic recovery and global default leakage.
- 38816737192 at 46ecff66: Lean's default_instance attribute is GLOBAL ONLY; run_meta is MetaM, not TermElabM.
- Final 990fba97 harness studied `Lean/Meta/Instances.lean`, `Lean/Elab/BuiltinEvalCommand.lean`, `Lean/Elab/GuardMsgs.lean`, `Lean/Elab/SyntheticMVars.lean` and upstream default tests. It uses `run_elab`, temporary `addDefaultInstance`, environment restoration in finally, no-recovery full synthesis and an expected-diagnostic guard. Compilation now PASSES. Continue the current run; do not reintroduce local default attributes or the older harnesses.

Earlier resolved runtime boundary: Int.decEq stays fully checked in Standard and lowers through exact-signature intEq. Removed only its redundant native-body runtime catalogue root (same boundary as Int.decLt/decLe); Int.instDecidableEq remains executable. Do not drag its private match proof closure into executable erasure.

## Concurrent development: preserve all four files and both histories

Development advanced from F4 receipt through 24 documentation-only commits to ab29c91a:
- `psc0/PSCV0_LANGUAGE_REFERENCE_v7.1.md`
- `psc0/README.md`
- `psc0/docs/PSCV0_V71_ITERATIVE_CONSISTENCY_AUDIT_2026-10-16.md`
- `psc0/docs/PSCV0_V71_REVISION_REAUDIT_2026-10-16.md`

The latest re-audit revises the earlier unresolved document findings; it reports no further supported document contradiction after iterative review. This is design evidence, NOT implemented or verified behavior. Do not expand the current selected profile/foundation automatically to proposed partial/fixpoint/unsafe policies. Preserve these exact current files and fresh branch history at integration. Verify whether further concurrent commits exist.

## Resume sequence

1. Fetch fresh branch HEADs and current CI38817100562. If complete, fetch job116704417991 logs and report exact failing owner or actual qualification metrics. Whole-job logs are available after completion.
2. Finish the coherent research qualification: source/kernel/solver/default/source-info/module receipts, target32/64, readable JS/TS/Rust, GC Wasm/WIT/WAT/core/components/Wasmtime and unchanged performance gates. Resolve root causes against pinned Lean; no weakened tests, budgets or foundation.
3. Review M2+A exit criteria in `psc0/docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md` against actual evidence. Selected deriving/registry/provenance completeness must be demonstrated. M2+A is still OPEN.
4. On green research, update design/status docs and both handoffs with exact SHA, counts, CI links and residual limits. Integrate into development with BOTH parent histories and all concurrent docs preserved; use fresh expected-HEAD/non-force writes.
5. Requalify exact integration HEAD (native plus applicable F1/F2/F3 replay). Update draft PR109. Then follow M2+A -> M3+B -> M4+C/D -> M5/E. General recursive/dependent deriving, full effects/proof automation, global backend preservation and C5 source reconstruction remain later work.
6. Update BOTH handoff files every completed milestone slice. Never claim complete from partial green or runtime tests alone.

## Tools and durable access

Use the GitHub connector to fetch files/ref/compare/actions/jobs/logs and create trees/commits/update refs with expected HEAD. Tools in the previous chat were `github_fetch`, `github_fetch_file`, `github_fetch_workflow_job_logs`, `github_create_tree`, `github_create_commit`, `github_update_ref`. Discover the current connector names in the new chat. Work in memory; no local filesystem or shell.

For API reads, previous connector returned JSON text in structuredContent.content; file/log reads returned raw text there. Avoid dumping full logs, generated multi-megabyte assets or full API responses. Fetch compact errors and metrics. A regular chat must not pretend it has GitHub write access; if its connector is unavailable, state that actual access blocker and request an appropriate connected environment.
