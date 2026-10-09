# PSKernel Core Arena v2 — proof-synchronized test lane

Created 2026-10-09 from proof branch commit `5a7d428b303a865b14a81e6bcb4a6e38050d9165`.
Ports the existing Arena host adapters from `756f4b9175edc11adf19b6b50586af762d296edc`, without copying its divergent production kernel code.

- `pskernel-core/src/**` and current proof files inherit the proof branch's newest source.
- The existing Arena v1 branch remains intact as the performance baseline; this new branch does not merge or overwrite it.
- The 4.34.1 Arena export metadata bridge remains distinct from the kernel's Lean 4.34.0 semantic pin.
- Ported code and native tests must pass cloud CI before being considered verified on v2.
- Full Init/Std/Mathlib are NOT yet green on v2. Preserve zero false acceptances.
- Next: instrument the hot Init interval around record 362,000 and run controlled full-corpus validation.
