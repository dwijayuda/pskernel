# 10. Worked Proof Patterns

This chapter collects small patterns already aligned with the bounded PSC1
tactic surface.

## Reflexivity

```proofscript
theorem selfEq {α: Type}(x: α): x = x := by rfl;
```

Use `rfl` when both equality sides reduce to the same term.

## Use a hypothesis directly

```proofscript
theorem keep {P: Prop}(h: P): P := by exact h;
```

Equivalent bounded style:

```proofscript
theorem keep2 {P: Prop}(h: P): P := by assumption;
```

## Introduce an implication

```proofscript
theorem idProof(P: Prop): P -> P := by
  intro h;
  exact h;
```

The proof constructs a function from evidence of `P` to evidence of `P`.

## Prove an Option equation by cases

Using the stdlib-style option:

```proofscript
theorem optionOrElseNoneRight {α: Type}
(value: PsOption(α)):
optionOrElse(value, PsOption.none) = value :=
  by cases value; rfl; rfl;
```

Case splitting is appropriate because the function itself computes by matching
on the same constructors.

## Simplify a known constructor case

```proofscript
theorem optionGetOrElseSome {α: Type}
(value: α, fallback: α):
optionGetOrElse(PsOption.some(value), fallback) = value :=
  by rfl;
```

The definition reduces directly.

## Explicit simplification

The current stdlib uses patterns like:

```proofscript
theorem optionGetOrElseNoneSome {α: Type}
(value: α, default: α):
optionGetOrElse(
  optionOrElse(PsOption.none, PsOption.some(value)),
  default
) = value :=
  by simp only [
    optionOrElseNone(PsOption.some(value)),
    optionGetOrElseSome(value, default)
  ];
```

The rule set is explicit.

## Inductive list proof

Representative structure:

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

The induction hypothesis closes the recursive case after unfolding the
constructor equation.

## Proof-search assistance

A small goal may be solvable by:

```proofscript
by exact?;
```

Treat the result as checked proof search assistance, not an oracle.

If search cannot construct an exact proof within the bounded strategy, write
the explicit proof.

## Stable proof engineering

Prefer proofs that:

- follow the structure of the program/data;
- use small named lemmas;
- use explicit rewrite/simplification sets;
- avoid depending on broad ambient automation;
- make assumptions visible.

These qualities are valuable for both self-host bootstrap stability and future
cross-version maintenance.

## Next

Continue to [The PSC1 Proof Boundary](./11-the-psc1-proof-boundary.md).
