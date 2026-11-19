# A Dynamic Epistemic Model of Mutual Acquaintance — Lean 4 working formalization

This is an **independent research experiment** in `dwijayuda/pskernel`. It is not part of the PS0, PSV0, PSC0, or compiler qualification pipelines.

**Philosophical correspondence (19 November 2026):** canonical *Tractatus de Perceptione et Amore* **v1.1.0**, with 116 active numbered propositions. The Lean modules remain **mathematical research companions**, not versioned philosophical editions. Their unchanged code interprets the stable core (especially §§1.12, 2.7, 3.23, 4.53, 5.31, 6.63, 6.92). The additions §§2.72, 4.54, 6.8, 6.93 have explanatory connections but no claim of a new theorem specific to those sentences. See [alignment audit](../COMPANION_ALIGNMENT_v1.1.0.md).

## Sources and scope

- `MutualAcquaintance.lean`: earlier finite Boolean and nonnegative-integer core (22 theorem declarations). The author reported a clean local compilation on Lean 4.35.0 and 4.36.0.
- `MutualAcquaintanceDynamics.lean`: v0.2 deterministic, time-indexed two-agent transition system (21 additional theorem declarations), with encounters represented as events and sequential histories represented as lists.
- `MutualAcquaintanceIdentification.lean`: exact binary filtering and a necessary and sufficient criterion for distinguishing two mechanisms by their report law. See the [research note](../notes/REVELATION_VS_CHANGE.md).
- `lean-toolchain`: Lean 4.36.0. No Mathlib or other third-party dependency.
- CI workflow: `.github/workflows/mutual-acquaintance-lean.yml`.

The dynamics file models separate observations, belief updates, preference transitions, and a relational state. It includes a conditional theorem showing that **if two admissible histories have the same final individual profile but different relational states, no deterministic profile-only predictor can fit both**. A toy model supplies witnesses. The theorem is conditional; it is not an empirical discovery about people.

## Exact-source verification provenance

The active Git blob SHA identifiers of **all three** modules match their counterparts on source commit `2734dd2c99c82f8a22792630f22c596810613d06`, which passed [GitHub Actions Linux Lean 4.36.0 run 44380993280, job 135072858943](https://github.com/dwijayuda/pskernel/actions/runs/44380993280/job/135072858943) with `LEAN_KERNEL_CHECK_OK`. This establishes historical successful compilation of those unchanged sources; it **does not** assert that CI ran successfully on the latest documentation-only branch head. The current PR-head workflow status must be checked independently.

## Reproduce

Install Lean through elan, then from this folder:

```sh
lean --version
lean MutualAcquaintance.lean
lean MutualAcquaintanceDynamics.lean
lean MutualAcquaintanceIdentification.lean
```

Successful Lean compilation with exit code 0 is required for a kernel-check claim. CI additionally publishes version and source SHA-256 values in its logs.

## Scientific limits

These are mathematical proofs about **chosen definitions and deterministic/finite toy models**. They do not verify the philosophical Tractatus itself, a general probabilistic Bayesian multi-agent model, psychological predictions, empirical validity, or scientific novelty. The paper remains a working draft. No Lean proof should be described as proving a law of romantic attraction.

See the [research audit](../RESEARCH_AUDIT.md) for theorem correspondence and exact CI receipts.
