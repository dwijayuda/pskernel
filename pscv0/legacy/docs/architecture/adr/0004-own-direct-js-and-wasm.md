# ADR 0004 — Own direct JavaScript and WebAssembly backends

**Status:** Accepted design direction; direct JS is planned, direct Wasm already exists as an extension.

## Context

The current bootstrap emits TypeScript and invokes a pinned TypeScript compiler. Rust and Lean provide useful external compilation paths. Relying exclusively on downstream source languages weakens bootstrap independence and makes the strongest backend-correctness claims depend on much larger external compilers.

## Decision

ProofScript should own two canonical portable executable paths:

```text
VerifiedIR -> JsIR   -> deterministic .js
VerifiedIR -> WasmIR -> deterministic .wasm
```

Direct JS is the long-term canonical JS/npm bootstrap/runtime backend. Direct Wasm is the strongest portable executable assurance target.

Keep TypeScript, Rust, and Lean as optional adapters, ecosystem integrations, optimization routes, and independent differential/provenance oracles.

## Consequences

- the canonical self-host path can eventually remove `tsc`;
- npm compatibility remains through `.js` + generated `.d.ts`;
- Wasm remains independent of JS/Rust lowering;
- multiple independent backends support differential execution;
- machine-code optimization can remain delegated to Lean/Rust toolchains where useful.

## Non-goals

- proving all ECMAScript;
- making Wasm layout part of VerifiedIR;
- deleting the TS/Rust/Lean backends.
