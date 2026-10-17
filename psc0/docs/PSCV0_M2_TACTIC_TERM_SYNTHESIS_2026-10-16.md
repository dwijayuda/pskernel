# M2 tactic-term synthesis ownership

Date: 16 October 2026. Status: implementation candidate; full cloud qualification pending. M2+A remains open.

## Evidence and root cause

Native run 38818458088 at research commit `0e739c9be7ff81ec4c3982b632f193e66c56ec98` passed compilation, parser/profile checks and all frozen logical asset replays. Source qualification stopped at semantic case 67 with `PSCV0-PROOF: local declaration has unresolved holes`, while the unchanged test requires the nested `rfl` refusal.

The case introduces a nondependent `have x: Nat := 0`, then attempts `have h: x = 0 := by { rfl }`. Its annotation can introduce scoped numeral obligations and its nested proof can be postponed. `psProofLocalValue` previously passed this intermediate term directly to `psProofLocal`, whose strict hole check ran before the tactic-owned source continuation was resumed. This is an elaboration completion boundary defect, not evidence that the invalid proof should be admitted and not a reason to weaken the diagnostic assertion. The analogous `exact`/`refine` consumer also needs to finish synthetic elaboration before applying its existing hole policy.

## Pinned implementation reference

Studied official Lean 4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, `src/Lean/Elab/Tactic/ElabTerm.lean`, particularly `runTermElab`, `elabTerm`, `closeMainGoalUsing`, `elabTermWithHoles` and `evalApplyLikeTactic`. The first functions complete synthetic metavariable processing before inspecting fresh holes. `apply` intentionally has different scheduling because its target can constrain the elaborated term; it is not indiscriminately forced before target application.

The scheduling pattern is adapted, not copied wholesale. Upstream attribution: Apache-2.0, Microsoft Corporation, Leonardo de Moura. PSC0 continues using its own immutable scoped work queue and checked assignment/replay operations.

## Implementation and invariants

`psProofWithTermSynthesis` opens an empty pending-work segment for one tactic-owned term, runs its annotation and value together where applicable, drains that segment using the existing bounded `psElabDrainPending`, then restores the caller's pending segment and postponement mode. The current metavariable context and source-information receipts are retained. Saved lexical scopes continue to govern every resumed item. Failed attempts return an error without publishing speculative state.

Both `psProofExact` (including its existing refine mode) and `psProofLocalValue` use this boundary. No new synthesis algorithm, evaluator, proof assumption, runtime shortcut or larger resource limit is introduced. Natural explicit holes are not automatically discharged: exact still refuses unresolved holes, refine still collects goals, and local declarations still require closed terms. Existing outer work is not silently discarded or prematurely defaulted.

## Qualification

Keep `Pscv0NativeTests.lean` and all of its expected phases/diagnostic prefixes unchanged. In particular, semantic cases 67 and 68 must still refuse opaque-have reflexivity at `rfl`; the explicit local-hole case must still refuse unresolved local declarations; exact/refine/focus/case tests retain their current requirements. The existing positive checked programs, dependent proof/indexing cases, scoped resumption, source-information and registry checks must also pass.

Run the unchanged native cloud workflow through source, official-kernel, module, target32/64, JavaScript/TypeScript/Rust, GC Wasm/component/Wasmtime and performance gates. Compilation alone is not qualification. Frozen declaration/surface assets and the selected foundation are unchanged. A final CI receipt must identify the exact tested commit and any remaining failure before this candidate is called qualified.
