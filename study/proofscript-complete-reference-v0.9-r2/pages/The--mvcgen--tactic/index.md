<a id="mvcgen-tactic"></a>

# ProofScript — 17. The mvcgen tactic

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Verification-condition generation connects a computation to a program-logic specification. Predicate transformers, state/error behavior, supported monads and loop interfaces are part of that connection. The final proof must establish the approved property of the actual computation, not merely prove unrelated obligations emitted by a buggy generator. Intrinsic contracts are experimental at the selected pin.

## ProofScript way of writing it


```proofscript
import Std.Internal.Do
set_option experimental.intrinsic true

def unchanged (n : Nat) : Id Nat
    ensures result => result = n :=
  pure n
```

**Compiler and coverage boundary.** Keep the native requires/ensures grammar, generated theorem identities, residual proof sections and assumption reports. The inherited example uses native spelling intentionally; it is already an L-class ProofScript form.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--mvcgen--tactic/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--mvcgen--tactic/index.html). Source Git blob: `7ead82c6c5262d3dcc4a48686e73267b5aee95eb`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 17. The mvcgen tactic

## Tutorials

- [Verifying Imperative Programs Using `mvcgen`](https://lean-lang.org/doc/tutorials/4.34.0-rc2//#mvcgen-tactic-tutorial)

The `mvcgen` tactic implements a *monadic verification condition generator*: It breaks down a goal involving a program written using Lean's imperative [`do`](../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) notation into a number of smaller [*verification conditions*](Overview/index.md#--tech-term-verification-conditions) (
<a id="--tech-term-VCs"></a>
VCs) that are sufficient to prove the goal. In addition to a reference that describes the use of `mvcgen`, this chapter includes a [tutorial](https://lean-lang.org/doc/tutorials/4.34.0-rc2//#mvcgen-tactic-tutorial) that can be read independently of the reference.

In order to use the `mvcgen` tactic, `Std.Tactic.Do` must be imported and the namespace `Std.Do` must be opened.

1. [17.1. Overview](Overview/index.md#The-Lean-Language-Reference--The--mvcgen--tactic--Overview)
2. [17.2. Predicate Transformers](Predicate-Transformers/index.md#The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers)
3. [17.3. Verification Conditions](Verification-Conditions/index.md#The-Lean-Language-Reference--The--mvcgen--tactic--Verification-Conditions)
4. [17.4. Enabling `mvcgen` For Monads](Enabling--mvcgen--For-Monads/index.md#The-Lean-Language-Reference--The--mvcgen--tactic--Enabling--mvcgen--For-Monads)
5. [17.5. Proof Mode](Proof-Mode/index.md#mvcgen-proof-mode)
