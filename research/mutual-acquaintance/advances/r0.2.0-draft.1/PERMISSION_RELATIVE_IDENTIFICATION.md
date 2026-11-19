# Permission-relative identifiability and constitutive encounters

**Research iteration:** r0.2.0-draft.1  
**Date:** 2026-11-19  
**Companion philosophical text:** Tractatus de Perceptione et Amore v2.0.0-draft.1  
**Status:** mathematical note + research proposal; not peer-reviewed, not novel theorem, no participant data.

## Abstract

When two people become acquainted, an encounter can affect both the
evidence available to each and the object of evaluation. The model
comparison problem must nevertheless distinguish four issues: (i)
different mechanisms producing the same observations, (ii) an
intervention's effect on an observed indicator, (iii) the mechanism
behind that effect, and (iv) whether the intervention is jointly
permitted in the first place. We derive exact, **standard** equal-prior
classification-risk bounds for two binary report laws and exhibit a
finite jointly-authorized versus blocked-policy contrast. In the
illustrative experiment, active interaction changes model
discrimination from zero to 1/4, but only under a model that stipulates
joint approval and invariant reporting. A refusal prevents the *particular
experiment*; it does not prove that all other evidence is unavailable.
We then describe which causal claims an ethical randomized offer can
actually identify, identify confounds that can mimic creation of a
relational state, and formulate a target for genuinely informative
future research. Neither the mathematics nor existing literature
licenses mind reading or optimizing another person's consent.

## 1. The epistemic problem is not just prediction

Distinguish these questions:

1. Does an observation predict a report, a behavior, or a choice?
2. Does it identify a latent *current state* under a specified
   measurement rule?
3. Does it distinguish an earlier latent propensity from a relational
   state that was **causally realized** during interaction?
4. Is another experiment to answer (2) or (3) actually available to
   both participants, given the right to refuse?

Do **not** infer from a large dyad-specific statistical effect that a
distinct relational state was created at a particular encounter.
Dyadic random effects, time-varying innovations, and measurement error
are different objects. A dynamic Social Relations Model explicitly
separates them [Pillinger et al., 2024]. An interaction effect can also
be an already-existing but unobserved *propensity* rather than a
realized state.

Likewise, no one needs to know every hidden motive for an actionable
decision: an explicit refusal can settle whether a further romantic
step is permitted, even when the other's attraction or reasons are
unknown. This is a normative rule about the permissible choice set,
not a theorem extracting morality from a probability distribution.

## 2. Two restricted explanations

Let mechanism R stand for *revelation* and C for *constitution*.
Both hypotheses predict reports under a common measurement scheme.

- **R (restricted):** an unchanging relation-relevant target
  influences reports; the offered encounter produces no causal change
  in that target and reporting is invariant across offers.
- **C (restricted):** when the jointly approved action occurs, the
  target can change, followed by reporting through the **same** channel.
- **M (mixed):** latent propensity is present before the encounter,
  while a distinct realized relational state is built through it.
  This account is conceptually coherent. A statistically significant
  intervention need not rule out pre-existing propensities.

Do not infer the metaphysical claim "the relation did not exist" from
a mere difference in self-reports. Measurement changes, expectation
effects, selective follow-up, and changes in each person's private
preferences are alternative channels.

### Conditional experiment

Consider one binary report Y. The two mechanisms have the same total
count D>0 but different positive-report counts a under R and b under
C, with 0<=a,b<=D. The negative-report counts are D-a and D-b.

For a classifier δ that predicts R or C from a single report, its
sum of errors across one draw from each hypothesis is:

    Eδ = P_R_count(δ(Y)=C) + P_C_count(δ(Y)=R).

Under an equal prior probability for R and C:

    Risk(δ) = Eδ / (2D).

The **minimum** risk is

    Risk* = [D - |a-b|] / (2D)
          = (1 - TV(P_R,P_C)) / 2,

since TV for a binary common-denominator experiment is |a-b|/D.
This is the classical Bayes error / total-variation identity specialized
to binary outcomes. It is **not an original mathematical discovery**.

The Lean 4 module [MutualAcquaintanceDecision.lean](../../lean/MutualAcquaintanceDecision.lean)
proves, for each possible binary decision rule, the exact lower bound
Eδ + |a-b| >= D, and constructs an attaining rule. It also checks
that zero gap is equivalent to identical laws. The proof concerns
explicit integer counts and Boolean classifiers only.

