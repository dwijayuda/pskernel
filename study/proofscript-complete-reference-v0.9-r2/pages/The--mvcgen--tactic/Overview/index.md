<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Overview"></a>

# ProofScript — 17.1. Overview

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Verification-condition generation connects a computation to a program-logic specification. Predicate transformers, state/error behavior, supported monads and loop interfaces are part of that connection. The final proof must establish the approved property of the actual computation, not merely prove unrelated obligations emitted by a buggy generator. Intrinsic contracts are experimental at the selected pin.

**Compiler and coverage boundary.** Keep the native requires/ensures grammar, generated theorem identities, residual proof sections and assumption reports. The inherited example uses native spelling intentionally; it is already an L-class ProofScript form.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--mvcgen--tactic/Overview/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--mvcgen--tactic/Overview/index.html). Source Git blob: `67e7e57e3b7954ef03e6d7ee6d9832edb139e233`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 17.1. Overview

The workflow of `mvcgen` consists of the following:

1. Monadic programs are re-interpreted according to a [predicate transformer semantics](../Predicate-Transformers/index.md#--tech-term-predicate-transformer-semantics). An instance of `WP` determines the monad's interpretation. Each program is interpreted as a mapping from arbitrary [postconditions](../Predicate-Transformers/index.md#--tech-term-postcondition) to the [weakest precondition](../Predicate-Transformers/index.md#--tech-term-weakest-preconditions) that would ensure the postcondition. This step is invisible to most users, but library authors who want to enable their monads to work with `mvcgen` need to understand it.
2. Programs are composed from smaller programs. Each statement in a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block is associated with a predicate transformer, and there are general-purpose rules for combining these statements with sequencing and control-flow operators. A statement with its pre- and postconditions is called a [*Hoare triple*](../Predicate-Transformers/index.md#--tech-term-Hoare-triple). In a program, the postcondition of each statement should suffice to prove the precondition of the next one, and loops require a specified 
  <a id="--tech-term-loop-invariant"></a>
  *loop invariant*, which is a statement that must be true at the beginning of the loop and at the end of each iteration. Designated [*specification lemmas*](../Predicate-Transformers/index.md#--tech-term-Specification-lemmas) associate functions with Hoare triples that specify them.
3. Applying the weakest-precondition semantics of a monadic program to a desired proof goal results in the precondition that must hold in order to prove the goal. Any missing steps such as loop invariants or proofs that a statement's precondition implies its postcondition become new subgoals. These missing steps are called the 
  <a id="--tech-term-verification-conditions"></a>
  *verification conditions*. The `mvcgen` tactic performs this transformation, replacing the goal with its verification conditions. During this transformation, `mvcgen` uses specification lemmas to discharge proofs about individual statements.
4. After supplying loop invariants, many verification conditions can in practice be discharged automatically. Those that cannot can be proven using either a [special proof mode](../../Tactic-Proofs/Tactic-Reference/index.md#tactic-ref-spred) or ordinary Lean tactics, depending on whether they are expressed in the logic of program assertions or as ordinary propositions.
