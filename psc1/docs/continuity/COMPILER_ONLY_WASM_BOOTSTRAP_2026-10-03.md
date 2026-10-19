# Compiler-only bootstrap with Lean WASM default — 2026-10-03

Base commit: `234ff270404687b5313f96241bbea98a4ad12ea4`.

The bootstrap policy is intentionally changed: `pskernel-core` is preserved but
removed from the generated bootstrap closure and marked `proofscript.bootstrap=false`.
`pskernel-lean-wasm` is also non-bootstrap and becomes the default **host-side**
checker. The native Lean provider and owned checker remain explicit alternatives.

The compiler composition root imports only `Ps.BackendTs.Compiler`. Kernel checking
happens at the checked-build boundary after canonical admissions are produced. This
keeps the self-hosted artifact to the compiler while retaining real Lean kernel
validation.

No provider failure falls back to another checker. Existing owned-kernel source,
tests, manifests and historical evidence are retained; this change does not claim that
owned-kernel development is complete.

Success for this workstream is a compiler fixed point checked by the default WASM
provider: stable canonical generated source plus exact generated TypeScript parity
across bootstrap, selfhost and repeat generations.
