# ADR 0003 — Separate construction IR from VerifiedIR

**Status:** Accepted design direction; current `PsVerifiedIrType.unknown` shows why the migration is needed.

## Context

The current compiler IR is target-neutral and valuable, but the type `PsVerifiedIrType` includes `unknown`, and erasure can produce unresolved runtime-type placeholders.

That is useful during construction but weakens the long-term meaning of “VerifiedIR”.

## Decision

Use two stages:

```text
CheckedCore
 -> ErasedIR / RuntimeIR
 -> validateRuntimeIr
 -> VerifiedIR
```

Construction IR may contain unresolved/temporary forms. VerifiedIR may not contain unresolved executable semantics.

## Minimum validator obligations

- names resolve;
- calls/arity/types are valid;
- structures/constructors/fields exist;
- intrinsics satisfy their signatures;
- match alternatives are well formed;
- executable types have target-neutral runtime representation;
- external/module references are valid;
- required runtime primitives exist.

## Consequences

Backends can rely on stronger invariants and become simpler. Negative validation tests become a reusable security/correctness boundary. The word “verified” corresponds to an actual executable validator contract rather than only pipeline provenance.
