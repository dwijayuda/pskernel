## 2026-10-25 — Deferred-transform candidate prepared for complete qualification

The integration branch remains at the fully qualified T05 source `10144e2f9e8d223b5dcde275bd1f48d25df113b3`. This next candidate carries only the three previously prepared predecessor-binding moves in Transform, TransformSupport and Lift, their universal equality proofs, the 23 raw staged-call controls, and qualification/evidence infrastructure. No new fuel policy, public admission behavior, theorem statement, or unsafe construct is introduced.

The existing complete qualification workflow is extended in place: both source inventories contain 82 exact inputs, all 371 retained native reports and retained runtime controls remain required, three new universal equality reports bring the required total to 374, and 17 detached scripts include the new 23-assertion harness. Its new final runtime receipt follows the eight retained receipt snapshots without changing them. The native gate authenticates the entire three edited files against pinned predecessor blobs and checks the proof's frozen bodies before compilation.

Reviewed shared-bootstrap adapter `7bd3303c49bd48b17ce70fa42e7dda389a35732c` is included. The earlier A/B diagnostic [40146310517](https://github.com/dwijayuda/pskernel/actions/runs/40146310517) at `c5f0050747a2c34cabbc711305bc975c77fc6d2d` must reach a terminal state before starting the single replacement experiment. That replacement will use the same exact candidate SHA as the complete qualification, with authenticated shared translation, check and build binaries. The old diagnostic's per-checkout bootstrap translator limitation remains explicit.

**This transform candidate is not qualified.** Retrieve this commit's exact source/run before recording any result. Require native374, complete generated and canonical routes, exact 23 new assertions on each route, and the separate deferred-profile archive audit. Keep integration at `10144e2f` until those gates pass; inspect the bounded A/B observations before deciding to adopt the optimization. B remains OPEN, C remains FAIL, D remains OPEN.

## Latest checkpoint — shared bootstrap adapter prepared

Current diagnostic source `c5f0050747a2c34cabbc711305bc975c77fc6d2d` has a running A/B cohort [40146310517](https://github.com/dwijayuda/pskernel/actions/runs/40146310517), attempt 1. Fresh native job `121028288826` passed all three universal equality reports. Compiler job `121028584772` passed its 254-declaration portable check and produced shared binary SHA256 `13635a423d1343e9a4770be0b7e02d859a6b845b221a0363d19bfdfab8e3cc1c`. Both clean producer checkouts passed the early generated-leaf step by job status and are still building their complete closures; actual producer logs and measurements have not yet been inspected.

That running diagnostic uses the stock bootstrap helper, whose translation command invokes `lake exe psc1 translate` in each checkout. Its final source check/build uses the authenticated shared binary, but it does not establish that every canonical translation used that same binary. Do not report that stronger property for this cohort.

This revision prepares a temporary bootstrap adapter outside the tracked checkout. It authenticates the original bootstrap Git blob `734db05bccdd777f3cb1fa95aa9904e36caa9926`, makes exactly four checked text substitutions (two absolute helper imports, explicit checkout root, and the verified shared translator command), syntax-checks the adapter, and preserves all other collection, ordering, translation arguments, and manifest logic. The adapter and its source/binary digests are retained in the exact 18-file producer inventory and rechecked by the measurement driver. The retained bootstrap helper sources must also match the fixed baseline.

No new production or proof bodies change in this revision. It has not executed yet. Do not launch a duplicate replacement cohort while the current diagnostic is running. The current A/B result, complete source qualification, independent archive verification, and performance qualification remain pending. The notes below preserve earlier checkpoints and must not be read as newer execution evidence.

## A/B workflow wired — execution pending

The new `.github/workflows/psc1-pskernel-transform-delay-abba.yml` triggers only on its own path and the A/B driver on this isolated draft branch. It reruns source authentication and the three native proofs for the experiment SHA, builds one shared compiler, and uses clean explicit baseline/candidate kernel checkouts. Each producer checks the new 23 controls on a small generated leaf before checking and building the complete canonical kernel, then retains the DAG, paged, and 138 Arena replay controls.

Native, compiler, producer, and measurement receipts distinguish experiment, compiler, and kernel source identities and bind every intermediate file by digest. The producer jobs retain the existing 75-minute generation ceiling; the final same-runner diagnostic retains the existing 60-second per-case bound, fuel4096, empty PATH, and 2,048MiB old-space setting. All full-qualification and performance-qualification flags remain false. No A/B result exists yet.

## Bounded A/B driver prepared

`psc1/scripts/pskernel-transform-delay-abba.py` is prepared for four authentic Arena cases in fresh-process A-B-B-A order: repeated subproblem, Church numerals, Init.Prelude, and the rejected projection-of-stuck-Prop control. It pins the existing archive and case-body digests, uses the existing replay driver with fuel4096, empty PATH, 2,048MiB old-space and a 60-second per-case host bound, and compares complete semantic result fields whenever both variants finish.

The producer contract distinguishes the experiment SHA, the clean baseline/candidate kernel source SHA, and the single shared compiler source SHA. A separate compiler receipt binds the immutable native proof receipt to the compiler binary. All producer files and retained runtime controls must authenticate before measurement. Timeouts remain censored observations. This four-case diagnostic is neither the 193-case Arena qualification nor performance qualification. Producer workflow wiring and execution are still pending at this checkpoint.

## Native equality checkpoint — passed, generated/performance pending

Exact draft `d7d7b8905d6f7bb6e0044a2fcae4a33fe1424ed5` passed the native-only preflight in [40145171697](https://github.com/dwijayuda/pskernel/actions/runs/40145171697), attempt 1, job `121024847987`. The actual log contains all three ordered universal equality reports with only `propext`, `Classical.choice`, and `Quot.sound` as applicable. Source authentication confirms the three frozen bodies and exact full-file binding moves; all 186 native build jobs passed.

The proof log SHA256 is `d4149b5e52dd64256bfc68acb407fe110a436dbcfccd4faa72d26d0aa170cc4c`; the source-audit SHA256 is `6e37efc791958cf18ef5d4c4b640f73994cebe7cc4d2911ad73ddaea9c09a9fd`. The API-reported archive is `12580094440`, 4,525 bytes, SHA256 `04f193a1c779d458ef82a921be9a560e5eb5ce86dbf8b962b79ea095d9b6e4d4`; this checkpoint has not independently audited that ZIP. Exact terminal receipts and scope are recorded in `docs/qualification/T08_DEFERRED_TRANSFORM_NATIVE_d7d7b890.json`.

This is a scoped native equality result. Generated23, complete source qualification, and bounded A/B observations remain pending. Production integration still requires the complete source qualification.

# T08 deferred transform workers — prepared draft, 2026-10-25

## Status

This is an unqualified implementation draft based on `10144e2f9e8d223b5dcde275bd1f48d25df113b3`. The baseline's complete T05 generated qualification and archive audit were still running when this draft was prepared. No performance improvement, Arena compatibility result, or new qualified source is claimed.

## Native preflight correction

Initial run [40144960417](https://github.com/dwijayuda/pskernel/actions/runs/40144960417), attempt 1, at `705ec57230ae631aa6779072d0522c9d3815645e` passed the frozen-body authentication, exact three-binding-change guard, portable source/syntax checks, and native production build (186 jobs). The three successor proof cases simplified to matching expressions but lacked the final definitional-equality closure used by the retained `PsKernelKnotFuelProofs` pattern.

The repair appends `<;> rfl` to each of the three existing simplification steps. The universal theorem statements, frozen definitions, and production files are unchanged. The failed run supplies no proof qualification; a fresh exact-source native preflight is required.

## Focused production change

Move only the existing predecessor-function binding under every existing result lambda in:

- `Core/ExprV2/Transform.lean`: `psKernelExprV2TransformWithFuel`.
- `Core/ExprV2/TransformSupport.lean`: `psKernelExprV2TransformCountWithFuel`.
- `Core/ExprV2/Lift.lean`: `psKernelExprV2PagedLiftWithFuel`.

The explicit declaration arities, fuel clauses, helper calls, memo keys, state, errors, and output IDs remain the same. This addresses eager recursive function construction in generated code. TransformSpine already defers its predecessor and is unchanged.

## Gates

`PsKernelDeferredTransformProofs.lean` freezes the three original worker bodies and states universal function equalities for every fuel and arbitrary state/input, with no valid-arena or valid-memo premises. The native preflight authenticates the original Git blobs, frozen bodies, and the exact binding-only edits across all three complete source files. It requires exactly three ordered proof reports using only the standard allowed axioms.

The new generated harness has 23 assertions covering all 11 returned-function stages across three exports, raw zero/successor fuel precedence, malformed internal roots/memos, state identity, shared-child memo threading, and appended IDs. These raw equations do not establish validity for untrusted input. The retained checked-wrapper and broad transformation controls remain required.

Native preflight and JavaScript syntax checks precede expensive complete generated or performance work. The preflight is diagnostic only. Before adoption, require fresh exact-source complete native/generated/canonical qualification and archive verification, plus a bounded same-runner A/B measurement preserving Node22, Lean4.35, fuel4096, and existing limits.

## Remaining performance obligations

Historical Church tracing already locates a fuel4096 type-DefEq exhaustion. This exact-semantics change must preserve that result; it is not a claim that Church is accepted. The Init.Prelude timeout and full Arena compatibility must be measured on the new exact source. A remains qualified on its recorded source; B is OPEN, C is FAIL, D is OPEN. The replay/ArenaModel and external decoder/layout proof bridges remain open.
