# 6. Induction and Recursion

Recursion constructs data/results.

Induction constructs proofs.

For inductive data, both follow the same constructor structure.

## Structural recursion

```proofscript
function listLength {α: Type}(xs: PsList(α)): Nat :=
  match xs with {
    | .nil => 0;
    | .cons head tail => 1 + listLength(tail);
  };
```

The recursive call is on the structurally smaller tail.

## A theorem by induction

The current PSC1 stdlib proves list laws using induction plus rewriting.

Representative pattern:

```proofscript
theorem listAppendNilRight {α: Type}
(xs: PsList(α)):
listAppend(xs, PsList.nil) = xs :=
  by
    induction xs;
    rfl;
    rw [listAppendCons(head, tail, PsList.nil)];
    rw [tail_ih];
```

The exact generated branch names are determined by the bounded tactic
implementation and recursor metadata.

## Why induction hypotheses appear

In the recursive constructor case, the induction principle assumes the theorem
for recursive fields before asking you to prove it for the constructor value.

That assumption is the induction hypothesis.

## Recursion and termination

A total recursive definition must be accepted by the supported recursion
discipline.

Structural recursion is the preferred first PSC1 mechanism because the
decrease is visible in the datatype.

## General well-founded recursion

Lean supports more general termination proofs.

PSC1 does not make the full system a first-freeze requirement unless compiler
source demonstrates the need.

The language can expand later without changing the core trust model.

## Controlled partial definitions

PSC1 also needs a controlled executable `partial def` boundary for algorithms
that are operationally useful but outside the first termination checker.

Partial definitions are **not** proof-producing shortcuts.

They cannot be used to justify arbitrary propositions through nontermination or
host execution.

## Induction on multiple/nested data

Rich mutual and indexed induction is possible in the semantic model but may
exceed the first bounded tactic surface.

The correct behavior is fail-closed rather than constructing an approximate
proof.

## Proof by computation

Some inductive equations reduce definitionally and can be closed with `rfl`.

Others need explicit induction and rewrite lemmas.

Understanding which is which makes proofs smaller and more stable.

## Next

Continue to
[Structures, Classes, and Evidence](./07-structures-classes-and-evidence.md).
