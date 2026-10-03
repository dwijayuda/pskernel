<a id="sum-types"></a>

# ProofScript — 20.14. Sum Types

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Sum-Types/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Sum-Types/index.html). Source Git blob: `64783d444858a6be8dacf711a7c28582b9db02d1`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.14. Sum Types

<a id="--tech-term-Sum-types"></a>
*Sum types* represent a choice between two types: an element of the sum is an element of one of the other types, paired with an indication of which type it came from. Sums are also known as disjoint unions, discriminated unions, or tagged unions. The constructors of a sum are also called 
<a id="--tech-term-injections"></a>
*injections*; mathematically, they can be considered as injective functions from each summand to the sum.

There are two varieties of the sum type:

- `Sum` is [polymorphic](../../The-Type-System/Universes/index.md#--tech-term-universe-polymorphism) over all `Type` [universes](../../The-Type-System/Universes/index.md#--tech-term-universes), and is never a [proposition](../../The-Type-System/Propositions/index.md#--tech-term-Propositions).
- `PSum` is allows the summands to be propositions or types. Unlike `Or`, the `PSum` of two propositions is still a type, and non-propositional code can check which injection was used to construct a given value.

Manually-written Lean code almost always uses only `Sum`, while `PSum` is used as part of the implementation of proof automation. This is because it imposes problematic constraints that universe level unification cannot solve. In particular, this type is in the universe `Sort (max 1 u v)`, which can cause problems for universe level unification because the equation `max 1 u v = ?u + 1` has no solution in level arithmetic. `PSum` is usually only used in automation that constructs sums of arbitrary types.

<a id="Sum___inl"></a>

**inductive type**

```text
Sum.{u, v} (α : Type u) (β : Type v) : Type (max u v)
```

The disjoint union of types `α` and `β`, ordinarily written `α ⊕ β`.

An element of `α ⊕ β` is either an `a : α` wrapped in `Sum.inl` or a `b : β` wrapped in `Sum.inr`. `α ⊕ β` is not equivalent to the set-theoretic union of `α` and `β` because its values include an indication of which of the two types was chosen. The union of a singleton set with itself contains one element, while `Unit ⊕ Unit` contains distinct values `inl ()` and `inr ()`.

**Constructors**

```text
Sum.inl.{u, v} {α : Type u} {β : Type v} (val : α) : α ⊕ β
```

Left injection into the sum type `α ⊕ β`.

```text
Sum.inr.{u, v} {α : Type u} {β : Type v} (val : β) : α ⊕ β
```

Right injection into the sum type `α ⊕ β`.

<a id="PSum___inl"></a>

**inductive type**

```text
PSum.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v)
```

The disjoint union of arbitrary sorts `α` `β`, or `α ⊕' β`.

It differs from `α ⊕ β` in that it allows `α` and `β` to have arbitrary sorts `Sort u` and `Sort v`, instead of restricting them to `Type u` and `Type v`. This means that it can be used in situations where one side is a proposition, like `True ⊕' Nat`. However, the resulting universe level constraints are often more difficult to solve than those that result from `Sum`.

**Constructors**

```text
PSum.inl.{u, v} {α : Sort u} {β : Sort v} (val : α) : α ⊕' β
```

Left injection into the sum type `α ⊕' β`.

```text
PSum.inr.{u, v} {α : Sort u} {β : Sort v} (val : β) : α ⊕' β
```

Right injection into the sum type `α ⊕' β`.

<a id="sum-syntax"></a>
### 20.14.1. Syntax

The names `Sum` and `PSum` are rarely written explicitly. Most code uses the corresponding infix operators.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Sum Types**

<a id="_FLQQ_term______FLQQ_-next-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | term ⊕ term
```

`α ⊕ β` is notation for `Sum α β`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Potentially-Propositional Sum Types**

<a id="_FLQQ_term_________FLQQ_-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | term ⊕' term
```

`α ⊕' β` is notation for `PSum α β`.

<a id="sum-api"></a>
### 20.14.2. API Reference

Sum types are primarily used with [pattern matching](../../Terms/Pattern-Matching/index.md#--tech-term-Pattern-matching) rather than explicit function calls from an API. As such, their primary API is the constructors `inl` and `inr`.

<a id="The-Lean-Language-Reference--Basic-Types--Sum-Types--API-Reference--Case-Distinction"></a>
#### 20.14.2.1. Case Distinction

<a id="Sum___isLeft"></a>

**def**

```text
Sum.isLeft.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α ⊕ β → Bool
```

Checks whether a sum is the left injection `inl`.

<a id="Sum___isRight"></a>

**def**

```text
Sum.isRight.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α ⊕ β → Bool
```

Checks whether a sum is the right injection `inr`.

<a id="The-Lean-Language-Reference--Basic-Types--Sum-Types--API-Reference--Extracting-Values"></a>
#### 20.14.2.2. Extracting Values

<a id="Sum___elim"></a>

**def**

```text
Sum.elim.{u_1, u_2, u_3} {α : Type u_1} {β : Type u_2} {γ : Sort u_3}
  (f : α → γ) (g : β → γ) : α ⊕ β → γ
```

Case analysis for sums that applies the appropriate function `f` or `g` after checking which constructor is present.

<a id="Sum___getLeft"></a>

**def**

```text
Sum.getLeft.{u_1, u_2} {α : Type u_1} {β : Type u_2} (ab : α ⊕ β) :
  ab.isLeft = true → α
```

Retrieves the contents from a sum known to be `inl`.

<a id="Sum___getLeft___"></a>

**def**

```text
Sum.getLeft?.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α ⊕ β → Option α
```

Checks whether a sum is the left injection `inl` and, if so, retrieves its contents.

<a id="Sum___getRight"></a>

**def**

```text
Sum.getRight.{u_1, u_2} {α : Type u_1} {β : Type u_2} (ab : α ⊕ β) :
  ab.isRight = true → β
```

Retrieves the contents from a sum known to be `inr`.

<a id="Sum___getRight___"></a>

**def**

```text
Sum.getRight?.{u_1, u_2} {α : Type u_1} {β : Type u_2} :
  α ⊕ β → Option β
```

Checks whether a sum is the right injection `inr` and, if so, retrieves its contents.

<a id="The-Lean-Language-Reference--Basic-Types--Sum-Types--API-Reference--Transformations"></a>
#### 20.14.2.3. Transformations

<a id="Sum___map"></a>

**def**

```text
Sum.map.{u_1, u_2, u_3, u_4} {α : Type u_1} {α' : Type u_2}
  {β : Type u_3} {β' : Type u_4} (f : α → α') (g : β → β') :
  α ⊕ β → α' ⊕ β'
```

Transforms a sum according to functions on each type.

This function maps `α ⊕ β` to `α' ⊕ β'`, sending `α` to `α'` and `β` to `β'`.

<a id="Sum___swap"></a>

**def**

```text
Sum.swap.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α ⊕ β → β ⊕ α
```

Swaps the factors of a sum type.

The constructor `Sum.inl` is replaced with `Sum.inr`, and vice versa.

<a id="The-Lean-Language-Reference--Basic-Types--Sum-Types--API-Reference--Inhabited"></a>
#### 20.14.2.4. Inhabited

The `Inhabited` definitions for `Sum` and `PSum` are not registered as instances. This is because there are two separate ways to construct a default value (via `inl` or `inr`), and instance synthesis might result in either choice. The result could be situations where two identically-written terms elaborate differently and are not [definitionally equal](../../The-Type-System/index.md#--tech-term-definitional-equality).

Both types have `Nonempty` instances, for which [proof irrelevance](../../The-Type-System/index.md#--tech-term-proof-irrelevance) makes the choice of `inl` or `inr` not matter. This is enough to enable `partial` functions. For situations that require an `Inhabited` instance, such as programs that use `panic!`, the instance can be explicitly used by adding it to the local context with `have` or `let`.

<a id="Inhabited-Sum-Types"></a>
Inhabited Sum Types 

In Lean's logic, `panic!` is equivalent to the default value specified in its type's `Inhabited` instance. This means that the type must have such an instance—a `Nonempty` instance combined with the axiom of choice would render the program non-computable.

Products have the right instance:

```proofscript
example : Nat × String := panic! "Can't find it"
```

Sums do not, by default:

```proofscript
example : Nat ⊕ String := panic! "Can't find it"
```

```lean
failed to synthesize instance of type class
  Inhabited (Nat ⊕ String)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

The desired instance can be made available to instance synthesis using `have`:

```proofscript
example : Nat ⊕ String :=
  have : Inhabited (Nat ⊕ String) := Sum.inhabitedLeft
  panic! "Can't find it"
```

<a id="Sum___inhabitedLeft"></a>

**def**

```text
Sum.inhabitedLeft.{u, v} {α : Type u} {β : Type v} [Inhabited α] :
  Inhabited (α ⊕ β)
```

If the left type in a sum is inhabited then the sum is inhabited.

This is not an instance to avoid non-canonical instances when both the left and right types are inhabited.

<a id="Sum___inhabitedRight"></a>

**def**

```text
Sum.inhabitedRight.{u, v} {α : Type u} {β : Type v} [Inhabited β] :
  Inhabited (α ⊕ β)
```

If the right type in a sum is inhabited then the sum is inhabited.

This is not an instance to avoid non-canonical instances when both the left and right types are inhabited.

<a id="PSum___inhabitedLeft"></a>

**def**

```text
PSum.inhabitedLeft.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  [Inhabited α] : Inhabited (α ⊕' β)
```

If the left type in a sum is inhabited then the sum is inhabited.

This is not an instance to avoid non-canonical instances when both the left and right types are inhabited.

<a id="PSum___inhabitedRight"></a>

**def**

```text
PSum.inhabitedRight.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  [Inhabited β] : Inhabited (α ⊕' β)
```

If the right type in a sum is inhabited then the sum is inhabited.

This is not an instance to avoid non-canonical instances when both the left and right types are inhabited.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
The disjoint union of types `α` and `β`, ordinarily written `α ⊕ β`.

An element of `α ⊕ β` is either an `a : α` wrapped in `Sum.inl` or a `b : β` wrapped in `Sum.inr`.
`α ⊕ β` is not equivalent to the set-theoretic union of `α` and `β` because its values include an
indication of which of the two types was chosen. The union of a singleton set with itself contains
one element, while `Unit ⊕ Unit` contains distinct values `inl ()` and `inr ()`.
```


### Display 2


```text
The disjoint union of arbitrary sorts `α` `β`, or `α ⊕' β`.

It differs from `α ⊕ β` in that it allows `α` and `β` to have arbitrary sorts `Sort u` and `Sort v`,
instead of restricting them to `Type u` and `Type v`. This means that it can be used in situations
where one side is a proposition, like `True ⊕' Nat`. However, the resulting universe level
constraints are often more difficult to solve than those that result from `Sum`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
failed to synthesize instance of type class
  Inhabited (Nat ⊕ String)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