### Worked toy example

| Condition | R positive report | C positive report | TV | Best classification error |
| --- | --- | --- | --- | --- |
| Passive or refused offer | 6/16 | 6/16 | 0 | 1/2 |
| Jointly accepted active offer | 6/16 | 10/16 | 1/4 | 3/8 |

The numbers are chosen, not estimated. The active comparison increases
optimal classification accuracy from 1/2 to 5/8. It does not prove
that interaction creates intimacy in real people. In the Lean toy
setting, reported approval is exogenous and identically fixed under R
and C; the approval/decline itself has **no model-specific signal**.
Real participation choices need not satisfy that assumption.

**Permission-relative implication:** the fact that a forbidden or
refused encounter *would* distinguish two models does not make that
encounter an available source of information. Refusal sets an
operational boundary for the offered step, irrespective of latent
classification uncertainty. The logical observation is useful but not
novel: optimization over an inadmissible action set is irrelevant to a
real decision.

## 3. The decisive distinction: treatment effect ≠ mechanism identification

A randomized *offer* Z can estimate an intention-to-treat effect on an
observable outcome Y measured under consistent follow-up:

    ITT = E[Y | Z=1] - E[Y | Z=0].

If randomization and the usual consistency/interference conditions
hold, this can have a causal interpretation as an **effect of the
offer**, not necessarily of the jointly accepted encounter.

A useful causal sketch is:

    Z (random offer) ---> E (actual accepted encounter) ---> R1 ---> Y1
             |                    ^                        ^
             |                    |                        |
             v                    |                        |
       expectation/reporting      U (preferences, context) ---+
             |                    |
             +------------------> Y1
                                  |
                                  +--> consent/uptake E

Conditioning on E=1 compares a selected subset because two persons'
acceptance may depend on their private states. An offer itself can
affect expectations, preferences, or reporting (a direct path Z→Y);
therefore using Z as an instrument requires an exclusion restriction
that may fail. Even a causal effect on Y does not establish a unique
R1 mediator or distinguish preference change from state creation.

The target **must** be operational: e.g. adoption of a jointly
demonstrated coordination convention, independently assessed after a
controlled interaction. It must not be called "true compatibility" by
default. If the alternative mechanism is allowed arbitrary
action-dependent reporting, **no binary report contrast alone**
identifies formation.

Randomized differences, measurement-channel invariance, task
transfer, blinded behavioral scoring and a distinct private-preference
measure provide *joint evidence*; none alone is a magic identification
instrument.

## 4. Design that could actually fail

An ethically approved **pilot on mutually consenting pairs**, perhaps
first using non-romantic social interaction, could investigate
whether a new, reproducible dyad-specific coordination convention
appears after a controlled joint task more often than after a matched
individual-information exposure.

1. Before randomization, measure a narrow pre-specified individual
   competence and the baseline dyadic task output; register whether
   an operational convention already exists.
2. Randomize an **invitation** to joint problem-solving versus a
   noninteractive information-matched task where feasible. Both
   participants choose separately whether to take part, may stop,
   and may decline specific disclosures. Record *offer*, *uptake*,
   and *withdrawal* without treating uptake as randomized.
3. Measure the **same independently scored dyad-relevant outcome** in
   both arms at prespecified times, preferably on transfer tasks rather
   than the trained task alone. Use blinded coding where feasible.
4. Record each person's felt understanding and separately a
   criterion-linked accuracy measure where ethical and meaningful.
   Self-report discrepancy alone cannot certify deception or actual
   interpersonal knowledge.
5. Measure and report expectation shifts, individual practice
   gains, baseline propensities, preference-report changes, attrition,
   sequence effects, and selection into each subsequent meeting.
6. Register the primary ITT estimand, competing observable
   predictions, bounds/sensitivity analyses, and stop rules before
   accessing outcomes. Do not invent a study size or claim power
   until a pilot variance and target precision are justified.

**Critical falsification:** If a well-powered, reliable transfer
measure shows no meaningful offer effect, the particular causal
creation hypothesis (for that task, population, time horizon, and
measurement) is weakened. If the active task changes only
immediate self-reports but not independently scored transfer behavior,
a reporting/expectation mechanism deserves serious consideration.
A positive behavioral effect would still require distinguishing
individual practice, teaching, and dyad-specific learning.

**No causal breakthrough follows automatically**: experiments on
existing couples do not transfer without evidence to early
acquaintance, and non-romantic dyads do not automatically generalize
to romantic choice.

