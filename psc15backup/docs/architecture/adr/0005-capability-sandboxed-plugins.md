# ADR 0005 — Capability-sandbox third-party semantic plugins

**Status:** Accepted design direction; broad plugin execution is post-bootstrap work.

## Context

ProofScript needs extensibility without giving arbitrary package code ambient filesystem/network/process access or semantic authority.

A manifest alone does not sandbox in-process JavaScript.

## Decision

Third-party semantic plugins use explicit capability contracts and execute in a real isolation boundary where practical.

Preferred order:

1. Wasm Component/WASI-style sandbox with explicit imported capability interfaces;
2. isolated worker/process with bounded RPC;
3. in-process execution only for explicitly trusted plugins.

Plugin manifests declare:

```text
plugin/API identity
plugin kind
determinism
source/Core/Meta compatibility
requested capabilities
target restrictions
input/output contracts
```

No plugin can construct CheckedCore or bypass IR validation.

## Consequences

- compiler extension ecosystems can grow without ambient host authority;
- deterministic semantic plugins are cacheable/reproducible;
- filesystem/network/process access becomes reviewable;
- InterfaceIR/capability worlds become important platform contracts.

## Rejected alternative

Do not import arbitrary npm plugin JavaScript into the compiler process and treat declared permissions as enforcement.
