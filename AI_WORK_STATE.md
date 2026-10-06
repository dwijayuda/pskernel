# AI Work State

## Repository
- Canonical repository: `dwijayuda/pskernel`
- Proof branch: `pscv/prove-pskernel-core-v1`
- Integration branch: `psc2/selfhost-lean-kernel`
- Current proof HEAD when this state was written: `5d0e02799c789831b62ccc7d92c5af088526e1a3`
- Last known green proof checkpoint: `91d03bca250c4e1b97a2967b403a0aced211d3eb` (run #260)
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
   - The concrete mutually recursive checker implementation discharges the stateful contracts:
     - inference result typing + output-state soundness,
     - WHNF/reduction correctness + output-state soundness,
     - true DefEq soundness + output-state soundness.
   - Cache publication, presentation equality, context extension/weakening, and freshness obligations needed by the knot proof are discharged.

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
Last checked-in audit before this state file:
- A: 44
- B: 9
- C: 19
- D: 7
- Total canonical source/proof pairs: 79

## Current blocker
Configuration-level checker contracts are the active frontier. Run #261 fails only in `Ps.KernelCore.Metatheory.CheckerContracts`, at the false branch of `psKernelDefEqFinish_preserves_configuration`: the implementation returns the original state unchanged, but the proof reconstructs the underlying conjunction instead of returning the already-typed `PsKernelCheckerConfigurationSound` hypothesis. The current checkpoint fixes that proof shape without weakening the contract.

Last known green proof checkpoint remains `91d03bca250c4e1b97a2967b403a0aced211d3eb` (run #260):
- metatheory build: 100 jobs successful;
- recursive proof tree: 84/84 PASS;
- proof check: 110 seconds.

Recently discharged prerequisites:
- semantic expression-map cache publication;
- semantic DefEq pair-cache insertion;
- canonical local-context freshness and extension;
- semantic checker-state transport under context extension;
- reduction/DefEq weakening proved externally rather than as illegal recursive constructors.

## Immediate plan
1. Prove the concrete stateful checker-knot contracts by fuel/mutual induction, using the now-green cache publication and context weakening/freshness layers.
2. Complete remaining DefEq/reduction rules needed by that induction (LazyDelta/FinalRules/recursor computation and any uncovered terminal rules).
3. Complete ordinary/mutual/nested inductive admission transactions and environment-extension refinement.
4. Compose the final public KernelContract/API soundness theorem/family with concrete checker/admission proofs, not abstract assumptions.
5. Reconcile with the current integration branch and rerun all final proof/conformance gates.
6. Refresh the semantic audit and leave only explicit TCB boundaries as assumptions.

## Work discipline
- Preserve GitHub history and concurrent proof work.
- Refresh branch head before every write if concurrent work may have landed.
- Prefer dependency-guided reusable lemmas over test-fix hunting.
- Do not change production `pskernel-core/src/**` merely to make proofs easier. If a proof exposes a real implementation defect, document it and make the smallest semantically justified source fix.
- Commit meaningful checkpoints and keep this file updated as milestones/blockers change.
