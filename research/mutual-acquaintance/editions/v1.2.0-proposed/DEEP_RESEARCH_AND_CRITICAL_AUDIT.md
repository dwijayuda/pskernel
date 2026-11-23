# Deep Research, Mathematical Review, and Consistency Audit

**Review date:** 23 November 2026  
**Source baseline:** original repo's Tractatus v1.1.0 (116 active propositions); accessible Mathematical Companion v0.3, technical draft v0.2; independent Multi-Agent Research v0.1 from 22 November.  
**Output evaluated:** GitHub PR #270 Tractatus v1.2.0-proposed (126 propositions) and Mathematical Companion v0.4 (MA-1 through MA-9).

## 1. Executive verdict

The new edition is a *modest conceptual extension*: a pair's perceived compatibility can vary through events involving other people, while the original distinction between person, perception, represented ideal, choice, and relationship remains intact. This is mathematically coherent **only if** operative preferences, represented preferences, observations, selection into encounters, and relation-specific state are kept distinct. The framework can organize explanatory possibilities but **does not yet produce a novel empirically validated scientific theory**. The strongest new formal addition relative to the prior draft is explicit treatment of causal non-identification (MA-8) and a criterion for the *predictive*, not causal, value of outside-network histories (MA-9).

The old textbook mathematical results (metric Lipschitz bound; network propagation; symmetries; contraction; summary sufficiency) should not be advertised as newly discovered theorems. They are useful lemmas or adaptations. The current contribution is synthesis, a carefully restricted model family, and a testable research agenda.

## 2. Detailed issues, risk, and treatment

