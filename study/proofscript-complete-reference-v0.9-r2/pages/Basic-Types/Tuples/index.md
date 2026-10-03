<a id="tuples"></a>

# ProofScript — 20.13. Tuples

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Tuples/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Tuples/index.html). Source Git blob: `46db209c4935f3794447c6b38c1cb3fbea269c8c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.13. Tuples

The Lean standard library includes a variety of tuple-like types. In practice, they differ in four ways:

- whether the first projection is a type or a proposition
- whether the second projection is a type or a proposition
- whether the second projection's type depends on the first projection's value
- whether the type as a whole is a proposition or type

| Type | First Projection | Second Projection | Dependent? | Universe |
| --- | --- | --- | --- | --- |
| `Prod` | `Type u` | `Type v` | ❌️ | `Type (max u v)` |
| `And` | `Prop` | `Prop` | ❌️ | `Prop` |
| `Sigma` | `Type u` | `Type v` | ✔ | `Type (max u v)` |
| `Subtype` | `Type u` | `Prop` | ✔ | `Type u` |
| `Exists` | `Type u` | `Prop` | ✔ | `Prop` |

Some potential rows in this table do not exist in the library:

- There is no dependent pair where the first projection is a proposition, because [proof irrelevance](../../The-Type-System/index.md#--tech-term-proof-irrelevance) renders this meaningless.
- There is no non-dependent pair that combines a type with a proposition because the situation is rare in practice: grouping data with *unrelated* proofs is uncommon.

These differences lead to very different use cases. `Prod` and its variants `PProd` and `MProd` simply group data together—they are products. Because its second projection is dependent, `Sigma` has the character of a sum: for each element of the first projection's type, there may be a different type in the second projection. `Subtype` selects the values of a type that satisfy a predicate. Even though it syntactically resembles a pair, in practice it is treated as an actual subset. `And` is a logical connective, and `Exists` is a quantifier. This chapter documents the tuple-like pairs, namely `Prod` and `Sigma`.

<a id="pairs"></a>
### 20.13.1. Ordered Pairs

The type `α × β`, which is a [notation](../../Notations-and-Macros/Notations/index.md#--tech-term-notation) for `Prod α β`, contains ordered pairs in which the first item is an `α` and the second is a `β`. These pairs are written in parentheses, separated by commas. Larger tuples are represented as nested tuples, so `α × β × γ` is equivalent to `α × (β × γ)` and `(x, y, z)` is equivalent to `(x, (y, z))`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Product Types**

<a id="_FLQQ_term______FLQQ_-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | term × term
```

The product `Prod α β` is written `α × β`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Pairs**

<a id="Lean___Parser___Term___tuple"></a>

```ebnf
term ::= ...
    | ([anonymous]term, term)
```

<a id="Prod___mk"></a>

**structure**

```text
Prod.{u, v} (α : Type u) (β : Type v) : Type (max u v)
```

The product type, usually written `α × β`. Product types are also called pair or tuple types. Elements of this type are pairs in which the first element is an `α` and the second element is a `β`.

Products nest to the right, so `(x, y, z) : α × β × γ` is equivalent to `(x, (y, z)) : α × (β × γ)`.

Conventions for notations in identifiers:

- The recommended spelling of `×` in identifiers is `Prod`.

**Constructor**

```text
Prod.mk.{u, v}
```

Constructs a pair. This is usually written `(x, y)` instead of `Prod.mk x y`.

Conventions for notations in identifiers:

- The recommended spelling of `(a, b)` in identifiers is `mk`.

**Fields**

```text
fst : α
```

The first element of a pair.

```text
snd : β
```

The second element of a pair.

