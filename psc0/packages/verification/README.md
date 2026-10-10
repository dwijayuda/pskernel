# General verification proposal infrastructure (experimental)

This private, NON-AUTHORITATIVE development module defines
`psc-required-obligations/0`, `psc-verification-proposal/0`, and
`psc-verification-preflight/0` data schemas. The version-0 API deliberately
has no accepted/certified branch. Even a candidate matching every listed
obligation has **not** proven that the list was complete, the proofs were
admitted, its specifications approved, imported assumptions permitted, erasure
safe, or emitted code semantics preserving.

The obligations *must eventually* originate from an independently qualified
source/semantics/coverage process owned by the authoritative supervisor.
An untrusted proof/VC generator may return candidates for those exact goals.
This module does not implement a sound full verification-condition generator,
proof replay, trusted environment, or PSCV-CERT-v1.

`inspectProofCandidates` does not publish, execute npm scripts, start Lean,
or communicate with PSKernel Core. Its output is a diagnostic advisory that
cannot become the compiler's certificate token. The adjacent
`psc0/scripts/pscv-certification-gate.mjs` is supervisor-owned and refuses
verified executable authorization until an independently qualified
implementation replaces that explicit unavailable state.

Development/test only. No dependency from Ps.Bootstrap.SelfHost, no change
to the currently qualified compiler/kernel, and no public npm package.
