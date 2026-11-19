# A Dynamic Epistemic Model of Mutual Acquaintance — Lean 4 working formalization

This is an **independent research experiment** in `dwijayuda/pskernel`. It is not part of the PS0, PSV0, PSC0, or compiler qualification pipelines.

## Sources and scope

- `MutualAcquaintance.lean`: earlier finite Boolean and nonnegative-integer core (22 theorem declarations). The author reported a clean local compilation on Lean 4.35.0 and 4.36.0.
- `MutualAcquaintanceDynamics.lean`: v0.2 deterministic, time-indexed two-agent transition system (21 additional theorem declarations), with encounters represented as events and sequential histories represented as lists.
- `MutualAcquaintanceIdentification.lean`: exact binary filtering and a necessary and sufficient criterion for distinguishing two mechanisms by their report law. See the [research note](../notes/REVELATION_VS_CHANGE.md).
- `MutualAcquaintanceDecision.lean`: **r0.2.0-draft.1** exact equal-prior binary classification error (two report laws, common finite denominator), attainable classifier, and a permission-dependent **toy example**. The main identity is classical total-variation hypothesis testing, not a novel psychological or statistical result. See [the new research note](../advances/r0.2.0-draft.1/PERMISSION_RELATIVE_IDENTIFICATION.md). The [adaptive multi-round bound](../advances/r0.2.0-draft.1/SEQUENTIAL_BOUND.md) has **only a traditional written proof**, not a Lean proof.
- `lean-toolchain`: Lean 4.36.0. No Mathlib or other third-party dependency.
- CI workflow: `.github/workflows/mutual-acquaintance-lean.yml`.

The dynamics file models separate observations, belief updates, preference transitions, and a relational state. It includes a conditional theorem showing that **if two admissible histories have the same final individual profile but different relational states, no deterministic profile-only predictor can fit both**. A toy model supplies witnesses. The theorem is conditional; it is not an empirical discovery about people.

## Reproduce

Install Lean through elan, then from this folder:

```sh
lean --version
lean MutualAcquaintance.lean
lean MutualAcquaintanceDynamics.lean
lean MutualAcquaintanceIdentification.lean
lean MutualAcquaintanceDecision.lean
```

Successful Lean compilation with exit code 0 is required for a kernel-check claim. CI additionally publishes version and source SHA-256 values in its logs.

## Scientific limits

These are mathematical proofs about **chosen definitions and deterministic/finite toy models**. They do not verify the philosophical Tractatus itself, a general probabilistic Bayesian multi-agent model, psychological predictions, empirical validity, or scientific novelty. The paper remains a working draft. No Lean proof should be described as proving a law of romantic attraction.

See the [research audit](../RESEARCH_AUDIT.md) for theorem correspondence and exact CI receipts.
