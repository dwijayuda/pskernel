# 3. Propositions, Proofs, and Safe Indexing

One of the most useful lessons from programming in Lean is that a proof need not
be "extra mathematics." It can be an ordinary argument that lets a program use
an operation safely.

## Propositions are types

```proofscript
theorem selfEq(x: Nat): x = x := by rfl;
```

The proposition `x = x` is a type in `Prop`.

The theorem body constructs a value of that type: a proof.

## Evidence as a function argument

A bounds-sensitive array operation can require evidence:

```proofscript
function arrayGet {α: Type}
(xs: Array(α), index: Nat, h: index < Array.size(xs)): α :=
  Array.getInternal(xs, index, h);
```

The important design pattern is:

```text
data argument
+ proof of precondition
-> safe result
```

The proof can erase at runtime when it carries no computational content.

## Safe alternatives without explicit proof

The current stdlib also provides APIs whose types encode failure:

```proofscript
function arrayGet? {α: Type}
(xs: Array(α), index: Nat): PsOption(α) :=
  ...
```

or a defaulted result:

```proofscript
function arrayGetD {α: Type}
(xs: Array(α), index: Nat, fallback: α): α :=
  Array.getD(xs, index, fallback);
```

These represent three different contracts:

- prove the index valid;
- return an option;
- return a fallback.

PSC1 does not need one magic indexing syntax to hide the distinction.

## Proofs can be computed structurally

Suppose a recursive datatype has a property that follows from its constructors.
A recursive function can construct the corresponding proof just as it can
construct ordinary data.

That is the bridge between functional programming and induction.

## Bool is not Prop

```proofscript
function isOne(x: Nat): Bool :=
  x == 1;
```

returns executable data.

```proofscript
theorem oneRefl: (1: Nat) = 1 := by rfl;
```

states a proposition.

PSC1 keeps the distinction explicit.

## Why this improves APIs

Proof-carrying interfaces can make invalid states difficult or impossible to
express.

But PSC1 does not require every API to maximize type-level sophistication.
Sometimes `PsOption` or `PsResult` is clearer and cheaper.

The small-language principle applies to types too: use dependency where it
improves the contract.

## Kernel authority

The frontend may infer the proof argument or a tactic may construct it.

Neither mechanism is trusted by itself.

The resulting term still goes through pskernel.

## Next

Continue to [Overloading and Typeclasses](./04-overloading-and-typeclasses.md).
