# 5. Inductive Types and Elimination

Inductive types define data by constructors and automatically induce
elimination principles.

That single mechanism supports both programming pattern matches and proof
reasoning.

## A simple inductive

```proofscript
inductive PsOption(α: Type) where {
  | none;
  | some(value: α);
};
```

A value of `PsOption(α)` must be produced through one of the constructors.

## Constructors

Constructors are ordinary constants/functions in the checked environment.

```text
PsOption.none
PsOption.some
```

have types determined by the inductive declaration.

## Pattern matching

Programs eliminate the alternatives with `match`.

```proofscript
function optionIsSome {α: Type}(value: PsOption(α)): Bool :=
  match value with {
    | .none => false;
    | .some x => true;
  };
```

## Recursors

The kernel-facing representation of elimination uses generated recursors.

Tactic `cases` and `induction` therefore do not invent their own reasoning
principles; they build applications of the actual checked recursor.

This is important for trust.

## Proof by cases

For a proposition about every option value, split on constructors:

```proofscript
theorem optionOrElseNoneRight {α: Type}
(value: PsOption(α)):
optionOrElse(value, PsOption.none) = value :=
  by cases value; rfl; rfl;
```

Each branch reduces to a simpler goal.

## Recursive inductives

```proofscript
inductive PsList(α: Type) where {
  | nil;
  | cons(head: α, tail: PsList(α));
};
```

The recursive constructor field enables both:

- recursive programs over the tail;
- induction hypotheses about the tail.

## Indexed inductives

Dependent families can have result indices that vary by constructor.

They require more sophisticated motives and dependent elimination.

PSC1's semantic direction supports that model, but the first tactic/frontend
profile does not claim the full indexed `cases`/dependent pattern convenience
of Lean.

## Positivity and well-formedness

An inductive is not accepted merely because its syntax parses.

The kernel-facing semantics must enforce the appropriate positivity/universe
conditions.

## Structures as single-constructor data

A structure can be understood as a specialized single-constructor inductive
with named projections.

PSC1 exposes structures separately because they are a useful programming
abstraction.

## Next

Continue to [Induction and Recursion](./06-induction-and-recursion.md).
