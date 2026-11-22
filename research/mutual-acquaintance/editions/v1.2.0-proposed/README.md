# Tractatus de Perceptione et Amore — v1.2.0 (proposed)

**Editorial candidate, 23 November 2026. Not the canonical edition.** The canonical edition remains [v1.1.0](../v1.1.0/); no canonical working text or frozen version was overwritten.

This proposed edition incorporates the eight additional propositions in the separately prepared Markdown + LaTeX v1.2.0 research draft, plus the specifically approved §§6.95, 6.96, and a rewritten Chapter 7. It has **126** numbered propositions in each language: 116 identifiers from v1.1.0 (115 original proposition texts preserved verbatim and §7 replaced) and ten additions. The Chapter 6 title was already `Tentang perubahan dan kemungkinan yang belum dialami` in the source edition and is retained.

- [Indonesian — source text](Tractatus_de_Perceptione_et_Amore_ID.md)
- [English — working translation](Tractatus_de_Perceptione_et_Amore_EN.md)
- [Latin — unreviewed working translation](Tractatus_de_Perceptione_et_Amore_LA.md)
- [Editorial ledger and interpretive limits](EDITORIAL_AUDIT.md)
- [Full 126-proposition companion correspondence](COMPANION_ALIGNMENT_v0.4.md)

## Explicit approval implemented (ID)

> **6.95** Apa yang dikatakan seseorang tentang dirinya atau orang lain adalah bagian dari apa yang dapat kita ketahui, tetapi bukan keseluruhannya.
>
> **6.96** Ada hal yang dapat diketahui melalui penjelasan, ada yang baru tampak melalui tindakan dan pengalaman bersama. Namun apa yang tampak pun tidak selalu menentukan seluruh maksud atau sebabnya.
>
> **7.** Tentang apa yang belum dapat kita ketahui, kita tidak boleh berbicara seolah telah mengetahuinya.

The final heading is **7. Tentang batas pengetahuan**. These are philosophical propositions, not Lean theorems or claims that conduct uniquely identifies another person's private intention. An action can provide evidence without determining its hidden cause. The `saying/showing` vocabulary is an interpretive analogy, **not** the same as Wittgenstein's technical logic of showing.

**Companion status:** Existing [Mathematical Companion v0.3](../../companion/Mathematical_Companion_v0.3_EN.md) and [technical working draft v0.2](../../paper/A_Dynamic_Epistemic_Model_of_Mutual_Acquaintance_WORKING_DRAFT.md) remain unchanged and explicitly aligned to v1.1.0. The [proposed Mathematical Companion v0.4](../../companion/Mathematical_Companion_v0.4_EN.md), [126-proposition alignment](COMPANION_ALIGNMENT_v0.4.md), [multi-agent Lean source](../../lean/MultiAgentAcquaintance.lean) and finite checks have now been added to this same PR. They remain **proposed**, not the canonical companion, and their kernel verification scope is restricted to the actual Lean declarations and successful CI receipts. No empirical claim is made.

Run `python3 research/mutual-acquaintance/editions/v1.2.0-proposed/check_proposed_edition.py` to check numbering and preservation.
