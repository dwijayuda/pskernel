<a id="quotients"></a>

# ProofScript — 4.5. Quotients

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functions, propositions, universes, inductives and quotients retain their Lean meaning. A proof is an inhabitant of a proposition; Boolean truth is not the same object. Parameters may determine later parameter types. Universe levels cannot be approximated as machine integer ranks. Inductive constructors require the native positivity, universe, parameter and index checks. Quotient eliminators must respect their relation, rather than use runtime object identity.

**Compiler and coverage boundary.** Use exact declared core rules and axiom policies. Library names and hash matches alone cannot authorize primitive reductions. Soundness and exact acceptance equivalence are distinct obligations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Type-System/Quotients/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Type-System/Quotients/index.html). Source Git blob: `f6bdb20086cef8eb11e177ee73cb6ce21490486a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next"></a>
<a id="docstring-section-Fields-next-next"></a>

---

## 4.5. Quotients

<a id="--tech-term-Quotient-types"></a>
*Quotient types* allow a new type to be formed by decreasing the granularity of an existing type's [propositional equality](../../Basic-Propositions/Propositional-Equality/index.md#--tech-term-Propositional-equality). In particular, given a type A and an equivalence relation \sim, the quotient A / \sim contains the same elements as A, but every pair of elements that are related by \sim are considered equal. Equality is respected universally; nothing in Lean's logic can observe any difference between two equal terms. Thus, quotient types provide a way to build an impenetrable abstraction barrier. In particular, all functions from a quotient type must prove that they respect the equivalence relation.

<a id="Quotient"></a>

**def**

```text
Quotient.{u} {α : Sort u} (s : Setoid α) : Sort u
```

Quotient types coarsen the propositional equality for a type so that terms related by some equivalence relation are considered equal. The equivalence relation is given by an instance of `Setoid`.

Set-theoretically, `Quotient s` can seen as the set of equivalence classes of `α` modulo the `Setoid` instance's relation `s.r`. Functions from `Quotient s` must prove that they respect `s.r`: to define a function `f : Quotient s → β`, it is necessary to provide `f' : α → β` and prove that for all `x : α` and `y : α`, `s.r x y → f' x = f' y`. `Quotient.lift` implements this operation.

The key quotient operators are:

- `Quotient.mk` places elements of the underlying type `α` into the quotient.
- `Quotient.lift` allows the definition of functions from the quotient to some other type.
- `Quotient.sound` asserts the equality of elements related by `r`
- `Quotient.ind` is used to write proofs about quotients by assuming that all elements are constructed with `Quotient.mk`.

`Quotient` is built on top of the primitive quotient type `Quot`, which does not require a proof that the relation is an equivalence relation. `Quotient` should be used instead of `Quot` for relations that actually are equivalence relations.

