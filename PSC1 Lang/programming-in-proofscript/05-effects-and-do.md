# 5. Effects and `do`

Functional Programming in Lean develops monads and transformer stacks as a
general effect toolkit.

PSC1 takes the semantic lesson while freezing a smaller first language.

## Pure computation

Ordinary portable functions are referentially transparent with respect to PSC1
semantics.

```proofscript
function increment(x: Nat): Nat :=
  x + 1;
```

Calling this function cannot secretly read the current process environment or
mutate a host-global variable.

## The compiler needs effects

A real self-hosted compiler needs at least:

- immutable context;
- mutable logical/compiler state;
- recoverable errors;
- speculative rollback.

PSC1 therefore requires a concrete reader/state/error compiler effect.

## `pure` and `bind`

The semantic core is conventional:

```text
pure : α -> M α
bind : M α -> (α -> M β) -> M β
```

Exact source/library names are part of the frozen self-host API rather than a
license to assume every Lean monad class is present.

## `do` notation

`do` makes sequencing readable.

The notation must elaborate to the explicit effect semantics.

It does not mean:

- JavaScript Promise chaining;
- implicit async;
- Rust's statement semantics;
- a host exception mechanism.

## Reader

Reader-like context is suitable for immutable compiler configuration,
environment handles, and contextual options.

## State

State carries values such as:

- fresh identifiers;
- environments;
- metavariable assignments;
- parser/elaborator state.

State changes are explicit in the effect semantics.

## Error

Recoverable compiler failures use a typed error channel rather than relying on
host exceptions as the language definition.

## Rollback

Speculative elaboration/parsing needs transaction behavior:

1. snapshot state;
2. try an alternative;
3. commit on success;
4. restore on recoverable failure.

Metavariable assignments from a failed speculative path must not leak.

## Why not require transformer stacks now?

Lean's ReaderT/StateT/ExceptT ecosystem is powerful, but generic higher-kinded
transformer machinery would expand the PSC1 self-hosting surface.

If one concrete compiler effect can express the compiler naturally, it is the
better first-freeze choice.

Libraries may later recover more general abstractions.

## Host IO

Filesystem, network, clock, randomness, process state, and similar capabilities
are explicitly effectful host boundaries.

A backend adapter may use Node, native OS APIs, or WASI, but those host
mechanisms are not PSC1 semantics.

## Next

Continue to
[Programming with Dependent Types](./06-programming-with-dependent-types.md).
