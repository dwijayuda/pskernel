# Stage-0 pilot protocol: two people, two kinds of evidence

**Research iteration:** r0.2.0-draft.1 · **Status:** PRE-REGISTRATION BLUEPRINT ONLY  
**No participants recruited; no ethics approval, sample size, registered hypothesis,
data, or validated instrument is claimed.**  
**Companion:** [permission-relative identification](PERMISSION_RELATIVE_IDENTIFICATION.md)

## Research objective

Test the **narrow** hypothesis that a jointly completed, low-stakes
coordination task can cause a measurable dyad-specific behavioral
convention to emerge beyond individual task practice and exposure
to similar information. This is NOT a test that romantic love can
be generated, and no such manipulation is proposed.

One should distinguish:

- **Operational change in performance**: a transfer task score changes.
- **Coordination rule formation**: partners converge on a jointly usable
  routine not present at baseline, demonstrated in a transfer task.
- **Changes in independent skills/preferences**: individuals improve
  whether or not the same two people perform together.
- **Relational intimacy/compatibility**: separate psychological constructs
  that do not follow from the first three by definition.

An experiment showing an effect on the first measure does **not**
automatically establish the others.

## Population and consent

Use adult, fully consenting volunteer dyads for the first pilot.
Prefer non-romantic cooperative tasks to reduce suggestion, pressure,
and appearance of induced attraction. Both participants independently
consent to study participation. Invitations may be declined at any
time. Study staff never request romance-related disclosures or ask
either participant to persist after the other withdraws.

A participant can withdraw separately from task participation and
optional post-task interviews. Observations beyond an explicitly
declined procedure are not collected. Withdrawal and missing outcome
data may be informative and must be reported transparently.

Recruiting established romantic couples could test a separate
relationship-stage hypothesis, but transporting those results to
**acquaintance formation** would require new evidence.

## Conditions and intervention

A dyad receives one randomized **offer** after initial neutral
baseline measurement and independent willingness checks.

| Arm | Offered activity | Shared information | Key difference |
| --- | --- | --- | --- |
| Z=1 | Brief, mutually approved live cooperative task | The same neutral instructions and problem material | Participants make reciprocal in-the-moment choices |
| Z=0 | Independently work with equivalent problem material and annotated examples | Comparable written material and duration where feasible | No dyadic reciprocal coordination during exposure |

Information equivalence is only an aspiration: interactivity conveys
signals not present in an independent task. Record this difference
rather than claiming strict information matching.

After the assigned stage, offer all consenting dyads the same
**blinded-scored transfer task** in a different setting. Record whether
a nontrivial shared coordination convention, beyond ordinary task
proficiency, appeared and remained usable. For the primary behavioral
outcome, choose an explicit scoring rule *before* data collection.
Examples (to refine with measurement experts):

- correct coordination on an untrained instance with minimal chatter;
- efficiency beyond predictions from each participant's independently
  tested task skill;
- consistency of mutually selected, identifiable action sequences
  across repeated transfer rounds.

Use at least one **negative-control individual task**; if only
individual performance rises, a dyad-formation explanation loses
support. If dyads are repeatedly reshuffled for actor-partner
variance estimation, this constitutes a *different* experiment with
interference and carryover risks. Do not casually pool its effects
with the primary randomized protocol.

## Estimands and hypotheses to preregister

Let Y_i be the pre-specified behavioral transfer outcome for dyad i,
measured under a consistent protocol; Z_i in {0,1} the randomized
offer. The primary causal estimand is

    tau_offer = E[Y_i(Z_i=1) - Y_i(Z_i=0)].

This is an **intention-to-treat offer effect**. Randomization does
not automatically identify the effect of completing the task because
completion depends on consent, both participants' states, and other
circumstances.

Candidate outcome contrasts:

- **H0, narrow:** no change in the distribution of the defined transfer
  score due to assignment, up to a justified smallest effect of interest.
- **H1, narrow:** assignment changes the expected or distributional
  transfer score, direction to be preregistered after piloting.
- **H_reporting:** assignment alters perceived understanding or
  self-reported connectedness without changing independently scored
  transfer behavior beyond individual skill.
- **H_skill:** assignment changes independent task skill to a degree
  that accounts for the change in dyad task score.
- **H_coordination:** assignment affects transfer score specifically
  when the original partner is present after accounting for
  individual skill and ordinary familiarity. This is a
  **mechanistic interpretation** requiring stronger assumptions and,
  ideally, a separate experimentally justified partner-comparison
  design.

