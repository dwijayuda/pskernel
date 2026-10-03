<a id="The-Lean-Language-Reference--Basic-Types--The-Unit-Type"></a>

# ProofScript — 20.9. The Unit Type

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/The-Unit-Type/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/The-Unit-Type/index.html). Source Git blob: `3207151450ba94aceaca817590d1c1981d99655c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.9. The Unit Type

The unit type is the canonical type with exactly one element, named `unit` and represented by the empty tuple `()`. It describes only a single value, which consists of said constructor applied to no arguments whatsoever.

`Unit` is analogous to `void` in languages derived from C: even though `void` has no elements that can be named, it represents the return of control flow from a function with no additional information. In functional programming, `Unit` is the return type of things that “return nothing”. Mathematically, this is represented by a single completely uninformative value, as opposed to an empty type such as `Empty`, which represents unreachable code.

When programming with [monads](../../Functors___-Monads-and--do--Notation/index.md#monads-and-do), `Unit` is especially useful. For any type `α`, `m α` represents an action that has side effects and returns a value of type `α`. The type `m Unit` represents an action that has some side effects but does not return a value.

There are two variants of the unit type:

- `Unit` is a `Type` that exists in the smallest non-propositional [universe](../../The-Type-System/Universes/index.md#--tech-term-universes).
- `PUnit` is [universe polymorphic](../../The-Type-System/Universes/index.md#--tech-term-universe-polymorphism) and can be used in any non-propositional [universe](../../The-Type-System/Universes/index.md#--tech-term-universes).

Behind the scenes, `Unit` is actually defined as `PUnit.{1}`. `Unit` should be preferred over `PUnit` when possible to avoid unnecessary universe parameters. If in doubt, use `Unit` until universe errors occur.

<a id="Unit"></a>

**def**

```text
Unit : Type
```

The canonical type with one element. This element is written `()`.

`Unit` has a number of uses:

- It can be used to model control flow that returns from a function call without providing other information.
- Monadic actions that return `Unit` have side effects without computing values.
- In polymorphic types, it can be used to indicate that no data is to be stored in a particular field.

<a id="Unit___unit"></a>

**def**

```text
Unit.unit : Unit
```

The only element of the unit type.

It can be written as an empty tuple: `()`.

<a id="PUnit___unit"></a>

**inductive type**

```text
PUnit.{u} : Sort u
```

The canonical universe-polymorphic type with just one element.

It should be used in contexts that require a type to be universe polymorphic, thus disallowing `Unit`.

**Constructors**

```text
PUnit.unit.{u} : PUnit
```

The only element of the universe-polymorphic unit type.

<a id="The-Lean-Language-Reference--Basic-Types--The-Unit-Type--Definitional-Equality"></a>
### 20.9.1. Definitional Equality

<a id="--tech-term-Unit-like-types"></a>
*Unit-like types* are inductive types that have a single constructor which takes no non-proof parameters. `PUnit` is one such type. All elements of unit-like types are [definitionally equal](../../The-Type-System/index.md#--tech-term-definitional-equality) to all other elements.

<a id="Definitional-Equality-of--Unit"></a>
Definitional Equality of `Unit` 

Every term with type `Unit` is definitionally equal to every other term with type `Unit`:

```proofscript
example (e1 e2 : Unit) : e1 = e2 := rfl
```

<a id="Definitional-Equality-of-Unit-Like-Types"></a>
Definitional Equality of Unit-Like Types 

Both `CustomUnit` and `AlsoUnit` are unit-like types, with a single constructor that takes no parameters. Every pair of terms with either type is definitionally equal.
<a id="CustomUnit-_LPAR_in-Definitional-Equality-of-Unit-Like-Types_RPAR_"></a>
<a id="CustomUnit___customUnit-_LPAR_in-Definitional-Equality-of-Unit-Like-Types_RPAR_"></a>
<a id="AlsoUnit-_LPAR_in-Definitional-Equality-of-Unit-Like-Types_RPAR_"></a>


```proofscript
inductive CustomUnit where
  | customUnit

example (e1 e2 : CustomUnit) : e1 = e2 := rfl

structure AlsoUnit where

example (e1 e2 : AlsoUnit) : e1 = e2 := rfl
```

Types with parameters, such as `WithParam`, are also unit-like if they have a single constructor that does not take parameters.
<a id="WithParam-_LPAR_in-Definitional-Equality-of-Unit-Like-Types_RPAR_"></a>
<a id="WithParam___mk-_LPAR_in-Definitional-Equality-of-Unit-Like-Types_RPAR_"></a>


```proofscript
inductive WithParam (n : Nat) where
  | mk

example (x y : WithParam 3) : x = y := rfl
```

Constructors with non-proof parameters are not unit-like, even if the parameters are all unit-like types.
<a id="NotUnitLike-_LPAR_in-Definitional-Equality-of-Unit-Like-Types_RPAR_"></a>
<a id="NotUnitLike___mk-_LPAR_in-Definitional-Equality-of-Unit-Like-Types_RPAR_"></a>


```proofscript
inductive NotUnitLike where
  | mk (u : Unit)
```

```proofscript
example (e1 e2 : NotUnitLike) : e1 = e2 := rfl
```

```lean
Type mismatch
  rfl
has type
  ?m.3 = ?m.3
but is expected to have type
  e1 = e2
```

Constructors of unit-like types may take parameters that are proofs.
<a id="ProofUnitLike-_LPAR_in-Definitional-Equality-of-Unit-Like-Types_RPAR_"></a>
<a id="ProofUnitLike___mk-_LPAR_in-Definitional-Equality-of-Unit-Like-Types_RPAR_"></a>


```proofscript
inductive ProofUnitLike where
  | mk : 2 = 2 → ProofUnitLike

example (e1 e2 : ProofUnitLike) : e1 = e2 := rfl
```

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Type mismatch
  rfl
has type
  ?m.3 = ?m.3
but is expected to have type
  e1 = e2
```

