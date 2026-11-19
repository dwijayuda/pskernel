# Companion alignment audit — Tractatus v1.1.0

**Audit date:** 19 November 2026  
**Canonical philosophical edition:** *Tractatus de Perceptione et Amore* **v1.1.0**, Indonesian [working source](tractatus/Tractatus_de_Perceptione_et_Amore_ID.md), [frozen edition](editions/v1.1.0/Tractatus_de_Perceptione_et_Amore_ID.md), with companion [English](editions/v1.1.0/Tractatus_de_Perceptione_et_Amore_EN.md) and [Latin](editions/v1.1.0/Tractatus_de_Perceptione_et_Amore_LA.md).  
**Active propositions:** 116, seven chapters. **Retired identifiers:** 2.52, 4.31, 4.42, 5.51, 6.11, 6.52 (not reused). **Added in v1.1.0:** 2.72, 4.54, 6.93.  
**Version of mathematical companion:** working paper **v0.2**, a **separate** version series. The mathematical paper and Lean source are not the philosophical source of truth.

## Cross-companion interpretation and limits

| TDA v1.1.0 source | Paper / note | Lean counterpart | Correspondence and limit |
| --- | --- | --- | --- |
| §§1.12, 1.22, 1.31, 1.52 | Paper §1, representation and private observation | `MutualAcquaintance.lean` finite shared-signal witness; `MutualAcquaintanceDynamics.lean` agent-specific observation | Illustrates representation vs target and possible asymmetric learning; does **not** show that more encounters never improve accuracy. |
| §§2.7, **2.72** | Paper §2 and T3 decision-sufficiency result | `MutualAcquaintance.lean` fixed-decision example | New §2.72 adds value-of-information and consequence-of-error framing. The theorem is for a costless, fixed action/utility problem, not a moral or universal threshold for knowing someone enough. |
| §§3.22–3.23 | Paper §3 and C2 | Core preference-report counterexample; dynamics preference field | Distinguishes reporting/discovery/formation in an interpretation; the finite witness does not empirically classify any person's preferences. |
| §§4.53, **4.54** | Paper §4, perceived understanding and responsiveness | Silence witness (core); observation fields (dynamics) | §4.54 introduces **experienced closeness as a distinct possible result of response**. Neither the Lean model nor the paper proves a causal effect of responsive listening in humans or validates intent accuracy. |
| §§5.3–5.33 | Paper §5, definitional mutual-willingness condition and T4 bounds | `jointly_undertaken_requires_both` and willingness-bounds theorem in core | §5.32 explicitly says the mutual-willingness formula is *definitional*. No formal proof predicts actual choice or guarantees relational feasibility. |
| **§6.8**, §§6.61–6.64, 6.91–6.92 | Paper §6, passive vs active information, relational changes, history dependence | Dynamics state and order-sensitive witness; finite C4/C5 illustrations | The information-gathering action can change the modeled relational state. Negative impact in C4 is stipulated as a **counterexample**, not observed behavior or guidance to probe someone. |
| **§6.93** | Paper §6.5, one-step report contrasts and identification sensitivity; [revelation versus change](notes/REVELATION_VS_CHANGE.md), [sensitivity](notes/IDENTIFICATION_SENSITIVITY.md) | `MutualAcquaintanceIdentification.lean` restricted binary report models and calibrated/invariant-channel bounds | One report change need not identify **revelation vs formation**. Statements about moved latent mass require explicit binary-state, channel, exchangeability and consent assumptions; no general empirical identification theorem follows. |
| §7 | Paper §7 | No formal theorem | The closing literary claim is neither a theorem of ineffability nor a claim that people are permanently unknowable. |

**Mapping policy:** these are carefully scoped **interpretations**, not a proof of the philosophical sentence from a mathematical theorem. Paper sections use their **own** numeric labels (e.g. paper §6.5), which must not be mistaken for proposition numbers in the Tractatus. The [complete v1.1.0 proposition index](paper/PROPOSITION_INDEX.md) covers all 116 active literary IDs, including those with no Lean counterpart. The six retired identifiers remain available via [v1.0 provenance](editions/README.md), but are **not** claimed as active v1.1.0 sources.

## Mathematical invariance

The update to the [mathematical working draft](paper/A_Dynamic_Epistemic_Model_of_Mutual_Acquaintance_WORKING_DRAFT.md) changes its **bibliographic source label, crosswalk and explanatory paragraphs**. The **20 display-math blocks** in the source were compared with its earlier Git revision at `20f181aa150136152e815356cd8456efa1877da4`; all 20 were textually unchanged. This comparison is not an independent proof review.

