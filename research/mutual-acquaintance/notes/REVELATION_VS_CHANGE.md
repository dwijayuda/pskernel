# Can an encounter distinguish revelation from change?

This note extends the working paper's §6.5 and interprets *Tractatus de Perceptione et Amore* §6.92. It compares two explicit one-step stochastic mechanisms. The estimand is the change in the population probability of a narrowly defined binary relational outcome under a fixed, mutually feasible encounter policy. An example target could be whether the dyad has established a specific coordination routine before a later assessment. The mathematical bit stands for whatever outcome a study operationalizes.

## Model

Let the initial latent state have false mass n₀ and true mass n₁, with positive total N. A count of n divided by N denotes an exact rational probability. The stable mechanism preserves the latent state. The change mechanism moves m units from false to true when a step is offered and both independently recorded approvals are present. The model allows statistical dependence between participants in applications. Here approvals define the compared policy context and are held fixed independently of the latent draw. When the initial false mass is positive the switch probability is m/n₀. It can be any rational in [0,1] by choosing a suitable count representation. The policy may leave the state unchanged.

Both mechanisms use the same measurement channel. The positive report probability is c₀/K in the false state and c₁/K in the true state, with positive K and both c values between 0 and K. The same measurement is taken after either policy. The passive policy leaves m at zero. Even under that policy a noisy report can reveal information about the existing state when the prior gives positive mass to both states and c₀ and c₁ differ.

## Exact criterion

For the accepted step, the difference in positive-report probabilities between the change and stable mechanisms is

    m (c₁ − c₀) / (N K).

The displaced false mass would have contributed m c₀ in the stable mechanism and contributes m c₁ in the change mechanism. All remaining mass contributes the same under both. The negative-report difference is the additive inverse. Thus the complete report laws agree exactly when m = 0 or c₀ = c₁. This gives passive equivalence, a sufficient separating policy, and the degenerate cases in which even an accepted step cannot separate the mechanisms.

The finite filter first forms the correct next-state count pair, then multiplies each count by the appropriate row likelihood. Dividing by their sum gives the posterior when report evidence is positive. Lean proves the report counts sum to the common denominator and represents the posterior by a positive-total count pair. The code uses integer arithmetic with an exact rational interpretation, with no floating point or external probability library.

### Witness and filtered prediction

With initial counts (3,1), movable mass 2, channel numerators (1,3) and denominator 4, the positive report has probability 6/16 for both models under the passive policy. Under the accepted policy it remains 6/16 for the stable mechanism and rises to 10/16 for the change mechanism. In the latter case the posterior probability of a true relational state after a positive report is 9/10. The 1/4 difference in report probabilities is a contrast between model predictions.

## Identification and limits

This is population-level discrimination inside a specified two-model class. Different probability laws can still produce the same observed outcome in one dyad or finite sample. If the reporting contrast is known and nonzero, the population report difference recovers m/N by dividing by that contrast. If the contrast is unknown, the report difference determines only their product. A changed channel, for example because the encounter affects willingness to report, or differing latent distributions across policies could also produce the observed contrast. Comparable selection, measurement invariance and explicitly modeled approvals are therefore substantive design assumptions. A real study would need independent evidence for them.

The model isolates one transition and a binary follow-up. Private observation histories, endogenous approvals, multiple rounds, sampling uncertainty, and empirical calibration are subsequent research questions.

The Lean correspondence is in [the identification module](../lean/MutualAcquaintanceIdentification.lean). The main results are `same_report_law_iff`, `passive_agreement`, `accepted_step_separates`, `report_total` and `posterior_total`. Both the general criterion and the numerical witness are checked by the same Linux workflow as the earlier modules.
