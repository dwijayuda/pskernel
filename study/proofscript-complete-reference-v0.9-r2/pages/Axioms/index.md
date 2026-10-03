<a id="axioms"></a>

# ProofScript — 8. Axioms

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

An axiom adds an assumption, not an implementation. Classical mathematics may use reviewed foundational assumptions, while stricter constructive profiles can restrict them. Report the transitive dependencies of each requested theorem. Research/editor placeholders are not strict-release evidence. A theorem about a foreign model does not by itself prove the external service implements that model.

## ProofScript way of writing it


```proofscript
theorem implicationIdentity {P: Prop}(h: P): P := by
  exact h

#print axioms implicationIdentity
```

**Compiler and coverage boundary.** Check the exact statement, referenced definitions and approved axiom identities. Do not restore pre-final native-evaluation kernel hooks from the mirror.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Axioms/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Axioms/index.html). Source Git blob: `59cae2ce97416b64c1ff327912473c7734f1b93c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

> **Stable-pin correction:** this inherited page mentions `Lean.reduceBool`, `Lean.reduceNat`, `Lean.ofReduceBool`, `Lean.ofReduceNat`, `Lean.trustCompiler`. These pre-final kernel mechanisms are not part of the selected Lean 4.34.0 stable semantics. Their historical descriptions remain for source coverage, not as authorization to implement those reductions. Native proof tactics require separate assumption/evidence accounting.

---

## 8. Axioms

<a id="--tech-term-Axioms"></a>
*Axioms* are postulated constants. While the axiom's type must itself be a type (that is, it must have type `Sort u`), there are no further requirements. Axioms do not [reduce](../The-Type-System/index.md#--tech-term-reduction) to other terms.

Axioms can be used to experiment with the consequences of an idea before investing the time required to construct a model or prove a theorem. They can also be used to adopt reasoning principles that can't otherwise be accessed in Lean's type theory; Lean itself provides [three such axioms](index.md#standard-axioms) that are known to be consistent. However, axioms should be used with caution: axioms that are inconsistent with one another, or just false, undermine the very foundations of proofs. Lean automatically tracks the axioms that each proof depends on so that they can be audited.

<a id="axiom-declarations"></a>
### 8.1. Axiom Declarations

Axioms declarations include a name and a type:

<a id="Lean___Parser___Command___axiom"></a>

**syntax**

**Axiom Declarations**

<a id="Lean___Parser___Command___axiom-next"></a>

```ebnf
axiom ::= ...
    | axiom declId declSig
```

Axioms declarations may be modified with all possible [declaration modifiers](../Definitions/Modifiers/index.md#declaration-modifiers). Documentation comments, attributes, `private`, and `protected` have the same meaning as for other declarations. The modifiers `partial`, `nonrec`, `noncomputable` and `unsafe` have no effect.

<a id="axiom-consistency"></a>
### 8.2. Consistency

Using axioms is risky. Because they introduce a new constant of any type, and an inhabitant of a type that is a proposition counts as a proof of the proposition, axioms can be used to prove even false propositions. Any proof that relies on an axiom can be trusted only to the extent that the axiom is both true and consistent with the other axioms used. By their very nature, Lean cannot check whether new axioms are consistent; please exercise care when adding axioms.

<a id="Inconsistencies-From-Axioms"></a>
Inconsistencies From Axioms 

Axioms may introduce inconsistency, either alone or in combination with other axioms.

Assuming a false statement allows any statement at all to be proved:
<a id="false_is_true-_LPAR_in-Inconsistencies-From-Axioms_RPAR_"></a>
<a id="two_eq_five-_LPAR_in-Inconsistencies-From-Axioms_RPAR_"></a>


```proofscript
axiom false_is_true : False

