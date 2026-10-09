# Bounded cache eligibility experiment (proof-synchronized PSKernel)

Parent pinned: `7bd41fe7059b3628780dc07716ea9f9f7d5a3075`. Candidate imports only the *non-semantic cache-publication eligibility* from the preceding Arena lane `756f4b9175edc11adf19b6b50586af762d296edc`. No declaration admission bypasses, fuel changes or proof-checking shortcuts.

The eligibility scan must reject every cache key containing a free variable and additionally avoids caching expression keys larger than 256 visited expression nodes; smaller closed keys have identical eligibility as the parent. Actual structural hashing and cache key equality remain unchanged. A cache miss must not accept an invalid term.

Validation: candidate full foundation differential + level regression + pinned prelude, followed by same-runner identical input A/B at 200k/362100/380k Init prefixes (twice/reversed), then tutorial/negative corpus if promising.

Observe any regression in inferred types, error classification or valid proof acceptance; no speedup claim without green verdicts and measured timings. Full Init/Std/Mathlib still pending.