There are also the variants `α ×' β` (which is notation for `PProd α β`) and `MProd`, which differ with respect to [universe](../../The-Type-System/Universes/index.md#--tech-term-universes) levels: like `PSum`, `PProd` allows either `α` or `β` to be a proposition, while `MProd` requires that both be types at the *same* universe level. Generally speaking, `PProd` is primarily used in the implementation of proof automation and the elaborator, as it tends to give rise to universe level unification problems that can't be solved. `MProd`, on the other hand, can simplify universe level issues in certain advanced use cases.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Products of Arbitrary Sorts**

<a id="_FLQQ_term_________FLQQ_-next-next-next-next"></a>

```ebnf
term ::= ...
    | term ×' term
```

The product `PProd α β`, in which both types could be propositions, is written `α × β`.

<a id="PProd___mk"></a>

**structure**

```text
PProd.{u, v} (α : Sort u) (β : Sort v) : Sort (max (max 1 u) v)
```

A product type in which the types may be propositions, usually written `α ×' β`.

This type is primarily used internally and as an implementation detail of proof automation. It is rarely useful in hand-written code.

Conventions for notations in identifiers:

- The recommended spelling of `×'` in identifiers is `PProd`.

**Constructor**

```text
PProd.mk.{u, v}
```

**Fields**

```text
fst : α
```

The first element of a pair.

```text
snd : β
```

The second element of a pair.

<a id="MProd___mk"></a>

**structure**

```text
MProd.{u} (α β : Type u) : Type u
```

A product type in which both `α` and `β` are in the same universe.

It is called `MProd` is because it is the *universe-monomorphic* product type.

**Constructor**

```text
MProd.mk.{u}
```

**Fields**

```text
fst : α
```

The first element of a pair.

```text
snd : β
```

The second element of a pair.

<a id="prod-api"></a>
#### 20.13.1.1. API Reference

As a mere pair, the primary API for `Prod` is provided by pattern matching and by the first and second projections `Prod.fst` and `Prod.snd`.

<a id="The-Lean-Language-Reference--Basic-Types--Tuples--Ordered-Pairs--API-Reference--Transformation"></a>
##### 20.13.1.1.1. Transformation

<a id="Prod___map"></a>

**def**

```text
Prod.map.{u₁, u₂, v₁, v₂} {α₁ : Type u₁} {α₂ : Type u₂} {β₁ : Type v₁}
  {β₂ : Type v₂} (f : α₁ → α₂) (g : β₁ → β₂) : α₁ × β₁ → α₂ × β₂
```

Transforms a pair by applying functions to both elements.

Examples:

- `(1, 2).map (· + 1) (· * 3) = (2, 6)`
- `(1, 2).map toString (· * 3) = ("1", 6)`

<a id="Prod___swap"></a>

**def**

```text
Prod.swap.{u_1, u_2} {α : Type u_1} {β : Type u_2} : α × β → β × α
```

Swaps the elements in a pair.

Examples:

- `(1, 2).swap = (2, 1)`
- `("orange", -87).swap = (-87, "orange")`

<a id="The-Lean-Language-Reference--Basic-Types--Tuples--Ordered-Pairs--API-Reference--Natural-Number-Ranges"></a>
##### 20.13.1.1.2. Natural Number Ranges

<a id="Prod___allI"></a>

**def**

```text
Prod.allI (i : Nat × Nat)
  (f : (j : Nat) → i.fst ≤ j → j < i.snd → Bool) : Bool
```

Checks whether a predicate holds for all natural numbers in a range.

In particular, `(start, stop).allI f` returns true if `f` is true for all natural numbers from `start` (inclusive) to `stop` (exclusive).

Examples:

- `(5, 8).allI (fun j _ _ => j < 10) = (5 < 10) && (6 < 10) && (7 < 10)`
- `(5, 8).allI (fun j _ _ => j % 2 = 0) = false`
- `(6, 7).allI (fun j _ _ => j % 2 = 0) = true`

<a id="Prod___anyI"></a>

**def**

```text
Prod.anyI (i : Nat × Nat)
  (f : (j : Nat) → i.fst ≤ j → j < i.snd → Bool) : Bool
```

Checks whether a predicate holds for any natural number in a range.

In particular, `(start, stop).allI f` returns true if `f` is true for any natural number from `start` (inclusive) to `stop` (exclusive).

Examples:

- `(5, 8).anyI (fun j _ _ => j == 6) = (5 == 6) || (6 == 6) || (7 == 6)`
- `(5, 8).anyI (fun j _ _ => j % 2 = 0) = true`
- `(6, 6).anyI (fun j _ _ => j % 2 = 0) = false`

<a id="Prod___foldI"></a>

**def**

```text
Prod.foldI.{u} {α : Type u} (i : Nat × Nat)
  (f : (j : Nat) → i.fst ≤ j → j < i.snd → α → α) (init : α) : α
```

Combines an initial value with each natural number from a range, in increasing order.

In particular, `(start, stop).foldI f init` applies `f`on all the numbers from `start` (inclusive) to `stop` (exclusive) in increasing order:

Examples:

- `(5, 8).foldI (fun j _ _ xs => xs.push j) #[] = (#[] |>.push 5 |>.push 6 |>.push 7)`
- `(5, 8).foldI (fun j _ _ xs => xs.push j) #[] = #[5, 6, 7]`
- `(5, 8).foldI (fun j _ _ xs => toString j :: xs) [] = ["7", "6", "5"]`

<a id="The-Lean-Language-Reference--Basic-Types--Tuples--Ordered-Pairs--API-Reference--Ordering"></a>
##### 20.13.1.1.3. Ordering

<a id="Prod___lexLt"></a>

**def**

```text
Prod.lexLt.{u_1, u_2} {α : Type u_1} {β : Type u_2} [LT α] [LT β]
  (s t : α × β) : Prop
```

Lexicographical order for products.

Two pairs are lexicographically ordered if their first elements are ordered or if their first elements are equal and their second elements are ordered.

<a id="sigma-types"></a>
### 20.13.2. Dependent Pairs

<a id="--tech-term-Dependent-pairs"></a>
*Dependent pairs*, also known as 
<a id="--tech-term-dependent-sums"></a>
*dependent sums* or 
<a id="--tech-term-___-types"></a>
*Σ-types*,
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 are pairs in which the second term's type may depend on the *value* of the first term. They are closely related to the existential quantifier and `Subtype`. Unlike existentially quantified statements, dependent pairs are in the `Type` universe and are computationally relevant data. Unlike subtypes, the second term is also computationally relevant data. Like ordinary pairs, dependent pairs may be nested; this nesting is right-associative.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Dependent Pair Types**

<a id="_FLQQ_term______1_FLQQ_"></a>

```ebnf
term ::= ...
    | (ident : term) × term
```

<a id="_FLQQ_term_________FLQQ_-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | Σ ident ident* (: term)?, term
```

<a id="_FLQQ_term_________FLQQ_-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | Σ (ident ident* : term), term
```

Dependent pair types bind one or more variables, which are then in scope in the final term. If there is one variable, then its type is a that of the first element in the pair and the final term is the type of the second element in the pair. If there is more than one variable, the types are nested right-associatively. The identifiers may also be `_`. With parentheses, multiple bound variables may have different types, while the unparenthesized variant requires that all have the same type.

<a id="Nested-Dependent-Pair-Types"></a>
Nested Dependent Pair Types  

The type

```proofscript
Σ n k : Nat, Fin (n * k)
```

is equivalent to

```proofscript
Σ n : Nat, Σ k : Nat, Fin (n * k)
```

and

```proofscript
(n : Nat) × (k : Nat) × Fin (n * k)
```

The type

```proofscript
Σ (n k : Nat) (i : Fin (n * k)) , Fin i.val
```

is equivalent to

```proofscript
Σ (n : Nat), Σ (k : Nat), Σ (i : Fin (n * k)) , Fin i.val
```

and

```proofscript
(n : Nat) × (k : Nat) × (i : Fin (n * k)) × Fin i.val
```

The two styles of annotation cannot be mixed in a single `Σ`-type:

```lean
Σ n k (i : Fin (n * k)) , Fin i.val
```

```lean
<example>:1:5-1:7: unexpected token '('; expected ','
```

Dependent pairs are typically used in one of two ways:

1. They can be used to “package” a concrete type index together with a value of the indexed family, used when the index value is not known ahead of time. The type `Σ n, Fin n` is a pair of a natural number and some other number that's strictly smaller. This is the most common way to use dependent pairs.
2. The first element can be thought of as a “tag” that's used to select from among different types for the second term. This is similar to the way that selecting a constructor of a sum type determines the types of the constructor's arguments. For example, the type

   

  ```proofscript
  Σ (b : Bool), if b then Unit else α
  ```

  

  is equivalent to `Option α`, where `none` is `⟨true, ()⟩` and `some x` is `⟨false, x⟩`. Using dependent pairs this way is uncommon, because it's typically much easier to define a special-purpose [inductive type](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types) directly.

<a id="Sigma___mk"></a>

**structure**

```text
Sigma.{u, v} {α : Type u} (β : α → Type v) : Type (max u v)
```

Dependent pairs, in which the second element's type depends on the value of the first element. The type `Sigma β` is typically written `Σ a : α, β a` or `(a : α) × β a`.

Although its values are pairs, `Sigma` is sometimes known as the *dependent sum type*, since it is the type level version of an indexed summation.

**Constructor**

```text
Sigma.mk.{u, v}
```

Constructs a dependent pair.

Using this constructor in a context in which the type is not known usually requires a type ascription to determine `β`. This is because the desired relationship between the two values can't generally be determined automatically.

**Fields**

```text
fst : α
```

The first component of a dependent pair.

```text
snd : β self.fst
```

The second component of a dependent pair. Its type depends on the first component.

<a id="Dependent-Pairs-with-Data"></a>
Dependent Pairs with Data 

The type `Vector`, which associates a known length with an array, can be placed in a dependent pair with the length itself. While this is logically equivalent to just using `Array`, this construction is sometimes necessary to bridge gaps in an API.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="getNLinesRev-_LPAR_in-Dependent-Pairs-with-Data_RPAR_"></a>
<a id="getNLines-_LPAR_in-Dependent-Pairs-with-Data_RPAR_"></a>
<a id="getValues-_LPAR_in-Dependent-Pairs-with-Data_RPAR_"></a>
<a id="main-_LPAR_in-Dependent-Pairs-with-Data_RPAR_"></a>


```proofscript
def getNLinesRev : (n : Nat) → IO (Vector String n)
  | 0 => pure #v[]
  | n + 1 => do
    let xs ← getNLinesRev n
    return xs.push (← (← IO.getStdin).getLine)

function getNLines (n : Nat) : IO (Vector String n) := do
  return (← getNLinesRev n).reverse

partial const getValues : IO (Σ n, Vector String n) := do
  let stdin ← IO.getStdin

  IO.println "How many lines to read?"
  let howMany ← stdin.getLine

  if let some howMany := howMany.trimAscii.copy.toNat? then
    return ⟨howMany, (← getNLines howMany)⟩
  else
    IO.eprintln "Please enter a number."
    getValues

const main : IO Unit := do
  let values ← getValues
  IO.println s!"Got {values.fst} values. They are:"
  for x in values.snd do
    IO.println x.trimAscii
```

When calling the program with this standard input:

  `stdin``4``Apples``Quince``Plums``Raspberries` 

the output is:

  `stdout``How many lines to read?``Got 4 values. They are:``Raspberries``Plums``Quince``Apples`   
<a id="Dependent-Pairs-as-Sums"></a>
Dependent Pairs as Sums 

`Sigma` can be used to implement sum types. The `Bool` in the first projection of `Sum'` indicates which type the second projection is drawn from.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Sum___-_LPAR_in-Dependent-Pairs-as-Sums_RPAR_"></a>


```proofscript
function Sum' (α : Type) (β : Type) : Type :=
  Σ (b : Bool),
    match b with
    | true => α
    | false => β
```

The injections pair a tag (a `Bool`) with a value of the indicated type. Annotating them with `match_pattern` allows them to be used in patterns as well as in ordinary terms.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Sum______inl-_LPAR_in-Dependent-Pairs-as-Sums_RPAR_"></a>
<a id="Sum______inr-_LPAR_in-Dependent-Pairs-as-Sums_RPAR_"></a>
<a id="Sum______swap-_LPAR_in-Dependent-Pairs-as-Sums_RPAR_"></a>


```proofscript
variable {α β : Type}

@[match_pattern]
function Sum'.inl (x : α) : Sum' α β := ⟨true, x⟩

@[match_pattern]
function Sum'.inr (x : β) : Sum' α β := ⟨false, x⟩

def Sum'.swap : Sum' α β → Sum' β α
  | .inl x => .inr x
  | .inr y => .inl y
```

Just as `Prod` has a variant `PProd` that accepts propositions as well as types, `PSigma` allows its projections to be propositions. This has the same drawbacks as `PProd`: it is much more likely to lead to failures of universe level unification. However, `PSigma` can be necessary when implementing custom proof automation or in some rare, advanced use cases.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Fully-Polymorphic Dependent Pair Types**

<a id="_FLQQ_term____________FLQQ_"></a>

```ebnf
term ::= ...
    | Σ' ident ident* (: term)? , term
```

<a id="_FLQQ_term____________FLQQ_-next"></a>

```ebnf
term ::= ...
    | Σ' (ident ident* : term), term
```

The rules for nesting `Σ'`, as well as those that govern its binding structure, are the same as those for `Σ`.

<a id="PSigma___mk"></a>

**structure**

```text
PSigma.{u, v} {α : Sort u} (β : α → Sort v) : Sort (max (max 1 u) v)
```

Fully universe-polymorphic dependent pairs, in which the second element's type depends on the value of the first element and both types are allowed to be propositions. The type `PSigma β` is typically written `Σ' a : α, β a` or `(a : α) ×' β a`.

In practice, this generality leads to universe level constraints that are difficult to solve, so `PSigma` is rarely used in manually-written code. It is usually only used in automation that constructs pairs of arbitrary types.

To pair a value with a proof that a predicate holds for it, use `Subtype`. To demonstrate that a value exists that satisfies a predicate, use `Exists`. A dependent pair with a proposition as its first component is not typically useful due to proof irrelevance: there's no point in depending on a specific proof because all proofs are equal anyway.

**Constructor**

```text
PSigma.mk.{u, v}
```

Constructs a fully universe-polymorphic dependent pair.

**Fields**

```text
fst : α
```

The first component of a dependent pair.

```text
snd : β self.fst
```

The second component of a dependent pair. Its type depends on the first component.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
The product type, usually written `α × β`. Product types are also called pair or tuple types.
Elements of this type are pairs in which the first element is an `α` and the second element is a
`β`.

Products nest to the right, so `(x, y, z) : α × β × γ` is equivalent to `(x, (y, z)) : α × (β × γ)`.


Conventions for notations in identifiers:

 * The recommended spelling of `×` in identifiers is `Prod`.
```


### Display 2


```text
Tuple notation; `()` is short for `Unit.unit`, `(a, b, c)` for `Prod.mk a (Prod.mk b c)`, etc. 

Conventions for notations in identifiers:

 * The recommended spelling of `(a, b)` in identifiers is `mk`.
```


### Display 3


```text
A product type in which the types may be propositions, usually written `α ×' β`.

This type is primarily used internally and as an implementation detail of proof automation. It is
rarely useful in hand-written code.


Conventions for notations in identifiers:

 * The recommended spelling of `×'` in identifiers is `PProd`.
```


### Display 4


```text
`binderIdent` matches an `ident` or a `_`. It is used for identifiers in binding
position, where `_` means that the value should be left unnamed and inaccessible.
```