theorem two_eq_five : 2 = 5 := false_is_true.elim
```

Inconsistency may also arise from axioms that are incompatible with other properties of Lean. For example, parametricity is a powerful reasoning technique when used in languages that support it, but it is not compatible with Lean's standard axioms. If parametricity held, then the “free theorem” from the introduction to Wadler's [*Theorems for Free*](https://dl.acm.org/doi/pdf/10.1145/99370.99404) (1989), which describes a technique for using parametricity to derive theorems about polymorphic functions, would be true. As an axiom, it reads:
<a id="List___free_theorem-_LPAR_in-Inconsistencies-From-Axioms_RPAR_"></a>


```proofscript
axiom List.free_theorem {α β}
  (f : {α : _} → List α → List α) (g : α → β) :
  f ∘ (List.map g) = (List.map g) ∘ f
```

However, a consequence of excluded middle is that all propositions are decidable; this means that a function can *check* whether they are true or false. This function can't be compiled, but it still exists. This can be used to define polymorphic functions that are not parametric:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="nonParametric-_LPAR_in-Inconsistencies-From-Axioms_RPAR_"></a>


```proofscript
open Classical in
noncomputable function nonParametric
    {α : _} (xs : List α) :
    List α :=
  if α = Nat then [] else xs
```

The existence of this function contradicts the “free theorem”:
<a id="unit_not_nat-_LPAR_in-Inconsistencies-From-Axioms_RPAR_"></a>


```proofscript
theorem unit_not_nat : Unit ≠ Nat := by
  intro eq
  have ⟨allEq⟩ := eq ▸ (inferInstance : Subsingleton Unit)
  specialize allEq 0 1
  contradiction

example : False := by
  have := List.free_theorem nonParametric (fun () => 42)

  unfold nonParametric at this
  simp [unit_not_nat] at this

  have := congrFun this [()]
  contradiction
```

<a id="axiom-reduction"></a>
### 8.3. Reduction

Even consistent axioms can cause difficulties. [Definitional equality](../The-Type-System/index.md#--tech-term-definitional-equality) identifies terms modulo reduction rules. The [ι-reduction](../The-Type-System/Inductive-Types/index.md#--tech-term-___-reduction) rule specifies the interaction of recursors and constructors; because axioms are not constructors, it does not apply to them. Ordinarily, terms without free variables reduce to applications of constructors, but axioms can cause them to get “stuck,” resulting in large terms.

<a id="Axioms-and-Stuck-Reduction"></a>
Axioms and Stuck Reduction 

Adding an additional `0` to `Nat` with an axiom results in some definitional reductions getting stuck. In this example, two `Nat.succ` constructors are successfully moved to the outside of the term by reduction, but `Nat.rec` is unable to make further progress after encountering `Nat.otherZero`.
<a id="Nat___otherZero-_LPAR_in-Axioms-and-Stuck-Reduction_RPAR_"></a>


```proofscript
axiom Nat.otherZero : Nat

#reduce 4 + (Nat.otherZero + 2)
```

```lean
((Nat.rec ⟨fun x => x, PUnit.unit⟩ (fun n n_ih => ⟨fun x => (n_ih.1 x).succ, n_ih⟩) Nat.otherZero).1 4).succ.succ
```

Furthermore, the Lean compiler is not able to generate code for axioms. At runtime, Lean values must be represented by concrete data in memory, but axioms do not have a concrete representation. Definitions that contain non-proof code that relies on axioms must be marked `noncomputable` and can't be compiled.

<a id="Axioms-and-Compilation"></a>
Axioms and Compilation 

Adding an additional `0` to `Nat` with an axiom makes it so functions that use it can't be compiled. In particular, `List.length'` returns the axiom `Nat.otherZero` instead of `Nat.zero` as the length of the empty list.
<a id="Nat___otherZero-_LPAR_in-Axioms-and-Compilation_RPAR_"></a>


```proofscript
axiom Nat.otherZero : Nat

def List.length' : List α → Nat
  | [] => Nat.otherZero
  | _ :: _ => xs.length
```

```lean
`Nat.otherZero` not supported by code generator; consider marking definition as `noncomputable`
```

