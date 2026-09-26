# ProofScript self-host documentation

This directory is the active implementation workspace for the PSC1 Lean-first
self-host. The normative planning documents are split by phase so post-PSC1
platform work does not accidentally become a blocker for the current compiler
closure.

## Current self-host closure

See [`SELFHOSTING.md`](./SELFHOSTING.md) for the active bootstrap, fixed-point,
source-transition, Rust-native and Wasm-backend execution model.

See [`../docs/plans/07_SELF_HOSTING_FOUNDATION.md`](../docs/plans/07_SELF_HOSTING_FOUNDATION.md)
for the authoritative PSC1 foundation gates and REQUIRED/OPTIONAL language
policy.

See [`../docs/selfhost/PSC1_LEAN_BOOTSTRAP.md`](../docs/selfhost/PSC1_LEAN_BOOTSTRAP.md)
for the Lean-first compiler architecture and package migration model.

## Post-PSC1 extensible platform

See [`../docs/selfhost/POST_PSC1_PLATFORM.md`](../docs/selfhost/POST_PSC1_PLATFORM.md)
for the platform architecture that follows the first stable PSC1 JavaScript
self-host fixed point and `.ps` source transition.

That roadmap adds seven major platform surfaces without reopening PSC1 scope:

1. versioned Core / CheckedCore / VerifiedIR contracts;
2. explicit effect/capability semantics;
3. a Meta + tactic API;
4. a controlled plugin API;
5. InterfaceIR + generated FFI;
6. backend-neutral Task/Stream + Resource semantics;
7. semantic package manifests plus law/conformance infrastructure.

It also defines the extension decision ladder:

```text
library
  -> FFI / InterfaceIR
  -> desugaring
  -> controlled plugin
  -> Core proposal
  -> pskernel proposal only as the last resort
```

None of these post-PSC1 platform items is a retroactive SH7 or PSC1 completion
gate unless a real current compiler blocker proves that the existing PSC1
foundation is insufficient.