The active Lean modules were **not changed** in this alignment. Their current Git blobs matched the same files in commit `2734dd2c99c82f8a22792630f22c596810613d06`, associated with successful [Linux Lean 4.36.0 run 44380993280 / job 135072858943](https://github.com/dwijayuda/pskernel/actions/runs/44380993280/job/135072858943). That job printed `LEAN_KERNEL_CHECK_OK` and the exact source SHA-256 values:

| Lean 4 module | SHA-256 from successful historical job |
| --- | --- |
| `MutualAcquaintance.lean` | `98439818fa421e9d9c55fcecb06dc02da48e761ecc50c1d0393ddcd46c23f2ac` |
| `MutualAcquaintanceDynamics.lean` | `64e6f8ce53bad966f950ce5c47fa7f4259e16f6fb1d2ca04521d7ec837f0a4ca` |
| `MutualAcquaintanceIdentification.lean` | `28d8f35e4060739d6e0c3ef22e4c5e3b7c76791d2c25a6ee178c3e20a3865baa` |

This establishes successful **historical compilation for unchanged inputs**, not CI success for the latest documentation changes. If any Lean source changes, the historical receipts must not be used for its new content. The [Lean README](lean/README.md) and [earlier audit](RESEARCH_AUDIT.md) distinguish past from current results. `#print axioms` in selected modules is informative but no claim is made that every theorem has undergone an independently reproduced axiom-dependency audit.

## 19 November 2026 current-source CI receipt

The first completed post-alignment [GitHub Actions run 44508741681](https://github.com/dwijayuda/pskernel/actions/runs/44508741681), [job 135507088185](https://github.com/dwijayuda/pskernel/actions/runs/44508741681/job/135507088185) **succeeded** on PR #267 head `e0fb2a723b25582f53d49aa94c1c42412c4624e7`, using Lean 4.36.0. The log contains `LEAN_KERNEL_CHECK_OK`, exact SHA-256 values for all three modules matching the historical successful run, and the new check marker `TRACTATUS_V1_1_0_COMPANION_ALIGNMENT_OK: 116 ID/EN/LA/INDEX, 3 archived drafts, versioned paper references`. The same job ran the bounded Python examples. This is **real executed CI evidence** for that commit, not merely a hypothetical test or evidence for a future modified head. Any newer commit should be checked against its own CI result.

## Structural regression test

Run from the project directory:

```sh
python3 tests/check_edition_alignment.py
```

This checks:
- 116 unique numbered IDs, all three languages in the same order, and active copies equal to frozen v1.1.0 snapshots;
- the exact §5.31 displayed mutual-willingness formula, presence of newly added IDs, absence of the retired IDs;
- complete **116-ID** row match in the proposition index, core v1.1.0 source annotations in the paper, and archive manuscript counts (74, 78, 66);
- whether local Lean file SHA-256 values match the successful historical job (**reports but does not silently promote a changed file to verified**).

The same script is invoked alongside bounded finite Python examples in the [Lean 4 workflow](../../.github/workflows/mutual-acquaintance-lean.yml). These are **structural checks**, not validation of philosophical truth or psychological premises. The latest pipeline must be checked for an exact successful run before claiming all tests passed on the current head.

## PDF and remaining verification boundary

The project includes three *Tractatus* PDF files and a mathematical paper PDF. The Markdown sources are authoritative. **The working-paper PDF needs regeneration**: on the audit head, its Git blob SHA was still `fecaf1e4e0c2c210bdda8e97a5050d467059067a`, identical to the pre-alignment source commit `20f181aa150136152e815356cd8456efa1877da4`, whereas the working paper Markdown has since changed substantially. The three Tractatus PDF blobs had changed since the v1.0 baseline, but their visual/content equivalence to v1.1.0 has **not been independently checked**. The dedicated [PDF workflow](../../.github/workflows/mutual-acquaintance-pdfs.yml) is configured to regenerate all four snapshots on changes to the working paper or active tractatus Markdown on the research branch, but a configured workflow or a committed older PDF is not evidence of successful new rendering. Verify a post-alignment workflow receipt, generated PDFs, and visual quality before calling the PDF versions v1.1.0-consistent.

Other unproven matters: general stochastic/Bayesian theorem in Lean; causal identification from nonrandom encounters; calibration and invariance of real reports; experimental outcomes; philosophical novelty; human-rated English and philological Latin translation quality; complete theorem-by-theorem independent review. None is supplied merely by updating edition labels.

## Edition history policy

The three v2 proposals—[74-proposition draft.1](editions/archive/v2.0.0-draft.1/), [78-proposition draft.2](editions/archive/v2.0.0-draft.2/) and the [66-proposition independent alternative](editions/archive/v2.0.0-draft.1-alt66/)—are archived, not current. Their editorial programmes and any independent mathematical research iteration are **not** merged into canonical v1.1.0 by changing citations. The historical baseline section of `RESEARCH_AUDIT.md` remains intentionally historical. Future versions must use distinct IDs or a documented mapping before changing companion theorem claims.