Axioms used in proofs rather than programs do not prevent a function from being compiled. The compiler does not generate code for proofs, so axioms in proofs are no problem. `nextOdd` computes the next odd number from a `Nat`, which may be the number itself or one greater:
<a id="nextOdd-_LPAR_in-Axioms-and-Compilation_RPAR_"></a>


```proofscript
def nextOdd (k : Nat) :
    { n : Nat // n % 2 = 1 ∧ (n = k ∨ n = k + 1) } where
  val := if k % 2 = 1 then k else k + 1
  property := by
    by_cases k % 2 = 1 <;>
    simp [*] <;> omega
```

The tactic proof generates a term that transitively relies on three axioms:

```proofscript
#print axioms nextOdd
```

```lean
'nextOdd' depends on axioms: [propext, Classical.choice, Quot.sound]
```

Because they occur only in a proof, the compiler has no problem generating code:

```proofscript
#eval (nextOdd 4, nextOdd 5)
```

```lean
(5, 5)
```

<a id="standard-axioms"></a>
### 8.4. Standard Axioms

There are seven standard axioms in Lean. The first three axioms are important parts of how mathematics is done in Lean:

- ```proofscript
  Classical.choice.{u} {α : Sort u} : Nonempty α → α
  ```
- ```proofscript
  propext {a b : Prop} : (a ↔ b) → a = b
  ```
- ```proofscript
  Quot.sound.{u} {α : Sort u}
    {r : α → α → Prop} {a b : α} :
    r a b → Quot.mk r a = Quot.mk r b
  ```

