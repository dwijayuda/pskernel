# Typeclasses and Instances

PSC1 uses Lean-compatible typeclass concepts for type-directed evidence and
operations.

A PSC1 `class` is **not** an object-oriented class.

## A class declares required evidence

Representative shape:

```proofscript
class Sized(α: Type) where {
  size: α -> Nat;
}
```

Conceptually, a value of `Sized α` provides a sizing operation for values of
type `α`.

## Instance parameters

A function may request instance evidence using an instance binder.

```text
[SomeClass α]
```

The elaborator may synthesize a suitable instance from the current environment.

This is type-directed elaboration, not dynamic runtime prototype lookup.

## Instances

An instance supplies evidence for a class.

The exact currently accepted declaration forms are part of the bounded
source-profile matrix.

The language architecture supports:

- class declarations;
- local instance synthesis;
- bounded global instance registration/synthesis;
- `Decidable` behavior needed by the frozen compiler.

## Why typeclasses are useful

Typeclasses can abstract over behavior without changing the data definition.

Examples of the general pattern include:

- equality/comparison behavior;
- conversion/showing;
- decidability;
- compiler-specific abstractions where type-directed evidence is appropriate.

PSC1's first profile implements only what its language and compiler actually
need.

## Typeclasses are not TypeScript interfaces

A TypeScript interface is primarily a structural static type description.

A PSC1 class participates in dependent elaboration and instance synthesis.

A backend may choose a dictionary-like runtime representation when needed, but
that is an implementation artifact.

## Typeclasses are not OOP inheritance

PSC1 does not derive the following from `class`:

- subclass inheritance;
- virtual methods;
- `this`;
- constructors;
- object identity;
- protected/private state.

Use structures and inductives for data.

Use functions/modules for organization.

Use typeclasses for type-directed evidence/behavior.

## `Decidable`

Some propositions can be decided computationally.

PSC1's first self-host profile explicitly needs the bounded
class/instance/`Decidable` machinery exercised by compiler code.

That does not mean all Lean typeclass features are required.

## Instance search boundaries

A sound typeclass system also needs predictable elaboration behavior.

Current plans call for progressively stronger support for:

- priorities where needed;
- recursive search control;
- imported instance indexes;
- `outParam`/`semiOutParam` only if the chosen subset needs them.

PSC1 deliberately does not port the entire Lean convenience surface first.

## Failure is better than a guessed instance

If the bounded elaborator cannot resolve required instance evidence, it should
fail with a useful diagnostic.

It must not:

- select a JavaScript implementation by duck typing;
- treat a structural object as implicit class evidence;
- bypass pskernel;
- insert an unchecked assumption without reporting it.

## Typeclasses and portability

A typeclass describes language-level evidence.

A backend can lower that evidence differently, provided observable PSC1
semantics stay the same.

This makes class-driven generic libraries compatible with the target-neutral
VerifiedIR architecture.

## Optional conveniences

Method-style notation can make typeclass-driven code pleasant, but it is not a
first PSC1 freeze requirement unless compiler source adopts it.

The small-language rule is:

> get the semantic mechanism right first; add source convenience only when it
> earns its cost.

## Next

Continue to [Recursion and Totality](./08-recursion-and-totality.md).