A proof that two elements of the underlying type are related by the equivalence relation is sufficient to prove that they are equal in the `Quotient`. However, [definitional equality](../index.md#--tech-term-definitional-equality) is unaffected by the use of `Quotient`: two elements in the quotient are definitionally equal if and only if they are definitionally equal in the underlying type.

Quotient types are not widely used in programming. However, they occur regularly in mathematics:

  Integers

The integers are traditionally defined as a pair of natural numbers (n, k) that encodes the integer n - k. In this encoding, two integers (n_1, k_1) and (n_2, k_2) are equal if n_1 + k_2 = n_2 + k_1.

  Rational Numbers

The number \frac{n}{d} can be encoded as the pair (n, d), where d \neq 0. Two rational numbers \frac{n_1}{d_1} and \frac{n_2}{d_2} are equal if n_1 d_2 = n_2 d_1.

  Real Numbers

The real numbers can be represented as a Cauchy sequence, but this encoding is not unique. Using a quotient type, two Cauchy sequences can be made equal when their difference converges to zero.

  Finite Sets

Finite sets can be represented as lists of elements. With a quotient types, two finite sets can be made equal if they contain the same elements; this definition does not impose any requirements (such as decidable equality or an ordering relation) on the type of elements.

One alternative to quotient types would be to reason directly about the equivalence classes introduced by the relation. The downside of this approach is that it does not allow *computation*: in addition to knowing *that* there is an integer that is the sum of 5 and 8, it is useful for 5 + 8 = 13 to not be a theorem that requires proof. Defining functions out of sets of equivalence classes relies on non-computational classical reasoning principles, while functions from quotient types are ordinary computational functions that additionally respect an equivalence relation.

<a id="quotient-alternatives"></a>
### 4.5.1. Alternatives to Quotient Types

While `Quotient` is a convenient way to form quotients with reasonable computational properties, it is often possible to define quotients in other ways.

In general, a type Q is said to be the quotient of A by an equivalence relation \sim if it respects the universal property of quotients: there is a function q:A\to Q with the property that q(a)=q(b) if and only if a\sim b for all a and b in A.

Quotients formed with `Quotient` have this property up to [propositional equality](../../Basic-Propositions/Propositional-Equality/index.md#--tech-term-Propositional-equality): elements of A that are related by \sim are equal, so they cannot be distinguished. However, members of the same equivalence class are not necessarily [definitionally equal](../index.md#--tech-term-definitional-equality) in the quotient.

Quotients may also be implemented by designating a single representative of each equivalence class in A itself, and then defining Q as pair of elements in A with proofs that they are such a canonical representative. Together with a function that maps each a in A to its canonical representative, Q is a quotient of A. Due to [proof irrelevance](../index.md#--tech-term-proof-irrelevance), representatives in Q of the same equivalence class are [definitionally equal](../index.md#--tech-term-definitional-equality).

Such a manually implemented quotient Q can be easier to work with than `Quotient`. In particular, because each equivalence class is represented by its single canonical representative, there's no need to prove that functions from the quotient respect the equivalence relation. It can also have better computational properties due to the fact that the computations give normalized values (in contrast, elements of `Quotient` can be represented in multiple ways). Finally, because the manually implemented quotient is an [inductive type](../Inductive-Types/index.md#--tech-term-Inductive-types), it can be used in contexts where other kinds of types cannot, such as when defining a [nested inductive type](../Inductive-Types/index.md#nested-inductive-types). However, not all quotients can be manually implemented.

<a id="Manually-Quotiented-Integers"></a>
Manually Quotiented Integers 

When implemented as pairs of `Nat`s, each equivalence class according to the desired equality for integers has a canonical representative in which at least one of the `Nat`s is zero. This can be represented as a Lean structure:
<a id="Z-_LPAR_in-Manually-Quotiented-Integers_RPAR_"></a>
<a id="Z___a-_LPAR_in-Manually-Quotiented-Integers_RPAR_"></a>
<a id="Z___b-_LPAR_in-Manually-Quotiented-Integers_RPAR_"></a>
<a id="Z___canonical-_LPAR_in-Manually-Quotiented-Integers_RPAR_"></a>


```proofscript
structure Z where
  a : Nat
  b : Nat
  canonical : a = 0 ∨ b = 0
```

Due to [proof irrelevance](../index.md#--tech-term-proof-irrelevance), every value of this structure type that represents the same integer is *already* equal. Constructing a `Z` can be made more convenient with a wrapper that uses the fact that subtraction of natural numbers truncates at zero to automate the construction of the proof:
<a id="Z___mk___-_LPAR_in-Manually-Quotiented-Integers_RPAR_"></a>


```proofscript
def Z.mk' (n k : Nat) : Z where
  a := n - k
  b := k - n
  canonical := by omega
```

This construction respects the equality demanded of integers:
<a id="Z_mk____respects_eq-_LPAR_in-Manually-Quotiented-Integers_RPAR_"></a>


```proofscript
theorem Z_mk'_respects_eq :
    (Z.mk' n k = Z.mk' n' k') ↔ (n + k' = n' + k) := by
  simp [Z.mk']
  omega
```

To use this type in examples, it's convenient to have `Neg`, `OfNat`, and `ToString` instances. These instances make it easier to read or write examples.

```proofscript
instance : Neg Z where
  neg n := Z.mk' n.b n.a

instance : OfNat Z n where
  ofNat := Z.mk' n 0

instance : ToString Z where
  toString n :=
    if n.a = 0 then
      if n.b = 0 then "0"
      else s!"-{n.b}"
    else toString n.a
```

```proofscript
#eval (5 : Z)
```

```lean
5
```

```proofscript
#eval (-5 : Z)
```

```lean
-5
```

Addition is addition of the underlying `Nat`s:

```proofscript
instance : Add Z where
  add n k := Z.mk' (n.a + k.a) (n.b + k.b)
```

```proofscript
#eval (-5 + 22: Z)
```

```lean
17
```

Because each equivalence class is uniquely represented, there's no need to write a proof that these functions from `Z` respect the equivalence relation. However, in practice, the [API for quotients](index.md#quotient-api) should be implemented for manually-constructed quotients and proved to respect the universal property.

<a id="Built-In-Integers-as-Quotients"></a>
Built-In Integers as Quotients 

Lean's built-in integer type `Int` satisfies the universal property of quotients, and can thus be thought of as a quotient of pairs of `Nat`s. The canonical representative of each equivalence class can be computed via comparison and subtraction:This `toInt` function is called `Int.subNatNat` in the standard library.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="toInt-_LPAR_in-Built-In-Integers-as-Quotients_RPAR_"></a>


```proofscript
function toInt (n k : Nat) : Int :=
  if n < k then - (k - n : Nat)
  else if n = k then 0
  else (n - k : Nat)
```

It satisfies the universal property. Two pairs of `Nat`s represent the same integer if and only if `toInt` computes the same `Int` for both pairs:
<a id="toInt_sound-_LPAR_in-Built-In-Integers-as-Quotients_RPAR_"></a>


```proofscript
theorem toInt_sound :
    n + k' = k + n' ↔
    toInt n k = toInt n' k' := by
  simp only [toInt]
  split <;> split <;> omega
```

<a id="setoids"></a>
### 4.5.2. Setoids

Quotient types are built on setoids. A 
<a id="--tech-term-setoid"></a>
*setoid* is a type paired with a distinguished equivalence relation. Unlike a quotient type, the abstraction barrier is not enforced, and proof automation designed around equality cannot be used with the setoid's equivalence relation. Setoids are useful on their own, in addition to being a building block for quotient types.

<a id="Setoid___mk"></a>

**type class**

```text
Setoid.{u} (α : Sort u) : Sort (max 1 u)
```

A setoid is a type with a distinguished equivalence relation, denoted `≈`.

The `Quotient` type constructor requires a `Setoid` instance.

**Instance Constructor**

```text
Setoid.mk.{u}
```

**Methods**

```text
r : α → α → Prop
```

`x ≈ y` is the distinguished equivalence relation of a setoid.

```text
iseqv : Equivalence Setoid.r
```

The relation `x ≈ y` is an equivalence relation.

<a id="Setoid___refl"></a>

**theorem**

```text
Setoid.refl.{u} {α : Sort u} [Setoid α] (a : α) : a ≈ a
```

A setoid's equivalence relation is reflexive.

<a id="Setoid___symm"></a>

**theorem**

```text
Setoid.symm.{u} {α : Sort u} [Setoid α] {a b : α} (hab : a ≈ b) : b ≈ a
```

A setoid's equivalence relation is symmetric.

<a id="Setoid___trans"></a>

**theorem**

```text
Setoid.trans.{u} {α : Sort u} [Setoid α] {a b c : α} (hab : a ≈ b)
  (hbc : b ≈ c) : a ≈ c
```

A setoid's equivalence relation is transitive.

<a id="equivalence-relations"></a>
### 4.5.3. Equivalence Relations

An 
<a id="--tech-term-equivalence-relation"></a>
*equivalence relation* is a relation that is reflexive, symmetric, and transitive.

<a id="term-next-next-next"></a>

**syntax**

**Equivalence Relations**

Equivalence according to some canonical equivalence relation for a type is written using `≈`, which is overloaded using the [type class](../../Type-Classes/index.md#--tech-term-type-class) `HasEquiv`.

<a id="_FLQQ_term______FLQQ_"></a>

```ebnf
term ::= ...
    | term ≈ term
```

<a id="HasEquiv___mk"></a>

**type class**

```text
HasEquiv.{u, v} (α : Sort u) : Sort (max u (v + 1))
```

`HasEquiv α` is the typeclass which supports the notation `x ≈ y` where `x y : α`.

**Instance Constructor**

```text
HasEquiv.mk.{u, v}
```

**Methods**

```text
Equiv : α → α → Sort v
```

`x ≈ y` says that `x` and `y` are equivalent. Because this is a typeclass, the notion of equivalence is type-dependent.

Conventions for notations in identifiers:

- The recommended spelling of `≈` in identifiers is `equiv`.

The fact that a relation `r` is actually an equivalence relation is stated `Equivalence r`.

<a id="Equivalence___mk"></a>

**structure**

```text
Equivalence.{u} {α : Sort u} (r : α → α → Prop) : Prop
```

An equivalence relation `r : α → α → Prop` is a relation that is

- reflexive: `r x x`,
- symmetric: `r x y` implies `r y x`, and
- transitive: `r x y` and `r y z` implies `r x z`.

Equality is an equivalence relation, and equivalence relations share many of the properties of equality.

**Constructor**

```text
Equivalence.mk.{u}
```

**Fields**

```text
refl : ∀ (x : α), r x x
```

An equivalence relation is reflexive: `r x x`

```text
symm : ∀ {x y : α}, r x y → r y x
```

An equivalence relation is symmetric: `r x y` implies `r y x`

```text
trans : ∀ {x y z : α}, r x y → r y z → r x z
```

An equivalence relation is transitive: `r x y` and `r y z` implies `r x z`

Every `Setoid` instance leads to a corresponding `HasEquiv` instance.

<a id="quotient-api"></a>
### 4.5.4. Quotient API

The quotient API relies on a pre-existing `Setoid` instance.

<a id="quotient-intro"></a>
#### 4.5.4.1. Introducing Quotients

The type `Quotient` expects an instance of `Setoid` as an ordinary parameter, rather than as an [instance implicit](../../Type-Classes/index.md#--tech-term-instance-implicit) parameter. This helps ensure that the quotient uses the intended equivalence relation. The instance can be provided either by naming the instance or by using `inferInstance`.

A value in the quotient is a value from the setoid's underlying type, wrapped in `Quotient.mk`.

<a id="Quotient___mk"></a>

**def**

```text
Quotient.mk.{u} {α : Sort u} (s : Setoid α) (a : α) : Quotient s
```

Places an element of a type into the quotient that equates terms according to an equivalence relation.

The setoid instance is provided explicitly. `Quotient.mk'` uses instance synthesis instead.

Given `v : α`, `Quotient.mk s v : Quotient s` is like `v`, except all observations of `v`'s value must respect `s.r`. `Quotient.lift` allows values in a quotient to be mapped to other types, so long as the mapping respects `s.r`.

<a id="Quotient___mk___"></a>

**def**

```text
Quotient.mk'.{u} {α : Sort u} [s : Setoid α] (a : α) : Quotient s
```

Places an element of a type into the quotient that equates terms according to an equivalence relation.

The equivalence relation is found by synthesizing a `Setoid` instance. `Quotient.mk` instead expects the instance to be provided explicitly.

Given `v : α`, `Quotient.mk' v : Quotient s` is like `v`, except all observations of `v`'s value must respect `s.r`. `Quotient.lift` allows values in a quotient to be mapped to other types, so long as the mapping respects `s.r`.

<a id="The-Integers-as-a-Quotient-Type"></a>
The Integers as a Quotient Type 

The integers, defined as pairs of natural numbers where the represented integer is the difference of the two numbers, can be represented via a quotient type. This representation is not unique: both `(4, 7)` and `(1, 4)` represent `-3`.

Two encoded integers should be considered equal when they are related by `Z.eq`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Z___-_LPAR_in-The-Integers-as-a-Quotient-Type_RPAR_"></a>
<a id="Z___eq-_LPAR_in-The-Integers-as-a-Quotient-Type_RPAR_"></a>


```proofscript
const Z' : Type := Nat × Nat

function Z.eq (n k : Z') : Prop :=
  n.1 + k.2 = n.2 + k.1
```

This relation is an equivalence relation:
<a id="Z___eq___eqv-_LPAR_in-The-Integers-as-a-Quotient-Type_RPAR_"></a>


```proofscript
def Z.eq.eqv : Equivalence Z.eq where
  refl := by
    intro (x, y)
    simp +arith [eq]
  symm := by
    intro (x, y) (x', y') heq
    simp_all only [eq]
    omega
  trans := by
    intro (x, y) (x', y') (x'', y'')
    intro heq1 heq2
    simp_all only [eq]
    omega
```

Thus, it can be used as a `Setoid`:
<a id="Z___instSetoid-_LPAR_in-The-Integers-as-a-Quotient-Type_RPAR_"></a>


```proofscript
instance Z.instSetoid : Setoid Z' where
  r := Z.eq
  iseqv := Z.eq.eqv
```

The type `Z` of integers is then the quotient of `Z'` by the `Setoid` instance:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Z-_LPAR_in-The-Integers-as-a-Quotient-Type_RPAR_"></a>


```proofscript
const Z : Type := Quotient Z.instSetoid
```

The helper `Z.mk` makes it simpler to create integers without worrying about the choice of `Setoid` instance:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Z___mk-_LPAR_in-The-Integers-as-a-Quotient-Type_RPAR_"></a>


```proofscript
function Z.mk (n : Z') : Z := Quotient.mk _ n
```

However, numeric literals are even more convenient. An `OfNat` instance allows numeric literals to be used for integers:

```proofscript
instance : OfNat Z n where
  ofNat := Z.mk (n, 0)
```

<a id="quotient-elim"></a>
#### 4.5.4.2. Eliminating Quotients

Functions from quotients can be defined by proving that a function from the underlying type respects the quotient's equivalence relation. This is accomplished using `Quotient.lift` or its binary counterpart `Quotient.lift₂`. The variants `Quotient.liftOn` and `Quotient.liftOn₂` place the quotient parameter first rather than last in the parameter list.

<a id="Quotient___lift"></a>

**def**

```text
Quotient.lift.{u, v} {α : Sort u} {β : Sort v} {s : Setoid α}
  (f : α → β) : (∀ (a b : α), a ≈ b → f a = f b) → Quotient s → β
```

Lifts a function from an underlying type to a function on a quotient, requiring that it respects the quotient's equivalence relation.

Given `s : Setoid α` and a quotient `Quotient s`, applying a function `f : α → β` requires a proof `h` that `f` respects the equivalence relation `s.r`. In this case, the function `Quotient.lift f h : Quotient s → β` computes the same values as `f`.

`Quotient.liftOn` is a version of this operation that takes the quotient value as its first explicit parameter.

<a id="Quotient___liftOn"></a>

**def**

```text
Quotient.liftOn.{u, v} {α : Sort u} {β : Sort v} {s : Setoid α}
  (q : Quotient s) (f : α → β) (c : ∀ (a b : α), a ≈ b → f a = f b) : β
```

Lifts a function from an underlying type to a function on a quotient, requiring that it respects the quotient's equivalence relation.

Given `s : Setoid α` and a quotient value `q : Quotient s`, applying a function `f : α → β` requires a proof `c` that `f` respects the equivalence relation `s.r`. In this case, the term `Quotient.liftOn q f h : β` reduces to the result of applying `f` to the underlying `α` value.

`Quotient.lift` is a version of this operation that takes the quotient value last, rather than first.

<a id="Quotient___lift___"></a>

**def**

```text
Quotient.lift₂.{uA, uB, uC} {α : Sort uA} {β : Sort uB} {φ : Sort uC}
  {s₁ : Setoid α} {s₂ : Setoid β} (f : α → β → φ)
  (c :
    ∀ (a₁ : α) (b₁ : β) (a₂ : α) (b₂ : β),
      a₁ ≈ a₂ → b₁ ≈ b₂ → f a₁ b₁ = f a₂ b₂)
  (q₁ : Quotient s₁) (q₂ : Quotient s₂) : φ
```

Lifts a binary function from the underlying types to a binary function on quotients. The function must respect both quotients' equivalence relations.

`Quotient.lift` is a version of this operation for unary functions. `Quotient.liftOn₂` is a version that take the quotient parameters first.

<a id="Quotient___liftOn___"></a>

**def**

```text
Quotient.liftOn₂.{uA, uB, uC} {α : Sort uA} {β : Sort uB} {φ : Sort uC}
  {s₁ : Setoid α} {s₂ : Setoid β} (q₁ : Quotient s₁) (q₂ : Quotient s₂)
  (f : α → β → φ)
  (c :
    ∀ (a₁ : α) (b₁ : β) (a₂ : α) (b₂ : β),
      a₁ ≈ a₂ → b₁ ≈ b₂ → f a₁ b₁ = f a₂ b₂) :
  φ
```

Lifts a binary function from the underlying types to a binary function on quotients. The function must respect both quotients' equivalence relations.

`Quotient.liftOn` is a version of this operation for unary functions. `Quotient.lift₂` is a version that take the quotient parameters last.

<a id="Integer-Negation-and-Addition"></a>
Integer Negation and Addition 

Given the encoding `Z` of integers as a quotient of pairs of natural numbers, negation can be implemented by swapping the first and second projections:
<a id="neg___-_LPAR_in-Integer-Negation-and-Addition_RPAR_"></a>


```proofscript
def neg' : Z' → Z
  | (x, y) => .mk (y, x)
```

This can be transformed into a function from `Z` to `Z` by proving that negation respects the equivalence relation:

```proofscript
instance : Neg Z where
  neg :=
    Quotient.lift neg' <| by
      intro n k equiv
      cases n; cases k
      apply Quotient.sound
      simp [· ≈ ·, instHasEquivOfSetoid, Setoid.r, Z.eq] at *
      grind
```

Similarly, `Quotient.lift₂` is useful for defining binary functions from a quotient type. Addition is defined point-wise:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="add___-_LPAR_in-Integer-Negation-and-Addition_RPAR_"></a>


```proofscript
function add' (n k : Nat × Nat) : Z :=
  .mk (n.1 + k.1, n.2 + k.2)
```

Lifting it to the quotient requires a proof that addition respects the equivalence relation:

```proofscript
instance : Add Z where
  add (n : Z) :=
    n.lift₂ add' <| by
      intro n k n' k'
      intro heq heq'
      apply Quotient.sound
      cases n; cases k; cases n'; cases k'
      simp_all only [· ≈ ·, instHasEquivOfSetoid, Setoid.r, Z.eq]
      grind
```

When the function's result type is a [subsingleton](../Inductive-Types/index.md#--tech-term-subsingleton), `Quotient.recOnSubsingleton` or `Quotient.recOnSubsingleton₂` can be used to define the function. Because all elements of a subsingleton are equal, such a function automatically respects the equivalence relation, so there is no proof obligation.

<a id="Quotient___recOnSubsingleton"></a>

**def**

```text
Quotient.recOnSubsingleton.{u, v} {α : Sort u} {s : Setoid α}
  {motive : Quotient s → Sort v}
  [h : ∀ (a : α), Subsingleton (motive (Quotient.mk s a))]
  (q : Quotient s) (f : (a : α) → motive (Quotient.mk s a)) : motive q
```

An alternative recursion or induction principle for quotients that can be used when the target type is a subsingleton, in which all elements are equal.

In these cases, the proof that the function respects the quotient's equivalence relation is trivial, so any function can be lifted.

`Quotient.rec` does not assume that the target type is a subsingleton.

<a id="Quotient___recOnSubsingleton___"></a>

**def**

```text
Quotient.recOnSubsingleton₂.{uA, uB, uC} {α : Sort uA} {β : Sort uB}
  {s₁ : Setoid α} {s₂ : Setoid β}
  {motive : Quotient s₁ → Quotient s₂ → Sort uC}
  [s :
    ∀ (a : α) (b : β),
      Subsingleton (motive (Quotient.mk s₁ a) (Quotient.mk s₂ b))]
  (q₁ : Quotient s₁) (q₂ : Quotient s₂)
  (g :
    (a : α) → (b : β) → motive (Quotient.mk s₁ a) (Quotient.mk s₂ b)) :
  motive q₁ q₂
```

An alternative induction or recursion operator for defining binary operations on quotients that can be used when the target type is a subsingleton.

In these cases, the proof that the function respects the quotient's equivalence relation is trivial, so any function can be lifted.

<a id="quotient-proofs"></a>
#### 4.5.4.3. Proofs About Quotients

The fundamental tools for proving properties of elements of quotient types are the soundness axiom and the induction principle. The soundness axiom states that if two elements of the underlying type are related by the quotient's equivalence relation, then they are equal in the quotient type. The induction principle follows the structure of recursors for inductive types: in order to prove that a predicate holds for all elements of a quotient type, it suffices to prove that it holds for an application of `Quotient.mk` to each element of the underlying type. Because `Quotient` is not an [inductive type](../Inductive-Types/index.md#--tech-term-Inductive-types), tactics such as `cases` and `induction` require that `Quotient.ind` be specified explicitly with the `using` modifier.

<a id="Quotient___sound"></a>

**theorem**

```text
Quotient.sound.{u} {α : Sort u} {s : Setoid α} {a b : α} :
  a ≈ b → Quotient.mk s a = Quotient.mk s b
```

The **quotient axiom**, which asserts the equality of elements related in the setoid.

Because `Quotient` is built on a lower-level type `Quot`, `Quotient.sound` is implemented as a theorem. It is derived from `Quot.sound`, the soundness axiom for the lower-level quotient type `Quot`.

<a id="Quotient___ind"></a>

**theorem**

```text
Quotient.ind.{u} {α : Sort u} {s : Setoid α}
  {motive : Quotient s → Prop} :
  (∀ (a : α), motive (Quotient.mk s a)) → ∀ (q : Quotient s), motive q
```

A reasoning principle for quotients that allows proofs about quotients to assume that all values are constructed with `Quotient.mk`.

<a id="Proofs-About-Quotients"></a>
Proofs About Quotients 

Given the definition of integers as a quotient type from the prior examples, `Quotient.ind` and `Quotient.sound` can be used to prove that negation is an additive inverse. First, `Quotient.ind` is used to replace instances of `n` with applications of `Quotient.mk`. Having done so, the left side of the equality becomes definitionally equal to a single application of `Quotient.mk`, via unfolding definitions and the computation rule for `Quotient.lift`. This makes `Quotient.sound` applicable, which yields a new goal: to show that both sides are related by the equivalence relation. This is provable using `simp_arith`.
<a id="Z___add_neg_inverse-_LPAR_in-Proofs-About-Quotients_RPAR_"></a>


```proofscript
theorem Z.add_neg_inverse (n : Z) : n  + (-n) = 0 := by
  cases n using Quotient.ind
  apply Quotient.sound
  simp +arith [· ≈ ·, instHasEquivOfSetoid, Setoid.r, eq]
```

For more specialized use cases, `Quotient.rec`, `Quotient.recOn`, and `Quotient.hrecOn` can be used to define dependent functions from a quotient type to a type in any other universe. Stating that a dependent function respects the quotient's equivalence relation requires a means of dealing with the fact that the dependent result type is instantiated with different values from the quotient on each side of the equality. `Quotient.rec` and `Quotient.recOn` use the `Quotient.sound` to equate the related elements, inserting the appropriate cast into the statement of equality, while `Quotient.hrecOn` uses heterogeneous equality.

<a id="Quotient___rec"></a>

**def**

```text
Quotient.rec.{u, v} {α : Sort u} {s : Setoid α}
  {motive : Quotient s → Sort v}
  (f : (a : α) → motive (Quotient.mk s a))
  (h : ∀ (a b : α) (p : a ≈ b), ⋯ ▸ f a = f b) (q : Quotient s) :
  motive q
```

A dependent recursion principle for `Quotient`. It is analogous to the [recursor](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=recursors) for a structure, and can be used when the resulting type is not necessarily a proposition.

While it is very general, this recursor can be tricky to use. The following simpler alternatives may be easier to use:

- `Quotient.lift` is useful for defining non-dependent functions.
- `Quotient.ind` is useful for proving theorems about quotients.
- `Quotient.recOnSubsingleton` can be used whenever the target type is a `Subsingleton`.
- `Quotient.hrecOn` uses heterogeneous equality instead of rewriting with `Quotient.sound`.

`Quotient.recOn` is a version of this recursor that takes the quotient parameter first.

<a id="Quotient___recOn"></a>

**def**

```text
Quotient.recOn.{u, v} {α : Sort u} {s : Setoid α}
  {motive : Quotient s → Sort v} (q : Quotient s)
  (f : (a : α) → motive (Quotient.mk s a))
  (h : ∀ (a b : α) (p : a ≈ b), ⋯ ▸ f a = f b) : motive q
```

A dependent recursion principle for `Quotient`. It is analogous to the [recursor](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=recursors) for a structure, and can be used when the resulting type is not necessarily a proposition.

While it is very general, this recursor can be tricky to use. The following simpler alternatives may be easier to use:

- `Quotient.lift` is useful for defining non-dependent functions.
- `Quotient.ind` is useful for proving theorems about quotients.
- `Quotient.recOnSubsingleton` can be used whenever the target type is a `Subsingleton`.
- `Quotient.hrecOn` uses heterogeneous equality instead of rewriting with `Quotient.sound`.

`Quotient.rec` is a version of this recursor that takes the quotient parameter last.

<a id="Quotient___hrecOn"></a>

**def**

```text
Quotient.hrecOn.{u, v} {α : Sort u} {s : Setoid α}
  {motive : Quotient s → Sort v} (q : Quotient s)
  (f : (a : α) → motive (Quotient.mk s a))
  (c : ∀ (a b : α), a ≈ b → f a ≍ f b) : motive q
```

A dependent recursion principle for `Quotient` that uses [heterogeneous equality](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=HEq), analogous to a [recursor](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=recursors) for a structure.

`Quotient.recOn` is a version of this recursor that uses `Eq` instead of `HEq`.

If two elements of a type are equal in a quotient, then they are related by the setoid's equivalence relation. This property is called `Quotient.exact`.

<a id="Quotient___exact"></a>

**theorem**

```text
Quotient.exact.{u} {α : Sort u} {s : Setoid α} {a b : α} :
  Quotient.mk s a = Quotient.mk s b → a ≈ b
```

If two values are equal in a quotient, then they are related by its equivalence relation.

<a id="quotient-model"></a>
### 4.5.5. Logical Model

Like functions and universes, quotient types are a built-in feature of Lean's type system. However, the underlying primitives are based on the somewhat simpler `Quot` type rather than on `Quotient`, and `Quotient` is defined in terms of `Quot`. The primary difference is that `Quot` is based on an arbitrary relation, rather than a `Setoid` instance. The provided relation need not be an equivalence relation; the rules that govern `Quot` and `Eq` automatically extend the provided relation into its reflexive, transitive, symmetric closure. When the relation is already an equivalence relation, `Quotient` should be used instead of `Quot` so Lean can make use of the fact that the relation is an equivalence relation.

The fundamental quotient type API consists of `Quot`, `Quot.mk`, `Quot.lift`, `Quot.ind`, and `Quot.sound`. These are used in the same way as their `Quotient`-based counterparts.

<a id="Quot"></a>

**primitive**

```text
Quot.{u} {α : Sort u} (r : α → α → Prop) : Sort u
```

Low-level quotient types. Quotient types coarsen the propositional equality for a type `α`, so that terms related by some relation `r` are considered equal in `Quot r`.

Set-theoretically, `Quot r` can be seen as the set of equivalence classes of `α` modulo `r`. Functions from `Quot r` must prove that they respect `r`: to define a function `f : Quot r → β`, it is necessary to provide `f' : α → β` and prove that for all `x : α` and `y : α`, `r x y → f' x = f' y`.

`Quot` is a built-in primitive:

- `Quot.mk` places elements of the underlying type `α` into the quotient.
- `Quot.lift` allows the definition of functions from the quotient to some other type.
- `Quot.sound` asserts the equality of elements related by `r`.
- `Quot.ind` is used to write proofs about quotients by assuming that all elements are constructed with `Quot.mk`.

The relation `r` is not required to be an equivalence relation; the resulting quotient type's equality extends `r` to an equivalence as a consequence of the rules for equality and quotients. When `r` is an equivalence relation, it can be more convenient to use the higher-level type `Quotient`.

<a id="Quot___mk"></a>

**primitive**

```text
Quot.mk.{u} {α : Sort u} (r : α → α → Prop) (a : α) : Quot r
```

Places an element of a type into the quotient that equates terms according to the provided relation.

Given `v : α` and relation `r : α → α → Prop`, `Quot.mk r v : Quot r` is like `v`, except all observations of `v`'s value must respect `r`.

`Quot.mk` is a built-in primitive:

- `Quot` is the built-in quotient type.
- `Quot.lift` allows the definition of functions from the quotient to some other type.
- `Quot.sound` asserts the equality of elements related by `r`.
- `Quot.ind` is used to write proofs about quotients by assuming that all elements are constructed with `Quot.mk`.

<a id="Quot___lift"></a>

**primitive**

```text
Quot.lift.{u, v} {α : Sort u} {r : α → α → Prop} {β : Sort v}
  (f : α → β) (a : ∀ (a b : α), r a b → f a = f b) : Quot r → β
```

Lifts a function from an underlying type to a function on a quotient, requiring that it respects the quotient's relation.

Given a relation `r : α → α → Prop` and a quotient `Quot r`, applying a function `f : α → β` requires a proof `a` that `f` respects `r`. In this case, `Quot.lift f a : Quot r → β` computes the same values as `f`.

Lean's type theory includes a [definitional reduction](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=type-theory) from `Quot.lift f h (Quot.mk r v)` to `f v`.

`Quot.lift` is a built-in primitive:

- `Quot` is the built-in quotient type.
- `Quot.mk` places elements of the underlying type `α` into the quotient.
- `Quot.sound` asserts the equality of elements related by `r`
- `Quot.ind` is used to write proofs about quotients by assuming that all elements are constructed with `Quot.mk`; it is analogous to the [recursor](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=recursors) for a structure.

<a id="Quot___ind"></a>

**primitive**

```text
Quot.ind.{u} {α : Sort u} {r : α → α → Prop} {β : Quot r → Prop}
  (mk : ∀ (a : α), β (Quot.mk r a)) (q : Quot r) : β q
```

A reasoning principle for quotients that allows proofs about quotients to assume that all values are constructed with `Quot.mk`.

`Quot.rec` is analogous to the [recursor](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=recursors) for a structure, and can be used when the resulting type is not necessarily a proposition.

`Quot.ind` is a built-in primitive:

- `Quot` is the built-in quotient type.
- `Quot.mk` places elements of the underlying type `α` into the quotient.
- `Quot.lift` allows the definition of functions from the quotient to some other type.
- `Quot.sound` asserts the equality of elements related by `r`.

<a id="Quot___sound"></a>

**axiom**

```text
Quot.sound.{u} {α : Sort u} {r : α → α → Prop} {a b : α} :
  r a b → Quot.mk r a = Quot.mk r b
```

The **quotient axiom**, which asserts the equality of elements related by the quotient's relation.

The relation `r` does not need to be an equivalence relation to use this axiom. When `r` is not an equivalence relation, the quotient is with respect to the equivalence relation generated by `r`.

`Quot.sound` is part of the built-in primitive quotient type:

- `Quot` is the built-in quotient type.
- `Quot.mk` places elements of the underlying type `α` into the quotient.
- `Quot.lift` allows the definition of functions from the quotient to some other type.
- `Quot.ind` is used to write proofs about quotients by assuming that all elements are constructed with `Quot.mk`; it is analogous to the [recursor](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=recursors) for a structure.

[Quotient types](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=quotients) are described in more detail in the Lean Language Reference.

<a id="quotient-reduction"></a>
#### 4.5.5.1. Quotient Reduction

In addition to the above constants, Lean's kernel contains a reduction rule for `Quot.lift` that causes it to reduce when used with `Quot.mk`, analogous to [ι-reduction](../Inductive-Types/index.md#--tech-term-___-reduction) for inductive types. Given a relation `r` over `α`, a function `f` from `α` to `β`, and a proof `resp` that `f` respects `r`, the term `Quot.lift f resp (Quot.mk r x)` is [definitionally equal](../index.md#--tech-term-definitional-equality) to `f x`.

```proofscript
variable
  (r : α → α → Prop)
  (f : α → β)
  (ok : ∀ x y, r x y → f x = f y)
  (x : α)

example : Quot.lift f ok (Quot.mk r x) = f x := rfl
```

<a id="quotients-nested-inductives"></a>
#### 4.5.5.2. Quotients and Inductive Types

Because `Quot` is not an inductive type, types implemented as quotients may not occur around [nested occurrences](../Inductive-Types/index.md#nested-inductive-types) in inductive type declarations. These types declarations must be rewritten to remove the nested quotient, which can often be done by defining a quotient-free version and then separately defining an equivalence relation that implements the desired equality relation.

<a id="Nested-Inductive-Types-and-Quotients"></a>
Nested Inductive Types and Quotients 

The nested inductive type of rose trees nests the recursive occurrence of `RoseTree` under `List`:
<a id="RoseTree-_LPAR_in-Nested-Inductive-Types-and-Quotients_RPAR_"></a>
<a id="RoseTree___leaf-_LPAR_in-Nested-Inductive-Types-and-Quotients_RPAR_"></a>
<a id="RoseTree___branch-_LPAR_in-Nested-Inductive-Types-and-Quotients_RPAR_"></a>


```proofscript
inductive RoseTree (α : Type u) where
  | leaf : α → RoseTree α
  | branch : List (RoseTree α) → RoseTree α
```

However, taking a quotient of the `List` that identifies all elements in the style of [squash types](index.md#squash-types) causes Lean to reject the declaration:
<a id="SetTree-_LPAR_in-Nested-Inductive-Types-and-Quotients_RPAR_"></a>


```proofscript
inductive SetTree (α : Type u) where
  | leaf : α → SetTree α
  | branch :
    Quot (fun (xs ys : List (SetTree α)) => True) →
    SetTree α
```

```lean
(kernel) arg #2 of 'SetTree.branch' contains a non valid occurrence of the datatypes being declared
```

<a id="The-Lean-Language-Reference--The-Type-System--Quotients--Logical-Model--Low-Level-Quotient-API"></a>
#### 4.5.5.3. Low-Level Quotient API

`Quot.liftOn` is an version of `Quot.lift` that takes the quotient type's value first, by analogy to `Quotient.liftOn`.

<a id="Quot___liftOn"></a>

**def**

```text
Quot.liftOn.{u, v} {α : Sort u} {β : Sort v} {r : α → α → Prop}
  (q : Quot r) (f : α → β) (c : ∀ (a b : α), r a b → f a = f b) : β
```

Lifts a function from an underlying type to a function on a quotient, requiring that it respects the quotient's relation.

Given a relation `r : α → α → Prop` and a quotient's value `q : Quot r`, applying a `f : α → β` requires a proof `c` that `f` respects `r`. In this case, `Quot.liftOn q f h : β` evaluates to the result of applying `f` to the underlying value in `α` from `q`.

`Quot.liftOn` is a version of the built-in primitive `Quot.lift` with its parameters re-ordered.

[Quotient types](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=quotients) are described in more detail in the Lean Language Reference.

Lean also provides convenient elimination from `Quot` into any subsingleton without further proof obligations, along with dependent elimination principles that correspond to those used for `Quotient`.

<a id="Quot___recOnSubsingleton"></a>

**def**

```text
Quot.recOnSubsingleton.{u, v} {α : Sort u} {r : α → α → Prop}
  {motive : Quot r → Sort v}
  [h : ∀ (a : α), Subsingleton (motive (Quot.mk r a))] (q : Quot r)
  (f : (a : α) → motive (Quot.mk r a)) : motive q
```

An alternative induction principle for quotients that can be used when the target type is a subsingleton, in which all elements are equal.

In these cases, the proof that the function respects the quotient's relation is trivial, so any function can be lifted.

`Quot.rec` does not assume that the type is a subsingleton.

<a id="Quot___rec"></a>

**def**

```text
Quot.rec.{u, v} {α : Sort u} {r : α → α → Prop}
  {motive : Quot r → Sort v} (f : (a : α) → motive (Quot.mk r a))
  (h : ∀ (a b : α) (p : r a b), ⋯ ▸ f a = f b) (q : Quot r) : motive q
```

A dependent recursion principle for `Quot`. It is analogous to the [recursor](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=recursors) for a structure, and can be used when the resulting type is not necessarily a proposition.

While it is very general, this recursor can be tricky to use. The following simpler alternatives may be easier to use:

- `Quot.lift` is useful for defining non-dependent functions.
- `Quot.ind` is useful for proving theorems about quotients.
- `Quot.recOnSubsingleton` can be used whenever the target type is a `Subsingleton`.
- `Quot.hrecOn` uses [heterogeneous equality](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=HEq) instead of rewriting with `Quot.sound`.

`Quot.recOn` is a version of this recursor that takes the quotient parameter first.

<a id="Quot___recOn"></a>

**def**

```text
Quot.recOn.{u, v} {α : Sort u} {r : α → α → Prop}
  {motive : Quot r → Sort v} (q : Quot r)
  (f : (a : α) → motive (Quot.mk r a))
  (h : ∀ (a b : α) (p : r a b), ⋯ ▸ f a = f b) : motive q
```

A dependent recursion principle for `Quot` that takes the quotient first. It is analogous to the [recursor](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=recursors) for a structure, and can be used when the resulting type is not necessarily a proposition.

While it is very general, this recursor can be tricky to use. The following simpler alternatives may be easier to use:

- `Quot.lift` is useful for defining non-dependent functions.
- `Quot.ind` is useful for proving theorems about quotients.
- `Quot.recOnSubsingleton` can be used whenever the target type is a `Subsingleton`.
- `Quot.hrecOn` uses [heterogeneous equality](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=HEq) instead of rewriting with `Quot.sound`.

`Quot.rec` is a version of this recursor that takes the quotient parameter last.

<a id="Quot___hrecOn"></a>

**def**

```text
Quot.hrecOn.{u, v} {α : Sort u} {r : α → α → Prop}
  {motive : Quot r → Sort v} (q : Quot r)
  (f : (a : α) → motive (Quot.mk r a))
  (c : ∀ (a b : α), r a b → f a ≍ f b) : motive q
```

A dependent recursion principle for `Quot` that uses [heterogeneous equality](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=HEq), analogous to a [recursor](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=recursors) for a structure.

`Quot.recOn` is a version of this recursor that uses `Eq` instead of `HEq`.

<a id="quotient-funext"></a>
### 4.5.6. Quotients and Function Extensionality

Because Lean's definitional equality includes a computational reduction rule for `Quot.lift`, quotient types are used in the standard library to prove function extensionality, which would need to be an [axiom](../../Axioms/index.md#axioms) otherwise. This is done by first defining a type of functions quotiented by extensional equality, for which extensional equality holds by definition.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="extEq"></a>
<a id="ExtFun"></a>


```proofscript
variable {α : Sort u} {β : α → Sort v}

function extEq (f g : (x : α) → β x) : Prop :=
  ∀ x, f x = g x

function ExtFun (α : Sort u) (β : α → Sort v) :=
  Quot (@extEq α β)
```

Extensional functions can be applied just like ordinary functions. Application respects extensional equality by definition: if applying to functions gives equal results, then applying them gives equal results.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="extApp"></a>


```proofscript
function extApp
    (f : ExtFun α β)
    (x : α) :
    β x :=
  f.lift (· x) fun g g' h => by
    exact h x
```

To show that two functions that are extensionally equal are in fact equal, it suffices to show that the functions that result from extensionally applying the corresponding extensional functions are equal. This is because

```proofscript
extApp (Quot.mk _ f)
```

is definitionally equal to

```proofscript
fun x => (Quot.mk extEq f).lift (· x) (fun _ _ h => h x)
```

which is definitionally equal to `fun x => f x`, which is definitionally equal (by [η-equivalence](../index.md#--tech-term-___-equivalence)) to `f`. A propositional version of the computation rule for `Quot.lift` would not suffice, because the reducible expression occurs in the body of a function and rewriting by an equality in a function would already require function extensionality.

From here, it is enough to show that the extensional versions of the two functions are equal. This is true due to `Quot.sound`: the fact that they are in the quotient's equivalence relation is an assumption. This proof is a much more explicit version of the one in the standard library:
<a id="funext___"></a>


```proofscript
theorem funext'
    {f g : (x : α) → β x}
    (h : ∀ x, f x = g x) :
    f = g := by
  suffices extApp (Quot.mk _ f) = extApp (Quot.mk _ g) by
    unfold extApp at this
    dsimp at this
    exact this
  suffices Quot.mk extEq f = Quot.mk extEq g by
    apply congrArg
    exact this
  apply Quot.sound
  exact h
```

<a id="squash-types"></a>
### 4.5.7. Squash Types

Squash types are a quotient by the relation that relates all elements, transforming it into a [subsingleton](../Inductive-Types/index.md#--tech-term-subsingleton). In other words, if `α` is inhabited, then `Squash α` has a single element, and if `α` is uninhabited, then `Squash α` is also uninhabited. Unlike `Nonempty α`, which is a proposition stating that `α` is inhabited and is thus represented by a dummy value at runtime, `Squash α` is a type that is represented identically to `α`. Because `Squash α` is in the same universe as `α`, it is not subject to the restrictions on computing data from propositions.

<a id="Squash"></a>

**def**

```text
Squash.{u} (α : Sort u) : Sort u
```

The quotient of `α` by the universal relation. The elements of `Squash α` are those of `α`, but all of them are equal and cannot be distinguished.

`Squash α` is a `Subsingleton`: it is empty if `α` is empty, otherwise it has just one element. It is the “universal `Subsingleton`” mapped from `α`.

`Nonempty α` also has these properties. It is a proposition, which means that its elements (i.e. proofs) are erased from compiled code and represented by a dummy value. `Squash α` is a `Type u`, and its representation in compiled code is identical to that of `α`.

Consequently, `Squash.lift` may extract an `α` value into any subsingleton type `β`, while `Nonempty.rec` can only do the same when `β` is a proposition.

`Squash` is defined in terms of `Quotient`, so `Squash` can be used when a `Quotient` argument is expected.

<a id="Squash___mk"></a>

**def**

```text
Squash.mk.{u} {α : Sort u} (x : α) : Squash α
```

Places a value into its squash type, in which it cannot be distinguished from any other.

<a id="Squash___lift"></a>

**def**

```text
Squash.lift.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} [Subsingleton β]
  (s : Squash α) (f : α → β) : β
```

Extracts a squashed value into any subsingleton type.

If `β` is a subsingleton, a function `α → β` cannot distinguish between elements of `α` and thus automatically respects the universal relation that `Squash` quotients with.

<a id="Squash___ind"></a>

**theorem**

```text
Squash.ind.{u} {α : Sort u} {motive : Squash α → Prop}
  (h : ∀ (a : α), motive (Squash.mk a)) (q : Squash α) : motive q
```

A reasoning principle that allows proofs about squashed types to assume that all values are constructed with `Squash.mk`.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`x ≈ y` says that `x` and `y` are equivalent. Because this is a typeclass,
the notion of equivalence is type-dependent. 

Conventions for notations in identifiers:

 * The recommended spelling of `≈` in identifiers is `equiv`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
5
```


### Display 2


```text
-5
```


### Display 3


```text
17
```


### Display 4


```text
Definition `Z.eq.eqv` is a proposition; use `theorem` instead of `def`

Note: This linter can be disabled with `set_option linter.defProp false`
```


### Display 5


```text
(kernel) arg #2 of 'SetTree.branch' contains a non valid occurrence of the datatypes being declared
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
n:Natk:Nat⊢ n - k = 0 ∨ k - n = 0
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
n:Natk:Natn':Natk':Nat⊢ Z.mk' n k = Z.mk' n' k' ↔ n + k' = n' + k
```


### Display 4


```text
n:Natk:Natn':Natk':Nat⊢ n - k = n' - k' ∧ k - n = k' - n' ↔ n + k' = n' + k
```


### Display 5


```text
n:Natk':Natk:Natn':Nat⊢ n + k' = k + n' ↔ toInt n k = toInt n' k'
```


### Display 6


```text
n:Natk':Natk:Natn':Nat⊢ n + k' = k + n' ↔
  (if n < k then -↑(k - n) else if n = k then 0 else ↑(n - k)) =
    if n' < k' then -↑(k' - n') else if n' = k' then 0 else ↑(n' - k')
```


### Display 7


```text
isTruen:Natk':Natk:Natn':Nath✝:n < k⊢ n + k' = k + n' ↔ -↑(k - n) = if n' < k' then -↑(k' - n') else if n' = k' then 0 else ↑(n' - k')isFalsen:Natk':Natk:Natn':Nath✝:¬n < k⊢ n + k' = k + n' ↔ (if n = k then 0 else ↑(n - k)) = if n' < k' then -↑(k' - n') else if n' = k' then 0 else ↑(n' - k')
```


### Display 8


```text
isFalse.isTruen:Natk':Natk:Natn':Nath✝¹:¬n < kh✝:n = k⊢ n + k' = k + n' ↔ 0 = if n' < k' then -↑(k' - n') else if n' = k' then 0 else ↑(n' - k')isFalse.isFalsen:Natk':Natk:Natn':Nath✝¹:¬n < kh✝:¬n = k⊢ n + k' = k + n' ↔ ↑(n - k) = if n' < k' then -↑(k' - n') else if n' = k' then 0 else ↑(n' - k')
```


### Display 9


```text
isTrue.isTruen:Natk':Natk:Natn':Nath✝¹:n < kh✝:n' < k'⊢ n + k' = k + n' ↔ -↑(k - n) = -↑(k' - n')isTrue.isFalsen:Natk':Natk:Natn':Nath✝¹:n < kh✝:¬n' < k'⊢ n + k' = k + n' ↔ -↑(k - n) = if n' = k' then 0 else ↑(n' - k')isFalse.isTruen:Natk':Natk:Natn':Nath✝¹:¬n < kh✝:n = k⊢ n + k' = k + n' ↔ 0 = if n' < k' then -↑(k' - n') else if n' = k' then 0 else ↑(n' - k')isFalse.isFalsen:Natk':Natk:Natn':Nath✝¹:¬n < kh✝:¬n = k⊢ n + k' = k + n' ↔ ↑(n - k) = if n' < k' then -↑(k' - n') else if n' = k' then 0 else ↑(n' - k')
```


### Display 10


```text
⊢ ∀ (x : Z'), eq x x
```


### Display 11


```text
x:Naty:Nat⊢ eq (x, y) (x, y)
```


### Display 12


```text
⊢ ∀ {x y : Z'}, eq x y → eq y x
```


### Display 13


```text
x:Naty:Natx':Naty':Natheq:eq (x, y) (x', y')⊢ eq (x', y') (x, y)
```


### Display 14


```text
x:Naty:Natx':Naty':Natheq:x + y' = y + x'⊢ x' + y = y' + x
```


### Display 15


```text
⊢ ∀ {x y z : Z'}, eq x y → eq y z → eq x z
```


### Display 16


```text
x:Naty:Natx':Naty':Natx'':Naty'':Nat⊢ eq (x, y) (x', y') → eq (x', y') (x'', y'') → eq (x, y) (x'', y'')
```


### Display 17


```text
x:Naty:Natx':Naty':Natx'':Naty'':Natheq1:eq (x, y) (x', y')heq2:eq (x', y') (x'', y'')⊢ eq (x, y) (x'', y'')
```


### Display 18


```text
x:Naty:Natx':Naty':Natx'':Naty'':Natheq1:x + y' = y + x'heq2:x' + y'' = y' + x''⊢ x + y'' = y + x''
```


### Display 19


```text
⊢ ∀ (a b : Z'), a ≈ b → neg' a = neg' b
```


### Display 20


```text
n:Z'k:Z'equiv:n ≈ k⊢ neg' n = neg' k
```


### Display 21


```text
mkk:Z'fst✝:Natsnd✝:Natequiv:(fst✝, snd✝) ≈ k⊢ neg' (fst✝, snd✝) = neg' k
```


### Display 22


```text
mk.mkfst✝¹:Natsnd✝¹:Natfst✝:Natsnd✝:Natequiv:(fst✝¹, snd✝¹) ≈ (fst✝, snd✝)⊢ neg' (fst✝¹, snd✝¹) = neg' (fst✝, snd✝)
```


### Display 23


```text
mk.mkfst✝¹:Natsnd✝¹:Natfst✝:Natsnd✝:Natequiv:(fst✝¹, snd✝¹) ≈ (fst✝, snd✝)⊢ (snd✝¹, fst✝¹) ≈ (snd✝, fst✝)
```


### Display 24


```text
mk.mkfst✝¹:Natsnd✝¹:Natfst✝:Natsnd✝:Natequiv:fst✝¹ + snd✝ = snd✝¹ + fst✝⊢ snd✝¹ + fst✝ = fst✝¹ + snd✝
```


### Display 25


```text
n:Z⊢ ∀ (a₁ : Nat × Nat) (b₁ : Z') (a₂ : Nat × Nat) (b₂ : Z'), a₁ ≈ a₂ → b₁ ≈ b₂ → add' a₁ b₁ = add' a₂ b₂
```


### Display 26


```text
n✝:Zn:Nat × Natk:Z'n':Nat × Natk':Z'⊢ n ≈ n' → k ≈ k' → add' n k = add' n' k'
```


### Display 27


```text
n✝:Zn:Nat × Natk:Z'n':Nat × Natk':Z'heq:n ≈ n'heq':k ≈ k'⊢ add' n k = add' n' k'
```


### Display 28


```text
n✝:Zn:Nat × Natk:Z'n':Nat × Natk':Z'heq:n ≈ n'heq':k ≈ k'⊢ (n.fst + k.fst, n.snd + k.snd) ≈ (n'.fst + k'.fst, n'.snd + k'.snd)
```


### Display 29


```text
mkn:Zk:Z'n':Nat × Natk':Z'heq':k ≈ k'fst✝:Natsnd✝:Natheq:(fst✝, snd✝) ≈ n'⊢ ((fst✝, snd✝).fst + k.fst, (fst✝, snd✝).snd + k.snd) ≈ (n'.fst + k'.fst, n'.snd + k'.snd)
```


### Display 30


```text
mk.mkn:Zn':Nat × Natk':Z'fst✝¹:Natsnd✝¹:Natheq:(fst✝, snd✝) ≈ n'fst✝:Natsnd✝:Natheq':(fst✝, snd✝) ≈ k'⊢ ((fst✝¹, snd✝¹).fst + (fst✝, snd✝).fst, (fst✝¹, snd✝¹).snd + (fst✝, snd✝).snd) ≈ (n'.fst + k'.fst, n'.snd + k'.snd)
```


### Display 31


```text
mk.mk.mkn:Zk':Z'fst✝²:Natsnd✝²:Natfst✝¹:Natsnd✝¹:Natheq':(fst✝, snd✝) ≈ k'fst✝:Natsnd✝:Natheq:(fst✝², snd✝²) ≈ (fst✝, snd✝)⊢ ((fst✝², snd✝²).fst + (fst✝¹, snd✝¹).fst, (fst✝², snd✝²).snd + (fst✝¹, snd✝¹).snd) ≈
  ((fst✝, snd✝).fst + k'.fst, (fst✝, snd✝).snd + k'.snd)
```


### Display 32


```text
mk.mk.mk.mkn:Zfst✝³:Natsnd✝³:Natfst✝²:Natsnd✝²:Natfst✝¹:Natsnd✝¹:Natheq:(fst✝², snd✝²) ≈ (fst✝, snd✝)fst✝:Natsnd✝:Natheq':(fst✝², snd✝²) ≈ (fst✝, snd✝)⊢ ((fst✝³, snd✝³).fst + (fst✝², snd✝²).fst, (fst✝³, snd✝³).snd + (fst✝², snd✝²).snd) ≈
  ((fst✝¹, snd✝¹).fst + (fst✝, snd✝).fst, (fst✝¹, snd✝¹).snd + (fst✝, snd✝).snd)
```


### Display 33


```text
mk.mk.mk.mkn:Zfst✝³:Natsnd✝³:Natfst✝²:Natsnd✝²:Natfst✝¹:Natsnd✝¹:Natfst✝:Natsnd✝:Natheq:fst✝³ + snd✝¹ = snd✝³ + fst✝¹heq':fst✝² + snd✝ = snd✝² + fst✝⊢ fst✝³ + fst✝² + (snd✝¹ + snd✝) = snd✝³ + snd✝² + (fst✝¹ + fst✝)
```


### Display 34


```text
n:Z⊢ n + -n = 0
```


### Display 35


```text
aa✝:Z'⊢ Quotient.mk instSetoid a✝ + -Quotient.mk instSetoid a✝ = 0
```


### Display 36


```text
aa✝:Z'⊢ (a✝.fst + (a✝.snd, a✝.fst).fst, a✝.snd + (a✝.snd, a✝.fst).snd) ≈ (0, 0)
```


### Display 37


```text
α:Sort uβ:α → Sort vf:ExtFun α βx:αg:(x : α) → β xg':(x : α) → β xh:extEq g g'⊢ g x = g' x
```


### Display 38


```text
α:Sort uβ:α → Sort vf:(x : α) → β xg:(x : α) → β xh:∀ (x : α), f x = g x⊢ f = g
```


### Display 39


```text
α:Sort uβ:α → Sort vf:(x : α) → β xg:(x : α) → β xh:∀ (x : α), f x = g xthis:extApp (Quot.mk extEq f) = extApp (Quot.mk extEq g)⊢ f = g
```


### Display 40


```text
α:Sort uβ:α → Sort vf:(x : α) → β xg:(x : α) → β xh:∀ (x : α), f x = g xthis:(fun x => Quot.lift (fun x_1 => x_1 x) ⋯ (Quot.mk extEq f)) = fun x => Quot.lift (fun x_1 => x_1 x) ⋯ (Quot.mk extEq g)⊢ f = g
```


### Display 41


```text
α:Sort uβ:α → Sort vf:(x : α) → β xg:(x : α) → β xh:∀ (x : α), f x = g xthis:(fun x => f x) = fun x => g x⊢ f = g
```


### Display 42


```text
α:Sort uβ:α → Sort vf:(x : α) → β xg:(x : α) → β xh:∀ (x : α), f x = g x⊢ extApp (Quot.mk extEq f) = extApp (Quot.mk extEq g)
```


### Display 43


```text
α:Sort uβ:α → Sort vf:(x : α) → β xg:(x : α) → β xh:∀ (x : α), f x = g xthis:Quot.mk extEq f = Quot.mk extEq g⊢ extApp (Quot.mk extEq f) = extApp (Quot.mk extEq g)
```


### Display 44


```text
α:Sort uβ:α → Sort vf:(x : α) → β xg:(x : α) → β xh:∀ (x : α), f x = g xthis:Quot.mk extEq f = Quot.mk extEq g⊢ Quot.mk extEq f = Quot.mk extEq g
```


### Display 45


```text
α:Sort uβ:α → Sort vf:(x : α) → β xg:(x : α) → β xh:∀ (x : α), f x = g x⊢ Quot.mk extEq f = Quot.mk extEq g
```


### Display 46


```text
α:Sort uβ:α → Sort vf:(x : α) → β xg:(x : α) → β xh:∀ (x : α), f x = g x⊢ extEq f g
```

