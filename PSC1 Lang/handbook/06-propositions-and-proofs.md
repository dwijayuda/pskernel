# Propositions and Proofs

PSC1 treats propositions as types and proofs as terms.

That single idea connects ordinary programming to theorem proving.

## `Prop`

`Prop` is the universe of propositions.

A proposition can be used as the type of a theorem:

```proofscript
theorem selfEq(x: Nat): x = x := by rfl;
```

The theorem body constructs a proof term.

## Equality

PSC1 distinguishes two important equality forms.

### Propositional equality

```proofscript
x = y
```

This is a proposition.

A theorem may prove it.

### Bool-valued equality

```proofscript
x == y
```

This computes a `Bool` for supported equality instances.

A Bool is not silently promoted to a proposition just because it feels
truth-like.

For example:

```proofscript
(x == y) = true
```

is a proposition about a Bool-valued computation.

## Proof terms

The semantic object the kernel checks is a proof term.

Tactics are a convenient way to build such terms.

This architecture matters:

```text
tactic script
-> proof term
-> pskernel checks proof term
```

A tactic is not trusted simply because it says "success".

## `rfl`

The bounded current `rfl` path handles the ordinary Eq reflexivity case.

```proofscript
theorem selfEq {α: Type}(x: α): x = x := by rfl;
```

The elaborator constructs the real polymorphic reflexivity proof and pskernel
checks it.

The current implementation does not claim every Lean reflexive-relation feature
that Lean's full tactic supports.

## `exact`

If you already have a term of the goal type, `exact` can use it.

Conceptually:

```proofscript
theorem keep {P: Prop}(h: P): P := by exact h;
```

The supplied proof term must match the goal.

## `assumption`

`assumption` searches the local context for a matching proof.

The bounded tactic is useful when the needed proposition is already an
available hypothesis.

## `intro`

A function/proof of an implication or universal proposition can introduce a
binder.

The tactic builds the corresponding lambda-like proof structure.

## `apply`

`apply` uses a theorem/function whose result can match the current goal and
creates premise goals for required arguments.

PSC1's current implementation is deliberately bounded and does not pretend to
have the full implicit/instance/search behavior of Lean's complete Meta layer.

## `refine`

The current bounded `refine` supports controlled synthetic holes such as
`?_` in supported positions.

Unresolved holes become explicit goals.

A proof is not admitted until all required holes are solved.

## `constructor`

For an inductive target proposition/type, `constructor` tries constructors
using the same proof-producing application machinery.

It is not a special proof oracle.

## `cases`

`cases` eliminates a local inductive value and creates branch goals.

The current bounded implementation supports a useful unindexed slice and
constructs recursor-based proof terms.

Indexed/dependent cases require more general context/index handling and remain a
separate capability boundary.

## `induction`

`induction` extends constructor case analysis with induction hypotheses for
supported recursive fields.

The ProofScript stdlib dogfoods this for list theorems.

For example, list append laws are proved using ordinary induction, rewriting,
and reflexivity rather than a library-specific trusted shortcut.

## `rw`

The current bounded `rw` uses Eq proofs to transport the goal.

Representative spelling:

```proofscript
by rw [h];
```

or reverse direction:

```proofscript
by rw [← h];
```

The implementation constructs kernel-checkable equality transport.

The current slice does not claim all Lean locations, occurrence selectors, Iff
rewriting, or congruence behavior.

## `simp only`

The current simplifier story intentionally starts with explicit theorem sets:

```proofscript
by simp only [
  lemma1(...),
  lemma2(...)
];
```

This is much smaller than Lean's full global simplifier.

Explicitness makes termination, rule choice, and proof reconstruction easier to
audit during the early theorem-prover stage.

## `exact?`

The current bounded search explores a constrained set of locals/environment
candidates and accepts a candidate only when ordinary exact-style elaboration
closes the goal.

It is not full `solveByElim`/library search.

## Proofs over data

The current stdlib demonstrates useful patterns:

```proofscript
theorem optionGetOrElseSome {α: Type}
(value: α, fallback: α): optionGetOrElse(PsOption.some(value), fallback) = value := by rfl;
```

and proofs by cases:

```proofscript
theorem optionOrElseNoneRight {α: Type}
(value: PsOption(α)): optionOrElse(value, PsOption.none) = value :=
  by cases value; rfl; rfl;
```

These examples are valuable because they exercise ordinary language semantics,
not a separate theorem-only evaluator.

## Proof erasure

A valid proof may be erased before runtime when it is irrelevant to execution.

That does not make the proof unimportant: it influenced what could be checked.

It means the target does not need to carry a proof object when no executable
behavior depends on it.

## Axioms and runtime assumptions

A project can have assumptions.

Those assumptions should remain visible in assurance/trust metadata.

An npm FFI implementation is a runtime assumption, not a way to prove a
proposition by executing JavaScript.

## Proof correctness vs compiler correctness

A valid theorem proves its proposition under the logical assumptions.

It does not automatically prove that the compiler preserves every runtime
behavior while erasing/lowering the program.

PSC1 keeps these assurance questions separate.

## Good proof style for PSC1

For the first profile, prefer:

- small theorem statements;
- definitional computation when possible;
- explicit cases/induction;
- explicit rewrite lemmas;
- small deterministic tactic steps;
- ordinary reusable library theorems.

Do not make the language depend on enormous proof automation merely to make
simple verified programs writable.

## Next

Continue to [Typeclasses and Instances](./07-typeclasses-and-instances.md).
