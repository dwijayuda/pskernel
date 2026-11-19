# Mutual Acquaintance: Philosophy, Mathematics, and Lean 4

> **ARCHIVED (2026-11-19):** This branch contains historical proposals numbered above v1.1.0; they are **not** the current philosophical edition. The canonical edition is [Tractatus v1.1.0](https://github.com/dwijayuda/pskernel/blob/research/mutual-acquaintance-dynamics-20261118/research/mutual-acquaintance/tractatus/Tractatus_de_Perceptione_et_Amore_ID.md). [Edition registry and preserved archives](https://github.com/dwijayuda/pskernel/blob/research/mutual-acquaintance-dynamics-20261118/research/mutual-acquaintance/editions/README.md). Historical wording below is retained for provenance; any references to “current v2” describe the state of a former draft, not today's version policy.

A stand-alone **research project** inside `dwijayuda/pskernel`, completely separate from PS0, PSV0, PSC0, and compiler qualification.

## Philosophical editions (versioned)

**Current proposed v2.0.0-draft.2:** [read the revised Indonesian Tractatus](editions/v2.0.0-draft.2/Tractatus_de_Perceptione_et_Amore_ID.md) (**78 propositions**), [draft.2 philosophical addendum](editions/v2.0.0-draft.2/EDITORIAL_ADDENDUM.md), [draft.1 literature-grounded research programme](editions/v2.0.0-draft.1/RESEARCH_PROGRAM.md), and [119-row original→revised proposition map](editions/v2.0.0-draft.2/PROPOSITION_CROSSWALK.csv). Previous draft.1 (74 propositions) is retained without changes. The [edition registry](editions/README.md) records retrospective baseline naming and future version rules. This is a **draft**, not a peer-reviewed or empirically validated result.

**Original 119-proposition edition:** retained unchanged in `tractatus/` in Indonesian, English, and Latin. The mathematical paper and existing Lean source currently interpret the original philosophical edition, **not** the new v2 draft; correspondence is open work.

To audit the revised edition’s numbering from the repo root: `python research/mutual-acquaintance/editions/verify_edition.py`.

## New research iteration (independent of philosophical editions)

**r0.2.0-draft.1**: [research version registry](advances/README.md), [permission-relative hypothesis-testing note](advances/r0.2.0-draft.1/PERMISSION_RELATIVE_IDENTIFICATION.md), [adaptive sequential coupling bound](advances/r0.2.0-draft.1/SEQUENTIAL_BOUND.md), and [consent-safe Stage-0 pilot protocol](advances/r0.2.0-draft.1/PILOT_PROTOCOL.md). The new [Lean 4 binary decision module](lean/MutualAcquaintanceDecision.lean) proves elementary conditional error bounds and a stipulated example. Neither the numerical example nor the protocol is empirical evidence; the sequential bound is a written proof, not a Lean-checked theorem.

## Read in order

1. **Philosophical work**: [Tractatus de Perceptione et Amore (Indonesian)](tractatus/Tractatus_de_Perceptione_et_Amore_ID.md), [English](tractatus/Tractatus_de_Perceptione_et_Amore_EN.md), [Latin](tractatus/Tractatus_de_Perceptione_et_Amore_LA.md). Preserved 119-proposition source edition with §6.91, §6.92 and single §7.
2. **Mathematical working draft**: [A Dynamic Epistemic Model of Mutual Acquaintance](paper/A_Dynamic_Epistemic_Model_of_Mutual_Acquaintance_WORKING_DRAFT.md), and [proposition index](paper/PROPOSITION_INDEX.md).
3. **Kernel-checked Lean 4 formalization**: [Finite core](lean/MutualAcquaintance.lean), [dynamics](lean/MutualAcquaintanceDynamics.lean), [revelation versus change](lean/MutualAcquaintanceIdentification.lean), and [permission-relative classification](lean/MutualAcquaintanceDecision.lean). Lean 4.36.0 GitHub Actions [workflow](../../.github/workflows/mutual-acquaintance-lean.yml).
4. **Verification and support**: [finite checker](paper/check_finite_examples.py), [dynamic example checker](tests/check_dynamic_examples.py), [dynamics notes](notes/DYNAMICS_ADDENDUM.md), and [proof correspondence and CI evidence](research_notes.md).

For the current-state audit, theorem correspondence, literature comparison, and exact CI receipts, see [the research audit](RESEARCH_AUDIT.md).

## Reproduce

Run the Lean modules independently from `lean/`:

```sh
lean MutualAcquaintance.lean
lean MutualAcquaintanceDynamics.lean
lean MutualAcquaintanceIdentification.lean
lean MutualAcquaintanceDecision.lean
```

On Windows PowerShell: `./verify.ps1` from the `lean/` folder.

## Limitations and versions

The mathematical writing is a **working draft**. A previous standalone research-paper version and early Lean sketch are retained under `paper/archive/`, not substituted for the current draft. The Lean code formalizes finite and deterministic toy models rather than the entire stochastic model or any empirical regularity.

**PDFs:** All four PDF snapshots are committed alongside their authoritative Markdown sources. They were regenerated and committed by the dedicated [PDF workflow](../../.github/workflows/mutual-acquaintance-pdfs.yml). If Markdown changes, the PDFs must be regenerated; the Markdown files remain the source of truth.

Do not present a successful formal proof as an empirical confirmation of the behavioral premises.
