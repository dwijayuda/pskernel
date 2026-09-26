# 2. Propositions and Proofs

In PSC1, propositions are types in `Prop`, and proofs are terms inhabiting
those types.

## A proposition

```proofscript
x = x
```

is a proposition.

## A proof

```proofscript
theorem selfEq {α: Type}(x: α): x = x := by rfl;
```

constructs a proof of that proposition.

## Propositions as types

The propositions-as-types correspondence explains several proof patterns:

- proving an implication means constructing a function from evidence of the
  premise to evidence of the conclusion;
- proving a universal statement means constructing a dependent function;
- using a conjunction-like proposition means eliminating an inductive proof;
- proving equality means constructing/transforming an `Eq` proof.

PSC1 inherits the semantic model but only claims source notation that its
bounded frontend actually admits.

## Implication

The simplest implication-style proposition can be written using an arrow:

```proofscript
theorem keep {P: Prop}(h: P): P := by exact h;
```

A theorem with an argument `h: P` is already function-like proof
construction.

## Proof irrelevance

Proof values in `Prop` are logically important but normally irrelevant to
runtime computation.

That permits proof erasure while preserving the checked program contract.

Proof irrelevance does not mean "proofs are unchecked." It means programs do not
distinguish proof identities as ordinary runtime values.

## Constructive core

PSC1 does not silently assume arbitrary classical principles merely because the
host language can compute something.

Any axiom outside the constructive kernel foundation must remain explicit in
the checked environment/trust story.

## Evidence can guide programs

A proof can be passed as an argument to justify a safe operation:

```proofscript
function safeGet {α: Type}
(xs: Array(α), i: Nat, h: i < Array.size(xs)): α :=
  Array.getInternal(xs, i, h);
```

The proof may erase after it has served its checking role.

## Bool is different

```proofscript
x == y
```

produces a Bool for supported types.

```proofscript
x = y
```

is a proposition.

A Bool can participate in a proposition, but the two categories are not
silently identified.

## Tactics are proof constructors

A tactic command changes the current proof state and eventually produces a term.

If it cannot construct a well-typed term for every goal, the theorem fails.

## Next

Continue to
[Quantification and Equality](./03-quantification-and-equality.md).
