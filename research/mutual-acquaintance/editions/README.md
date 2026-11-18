# Tractatus de Perceptione et Amore — edition registry

**Date initiated:** 2026-11-19  
**Editorial principle:** treat the Indonesian *Tractatus* as a philosophical work in its own right. Its mathematical companion is an optional, fallible interpretation. Preserve the original voice; do not manufacture novelty or convert reflective propositions into unsupported laws.

## Versions

| Label | Status | What it refers to | Permanence |
| --- | --- | --- | --- |
| **v1.0.0-baseline** | Retrospective label, **not a historical release/tag** | [Original Indonesian Tractatus](../tractatus/Tractatus_de_Perceptione_et_Amore_ID.md) as recorded in Git commit `8cddd561986153bc443ee0b9310aacb80aeb1c38`; blob SHA `8611cb3403afa77ca59b1ac583ba806c6361ab7e` | **119 numbered propositions**; this file is not overwritten by the v2 proposal |
| **v2.0.0-draft.1** | New proposed philosophical edition, not peer-reviewed | [Indonesian treatise](./v2.0.0-draft.1/Tractatus_de_Perceptione_et_Amore_ID.md) | **74 numbered propositions**; subject to review; revision history in Git |

The labels above distinguish **editorial versions**, not software releases or claims of publication. A later stable `v2.0.0` should have a fixed commit and optionally an annotated Git tag once approved. **No tag has been created.**

## Version rules

- **MAJOR** (`1.x → 2.x`): change in the conceptual architecture, section order, or numbering that requires a proposition crosswalk.
- **MINOR** (`2.0 → 2.1`): new substantive propositions or a new interpretation without rewriting the core architecture; document remapping.
- **PATCH** (`2.0.0 → 2.0.1`): spelling, formatting, translation fixes with no substantive change; the text diff must support that claim.
- **Prerelease** (`-draft.1`, `-draft.2`): manuscript under active criticism, with no assumption of validity.
- **Canonical proposition reference:** `TDA v2.0.0-draft.1 §4.3`, never merely “4.3” in a comparative paper. The old `§6.92` and new `§4.3` are conceptually related, not identical wording.
- **No silent overwrites** of an earlier numbered edition after public citation. Commit history alone preserves changes, but a frozen edition path and a crosswalk make them intelligible.
- **Translation rule:** the Indonesian text is authoritative; make English/Latin editions only when this proposal stabilizes, and mark them clearly as translations with per-proposition consistency review. The existing EN/LA files still correspond to the older edition.

## Read in this order

1. [New v2 Indonesian Tractatus](./v2.0.0-draft.1/Tractatus_de_Perceptione_et_Amore_ID.md) — the revised philosophical work.
2. [Editor’s rationale, limits, and detailed version log](./v2.0.0-draft.1/EDITORIAL_AUDIT.md) — what changed and why.
3. [119-row proposition crosswalk](./v2.0.0-draft.1/PROPOSITION_CROSSWALK.csv) — maps **every** numbered v1 proposition to a primary v2 conceptual destination; **not** a literal line-by-line equivalence.
4. [Research programme](./v2.0.0-draft.1/RESEARCH_PROGRAM.md) — precedents, rival models, possible empirical tests, formal-methods limitations.
5. [Historical manuscript and existing mathematical paper](../tractatus/Tractatus_de_Perceptione_et_Amore_ID.md) — independent baseline, not superseded for citation purposes.

## Change log

### v2.0.0-draft.1 — 2026-11-19

**Conceptual major revision.** Condensed 119 to 74 propositions, reorganized 7 chapters while keeping a single concluding proposition in Chapter 7. The previous opening started from the distinction between person and representation, reached sufficiency in Chapter 2, preferences in Chapter 3, communication in Chapter 4, choice in Chapter 5, and relational creation late in Chapter 6. The new edition moves the epistemic/constitutive distinction to the **center (Chapter 4)** and makes decision-relative knowledge and bilateral agency explicit.

- **Consolidated:** repetitive statements about silence, uncertainty, misplaced confidence, and stated ideals; merged generic self-improvement language.
- **Retained and sharpened:** knowing enough is decision-relative (old §2.7 → new §2.3); discovery versus formation of preferences (old §3.23 → new §§3.2–3.22); felt versus accurate understanding (old §4.53 → new §4.12); joint willingness (old §5.31 → new §5.2).
- **Recentered:** old §§6.63, 6.91, 6.92 become new §§4.2–4.5, separating learning, preference changes and constitutive changes.
- **Clarified:** thin evidence is not necessarily wrong, and repeated evidence is not necessarily useless; counterfactuals are underidentified rather than unimaginable; an operative refusal may settle the permissible action without revealing every motive.
- **Removed:** suggestions of universal inscrutability, the aesthetic implication that it is noble to seek every answer, and any pretense that a trivial definitional implication is a deep psychological theorem.
- **Research companion:** rival revelation/constitution/mixed models; explicit conditions under which one restricted model could be falsified; no claim that actual compatibility was proven to be created by the interaction.
- **Original protected:** the baseline ID/EN/LA and the existing Lean 4 sources were **not edited** in this v2 branch.

### v1.0.0-baseline — retrospectively named 2026-11-19

The earlier philosophical edition: 119 numbered propositions, seven sections, concluding propositions 6.91, 6.92 and 7. Its provenance is the original Git blob above. The exact title and language are retained. This label does not imply an earlier Git tag or public release.

## Pending before v2 stable

External philosophical critique; rigorous cross-check of propositions against research claims; independent literary editing; line-by-line translation review; and publication decisions. The research plan has no collected data or new formally checked theorem. The results from previous Lean modules remain scoped to their respective source commits.
