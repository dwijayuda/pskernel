# What repeated reports identify

This extension of the one-step identification model follows a fixed population across a finite sequence of encounters. An encounter can move a share of the remaining false state into the true state when both participants accept. The true state is absorbing, the population is conserved, and one measurement channel applies throughout. The reported quantities are population marginals.

Lean checks that cumulative movement telescopes into net prevalence change. With channel discrimination q and cumulative movement M, the report contrast from the baseline is exactly q times M. If the channel is calibrated and informative, the baseline and final reports determine total movement. They leave its timing open. A machine-checked example has identical endpoint reports but a 62.5% intermediate report probability when movement occurs early and 37.5% when it occurs late.

## Intermediate waves under unknown calibration

For true-state baseline prevalence p and positive final contrast Δ, the one-step sharp bounds apply to cumulative movement. Even if every intermediate marginal report is available, an invariant but unknown channel need not narrow the bounds. Suppose the observed probabilities y(t) are nondecreasing. For any feasible cumulative movement and channel from the endpoint construction, set the cumulative movement in round t to (y(t) − y(0))/q. These quantities are nondecreasing, start at zero, and end at the candidate total movement. Their successive increments are feasible one-way movements because their sum fits the original false mass. With rational data and a rational candidate, a single common count denominator encodes the whole sequence. This construction requires that positive increments occur at encounters both participants accepted. A positive jump at a known closed encounter contradicts this version of the model.

The intermediate waves nevertheless constrain timing. For a positive final contrast, the fraction of cumulative movement completed by a given wave equals its share of the final report contrast. Exact population contrasts are assumed here. Sampling uncertainty, the joint distribution of repeated reports on the same dyads, time-varying reporting, and reverse movement may change what can be inferred. The intermediate-wave sharpness and timing fraction are written derivations. The Lean module checks mass balance, the general repeated-report contrast, and the timing counterexample.

See the [one-step sensitivity study](IDENTIFICATION_SENSITIVITY.md) for the calibration, reporting, and participation assumptions.