| ID | Severity | Flaw, confusion, or potential inconsistency | Decision in v1.2/v0.4 | Remaining status |
|---|---|---|---|---|
| A01 | Critical | Collapsing a *person* into a variable x(t) would confuse identity with a finite state. | A and B remain persons; x_i(t) records *features selected for the model*. | Conceptual limitation acknowledged. |
| A02 | Critical | Treating the six-tuple as the *entire relational state* conflicts with the prior companion's history-dependent r_AB. | Six-tuple is an interpretive lens; mathematical state adds r_AB and network. | No claim of sufficiency. |
| A03 | Critical | Represented ideal I_i, operative preference q_i, self-belief rho_i and report q-hat_i were conflated in informal discussion. | Separate variables with different observability. | Measurement scheme open. |
| A04 | Critical | Claiming perceived ideal-distance *causes* attraction despite weak registered preference-matching effects. | Distance/threshold is only a toy score. | Must test against strong actor-partner models. |
| A05 | Critical | Calling post-event association the third party's causal influence ignores selection, reverse causation and common causes. | Adds MA-8 observationally equivalent SCMs with different interventions. | Actual causal identification open. |
| A06 | High | A directed P_A(B) and P_B(A) are not symmetric; r_AB as one bit may erase differing perspectives. | Directional perceptual states, relational state may be vector. | Specify measurement components per application. |
| A07 | High | MA-3's social-contact graph alone does not encode pathway via ideals and evaluations. | Use *component-dependency graph*, including self-dependencies. | Temporal/asynchronous extension open. |
| A08 | High | MA-3's proof fails if the compared trajectories have different exogenous shocks or global dependence. | Identical external inputs, deterministic local updates assumed. | Stochastic intervention coupling future work. |
| A09 | High | MA-4 translation invariance can leave constrained [0,1] trait space. | State R^d and explicitly require admissible translations. | Empirical measurement scales open. |
| A10 | High | MA-5 is already present in the existing Lean development; duplication would overclaim discovery. | Mark as earlier theorem, reuse concept without new novelty claim. | No new proof claim. |
| A11 | High | MA-6 contraction need not cover stochastic social averaging where ||W||_infinity=1. | Restrict to strict contraction with identical inputs. | Broader convergence conditions open. |
| A12 | High | Stable matching under changing preferences is not a model of a breakup or divorce. | Explicitly state narrow matching-theoretic meaning. | No empirical law asserted. |
| A13 | High | MA-8 uses a binary outcome Y and binary encounter E; exposure 'versions' may differ. | Structural counterexample framed as existence; causal estimand requires operationalization. | Real treatment design unresolved. |
| A14 | High | Mutual information of extra history may be >0 because of confounding, without causal spillover. | MA-9 explicitly concerns predictive log loss only. | Prospective model comparison needed. |
| A15 | High | The multi-agent state is not observed just because its symbols are defined. | Include O_i observations, missing representations, calibration caveats. | Latent-variable identification open. |
| A16 | High | 116-to-126 edition could accidentally renumber or retire propositions without trace. | All 116 v1.1.0 IDs retained in three languages; 115 original proposition texts preserved verbatim; §7 revised deliberately, and 10 new identifiers added. A full 126-row alignment accompanies the proposal. | Automated checks run. |
| A17 | Medium | §3.1 used the everyday word 'preference' while §3.11 clarifies I as a picture; technical q is distinct. | Treat I as a represented ideal/preferences and q as operative preference in companion. | Philosophical terminology could be refined in future editorial review. |
| A18 | Medium | Adding network language everywhere would distort seven-chapter aphoristic structure. | Ten additions in §§1,3,6; 115 old proposition texts preserved and §7 revised deliberately. | Stylistic review still subjective. |
| A19 | Medium | 'No contact' does not imply that B's state is unchanged. | MA-2 explicitly *assumes* fixed B and P_AB for construction; philosophical text does not assert permanence. | Counterexample's scope marked. |
| A20 | Medium | Third-party spillover as a mechanism is already discussed in network behavior research. | Sources cite selection/influence, stochastic actor-oriented models, APIM/SRM. | Novelty unproven. |
| A21 | Medium | N(N−1) directed representations overstates observed data in a sparse network. | Only applies to a complete ordered pair system; missingness mentioned. | Data structure needs missing values. |
| A22 | Medium | One couple's history cannot identify the unchosen path without additional assumptions. | Distinguish observed, intervention, counterfactual; retain original C6. | Standard causal problem. |
| A23 | Medium | Self-reports of private feelings are not infallible ground truth. | Measurement protocol to separate felt understanding, direct report, and accuracy is proposed, not asserted. | Requires psychometric study. |
| A24 | Medium | 'Every new meeting changes six things' is false as universal mathematical or psychological assertion. | Use modal language *can/may*, not must; preserve unchanged alternatives. | No universal claim. |
| A25 | Medium | 'Everything about relationships is explained' is scientifically indefensible. | Report scope and open phenomena, cultural, legal, personal and environmental factors. | Major empirical limitations. |
| A26 | Medium | Lean toy Boolean examples do not prove smooth metric, stochastic, entropy or causal identification theorems. | Written proofs separated from finite Lean model; exact CI receipts are required. | Independent Lean 4 compilation and richer formalization needed. |
| A27 | Medium | Latin translation fluency/semantic fidelity may be overclaimed. | Latin explicitly marked working translation, not philologically reviewed. | Expert review required. |
| A28 | Medium | The new edition has not been promoted to GitHub canon, so using v1.2 as already canonical would be misleading. | Version marked **proposed**; repo canon remains v1.1.0. | Promotion needs explicit review + GitHub version policy update. |
| A29 | Medium | Formal dynamic preference utility can require selecting a normative welfare perspective (current vs transformed self). | No moral optimization is attributed to an agent without an explicit welfare model. | Philosophical, not resolved by elementary regret. |
| A30 | Medium | Networks interfere with naive randomized-outcome assumptions; pair-splitting alone may leak exposure across a network. | Data plan discusses clusters, network spillovers, appropriate prospective partitions. | Empirical implementation needed. |

## 2a. Follow-up audit: approved §§6.95–6.96 and §7

