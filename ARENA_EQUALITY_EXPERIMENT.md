# Shape-first expression equality A/B

Base kernel: `7bd41fe7059b3628780dc07716ea9f9f7d5a3075` (proof-synced v2, production checker from proof branch `5a7d428b303a865b14a81e6bcb4a6e38050d9165`).

This isolated experimental branch substitutes only `psKernelExprEq` with the equal-result, shape-first structural comparison already exercised on the earlier Arena branch `756f4b9175edc11adf19b6b50586af762d296edc`. No checker acceptance rules, fuel bounds, cache-scope eligibility, or proof modules are intentionally changed.

The same-runner A/B workflow builds both base and candidate and checks identical 200k, 362100, and 380k exported record prefixes in reversed execution order. `psKernelExprEq` must return exactly the same Boolean; any failed regression or changed verdict invalidates this candidate.

The large-init timeout is not solved or Mathlib-complete merely because this experiment passes. Full official Init, Std and Mathlib validations remain pending.

If this fails to deliver a material speedup, revert/leave experiment unmerged and investigate repeated cache scans/hashing, reduction/DefEq costs and architectural DAG sharing; do not claim gains from uncontrolled runner comparisons.
