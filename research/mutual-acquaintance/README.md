# Mutual Acquaintance: Philosophy, Mathematics, and Lean 4

A stand-alone **research project** inside `dwijayuda/pskernel`, completely separate from PS0, PSV0, PSC0, and compiler qualification.

## Read in order

1. **Philosophical work**: [Tractatus de Perceptione et Amore (Indonesian)](tractatus/Tractatus_de_Perceptione_et_Amore_ID.md), [English](tractatus/Tractatus_de_Perceptione_et_Amore_EN.md), [Latin](tractatus/Tractatus_de_Perceptione_et_Amore_LA.md). Latest 119-proposition edition with §6.91, §6.92 and single §7.
2. **Mathematical working draft**: [A Dynamic Epistemic Model of Mutual Acquaintance](paper/A_Dynamic_Epistemic_Model_of_Mutual_Acquaintance_WORKING_DRAFT.md), and [proposition index](paper/PROPOSITION_INDEX.md).
3. **Kernel-checked Lean 4 formalization**: [Finite core](lean/MutualAcquaintance.lean) and [dynamics](lean/MutualAcquaintanceDynamics.lean). Lean 4.36.0 GitHub Actions [workflow](../../.github/workflows/mutual-acquaintance-lean.yml).
4. **Verification and support**: [finite checker](paper/check_finite_examples.py), [dynamic example checker](tests/check_dynamic_examples.py), [dynamics notes](notes/DYNAMICS_ADDENDUM.md), and [proof correspondence and CI evidence](research_notes.md).

For the current-state audit, theorem correspondence, literature comparison, and exact CI receipts, see [the research audit](RESEARCH_AUDIT.md).

## Reproduce

Run the Lean modules independently from `lean/`:

```sh
lean MutualAcquaintance.lean
lean MutualAcquaintanceDynamics.lean
```

On Windows PowerShell: `./verify.ps1` from the `lean/` folder.

## Limitations and versions

The mathematical writing is a **working draft**. A previous standalone research-paper version and early Lean sketch are retained under `paper/archive/`, not substituted for the current draft. The Lean code formalizes finite and deterministic toy models rather than the entire stochastic model or any empirical regularity.

**PDFs:** All four PDF snapshots are committed alongside their authoritative Markdown sources. They were regenerated and committed by the dedicated [PDF workflow](../../.github/workflows/mutual-acquaintance-pdfs.yml). If Markdown changes, the PDFs must be regenerated; the Markdown files remain the source of truth.

Do not present a successful formal proof as an empirical confirmation of the behavioral premises.
