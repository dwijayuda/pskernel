<a id="simp-sets"></a>

# ProofScript — 15.3. Simp sets

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

simp uses selected rewrite theorems and congruence reasoning to construct checked evidence. simp only restricts the simplification set; simp at changes a hypothesis or location. The normal forms chosen by a library affect proof maintenance and automation. A simplifier is not a privileged evaluator permitted to replace an unproved goal with success.

**Compiler and coverage boundary.** Track the exact simp set, local hypotheses and configuration. A changed tactic script is not necessarily a changed theorem, but a cached proof must still match its dependency identity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Simplifier/Simp-sets/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Simplifier/Simp-sets/index.html). Source Git blob: `8d6a7c30fd97425e03e17c4af01e288f1c5b07fb`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 15.3. Simp sets

A collection of rules used by the simplifier is called a 
<a id="--tech-term-simp-set"></a>
*simp set*. A simp set is specified in terms of modifications from a 
<a id="--tech-term-default-simp-set"></a>
*default simp set*. These modifications can include adding rules, removing rules, or adding a set of rules. The `only` modifier to the `simp` tactic causes it to start with an empty simp set, rather than the default one. Rules are added to the default simp set using the `simp` attribute.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Registering simp Lemmas**

The `simp` attribute adds a declaration to the default simp set. If the declaration is a definition, the definition is marked for unfolding; if it is a theorem, then the theorem is registered as a rewrite rule.

<a id="Lean___Parser___Attr___simp"></a>

```ebnf
attr ::= ...
    | simp
```

<a id="Lean___Parser___Attr___simp-next"></a>

```ebnf
attr ::= ...
    | simp ↑ prio?
```

<a id="Lean___Parser___Attr___simp-next-next"></a>

```ebnf
attr ::= ...
    | simp ↓ prio?
```

<a id="Lean___Parser___Attr___simp-next-next-next"></a>

```ebnf
attr ::= ...
    | simp prio
```

<a id="--tech-term-Custom-simp-sets"></a>
*Custom simp sets* are created with `registerSimpAttr`, which must be run during [initialization](../../Elaboration-and-Compilation/index.md#--tech-term-initialization) by placing it in an `initialize` block. As a side effect, it creates a new attribute with the same interface as `simp` that adds rules to the custom simp set. The returned value is a `SimpExtension`, which can be used to programmatically access the contents of the custom simp set. The `simp` tactics can be instructed to use the new simp set by including its attribute name in the rule list.

<a id="Lean___Meta___registerSimpAttr"></a>

**def**

```text
Lean.Meta.registerSimpAttr (attrName : Lean.Name) (attrDescr : String)
  (ref : Lean.Name := by exact decl_name%) : IO Lean.Meta.SimpExtension
```

Registers the given name as a custom simp set. Applying the name as an attribute to a name adds it to the simp set, and using the name as a parameter to the `simp` tactic causes `simp` to use the included lemmas.

Custom simp sets must be registered during [initialization](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=initialization).

The description should be a short, singular noun phrase that describes the contents of the custom simp set.

<a id="Lean___Meta___SimpExtension"></a>

**def**

```text
Lean.Meta.SimpExtension : Type
```

The environment extension that contains a simp set, returned by `Lean.Meta.registerSimpAttr`.

Use the simp set's attribute or `Lean.Meta.addSimpTheorem` to add theorems to the simp set. Use `Lean.Meta.SimpExtension.getTheorems` to get the contents.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


````text
Theorems tagged with the `simp` attribute are used by the simplifier
(i.e., the `simp` tactic, and its variants) to simplify expressions occurring in your goals.
We call theorems tagged with the `simp` attribute "simp theorems" or "simp lemmas".
Lean maintains a database/index containing all active simp theorems.
Here is an example of a simp theorem.
```lean
@[simp] theorem ne_eq (a b : α) : (a ≠ b) = Not (a = b) := rfl
```
This simp theorem instructs the simplifier to replace instances of the term
`a ≠ b` (e.g. `x + 0 ≠ y`) with `Not (a = b)` (e.g., `Not (x + 0 = y)`).
The simplifier applies simp theorems in one direction only:
if `A = B` is a simp theorem, then `simp` replaces `A`s with `B`s,
but it doesn't replace `B`s with `A`s. Hence a simp theorem should have the
property that its right-hand side is "simpler" than its left-hand side.
In particular, `=` and `↔` should not be viewed as symmetric operators in this situation.
The following would be a terrible simp theorem (if it were even allowed):
```lean
@[simp] lemma mul_right_inv_bad (a : G) : 1 = a * a⁻¹ := ...
```
Replacing 1 with a * a⁻¹ is not a sensible default direction to travel.
Even worse would be a theorem that causes expressions to grow without bound,
causing simp to loop forever.

By default the simplifier applies `simp` theorems to an expression `e`
after its sub-expressions have been simplified.
We say it performs a bottom-up simplification.
You can instruct the simplifier to apply a theorem before its sub-expressions
have been simplified by using the modifier `↓`. Here is an example
```lean
@[simp↓] theorem not_and_eq (p q : Prop) : (¬ (p ∧ q)) = (¬p ∨ ¬q) :=
```

You can instruct the simplifier to rewrite the lemma from right-to-left:
```lean
attribute @[simp ←] and_assoc
```

When multiple simp theorems are applicable, the simplifier uses the one with highest priority.
The equational theorems of functions are applied at very low priority (100 and below).
If there are several with the same priority, it is uses the "most recent one". Example:
```lean
@[simp high] theorem cond_true (a b : α) : cond true a b = a := rfl
@[simp low+1] theorem or_true (p : Prop) : (p ∨ True) = True :=
  propext <| Iff.intro (fun _ => trivial) (fun _ => Or.inr trivial)
@[simp 100] theorem ite_self {d : Decidable c} (a : α) : ite c a a = a := by
  cases d <;> rfl
```
````


### Display 2


```text
Use this rewrite rule after entering the subterms
```


### Display 3


```text
Use this rewrite rule before entering the subterms
```

