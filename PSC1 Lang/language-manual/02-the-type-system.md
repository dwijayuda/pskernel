# 2. The Type System

PSC1 uses the Lean-compatible dependent type theory needed by its frozen
profile.

## Terms and types

Types are terms.

A checked term must have a type under the rules of the supported core theory.

## Function types

Non-dependent function type:

```proofscript
Nat -> Nat
```

Dependent function type:

```proofscript
(x: Nat) -> Fin x -> Nat
```

The latter is a Pi type because a later type depends on `x`.

## Lambda abstraction

```proofscript
fun (x: Nat) => x + 1
```

constructs a function term.

## Application

PSC1 supports adjacent D-CALL syntax:

```proofscript
f(x, y)
```

which normalizes to curried application.

## Let expressions

```proofscript
let x: Nat := value;
body
```

introduces a lexical local definition.

## Universes

PSC1 retains the universe machinery required for:

- generic types;
- dependent functions;
- inductive declarations;
- compiler source.

The first freeze does not require full user-facing Lean universe command syntax.

## Propositions

`Prop` is the universe of propositions.

Proofs are terms inhabiting propositions.

Proof irrelevance permits proof values to erase when runtime behavior does not
depend on their identity.

## Inductive types

Inductives define constructors and recursors.

The semantic checker enforces well-formedness, including the relevant
positivity/universe rules.

## Structures

Structures are specialized single-constructor data with named fields and
projections.

They are nominal checked declarations, not structural host objects.

## Definitional equality

Type checking uses definitional equality based on supported reduction/unfolding
semantics.

Definitional equality is distinct from:

- propositional `=`;
- Bool `==`;
- target-language equality.

## Metavariables

Metavariables exist during elaboration.

Unresolved expression or universe metavariables are not permitted in final
checked admissions.

## Equality

Propositional equality uses the ordinary polymorphic `Eq` semantics.

Current theorem work includes Eq reflexivity, equality transport/rewrite, and
bounded symmetry/search behavior.

## Claim boundary

PSC1 does not claim full Lean type-system convenience merely by sharing the
foundational calculus.

Indexed elimination, coercion insertion, universe syntax, and other advanced
frontend behavior require explicit PSC1 support.