See [PILOT_PROTOCOL.md](PILOT_PROTOCOL.md) for an analysis
blueprint with estimands, observation plans and competing outcomes.

## 5. Close precedents: avoid rediscovering them

- Aron et al. (2000), *Couples' Shared Participation in Novel and
  Arousing Activities and Experienced Relationship Quality*,
  DOI [10.1037/0022-3514.78.2.273](https://doi.org/10.1037/0022-3514.78.2.273).
  Includes laboratory experiments on shared activities and
  relationship quality. **Creating change through experience has
  already been investigated experimentally.**
- *Shared Activities and Marital Satisfaction: Causal Direction and
  Self-Expansion versus Boredom* (1993),
  DOI [10.1177/026540759301000205](https://doi.org/10.1177/026540759301000205).
  Earlier randomized couples-activity precedent.
- Eastwick, Finkel and Joel (2023), *Mate Evaluation Theory*,
  DOI [10.1037/rev0000360](https://doi.org/10.1037/rev0000360).
  A developed account of mate evaluation that this project must
  actually engage, not merely cite.
- Eastwick and Joel (2025), *How Do People Feel About Mates?*,
  DOI [10.1146/annurev-psych-012224-025712](https://doi.org/10.1146/annurev-psych-012224-025712).
  Reviews stage-dependent evaluation and sampling concerns.
- Eastwick, Zhao and Zietsch (online **29 Oct 2026**),
  *Mate preferences and the compatibility puzzle*,
  DOI [10.1016/j.tics.2026.10.001](https://doi.org/10.1016/j.tics.2026.10.001).
  Proposes growing compatibility through shared positive experiences.
  **Direct challenge to topical originality.**
- Pillinger, Steele, Leckie and Jenkins (2024),
  *A dynamic social relations model for clustered longitudinal dyadic
  data*, [open access](https://pmc.ncbi.nlm.nih.gov/articles/PMC11090398/).
  Separates time-varying behavior and dyad effects from error under
  a dynamic dyadic statistical model. The treatment is predominantly
  methodological and illustrates family interaction; causal creation
  remains a separate question.
- Joel et al. (2020), *Machine learning uncovers the most robust
  self-report predictors of relationship quality across 43
  longitudinal couples studies*, DOI
  [10.1073/pnas.1917036117](https://doi.org/10.1073/pnas.1917036117).
  Highlights relationship-specific self-report prediction while
  finding change difficult to predict. Not proof that change
  is intrinsically unpredictable.
- Gordon et al. (2025), *Toward a Science of Relationship
  Forecasting*, [PubMed](https://pubmed.ncbi.nlm.nih.gov/41428531/).
  Argues for dynamic, complex-systems forecasting: the broad
  methodological ambition is also **already claimed in the field**.
- Yan and Li (2026), *The Dyadic Universe Model*, DOI
  [10.3389/fpsyg.2026.1935191](https://doi.org/10.3389/fpsyg.2026.1935191).
  A recent proposed process model of highly immersive established
  relationships. Not direct evidence for early acquaintance,
  but a caution that naming latent relational dynamics alone
  is not a novelty claim.
- Standard binary hypothesis testing / variation distance supplies
  the risk identity. Blackwell (1953) supplies a stronger general
  decision-theoretic comparison framework,
  DOI [10.1214/aoms/1177729032](https://doi.org/10.1214/aoms/1177729032).

This list is a **targeted update**, not a systematic review. The
literature does not validate the proposed latent variables or prove
their independence. Psychological research about committed couples
often operates at a different relationship stage from this project.

## 6. What would earn stronger scientific credit?

A potential *new* technical contribution would give necessary and
sufficient **policy-dependent, decision-relevant identification
conditions** for a genuinely two-agent dynamic system in which each
person can withdraw approval, observations are private, and actions
alter both information and relational state. At present:

- Our binary classification identity is familiar and fully conditional.
- Existing finite stochastic notes already give sharp calibration
  bounds, counterexamples, and cumulative movement.
- We have no new empirical data, validated measurement, or result
  outperforming the cited relationship models.
- The proposed dynamic two-agent general theorem remains **open**.
- The philosophical Tractatus stays independent and can remain
  valuable without meeting the publication standards for statistics.

The intellectual standard is to show, against serious competing models,
what would otherwise be missed; if the answer is "nothing," simplify
rather than invent novelty.
