# 7. Structures, Classes, and Evidence

Structures package data.

Classes package data/evidence that elaboration may synthesize by type.

Both become ordinary checked terms.

## Structures

```proofscript
structure Point where {
  x: Nat;
  y: Nat;
}
```

The declaration creates constructor/projection semantics.

A theorem can quantify over a `Point` just like any other type.

## Proof-carrying structures

A structure may conceptually combine data and a proposition proving an invariant.

This pattern is useful when multiple operations should preserve the same
invariant.

PSC1 does not need special "validated object" syntax; structures and dependent
fields are sufficient.

## Classes

```proofscript
class Sized(α: Type) where {
  size: α -> Nat;
}
```

A class is structure-like but marks its instances for type-directed synthesis.

## Instance evidence

A function can have an instance argument:

```text
[Sized α]
```

Elaboration attempts to construct that argument from the available instance
environment.

The resulting term still contains explicit evidence at the core level.

## Decidable propositions

`Decidable P` packages computational evidence that a proposition can be
decided.

PSC1's first compiler profile needs bounded `Decidable` machinery because
compiler/theorem code uses decisions in executable contexts.

The existence of `Decidable` does not identify Bool and Prop.

## Search control

Instance search can recurse and must be controlled.

PSC1 follows a bounded deterministic policy rather than assuming all Lean
priority/output-parameter/coercion features are present.

## Structures vs classes

Use a structure when:

- callers should choose the value;
- the value is ordinary data.

Use a class when:

- the value represents canonical/type-directed evidence;
- elaboration should usually synthesize it.

## Proof trust

Instance synthesis is elaboration, not kernel authority.

A buggy synthesizer can at worst propose a bad term; pskernel still rejects a
term whose type is invalid.

## Next

Continue to
[Axioms, Computation, and Trust](./08-axioms-computation-and-trust.md).
