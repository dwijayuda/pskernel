# 1. Dependent Type Theory

PSC1's proof system is built on dependent type theory.

The key idea is that **types are themselves terms**, and later types can depend
on earlier values.

## Terms and types

```proofscript
const n: Nat := 3;
```

The term `n` has type `Nat`.

A type is not merely metadata for a backend. It participates in elaboration and
kernel checking.

## Function abstraction

```proofscript
fun (x: Nat) => x + 1
```

constructs a function.

The corresponding function type is:

```proofscript
Nat -> Nat
```

## Dependent functions

A dependent function may mention its input in a later type:

```proofscript
(x: Nat) -> Fin x -> Nat
```

This is a Pi type.

Universal quantification and ordinary function types are both represented using
this same dependent-function mechanism.

## Definitions

```proofscript
def answer: Nat := 42;
```

A definition adds a named constant to the environment after elaboration and
checking.

PSC1's `const` and `function` forms elaborate to the same definition
semantics.

## Local definitions

```proofscript
function f(x: Nat): Nat :=
  let y: Nat := x + 1;
  y * 2;
```

A local `let` introduces a term into the local context.

The kernel-facing term does not depend on JavaScript block scope.

## Implicit arguments

```proofscript
function identity {α: Type}(x: α): α :=
  x;
```

The elaborator can infer `α` from context.

The omitted argument still exists in the elaborated term.

## Universes

Dependent type theory requires universe levels so that "types of types" do not
collapse inconsistently.

PSC1 needs the universe machinery required by generic and dependent compiler
source, but the first freeze does not require all user-facing universe syntax
that full Lean provides.

## Metavariables

During elaboration, unknown pieces may temporarily be represented by
metavariables.

A metavariable is an elaborator obligation.

It is not a runtime dynamic value and it cannot remain unresolved in a checked
admission.

## Definitional equality

Two terms may be considered equal because they compute/unfold to the same core
term under the allowed reduction rules.

This relation is used by type checking.

It is different from:

- Bool-valued `==`;
- a propositional equality theorem `x = y`;
- host-language object equality.

## Kernel boundary

The elaborator may perform sophisticated inference.

The kernel receives the explicit result and independently checks it.

That architecture is what lets PSC1 keep a small trusted core even as the
frontend grows.

## Next

Continue to [Propositions and Proofs](./02-propositions-and-proofs.md).
