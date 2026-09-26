# 11. Effects and Host Capabilities

Real programs eventually need to interact with a world that changes.

Files are read.

Errors happen.

State evolves.

Time passes.

PSC1 keeps these effects explicit rather than letting backend behavior leak
into ordinary pure functions.

## Pure core

This function is pure:

```proofscript
function normalizeCount(x: Nat): Nat :=
  x + 1;
```

Its result depends only on its input.

## Compiler effects

A self-hosted compiler needs:

- immutable context;
- mutable compiler state;
- typed recoverable failure;
- sequencing;
- rollback for speculative work.

The first PSC1 profile therefore needs a concrete reader/state/error effect.

## `pure`

`pure` lifts an ordinary value into an effectful computation.

Conceptually:

```text
pure: α -> CompilerM(α)
```

## `bind`

`bind` sequences computations:

```text
bind: CompilerM(α) -> (α -> CompilerM(β)) -> CompilerM(β)
```

## `do`

`do` is readable notation for explicit sequencing.

It is not JavaScript Promise syntax in disguise.

The semantics belong to the PSC1 effect abstraction.

## State

Compiler state may include:

- fresh IDs;
- metavariables;
- environments;
- diagnostic accumulation;
- parser/elaboration caches.

State changes must be explicit enough to support rollback.

## Typed failure

Recoverable failures should use a declared channel.

A backend may internally throw an exception, but the PSC1-visible semantics
should remain the declared typed effect.

## Transactional rollback

Speculative parsing or elaboration often does:

1. remember current state;
2. try one interpretation;
3. if it fails recoverably, restore state;
4. try another interpretation.

Without rollback, failed alternatives could leak metavariable assignments or
environment changes.

## Filesystem and process APIs

These are host capabilities.

A JavaScript backend may use Node.

A Rust backend may use native OS APIs.

A Wasm backend may use WASI.

PSC1 source should depend on a capability contract, not on the accidental API
shape of one host.

## Asynchrony

Asynchronous programming is important, but PSC1's first freeze does not define
JavaScript Promise/event-loop semantics as portable source behavior.

A future task/async model should be specified backend-neutrally before becoming
a PSC1 language feature.

## Exercises

1. Classify these as pure or effectful: list length, current time, file read,
   integer addition, random number.
2. Sketch a compiler state containing a fresh-name counter.
3. Explain why a failed speculative elaboration must roll back metavariables.
4. Describe how the same file-read capability could be implemented by Node,
   native Rust, and WASI.