All three of these axioms are discussed in the book [Theorem Proving in Lean](https://lean-lang.org/theorem_proving_in_lean4/find/?domain=Verso.Genre.Manual.section&name=axioms-and-computation).

The axiom `sorryAx` is used as part of the implementation of the `sorry` tactic and `sorry` term. Uses of this axiom are not intended to occur in finished proofs, as it can be used to prove anything:

- ```proofscript
  sorryAx {α : Sort u} (synthetic := true) : α
  ```

Three final axioms do not truly exist for their *mathematical* content; from a mathematical perspective they prove trivial statements:

- ```proofscript
  Lean.trustCompiler : True
  ```
- ```proofscript
  Lean.ofReduceBool (a b : Bool) : Lean.reduceBool a = b → a = b
  ```
- ```proofscript
  Lean.ofReduceNat (a b : Nat) : Lean.reduceNat a = b → a = b
  ```

These axioms instead track proofs that depend on the correctness of the entire compiler, and not just on the much smaller [`kernel`](../Elaboration-and-Compilation/index.md#--tech-term-kernel).

<a id="Creating-and-Tracking-Proofs-That-Trust-the-Compiler"></a>
Creating and Tracking Proofs That Trust the Compiler 

The functions `Lean.reduceBool` and `Lean.reduceNat` can be invoked to have the compiler perform a calculation; this can greatly improve performance of implementations of proof by reflection.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="largeNumber-_LPAR_in-Creating-and-Tracking-Proofs-That-Trust-the-Compiler_RPAR_"></a>


```proofscript
const largeNumber : Nat := Lean.reduceNat (230_000 + 4_500 + 1_000_067)
```

The resulting term depends on the axiom `Lean.trustCompiler` in order to track the fact that this calculation depends on the correctness of the compiler.

```proofscript
#print axioms largeNumber
```

```lean
'largeNumber' depends on axioms: [Lean.trustCompiler]
```

<a id="Axioms-and-the--native_decide--Tactic"></a>
Axioms and the `native_decide` Tactic 

Instead of appealing to `Lean.trustCompiler`, the `native_decide` tactic creates a bespoke axiom for each invocation. This allows each axiom to be audited for the precise statement that it proves.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="bigSum-_LPAR_in-Axioms-and-the--native_decide--Tactic_RPAR_"></a>


```proofscript
const bigSum : (List.range 1_001).sum = 500_500 := by native_decide
#print axioms bigSum
```

```lean
'bigSum' depends on axioms: [bigSum._native.native_decide.ax_1]
```

The axiom's type can be checked directly:

```proofscript
#check bigSum._native.native_decide.ax_1
```

```lean
bigSum._native.native_decide.ax_1 : decide ((List.range 1001).sum = 500500) = true
```

<a id="print-axioms"></a>
### 8.5. Displaying Axiom Dependencies

The command [`#print axioms`](../Interacting-with-Lean/index.md#Lean___Parser___Command___printAxioms), followed by a defined identifier, displays all the axioms that a definition transitively relies on. In other words, if a proof uses another proof, which itself uses an axiom, then the axiom is reported by [`#print axioms`](../Interacting-with-Lean/index.md#Lean___Parser___Command___printAxioms) for both.

This can be used to audit the assumptions made by a proof, for instance detecting that a proof transitively depends on the `sorry` tactic.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="lazy"></a>


```proofscript
const lazy : 4 == 2 + 1 + 1 := by sorry
```

```proofscript
#print axioms lazy
```

```lean
'lazy' depends on axioms: [sorryAx]
```

<a id="Printing-Axioms-of-Simple-Definitions"></a>
Printing Axioms of Simple Definitions 

Consider the following three constants:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="addThree-_LPAR_in-Printing-Axioms-of-Simple-Definitions_RPAR_"></a>
<a id="excluded_middle-_LPAR_in-Printing-Axioms-of-Simple-Definitions_RPAR_"></a>
<a id="simple_equality-_LPAR_in-Printing-Axioms-of-Simple-Definitions_RPAR_"></a>


```proofscript
function addThree (n : Nat) : Nat := 1 + n + 2
theorem excluded_middle (P : Prop) : P ∨ ¬ P := Classical.em P
theorem simple_equality (P : Prop) : (P ∨ False) = P := or_false P
```

Regular functions like `addThree` that we might want to actually evaluation typically do not depend on any axioms:

```proofscript
#print axioms addThree
```

```lean
'addThree' does not depend on any axioms
```

The excluded middle theorem is only true if we use classical reasoning, so the foundation for classical reasoning shows up alongside other axioms:

```proofscript
#print axioms excluded_middle
```

```lean
'excluded_middle' depends on axioms: [propext, Classical.choice, Quot.sound]
```

Finally, the idea that two equivalent propositions are equal directly relies on [propositional extensionality](../The-Type-System/Propositions/index.md#--tech-term-Extensionality).

```proofscript
#print axioms simple_equality
```

```lean
'simple_equality' depends on axioms: [propext]
```

<a id="Using--___print-axioms--with--___guard_msgs"></a>
Using [`#print axioms`](../Interacting-with-Lean/index.md#Lean___Parser___Command___printAxioms) with [`#guard_msgs`](../Interacting-with-Lean/index.md#Lean___guardMsgsCmd) 

You can use [`#print axioms`](../Interacting-with-Lean/index.md#Lean___Parser___Command___printAxioms) together with [`#guard_msgs`](../Interacting-with-Lean/index.md#Lean___guardMsgsCmd) to ensure that updates to libraries from other projects cannot silently introduce unwanted dependencies on axioms.

For example, if the proof of `double_neg_elim` below changed in such a way that it used more axioms than those listed, then the [`#guard_msgs`](../Interacting-with-Lean/index.md#Lean___guardMsgsCmd) command would report an error.
<a id="double_neg_elim-_LPAR_in-Using--___print-axioms--with--___guard_msgs_RPAR_"></a>


```proofscript
theorem double_neg_elim (P : Prop) : (¬ ¬ P) = P :=
  propext Classical.not_not

/--
info: 'double_neg_elim' depends on axioms:
  [propext, Classical.choice, Quot.sound]
-/
#guard_msgs (whitespace := lax) in
#print axioms double_neg_elim
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`declId` matches `foo` or `foo.{u,v}`: an identifier possibly followed by a list of universe names
```


### Display 2


```text
`declSig` matches the signature of a declaration with required type: a list of binders and then `: type`
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
((Nat.rec ⟨fun x => x, PUnit.unit⟩ (fun n n_ih => ⟨fun x => (n_ih.1 x).succ, n_ih⟩) Nat.otherZero).1 4).succ.succ
```


### Display 2


```text
`Nat.otherZero` not supported by code generator; consider marking definition as `noncomputable`
```


### Display 3


```text
Unknown identifier `xs.length`
```


### Display 4


```text
'nextOdd' depends on axioms: [propext, Classical.choice, Quot.sound]
```


### Display 5


```text
(5, 5)
```


### Display 6


```text
`Lean.reduceNat` has been deprecated: in-kernel native reduction is deprecated; assert native evaluations with axioms instead
```


### Display 7


```text
'largeNumber' depends on axioms: [Lean.trustCompiler]
```


### Display 8


```text
Definition `bigSum` is a proposition; use `theorem` instead of `def`

Note: This linter can be disabled with `set_option linter.defProp false`
```


### Display 9


```text
'bigSum' depends on axioms: [bigSum._native.native_decide.ax_1]
```


### Display 10


```text
bigSum._native.native_decide.ax_1 : decide ((List.range 1001).sum = 500500) = true
```


### Display 11


```text
Definition `lazy` is a proposition; use `theorem` instead of `def`

Note: This linter can be disabled with `set_option linter.defProp false`
```


### Display 12


```text
declaration uses `sorry`
```


### Display 13


```text
'lazy' depends on axioms: [sorryAx]
```


### Display 14


```text
'addThree' does not depend on any axioms
```


### Display 15


```text
'excluded_middle' depends on axioms: [propext, Classical.choice, Quot.sound]
```


### Display 16


```text
'simple_equality' depends on axioms: [propext]
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ Unit ≠ Nat
```


### Display 2


```text
eq:Unit = Nat⊢ False
```


### Display 3


```text
eq:Unit = NatallEq:∀ (a b : Nat), a = b⊢ False
```


### Display 4


```text
eq:Unit = NatallEq:0 = 1⊢ False
```


### Display 5


```text
All goals completed! 🐙
```


### Display 6


```text
⊢ False
```


### Display 7


```text
this:(nonParametric ∘ List.map fun x => 42) = (List.map fun x => 42) ∘ nonParametric⊢ False
```


### Display 8


```text
this:((fun xs => if Nat = Nat then [] else xs) ∘ List.map fun x => 42) =
  (List.map fun x => 42) ∘ fun xs => if Unit = Nat then [] else xs⊢ False
```


### Display 9


```text
this:((fun xs => []) ∘ List.map fun x => 42) = (List.map fun x => 42) ∘ fun xs => xs⊢ False
```


### Display 10


```text
this✝:((fun xs => []) ∘ List.map fun x => 42) = (List.map fun x => 42) ∘ fun xs => xsthis:((fun xs => []) ∘ List.map fun x => 42) [()] = ((List.map fun x => 42) ∘ fun xs => xs) [()]⊢ False
```


### Display 11


```text
k:Nat⊢ (if k % 2 = 1 then k else k + 1) % 2 = 1 ∧
  ((if k % 2 = 1 then k else k + 1) = k ∨ (if k % 2 = 1 then k else k + 1) = k + 1)
```


### Display 12


```text
posk:Nath✝:k % 2 = 1⊢ (if k % 2 = 1 then k else k + 1) % 2 = 1 ∧
  ((if k % 2 = 1 then k else k + 1) = k ∨ (if k % 2 = 1 then k else k + 1) = k + 1)negk:Nath✝:¬k % 2 = 1⊢ (if k % 2 = 1 then k else k + 1) % 2 = 1 ∧
  ((if k % 2 = 1 then k else k + 1) = k ∨ (if k % 2 = 1 then k else k + 1) = k + 1)
```


### Display 13


```text
negk:Nath✝:¬k % 2 = 1⊢ (k + 1) % 2 = 1
```


### Display 14


```text
⊢ (List.range 1001).sum = 500500
```


### Display 15


```text
⊢ (4 == 2 + 1 + 1) = true
```

