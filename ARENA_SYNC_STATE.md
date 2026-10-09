# PSKernel Core Arena v2 — proof-synchronized test lane

Created 2026-10-09 from proof branch commit `5a7d428b303a865b14a81e6bcb4a6e38050d9165`.
Ports the existing Arena host adapters from `756f4b9175edc11adf19b6b50586af762d296edc`, without copying its divergent production kernel code.

- `pskernel-core/src/**` and current proof files inherit the proof branch's newest source.
- The existing Arena v1 branch remains intact as the performance baseline; this new branch does not merge or overwrite it.
- The 4.34.1 Arena export metadata bridge remains distinct from the kernel's Lean 4.34.0 semantic pin.
- Ported code and native tests must pass cloud CI before being considered verified on v2.
- Full Init/Std/Mathlib are NOT yet green on v2. Preserve zero false acceptances.
- Next: instrument the hot Init interval around record 362,000 and run controlled full-corpus validation.

## Observed cloud validation (2026-10-09)

## Arena synced-v2 verified cloud checkpoint — 2026-10-09

- Proof source base: `5a7d428b303a865b14a81e6bcb4a6e38050d9165` (`pscv/prove-pskernel-core-v1`); latest proof HEAD at this checkpoint: `5a7d428b303a865b14a81e6bcb4a6e38050d9165`. Neither source proof nor integration branches were modified by the Arena work.
- Synced v2 head before this documentation commit: `7bd41fe7059b3628780dc07716ea9f9f7d5a3075`.
- Verified native + pinned Init.Prelude readiness, level compatibility and portable foundation differential: Actions run `37922744077`, native job `113794341591` SUCCESS. Prelude 70,484 records / 2,038 declarations / 2,324 constants, 0.62s / 78,080 kB peak.
- Same Actions run tutorial job `113794786365`: 141/141 correct, 0 incorrect, 0 errors.
- Historical negative/soundness Actions run `37922744066`, job `113794341621`: 17 correct + 1 conservative decline, 0 false accepts.
- Host-only 380,000-record prefix profiling Actions run `37922810339`, job `113794559897`: 380,000 accepted, 4,014 declarations, 154.66s / 306,584 kB RSS. This is diagnostic prefix evidence, not full Init acceptance.
- Largest admissions in that trace: exported line 361999 (`Array.extract_append_extract._proof_1_1`) 63,278ms, 373249 (`_proof_1_3`) 28,125ms, 377172 (`_proof_1_2`) 6,928ms. These three account for ~98.33s. The full 380k trace has 63 records >=150ms totaling 139.1s.
- Independent cloud experiments (NOT accepted improvements): `pscv/pskernel-core-arena-equality-ab` compares shape-first expression equality; `pscv/pskernel-core-arena-cache-ab` compares bounded cache eligibility; both compare against this proof-synced baseline. Do not merge them without green correctness and repeatable performance evidence.
- Full official Init (500s) and Std (590s) remained timeouts on historical Arena v1; full Init/Std/Mathlib on v2 have NOT been accepted. No Mathlib-complete claim.

## External rationale

Lean's expression representation caches per-node hash and free-variable metadata. PSKernel's portable expression representation currently recomputes recursive structural equality, cache-key eligibility and hashing. This mismatch is a candidate cause of the proof-admission cost; only measured A/B experiments can determine which mechanisms dominate on the hot Init proofs.

The recorded 380k prefix pass must never be promoted to full Init or Mathlib completeness. Do not silence timeout/unknown outcomes.

## Arena proof-synced A/B conclusion — 2026-10-09

- All three isolated experiments passed their same-runner cloud A/B jobs (all tested prefix inputs accepted; exit 0). **A/B success is not full semantic assurance.**
- Strong performance winner: **bounded semantic cache key eligibility**, experiment `pscv/pskernel-core-arena-cache-ab` at `9dab024b28697ed1233e4d8f9198d16cfe40c1a4`, Actions #37923962388. The candidate rejects memoization for any key whose subtree exceeds a 256-node traversal budget and still rejects free-variable keys; it never skips checking or bypasses semantic admission.
- Bounded-cache controlled averages: 200,000 records, baseline 10.965s vs candidate 10.935s (~0.3%); 362,100 records 71.175s vs 45.57s (~36.0%); 380,000 records 89.765s vs 53.925s (~39.9%). Peak RSS at 380k ~309.6MB baseline vs ~299.2MB candidate. Same-runner order: baseline-1, candidate-1, candidate-2, baseline-2.
- Bounded-cache candidate foundation differential, Arena level regressions and pinned Init.Prelude passed before the A/B; tutorial/negative, full proof gate and full official Init/Std/Mathlib still need to run **on the optimized candidate**.
- Shape-first inference-cache eligibility, `pscv/pskernel-core-arena-cache-order-ab` at `a178c619bce5ef415d2cb578f3169c4b5d17989c`, Actions #37924378742: 380k baseline average 132.425s vs candidate 130.43s (~1.5% faster), no compelling improvement. Foundation/level/prelude checks passed.
- Shape-first structural equality, `pscv/pskernel-core-arena-equality-ab` at `3beec6b575e452f23d6cb76d780218d5149398e8`, Actions #37923775015: 380k baseline 154.79s vs candidate 155.77s (~0.6% slower). Foundation check passed; do not merge on performance grounds.
- Different A/B workflow runners have significantly different absolute timings; *only compare candidate vs baseline inside each identical-runner run*. Do not compare the 53.925s bounded-cache candidate to 155.77s equality candidate as if they were controlled against each other.
- Proof-source HEAD remains `5a7d428b303a865b14a81e6bcb4a6e38050d9165`, with kernel-proofs and portable-erasure CI #37919437449 green. Existing synced-v2 kernel acceptance is 141/141 tutorial, 17 correct + 1 conservative decline on 18 historical cases, pinned prelude and native/foundation green. These are from unoptimized synced-v2, not automatically a green signal for bounded-cache candidate.
- Full Init is historically timed out at Arena 500s and Std at 590s, without a confirmed semantic reject. Full Mathlib is not yet run.

**Next engineering sequence:** validate bounded-cache candidate using proof tree + 141 tutorials + negative corpus; then run official full Init and Std under original Arena time limits with exact `status`, `stderr`, wall and RSS evidence. Integrate into synced-v2 only after proof and correctness gates pass. If full results still time out, collect per-declaration traces beyond 380k to isolate other superlinear families; after full Init+Std are green, stream full Mathlib. Never weaken kernel fvar cache-scope invariants, admission, fuel safety or acceptance semantics.