| ID | Severity | Additional issue | Resolution and limitation |
| --- | --- | --- | --- |
| A31 | High | Wittgenstein's technical *Zeigen* is not ordinary observed behavior. | The comparison is explicitly analogical: §6.96 concerns evidence from actions and shared experience, not logical form. |
| A32 | High | §7 might be misread as forbidding uncertain inference altogether. | It forbids **speaking as though we know**; probabilistic hypotheses and explicitly acknowledged uncertainty remain legitimate. |
| A33 | High | Kernel verification of finite Boolean witnesses can be confused with general proofs of MA-1–MA-9. | Lean checks only named finite declarations; written mathematical arguments for metric bounds, network locality, contraction and information theory remain separate. |
| A34 | High | Original companion v0.4 referenced 124 propositions and an older final chapter. | Companion revised to the 126-proposition proposal, and an indexed crosswalk/CI checker added. |
| A35 | Medium | A perceived-ideal distance score might be mistaken for an empirical measure of attraction. | It remains a toy discrepancy score with no established universal psychometric validity. |
| A36 | High | Predictive network information can be strongly associated with an outcome despite zero causal influence. | MA-8 provides distinct causal models with identical observations; MA-9 is only a population-optimal log-loss identity. |

## Focused research novelty review (23 November 2026)

- Eastwick et al., DOI 10.1037/pspp0000524: large-scale empirical work already studies ideal-partner preference matching; the toy distance score is not a newly validated causal law.
- Eastwick, Zhao and Zietsch, DOI 10.1016/j.tics.2026.10.001: the compatibility puzzle and experience-dependence are part of existing relationship science.
- Shalizi and Thomas, DOI 10.1177/0049124111404820: observational network homophily and contagion are generically confounded; MA-8 adapts established causal reasoning.
- Longitudinal APIM review, DOI 10.1177/02654075261443593: dyadic longitudinal baselines are established and must be competitive comparators.

## Verification ledger

CI should run Lean 4.36.0 on `MultiAgentAcquaintance.lean` plus old modules, and a finite example checker. A successful run establishes only that the exact formalized statements typecheck in Lean and the bounded tests pass; it is not empirical validation, a proof of all MA-1–MA-9, or independent peer review.

## 3. Mathematical check details

**MA-1:** standard triangle inequality; threshold-stability corollary requires strict distance from threshold **greater** than the total drift bound.  
**MA-2:** explicit one-event constructed witness; the update of I_A is *postulated*. Cannot infer population frequency or real causation.  
**MA-3:** induction valid with fixed graph of all dependencies and same external inputs. Does not apply without modification to evolving graph or asynchronous encounters.  
**MA-4:** translation cancels in a difference score; only admissible translations count. Invariant observation makes the inverse problem non-unique.  
**MA-5:** exact predictor criterion is a well-known factorization condition. Already present in earlier verified Lean source.  
**MA-6:** correct under induced norm strictly <1 and common inputs, not a theorem about general consensus dynamics.  
**MA-7:** full set of specified rankings has initially no blocking pair and then A–C blocks. Stable matching is a very narrow mathematical outcome.  
**MA-8:** two structural assignments have identical observational (E,Y) laws with U fair and E=U, yet different outcomes under an intervention on E. This is a genuine *identification impossibility without added assumptions*, not a new principle in causal inference.  
**MA-9:** expected log-loss difference under the **true population distribution** equals conditional mutual information; equivalence to independence assumes standard finite-distribution positivity conventions. When learned from finite data, adding parameters can worsen forecasts. This result does not imply causation.

Executable checker `tests/check_models.py` checked 14,641 MA-1 exact rational combinations, plus finite witness and logic checks for MA-2 through MA-9. This supports numerical consistency, **not universal mathematical proof or Lean verification**.

## 4. Empirical literature: support versus conflict

