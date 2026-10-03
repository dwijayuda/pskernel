<a id="grind-ac"></a>

# ProofScript — 16.8. Associativity and Commutativity

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Associativity-and-Commutativity/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Associativity-and-Commutativity/index.html). Source Git blob: `623c443efb7827a0cc242336a143000cd822c0b0`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 16.8. Associativity and Commutativity

When an operator is associative, `grind` can efficiently rewrite terms that contain the operator to a normal form, making it easier to prove equalities that involve the operator. This rewriting can make use of further facts about the operator, such as the fact that it is commutative or idempotent, or that certain values are identities. Rewriting occurs both when adding terms to the “whiteboard” and in response to facts added by other solvers. This solver is controlled using the `ac` flag, and it is on by default. The `acSteps` option, which defaults to `1000`, controls how many `ac` rewriting steps are allowed.

<a id="Strings"></a>
Strings 

The `ac` solver can reason about strings. It's common for string-processing code to compute a prefix, and then later append further values. Using `ac`, these can be reasoned about more conveniently:

```proofscript
example (dir file p) (h : dir ++ "/" = p) :
    dir ++ ("/" ++ file) = p ++ file := by grind
```

<a id="The-Lean-Language-Reference--The--grind--tactic--Associativity-and-Commutativity--Normal-Forms"></a>
### 16.8.1. Normal Forms

The normal forms used by the `ac` solver depend on the properties that have been registered for the operator in question.

  Associativity

Associative operators are normalized by reducing nested trees of the operator to lists of operands. If `op` is associative, then the normal form of both `op (op x y) z` and `op x (op y z)` is `[x, y, z]`.

  Commutativity

Operators that are associative and commutative are normalized by sorting the operand lists. If `op` is associative and commutative, then the normal form of both `op z (op x y)` and `op (op x z) y` is `[x, y, z]`. In other words, the normal form is a multiset.

  Idempotence

If the operator is idempotent, then runs of duplicate elements are collapsed in the operand list. If `op` is associative and idempotent, then the normal form of `op x (op x y)` is `[x, y]`, but the normal form of `op (op x y) x` is still `[x, y, x]`. This collapsing occurs after sorting the list if the operator is commutative, so if `op` is associative, commutative, and idempotent, then the normal form of `op (op x y) x` is also `[x, y]`. In other words, the normal form of an associative, commutative, and idempotent operator is a set.

  Identities

If the operator has a unit, then it is removed from the normal form. That is, if `u` is a unit of the associative operator `op`, then the normal form of `op x (op u y)` is `[x, y]`.

<a id="The-Lean-Language-Reference--The--grind--tactic--Associativity-and-Commutativity--Extension"></a>
### 16.8.2. Extension

The `ac` solver can be extended to support new operators by providing an instance of `Std.Associative` for the operator. Instances of `Std.Commutative`, `Std.IdempotentOp`, and `Std.LawfulIdentity` further extend its capabilities by identifying more terms.

<a id="Std___Associative___mk"></a>

**type class**

```text
Std.Associative.{u} {α : Sort u} (op : α → α → α) : Prop
```

`Associative op` indicates `op` is an associative operation, i.e. `(a ∘ b) ∘ c = a ∘ (b ∘ c)`.

**Instance Constructor**

```text
Std.Associative.mk.{u}
```

**Methods**

```text
assoc : ∀ (a b c : α), op (op a b) c = op a (op b c)
```

An associative operation satisfies `(a ∘ b) ∘ c = a ∘ (b ∘ c)`.

<a id="Std___Commutative___mk"></a>

**type class**

```text
Std.Commutative.{u} {α : Sort u} (op : α → α → α) : Prop
```

`Commutative op` says that `op` is a commutative operation, i.e. `a ∘ b = b ∘ a`.

**Instance Constructor**

```text
Std.Commutative.mk.{u}
```

**Methods**

```text
comm : ∀ (a b : α), op a b = op b a
```

A commutative operation satisfies `a ∘ b = b ∘ a`.

<a id="Std___IdempotentOp___mk"></a>

**type class**

