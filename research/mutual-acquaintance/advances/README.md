# Research advances — separate from philosophical editions

This directory records *research iterations*, not editions of the literary
Tractatus. Changing a research argument, protocol or verified Lean module
does not silently renumber the work of philosophy.

## Version registry

| Version | Date | Status | Primary contribution |
| --- | --- | --- | --- |
| **r0.1.0-baseline** | Retrospective only | Prior working draft in the [paper/](../paper/) and [notes/](../notes/) tree | Dynamic epistemic and dyadic interpretation of the 119-proposition source; one-step and multi-round identification results and a Lean 4 development. **This label is not a historical Git release.** |
| **r0.2.0-draft.1** | 2026-11-19 | Current research extension, not reviewed | Finite binary Bayes classification error with permission-constrained encounter toy, written adaptive coupling bound, design/estimand critique and a Stage-0 pilot protocol. |

### Research iteration r0.2.0-draft.1

- [Permission-relative identifiability](r0.2.0-draft.1/PERMISSION_RELATIVE_IDENTIFICATION.md): precise one-report risk, mechanisms, causal identification, direct precedents.
- [Adaptive finite-horizon bound](r0.2.0-draft.1/SEQUENTIAL_BOUND.md): standard coupling argument, **traditional proof only**, no Lean claim.
- [Stage-0 pilot protocol](r0.2.0-draft.1/PILOT_PROTOCOL.md): clear testable target and ethical randomized-offer estimand, **not yet preregistered**.
- [Lean 4 module](../lean/MutualAcquaintanceDecision.lean): exact integer-count Bayes risk inequalities and toy bilateral approval.
- [Philosophical v2 edition](../editions/v2.0.0-draft.1/Tractatus_de_Perceptione_et_Amore_ID.md): separately versioned literary source. The existing mathematical paper remains anchored to the earlier philosophical edition unless explicitly mapped.

## Claims ledger

| Claim | Evidence | Status |
| --- | --- | --- |
| Binary testing error for a common positive denominator is exactly the total-variation Bayes error | Elementary argument in note, `every_rule_bound` and `optimal_rule_exists` in Lean | A **standard** result, verified in the specific finite Lean model once the current workflow passes |
| Passive vs jointly accepted toy signals differ in the two posited models | 6/16 vs 6/16 and 6/16 vs 10/16 numerators | Numerical stipulated witness; **not human data** |
| Finite-horizon TV bound for allowed adaptive policies | Standard coupling / union-bound argument in `SEQUENTIAL_BOUND.md` | Traditional written proof; **not Lean formalized** |
| A change in observed reporting identifies creation of a relational state | No valid evidence provided | **Not established** |
| Randomized *offer* may identify an ITT effect under suitable assumptions | Standard causal reasoning in protocol | Proposed design; no study carried out |
| Result is a substantial new theorem or validated new psychology | No supporting evidence | **Not claimed** |

## Numbering and provenance policy

- **Philosophical editions:** `vMAJOR.MINOR.PATCH[-draft.N]` in [editions/](../editions/), propositional IDs cited as `TDA v2.0.0-draft.1 §4.3`.
- **Research iterations:** `rMAJOR.MINOR.PATCH[-draft.N]` here. Increments track changes to the research framework, formal lemmas, protocols or assumptions, without implying progress toward a scientific breakthrough.
- **Lean source:** cite a **specific commit SHA**, path and exact workflow run, not just "verified" in the abstract; no file or theorem claims future reproducibility if the toolchain or dependencies change.
- **No overwrite of frozen editions** or revision-by-renaming; make a new version with a change summary, and preserve critical counterexamples and limitations.
- **No automatic promotion** from draft to an academic publication or from numerical example to empirical finding.

## Next genuinely useful research target

Establish a decision-specific, private-information, dynamically
state-changing identifiability theorem **under nontrivial two-person
action-availability constraints**. Compare to adaptive experiment
design and Blackwell's experiment ordering. If no mathematical
or empirical separation from known models is demonstrated, publish
the framework as a philosophical synthesis rather than claiming a
new scientific discovery.
