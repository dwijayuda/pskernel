# 3. Quantification and Equality

Two of the most important logical mechanisms in PSC1 are dependent
quantification and propositional equality.

## Universal quantification

A theorem parameter is a universal binder.

```proofscript
theorem selfEq {α: Type}(x: α): x = x := by rfl;
```

Conceptually, the theorem proves the statement for every valid choice of
`α` and `x`.

The core representation is a dependent function/Pi type.

## Introducing quantified assumptions

For implication/function-shaped goals, `intro` introduces a local binder.

Representative form:

```proofscript
theorem identityProof(P: Prop): P -> P := by
  intro h;
  assumption;
```

The resulting proof is lambda-like.

## Equality

PSC1's propositional `=` is the Lean-compatible polymorphic equality type.

The basic reflexive proof is generated through `Eq.refl`.

```proofscript
theorem zeroEq: (0: Nat) = 0 := by rfl;
```

## Definitional reflexivity

The current `rfl` tactic is intentionally bounded to Eq-oriented
definitional reflexivity.

It closes a goal when both sides are definitionally equal under the supported
reduction model.

It does not claim every relation-reflexivity feature of Lean's full tactic.

## Rewriting

Given an equality proof, `rw` transports the goal across that equality.

```proofscript
by
  rw [h];
```

Reverse direction:

```proofscript
by
  rw [← h];
```

The implementation constructs ordinary equality transport and lets pskernel
check the result.

## Equality symmetry

A proof of `a = b` can be transformed into a proof of `b = a`.

The current proof search has bounded support for useful equality symmetry, but
this is implemented by constructing checked proof terms rather than declaring a
special trusted equivalence.

## Existential propositions

Full Lean supports rich existential notation/elimination.

PSC1's core type theory can represent the relevant proposition machinery, but
the first frozen PSC1 source/theorem subset must not be assumed to include all
Lean existential syntax or tactic conveniences unless explicitly gated.

For current code, prefer features listed in the PSC1 conformance matrix.

## Equality and backend execution

Propositional equality is not JavaScript `===`, Rust `Eq`, or a Wasm
comparison instruction.

Those target operations may implement executable Bool equality for some values,
but proof equality remains a checked logical relation.

## Next

Continue to [Goals and Tactics](./04-goals-and-tactics.md).