```text
Std.IdempotentOp.{u} {α : Sort u} (op : α → α → α) : Prop
```

`IdempotentOp op` indicates `op` is an idempotent binary operation. i.e. `a ∘ a = a`.

**Instance Constructor**

```text
Std.IdempotentOp.mk.{u}
```

**Methods**

```text
idempotent : ∀ (x : α), op x x = x
```

An idempotent operation satisfies `a ∘ a = a`.

<a id="Std___LawfulIdentity___mk"></a>

**type class**

```text
Std.LawfulIdentity.{u} {α : Sort u} (op : α → α → α) (o : outParam α) :
  Prop
```

`LawfulIdentity op o` indicates `o` is a verified left and right identity of `op`.

**Instance Constructor**

```text
Std.LawfulIdentity.mk.{u}
```

**Extends**

- <a id="0-Std.Identity-Std.LawfulIdentity"></a>
  `Std.Identity op o`
- <a id="1-Std.LawfulLeftIdentity-Std.LawfulIdentity"></a>
  `Std.LawfulLeftIdentity op o`
- <a id="2-Std.LawfulRightIdentity-Std.LawfulIdentity"></a>
  `Std.LawfulRightIdentity op o`

**Methods**

```text
left_id : ∀ (a : α), op o a = a
```

 Inherited from 

1. `Std.Identity op o`
2. `Std.LawfulLeftIdentity op o`
3. `Std.LawfulRightIdentity op o`

```text
right_id : ∀ (a : α), op a o = a
```

 Inherited from 

1. `Std.Identity op o`
2. `Std.LawfulLeftIdentity op o`
3. `Std.LawfulRightIdentity op o`

While extending the `ac` solver, it can be useful to observe its operation. The option `trace.grind.ac`, as well as the more specific options `trace.grind.ac.assert`, `trace.grind.ac.internalize`, and `trace.grind.ac.basis`, can be used to observe its internal behavior. In particular, `trace.grind.ac.assert` displays the results of normalization that are added to the “whiteboard.”

<a id="trace___grind___ac"></a>

**option**

```text
trace.grind.ac
```

Default value: `false`

enable/disable tracing for the given module and submodules

<a id="trace___grind___ac___assert"></a>

**option**

```text
trace.grind.ac.assert
```

Default value: `false`

enable/disable tracing for the given module and submodules

<a id="trace___grind___ac___internalize"></a>

**option**

```text
trace.grind.ac.internalize
```

Default value: `false`

enable/disable tracing for the given module and submodules

<a id="trace___grind___ac___basis"></a>

**option**

```text
trace.grind.ac.basis
```

Default value: `false`

enable/disable tracing for the given module and submodules

<a id="Idempotence-and-Identity"></a>
Idempotence and Identity 

`Flags` tracks a set of Boolean flags, each of which corresponds to a bit position. Each flag is either set or clear, and all flags are clear when the bit value is `0`. The union of two sets of flags is found by taking the bit-wise OR of their bit representations.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Flags-_LPAR_in-Idempotence-and-Identity_RPAR_"></a>
<a id="Flags___bits-_LPAR_in-Idempotence-and-Identity_RPAR_"></a>
<a id="Flags___union-_LPAR_in-Idempotence-and-Identity_RPAR_"></a>
<a id="Flags___none-_LPAR_in-Idempotence-and-Identity_RPAR_"></a>


```proofscript
structure Flags where
  bits : Nat

namespace Flags

function union (a b : Flags) : Flags := ⟨a.bits ||| b.bits⟩
const none : Flags := ⟨0⟩
```

The union operation on flags is associative, commutative, and idempotent, and `Flags.none` is an identity:

```proofscript
instance : Std.Associative union where
  assoc x y z := by simp only [union, mk.injEq]; grind
instance : Std.Commutative union where
  comm x y := by simp only [union, mk.injEq]; grind
instance : Std.IdempotentOp union where
  idempotent x := by simp [union]
instance : Std.LawfulIdentity union none where
  left_id a := by simp [union, none]
  right_id a := by simp [union, none]
```

