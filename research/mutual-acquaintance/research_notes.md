# Research boundaries and proof correspondence

**Edition alignment (19 November 2026):** the current philosophical source is **Tractatus v1.1.0**, 116 propositions. This document's older verification receipts are **historical**, not the latest run. For current cross-references and exact-source checks see [COMPANION_ALIGNMENT_v1.1.0.md](COMPANION_ALIGNMENT_v1.1.0.md) and [the edition registry](editions/README.md). The three Lean source files are unchanged from successful [run 44380993280 / job 135072858943](https://github.com/dwijayuda/pskernel/actions/runs/44380993280/job/135072858943).


The seven *Tractatus* groups motivate the model:

1. Person versus representation;
2. identifiable evidence and decision-relative knowledge;
3. preference discovery versus preference change;
4. communication and interpretive ambiguity;
5. individual and mutual choice;
6. learning and constitutive relational change;
7. limits of statements and models.

The formalization currently establishes only finite, chosen mathematical counterparts. In particular, the v0.2 result about profile-only prediction is conditional on the existence of distinct relational states for an identical final profile, with a Boolean witness.

**Open**: normalized stochastic transitions, Bayesian filtering, general finite state spaces, long-term choices under preference revisions, statistical identifiability, comparison with existing models, and empirical validation.

**Earlier Linux CI evidence (first two modules, not the latest receipt)**: Run 44335791423, job 134912017712, commit 0a95aac365894392edc7ae470d6aaa703c21cc00; Lean 4.36.0; both Lean modules passed with exit code 0 and `LEAN_KERNEL_CHECK_OK`.

**Pinned file SHA-256**:
- `lean/MutualAcquaintance.lean`: 98439818fa421e9d9c55fcecb06dc02da48e761ecc50c1d0393ddcd46c23f2ac
- `lean/MutualAcquaintanceDynamics.lean`: df83d0d1af4e2e2bb774fff239f9975551587249fefd3ec84d7133ac76bb3d29

Do not cite CI of a prior commit as proof of additional changes. Always recheck the latest PR head's workflow status.
