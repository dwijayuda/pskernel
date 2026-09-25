# 4. Goals and Tactics

A tactic proof is an incremental program that constructs a proof term.

## Proof state

A proof state contains:

- local hypotheses;
- local variables;
- one or more goals;
- metavariable assignments created while elaborating the proof.

A goal can be read as:

```text
local context
⊢ target proposition
```

## `exact`

```proofscript
theorem keep {P: Prop}(h: P): P := by exact h;
```

`exact t` elaborates `t` against the current goal.

If its type does not match, the tactic fails.

## `assumption`

```proofscript
theorem keep2 {P: Prop}(h: P): P := by assumption;
```

The tactic searches the local context for compatible evidence.

## `intro`

```proofscript
theorem idProof(P: Prop): P -> P := by
  intro h;
  exact h;
```

`intro` converts a function/Pi-shaped goal into a local assumption plus a new
body goal.

## `apply`

`apply` uses a theorem/function whose conclusion can match the goal and
creates goals for missing premises.

PSC1's implementation is bounded: unsupported implicit/instance/search
situations fail rather than pretending to have full Lean Meta behavior.

## `refine`

`refine` supplies a partial proof term containing supported synthetic holes.

Those holes become explicit goals.

The current implementation accepts only bounded hole shapes; it is not a
general Lean parser for arbitrary refinement syntax.

## `constructor`

If the goal is an inductive proposition/type, `constructor` attempts to use a
constructor and creates goals for its required arguments.

This is ordinary constructor application, not a separate axiom.

## `cases`

`cases h` eliminates an inductive local value.

Each constructor produces a branch goal according to the generated recursor.

The current PSC1 path focuses on the bounded unindexed cases needed by the
language/compiler proof suite.

## `induction`

`induction h` follows the recursor structure and adds induction hypotheses for
supported recursive fields.

It is tightly connected to recursive datatype semantics.

## `rfl`

Closes supported equality goals by definitional reflexivity.

## `rw`

Rewrites the current goal using an equality proof.

Current syntax supports explicit rule direction.

## `simp only`

PSC1 deliberately starts with explicit simplification sets:

```proofscript
by
  simp only [lemma1(...), lemma2(...)];
```

The implementation is bounded and step-limited.

Unrestricted global `simp` behavior is not part of the first theorem surface.

## `exact?`

`exact?` performs bounded proof search over candidates available to the
current implementation.

A suggestion is accepted only when exact-style elaboration really closes the
goal.

It is not full library automation.

## Trust

Every successful tactic sequence must leave a complete proof term.

pskernel then checks that term independently.

## Next

Continue to
[Inductive Types and Elimination](./05-inductive-types-and-elimination.md).
