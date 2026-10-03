<a id="sort-coercion"></a>

# ProofScript — 11.3. Coercing to Sorts

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Coercions are native elaboration mechanisms, including coercion between types, to sorts and to function types. They are not JavaScript conversions based on truthiness or object prototypes. An implementation must preserve the selected coercion or reject the unsupported case. A foreign value needs an appropriate decoder or model before it can satisfy an owned logical invariant.

**Compiler and coverage boundary.** Record inserted coercions and their dependencies. Do not replace dependent coercions with unchecked target casts.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Coercions/Coercing-to-Sorts/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Coercions/Coercing-to-Sorts/index.html). Source Git blob: `353268ae547769d0855d347845bfb68f8590f6c1`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 11.3. Coercing to Sorts

The Lean elaborator expects types in certain positions without necessarily being able to determine the type's [universe](../../The-Type-System/Universes/index.md#--tech-term-universes) ahead of time. For example, the term following the colon in a definition header might be a proposition or a type. The ordinary coercion mechanism is not applicable because it requires a specific expected type, and there's no way to express that the expected type could be *any* universe in the `Coe` class.

When a term is elaborated in a position where a proposition or type is expected, but the inferred type of the elaborated term is not a proposition or type, Lean attempts to recover from the error by synthesizing an instance of `CoeSort`. If the instance is found, and the resulting type is itself a type, then it the coercion is inserted and unfolded.

Not every situation in which the elaborator expects a universe requires `CoeSort`. In some cases, a particular universe is available as an expected type. In these situations, ordinary coercion insertion using `CoeT` is used. Instances of `CoeSort` can be used to synthesize instances of `CoeOut`, so no separate instance is needed to support this use case. In general, coercions to types should be implemented as `CoeSort`.

<a id="CoeSort___mk"></a>

**type class**

```text
CoeSort.{u, v} (α : Sort u) (β : outParam (Sort v)) :
  Sort (max (max 1 u) v)
```

`CoeSort α β` is a coercion to a sort. `β` must be a universe, and this is triggered when `a : α` appears in a place where a type is expected, like `(x : a)` or `a → a`. `CoeSort` instances apply to `CoeOut` as well.

**Instance Constructor**

```text
CoeSort.mk.{u, v}
```

**Methods**

```text
coe : α → β
```

Coerces a value of type `α` to `β`, which must be a universe.

<a id="term-next-next-next-next-next-next"></a>

**syntax**

**Explicit Coercion to Sorts**

<a id="coeSortNotation"></a>

```ebnf
term ::= ...
    | ↥ term
```

Coercions to sorts can be explicitly triggered using the `↥` prefix operator.

<a id="Sort-Coercions"></a>
Sort Coercions 

A monoid is a type equipped with an associative binary operation and an identity element. While monoid structure can be defined as a type class, it can also be defined as a structure that “bundles up” the structure with the type:
<a id="Monoid-_LPAR_in-Sort-Coercions_RPAR_"></a>
<a id="Monoid___Carrier-_LPAR_in-Sort-Coercions_RPAR_"></a>
<a id="Monoid___op-_LPAR_in-Sort-Coercions_RPAR_"></a>
<a id="Monoid___id-_LPAR_in-Sort-Coercions_RPAR_"></a>
<a id="Monoid___op_assoc-_LPAR_in-Sort-Coercions_RPAR_"></a>
<a id="Monoid___id_op_identity-_LPAR_in-Sort-Coercions_RPAR_"></a>
<a id="Monoid___op_id_identity-_LPAR_in-Sort-Coercions_RPAR_"></a>


```proofscript
structure Monoid where
  Carrier : Type u
  op : Carrier → Carrier → Carrier
  id : Carrier
  op_assoc :
    ∀ (x y z : Carrier), op x (op y z) = op (op x y) z
  id_op_identity : ∀ (x : Carrier), op id x = x
  op_id_identity : ∀ (x : Carrier), op x id = x
```

The type `Monoid` does not indicate the carrier:
<a id="StringMonoid-_LPAR_in-Sort-Coercions_RPAR_"></a>


```proofscript
def StringMonoid : Monoid where
  Carrier := String
  op := (· ++ ·)
  id := ""
  op_assoc := by intros; simp [String.append_assoc]
  id_op_identity := by intros; simp
  op_id_identity := by intros; simp
```

However, a `CoeSort` instance can be implemented that applies the `Monoid.Carrier` projection when a monoid is used in a position where Lean would expect a type:

```proofscript
instance : CoeSort Monoid (Type u) where
  coe m := m.Carrier

example : StringMonoid := "hello"
```

<a id="Sort-Coercions-as-Ordinary-Coercions"></a>
Sort Coercions as Ordinary Coercions 

The [inductive type](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types) `NatOrBool` represents the types `Nat` and `Bool`. They can be coerced to the actual types `Nat` and `Bool`:
<a id="NatOrBool-_LPAR_in-Sort-Coercions-as-Ordinary-Coercions_RPAR_"></a>
<a id="NatOrBool___nat-_LPAR_in-Sort-Coercions-as-Ordinary-Coercions_RPAR_"></a>
<a id="NatOrBool___bool-_LPAR_in-Sort-Coercions-as-Ordinary-Coercions_RPAR_"></a>
<a id="NatOrBool___asType-_LPAR_in-Sort-Coercions-as-Ordinary-Coercions_RPAR_"></a>


```proofscript
inductive NatOrBool where
  | nat | bool

@[coe]
abbrev NatOrBool.asType : NatOrBool → Type
  | .nat => Nat
  | .bool => Bool

instance : CoeSort NatOrBool Type where
  coe := NatOrBool.asType

open NatOrBool
```

The `CoeSort` instance is used when `nat` occurs to the right of a colon:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="x-_LPAR_in-Sort-Coercions-as-Ordinary-Coercions_RPAR_"></a>


```proofscript
const x : nat := 5
```

When an expected type is available, ordinary coercion insertion is used. In this case, the `CoeSort` instance is used to synthesize a `CoeOut NatOrBool Type` instance, which chains with the `Coe Type (Option Type)` instance to recover from the type error.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="y-_LPAR_in-Sort-Coercions-as-Ordinary-Coercions_RPAR_"></a>


```proofscript
const y : Option Type := bool
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`↥ t` coerces `t` to a type.
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ ∀ (x y z : String), x ++ (y ++ z) = x ++ y ++ z
```


### Display 2


```text
x✝:Stringy✝:Stringz✝:String⊢ x✝ ++ (y✝ ++ z✝) = x✝ ++ y✝ ++ z✝
```


### Display 3


```text
All goals completed! 🐙
```


### Display 4


```text
⊢ ∀ (x : String), "" ++ x = x
```


### Display 5


```text
x✝:String⊢ "" ++ x✝ = x✝
```


### Display 6


```text
⊢ ∀ (x : String), x ++ "" = x
```


### Display 7


```text
x✝:String⊢ x✝ ++ "" = x✝
```

