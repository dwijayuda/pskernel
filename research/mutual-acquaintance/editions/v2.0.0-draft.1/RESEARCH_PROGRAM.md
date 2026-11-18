# Research programme: knowing while becoming

**Companion to:** *Tractatus de Perceptione et Amore*, v2.0.0-draft.1 (2026-11-19)  
**Status:** research design and literature-grounded conjectures, **not** a validated psychological theory, a new mathematical result, or a report of collected data.  
**Authority:** the Indonesian philosophical edition is independent from this paper. Model constraints do not automatically become truths about lived relationships.

## Research question

**How can two individuals obtain sufficient decision-relevant knowledge for an informed mutual choice when the encounters that supply evidence may also alter their preferences and the relation they are evaluating?**

This question has three parts which must not be collapsed:

1. **Epistemic:** What can person A or B infer from available observations, and about what specified target?
2. **Constitutive:** Does an encounter merely disclose a prior state, change a preference, create a dyad-specific state, or combine these effects?
3. **Practical:** What information is sufficient *for each independently consenting participant* to choose or not choose a next step?

The candidate contribution is a **carefully delimited synthesis and a discriminating research programme**, not invention of Bayesian updating, dynamic epistemic logic, relationship effects, preference change, or consent.

## What predecessors already establish

| Source | Relevant result or idea | Implication / limit for this project |
| --- | --- | --- |
| Funder, 1995, *Psychological Review*, [doi:10.1037/0033-295X.102.4.652](https://doi.org/10.1037/0033-295X.102.4.652) | Accurate judgment requires relevant cues and their availability, detection, and utilization. | Never assert that first impressions are intrinsically inaccurate. |
| Ambady & Rosenthal, 1992, *Psychological Bulletin*, [doi:10.1037/0033-2909.111.2.256](https://doi.org/10.1037/0033-2909.111.2.256) | Thin behavioral slices can predict specified outcomes in a meta-analysis. | Limited observation can be informative; prediction is not universal mind reading. |
| Vazire, 2010, *JPSP*, [doi:10.1037/a0017908](https://doi.org/10.1037/a0017908) | Accuracy of self versus other assessments depends partly on observability and evaluativeness. | Do not treat self-report as an infallible ground truth. |
| Laurenceau, Barrett & Pietromonaco, 1998, *JPSP*, [doi:10.1037/0022-3514.74.5.1238](https://doi.org/10.1037/0022-3514.74.5.1238) | Disclosure and perceived responsiveness contribute to experienced intimacy in interpersonal exchanges. | Relationship development through interaction is established research territory. |
| Joel, Eastwick & Finkel, 2017, *Psychological Science*, [doi:10.1177/0956797617714580](https://doi.org/10.1177/0956797617714580) | Predate self-reports failed to predict relationship-specific initial desire in the studied speed-dating datasets, despite predicting some actor/partner variance. | Specific predictive failure, not proof of general unpredictability. |
| Baxter et al., 2022, *PNAS*, [doi:10.1073/pnas.2206925119](https://doi.org/10.1073/pnas.2206925119) | Initial dyad-specific desire predicted later romantic outcomes in three speed-dating datasets. | Dyad-specific information can be useful; it need not be inaccessible or new at every step. |
| L. A. Paul, 2014, *Transformative Experience*, [publisher](https://academic.oup.com/book/7934) | Experiences can change what one knows and what one values, complicating antecedent choice. | The epistemic/preference-change distinction is **not** this project's invention. |
| van Ditmarsch & Kooi, 2006, [arXiv:cs/0610093](https://arxiv.org/abs/cs/0610093) | Dynamic epistemic logic distinguishes information changes from changes of facts through event postconditions. | Do not call the epistemic/ontic split novel. |
| Blackwell, 1953, *Annals of Mathematical Statistics*, [doi:10.1214/aoms/1177729032](https://doi.org/10.1214/aoms/1177729032) | Comparison of statistical experiments by their decision utility. | A free *passive* signal with fixed decision options is not the same as an encounter that changes the situation. |
| Eastwick, Zhao & Zietsch, published online **29 Oct 2026**, *Trends in Cognitive Sciences*, [doi:10.1016/j.tics.2026.10.001](https://doi.org/10.1016/j.tics.2026.10.001) | Compatibility may emerge as two people repeatedly extend shared positive experiences; preference–trait matching alone is weak. | **Very close recent conceptual predecessor**. The project must supply more than the statement that compatibility can be co-constructed. |

**Literature verification:** links were checked through bibliographic/publisher records on 2026-11-19. This is a targeted review, **not** a systematic search of every database, registered study, or subsequent citation. The 2026 review's proposal is not proof of the entire mechanism. Some studies summarized here are correlational and cannot determine causal creation.

## Minimal model: two agents, three changes

Let \(i\in\{A,B\}\), with pre-encounter latent individual state \(x_{i,t}\), operative preferences \(q_{i,t}\), dyad-specific state \(r_t\), context \(c_t\), and history \(h^i_t\). The model permits two different histories and therefore two different posteriors \(\pi_t^i\).

- **Belief update:** \(\pi^i_t\rightarrow\pi^i_{t+1}\), possibly without changing any modeled state.
- **Preference discovery/change:** a new self-report might reflect \(q_{i,t}\rightarrow q_{i,t+1}\), a change in beliefs about a fixed \(q_i\), or a different reporting rule.
- **Relational transition:** \(r_t\rightarrow r_{t+1}\) may be generated by the joint actions \((a_t^A,a_t^B)\); this is not derivable solely from \(x_A,x_B\) without additional assumptions.

A general controlled kernel is:

\[
P(s_{t+1},y^A_{t+1},y^B_{t+1}\mid s_t,a^A_t,a^B_t),
\qquad s_t=(x_{A,t},x_{B,t},q_{A,t},q_{B,t},r_t,c_t).
\]

This is a **representation**; the existence of a field named \(r_t\) proves no corresponding natural kind. Actions are not necessarily informative, transformative, beneficial, or voluntarily available.

### Competing accounts

**R — revelation model (restricted).** A relatively stable dyad attribute \(z_{AB}\) influences what the participants observe. Information about it improves through encounters. Under an explicitly constrained measurement law, the encounter does not itself alter the target \(z_{AB}\).

**C — constitution model.** A dyad-specific state \(r_t\) is affected by what the participants do together. Later observations depend on the modified state.

**M — mixed model.** Encounters reveal some pre-existing properties and change other properties. This is a realistic candidate but may be too flexible to test without constraints.

**Important:** reports changing over time do **not** alone distinguish R from C. A stable unobserved variable encoding the entire response schedule under possible encounters can mimic a seemingly evolving process when the model class is unrestricted. Conversely, if R permits arbitrary action-specific reporting channels, a post-encounter difference need not reject R. The contrast must be made among *restricted, explicit models*, not between unrestricted philosophical stories.

### A testable restricted contrast

Suppose participants voluntarily enter randomized, acceptably similar interaction conditions \(a=0,1\). Assume:

1. Randomization is respected with positive assignment probabilities.
2. The outcome \(Y\) measures a specified dyad-relevant target with a **stable, validated measurement rule**, not simply a demand-induced report.
3. In the *restricted null model* R0, no pathway from assignment to \(Y\) exists other than a proposed dyadic state transition; and the dyadic state is stable during the intervention.
4. Spillovers, selection, and contextual differences are either prevented or modeled sufficiently for the estimand.

Then R0 implies

\[
P(Y_{t+1}\mid \mathrm{do}(a=0))
=
P(Y_{t+1}\mid \mathrm{do}(a=1)).
\]

A reproducible difference would falsify **R0 under those assumptions**. It would not, by itself, uniquely prove relational constitution: response bias, individual preference change, measurement effects, attrition, or other causal pathways could also explain it. A positive causal result demands additional mediating measures and competing model checks.

This conditional exclusion restriction is a familiar causal-identification strategy, **not an original universal theorem**. The research value lies in selecting credible measures and restrictions that actually distinguish hypotheses about interpersonal development.

## Empirical design worth attempting

**Candidate study, not yet implemented:** consent-based, registered longitudinal dyadic study with repeated, low-stakes interactions. Collect baseline trait/preferences, pre- and post-encounter expectations, independent reports of feeling understood, behavioral/criterion-linked understanding where obtainable, and separate willingness to continue. Compare shared-task conditions to *information-matched* conversational conditions only where ethically and practically feasible. Both people may refuse, exit, or withhold disclosures at any time.

Prespecify:

- **Primary estimand:** intention-to-treat difference in a defined, validated post-encounter dyadic outcome between randomized conditions. Do not name it 'created compatibility' without construct validation.
- **Secondary estimands:** calibrated predictive accuracy at each time, change in independently measured preference reports, and each participant's own decision to continue.
- **Measurement audit:** separate felt understanding from accuracy; separate pre-existing dispositions, changing preferences, the reporting channel, and dyad-specific effects; test measurement invariance across conditions and time.
- **Design audit:** account for actor/partner dependence, order effects, selective continuation, dropout, context, violations of interference assumptions, and time-varying confounding. Never condition naively on only those pairs who voluntarily agree to a second encounter.
- **Falsification:** compare predictive performance and pre-registered model restrictions on held-out dyads and contexts; report null effects and intervals. A complex C model must earn its parameters against simpler R models.
- **Ethics:** no coercion, fake affection, deceptive signaling, attempts to bypass refusals, or optimization for increasing another person's willingness. A rejection can settle the permissible next step without settling every latent feeling.

## Mathematics: the difference between a valid proof and a useful result

The existing Lean 4 project checks small finite, conditional claims about observation equivalence, toy transitions, willingness, and decision payoffs. Such checks are valuable for eliminating logical mistakes **inside the chosen abstraction**. They do not verify stochastic psychological mechanisms or establish psychological predictions. The new philosophical version has **no new Lean theorem claims**.

A mathematical contribution would need to identify a genuinely informative problem, for example:

- Find explicit minimal observation/intervention conditions under which restricted R and C models can be distinguished while allowing private histories and mutually voluntary actions.
- State a nontrivial impossibility or sensitivity result for distinguishing preference *discovery* from *change* given specified reporting assumptions.
- Characterize decision-relevant information for **two** participants with independent options, including abstention and withdrawal, under state-changing encounters.
- Prove a result that is not just conjunction elimination, a Boolean example, a standard likelihood identity, or rewriting an assumption.

Any future theorem should identify assumptions, countermodels, scope, and whether it has actually passed Lean. Any future observational claim requires data, not merely a successful compiler run.

## Proposed novel thesis — explicitly provisional

The most promising angle is **decision-relative co-formation under asymmetric knowledge**:

> Two people's decision problem may change during the very encounters used to inform it. The challenge is not to achieve omniscience, nor to optimize another person's choice, but to distinguish what can be learned from what can be formed under actions both are free to accept or decline.

This thesis is a synthesis with identifiable predecessors. **Do not label it a discovery until the comparative and empirical work shows what it explains that those predecessors do not.** Its importance must be judged through clear contrasts, discriminating predictions, independently credible measurement, and possible failure.

## Research gates before claiming an important result

- **Gate 1 — philosophical:** external critical readers independently identify a coherent, non-trivial argument and counterexamples.
- **Gate 2 — mathematical:** an explicit theorem solves a problem not trivialized by its premises; proof is verified and the scope documented.
- **Gate 3 — empirical:** preregistered analyses provide evidence that distinguishes at least two credible accounts; null results do not get rewritten as support.
- **Gate 4 — reproducible:** versioned data dictionary, protocol, analysis code, measures, decision logs, and anonymized reproducibility artifacts where consent permits.
- **Gate 5 — external review:** independent feedback, preferably from relationship scientists, formal epistemologists, and philosophers of choice. No current stage satisfies an external publication claim.
