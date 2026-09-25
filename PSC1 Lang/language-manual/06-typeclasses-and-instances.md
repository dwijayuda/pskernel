# 6. Typeclasses and Instance Synthesis

PSC1 typeclasses implement bounded ad-hoc polymorphism.

## Class declaration

Representative form:

```proofscript
class Sized(α: Type) where {
  size: α -> Nat;
}
```

A class declaration defines a type of evidence.

## Instance arguments

Instance binders use the Lean-compatible category:

```text
[C α]
```

The elaborator tries to synthesize the required evidence.

## Instance declarations

Instances register terms that can solve class goals.

PSC1's exact declaration syntax is bounded by the source feature matrix.

## Synthesis

Instance synthesis may use:

- local instance assumptions;
- bounded global/imported instance registrations;
- recursive search with limits;
- required priority/index behavior where implemented.

Failure to synthesize is an elaboration error.

## Decidable

The self-host profile needs bounded `Decidable` support so propositions can
participate in executable decisions where appropriate.

Bool and Prop remain distinct.

## Search safety

Instance search is not permitted to:

- execute arbitrary host code as proof;
- synthesize an unchecked axiom silently;
- use backend object shape;
- ignore ambiguous/failed semantic constraints.

## Typeclasses and operators

Operator elaboration may depend on typeclass evidence.

The resulting operation still must obey PSC1's frozen scalar/data semantics.

## Not full Lean class surface

The first freeze does not require every feature of Lean's class system,
including all deriving/coercion/output-parameter conveniences.

A feature becomes PSC1 when explicitly implemented and gated.
