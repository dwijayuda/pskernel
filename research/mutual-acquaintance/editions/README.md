# Tractatus de Perceptione et Amore — edition registry

**Current canonical philosophical edition: v1.1.0 (19 November 2026).**

This registry is authoritative for the `research/mutual-acquaintance-dynamics-20261118` research branch. The canonical working copies are in [Indonesian](../tractatus/Tractatus_de_Perceptione_et_Amore_ID.md), [English](../tractatus/Tractatus_de_Perceptione_et_Amore_EN.md), and [Latin](../tractatus/Tractatus_de_Perceptione_et_Amore_LA.md). Frozen [v1.1.0 snapshots](v1.1.0/) preserve the edition without depending on moving working files. Indonesian is the source language; Latin has not received expert philological review.

This supersession is **editorial/version-policy only**. It does not imply peer review, empirical validation, or a novel mathematical theorem. The companion Lean models retain their explicitly limited interpretations.

## Current and historic editions

| Label | Status as of 2026-11-19 | Contents |
| --- | --- | --- |
| **v1.1.0** | **CURRENT, canonical** | [ID](v1.1.0/Tractatus_de_Perceptione_et_Amore_ID.md) · [EN](v1.1.0/Tractatus_de_Perceptione_et_Amore_EN.md) · [LA](v1.1.0/Tractatus_de_Perceptione_et_Amore_LA.md); **116** active propositions, stable numbering. Integrated by [PR #269](https://github.com/dwijayuda/pskernel/pull/269). |
| v1.0.0-baseline | Historic source (retrospective label; **not** an earlier Git release/tag) | Original **119** propositions; [source commit `8cddd561`](https://github.com/dwijayuda/pskernel/commit/8cddd561986153bc443ee0b9310aacb80aeb1c38), ID blob `8611cb3403afa77ca59b1ac583ba806c6361ab7e`. |
| **v2.0.0-draft.1** | **ARCHIVED proposal, not current** | [74-proposition manuscript](archive/v2.0.0-draft.1/Tractatus_de_Perceptione_et_Amore_ID.md), [editorial audit](archive/v2.0.0-draft.1/EDITORIAL_AUDIT.md), [crosswalk](archive/v2.0.0-draft.1/PROPOSITION_CROSSWALK.csv), [research programme](archive/v2.0.0-draft.1/RESEARCH_PROGRAM.md). ID source blob `96285c8103315775da33bc267fb726b92ff3bb51`. |
| **v2.0.0-draft.2** | **ARCHIVED proposal, not current** | [78-proposition manuscript](archive/v2.0.0-draft.2/Tractatus_de_Perceptione_et_Amore_ID.md), [addendum](archive/v2.0.0-draft.2/EDITORIAL_ADDENDUM.md), [crosswalk](archive/v2.0.0-draft.2/PROPOSITION_CROSSWALK.csv). ID source blob `7032bbb436f1e634c7264115f362b67148d0f691`. |
| **v2.0.0-draft.1-alt66** | **ARCHIVED independent alternative**, not equivalent to the 74-proposition draft.1 | [66-proposition manuscript](archive/v2.0.0-draft.1-alt66/Tractatus_de_Perceptione_et_Amore_ID.md) and [editorial ledger](archive/v2.0.0-draft.1-alt66/V2_EDITORIAL_LEDGER.md). ID source blob `6b4e99d2566ba533c62a0bdc71ca14f52ec8448d`. |

The v2 material was never merged as the canonical philosophical edition. All three v2 proposals are preserved *verbatim* under [archive/](archive/). Their complete Git-era research contexts remain independently preserved in the [v2 proposal archive branch](https://github.com/dwijayuda/pskernel/tree/archive/tractatus-v2-proposals-20261119) and [66-proposition alternative archive branch](https://github.com/dwijayuda/pskernel/tree/archive/tractatus-v2-alternative-20261119). The related experimental research iteration `r0.2.0-draft.1` was **not** a philosophical edition and is preserved in the first archive branch; it was not promoted or silently deleted.

## Versioning and citation

- Cite **`TDA v1.1.0 §6.92`**, not simply `§6.92`, whenever multiple versions are discussed.
- Preserve gaps created by retired proposition numbers. Do not silently renumber or reuse identifiers in v1.1.0.
- Archive future experimental editions before designating a new current edition.
- Minor editorial revisions should retain the character, structure and sound distinctions of the work unless a concrete reason warrants change.
- Changing the canonical edition requires an explicit version-registry update and a matching review of translations, proposition index and any claimed proof correspondence.
- The file name `Tractatus_de_Perceptione_et_Amore_ID.md` without an edition qualifier on the active research branch refers to **v1.1.0**, not to any v2 proposal.


## Companion relationship to canonical v1.1.0

The [mathematical working paper](../paper/A_Dynamic_Epistemic_Model_of_Mutual_Acquaintance_WORKING_DRAFT.md) is **v0.2** in an independent research version series, not a rival edition of the Tractatus. Its active proposition links and interpretive explanations now target **v1.1.0**. The [companion alignment audit](../COMPANION_ALIGNMENT_v1.1.0.md) documents which sources have Lean counterparts, the preserved proof-scope limits, and the unresolved PDF verification obligation. No v2 draft is active by implication from a later date or higher version string.