With these instances, the `ac` solver can dispatch all of the following goals. In the second example, idempotency can only be used due to commutativity, because the two identical arguments are not adjacent in the original term.

```proofscript
example : union a (union b c) = union (union c a) b := by grind
example : union (union a b) a = union a b := by grind
example : union a none = a := by grind
example :
    union (union a b) (union none (union b c))
      = union a (union b c) := by
  grind
```

The negated normal-form equality that is added to the context can be seen using `trace.grind.ac.assert`:

```proofscript
set_option trace.grind.ac.assert true in
example : union (union a b) a = union a (union b none) := by grind
```

```lean
[grind.ac.assert] a.union b ≠ a.union b
```

<a id="difference-lists-ac"></a>
Difference Lists 

A 
<a id="--tech-term-difference-list"></a>
*difference list* is a clever representation of lists as functions that avoids the quadratic overhead of appending to the end of lists. Because Lean supports [efficient arrays](../../Basic-Types/Arrays/index.md#Array), they are typically not useful in day-to-day code, but they effectively demonstrate how to extend the `ac` solver.

A difference list is a function from lists to lists. The list `xs` is represented by a function that, when applied to `ys`, returns `xs ++ ys`.
<a id="DList-_LPAR_in-Difference-Lists_RPAR_"></a>


```proofscript
def DList α := List α → List α
```

The empty list is the identity function. An item is added to the beginning of a list by creating a function that adds the element. Appending two lists is function composition.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="DList___empty-_LPAR_in-Difference-Lists_RPAR_"></a>
<a id="DList___cons-_LPAR_in-Difference-Lists_RPAR_"></a>


```proofscript
const DList.empty : DList α := id

function DList.cons (x : α) (xs : DList α) : DList α :=
  fun ys => (x :: xs ys)

instance : Append (DList α) where
  append xs ys := xs ∘ ys
```

The proofs that appending two difference lists is associative and that the empty difference list is a left and right identity of the append operator succeed by reflexivity because definitional equality includes the β and η laws for functions:

```proofscript
instance : Std.Associative (α := DList α) (· ++ ·) where
  assoc xs ys zs := by rfl

instance : Std.LawfulIdentity (α := DList α) (· ++ ·) .empty where
  left_id xs := by rfl
  right_id xs := by rfl
```

Given these instances, `grind` can dispatch many proofs.

```proofscript
variable (a b c d x y : DList Nat)
```

Because append is associative, terms can be rebracketed and units vanish:

```proofscript
example : ((a ++ b) ++ c) ++ d = a ++ (b ++ (c ++ d)) := by grind

example : (a ++ .empty) ++ (.empty ++ b) = a ++ b := by grind

example : (.empty ++ .empty : DList Nat) = .empty := by grind
```

While [simplification lemmas](../../The-Simplifier/Rewrite-Rules/index.md#simp-rewrites) could easily solve those problems, `grind`'s `ac` solver allows a greater degree of flexibility. To use the hypotheses in these examples, it would not be sufficient to just rewrite goals and hypotheses to a normal form that reassociated an associative operator to the right:

```proofscript
example (h : a ++ b = x) : a ++ (b ++ c) = x ++ c := by grind

example (h : a ++ b = x) :
    (a ++ .empty) ++ (b ++ c) = x ++ c := by grind

example (h₁ : a ++ b = x) (h₂ : x ++ c = y) :
    a ++ (b ++ c) = y := by grind
```

Because appending difference lists is not commutative, order still matters:

```proofscript
example : a ++ b = b ++ a := by grind
```
<a id="--verso-unique-1579"></a>


```lean
`grind` failed
grinda b c d x y:DList Nath:¬a ++ b = b ++ a⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] ¬a ++ b = b ++ a[eqc] False propositions[prop] a ++ b = b ++ a[assoc] Operator `HAppend.hAppend`[diseqs] Disequalities[_] a ++ b ≠ b ++ a[properties] Properties[_] identity: `DList.empty`
```

<a id="The-Lean-Language-Reference--The--grind--tactic--Associativity-and-Commutativity--Exclusions"></a>
### 16.8.3. Exclusions

The `ac` solver does not apply to some built-in operators, namely `And`, `Or`, and `Iff`. They are better served by other `grind` features. When the operand type has `Lean.Grind.CommRing` and/or `Lean.Grind.CommSemiring` instances, `ac` omits its rules for certain operators that are usually better solved by [the `ring` solver](../Algebraic-Solver-_LPAR_Commutative-Rings___-Fields_RPAR_/index.md#grind-ring), namely `+`, `-`, `*`, `/`, and `^`.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
[grind.ac.assert] a.union b ≠ a.union b
```


### Display 2


```text
`grind` failed
grinda b c d x y:DList Nath:¬a ++ b = b ++ a⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] ¬a ++ b = b ++ a[eqc] False propositions[prop] a ++ b = b ++ a[assoc] Operator `HAppend.hAppend`[diseqs] Disequalities[_] a ++ b ≠ b ++ a[properties] Properties[_] identity: `DList.empty`
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
dir:Stringfile:Stringp:Stringh:dir ++ "/" = p⊢ dir ++ ("/" ++ file) = p ++ file
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
x:Flagsy:Flagsz:Flags⊢ (x.union y).union z = x.union (y.union z)
```


### Display 4


```text
x:Flagsy:Flagsz:Flags⊢ x.bits ||| y.bits ||| z.bits = x.bits ||| (y.bits ||| z.bits)
```


### Display 5


```text
x:Flagsy:Flags⊢ x.union y = y.union x
```


### Display 6


```text
x:Flagsy:Flags⊢ x.bits ||| y.bits = y.bits ||| x.bits
```


### Display 7


```text
x:Flags⊢ x.union x = x
```


### Display 8


```text
a:Flags⊢ none.union a = a
```


### Display 9


```text
a:Flags⊢ a.union none = a
```


### Display 10


```text
a:Flagsb:Flagsc:Flags⊢ a.union (b.union c) = (c.union a).union b
```


### Display 11


```text
a:Flagsb:Flags⊢ (a.union b).union a = a.union b
```


### Display 12


```text
a:Flagsb:Flagsc:Flags⊢ (a.union b).union (none.union (b.union c)) = a.union (b.union c)
```


### Display 13


```text
a:Flagsb:Flags⊢ (a.union b).union a = a.union (b.union none)
```


### Display 14


```text
α:Type u_1xs:DList αys:DList αzs:DList α⊢ xs ++ ys ++ zs = xs ++ (ys ++ zs)
```


### Display 15


```text
α:Type u_1xs:DList α⊢ DList.empty ++ xs = xs
```


### Display 16


```text
α:Type u_1xs:DList α⊢ xs ++ DList.empty = xs
```


### Display 17


```text
a:DList Natb:DList Natc:DList Natd:DList Natx:DList Naty:DList Nat⊢ a ++ b ++ c ++ d = a ++ (b ++ (c ++ d))
```


### Display 18


```text
a:DList Natb:DList Natc:DList Natd:DList Natx:DList Naty:DList Nat⊢ a ++ DList.empty ++ (DList.empty ++ b) = a ++ b
```


### Display 19


```text
a:DList Natb:DList Natc:DList Natd:DList Natx:DList Naty:DList Nat⊢ DList.empty ++ DList.empty = DList.empty
```


### Display 20


```text
a:DList Natb:DList Natc:DList Natd:DList Natx:DList Naty:DList Nath:a ++ b = x⊢ a ++ (b ++ c) = x ++ c
```


### Display 21


```text
a:DList Natb:DList Natc:DList Natd:DList Natx:DList Naty:DList Nath:a ++ b = x⊢ a ++ DList.empty ++ (b ++ c) = x ++ c
```


### Display 22


```text
a:DList Natb:DList Natc:DList Natd:DList Natx:DList Naty:DList Nath₁:a ++ b = xh₂:x ++ c = y⊢ a ++ (b ++ c) = y
```


### Display 23


```text
a:DList Natb:DList Natc:DList Natd:DList Natx:DList Naty:DList Nat⊢ a ++ b = b ++ a
```

