# Arena optimized v3 acceptance

Proof source base: `5a7d428b303a865b14a81e6bcb4a6e38050d9165`.
Candidate base: `e1166c00c3e1e92bf3e67149c4b85b85461db35d` (proof-synced Arena v2).
Only production source change: 256-node bounded semantic cache eligibility from Arena cache A/B experiment `9dab024b28697ed1233e4d8f9198d16cfe40c1a4`.
CI gates: full PSKernel proof tree/erasure, native foundation/Prelude, tutorial 141/141, historical negative corpus with zero false accepts, and official full Init+Std.
Full Init/Std use upstream Arena's original timeouts. Timeout is failure, not decline or acceptance. Preserve JSON results.
Full Mathlib remains pending until full Init+Std pass. No changes to proof, integration, old Arena, or v2 branches.
