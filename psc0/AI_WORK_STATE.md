# PSC0 AI work state — PSCV0 readable-source bridge implementation

## Active direction

Branch: `psc0/pscv0-readable-selfhost-v1`, created from immutable adoption checkpoint `b64a95e4537dade93462e0232b5da54d79f9cb25` on `psc0/npm-modular-packages-v1`. The original npm branch, main, kernel source and kernel-proof branches are not changed by this experiment.

The user's uploaded PSCV0 reference is authoritative for new language design. Its exact local attachment was re-hashed before this implementation: 230234 bytes, SHA-256 `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0`. Semantic source pin: Lean4.35.0-rc4 `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. The existing bootstrap/runtime remains 4.34 based. These identities must not be conflated.

## First coherent slice

Implement a portable high-level source representation for **declaration-level, explicitly Except-typed do blocks** with simple identifier/wildcard binds, immutable lets, term actions and terminal return. Retain `do` until source printing; lower separately to ordinary existing typed matches/lets/constructor applications. Support paired owned PS-braced and native-Lean-layout source readers and printers. This is a bounded capability of PSCV0, not complete PSCV0 or a second user-selectable legacy grammar.

New code lives in `packages/syntax/src/Ps/Syntax/Pscv0/`. It is written in the existing seed-consumable `.lean` subset as the bootstrap bridge, not in handwritten host JavaScript. The old compiler sources and public CLI remain unchanged until this bridge is qualified and broader source rules can be adopted coherently.

No loops, mutation, nested do, early return, general monads, new kernel rules, new backend, tactic framework, class/instance language or full compiler-source authority switch is part of this slice. Original source is retained verbatim; canonical cross-source printing must refuse unsupported trivia rather than silently drop comments.

## Qualification plan

Compile only the syntax bridge dependency closure using the retained self-hosted compiler. Exercise the generated bridge, not a handwritten replacement, through positive/negative syntax tests, PS/Lean high-level round trips, hygienic lowering, exact fixture admission comparisons and ordinary generated-JS behavior. Keep compiler-generating checks distinct from independent kernel checking. No full C2/C3 or kernel regeneration unless later explicitly required for seed promotion. Existing exact-source guards remain unchanged, and do not qualify new source merely by repinning them.

All code execution uses GitHub cloud CI. Use expected-HEAD non-force writes; no local repository checkout/build/test, Desktop Commander, npm publication or unrequested merge. Reading/hash-identifying the uploaded reference is allowed attachment processing, not a repository build.

## Status

Implementation is being prepared. No new compiler conformance, bridge compilation or self-host success is claimed before actual CI results. Preserve the full previous work state at `docs/history/AI_WORK_STATE_BEFORE_PSCV0_BRIDGE.md`.
