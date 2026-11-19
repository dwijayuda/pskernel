# Mutual Acquaintance: Philosophy, Mathematics, and Lean 4

> **ARCHIVED (2026-11-19):** This branch contains historical proposals numbered above v1.1.0; they are **not** the current philosophical edition. The canonical edition is [Tractatus v1.1.0](https://github.com/dwijayuda/pskernel/blob/research/mutual-acquaintance-dynamics-20261118/research/mutual-acquaintance/tractatus/Tractatus_de_Perceptione_et_Amore_ID.md). [Edition registry and preserved archives](https://github.com/dwijayuda/pskernel/blob/research/mutual-acquaintance-dynamics-20261118/research/mutual-acquaintance/editions/README.md). Historical wording below is retained for provenance; any references to “current v2” describe the state of a former draft, not today's version policy.

A stand-alone **research project** inside `dwijayuda/pskernel`, completely separate from PS0, PSV0, PSC0, and compiler qualification.

## Editorial revision (not yet the canonical research edition)

A shorter Indonesian **[Tractatus v2.0.0-draft.1](tractatus/Tractatus_de_Perceptione_et_Amore_ID_v2.md)** (66 propositions, 19 November 2026) is available with its **[revision and number-crosswalk ledger](tractatus/V2_EDITORIAL_LEDGER.md)**. This is an independently readable editorial proposal that removes repetition and strengthens the question of informed mutual choice under relational change.

**Compatibility:** The three unversioned Markdown editions, their PDFs, the 119-entry proposition index, and the Lean/paper correspondence below still refer to **v1**. Do not assume their numbering or proof claims describe v2. Translation, theorem remapping, and PDF generation for v2 remain outstanding.

## Read in order

1. **Philosophical work**: [Tractatus de Perceptione et Amore (Indonesian)](tractatus/Tractatus_de_Perceptione_et_Amore_ID.md), [English](tractatus/Tractatus_de_Perceptione_et_Amore_EN.md), [Latin](tractatus/Tractatus_de_Perceptione_et_Amore_LA.md). Latest 119-proposition edition with §6.91, §6.92 and single §7.
2. **Mathematical working draft**: [A Dynamic Epistemic Model of Mutual Acquaintance](paper/A_Dynamic_Epistemic_Model_of_Mutual_Acquaintance_WORKING_DRAFT.md), and [proposition index](paper/PROPOSITION_INDEX.md).
3. **Kernel-checked Lean 4 formalization**: [Finite core](lean/MutualAcquaintance.lean), [dynamics](lean/MutualAcquaintanceDynamics.lean), and [revelation versus change](lean/MutualAcquaintanceIdentification.lean). Lean 4.36.0 GitHub Actions [workflow](../../.github/workflows/mutual-acquaintance-lean.yml).
4. **Verification and support**: [finite checker](paper/check_finite_examples.py), [dynamic example checker](tests/check_dynamic_examples.py), [dynamics notes](notes/DYNAMICS_ADDENDUM.md), and [proof correspondence and CI evidence](research_notes.md).

For the current-state audit, theorem correspondence, literature comparison, and exact CI receipts, see [the research audit](RESEARCH_AUDIT.md).

## Reproduce

Run the Lean modules independently from `lean/`:

```sh
lean MutualAcquaintance.lean
lean MutualAcquaintanceDynamics.lean
lean MutualAcquaintanceIdentification.lean
```

On Windows PowerShell: `./verify.ps1` from the `lean/` folder.

## Limitations and versions

The mathematical writing is a **working draft**. A previous standalone research-paper version and early Lean sketch are retained under `paper/archive/`, not substituted for the current draft. The Lean code formalizes finite and deterministic toy models rather than the entire stochastic model or any empirical regularity.

**PDFs:** All four PDF snapshots are committed alongside their authoritative Markdown sources. They were regenerated and committed by the dedicated [PDF workflow](../../.github/workflows/mutual-acquaintance-pdfs.yml). If Markdown changes, the PDFs must be regenerated; the Markdown files remain the source of truth.

Do not present a successful formal proof as an empirical confirmation of the behavioral premises.
