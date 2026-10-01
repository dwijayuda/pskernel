# 10. Recursion, Partiality, and Effects

PSC1 must express a real compiler without importing unrestricted host semantics.

## Structural recursion

Preferred first-freeze recursion is structural.

```proofscript
function listLength {α: Type}(xs: PsList(α)): Nat :=
  match xs with {
    | .nil => 0;
    | .cons head tail => 1 + listLength(tail);
  };
```

The recursive call follows a structurally smaller field.

## Termination

Total recursive definitions participate in the logical checked model only when
accepted by the supported recursion discipline.

General well-founded termination infrastructure is optional unless needed by
frozen compiler source.

## Partial definitions

PSC1 permits a controlled executable `partial def` boundary.

Partial definitions are runtime/compiler capabilities and cannot be used as a
logical loophole.

## Effects

Portable ordinary functions are pure.

Host/compiler effects are explicit.

## Compiler effect requirements

The self-host compiler needs a concrete effect supporting:

- reader/context;
- state;
- typed error;
- `pure`;
- `bind`;
- `do`;
- recovery;
- transactional rollback.

## Rollback

Speculative parsing/elaboration must restore state after a failed branch.

Metavariable or environment changes from a failed speculative path cannot leak.

## Generic monad infrastructure

Lean's general Monad/Functor/transformer ecosystem is a useful design reference.

PSC1 does not require that entire abstraction stack for the first freeze.

One concrete, well-specified compiler effect can satisfy self-hosting with a
smaller language/stdlib burden.

## Imperative syntax

Loops, mutation syntax, `break`, and `continue` are optional/non-blocking
unless actual compiler source makes them necessary.

They must lower to explicit PSC1 semantics rather than inherit one backend's
statement behavior.
