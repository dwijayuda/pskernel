# 7. Tactic Proofs

PSC1 tactic mode is a bounded proof-construction language.

## Current tactic set

```text
exact
exact?
assumption
intro
apply
refine
constructor
cases
induction
rfl
rw
simp only
```

This list comes from the current executable tactic parser/elaborator surface.

## Semantics

Tactics manipulate metavariable goals.

Successful completion yields a proof term.

pskernel checks the completed term.

## `exact`

Elaborate a candidate against the current goal.

## `assumption`

Find compatible evidence in the local context.

## `intro`

Introduce a Pi/function/implication binder.

## `apply`

Apply a theorem/function and generate premise goals.

## `refine`

Provide a partial candidate with supported synthetic holes.

## `constructor`

Apply a constructor to an inductive goal.

## `cases`

Eliminate a supported inductive local through its recursor.

## `induction`

Use the recursor/induction principle and generate supported induction
hypotheses.

## `rfl`

Bounded Eq-only definitional reflexivity.

## `rw`

Rewrite the current goal using explicit equality evidence, including supported
reverse direction.

## `simp only`

Bounded simplification from an explicit supplied rule set.

The current implementation uses bounded steps and does not import full Lean
global simplifier behavior.

## `exact?`

Bounded candidate search.

It succeeds only by finding a term that ordinary exact-style checking accepts.

## Unsupported Lean tactic features

PSC1 does not currently claim full:

- tactic combinator language;
- `conv`;
- `simp`;
- `grind`;
- `omega`;
- custom tactic macros;
- general dependent cases/induction automation.

Unknown/unsupported tactics fail closed.
