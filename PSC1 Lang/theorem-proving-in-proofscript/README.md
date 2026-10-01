# Theorem Proving in ProofScript PSC1

This book is the PSC1 counterpart to the material studied under
`study/theorem_proving_in_lean4/`.

It teaches the theorem prover as a **proof-term construction system** rather than
as a bag of magical tactics.

PSC1 deliberately supports a much smaller tactic and source surface than full
Lean. The semantic core is still Lean-compatible where PSC1 claims support, and
the final authority is pskernel.

## Reading order

1. [Dependent Type Theory](./01-dependent-type-theory.md)
2. [Propositions and Proofs](./02-propositions-and-proofs.md)
3. [Quantification and Equality](./03-quantification-and-equality.md)
4. [Goals and Tactics](./04-goals-and-tactics.md)
5. [Inductive Types and Elimination](./05-inductive-types-and-elimination.md)
6. [Induction and Recursion](./06-induction-and-recursion.md)
7. [Structures, Classes, and Evidence](./07-structures-classes-and-evidence.md)
8. [Axioms, Computation, and Trust](./08-axioms-computation-and-trust.md)
9. [Proof Feedback and Debugging](./09-proof-feedback-and-debugging.md)
10. [Worked Proof Patterns](./10-worked-proof-patterns.md)
11. [The PSC1 Proof Boundary](./11-the-psc1-proof-boundary.md)

## Current bounded tactic vocabulary

The executable PSC1 tactic parser currently recognizes the bounded family:

```text
exact
exact?
assumption
rfl
apply
refine
constructor
cases
induction
rw
simp only
intro
```

Every tactic must construct or refine an ordinary proof term that pskernel
checks.

This book therefore does **not** teach unsupported Lean tactics as PSC1
features.

## Proofs and programs share a type theory

A runtime function:

```proofscript
function identity {α: Type}(x: α): α :=
  x;
```

and a theorem:

```proofscript
theorem selfEq {α: Type}(x: α): x = x := by rfl;
```

are both elaborated into typed terms.

The difference is that theorem results inhabit `Prop` and can usually erase
before runtime.

## Trust model

```text
source tactic script
-> tactic elaboration
-> proof term
-> pskernel
```

The tactic implementation, parser, LSP, generated TypeScript, and runtime are
not permitted to bypass the kernel.

For exact implementation status see
[../CONFORMANCE_PORTABILITY_AND_STATUS.md](../CONFORMANCE_PORTABILITY_AND_STATUS.md).
