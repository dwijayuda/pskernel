# Mutual Acquaintance: Philosophy, Mathematics, and Lean 4

A stand-alone **research project** inside `dwijayuda/pskernel`, completely separate from PS0, PSV0, PSC0, and compiler qualification.

## Philosophical edition status

**Current: v1.1.0**, 116 propositions. [Read the edition registry](editions/README.md) and [frozen trilingual v1.1.0 snapshots](editions/v1.1.0/). The higher-numbered proposals **v2.0.0-draft.1** (74 propositions), **v2.0.0-draft.2** (78), and the independent **v2.0.0-draft.1-alt66** (66) are preserved in the [archive](editions/archive/), **not** recommended as current or canonical editions. Their source Git histories have also been preserved in separate archive branches.

This version-policy choice changes no Lean source, formal claim, or mathematical working paper. The repository-wide `main` branch and independent research PR have their own integration lifecycle.

## Companion consistency and verification

[**v1.1.0 companion alignment audit**](COMPANION_ALIGNMENT_v1.1.0.md) connects the philosophical propositions to paper v0.2, the current Lean modules and the independent research notes, and records scope limits and exact-source Lean CI evidence. All 20 display-math blocks of the paper were left unchanged when literary cross-references were updated. Run `python3 tests/check_edition_alignment.py` from this project directory to check the 116 IDs, trilingual snapshots, proposition index, version registry and archived v2 proposals; the same check is included in the Lean workflow.

All four PDF snapshots have now been regenerated from v1.1.0-aligned Markdown, with [source/PDF SHA-256 receipts](PDF_SOURCE_RECEIPTS.sha256) and a [successful PDF workflow run](https://github.com/dwijayuda/pskernel/actions/runs/44511575748). Rendering correctness and source consistency are **not** mathematical novelty or empirical validation.

## Read in order

1. **Philosophical work**: [Tractatus de Perceptione et Amore (Indonesian)](tractatus/Tractatus_de_Perceptione_et_Amore_ID.md), [English](tractatus/Tractatus_de_Perceptione_et_Amore_EN.md), [Latin](tractatus/Tractatus_de_Perceptione_et_Amore_LA.md). **CURRENT canonical edition: v1.1.0 (2026-11-19)** with 116 active propositions, stable historical numbering, and refined §§2.72, 4.54, and 6.93. See the [revision log](tractatus/REVISION_NOTES.md).
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

**PDFs:** The authoritative Markdown and four verified PDF snapshots were synchronized on 19 November 2026 by the dedicated [PDF workflow](../../.github/workflows/mutual-acquaintance-pdfs.yml). The [SHA-256 receipt](PDF_SOURCE_RECEIPTS.sha256) records the exact source/PDF pairs for that render. If any Markdown source changes, the snapshots must be regenerated and checked again; the Markdown remains authoritative.

Do not present a successful formal proof as an empirical confirmation of the behavioral premises.
