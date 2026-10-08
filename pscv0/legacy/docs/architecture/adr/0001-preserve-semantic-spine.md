# ADR 0001 — Preserve the semantic spine

**Status:** Accepted design direction; implementation evolves incrementally.

## Context

The current compiler already separates frontend elaboration, Core, erasure, target-neutral compiler IR, and backends. Forward plans add an owned kernel, direct JS, stronger Wasm assurance, InterfaceIR, plugins, capabilities, package/build systems, and formal verification.

A tempting growth strategy would be to collapse boundaries to reduce short-term implementation work.

## Decision

Preserve this direction:

```text
source
 -> smart frontend
 -> CandidateCore
 -> pskernel-core
 -> CheckedCore
 -> erasure
 -> runtime/construction IR
 -> validator
 -> VerifiedIR
 -> target IR/backend
```

Platform capabilities grow around/above this semantic spine rather than redefining it.

## Consequences

Positive:

- kernel authority remains small;
- backend implementations stay target-specific and replaceable;
- formal proof obligations compose by adjacent transformations;
- untrusted plugins/tactics can remain outside foundational authority;
- direct JS/Wasm, Lean, Rust, and TS can coexist without changing PSC semantics.

Costs:

- more explicit artifact/contract types;
- adapters and validators must be maintained;
- some short-term duplication is preferable to collapsing semantic layers.

## Rejected alternatives

- Core directly emitting JS/Wasm;
- putting target representation in VerifiedIR;
- making TypeScript/Rust/Lean semantics define PSC;
- expanding the kernel for ecosystem convenience.
