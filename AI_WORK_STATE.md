# AI Work State

## Repository
- Canonical repository: `dwijayuda/pskernel`
- Proof branch: `pscv/prove-pskernel-core-v1`
- Integration branch: `psc2/selfhost-lean-kernel`
- Current proof implementation HEAD reconciled in this state: `770223730c05f45c783a1084339bb8de37ea9180`
- Last fully registered green proof checkpoint: `7191b91df2521cfdf1c64ed464a1341fb33b052a` (run #325)
- Run #326 (`dbdbc591...`) succeeded, but it predated Lake-root registration of `CheckedInferenceConfiguration.lean` and therefore did not validate that module.
- Run #327 (`8a51ffc...`) failed after registration exposed two eager-reduce context transport errors in checked inference.
- Commit `5f46df27...` fixes those transports explicitly; run #328 is green.
- Commit `4248828...` closes projection recursion with the configuration-aware projection theorem.
- Run #329 failed because registering `CheckedProjectionConfiguration.lean` exposed proof-construction errors in that new module: WHNF-source arguments were misbound, constant-info cases were non-exhaustive, and the final projection judgment used the wrong type-WHNF expression.
- Commit `614dd4de...` repairs those projection proof skeleton issues. Commit `77022373...` simplifies the remaining impossible arity branch directly from the executable guard. Run #333 is the current intended full validation.
- Current integration HEAD last observed: `cae6b6d5fb3d50138889e1aeb74436e7b5ea5316`
- Workflow: GitHub-first only. Do not depend on local/Desktop Commander state.

## Acceptance criteria
The work is complete only when all of the following hold:

1. **Mechanical closure**
   - Every canonical `pskernel-core/src/**.lean` source has its canonical proof companion.
   - The full recursive PSKernel Core proof gate is green from the final proof HEAD.

2. **Semantic/refinement closure**
   - The Assurance Plane contains independent semantic/refinement judgments for typing, reduction, non-transitive algorithmic definitional equality, environment/history, cache/state soundness, declaration admission, and inductive admission.
   - Canonical modules are upgraded from shallow/control evidence to semantic/refinement evidence where meaningful.
   - Remaining true trust assumptions are explicitly named TCB boundaries rather than hidden assumptions.

3. **Concrete checker soundness**
   - The concrete mutually recursive checker implementation discharges the final configuration/stateful contracts:
     - checked inference returns a typed result and preserves configuration soundness,
     - infer-only preserves configuration soundness,
     - WHNF/reduction returns a valid reduction and preserves configuration soundness,
     - true DefEq is sound and preserves configuration soundness.
   - Cache publication, presentation equality, context extension/weakening, freshness, environment-index refinement, recursion-depth/configuration obligations needed by the knot proof are discharged.

4. **Admission soundness**
   - Successful ordinary declaration admission refines a well-formed semantic environment extension.
   - Quot admission refinement remains closed.
   - Ordinary, mutual, and nested inductive admission/recursor/flatten-restore transaction semantics are connected to explicit Assurance Plane predicates/judgments.

5. **Public composition**
   - Public Kernel/API/session success is connected to the concrete checker/admission soundness theorems, not merely abstract assumptions.
   - A final explicit implementation-refinement theorem/family makes the kernel soundness claim auditable.

6. **Integration reconciliation**
   - Re-sync/rebase/merge the proof work against the current integration branch without discarding proof work.
   - Re-run the full proof/conformance gates after reconciliation.
   - Update the semantic audit to the final state.

## Current semantic audit
Last checked-in audit:
- A: 44
- B: 9
- C: 19
- D: 7
- Total canonical source/proof pairs: 79

The audit is conservative relative to newer cross-module checker-contract/context work. Do not inflate module grades without applying the written A/B/C/D criteria.

## Current checkpoint
- Fully registered green checkpoint remains `7191b91df2521cfdf1c64ed464a1341fb33b052a` (run #325) until run #329 finishes.
- Configuration-aware projection semantics were added in `8a51ffc99f3a40f0847ea2121e93a9eab7100507` and registered as a Lake root in `48c5195caa9600990dd9b40537d2b8e2553bac9b`.
- Checked inference projection recursion is closed in `4248828b28f106f8cb4fbd633bce3c46aa753fbe` by deriving fixed-fuel checked-inference soundness from the induction hypothesis and feeding it to the projection configuration theorem.
- `Metatheory/CheckerComposition.lean` now exposes importable public-wrapper contracts: checked inference composes from the checked core plus WHNF/DefEq contracts, and infer-only composes from the infer-only core plus WHNF.
- Full registered PSKernel Core metatheory/proof tree is green with the concrete infer-only core configuration-preservation theorem enabled as a Lake root.
- Projection configuration and Projection semantic/refinement layers are now importable Assurance Plane modules and green.
- The 13 per-constructor inference typing refinement theorems are promoted into importable `Metatheory/InferenceTyping.lean` and green.
- `PsKernelInferOnlyCoreConfigurationPreserves whnf defeq` is now genuinely validated by the registered proof gate (the earlier run #321 was not sufficient because the module was not yet a Lake root).
- Context/configuration infrastructure is green: local-context weakening, fresh-bound monotonicity, fresh local/let configuration preservation, rec-depth transport, scope-exit cache isolation, and app-only inference configuration preservation.
- The checked-in semantic audit remains conservative at A=44/B=9/C=19/D=7 pending criteria-based refresh after concrete checker closure.

## Current blocker
Confirmed production-kernel semantic defect:
- Local-scope fvar escape through semantic caches, fixed by `0263c550ec65f558575afd3396ee95a1de168237` and now covered by the green run #312 migration.

Immediate blocker:
- validate run #333 after the checked-projection proof corrections (`614dd4de...`, `77022373...`);
- the public checked/infer-only wrapper composition is now present under `Metatheory/CheckerComposition.lean`; once the registered checked-inference/projection stack is green, proceed directly to concrete WHNF-core/public-WHNF and DefEq configuration soundness.

Architectural blockers still remaining:
- close concrete checked/infer-only inference configuration contracts across all branches;
- close concrete WHNF/WHNF-core and DefEq configuration/stateful contracts for the mutually recursive checker knot;
- finish remaining DefEq final/lazy-delta/eta/proof-irrelevance and recursor/iota semantics;
- complete ordinary/mutual/nested inductive transaction refinement;
- compose the concrete checker/admission theorems into the final public implementation-refinement theorem/family;
- reconcile against current integration, rerun final proof/conformance gates, and refresh the semantic audit.

## Immediate plan
1. Prove `PsKernelCheckedInferenceCoreConfigurationSound whnf defeq`.
2. Lift checked/infer-only core theorems through the public inference wrapper.
3. Prove concrete WHNF-core/public-WHNF configuration/stateful contracts.
4. Prove concrete DefEq configuration/stateful soundness, prioritizing LazyDelta, FinalRules, eta/proof-irrelevance, recursor computation, and success-cache paths.
5. Compose the mutually recursive checker knot and discharge the abstract assumptions already consumed by API/session refinement theorems.
6. Complete ordinary/mutual/nested inductive admission transaction semantics and environment-extension refinement.
7. Add the final explicit implementation-refinement theorem/family and refresh the semantic audit.
8. Reconcile against current integration, rerun the full proof/conformance gates, and commit the final `AI_WORK_STATE.md`.

## Work discipline
- Preserve GitHub history and concurrent proof work.
- Refresh the real branch tip through GitHub before every write if concurrent work may have landed.
- Prefer dependency-guided reusable lemmas and structural/fuel induction over test/fix hunting.
- Do not change production `pskernel-core/src/**` merely to make proofs easier. If a proof exposes a real implementation defect, document it and make the smallest semantically justified source fix.
- Commit meaningful checkpoints and keep this file updated as milestones/blockers change.

## Confirmed implementation defect: local-scope cache escape
- Proof analysis of the concrete checker knot exposed a PSKernel-specific mismatch with pinned Lean 4.34 cache assumptions.
- Lean 4.34 shares checker caches across local-context scopes because kernel free-variable IDs are globally unique internal identities and `infer_type_core` has a closed-input precondition.
- PSKernel represents `.fvar` IDs as structurally forgeable `PsKernelName` values and its raw checked-expression/session surface can receive such expressions.
- Prior behavior allowed semantic caches to contain expressions mentioning fresh child-scope fvars and later query them outside that scope.
- **Source fix committed:** `0263c550ec65f558575afd3396ee95a1de168237`.
- The fix introduces one shared semantic-cache eligibility policy rejecting keys containing any fvar and applies it consistently to:
  - inference cache lookup/publication,
  - WHNF-core cache lookup/publication,
  - public WHNF cache lookup/publication,
  - delta/unfold cache lookup/publication,
  - DefEq success-cache lookup/publication,
  - DefEq failure-cache lookup/publication.
- Cache-policy regression proofs cover direct and nested fvar keys plus pair-cache ineligibility.
- Run #304 is the first full proof-tree validation of the source fix.
- Do not weaken `PsKernelCheckerStateSemanticSound` to hide cache-scope issues.
