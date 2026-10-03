<a id="mvcgen-proof-mode"></a>

# ProofScript — 17.5. Proof Mode

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Verification-condition generation connects a computation to a program-logic specification. Predicate transformers, state/error behavior, supported monads and loop interfaces are part of that connection. The final proof must establish the approved property of the actual computation, not merely prove unrelated obligations emitted by a buggy generator. Intrinsic contracts are experimental at the selected pin.

**Compiler and coverage boundary.** Keep the native requires/ensures grammar, generated theorem identities, residual proof sections and assumption reports. The inherited example uses native spelling intentionally; it is already an L-class ProofScript form.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--mvcgen--tactic/Proof-Mode/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--mvcgen--tactic/Proof-Mode/index.html). Source Git blob: `d063a327c71ccba868086b71a5f4c18905a589bd`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 17.5. Proof Mode

Stateful goals can be proven using a special *proof mode* in which goals are rendered with two contexts of hypotheses: the ordinary Lean context, which contains Lean variables, and a special stateful context, which contains assumptions about the monadic state. In the proof mode, the goal is an `SPred`, rather than a `Prop`, and the entire goal is equivalent to an entailment relation (`SPred.entails`) from the conjunction of the hypotheses to the conclusion.

<a id="Std___Tactic___Do___mgoalStx"></a>

**syntax**

**Proof Mode Goals**

Proof mode goals are rendered as a series of named hypotheses, one per line, followed by [`⊢ₛ`](index.md#Std___Tactic___Do___mgoalStx-next) and a goal.

<a id="Std___Tactic___Do___mgoalStx-next"></a>

```ebnf
mgoalStx ::= ...
    | (ident : term)*
      ⊢ₛ term
```

In the proof mode, special tactics manipulate the stateful context. These tactics are described in [their own section in the tactic reference](../../Tactic-Proofs/Tactic-Reference/index.md#tactic-ref-spred).

When working with concrete monads, `mvcgen` typically does not result in stateful proof goals—they are simplified away. However, monad-polymorphic theorems can lead to stateful goals remaining.

<a id="Stateful-Proofs"></a>
Stateful Proofs 

The function `bump` increments its state by the indicated amount and returns the resulting value.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="bump-_LPAR_in-Stateful-Proofs_RPAR_"></a>


```proofscript
variable [Monad m] [WPMonad m ps]
function bump (n : Nat) : StateT Nat m Nat := do
  modifyThe Nat (· + n)
  getThe Nat
```

This specification lemma for `bump` is proved in an intentionally low-level manner to demonstrate the intermediate proof states:
<a id="bump_correct-_LPAR_in-Stateful-Proofs_RPAR_"></a>


```proofscript
theorem bump_correct :
      ⦃ fun n => ⌜n = k⌝ ⦄
      bump (m := m) i
      ⦃ ⇓ r n => ⌜r = n ∧ n = k + i⌝ ⦄ := by
  mintro n_eq_k
  unfold bump
  unfold modifyThe
  mspec
  mspec
  mpure_intro
  constructor
  . trivial
  . simp_all
```

The lemma can also be proved using only the simplifier:
<a id="bump_correct___-_LPAR_in-Stateful-Proofs_RPAR_"></a>


```proofscript
theorem bump_correct' :
    ⦃ fun n => ⌜n = k⌝ ⦄
    bump (m := m) i
    ⦃ ⇓ r n => ⌜r = n ∧ n = k + i⌝ ⦄ := by
  mintro _
  simp_all [bump]
```

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
m:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nat⊢ ⦃fun n => ⌜n = k⌝⦄ bump i ⦃PostCond.noThrow fun r n => ⌜r = n ∧ n = k + i⌝⦄
```


### Display 2


```text
m:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nat⊢ 
n_eq_k : fun n => ⌜n = k⌝
⊢ₛ wp⟦bump i⟧ (PostCond.noThrow fun r n => ⌜r = n ∧ n = k + i⌝)
```


### Display 3


```text
m:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nat⊢ 
n_eq_k : fun n => ⌜n = k⌝
⊢ₛ
wp⟦do
    modifyThe Nat fun x => x + i
    getThe Nat⟧
  (PostCond.noThrow fun r n => ⌜r = n ∧ n = k + i⌝)
```


### Display 4


```text
m:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nat⊢ 
n_eq_k : fun n => ⌜n = k⌝
⊢ₛ
wp⟦do
    MonadStateOf.modifyGet fun s => (PUnit.unit, s + i)
    getThe Nat⟧
  (PostCond.noThrow fun r n => ⌜r = n ∧ n = k + i⌝)
```


### Display 5


```text
m:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nat⊢ 
n_eq_k : fun n => ⌜n = k⌝
⊢ₛ fun s => wp⟦getThe Nat⟧ (PostCond.noThrow fun r n => ⌜r = n ∧ n = k + i⌝) (s + i)
```


### Display 6


```text
m:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nats✝:Nath✝:s✝ = k⊢ 
⊢ₛ ⌜True ∧ s✝ + i = k + i⌝
```


### Display 7


```text
m:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nats✝:Nath✝:s✝ = k⊢ True ∧ s✝ + i = k + i
```


### Display 8


```text
leftm:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nats✝:Nath✝:s✝ = k⊢ Truerightm:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nats✝:Nath✝:s✝ = k⊢ s✝ + i = k + i
```


### Display 9


```text
leftm:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nats✝:Nath✝:s✝ = k⊢ True
```


### Display 10


```text
All goals completed! 🐙
```


### Display 11


```text
rightm:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nats✝:Nath✝:s✝ = k⊢ s✝ + i = k + i
```


### Display 12


```text
m:Type → Type u_1ps:PostShapeinst✝¹:Monad minst✝:WPMonad m psi:Natk:Nat⊢ 
h✝ : fun n => ⌜n = k⌝
⊢ₛ wp⟦bump i⟧ (PostCond.noThrow fun r n => ⌜r = n ∧ n = k + i⌝)
```

