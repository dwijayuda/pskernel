# What two encounter policies can identify

This note extends [revelation versus change](REVELATION_VS_CHANGE.md) and the interpretation of *Tractatus de Perceptione et Amore* §6.92. It distinguishes three questions. Does the encounter change a latent outcome? How much probability mass changes? How much do reports change under an offer policy? The third question can be answered in settings where the first two remain unresolved.

## When the amount of change is identified

Let p be the initial probability of the true latent state, and let m be the probability mass that moves from false to true. The transition is one-way, so 0 ≤ m ≤ 1−p. Let c₀ and c₁ be the positive-report probabilities in the two latent states, and let q = c₁−c₀. The passive report probability is y₀ = c₀ + p q. If the policies start with the same latent distribution and share the same measurement channel, the active report probability is y₁ = c₀ + (p+m) q. Their difference is Δ = m q. A known nonzero q identifies m from the observed contrast. The baseline p is unnecessary for this division, although it constrains feasibility. Lean checks the numerator equation and uniqueness for a strictly oriented calibrated channel with a common count representation.

If transitions can run in both directions, the same calculation identifies the net change in prevalence under calibration. It cannot recover how many dyads moved in either direction. Offsetting transitions can leave both prevalence and report probabilities unchanged.

## Sharp bounds with unknown calibration

Suppose 0 < p < 1 is known, Δ > 0, measurement is invariant, and the measurement is positively oriented but its discrimination is unknown. Write

    q_max = min(y₀/p, (1−y₀)/(1−p)).

The conditions c₀ ≥ 0 and c₁ ≤ 1 imply q ≤ q_max. The one-way transition and the observed positive contrast imply q ≥ Δ/(1−p). The model is feasible exactly when the resulting interval for q is nonempty. For compatible data its sharp set for moved probability mass is

    Δ/q_max ≤ m ≤ 1−p.

For any m in this interval, set q = Δ/m, c₀ = y₀ − p q and c₁ = y₀ + (1−p) q. These choices are feasible and reproduce both observed probabilities. This proves sharpness over real-valued probabilities and supplies rational witnesses for rational inputs and candidate masses. The bounds and their sharpness are written proofs. The current Lean module checks the exact contrast and explicit observationally equivalent mechanisms.

With p = 1/4, y₀ = 3/8, and y₁ = 5/8, the data identify positive movement and constrain it to [3/10, 3/4] under these assumptions. These endpoints are attainable: movement 3/10 uses report probabilities (1/6, 1), and movement 3/4 uses (7/24, 5/8). Information about the measurement channel narrows this interval.

## Four mechanisms, one pair of observed laws

Each row below gives the same passive and active report probabilities, 3/8 and 5/8. The scenarios are constructed witnesses, with no estimates of real behavior.

| Explanation | Initial latent prevalence, passive / active | Moved probability mass | Positive-report probabilities in the false / true states |
|---|---|---:|---|
| Calibrated change | 1/4 / 1/4 | 1/2 | (1/4, 3/4) under both policies |
| Another invariant calibration | 1/4 / 1/4 | 2/3 | (9/32, 21/32) under both policies |
| Change in reporting | 1/4 / 1/4 | 0 | (1/4, 3/4) passive, (1/2, 1) active |
| Different participation | 1/4 / 3/4 | 0 | (1/4, 3/4) under both policies |

The first two rows identify the role of independent calibration. The third shows why a more positive report could reflect a changed response process. The fourth shows why comparing people who accepted with a different comparison group can change the composition of the sample. Lean checks equality of the full binary report law in all four cases, via a common denominator and matching positive numerators.

## Empirical design implications

- Specify a relational outcome narrow enough to assess, such as whether the dyad has established a particular coordination routine, and specify whose reports measure it. A reported sense of connection may itself be an outcome of interest, distinct from a report used as a proxy for a separate relational state.
- Randomize a voluntary offer and compare by assigned offer when the question concerns the offer's effect on the observed report. Keep assessment timing and measurement procedures comparable, follow both groups, and document missingness. Acceptance expresses both participants' agency and can be associated with their existing relationship. A comparison restricted to acceptors calls for additional causal assumptions. An instrumental-variable interpretation also requires assumptions about how assignment affects the outcome, including exclusion of other pathways. [Angrist, Imbens and Rubin](https://doi.org/10.1080/01621459.1996.10476902)
- Calibrate the measurement independently where possible. A behaviorally anchored task scored without knowledge of assignment is one possible additional indicator. Agreement between two measures is insufficient on its own to establish validity. Latent-class calibration can work under specific assumptions, such as shared error rates and conditionally independent errors across tests, which require substantive justification here. [Hui and Walter](https://pubmed.ncbi.nlm.nih.gov/7370371/)
- Prespecify the observed-report contrast, the assumptions supporting a latent interpretation, and the corresponding identified set or sensitivity analysis. The sharp set above describes structural uncertainty at known population probabilities. Sampling error and loss to follow-up require separate analysis.

The philosophical distinction between what was already there and what took shape together survives this sensitivity analysis. A study has to earn the inference from an observed change to either explanation.
