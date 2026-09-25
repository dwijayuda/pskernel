# 6. Abstraction with Structures, Inductives, and Typeclasses

JavaScript abstraction often centers on objects, prototypes, classes, and
methods.

PSC1 reaches similar software-design goals through a different set of
mechanisms:

- functions;
- structures;
- inductives;
- modules;
- typeclasses;
- dependent types.

## Abstract data through modules

A type can expose a small public set of constructors/functions while keeping
implementation helpers local to a module.

The module boundary, not prototype inheritance, is the first abstraction tool.

## Structures for product data

Use a structure when a value is made of several named pieces that belong
together.

```proofscript
structure Position where {
  line: Nat;
  column: Nat;
}
```

## Inductives for alternatives

Use an inductive when a value can have one of several shapes.

```proofscript
inductive TokenKind where {
  | identifier;
  | number;
  | endOfInput;
};
```

Pattern matching forces the program to address constructor alternatives
explicitly.

## Typeclasses for ad-hoc polymorphism

Representative class:

```proofscript
class Sized(α: Type) where {
  size: α -> Nat;
}
```

The elaborator can synthesize evidence for `[Sized α]`.

This is not virtual method dispatch and does not imply object identity.

## Dependent types for stronger interfaces

When an operation's result or precondition depends on a value, use a dependent
type.

Example shape:

```text
(xs: Array α) -> (i: Nat) -> i < size xs -> α
```

This expresses an invariant directly.

## Avoid inheritance-shaped thinking

PSC1 does not need source semantics for:

- prototype chains;
- `this`;
- class inheritance;
- `instanceof`;
- mutable hidden fields;
- getter/setter magic.

If an abstraction can be expressed with data + functions + evidence, that is
usually more portable and easier to verify.

## Iterator-like abstractions

Generic iteration can be provided as library functions or typeclasses when the
compiler workload justifies it.

A new language-level iterator protocol is not required for PSC1 freeze merely
because JavaScript has one.

## Exercises

1. Model a compiler token using one structure and one inductive.
2. Refactor an imaginary object-oriented "Shape" hierarchy into an inductive
   plus functions.
3. Give an example where a typeclass is more appropriate than adding a tag to
   an inductive.
4. Give an example where a dependent function type prevents an invalid call.
