# Adaptive evidence under permitted encounters: a finite-horizon bound

**Research iteration:** r0.2.0-draft.1 · **Proof status:** traditional mathematical argument
(not formalized in Lean). **Not claimed as a new theorem**: this is the
standard coupling/telescoping argument for total variation, applied to
a two-person restricted-policy question.  
**Companion:** [permission-relative identification](PERMISSION_RELATIVE_IDENTIFICATION.md)

## 1. Problem

Two candidate stochastic models, R and C, predict a sequence of
observable interactions. Both people may decide which joint
encounters they are willing to undertake. A *permitted policy*
\(\pi\) only chooses actions that are allowable for both participants
at the history at which the choice occurs.

We must be precise about what the policy sees. Let \(H_t\) contain
the entire **publicly available** history used by the policy,
including any consent/withdrawal signals actually available to it.
Each person's private signals can be included in an expanded
history if the policy is assumed to observe them; otherwise it may
not condition on them.

Given public history \(h\), the same policy \(\pi\) randomizes over
the **same** permitted actions in R and C; if the permitted sets
differ by model, then the proof below must count that difference
as observable information or use a common smaller permitted set.
Approvals are never taken from another person by fiat.

Let \(K_R^\pi(\,\cdot\mid h)\) and
\(K_C^\pi(\,\cdot\mid h)\) be the complete conditional laws of the
next observable step, including policy choices if they are
observable, after a common history h.

## 2. Conditional theorem (finite horizon)

Assume a common initial observable-history law. For each
\(t=0,\ldots,T-1\), assume a finite alphabet of next-step reports
and a deterministic sequence \(\varepsilon_t\in[0,1]\) such that

\[
 \operatorname{TV}\!\left(
 K_R^\pi(\,\cdot\mid h),
 K_C^\pi(\,\cdot\mid h)\right)
 \leq \varepsilon_t
\]

for every history h that may be reached **under a coupling
with matching histories up to t**. The comparison includes any
available participation information on which the policy depends.

Then the full observable trace distributions obey

\[
 \operatorname{TV}
 \big(P_R^\pi(H_T),P_C^\pi(H_T)\big)
 \leq \min\left\{1,\sum_{t=0}^{T-1}\varepsilon_t\right\}.
 \tag{A1}
\]

For binary model choice with equal prior probabilities, every
classifier \(\delta(H_T)\) therefore has error risk at least

\[
 R(\delta)\geq
 \frac12
 \left(
 1-\min\left\{1,\sum_{t=0}^{T-1}\varepsilon_t\right\}
 \right).
 \tag{A2}
\]

**Conditional proof.** Couple the two models' initial histories
identically. While their histories agree, run the common
history-dependent policy using the same randomization, then
apply a maximal coupling to the two next-observation kernels.
Conditional on a common history at time t, the probability the
next reports differ is their total-variation distance and is at
most \(\varepsilon_t\). Stop trying to keep the chains matched
after their first disagreement. The probability of any mismatch
by time T is at most the sum of the per-round mismatch
probabilities by a union bound. Since total variation between
the laws of two random variables is at most their disagreement
probability under **any** coupling, (A1) follows, additionally
bounded by 1. The equal-prior optimal binary testing risk
identity is \((1-\operatorname{TV})/2\), yielding (A2). □

**The result is only as good as its uniform kernel bound.** A
bound on one-time marginals *without conditioning on observed
histories* does not give (A1); time-series correlations,
strategic signalling and selection can make longer histories
much more informative than single cross-sectional reports.

## 3. Implications and limits

**Exact equality.** If \(\varepsilon_t=0\) on every policy-reachable
history, the entire trace laws are identical. Repeating such
encounters, even with adaptive decisions based on prior reports,
does not identify the model. This is conditional nonidentification,
not a global assertion that persons are unknowable.

**Small differences.** If a feasible two-round design satisfies
\(\varepsilon_0,\varepsilon_1\leq 0.05\), then the bound only
guarantees binary model-classification error \(\geq0.45\), given
equal priors; it does **not** assert the true error is exactly
0.45. These numbers are illustrative, not estimated.

**High-discrimination but inadmissible encounter.** A potential
action with large TV may be excluded by consent. Its existence
does not change the uniform bound over genuinely permitted
policies. However, refusal itself might carry observable
information, so the conditional kernels must include it rather
than assume it away.

**Consequences for decision relevance.** A model may be
unidentifiable but some admissible decisions can remain
well-determined under both models; identity of the mechanism
need not be a prerequisite for making those decisions. Conversely,
a model-discriminating intervention may be ethically unavailable.
This links old Tractatus §2.7 and §6.92 to the revised §§2.3, 4.3,
5.2 and 6.4 without presenting them as proved psychological laws.

**Costs of interventions.** A voluntary encounter may
change the relational state, future action sets, and model
observability. Formula (A1) applies to the resulting trace
kernels **if its assumptions hold**; it does not claim that a
more informative policy is always preferable or that a
stationary model is realistic.

## 4. What this does not establish

- A metric for latent human compatibility.
- Whether any observed change reflects revelation, preference
  formation, demand, or relational constitution.
- Uniform conditional TV bounds from the existing data.
- An unconstrained two-player dynamic game in which private
  willingness and policies are jointly inferred.
- A new research result in probability theory.
- A Lean-kernel check of (A1) or (A2).

The existing Lean module verifies the **one-report binary**
equal-prior testing identity with integer counts. Proving a
useful multi-round theorem with private information,
model-dependent feasible actions, and jointly voluntary
policies remains open.

## 5. Background and review standard

This is a direct application of the classical coupling
characterization of total variation and statistical hypothesis
testing. The project should compare it with work on
Le Cam's two-point method, Blackwell comparison of
experiments, adaptive sequential design, and controlled
Markov processes. For background on Blackwell comparisons:
[Blackwell 1953](https://doi.org/10.1214/aoms/1177729032).
For the causal problems of sequential interventions:
[Hernán and Robins, *Causal Inference: What If*](https://www.hsph.harvard.edu/miguel-hernan/causal-inference-book/).

The research contribution, if any, would be a *new and
substantiated application* with meaningfully constrained
permitted-policy sets, calibrated observation models and
informative empirical outcomes. A familiar probability
bound by itself is not that contribution.
