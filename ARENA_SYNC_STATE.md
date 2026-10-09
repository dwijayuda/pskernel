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