- Eastwick et al.'s worldwide registered report (2025, N=10,358, 43 countries) evaluates stated preference-matching and finds that particular matching effects can be small: a direct warning against unqualified `compatibility = ideal distance`. DOI 10.1037/pspp0000524.
- Eastwick, Zhao, Zietsch (2026) review a compatibility puzzle and discuss repeated shared experiences; a review does not identify or validate this proposed transition function. DOI 10.1016/j.tics.2026.10.001.
- Baxter et al. (2022) distinguish actor, partner, and relationship-specific attraction effects. The v0.4 model must improve upon rather than rediscover SRM actor/partner decomposition. PMID 36322750.
- A 13-year repeated-preference study involving 204 participants finds substantial stability of many ideal preferences as well as changes. Consequently 'all ideals constantly change' is unwarranted. PMID 37029599.
- A 27-month study involving 285 participants finds both stability and context-related changes in mate criteria. PMID 30229702.
- Manski (1993), Shalizi & Thomas (2011) and Snijders et al. (2010) establish important earlier methods and warnings for peer effects, homophily, and dynamic network selection. Their work limits claims to novelty and causal interpretation.
- A 2026 systematic review of longitudinal APIM research shows that dynamic dyadic models are a strong contemporary baseline, not an unsolved blank slate. DOI 10.1177/02654075261443593.
- L. A. Paul's work on transformative experiences explains philosophical difficulty in treating a future self's preferences as fixed during present choices; no numerical toy model resolves that normative problem.

## 5. Identification problems still open

1. **Operative preferences vs declared ideals:** Can both be independently calibrated with repeated behavioral tasks, while avoiding strong assumptions about what the task measures?
2. **Third-party causality:** Can outside exposure be plausibly randomized or identified by a natural experiment, while retaining voluntary participation and accounting for interference?
3. **Dyadic history versus individual profile:** Does M2 improve prospective, out-of-sample prediction versus M1 after comparable complexity regularization, not merely fit training data better?
4. **Learning versus formation:** Can repeated independent indicators separate latent change from reporting drift, or can only partially identified bounds be defended?
5. **Temporal and multiplex networks:** How do locality claims generalize when one event simultaneously changes perceptions, preferences, and opportunities in several types of networks?
6. **Real-world outcomes:** How would dating, friendship, marriage, separation, and divorce be operationalized without conflating distinct social/institutional processes?

## 6. Independent peer-review rubric

| Dimension | Preliminary judgment | Reason |
|---|---|---|
| Text continuity | Strong | Seven chapters and 116 original identifiers preserved, with 115 verbatim texts, revised §7 and ten additions. |
| Conceptual precision | Improved but incomplete | Distinguishes person, operative preference, self-belief, ideal, perception and dyad state; these remain partly latent. |
| Mathematical validity | Promising, conditional | MA-1–MA-9 have written arguments/witnesses; scope explicit; not independently peer-reviewed or kernel-proved. |
| Scientific originality | Not established | Many formal results classical; overlap with SRM/APIM/network and causal inference. |
| Empirical evidence | Absent for specific model | Sources motivate components but do not estimate or discriminate the full dynamics. |
| Falsifiability | Operational program proposed | M0/M1/M2 predictive comparison and possible causal estimands outlined. |
| Formal verification | Candidate only for new files | Lean verification is defined by exact PR-head CI and the declarations that compile; successful finite checks do not prove all MA-1–MA-9. |
| Translation fidelity | Provisional | Indonesian source authoritative; new English/Latin phrasing not independently reviewed. |

**Recommendation:** retain the working label **Tractatus v1.2.0-proposed + Companion v0.4** until the proposition crosswalk, translations, Lean compilation and empirical comparison protocol receive independent review. Do not delete or rewrite the canonical v1.1.0 in the source repository based on this package alone.

## 7. Source references

Reference links with identifiers are in `companion/Mathematical_Companion_v0.4_EN.md` §8. The frozen canonical sources remain under `editions/v1.1.0/`; proposed sources and 126-row alignment are under `editions/v1.2.0-proposed/`.