# PSCV0 v7 — AI work state / regular-chat handoff

Updated16 October2026. M2+A remains OPEN. This receipt supersedes stale pending-run instructions; original receipts remain in Git history.

## Working contract

User-owned public compiler/formal-verification repository `dwijayuda/pskernel`. GitHub connector and cloud Linux CI exclusively: no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`; official Lean4.35.0 at eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study pinned corresponding source/tests before substantial compiler changes. Only propext and Quot.sound as logical assumptions. No sorry/unchecked admission, weakened gates, increased budgets, pskernel-core, self-hosting, compiler-source `.ps` migration or C5 execution. Application fixtures allowed. Wasm GC internally, linear memory only explicit ABI boundaries.

Research `psc0/pscv0-v7-platform-words-research`; development `psc0/pscv0-v7-native-lean-v1`. Keep PR109 draft/open, base `psc0/pscv0-v7-m1-parser-ownership-v1`; never merge. Fresh expected-HEAD/non-force updates; preserve both histories/concurrent docs. Update BOTH this file and AI_CONTINUE_PROMPT.md each completed slice. Order M2+A -> M3+B -> M4+C/D -> M5/E.

## Current slice: exact platform ABI signature checks

Compiler implementation3405c32a7a0fdadb930b8f72c8c95f7ff7c31f53 remains unchanged. This commit corrects only two ABI-signature assertions in the existing platform harness, replacing raw WIT spelling checks with exact normalized scalar-signature checks after the existing pinned wasm-tools parse/reprint. WIT permits `%value` as the parameter name; all names/types/signedness/widths/arity and the complete WIT-vs-binary signature check are retained. No runtime expectations, test fixtures, assets, budgets or logical assumptions changed. Design and exact evidence: `docs/PSCV0_M2_WIT_SIGNATURE_QUALIFICATION_2026-10-16.md`.

Parent0ee750ee71e5264cc1fa53c3b878a8689a588d3c adds a read-only compact cloud diagnostic (run38827243885/job116737445701 SUCCESS), extracting the exact failing context without enormous source dumps. It is diagnostic infrastructure, not a qualification pass.

Native38823906652/job116726744360 at3405c32a completed FAILURE. Compiler build, parser/native checks, frozen assets, checked source/Standard and real three-module emission PASSED. GC/component step failed at platform harness line30: emitted `export %echo-unsigned: func(%value: u32) -> u32;` was compared to a regex requiring bare `value`. NOT a missing checkToIS export. The old checkGetWidth erasure error was no longer the failing point; runtime execution of that path still needs the fresh full gate. Subsequent TypeScript/Rust application, native Wasmtime and performance steps were SKIPPED.

Independent F3/F4/platform38823906736/job116726744576 at3405c32a completed SUCCESS, including scientific/numeric, display/cross-width and abstract-platform reviews. Fetch new native run for this harness commit, not the previous result. Never promote pending/partial green.

## Compiler corrections already present

3405c32a corrected `packages/erasure/src/Ps/Erasure/Platform.lean`: getNumBits produces generic Subtype Nat; validate its prepared one-parameter/one-physical-field/non-unboxed layout directly, rather than the intentionally monomorphic helper. Nat type argument, actual prepared names, once-only Unit evaluation, abstract logical width and explicit target32/64 remain intact. Pinned study: Init/Prelude.lean and Lean/Compiler/LCNF/ToImpureType.lean; note M2_PLATFORM_SUBTYPE_LAYOUT_2026-10-16.

be634b576572ab2fa4ba43962abec67f1ee6eec5 isolated tactic-owned synthesis before strict exact/refine/local-value hole checks, matching pinned Lean/Elab/Tactic/ElabTerm.lean. Source qualification now passes without rewriting the required nested-rfl refusal. Keep isolated global-default theorem/native oracle and explicit-scalar shared runtime case; do not revive abandoned default fixtures.

## Exit review and concurrency

Read `docs/PSCV0_M2_A_EXIT_REVIEW_2026-10-16.md` and roadmap rather than repeat the whole inventory. The review's native pending paragraph is superseded above. It maps deriving, scoped solver/replay/defaults, structural instance keys, source information, live registry/assumptions, real project-interface provenance and35-probe platform families to existing owners/tests. General backend preservation is not established by runtime observations.

Last inspected development e6183db9ddeeb532cdad3c3aae8c3396c99574b9; actual merge base with research3405c32a ac3887d173347d6f39356f93b646976941212b3f. Development's documentation-only changes span TEN paths: both handoffs, v7.1/v7.2 references, README, scalar-completion note, roadmap and three audits. Re-fetch/compare both heads; preserve all newer language docs, qualified F4 receipts and both parent histories. Reconcile status/handoffs/roadmap, not blind copying. Newer partial/fixpoint/unsafe proposals do not expand this selected profile automatically. No dev update or PR change made yet.

## Selected scope and remaining acceptance

Profile pscv0-v7-native-bounded/73:3599 strict declarations. Declaration FNV10704736494700616048; SHA256 a7a45451faa0d1724642590262bda91d12ff49b6f711abd2f6255f883a5a8b1f; surfacev3 SHA256117f2692ea15046020e113cd0454c5befa73479ec43e9923cafcbfc1e2031ed8. Obtain class/instance/default counts and metrics from final manifest, not guesses. Planned1069 shared observations is NOT yet confirmed all-backend. Last fully green development executable f1bb4bb810b2397a42ee5d04e4cc2af7dfc4c9d3 had978 observations, native38793307283 and applicable independent replays.

Finish fresh research native qualification across source/kernel/module/target32-64/JS/TS/Rust/GC/core/component/Wasmtime/performance; reconcile exits with actual receipts. Only then integrate both histories and all concurrent docs, qualify exact integration HEAD with native plus applicable F1/F2/F3-F4 replays, update draft PR109 and both handoffs. M2+A is still OPEN; later M3+B data/termination, M4+C/D effects/specification/proof automation, M5/E C5/global integration remain separate. GitHub writes work; existing source/harness push workflows trigger CI without dispatch.
