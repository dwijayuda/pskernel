# Generics and Dependent Types

PSC1's generic programming model is part of a dependent type system.

This means ordinary parametric polymorphism and value-dependent types are not
two unrelated features. They are points on the same function/type spectrum.

## Generic identity

```proofscript
function identity {α : Type}(x : α) : α :=
  x;
```

The type parameter `α` is implicit.

The function says that input and output share the same type.

## Why implicit binders use braces

PSC1 keeps Lean-compatible binder categories because they carry semantic
information.

```text
(x : A)       explicit
{α : Type}    implicit
{{α : Type}}  strict implicit, where supported
[C α]         instance implicit
```

Replacing all of these with TypeScript `<T>` would hide important distinctions
needed by elaboration.

## Generic data

```proofscript
inductive PsOption(α : Type) where {
  | none;
  | some(value : α);
};
```

`PsOption(Nat)` and `PsOption(String)` instantiate the same generic
definition with different types.

## Generic functions over data

```proofscript
function optionMap {α : Type}{β : Type}
(f : α -> β, value : PsOption(α)) : PsOption(β) :=
  match value with {
    | .none => PsOption.none;
    | .some x => PsOption.some(f(x));
  };
```

The function relates:

- the input element type `α`;
- the output element type `β`;
- the mapper `α -> β`;
- the result container `PsOption(β)`.

## Dependent function types

An ordinary function type:

```proofscript
Nat -> Nat
```

has a result type independent of the input value.

A dependent function type:

```proofscript
(x : Nat) -> Fin x -> Nat
```

lets a later type mention `x`.

This is a Pi type.

## Why dependency matters

Suppose a value is an index known to be less than a size.

A dependent API can carry that relationship in the type instead of asking every
caller to remember it informally.

The exact library type used for such an index is secondary. The important PSC1
capability is that types may depend on values.

## Propositions can appear in types

Proof arguments can express preconditions.

A function might conceptually require evidence `h : index < size` before
performing a bounds-sensitive operation.

The current stdlib already wraps array operations whose underlying semantics
use bounded access evidence.

## Type inference does not remove semantics

PSC1 may infer an implicit type argument.

That does not mean the argument is semantically nonexistent.

Elaboration constructs the fully typed term, then pskernel checks it.

## Metavariables

During elaboration, unknown pieces may temporarily be represented by
metavariables.

A metavariable is an elaboration device, not a runtime dynamic type.

Before a checked declaration is admitted, required metavariables must be
resolved under the supported profile.

## Universes

Dependent type theory needs universes to avoid inconsistent "type of all types"
behavior.

PSC1's first profile needs enough universe machinery to support its generic and
dependent declarations.

User-facing universe command/syntax breadth is not itself a first-freeze
requirement when inference/bounded universes are enough for the compiler.

## Definitional equality

Two expressions can be equal by computation/unfolding under the semantic
reduction rules even when their surface syntax differs.

Meta/elaboration uses definitional equality to type-check applications and
proofs.

This is not JavaScript `===`, and it is not the same as a theorem proving
arbitrary propositional equality.

## Typeclasses and dependent arguments

Instance arguments are another binder category:

```proofscript
[C α]
```

The elaborator may synthesize appropriate evidence from the instance
environment.

Only the bounded class/instance machinery needed by PSC1 is a first-freeze
requirement.

## Dependent data

The long-term language can support indexed/dependent inductive families.

The repository's active plans distinguish:

- basic generic recursive ADTs, which are already heavily dogfooded;
- richer indexed/dependent inductive elimination, which needs stronger Meta and
  recursor handling.

Do not infer full Lean dependent-pattern support from the existence of Pi
types.

## The portability advantage

Dependent types and proofs are checked before backend lowering.

That means a verified relationship does not need to be redefined separately for
JavaScript, Rust, and Wasm.

Runtime representation can vary while checked semantics remain shared.

## What to learn next

Now that types can express relationships, continue to
[Propositions and Proofs](./06-propositions-and-proofs.md).
