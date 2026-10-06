# AI Work State

## Repository
- Canonical repository: `dwijayuda/pskernel`
- Proof branch: `pscv/prove-pskernel-core-v1`
- Integration branch: `psc2/selfhost-lean-kernel`
- Current proof HEAD when this state was written: `0263c550ec65f558575afd3396ee95a1de168237`
- Last known green proof checkpoint: `c521adc59916a7fed2384365db222876c2677e2b` (run #285)
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
- Last explicitly recorded fully green checkpoint remains `c521adc59916a7fed2384365db222876c2677e2b` (run #285).
- Live proof HEAD is `0263c550ec65f558575afd3396ee95a1de168237`, `fix(pskernel-core): prevent local fvars from escaping semantic caches`.
- GitHub run #304 is validating that exact head.
- Projection configuration-preservation work remains on branch; the latest proof-only Projection attempts preceding the source fix were still red.
- Concrete-checker infrastructure includes checker configuration contracts, context-state metatheory, cache/state soundness transport, Projection configuration preservation, EnsureSort/EnsureForall transport, and infer-only app-loop configuration-preservation work.
- The checked-in semantic audit remains conservative at A=44/B=9/C=19/D=7 and has not yet been refreshed for the latest checker-contract/cache-scope work.
- Integration has moved far in commit count; final proof/integration reconciliation remains required. GitHub is canonical and no proof work should be discarded.

## Current blocker
No known production-kernel semantic defect.

Immediate blocker:
- validate the full proof gate for source-fix head `0263c550ec65f558575afd3396ee95a1de168237` (run #304);
- repair proof obligations invalidated by the new shared semantic-cache eligibility policy;
- restore the full recursive proof gate before continuing checker-knot discharge.

Architectural blockers still remaining:
- close concrete checked/infer-only inference configuration contracts across all branches;
- close concrete WHNF/WHNF-core and DefEq configuration/stateful contracts for the mutually recursive checker knot;
- finish remaining DefEq final/lazy-delta/eta/proof-irrelevance and recursor/iota semantics;
- complete ordinary/mutual/nested inductive transaction refinement;
- compose the concrete checker/admission theorems into the final public implementation-refinement theorem/family;
- reconcile against current integration, rerun final proof/conformance gates, and refresh the semantic audit.

## Immediate plan
1. Validate live HEAD `686ad6b784f08e5840726c7fd97986e36cc4d01d`; treat the first failing theorem as the only immediate repair target.
2. Finish `psKernelInferAppOnlyLoopWithFuel` and checked/infer-only `psKernelInferCoreWithFuel` configuration preservation by structural/fuel induction, reusing EnsureForall/EnsureSort, projection, context-state, and cache-publication contracts.
3. Prove concrete WHNF-core/public-WHNF configuration/stateful contracts using reduction-cache publication and existing reduction semantics.
4. Prove concrete DefEq configuration/stateful soundness, prioritizing LazyDelta, FinalRules, eta/proof-irrelevance, recursor computation, and success-cache paths.
5. Compose the mutually recursive checker knot and discharge the abstract assumptions already consumed by API/session refinement theorems.
6. Complete ordinary/mutual/nested inductive admission transaction semantics and environment-extension refinement.
7. Add the final explicit implementation-refinement theorem/family and update the semantic audit.
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