One could preregister an equivalence or non-inferiority region for
the primary measure, but only after calculating a meaningful minimum
effect and precision. Absence of a significant p-value is not
evidence of equivalence.

## Measures and falsification

Pre-register a data dictionary with distinct variables for:

- random assignment, offered opportunity, A's consent, B's consent,
  completion and withdrawal, assessment status, and missingness reasons;
- individual baseline proficiency, previous acquaintance,
  initial task familiarity, and relevant opportunity/selection context;
- observable dyadic transfer performance, separate A/B ratings,
  expectancy and demand effects, and any blinded assessor score;
- subjective felt understanding **separate from** criterion-linked
  accuracy, including whose criterion is used and its limitations;
- verbalized preferences **separate from** measured behavioral
  choices, with measures of temporal and contextual stability.

A plausible result against the favored constitution explanation is
that transfer improves only for individually practiced information,
or only in self-report and expectation, not for genuine partner-specific
coordination. Even a positive joint-task effect would not prove
that an underlying compatibility propensity did not already exist.

Avoid treating close agreement in self-reports as proof of shared
understanding. Define a behavioral criterion or validation task when
accuracy is the target. Feelings of being understood can be meaningful
outcomes independently.

## Analysis intentions

- Randomization unit is the dyad, **not** the member: preserve dyadic
  dependence, and clarify clusters if individuals appear in multiple
  pairs.
- Estimate offer-arm effect with uncertainty intervals and a
  pre-specified simple analysis before complex multilevel models.
  Adjust for prespecified baseline measures, not post-treatment
  variables that could be affected by assignment.
- Record uptake; compare completers only as exploratory/descriptive
  unless causal assumptions about selection are defensible.
- No instrumental-variable estimate from an offer without a justified
  **exclusion restriction**, monotonicity, and the other necessary
  assumptions. Offer itself can alter expectations and reporting.
- Document missingness and sensitivity analyses, including worst-case
  bounds for binary outcomes where feasible. No automatic
  complete-case causal interpretation.
- Separate exploratory analyses of A's and B's distinct reports from
  the dyad-level primary score. Use valid multiplicity control
  if multiple outcomes are elevated to primary.
- Fit actor/partner/dyad models only after checking what is estimable
  under the actual design; one observation per pair cannot separate
  relationship variance from error.
- Validate scoring reliability (blinding, inter-rater agreement, and
  possible retest); specify transfer versus trained tasks to reduce
  practice artifacts.
- Sample size: **open**. Determine from an independently justified
  effect size or pilot variability, specified precision/power and
  dropout sensitivity before registering a confirmatory study.
  Do not invent N or power here.

## Ethical stop rule

Both individuals must independently accept *every* joint research
activity. A refusal to engage in an activity is sufficient to
terminate the corresponding task. No statistical advantage from
conducting a more informative experiment overrides this condition.
There is no intervention to increase another participant's consent,
and no obligation to explain a refusal.

The project makes a methodological distinction between the truth of
a hidden proposition and the permissible next action. It does **not**
equate statistical uncertainty with license to press for disclosure.

## Open science and decision gates

1. Write down the precise behavioral task, scoring rubric, diagram,
   exclusion restrictions, and missing-data plan.
2. Seek independent human-subjects and measurement review.
3. Pilot reliability and participant comprehension; refine
   operationalization without claiming confirmatory inference.
4. Register hypotheses, analysis, consent, and sample determination
   before confirmatory data collection.
5. Publish null results and boundary failures. Preserve a versioned
   specification; never backfit the hypothesis to observed outcomes.

## Directly relevant methodological precedents

- [A dynamic social relations model (2024)](https://pmc.ncbi.nlm.nih.gov/articles/PMC11090398/): dyad variance, temporal residuals, and measurement error are not interchangeable.
- [Causal inference in life-event studies](https://doi.org/10.1177/25152459241302015): design, time-varying confounding, selection.
- [These Are Not the Effects You Are Looking For](https://doi.org/10.1177/25152459221140842): separating within-person modeling from causal identification.
- [Hernán and Robins, *Causal Inference: What If*](https://www.hsph.harvard.edu/miguel-hernan/causal-inference-book/): randomized assignment, causal estimands and assumptions.
- [1993 shared activity experiment](https://doi.org/10.1177/026540759301000205) and [Aron et al. (2000)](https://doi.org/10.1037/0022-3514.78.2.273): direct existing experimental precedent for shared experience affecting relationship quality.

**Scope:** proposal only; no applied ethics approval, data collection, estimated
effect, statistical conclusion or verified general dynamic theorem.
