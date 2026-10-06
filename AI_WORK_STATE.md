# AI Work State

## Repository
- Canonical repository: `dwijayuda/pskernel`
- Proof branch: `pscv/prove-pskernel-core-v1`
- Integration branch: `psc2/selfhost-lean-kernel`
- Current proof HEAD when this state was written: `69c9e3ad8459446c4110594625f86d6278851cdd`
- Last known green proof checkpoint: `69c9e3ad8459446c4110594625f86d6278851cdd` (run #277)
- Current integration HEAD observed: `637c7e77a9e52141f9ddda1af18ca11c1a874210`
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
   - Cache publication, presentation equality, context extension/weakening, freshness, environment-index refinement, and recursion-depth/configuration obligations needed by the knot proof are discharged.

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

The audit is conservative relative to newer cross-module checker-contract work; do not inflate module grades without applying the written A/B/C/D criteria.

## Current checkpoint
Run #277 is fully green at `69c9e3ad8459446c4110594625f86d6278851cdd`.

Newly established architecture since the prior checkpoint includes:
- semantic map-cache and unordered DefEq pair-cache publication laws;
- presentation-equivalence transport in typing/reduction/defeq judgments;
- local-context freshness, extension, semantic weakening, and configuration transport;
- checker configuration soundness tracking environment-index refinement, local fresh-name bounds, and all semantic caches;
- configuration-preservation across inference cache publication, WHNF/WHNF-core caching, successful DefEq caching, recursion-depth entry, eager-reduction/native-evaluator context flags, and semantic-equivalent contexts;
- final inference contract split:
  - checked inference must return a `PsKernelTypingJudgment` and preserve configuration;
  - inference-only need only preserve configuration, because the executable infer-only path intentionally skips some checked-application validation;
- public Knot wrappers already compose abstract configuration contracts into checker/API-level contracts;
- `psKernelEnsureSortWith_configuration_refines` is now proved, including the nontrivial WHNF fallback path.

## Current blocker
No mechanical blocker at this checkpoint.

The remaining blocker is architectural: prove the concrete mutually recursive checker functions satisfy the final configuration contracts, then close the remaining DefEq/reduction/inductive transaction semantics needed by those proofs.

## Immediate plan
1. Prove concrete `psKernelInferCoreWithFuel` contracts by fuel induction:
   - checked mode: `PsKernelCheckedInferenceCoreConfigurationSound`;
   - infer-only mode: `PsKernelInferOnlyCoreConfigurationPreserves`;
   using cache-hit soundness, EnsureSort, context freshness/weakening, projection/typing refinements, and concrete WHNF/DefEq contracts.
2. Prove concrete WHNF-core/public-WHNF configuration soundness using reduction-cache publication, existing reduction semantics, recursor reduction, native reduction boundaries, and context/configuration preservation.
3. Prove concrete DefEq checked/configuration soundness, prioritizing LazyDelta, FinalRules, eta/proof-irrelevance, recursor computation, and successful-cache paths.
4. Compose the mutually recursive checker knot and discharge the abstract assumptions already used by API/session theorems.
5. Complete ordinary/mutual/nested inductive admission transactions and environment-extension refinement.
6. Add the final explicit implementation-refinement theorem/family.
7. Reconcile against current integration, rerun final proof/conformance gates, and refresh the semantic audit.

## Work discipline
- Preserve GitHub history and concurrent proof work.
- Refresh the real branch tip through the GitHub commits API before every write if concurrent work may have landed.
- Prefer dependency-guided reusable lemmas and structural induction over test/fix hunting.
- Do not change production `pskernel-core/src/**` merely to make proofs easier. If a proof exposes a real implementation defect, document it and make the smallest semantically justified source fix.
- Commit meaningful checkpoints and keep this file updated as milestones/blockers change.
