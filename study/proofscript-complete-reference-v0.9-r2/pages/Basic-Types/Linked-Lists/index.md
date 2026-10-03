<a id="List"></a>

# ProofScript — 20.15. Linked Lists

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Linked-Lists/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Linked-Lists/index.html). Source Git blob: `5da14e0212966f5eef0aa3084eaf86f469b94cb9`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.15. Linked Lists

Linked lists, implemented as the [inductive type](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types) `List`, contain an ordered sequence of elements. Unlike [arrays](../Arrays/index.md#Array), Lean compiles lists according to the ordinary rules for inductive types; however, some operations on lists are replaced by tail-recursive equivalents in compiled code using the `csimp` mechanism. Lean provides syntax for both literal lists and the constructor `List.cons`.

<a id="List___nil"></a>

**inductive type**

```text
List.{u} (α : Type u) : Type u
```

Linked lists: ordered lists, in which each element has a reference to the next element.

Most operations on linked lists take time proportional to the length of the list, because each element must be traversed to find the next element.

`List α` is isomorphic to `Array α`, but they are useful for different things:

- `List α` is easier for reasoning, and `Array α` is modeled as a wrapper around `List α`.
- `List α` works well as a persistent data structure, when many copies of the tail are shared. When the value is not shared, `Array α` will have better performance because it can do destructive updates.

**Constructors**

```text
List.nil.{u} {α : Type u} : List α
```

The empty list, usually written `[]`.

Conventions for notations in identifiers:

- The recommended spelling of `[]` in identifiers is `nil`.

```text
List.cons.{u} {α : Type u} (head : α) (tail : List α) :
  List α
```

The list whose first element is `head`, where `tail` is the rest of the list. Usually written `head :: tail`.

Conventions for notations in identifiers:

- The recommended spelling of `::` in identifiers is `cons`.
- The recommended spelling of `[a]` in identifiers is `singleton`.

<a id="list-syntax"></a>
### 20.15.1. Syntax

List literals are written in square brackets, with the elements of the list separated by commas. The constructor `List.cons` that adds an element to the front of a list is represented by the infix operator [`::`](index.md#_FLQQ_term_________FLQQ_-next-next-next-next-next-next-next-next). The syntax for lists can be used both in ordinary terms and in patterns.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**List Literals**

<a id="_FLQQ_term_LSQ___RSQ__FLQQ_-next"></a>

```ebnf
term ::= ...
    | [term,*]
```

The syntax `[a, b, c]` is shorthand for `a :: b :: c :: []`, or `List.cons a (List.cons b (List.cons c List.nil))`. It allows conveniently constructing list literals.

For lists of length at least 64, an alternative desugaring strategy is used which uses let bindings as intermediates as in `let left := [d, e, f]; a :: b :: c :: left` to avoid creating very deep expressions. Note that this changes the order of evaluation, although it should not be observable unless you use side effecting operations like `dbg_trace`.

Conventions for notations in identifiers:

- The recommended spelling of `[]` in identifiers is `nil`.
- The recommended spelling of `[a]` in identifiers is `singleton`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**List Construction**

<a id="_FLQQ_term_________FLQQ_-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | term :: term
```

The list whose first element is `head`, where `tail` is the rest of the list. Usually written `head :: tail`.

Conventions for notations in identifiers:

- The recommended spelling of `::` in identifiers is `cons`.

<a id="Constructing-Lists"></a>
Constructing Lists 

All of these examples are equivalent:

```proofscript
example : List Nat := [1, 2, 3]
example : List Nat := 1 :: [2, 3]
example : List Nat := 1 :: 2 :: [3]
example : List Nat := 1 :: 2 :: 3 :: []
example : List Nat := 1 :: 2 :: 3 :: .nil
example : List Nat := 1 :: 2 :: .cons 3 .nil
example : List Nat := .cons 1 (.cons 2 (.cons 3 .nil))
```

<a id="Pattern-Matching-and-Lists"></a>
Pattern Matching and Lists 

All of these functions are equivalent:
<a id="split-_LPAR_in-Pattern-Matching-and-Lists_RPAR_"></a>


```proofscript
def split : List α → List α × List α
  | [] => ([], [])
  | [x] => ([x], [])
  | x :: x' :: xs =>
    let (ys, zs) := split xs
    (x :: ys, x' :: zs)
```
<a id="split___-_LPAR_in-Pattern-Matching-and-Lists_RPAR_"></a>


```proofscript
def split' : List α → List α × List α
  | .nil => (.nil, .nil)
  | x :: [] => (.singleton x, .nil)
  | x :: x' :: xs =>
    let (ys, zs) := split xs
    (x :: ys, x' :: zs)
```
<a id="split______-_LPAR_in-Pattern-Matching-and-Lists_RPAR_"></a>


```proofscript
def split'' : List α → List α × List α
  | .nil => (.nil, .nil)
  | .cons x .nil => (.singleton x, .nil)
  | .cons x (.cons x' xs) =>
    let (ys, zs) := split xs
    (.cons x ys, .cons x' zs)
```

<a id="list-performance"></a>
### 20.15.2. Performance Notes

The representation of lists is not overridden or modified by the compiler: they are linked lists, with a pointer indirection for each element. Calculating the length of a list requires a full traversal, and modifying an element in a list requires a traversal and reallocation of the prefix of the list that is prior to the element being modified. Due to Lean's reference-counting-based memory management, operations such as `List.map` that traverse a list, allocating a new `List.cons` constructor for each in the prior list, can reuse the original list's memory when there are no other references to it.

Because of the important role played by lists in specifications, most list functions are written as straightforwardly as possible using structural recursion. This makes it easier to write proofs by induction, but it also means that these operations consume stack space proportional to the length of the list. There are tail-recursive versions of many list functions that are equivalent to the non-tail-recursive versions, but are more difficult to use when reasoning. In compiled code, the tail-recursive versions are automatically used instead of the non-tail-recursive versions.

<a id="list-api-reference"></a>
### 20.15.3. API Reference

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Predicates-and-Relations"></a>
#### 20.15.3.1. Predicates and Relations

<a id="List___IsPrefix"></a>

**def**

```text
List.IsPrefix.{u} {α : Type u} (l₁ l₂ : List α) : Prop
```

The first list is a prefix of the second.

`IsPrefix l₁ l₂`, written `l₁ <+: l₂`, means that there exists some `t : List α` such that `l₂` has the form `l₁ ++ t`.

The function `List.isPrefixOf` is a Boolean equivalent.

Conventions for notations in identifiers:

- The recommended spelling of `<+:` in identifiers is `prefix` (not `isPrefix`).

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**List Prefix**

<a id="List____FLQQ_term__LT_________FLQQ_"></a>

```ebnf
term ::= ...
    | term <+: term
```

The first list is a prefix of the second.

`IsPrefix l₁ l₂`, written `l₁ <+: l₂`, means that there exists some `t : List α` such that `l₂` has the form `l₁ ++ t`.

The function `List.isPrefixOf` is a Boolean equivalent.

Conventions for notations in identifiers:

- The recommended spelling of `<+:` in identifiers is `prefix` (not `isPrefix`).

<a id="List___IsSuffix"></a>

**def**

```text
List.IsSuffix.{u} {α : Type u} (l₁ l₂ : List α) : Prop
```

The first list is a suffix of the second.

`IsSuffix l₁ l₂`, written `l₁ <:+ l₂`, means that there exists some `t : List α` such that `l₂` has the form `t ++ l₁`.

The function `List.isSuffixOf` is a Boolean equivalent.

Conventions for notations in identifiers:

- The recommended spelling of `<:+` in identifiers is `suffix` (not `isSuffix`).

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**List Suffix**

<a id="List____FLQQ_term__LT_________FLQQ_-next"></a>

```ebnf
term ::= ...
    | term <:+ term
```

The first list is a suffix of the second.

`IsSuffix l₁ l₂`, written `l₁ <:+ l₂`, means that there exists some `t : List α` such that `l₂` has the form `t ++ l₁`.

The function `List.isSuffixOf` is a Boolean equivalent.

Conventions for notations in identifiers:

- The recommended spelling of `<:+` in identifiers is `suffix` (not `isSuffix`).

<a id="List___IsInfix"></a>

**def**

```text
List.IsInfix.{u} {α : Type u} (l₁ l₂ : List α) : Prop
```

The first list is a contiguous sub-list of the second list. Typically written with the `<:+:` operator.

In other words, `l₁ <:+: l₂` means that there exist lists `s : List α` and `t : List α` such that `l₂` has the form `s ++ l₁ ++ t`.

Conventions for notations in identifiers:

- The recommended spelling of `<:+:` in identifiers is `infix` (not `isInfix`).

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**List Infix**

<a id="List____FLQQ_term__LT____________FLQQ_"></a>

```ebnf
term ::= ...
    | term <:+: term
```

The first list is a contiguous sub-list of the second list. Typically written with the `<:+:` operator.

In other words, `l₁ <:+: l₂` means that there exist lists `s : List α` and `t : List α` such that `l₂` has the form `s ++ l₁ ++ t`.

Conventions for notations in identifiers:

- The recommended spelling of `<:+:` in identifiers is `infix` (not `isInfix`).

<a id="List___Sublist___slnil"></a>

**inductive predicate**

```text
List.Sublist.{u_1} {α : Type u_1} : List α → List α → Prop
```

The first list is a non-contiguous sub-list of the second list. Typically written with the `<+` operator.

In other words, `l₁ <+ l₂` means that `l₁` can be transformed into `l₂` by repeatedly inserting new elements.

**Constructors**

```text
List.Sublist.slnil.{u_1} {α : Type u_1} : [].Sublist []
```

The base case: `[]` is a sublist of `[]`

```text
List.Sublist.cons.{u_1} {α : Type u_1} {l₁ l₂ : List α}
  (a : α) : l₁.Sublist l₂ → l₁.Sublist (a :: l₂)
```

If `l₁` is a subsequence of `l₂`, then it is also a subsequence of `a :: l₂`.

```text
List.Sublist.cons_cons.{u_1} {α : Type u_1} {l₁ l₂ : List α}
  (a : α) : l₁.Sublist l₂ → (a :: l₁).Sublist (a :: l₂)
```

If `l₁` is a subsequence of `l₂`, then `a :: l₁` is a subsequence of `a :: l₂`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Sublists**

<a id="List____FLQQ_term__LT______FLQQ_"></a>

```ebnf
term ::= ...
    | term <+ term
```

The first list is a non-contiguous sub-list of the second list. Typically written with the `<+` operator.

In other words, `l₁ <+ l₂` means that `l₁` can be transformed into `l₂` by repeatedly inserting new elements.

This syntax is only available when the `List` namespace is opened.

<a id="List___Perm___nil"></a>

**inductive predicate**

```text
List.Perm.{u} {α : Type u} : List α → List α → Prop
```

Two lists are permutations of each other if they contain the same elements, each occurring the same number of times but not necessarily in the same order.

One list can be proven to be a permutation of another by showing how to transform one into the other by repeatedly swapping adjacent elements.

`List.isPerm` is a Boolean equivalent of this relation.

**Constructors**

```text
List.Perm.nil.{u} {α : Type u} : [].Perm []
```

The empty list is a permutation of the empty list: `[] ~ []`.

```text
List.Perm.cons.{u} {α : Type u} (x : α) {l₁ l₂ : List α} :
  l₁.Perm l₂ → (x :: l₁).Perm (x :: l₂)
```

If one list is a permutation of the other, adding the same element as the head of each yields lists that are permutations of each other: `l₁ ~ l₂ → x::l₁ ~ x::l₂`.

```text
List.Perm.swap.{u} {α : Type u} (x y : α) (l : List α) :
  (y :: x :: l).Perm (x :: y :: l)
```

If two lists are identical except for having their first two elements swapped, then they are permutations of each other: `x::y::l ~ y::x::l`.

```text
List.Perm.trans.{u} {α : Type u} {l₁ l₂ l₃ : List α} :
  l₁.Perm l₂ → l₂.Perm l₃ → l₁.Perm l₃
```

Permutation is transitive: `l₁ ~ l₂ → l₂ ~ l₃ → l₁ ~ l₃`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**List Permutation**

<a id="List____FLQQ_term______FLQQ_"></a>

```ebnf
term ::= ...
    | term ~ term
```

Two lists are permutations of each other if they contain the same elements, each occurring the same number of times but not necessarily in the same order.

One list can be proven to be a permutation of another by showing how to transform one into the other by repeatedly swapping adjacent elements.

`List.isPerm` is a Boolean equivalent of this relation.

This syntax is only available when the `List` namespace is opened.

<a id="List___Pairwise___nil"></a>

**inductive predicate**

```text
List.Pairwise.{u} {α : Type u} (R : α → α → Prop) : List α → Prop
```

Each element of a list is related to all later elements of the list by `R`.

`Pairwise R l` means that all the elements of `l` with earlier indexes are `R`-related to all the elements with later indexes.

For example, `Pairwise (· ≠ ·) l` asserts that `l` has no duplicates, and `Pairwise (· < ·) l` asserts that `l` is (strictly) sorted.

Examples:

- `Pairwise (· < ·) [1, 2, 3] ↔ (1 < 2 ∧ 1 < 3) ∧ 2 < 3`
- `Pairwise (· = ·) [1, 2, 3] = False`
- `Pairwise (· ≠ ·) [1, 2, 3] = True`

**Constructors**

```text
List.Pairwise.nil.{u} {α : Type u} {R : α → α → Prop} :
  List.Pairwise R []
```

All elements of the empty list are vacuously pairwise related.

```text
List.Pairwise.cons.{u} {α : Type u} {R : α → α → Prop}
  {a : α} {l : List α} :
  (∀ (a' : α), a' ∈ l → R a a') →
    List.Pairwise R l → List.Pairwise R (a :: l)
```

A nonempty list is pairwise related with `R` if the head is related to every element of the tail and the tail is itself pairwise related.

That is, `a :: l` is `Pairwise R` if:

- `R` relates `a` to every element of `l`
- `l` is `Pairwise R`.

<a id="List___Nodup"></a>

**def**

```text
List.Nodup.{u} {α : Type u} : List α → Prop
```

The list has no duplicates: it contains every element at most once.

It is defined as `Pairwise (· ≠ ·)`: each element is unequal to all other elements.

<a id="List___Lex___nil"></a>

**inductive predicate**

```text
List.Lex.{u} {α : Type u} (r : α → α → Prop) (as bs : List α) : Prop
```

Lexicographic ordering for lists with respect to an ordering of elements.

`as` is lexicographically smaller than `bs` if

- `as` is empty and `bs` is non-empty, or
- both `as` and `bs` are non-empty, and the head of `as` is less than the head of `bs` according to `r`, or
- both `as` and `bs` are non-empty, their heads are equal, and the tail of `as` is less than the tail of `bs`.

**Constructors**

```text
List.Lex.nil.{u} {α : Type u} {r : α → α → Prop} {a : α}
  {l : List α} : List.Lex r [] (a :: l)
```

`[]` is the smallest element in the lexicographic order.

```text
List.Lex.rel.{u} {α : Type u} {r : α → α → Prop} {a₁ : α}
  {l₁ : List α} {a₂ : α} {l₂ : List α} (h : r a₁ a₂) :
  List.Lex r (a₁ :: l₁) (a₂ :: l₂)
```

If the head of the first list is smaller than the head of the second, then the first list is lexicographically smaller than the second list.

```text
List.Lex.cons.{u} {α : Type u} {r : α → α → Prop} {a : α}
  {l₁ l₂ : List α} (h : List.Lex r l₁ l₂) :
  List.Lex r (a :: l₁) (a :: l₂)
```

If two lists have the same head, then their tails determine their lexicographic order. If the tail of the first list is lexicographically smaller than the tail of the second list, then the entire first list is lexicographically smaller than the entire second list.

<a id="List___Mem___head"></a>

**inductive predicate**

```text
List.Mem.{u} {α : Type u} (a : α) : List α → Prop
```

List membership, typically accessed via the `∈` operator.

`a ∈ l` means that `a` is an element of the list `l`. Elements are compared according to Lean's logical equality.

The related function `List.elem` is a Boolean membership test that uses a `BEq α` instance.

Examples:

- `a ∈ [x, y, z] ↔ a = x ∨ a = y ∨ a = z`

**Constructors**

```text
List.Mem.head.{u} {α : Type u} {a : α} (as : List α) :
  List.Mem a (a :: as)
```

The head of a list is a member: `a ∈ a :: as`.

```text
List.Mem.tail.{u} {α : Type u} {a : α} (b : α)
  {as : List α} : List.Mem a as → List.Mem a (b :: as)
```

A member of the tail of a list is a member of the list: `a ∈ l → a ∈ b :: l`.

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Constructing-Lists"></a>
#### 20.15.3.2. Constructing Lists

<a id="List___singleton"></a>

**def**

```text
List.singleton.{u} {α : Type u} (a : α) : List α
```

Constructs a single-element list.

Examples:

- `List.singleton 5 = [5]`.
- `List.singleton "green" = ["green"]`.
- `List.singleton [1, 2, 3] = [[1, 2, 3]]`

<a id="List___concat"></a>

**def**

```text
List.concat.{u} {α : Type u} : List α → α → List α
```

Adds an element to the *end* of a list.

The added element is the last element of the resulting list.

Examples:

- `List.concat ["red", "yellow"] "green" = ["red", "yellow", "green"]`
- `List.concat [1, 2, 3] 4 = [1, 2, 3, 4]`
- `List.concat [] () = [()]`

<a id="List___replicate"></a>

**def**

```text
List.replicate.{u} {α : Type u} (n : Nat) (a : α) : List α
```

Creates a list that contains `n` copies of `a`.

- `List.replicate 5 "five" = ["five", "five", "five", "five", "five"]`
- `List.replicate 0 "zero" = []`
- `List.replicate 2 ' ' = [' ', ' ']`

<a id="List___replicateTR"></a>

**def**

```text
List.replicateTR.{u} {α : Type u} (n : Nat) (a : α) : List α
```

Creates a list that contains `n` copies of `a`.

This is a tail-recursive version of `List.replicate`.

- `List.replicateTR 5 "five" = ["five", "five", "five", "five", "five"]`
- `List.replicateTR 0 "zero" = []`
- `List.replicateTR 2 ' ' = [' ', ' ']`

<a id="List___ofFn"></a>

**def**

```text
List.ofFn.{u_1} {α : Type u_1} {n : Nat} (f : Fin n → α) : List α
```

Creates a list by applying `f` to each potential index in order, starting at `0`.

Examples:

- `List.ofFn (n := 3) toString = ["0", "1", "2"]`
- `List.ofFn (fun i => #["red", "green", "blue"].get i.val i.isLt) = ["red", "green", "blue"]`

<a id="List___append"></a>

**def**

```text
List.append.{u_1} {α : Type u_1} (xs ys : List α) : List α
```

Appends two lists. Normally used via the `++` operator.

Appending lists takes time proportional to the length of the first list: `O(|xs|)`.

Examples:

- `[1, 2, 3] ++ [4, 5] = [1, 2, 3, 4, 5]`.
- `[] ++ [4, 5] = [4, 5]`.
- `[1, 2, 3] ++ [] = [1, 2, 3]`.

<a id="List___appendTR"></a>

**def**

```text
List.appendTR.{u} {α : Type u} (as bs : List α) : List α
```

Appends two lists. Normally used via the `++` operator.

Appending lists takes time proportional to the length of the first list: `O(|xs|)`.

This is a tail-recursive version of `List.append`.

Examples:

- `[1, 2, 3] ++ [4, 5] = [1, 2, 3, 4, 5]`.
- `[] ++ [4, 5] = [4, 5]`.
- `[1, 2, 3] ++ [] = [1, 2, 3]`.

<a id="List___range"></a>

**def**

```text
List.range (n : Nat) : List Nat
```

Returns a list of the numbers from `0` to `n` exclusive, in increasing order.

`O(n)`.

Examples:

- `range 5 = [0, 1, 2, 3, 4]`
- `range 0 = []`
- `range 2 = [0, 1]`

<a id="List___range___"></a>

**def**

```text
List.range' (start len : Nat) (step : Nat := 1) : List Nat
```

Returns a list of the numbers with the given length `len`, starting at `start` and increasing by `step` at each element.

In other words, `List.range' start len step` is `[start, start+step, ..., start+(len-1)*step]`.

Examples:

- `List.range' 0 3 (step := 1) = [0, 1, 2]`
- `List.range' 0 3 (step := 2) = [0, 2, 4]`
- `List.range' 0 4 (step := 2) = [0, 2, 4, 6]`
- `List.range' 3 4 (step := 2) = [3, 5, 7, 9]`

<a id="List___range___TR"></a>

**def**

```text
List.range'TR (s n : Nat) (step : Nat := 1) : List Nat
```

Returns a list of the numbers with the given length `len`, starting at `start` and increasing by `step` at each element.

In other words, `List.range'TR start len step` is `[start, start+step, ..., start+(len-1)*step]`.

This is a tail-recursive version of `List.range'`.

Examples:

- `List.range'TR 0 3 (step := 1) = [0, 1, 2]`
- `List.range'TR 0 3 (step := 2) = [0, 2, 4]`
- `List.range'TR 0 4 (step := 2) = [0, 2, 4, 6]`
- `List.range'TR 3 4 (step := 2) = [3, 5, 7, 9]`

<a id="List___finRange"></a>

**def**

```text
List.finRange (n : Nat) : List (Fin n)
```

Lists all elements of `Fin n` in order, starting at `0`.

Examples:

- `List.finRange 0 = ([] : List (Fin 0))`
- `List.finRange 2 = ([0, 1] : List (Fin 2))`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Length"></a>
#### 20.15.3.3. Length

<a id="List___length"></a>

**def**

```text
List.length.{u_1} {α : Type u_1} : List α → Nat
```

The length of a list.

This function is overridden in the compiler to `lengthTR`, which uses constant stack space.

Examples:

- `([] : List String).length = 0`
- `["green", "brown"].length = 2`

<a id="List___lengthTR"></a>

**def**

```text
List.lengthTR.{u_1} {α : Type u_1} (as : List α) : Nat
```

The length of a list.

This is a tail-recursive version of `List.length`, used to implement `List.length` without running out of stack space.

Examples:

- `([] : List String).lengthTR = 0`
- `["green", "brown"].lengthTR = 2`

<a id="List___isEmpty"></a>

**def**

```text
List.isEmpty.{u} {α : Type u} : List α → Bool
```

Checks whether a list is empty.

`O(1)`.

Examples:

- `[].isEmpty = true`
- `["grape"].isEmpty = false`
- `["apple", "banana"].isEmpty = false`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Head-and-Tail"></a>
#### 20.15.3.4. Head and Tail

<a id="List___head"></a>

**def**

```text
List.head.{u} {α : Type u} (as : List α) : as ≠ [] → α
```

Returns the first element of a non-empty list.

<a id="List___head___"></a>

**def**

```text
List.head?.{u} {α : Type u} : List α → Option α
```

Returns the first element in the list, if there is one. Returns `none` if the list is empty.

Use `List.headD` to provide a fallback value for empty lists, or `List.head!` to panic on empty lists.

Examples:

- `([] : List Nat).head? = none`
- `[3, 2, 1].head? = some 3`

<a id="List___headD"></a>

**def**

```text
List.headD.{u} {α : Type u} (as : List α) (fallback : α) : α
```

Returns the first element in the list if there is one, or `fallback` if the list is empty.

Use `List.head?` to return an `Option`, and `List.head!` to panic on empty lists.

Examples:

- `[].headD "empty" = "empty"`
- `[].headD 2 = 2`
- `["head", "shoulders", "knees"].headD "toes" = "head"`

<a id="List___head___-next"></a>

**def**

```text
List.head!.{u_1} {α : Type u_1} [Inhabited α] : List α → α
```

Returns the first element in the list. If the list is empty, panics and returns `default`.

Safer alternatives include:

- `List.head`, which requires a proof that the list is non-empty,
- `List.head?`, which returns an `Option`, and
- `List.headD`, which returns an explicitly-provided fallback value on empty lists.

<a id="List___tail"></a>

**def**

```text
List.tail.{u} {α : Type u} : List α → List α
```

Drops the first element of a nonempty list, returning the tail. Returns `[]` when the argument is empty.

Examples:

- `["apple", "banana", "grape"].tail = ["banana", "grape"]`
- `["apple"].tail = []`
- `([] : List String).tail = []`

<a id="List___tail___"></a>

**def**

```text
List.tail!.{u_1} {α : Type u_1} : List α → List α
```

Drops the first element of a nonempty list, returning the tail. If the list is empty, this function panics when executed and returns the empty list.

Safer alternatives include

- `tail`, which returns the empty list without panicking,
- `tail?`, which returns an `Option`, and
- `tailD`, which returns a fallback value when passed the empty list.

Examples:

- `["apple", "banana", "grape"].tail! = ["banana", "grape"]`
- `["banana", "grape"].tail! = ["grape"]`

<a id="List___tail___-next"></a>

**def**

```text
List.tail?.{u} {α : Type u} : List α → Option (List α)
```

Drops the first element of a nonempty list, returning the tail. Returns `none` when the argument is empty.

Alternatives include `List.tail`, which returns the empty list on failure, `List.tailD`, which returns an explicit fallback value, and `List.tail!`, which panics on the empty list.

Examples:

- `["apple", "banana", "grape"].tail? = some ["banana", "grape"]`
- `["apple"].tail? = some []`
- `([] : List String).tail = none`

<a id="List___tailD"></a>

**def**

```text
List.tailD.{u} {α : Type u} (l fallback : List α) : List α
```

Drops the first element of a nonempty list, returning the tail. Returns `none` when the argument is empty.

Alternatives include `List.tail`, which returns the empty list on failure, `List.tail?`, which returns an `Option`, and `List.tail!`, which panics on the empty list.

Examples:

- `["apple", "banana", "grape"].tailD ["orange"] = ["banana", "grape"]`
- `["apple"].tailD ["orange"] = []`
- `[].tailD ["orange"] = ["orange"]`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Lookups"></a>
#### 20.15.3.5. Lookups

<a id="List___get"></a>

**def**

```text
List.get.{u} {α : Type u} (as : List α) : Fin as.length → α
```

Returns the element at the provided index, counting from `0`.

In other words, for `i : Fin as.length`, `as.get i` returns the `i`'th element of the list `as`. Because the index is a `Fin` bounded by the list's length, the index will never be out of bounds.

Examples:

- `["spring", "summer", "fall", "winter"].get (2 : Fin 4) = "fall"`
- `["spring", "summer", "fall", "winter"].get (0 : Fin 4) = "spring"`

<a id="List___getD"></a>

**def**

```text
List.getD.{u_1} {α : Type u_1} (as : List α) (i : Nat) (fallback : α) :
  α
```

Returns the element at the provided index, counting from `0`. Returns `fallback` if the index is out of bounds.

To return an `Option` depending on whether the index is in bounds, use `as[i]?`. To panic if the index is out of bounds, use `as[i]!`.

Examples:

- `["spring", "summer", "fall", "winter"].getD 2 "never" = "fall"`
- `["spring", "summer", "fall", "winter"].getD 0 "never" = "spring"`
- `["spring", "summer", "fall", "winter"].getD 4 "never" = "never"`

<a id="List___getLast"></a>

**def**

```text
List.getLast.{u} {α : Type u} (as : List α) : as ≠ [] → α
```

Returns the last element of a non-empty list.

Examples:

- `["circle", "rectangle"].getLast (by decide) = "rectangle"`
- `["circle"].getLast (by decide) = "circle"`

<a id="List___getLast___"></a>

**def**

```text
List.getLast?.{u} {α : Type u} : List α → Option α
```

Returns the last element in the list, or `none` if the list is empty.

Alternatives include `List.getLastD`, which takes a fallback value for empty lists, and `List.getLast!`, which panics on empty lists.

Examples:

- `["circle", "rectangle"].getLast? = some "rectangle"`
- `["circle"].getLast? = some "circle"`
- `([] : List String).getLast? = none`

<a id="List___getLastD"></a>

**def**

```text
List.getLastD.{u} {α : Type u} (as : List α) (fallback : α) : α
```

Returns the last element in the list, or `fallback` if the list is empty.

Alternatives include `List.getLast?`, which returns an `Option`, and `List.getLast!`, which panics on empty lists.

Examples:

- `["circle", "rectangle"].getLastD "oval" = "rectangle"`
- `["circle"].getLastD "oval" = "circle"`
- `([] : List String).getLastD "oval" = "oval"`

<a id="List___getLast___-next"></a>

**def**

```text
List.getLast!.{u_1} {α : Type u_1} [Inhabited α] : List α → α
```

Returns the last element in the list. Panics and returns `default` if the list is empty.

Safer alternatives include:

- `getLast?`, which returns an `Option`,
- `getLastD`, which takes a fallback value for empty lists, and
- `getLast`, which requires a proof that the list is non-empty.

Examples:

- `["circle", "rectangle"].getLast! = "rectangle"`
- `["circle"].getLast! = "circle"`

<a id="List___lookup"></a>

**def**

```text
List.lookup.{u, v} {α : Type u} {β : Type v} [BEq α] :
  α → List (α × β) → Option β
```

Treats the list as an association list that maps keys to values, returning the first value whose key is equal to the specified key.

`O(|l|)`.

Examples:

- `[(1, "one"), (3, "three"), (3, "other")].lookup 3 = some "three"`
- `[(1, "one"), (3, "three"), (3, "other")].lookup 2 = none`

<a id="List___max___"></a>

**def**

```text
List.max?.{u} {α : Type u} [Max α] : List α → Option α
```

Returns the largest element of the list if it is not empty, or `none` if it is empty.

Examples:

- `[].max? = none`
- `[4].max? = some 4`
- `[1, 4, 2, 10, 6].max? = some 10`

<a id="List___min___"></a>

**def**

```text
List.min?.{u} {α : Type u} [Min α] : List α → Option α
```

Returns the smallest element of the list if it is not empty, or `none` if it is empty.

Examples:

- `[].min? = none`
- `[4].min? = some 4`
- `[1, 4, 2, 10, 6].min? = some 1`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Queries"></a>
#### 20.15.3.6. Queries

<a id="List___count"></a>

**def**

```text
List.count.{u} {α : Type u} [BEq α] (a : α) : List α → Nat
```

Counts the number of times an element occurs in a list.

Examples:

- `[1, 1, 2, 3, 5].count 1 = 2`
- `[1, 1, 2, 3, 5].count 5 = 1`
- `[1, 1, 2, 3, 5].count 4 = 0`

<a id="List___countP"></a>

**def**

```text
List.countP.{u} {α : Type u} (p : α → Bool) (l : List α) : Nat
```

Counts the number of elements in the list `l` that satisfy the Boolean predicate `p`.

Examples:

- `[1, 2, 3, 4, 5].countP (· % 2 == 0) = 2`
- `[1, 2, 3, 4, 5].countP (· < 5) = 4`
- `[1, 2, 3, 4, 5].countP (· > 5) = 0`

<a id="List___idxOf"></a>

**def**

```text
List.idxOf.{u} {α : Type u} [BEq α] (a : α) : List α → Nat
```

Returns the index of the first element equal to `a`, or the length of the list if no element is equal to `a`.

Examples:

- `["carrot", "potato", "broccoli"].idxOf "carrot" = 0`
- `["carrot", "potato", "broccoli"].idxOf "broccoli" = 2`
- `["carrot", "potato", "broccoli"].idxOf "tomato" = 3`
- `["carrot", "potato", "broccoli"].idxOf "anything else" = 3`

<a id="List___idxOf___"></a>

**def**

```text
List.idxOf?.{u} {α : Type u} [BEq α] (a : α) : List α → Option Nat
```

Returns the index of the first element equal to `a`, or `none` if no element is equal to `a`.

Examples:

- `["carrot", "potato", "broccoli"].idxOf? "carrot" = some 0`
- `["carrot", "potato", "broccoli"].idxOf? "broccoli" = some 2`
- `["carrot", "potato", "broccoli"].idxOf? "tomato" = none`
- `["carrot", "potato", "broccoli"].idxOf? "anything else" = none`

<a id="List___finIdxOf___"></a>

**def**

```text
List.finIdxOf?.{u} {α : Type u} [BEq α] (a : α) (l : List α) :
  Option (Fin l.length)
```

Returns the index of the first element equal to `a`, or the length of the list if no element is equal to `a`. The index is returned as a `Fin`, which guarantees that it is in bounds.

Examples:

- `["carrot", "potato", "broccoli"].finIdxOf? "carrot" = some 0`
- `["carrot", "potato", "broccoli"].finIdxOf? "broccoli" = some 2`
- `["carrot", "potato", "broccoli"].finIdxOf? "tomato" = none`
- `["carrot", "potato", "broccoli"].finIdxOf? "anything else" = none`

<a id="List___find___"></a>

**def**

```text
List.find?.{u} {α : Type u} (p : α → Bool) : List α → Option α
```

Returns the first element of the list for which the predicate `p` returns `true`, or `none` if no such element is found.

`O(|l|)`.

Examples:

- `[7, 6, 5, 8, 1, 2, 6].find? (· < 5) = some 1`
- `[7, 6, 5, 8, 1, 2, 6].find? (· < 1) = none`

<a id="List___findFinIdx___"></a>

**def**

```text
List.findFinIdx?.{u} {α : Type u} (p : α → Bool) (l : List α) :
  Option (Fin l.length)
```

Returns the index of the first element for which `p` returns `true`, or `none` if there is no such element. The index is returned as a `Fin`, which guarantees that it is in bounds.

Examples:

- `[7, 6, 5, 8, 1, 2, 6].findFinIdx? (· < 5) = some (4 : Fin 7)`
- `[7, 6, 5, 8, 1, 2, 6].findFinIdx? (· < 1) = none`

<a id="List___findIdx"></a>

**def**

```text
List.findIdx.{u} {α : Type u} (p : α → Bool) (l : List α) : Nat
```

Returns the index of the first element for which `p` returns `true`, or the length of the list if there is no such element.

Examples:

- `[7, 6, 5, 8, 1, 2, 6].findIdx (· < 5) = 4`
- `[7, 6, 5, 8, 1, 2, 6].findIdx (· < 1) = 7`

<a id="List___findIdx___"></a>

**def**

```text
List.findIdx?.{u} {α : Type u} (p : α → Bool) (l : List α) : Option Nat
```

Returns the index of the first element for which `p` returns `true`, or `none` if there is no such element.

Examples:

- `[7, 6, 5, 8, 1, 2, 6].findIdx (· < 5) = some 4`
- `[7, 6, 5, 8, 1, 2, 6].findIdx (· < 1) = none`

<a id="List___findM___"></a>

**def**

```text
List.findM?.{u} {m : Type → Type u} [Monad m] {α : Type}
  (p : α → m Bool) : List α → m (Option α)
```

Returns the first element of the list for which the monadic predicate `p` returns `true`, or `none` if no such element is found. Elements of the list are checked in order.

`O(|l|)`.

Example:

```proofscript
#eval [7, 6, 5, 8, 1, 2, 6].findM? fun i => do
  if i < 5 then
    return true
  if i ≤ 6 then
    IO.println s!"Almost! {i}"
  return false
```

```proofscript
Almost! 6
Almost! 5
```

```proofscript
some 1
```

<a id="List___findSome___"></a>

**def**

```text
List.findSome?.{u, v} {α : Type u} {β : Type v} (f : α → Option β) :
  List α → Option β
```

Returns the first non-`none` result of applying `f` to each element of the list in order. Returns `none` if `f` returns `none` for all elements of the list.

`O(|l|)`.

Examples:

- `[7, 6, 5, 8, 1, 2, 6].findSome? (fun x => if x < 5 then some (10 * x) else none) = some 10`
- `[7, 6, 5, 8, 1, 2, 6].findSome? (fun x => if x < 1 then some (10 * x) else none) = none`

<a id="List___findSomeM___"></a>

**def**

```text
List.findSomeM?.{u, v, w} {m : Type u → Type v} [Monad m] {α : Type w}
  {β : Type u} (f : α → m (Option β)) : List α → m (Option β)
```

Returns the first non-`none` result of applying the monadic function `f` to each element of the list, in order. Returns `none` if `f` returns `none` for all elements.

`O(|l|)`.

Example:

```proofscript
#eval [7, 6, 5, 8, 1, 2, 6].findSomeM? fun i => do
  if i < 5 then
    return some (i * 10)
  if i ≤ 6 then
    IO.println s!"Almost! {i}"
  return none
```

```proofscript
Almost! 6
Almost! 5
```

```proofscript
some 10
```

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Conversions"></a>
#### 20.15.3.7. Conversions

<a id="List___toArray"></a>

**def**

```text
List.toArray.{u_1} {α : Type u_1} (xs : List α) : Array α
```

Converts a `List α` into an `Array α`.

`O(|xs|)`. At runtime, this operation is implemented by `List.toArrayImpl` and takes time linear in the length of the list. `List.toArray` should be used instead of `Array.mk`.

Examples:

- `[1, 2, 3].toArray = #[1, 2, 3]`
- `["monday", "wednesday", friday"].toArray = #["monday", "wednesday", friday"].`

<a id="List___toArrayImpl"></a>

**def**

```text
List.toArrayImpl.{u_1} {α : Type u_1} (xs : List α) : Array α
```

Converts a `List α` into an `Array α` by repeatedly pushing elements from the list onto an empty array. `O(|xs|)`.

Use `List.toArray` instead of calling this function directly. At runtime, this operation implements both `List.toArray` and `Array.mk`.

<a id="List___toByteArray"></a>

**def**

```text
List.toByteArray (bs : List UInt8) : ByteArray
```

Converts a list of bytes into a `ByteArray`.

<a id="List___toFloatArray"></a>

**def**

```text
List.toFloatArray (ds : List Float) : FloatArray
```

Converts a list of floats into a `FloatArray`.

<a id="List___toString"></a>

**def**

```text
List.toString.{u_1} {α : Type u_1} [ToString α] : List α → String
```

Converts a list into a string, using `ToString.toString` to convert its elements.

The resulting string resembles list literal syntax, with the elements separated by `", "` and enclosed in square brackets.

The resulting string may not be valid Lean syntax, because there's no such expectation for `ToString` instances.

Examples:

- `[1, 2, 3].toString = "[1, 2, 3]"`
- `["cat", "dog"].toString = "[cat, dog]"`
- `["cat", "dog", ""].toString = "[cat, dog, ]"`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Modification"></a>
#### 20.15.3.8. Modification

<a id="List___set"></a>

**def**

```text
List.set.{u_1} {α : Type u_1} (l : List α) (n : Nat) (a : α) : List α
```

Replaces the value at (zero-based) index `n` in `l` with `a`. If the index is out of bounds, then the list is returned unmodified.

Examples:

- `["water", "coffee", "soda", "juice"].set 1 "tea" = ["water", "tea", "soda", "juice"]`
- `["water", "coffee", "soda", "juice"].set 4 "tea" = ["water", "coffee", "soda", "juice"]`

<a id="List___setTR"></a>

**def**

```text
List.setTR.{u_1} {α : Type u_1} (l : List α) (n : Nat) (a : α) : List α
```

Replaces the value at (zero-based) index `n` in `l` with `a`. If the index is out of bounds, then the list is returned unmodified.

This is a tail-recursive version of `List.set` that's used at runtime.

Examples:

- `["water", "coffee", "soda", "juice"].set 1 "tea" = ["water", "tea", "soda", "juice"]`
- `["water", "coffee", "soda", "juice"].set 4 "tea" = ["water", "coffee", "soda", "juice"]`

<a id="List___modify"></a>

**def**

```text
List.modify.{u} {α : Type u} (l : List α) (i : Nat) (f : α → α) : List α
```

Replaces the element at the given index, if it exists, with the result of applying `f` to it. If the index is invalid, the list is returned unmodified.

Examples:

- `[1, 2, 3].modify 0 (· * 10) = [10, 2, 3]`
- `[1, 2, 3].modify 2 (· * 10) = [1, 2, 30]`
- `[1, 2, 3].modify 3 (· * 10) = [1, 2, 3]`

<a id="List___modifyTR"></a>

**def**

```text
List.modifyTR.{u_1} {α : Type u_1} (l : List α) (i : Nat) (f : α → α) :
  List α
```

Replaces the element at the given index, if it exists, with the result of applying `f` to it.

This is a tail-recursive version of `List.modify`.

Examples:

- `[1, 2, 3].modifyTR 0 (· * 10) = [10, 2, 3]`
- `[1, 2, 3].modifyTR 2 (· * 10) = [1, 2, 30]`
- `[1, 2, 3].modifyTR 3 (· * 10) = [1, 2, 3]`

<a id="List___modifyHead"></a>

**def**

```text
List.modifyHead.{u} {α : Type u} (f : α → α) : List α → List α
```

Replace the head of the list with the result of applying `f` to it. Returns the empty list if the list is empty.

Examples:

- `[1, 2, 3].modifyHead (· * 10) = [10, 2, 3]`
- `[].modifyHead (· * 10) = []`

<a id="List___modifyTailIdx"></a>

**def**

```text
List.modifyTailIdx.{u} {α : Type u} (l : List α) (i : Nat)
  (f : List α → List α) : List α
```

Replaces the `n`th tail of `l` with the result of applying `f` to it. Returns the input without using `f` if the index is larger than the length of the List.

Examples:

```proofscript
["circle", "square", "triangle"].modifyTailIdx 1 List.reverse
```

```proofscript
["circle", "triangle", "square"]
```

```proofscript
["circle", "square", "triangle"].modifyTailIdx 1 (fun xs => xs ++ xs)
```

```proofscript
["circle", "square", "triangle", "square", "triangle"]
```

```proofscript
["circle", "square", "triangle"].modifyTailIdx 2 (fun xs => xs ++ xs)
```

```proofscript
["circle", "square", "triangle", "triangle"]
```

```proofscript
["circle", "square", "triangle"].modifyTailIdx 5 (fun xs => xs ++ xs)
```

```proofscript
["circle", "square", "triangle"]
```

<a id="List___erase"></a>

**def**

```text
List.erase.{u_1} {α : Type u_1} [BEq α] : List α → α → List α
```

Removes the first occurrence of `a` from `l`. If `a` does not occur in `l`, the list is returned unmodified.

`O(|l|)`.

Examples:

- `[1, 5, 3, 2, 5].erase 5 = [1, 3, 2, 5]`
- `[1, 5, 3, 2, 5].erase 6 = [1, 5, 3, 2, 5]`

<a id="List___eraseTR"></a>

**def**

```text
List.eraseTR.{u_1} {α : Type u_1} [BEq α] (l : List α) (a : α) : List α
```

Removes the first occurrence of `a` from `l`. If `a` does not occur in `l`, the list is returned unmodified.

`O(|l|)`.

This is a tail-recursive version of `List.erase`, used in runtime code.

Examples:

- `[1, 5, 3, 2, 5].eraseTR 5 = [1, 3, 2, 5]`
- `[1, 5, 3, 2, 5].eraseTR 6 = [1, 5, 3, 2, 5]`

<a id="List___eraseDups"></a>

**def**

```text
List.eraseDups.{u_1} {α : Type u_1} [BEq α] (as : List α) : List α
```

Erases duplicated elements in the list, keeping the first occurrence of duplicated elements.

`O(|l|^2)`.

Examples:

- `[1, 3, 2, 2, 3, 5].eraseDups = [1, 3, 2, 5]`
- `["red", "green", "green", "blue"].eraseDups = ["red", "green", "blue"]`

<a id="List___eraseIdx"></a>

**def**

```text
List.eraseIdx.{u} {α : Type u} (l : List α) (i : Nat) : List α
```

Removes the element at the specified index. If the index is out of bounds, the list is returned unmodified.

`O(i)`.

Examples:

- `[0, 1, 2, 3, 4].eraseIdx 0 = [1, 2, 3, 4]`
- `[0, 1, 2, 3, 4].eraseIdx 1 = [0, 2, 3, 4]`
- `[0, 1, 2, 3, 4].eraseIdx 5 = [0, 1, 2, 3, 4]`

<a id="List___eraseIdxTR"></a>

**def**

```text
List.eraseIdxTR.{u_1} {α : Type u_1} (l : List α) (n : Nat) : List α
```

Removes the element at the specified index. If the index is out of bounds, the list is returned unmodified.

`O(i)`.

This is a tail-recursive version of `List.eraseIdx`, used at runtime.

Examples:

- `[0, 1, 2, 3, 4].eraseIdxTR 0 = [1, 2, 3, 4]`
- `[0, 1, 2, 3, 4].eraseIdxTR 1 = [0, 2, 3, 4]`
- `[0, 1, 2, 3, 4].eraseIdxTR 5 = [0, 1, 2, 3, 4]`

<a id="List___eraseP"></a>

**def**

```text
List.eraseP.{u} {α : Type u} (p : α → Bool) : List α → List α
```

Removes the first element of a list for which `p` returns `true`. If no element satisfies `p`, then the list is returned unchanged.

Examples:

- `[2, 1, 2, 1, 3, 4].eraseP (· < 2) = [2, 2, 1, 3, 4]`
- `[2, 1, 2, 1, 3, 4].eraseP (· > 2) = [2, 1, 2, 1, 4]`
- `[2, 1, 2, 1, 3, 4].eraseP (· > 8) = [2, 1, 2, 1, 3, 4]`

<a id="List___erasePTR"></a>

**def**

```text
List.erasePTR.{u_1} {α : Type u_1} (p : α → Bool) (l : List α) : List α
```

Removes the first element of a list for which `p` returns `true`. If no element satisfies `p`, then the list is returned unchanged.

This is a tail-recursive version of `eraseP`, used at runtime.

Examples:

- `[2, 1, 2, 1, 3, 4].erasePTR (· < 2) = [2, 2, 1, 3, 4]`
- `[2, 1, 2, 1, 3, 4].erasePTR (· > 2) = [2, 1, 2, 1, 4]`
- `[2, 1, 2, 1, 3, 4].erasePTR (· > 8) = [2, 1, 2, 1, 3, 4]`

<a id="List___eraseReps"></a>

**def**

```text
List.eraseReps.{u_1} {α : Type u_1} [BEq α] (as : List α) : List α
```

Erases repeated elements, keeping the first element of each run.

`O(|l|)`.

Example:

- `[1, 3, 2, 2, 2, 3, 3, 5].eraseReps = [1, 3, 2, 3, 5]`

<a id="List___extract"></a>

**def**

```text
List.extract.{u} {α : Type u} (l : List α) (start : Nat := 0)
  (stop : Nat := l.length) : List α
```

Returns the slice of `l` from indices `start` (inclusive) to `stop` (exclusive).

Examples:

- [0, 1, 2, 3, 4, 5].extract 1 2 = [1]
- [0, 1, 2, 3, 4, 5].extract 2 2 = []
- [0, 1, 2, 3, 4, 5].extract 2 4 = [2, 3]
- [0, 1, 2, 3, 4, 5].extract 2 = [2, 3, 4, 5]
- [0, 1, 2, 3, 4, 5].extract (stop := 2) = [0, 1]

<a id="List___removeAll"></a>

**def**

```text
List.removeAll.{u} {α : Type u} [BEq α] (xs ys : List α) : List α
```

Removes all elements of `xs` that are present in `ys`.

`O(|xs| * |ys|)`.

Examples:

- `[1, 1, 5, 1, 2, 4, 5].removeAll [1, 2, 2] = [5, 4, 5]`
- `[1, 2, 3, 2].removeAll [] = [1, 2, 3, 2]`
- `[1, 2, 3, 2].removeAll [3] = [1, 2, 2]`

<a id="List___replace"></a>

**def**

```text
List.replace.{u} {α : Type u} [BEq α] (l : List α) (a b : α) : List α
```

Replaces the first element of the list `l` that is equal to `a` with `b`. If no element is equal to `a`, then the list is returned unchanged.

`O(|l|)`.

Examples:

- `[1, 4, 2, 3, 3, 7].replace 3 6 = [1, 4, 2, 6, 3, 7]`
- `[1, 4, 2, 3, 3, 7].replace 5 6 = [1, 4, 2, 3, 3, 7]`

<a id="List___replaceTR"></a>

**def**

```text
List.replaceTR.{u_1} {α : Type u_1} [BEq α] (l : List α) (b c : α) :
  List α
```

Replaces the first element of the list `l` that is equal to `a` with `b`. If no element is equal to `a`, then the list is returned unchanged.

`O(|l|)`. This is a tail-recursive version of `List.replace` that's used in runtime code.

Examples:

- `[1, 4, 2, 3, 3, 7].replaceTR 3 6 = [1, 4, 2, 6, 3, 7]`
- `[1, 4, 2, 3, 3, 7].replaceTR 5 6 = [1, 4, 2, 3, 3, 7]`

<a id="List___reverse"></a>

**def**

```text
List.reverse.{u} {α : Type u} (as : List α) : List α
```

Reverses a list.

`O(|as|)`.

Because of the “functional but in place” optimization implemented by Lean's compiler, this function does not allocate a new list when its reference to the input list is unshared: it simply walks the linked list and reverses all the node pointers.

Examples:

- `[1, 2, 3, 4].reverse = [4, 3, 2, 1]`
- `[].reverse = []`

<a id="List___flatten"></a>

**def**

```text
List.flatten.{u_1} {α : Type u_1} : List (List α) → List α
```

Concatenates a list of lists into a single list, preserving the order of the elements.

`O(|flatten L|)`.

Examples:

- `[["a"], ["b", "c"]].flatten = ["a", "b", "c"]`
- `[["a"], [], ["b", "c"], ["d", "e", "f"]].flatten = ["a", "b", "c", "d", "e", "f"]`

<a id="List___flattenTR"></a>

**def**

```text
List.flattenTR.{u_1} {α : Type u_1} (l : List (List α)) : List α
```

Concatenates a list of lists into a single list, preserving the order of the elements.

`O(|flatten L|)`. This is a tail-recursive version of `List.flatten`, used in runtime code.

Examples:

- `[["a"], ["b", "c"]].flattenTR = ["a", "b", "c"]`
- `[["a"], [], ["b", "c"], ["d", "e", "f"]].flattenTR = ["a", "b", "c", "d", "e", "f"]`

<a id="List___rotateLeft"></a>

**def**

```text
List.rotateLeft.{u} {α : Type u} (xs : List α) (i : Nat := 1) : List α
```

Rotates the elements of `xs` to the left, moving `i % xs.length` elements from the start of the list to the end.

`O(|xs|)`.

Examples:

- `[1, 2, 3, 4, 5].rotateLeft 3 = [4, 5, 1, 2, 3]`
- `[1, 2, 3, 4, 5].rotateLeft 5 = [1, 2, 3, 4, 5]`
- `[1, 2, 3, 4, 5].rotateLeft 1 = [2, 3, 4, 5, 1]`

<a id="List___rotateRight"></a>

**def**

```text
List.rotateRight.{u} {α : Type u} (xs : List α) (i : Nat := 1) : List α
```

Rotates the elements of `xs` to the right, moving `i % xs.length` elements from the end of the list to the start.

After rotation, the element at `xs[n]` is at index `(i + n) % l.length`. `O(|xs|)`.

Examples:

- `[1, 2, 3, 4, 5].rotateRight 3 = [3, 4, 5, 1, 2]`
- `[1, 2, 3, 4, 5].rotateRight 5 = [1, 2, 3, 4, 5]`
- `[1, 2, 3, 4, 5].rotateRight 1 = [5, 1, 2, 3, 4]`

<a id="List___leftpad"></a>

**def**

```text
List.leftpad.{u} {α : Type u} (n : Nat) (a : α) (l : List α) : List α
```

Pads `l : List α` on the left with repeated occurrences of `a : α` until it is of length `n`. If `l` already has at least `n` elements, it is returned unmodified.

Examples:

- `[1, 2, 3].leftpad 5 0 = [0, 0, 1, 2, 3]`
- `["red", "green", "blue"].leftpad 4 "blank" = ["blank", "red", "green", "blue"]`
- `["red", "green", "blue"].leftpad 3 "blank" = ["red", "green", "blue"]`
- `["red", "green", "blue"].leftpad 1 "blank" = ["red", "green", "blue"]`

<a id="List___leftpadTR"></a>

**def**

```text
List.leftpadTR.{u} {α : Type u} (n : Nat) (a : α) (l : List α) : List α
```

Pads `l : List α` on the left with repeated occurrences of `a : α` until it is of length `n`. If `l` already has at least `n` elements, it is returned unmodified.

This is a tail-recursive version of `List.leftpad`, used at runtime.

Examples:

- `[1, 2, 3].leftPadTR 5 0 = [0, 0, 1, 2, 3]`
- `["red", "green", "blue"].leftPadTR 4 "blank" = ["blank", "red", "green", "blue"]`
- `["red", "green", "blue"].leftPadTR 3 "blank" = ["red", "green", "blue"]`
- `["red", "green", "blue"].leftPadTR 1 "blank" = ["red", "green", "blue"]`

<a id="List___rightpad"></a>

**def**

```text
List.rightpad.{u} {α : Type u} (n : Nat) (a : α) (l : List α) : List α
```

Pads `l : List α` on the right with repeated occurrences of `a : α` until it is of length `n`. If `l` already has at least `n` elements, it is returned unmodified.

Examples:

- `[1, 2, 3].rightpad 5 0 = [1, 2, 3, 0, 0]`
- `["red", "green", "blue"].rightpad 4 "blank" = ["red", "green", "blue", "blank"]`
- `["red", "green", "blue"].rightpad 3 "blank" = ["red", "green", "blue"]`
- `["red", "green", "blue"].rightpad 1 "blank" = ["red", "green", "blue"]`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Modification--Insertion"></a>
##### 20.15.3.8.1. Insertion

<a id="List___insert"></a>

**def**

```text
List.insert.{u} {α : Type u} [BEq α] (a : α) (l : List α) : List α
```

Inserts an element into a list without duplication.

If the element is present in the list, the list is returned unmodified. Otherwise, the new element is inserted at the head of the list.

Examples:

- `[1, 2, 3].insert 0 = [0, 1, 2, 3]`
- `[1, 2, 3].insert 4 = [4, 1, 2, 3]`
- `[1, 2, 3].insert 2 = [1, 2, 3]`

<a id="List___insertIdx"></a>

**def**

```text
List.insertIdx.{u} {α : Type u} (xs : List α) (i : Nat) (a : α) : List α
```

Inserts an element into a list at the specified index. If the index is greater than the length of the list, then the list is returned unmodified.

In other words, the new element is inserted into the list `l` after the first `i` elements of `l`.

Examples:

- `["tues", "thur", "sat"].insertIdx 1 "wed" = ["tues", "wed", "thur", "sat"]`
- `["tues", "thur", "sat"].insertIdx 2 "wed" = ["tues", "thur", "wed", "sat"]`
- `["tues", "thur", "sat"].insertIdx 3 "wed" = ["tues", "thur", "sat", "wed"]`
- `["tues", "thur", "sat"].insertIdx 4 "wed" = ["tues", "thur", "sat"]`

<a id="List___insertIdxTR"></a>

**def**

```text
List.insertIdxTR.{u_1} {α : Type u_1} (l : List α) (n : Nat) (a : α) :
  List α
```

Inserts an element into a list at the specified index. If the index is greater than the length of the list, then the list is returned unmodified.

In other words, the new element is inserted into the list `l` after the first `i` elements of `l`.

This is a tail-recursive version of `List.insertIdx`, used at runtime.

Examples:

- `["tues", "thur", "sat"].insertIdxTR 1 "wed" = ["tues", "wed", "thur", "sat"]`
- `["tues", "thur", "sat"].insertIdxTR 2 "wed" = ["tues", "thur", "wed", "sat"]`
- `["tues", "thur", "sat"].insertIdxTR 3 "wed" = ["tues", "thur", "sat", "wed"]`
- `["tues", "thur", "sat"].insertIdxTR 4 "wed" = ["tues", "thur", "sat"]`

<a id="List___intersperse"></a>

**def**

```text
List.intersperse.{u} {α : Type u} (sep : α) (l : List α) : List α
```

Alternates the elements of `l` with `sep`.

`O(|l|)`.

`List.intercalate` is a similar function that alternates a separator list with elements of a list of lists.

Examples:

- `List.intersperse "then" [] = []`
- `List.intersperse "then" ["walk"] = ["walk"]`
- `List.intersperse "then" ["walk", "run"] = ["walk", "then", "run"]`
- `List.intersperse "then" ["walk", "run", "rest"] = ["walk", "then", "run", "then", "rest"]`

<a id="List___intersperseTR"></a>

**def**

```text
List.intersperseTR.{u} {α : Type u} (sep : α) (l : List α) : List α
```

Alternates the elements of `l` with `sep`.

`O(|l|)`.

This is a tail-recursive version of `List.intersperse`, used at runtime.

Examples:

- `List.intersperseTR "then" [] = []`
- `List.intersperseTR "then" ["walk"] = ["walk"]`
- `List.intersperseTR "then" ["walk", "run"] = ["walk", "then", "run"]`
- `List.intersperseTR "then" ["walk", "run", "rest"] = ["walk", "then", "run", "then", "rest"]`

<a id="List___intercalate"></a>

**def**

```text
List.intercalate.{u} {α : Type u} (sep : List α) (xs : List (List α)) :
  List α
```

Alternates the lists in `xs` with the separator `sep`, appending them. The resulting list is flattened.

`O(|xs|)`.

`List.intersperse` is a similar function that alternates a separator element with the elements of a list.

Examples:

- `List.intercalate sep [] = []`
- `List.intercalate sep [a] = a`
- `List.intercalate sep [a, b] = a ++ sep ++ b`
- `List.intercalate sep [a, b, c] = a ++ sep ++ b ++ sep ++ c`

<a id="List___intercalateTR"></a>

**def**

```text
List.intercalateTR.{u_1} {α : Type u_1} (sep : List α)
  (xs : List (List α)) : List α
```

Alternates the lists in `xs` with the separator `sep`.

This is a tail-recursive version of `List.intercalate` used at runtime.

Examples:

- `List.intercalateTR sep [] = []`
- `List.intercalateTR sep [a] = a`
- `List.intercalateTR sep [a, b] = a ++ sep ++ b`
- `List.intercalateTR sep [a, b, c] = a ++ sep ++ b ++ sep ++ c`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Sorting"></a>
#### 20.15.3.9. Sorting

<a id="List___mergeSort"></a>

**def**

```text
List.mergeSort.{u_1} {α : Type u_1} (xs : List α)
  (le : α → α → Bool := by exact fun a b => a ≤ b) : List α
```

A stable merge sort.

This function is a simplified implementation that's designed to be easy to reason about, rather than for efficiency. In particular, it uses the non-tail-recursive `List.merge` function and traverses lists unnecessarily.

It is replaced at runtime by an efficient implementation that has been proven to be equivalent.

<a id="List___merge"></a>

**def**

```text
List.merge.{u_1} {α : Type u_1} (xs ys : List α)
  (le : α → α → Bool := by exact fun a b => a ≤ b) : List α
```

Merges two lists, using `le` to select the first element of the resulting list if both are non-empty.

If both input lists are sorted according to `le`, then the resulting list is also sorted according to `le`. `O(|xs| + |ys|)`.

This implementation is not tail-recursive, but it is replaced at runtime by a proven-equivalent tail-recursive merge.

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Iteration"></a>
#### 20.15.3.10. Iteration

<a id="List___iter"></a>

**def**

```text
List.iter.{w} {α : Type w} (l : List α) : Std.Iter α
```

Returns a finite iterator for the given list. The iterator yields the elements of the list in order and then terminates.

The monadic version of this iterator is `List.iterM`.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="List___iterM"></a>

**def**

```text
List.iterM.{w, w'} {α : Type w} (l : List α) (m : Type w → Type w')
  [Pure m] : Std.IterM m α
```

Returns a finite iterator for the given list. The iterator yields the elements of the list in order and then terminates.

The non-monadic version of this iterator is `List.iter`.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="List___forA"></a>

**def**

```text
List.forA.{u, v, w} {m : Type u → Type v} [Applicative m] {α : Type w}
  (as : List α) (f : α → m PUnit) : m PUnit
```

Applies the applicative action `f` to every element in the list, in order.

If `m` is also a `Monad`, then using `List.forM` can be more efficient.

`List.mapA` is a variant that collects results.

<a id="List___forM"></a>

**def**

```text
List.forM.{u, v, w} {m : Type u → Type v} [Monad m] {α : Type w}
  (as : List α) (f : α → m PUnit) : m PUnit
```

Applies the monadic action `f` to every element in the list, in order.

`List.mapM` is a variant that collects results. `List.forA` is a variant that works on any `Applicative`.

<a id="List___firstM"></a>

**def**

```text
List.firstM.{u, v, w} {m : Type u → Type v} [Alternative m] {α : Type w}
  {β : Type u} (f : α → m β) : List α → m β
```

Maps `f` over the list and collects the results with `<|>`. The result for the end of the list is `failure`.

Examples:

- `[[], [1, 2], [], [2]].firstM List.head? = some 1`
- `[[], [], []].firstM List.head? = none`
- `[].firstM List.head? = none`

<a id="List___sum"></a>

**def**

```text
List.sum.{u_1} {α : Type u_1} [Add α] [Zero α] : List α → α
```

Computes the sum of the elements of a list.

Examples:

- `[a, b, c].sum = a + (b + (c + 0))`
- `[1, 2, 5].sum = 8`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Iteration--Folds"></a>
##### 20.15.3.10.1. Folds

Folds are operators that combine the elements of a list using a function. They come in two varieties, named after the nesting of the function calls:

<a id="--tech-term-Left-folds"></a>
Left folds

Left folds combine the elements from the head of the list towards the end. The head of the list is combined with the initial value, and the result of this operation is then combined with the next value, and so forth.

<a id="--tech-term-Right-folds"></a>
Right folds

Right folds combine the elements from the end of the list towards the start, as if each `cons` constructor were replaced by a call to the combining function and `nil` were replaced by the initial value.

Monadic folds, indicated with an `-M` suffix, allow the combining function to use effects in a [monad](../../Functors___-Monads-and--do--Notation/index.md#--tech-term-Monad), which may include stopping the fold early.

<a id="List___foldl"></a>

**def**

```text
List.foldl.{u, v} {α : Type u} {β : Type v} (f : α → β → α) (init : α) :
  List β → α
```

Folds a function over a list from the left, accumulating a value starting with `init`. The accumulated value is combined with the each element of the list in order, using `f`.

Examples:

- `[a, b, c].foldl f z  = f (f (f z a) b) c`
- `[1, 2, 3].foldl (· ++ toString ·) "" = "123"`
- `[1, 2, 3].foldl (s!"({·} {·})") "" = "((( 1) 2) 3)"`

<a id="List___foldlM"></a>

**def**

```text
List.foldlM.{u, v, w} {m : Type u → Type v} [Monad m] {s : Type u}
  {α : Type w} (f : s → α → m s) (init : s) : List α → m s
```

Folds a monadic function over a list from the left, accumulating a value starting with `init`. The accumulated value is combined with the each element of the list in order, using `f`.

Example:

```text
example [Monad m] (f : α → β → m α) :
    List.foldlM (m := m) f x₀ [a, b, c] = (do
      let x₁ ← f x₀ a
      let x₂ ← f x₁ b
      let x₃ ← f x₂ c
      pure x₃)
  := by rfl
```

<a id="List___foldlRecOn"></a>

**def**

```text
List.foldlRecOn.{u_1, u_2, u_3} {β : Type u_1} {α : Type u_2}
  {motive : β → Sort u_3} (l : List α) (op : β → α → β) {b : β} :
  motive b →
    ((b : β) → motive b → (a : α) → a ∈ l → motive (op b a)) →
      motive (List.foldl op b l)
```

A reasoning principle for proving propositions about the result of `List.foldl` by establishing an invariant that is true for the initial data and preserved by the operation being folded.

Because the motive can return a type in any sort, this function may be used to construct data as well as to prove propositions.

Example:

```proofscript
example {xs : List Nat} : xs.foldl (· + ·) 1 > 0 := by
  apply List.foldlRecOn
  . show 0 < 1; trivial
  . show ∀ (b : Nat), 0 < b → ∀ (a : Nat), a ∈ xs → 0 < b + a
    intros; omega
```

<a id="List___foldr"></a>

**def**

```text
List.foldr.{u, v} {α : Type u} {β : Type v} (f : α → β → β) (init : β)
  (l : List α) : β
```

Folds a function over a list from the right, accumulating a value starting with `init`. The accumulated value is combined with each element of the list in reverse order, using `f`.

`O(|l|)`. Replaced at runtime with `List.foldrTR`.

Examples:

- `[a, b, c].foldr f init  = f a (f b (f c init))`
- `[1, 2, 3].foldr (toString · ++ ·) "" = "123"`
- `[1, 2, 3].foldr (s!"({·} {·})") "!" = "(1 (2 (3 !)))"`

<a id="List___foldrM"></a>

**def**

```text
List.foldrM.{u, v, w} {m : Type u → Type v} [Monad m] {s : Type u}
  {α : Type w} (f : α → s → m s) (init : s) (l : List α) : m s
```

Folds a monadic function over a list from the right, accumulating a value starting with `init`. The accumulated value is combined with the each element of the list in reverse order, using `f`.

Example:

```text
example [Monad m] (f : α → β → m β) :
  List.foldrM (m := m) f x₀ [a, b, c] = (do
    let x₁ ← f c x₀
    let x₂ ← f b x₁
    let x₃ ← f a x₂
    pure x₃)
  := by rfl
```

<a id="List___foldrRecOn"></a>

**def**

```text
List.foldrRecOn.{u_1, u_2, u_3} {β : Type u_1} {α : Type u_2}
  {motive : β → Sort u_3} (l : List α) (op : α → β → β) {b : β} :
  motive b →
    ((b : β) → motive b → (a : α) → a ∈ l → motive (op a b)) →
      motive (List.foldr op b l)
```

A reasoning principle for proving propositions about the result of `List.foldr` by establishing an invariant that is true for the initial data and preserved by the operation being folded.

Because the motive can return a type in any sort, this function may be used to construct data as well as to prove propositions.

Example:

```proofscript
example {xs : List Nat} : xs.foldr (· + ·) 1 > 0 := by
  apply List.foldrRecOn
  . show 0 < 1; trivial
  . show ∀ (b : Nat), 0 < b → ∀ (a : Nat), a ∈ xs → 0 < a + b
    intros; omega
```

<a id="List___foldrTR"></a>

**def**

```text
List.foldrTR.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → β → β)
  (init : β) (l : List α) : β
```

Folds a function over a list from the right, accumulating a value starting with `init`. The accumulated value is combined with the each element of the list in reverse order, using `f`.

`O(|l|)`. This is the tail-recursive replacement for `List.foldr` in runtime code.

Examples:

- `[a, b, c].foldrTR f init  = f a (f b (f c init))`
- `[1, 2, 3].foldrTR (toString · ++ ·) "" = "123"`
- `[1, 2, 3].foldrTR (s!"({·} {·})") "!" = "(1 (2 (3 !)))"`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Transformation"></a>
#### 20.15.3.11. Transformation

<a id="List___map"></a>

**def**

```text
List.map.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → β)
  (l : List α) : List β
```

Applies a function to each element of the list, returning the resulting list of values.

`O(|l|)`.

Examples:

- `[a, b, c].map f = [f a, f b, f c]`
- `[].map Nat.succ = []`
- `["one", "two", "three"].map (·.length) = [3, 3, 5]`
- `["one", "two", "three"].map (·.reverse) = ["eno", "owt", "eerht"]`

<a id="List___mapTR"></a>

**def**

```text
List.mapTR.{u, v} {α : Type u} {β : Type v} (f : α → β) (as : List α) :
  List β
```

Applies a function to each element of the list, returning the resulting list of values.

`O(|l|)`. This is the tail-recursive variant of `List.map`, used in runtime code.

Examples:

- `[a, b, c].mapTR f = [f a, f b, f c]`
- `[].mapTR Nat.succ = []`
- `["one", "two", "three"].mapTR (·.length) = [3, 3, 5]`
- `["one", "two", "three"].mapTR (·.reverse) = ["eno", "owt", "eerht"]`

<a id="List___mapM"></a>

**def**

```text
List.mapM.{u, v, w} {m : Type u → Type v} [Monad m] {α : Type w}
  {β : Type u} (f : α → m β) (as : List α) : m (List β)
```

Applies the monadic action `f` to every element in the list, left-to-right, and returns the list of results.

This implementation is tail recursive. `List.mapM'` is a non-tail-recursive variant that may be more convenient to reason about. `List.forM` is the variant that discards the results and `List.mapA` is the variant that works with `Applicative`.

<a id="List___mapM___"></a>

**def**

```text
List.mapM'.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3}
  {β : Type u_1} [Monad m] (f : α → m β) : List α → m (List β)
```

Applies the monadic action `f` on every element in the list, left-to-right, and returns the list of results.

This is a non-tail-recursive variant of `List.mapM` that's easier to reason about. It cannot be used as the main definition and replaced by the tail-recursive version because they can only be proved equal when `m` is a `LawfulMonad`.

<a id="List___mapA"></a>

**def**

```text
List.mapA.{u, v, w} {m : Type u → Type v} [Applicative m] {α : Type w}
  {β : Type u} (f : α → m β) : List α → m (List β)
```

Applies the applicative action `f` on every element in the list, left-to-right, and returns the list of results.

If `m` is also a `Monad`, then using `mapM` can be more efficient.

See `List.forA` for the variant that discards the results. See `List.mapM` for the variant that works with `Monad`.

This function is not tail-recursive, so it may fail with a stack overflow on long lists.

<a id="List___mapFinIdx"></a>

**def**

```text
List.mapFinIdx.{u_1, u_2} {α : Type u_1} {β : Type u_2} (as : List α)
  (f : (i : Nat) → α → i < as.length → β) : List β
```

Applies a function to each element of the list along with the index at which that element is found, returning the list of results. In addition to the index, the function is also provided with a proof that the index is valid.

`List.mapIdx` is a variant that does not provide the function with evidence that the index is valid.

<a id="List___mapFinIdxM"></a>

**def**

```text
List.mapFinIdxM.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3}
  {β : Type u_1} [Monad m] (as : List α)
  (f : (i : Nat) → α → i < as.length → m β) : m (List β)
```

Applies a monadic function to each element of the list along with the index at which that element is found, returning the list of results. In addition to the index, the function is also provided with a proof that the index is valid.

`List.mapIdxM` is a variant that does not provide the function with evidence that the index is valid.

<a id="List___mapIdx"></a>

**def**

```text
List.mapIdx.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : Nat → α → β)
  (as : List α) : List β
```

Applies a function to each element of the list along with the index at which that element is found, returning the list of results.

`List.mapFinIdx` is a variant that additionally provides the function with a proof that the index is valid.

<a id="List___mapIdxM"></a>

**def**

```text
List.mapIdxM.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3}
  {β : Type u_1} [Monad m] (f : Nat → α → m β) (as : List α) :
  m (List β)
```

Applies a monadic function to each element of the list along with the index at which that element is found, returning the list of results.

`List.mapFinIdxM` is a variant that additionally provides the function with a proof that the index is valid.

<a id="List___mapMono"></a>

**def**

```text
List.mapMono.{u_1} {α : Type u_1} (as : List α) (f : α → α) : List α
```

Applies a function to each element of a list, returning the list of results. The function is monomorphic: it is required to return a value of the same type. The internal implementation uses pointer equality, and does not allocate a new list if the result of each function call is pointer-equal to its argument.

For verification purposes, `List.mapMono = List.map`.

<a id="List___mapMonoM"></a>

**def**

```text
List.mapMonoM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1}
  [Monad m] (as : List α) (f : α → m α) : m (List α)
```

Applies a monadic function to each element of a list, returning the list of results. The function is monomorphic: it is required to return a value of the same type. The internal implementation uses pointer equality, and does not allocate a new list if the result of each function call is pointer-equal to its argument.

<a id="List___flatMap"></a>

**def**

```text
List.flatMap.{u, v} {α : Type u} {β : Type v} (b : α → List β)
  (as : List α) : List β
```

Applies a function that returns a list to each element of a list, and concatenates the resulting lists.

Examples:

- `[2, 3, 2].flatMap List.range = [0, 1, 0, 1, 2, 0, 1]`
- `["red", "blue"].flatMap String.toList = ['r', 'e', 'd', 'b', 'l', 'u', 'e']`

<a id="List___flatMapTR"></a>

**def**

```text
List.flatMapTR.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → List β)
  (as : List α) : List β
```

Applies a function that returns a list to each element of a list, and concatenates the resulting lists.

This is the tail-recursive version of `List.flatMap` that's used at runtime.

Examples:

- `[2, 3, 2].flatMapTR List.range = [0, 1, 0, 1, 2, 0, 1]`
- `["red", "blue"].flatMapTR String.toList = ['r', 'e', 'd', 'b', 'l', 'u', 'e']`

<a id="List___flatMapM"></a>

**def**

```text
List.flatMapM.{u, v, w} {m : Type u → Type v} [Monad m] {α : Type w}
  {β : Type u} (f : α → m (List β)) (as : List α) : m (List β)
```

Applies a monadic function that returns a list to each element of a list, from left to right, and concatenates the resulting lists.

<a id="List___zip"></a>

**def**

```text
List.zip.{u, v} {α : Type u} {β : Type v} :
  List α → List β → List (α × β)
```

Combines two lists into a list of pairs in which the first and second components are the corresponding elements of each list. The resulting list is the length of the shorter of the input lists.

`O(min |xs| |ys|)`.

Examples:

- `["Mon", "Tue", "Wed"].zip [1, 2, 3] = [("Mon", 1), ("Tue", 2), ("Wed", 3)]`
- `["Mon", "Tue", "Wed"].zip [1, 2] = [("Mon", 1), ("Tue", 2)]`
- `[x₁, x₂, x₃].zip [y₁, y₂, y₃, y₄] = [(x₁, y₁), (x₂, y₂), (x₃, y₃)]`

<a id="List___zipIdx"></a>

**def**

```text
List.zipIdx.{u} {α : Type u} (l : List α) (n : Nat := 0) :
  List (α × Nat)
```

Pairs each element of a list with its index, optionally starting from an index other than `0`.

`O(|l|)`.

Examples:

- `[a, b, c].zipIdx = [(a, 0), (b, 1), (c, 2)]`
- `[a, b, c].zipIdx 5 = [(a, 5), (b, 6), (c, 7)]`

<a id="List___zipIdxTR"></a>

**def**

```text
List.zipIdxTR.{u_1} {α : Type u_1} (l : List α) (n : Nat := 0) :
  List (α × Nat)
```

Pairs each element of a list with its index, optionally starting from an index other than `0`.

`O(|l|)`. This is a tail-recursive version of `List.zipIdx` that's used at runtime.

Examples:

- `[a, b, c].zipIdxTR = [(a, 0), (b, 1), (c, 2)]`
- `[a, b, c].zipIdxTR 5 = [(a, 5), (b, 6), (c, 7)]`

<a id="List___zipWith"></a>

**def**

```text
List.zipWith.{u, v, w} {α : Type u} {β : Type v} {γ : Type w}
  (f : α → β → γ) (xs : List α) (ys : List β) : List γ
```

Applies a function to the corresponding elements of two lists, stopping at the end of the shorter list.

`O(min |xs| |ys|)`.

Examples:

- `[1, 2].zipWith (· + ·) [5, 6] = [6, 8]`
- `[1, 2, 3].zipWith (· + ·) [5, 6, 10] = [6, 8, 13]`
- `[].zipWith (· + ·) [5, 6] = []`
- `[x₁, x₂, x₃].zipWith f [y₁, y₂, y₃, y₄] = [f x₁ y₁, f x₂ y₂, f x₃ y₃]`

<a id="List___zipWithTR"></a>

**def**

```text
List.zipWithTR.{u_1, u_2, u_3} {α : Type u_1} {β : Type u_2}
  {γ : Type u_3} (f : α → β → γ) (as : List α) (bs : List β) : List γ
```

Applies a function to the corresponding elements of two lists, stopping at the end of the shorter list.

`O(min |xs| |ys|)`. This is a tail-recursive version of `List.zipWith` that's used at runtime.

Examples:

- `[1, 2].zipWithTR (· + ·) [5, 6] = [6, 8]`
- `[1, 2, 3].zipWithTR (· + ·) [5, 6, 10] = [6, 8, 13]`
- `[].zipWithTR (· + ·) [5, 6] = []`
- `[x₁, x₂, x₃].zipWithTR f [y₁, y₂, y₃, y₄] = [f x₁ y₁, f x₂ y₂, f x₃ y₃]`

<a id="List___zipWithAll"></a>

**def**

```text
List.zipWithAll.{u, v, w} {α : Type u} {β : Type v} {γ : Type w}
  (f : Option α → Option β → γ) : List α → List β → List γ
```

Applies a function to the corresponding elements of both lists, stopping when there are no more elements in either list. If one list is shorter than the other, the function is passed `none` for the missing elements.

Examples:

- `[1, 6].zipWithAll min [5, 2] = [some 1, some 2]`
- `[1, 2, 3].zipWithAll Prod.mk [5, 6] = [(some 1, some 5), (some 2, some 6), (some 3, none)]`
- `[x₁, x₂].zipWithAll f [y] = [f (some x₁) (some y), f (some x₂) none]`

<a id="List___unzip"></a>

**def**

```text
List.unzip.{u, v} {α : Type u} {β : Type v} (l : List (α × β)) :
  List α × List β
```

Separates a list of pairs into two lists that contain the respective first and second components.

`O(|l|)`.

Examples:

- `[("Monday", 1), ("Tuesday", 2)].unzip = (["Monday", "Tuesday"], [1, 2])`
- `[(x₁, y₁), (x₂, y₂), (x₃, y₃)].unzip = ([x₁, x₂, x₃], [y₁, y₂, y₃])`
- `([] : List (Nat × String)).unzip = (([], []) : List Nat × List String)`

<a id="List___unzipTR"></a>

**def**

```text
List.unzipTR.{u, v} {α : Type u} {β : Type v} (l : List (α × β)) :
  List α × List β
```

Separates a list of pairs into two lists that contain the respective first and second components.

`O(|l|)`. This is a tail-recursive version of `List.unzip` that's used at runtime.

Examples:

- `[("Monday", 1), ("Tuesday", 2)].unzipTR = (["Monday", "Tuesday"], [1, 2])`
- `[(x₁, y₁), (x₂, y₂), (x₃, y₃)].unzipTR = ([x₁, x₂, x₃], [y₁, y₂, y₃])`
- `([] : List (Nat × String)).unzipTR = (([], []) : List Nat × List String)`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Filtering"></a>
#### 20.15.3.12. Filtering

<a id="List___filter"></a>

**def**

```text
List.filter.{u} {α : Type u} (p : α → Bool) (l : List α) : List α
```

Returns the list of elements in `l` for which `p` returns `true`.

`O(|l|)`.

Examples:

- `[1, 2, 5, 2, 7, 7].filter (· > 2) = [5, 7, 7]`
- `[1, 2, 5, 2, 7, 7].filter (fun _ => false) = []`
- `[1, 2, 5, 2, 7, 7].filter (fun _ => true) = [1, 2, 5, 2, 7, 7]`

<a id="List___filterTR"></a>

**def**

```text
List.filterTR.{u} {α : Type u} (p : α → Bool) (as : List α) : List α
```

Returns the list of elements in `l` for which `p` returns `true`.

`O(|l|)`. This is a tail-recursive version of `List.filter`, used at runtime.

Examples:

- `[1, 2, 5, 2, 7, 7].filterTR (· > 2)  = [5, 7, 7]`
- `[1, 2, 5, 2, 7, 7].filterTR (fun _ => false) = []`
- `[1, 2, 5, 2, 7, 7].filterTR (fun _ => true) = * [1, 2, 5, 2, 7, 7]`

<a id="List___filterM"></a>

**def**

```text
List.filterM.{v} {m : Type → Type v} [Monad m] {α : Type}
  (p : α → m Bool) (as : List α) : m (List α)
```

Applies the monadic predicate `p` to every element in the list, in order from left to right, and returns the list of elements for which `p` returns `true`.

`O(|l|)`.

Example:

```proofscript
#eval [1, 2, 5, 2, 7, 7].filterM fun x => do
  IO.println s!"Checking {x}"
  return x < 3
```

```proofscript
Checking 1
Checking 2
Checking 5
Checking 2
Checking 7
Checking 7
```

```proofscript
[1, 2, 2]
```

<a id="List___filterRevM"></a>

**def**

```text
List.filterRevM.{v} {m : Type → Type v} [Monad m] {α : Type}
  (p : α → m Bool) (as : List α) : m (List α)
```

Applies the monadic predicate `p` on every element in the list in reverse order, from right to left, and returns those elements for which `p` returns `true`. The elements of the returned list are in the same order as in the input list.

Example:

```proofscript
#eval [1, 2, 5, 2, 7, 7].filterRevM fun x => do
  IO.println s!"Checking {x}"
  return x < 3
```

```proofscript
Checking 7
Checking 7
Checking 2
Checking 5
Checking 2
Checking 1
```

```proofscript
[1, 2, 2]
```

<a id="List___filterMap"></a>

**def**

```text
List.filterMap.{u, v} {α : Type u} {β : Type v} (f : α → Option β) :
  List α → List β
```

Applies a function that returns an `Option` to each element of a list, collecting the non-`none` values.

`O(|l|)`.

Example:

```proofscript
#eval [1, 2, 5, 2, 7, 7].filterMap fun x =>
  if x > 2 then some (2 * x) else none
```

```proofscript
[10, 14, 14]
```

<a id="List___filterMapTR"></a>

**def**

```text
List.filterMapTR.{u_1, u_2} {α : Type u_1} {β : Type u_2}
  (f : α → Option β) (l : List α) : List β
```

Applies a function that returns an `Option` to each element of a list, collecting the non-`none` values.

`O(|l|)`. This is a tail-recursive version of `List.filterMap`, used at runtime.

Example:

```proofscript
#eval [1, 2, 5, 2, 7, 7].filterMapTR fun x =>
  if x > 2 then some (2 * x) else none
```

```proofscript
[10, 14, 14]
```

<a id="List___filterMapM"></a>

**def**

```text
List.filterMapM.{u, v, w} {m : Type u → Type v} [Monad m] {α : Type w}
  {β : Type u} (f : α → m (Option β)) (as : List α) : m (List β)
```

Applies a monadic function that returns an `Option` to each element of a list, collecting the non-`none` values.

`O(|l|)`.

Example:

```proofscript
#eval [1, 2, 5, 2, 7, 7].filterMapM fun x => do
  IO.println s!"Examining {x}"
  if x > 2 then return some (2 * x)
  else return none
```

```proofscript
Examining 1
Examining 2
Examining 5
Examining 2
Examining 7
Examining 7
```

```proofscript
[10, 14, 14]
```

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Filtering--Partitioning"></a>
##### 20.15.3.12.1. Partitioning

<a id="List___take"></a>

**def**

```text
List.take.{u} {α : Type u} (n : Nat) (xs : List α) : List α
```

Extracts the first `n` elements of `xs`, or the whole list if `n` is greater than `xs.length`.

`O(min n |xs|)`.

Examples:

- `[a, b, c, d, e].take 0 = []`
- `[a, b, c, d, e].take 3 = [a, b, c]`
- `[a, b, c, d, e].take 6 = [a, b, c, d, e]`

<a id="List___takeTR"></a>

**def**

```text
List.takeTR.{u_1} {α : Type u_1} (n : Nat) (l : List α) : List α
```

Extracts the first `n` elements of `xs`, or the whole list if `n` is greater than `xs.length`.

`O(min n |xs|)`. This is a tail-recursive version of `List.take`, used at runtime.

Examples:

- `[a, b, c, d, e].takeTR 0 = []`
- `[a, b, c, d, e].takeTR 3 = [a, b, c]`
- `[a, b, c, d, e].takeTR 6 = [a, b, c, d, e]`

<a id="List___takeWhile"></a>

**def**

```text
List.takeWhile.{u} {α : Type u} (p : α → Bool) (xs : List α) : List α
```

Returns the longest initial segment of `xs` for which `p` returns true.

`O(|xs|)`.

Examples:

- `[7, 6, 4, 8].takeWhile (· > 5) = [7, 6]`
- `[7, 6, 6, 5].takeWhile (· > 5) = [7, 6, 6]`
- `[7, 6, 6, 8].takeWhile (· > 5) = [7, 6, 6, 8]`

<a id="List___takeWhileTR"></a>

**def**

```text
List.takeWhileTR.{u_1} {α : Type u_1} (p : α → Bool) (l : List α) :
  List α
```

Returns the longest initial segment of `xs` for which `p` returns true.

`O(|xs|)`. This is a tail-recursive version of `List.take`, used at runtime.

Examples:

- `[7, 6, 4, 8].takeWhileTR (· > 5) = [7, 6]`
- `[7, 6, 6, 5].takeWhileTR (· > 5) = [7, 6, 6]`
- `[7, 6, 6, 8].takeWhileTR (· > 5) = [7, 6, 6, 8]`

<a id="List___drop"></a>

**def**

```text
List.drop.{u} {α : Type u} (n : Nat) (xs : List α) : List α
```

Removes the first `n` elements of the list `xs`. Returns the empty list if `n` is greater than the length of the list.

`O(min n |xs|)`.

Examples:

- `[0, 1, 2, 3, 4].drop 0 = [0, 1, 2, 3, 4]`
- `[0, 1, 2, 3, 4].drop 3 = [3, 4]`
- `[0, 1, 2, 3, 4].drop 6 = []`

<a id="List___dropWhile"></a>

**def**

```text
List.dropWhile.{u} {α : Type u} (p : α → Bool) : List α → List α
```

Removes the longest prefix of a list for which `p` returns `true`.

Elements are removed from the list until one is encountered for which `p` returns `false`. This element and the remainder of the list are returned.

`O(|l|)`.

Examples:

- `[1, 3, 2, 4, 2, 7, 4].dropWhile (· < 4) = [4, 2, 7, 4]`
- `[8, 3, 2, 4, 2, 7, 4].dropWhile (· < 4) = [8, 3, 2, 4, 2, 7, 4]`
- `[8, 3, 2, 4, 2, 7, 4].dropWhile (· < 100) = []`

<a id="List___dropLast"></a>

**def**

```text
List.dropLast.{u_1} {α : Type u_1} : List α → List α
```

Removes the last element of the list, if one exists.

Examples:

- `[].dropLast = []`
- `["tea"].dropLast = []`
- `["tea", "coffee", "juice"].dropLast = ["tea", "coffee"]`

<a id="List___dropLastTR"></a>

**def**

```text
List.dropLastTR.{u_1} {α : Type u_1} (l : List α) : List α
```

Removes the last element of the list, if one exists.

This is a tail-recursive version of `List.dropLast`, used at runtime.

Examples:

- `[].dropLastTR = []`
- `["tea"].dropLastTR = []`
- `["tea", "coffee", "juice"].dropLastTR = ["tea", "coffee"]`

<a id="List___splitAt"></a>

**def**

```text
List.splitAt.{u} {α : Type u} (n : Nat) (l : List α) : List α × List α
```

Splits a list at an index, resulting in the first `n` elements of `l` paired with the remaining elements.

If `n` is greater than the length of `l`, then the resulting pair consists of `l` and the empty list. `List.splitAt` is equivalent to a combination of `List.take` and `List.drop`, but it is more efficient.

Examples:

- `["red", "green", "blue"].splitAt 2 = (["red", "green"], ["blue"])`
- `["red", "green", "blue"].splitAt 3 = (["red", "green", "blue], [])`
- `["red", "green", "blue"].splitAt 4 = (["red", "green", "blue], [])`

<a id="List___span"></a>

**def**

```text
List.span.{u} {α : Type u} (p : α → Bool) (as : List α) :
  List α × List α
```

Splits a list into the longest initial segment for which `p` returns `true`, paired with the remainder of the list.

`O(|l|)`.

Examples:

- `[6, 8, 9, 5, 2, 9].span (· > 5) = ([6, 8, 9], [5, 2, 9])`
- `[6, 8, 9, 5, 2, 9].span (· > 10) = ([], [6, 8, 9, 5, 2, 9])`
- `[6, 8, 9, 5, 2, 9].span (· > 0) = ([6, 8, 9, 5, 2, 9], [])`

<a id="List___splitBy"></a>

**def**

```text
List.splitBy.{u} {α : Type u} (R : α → α → Bool) :
  List α → List (List α)
```

Splits a list into the longest segments in which each pair of adjacent elements are related by `R`.

`O(|l|)`.

Examples:

- `[1, 1, 2, 2, 2, 3, 2].splitBy (· == ·) = [[1, 1], [2, 2, 2], [3], [2]]`
- `[1, 2, 5, 4, 5, 1, 4].splitBy (· < ·) = [[1, 2, 5], [4, 5], [1, 4]]`
- `[1, 2, 5, 4, 5, 1, 4].splitBy (fun _ _ => true) = [[1, 2, 5, 4, 5, 1, 4]]`
- `[1, 2, 5, 4, 5, 1, 4].splitBy (fun _ _ => false) = [[1], [2], [5], [4], [5], [1], [4]]`

<a id="List___partition"></a>

**def**

```text
List.partition.{u} {α : Type u} (p : α → Bool) (as : List α) :
  List α × List α
```

Returns a pair of lists that together contain all the elements of `as`. The first list contains those elements for which `p` returns `true`, and the second contains those for which `p` returns `false`.

`O(|l|)`. `as.partition p` is equivalent to `(as.filter p, as.filter (not ∘ p))`, but it is slightly more efficient since it only has to do one pass over the list.

Examples:

- `[1, 2, 5, 2, 7, 7].partition (· > 2) = ([5, 7, 7], [1, 2, 2])`
- `[1, 2, 5, 2, 7, 7].partition (fun _ => false) = ([], [1, 2, 5, 2, 7, 7])`
- `[1, 2, 5, 2, 7, 7].partition (fun _ => true) = ([1, 2, 5, 2, 7, 7], [])`

<a id="List___partitionM"></a>

**def**

```text
List.partitionM.{u_1} {m : Type → Type u_1} {α : Type} [Monad m]
  (p : α → m Bool) (l : List α) : m (List α × List α)
```

Returns a pair of lists that together contain all the elements of `as`. The first list contains those elements for which the monadic predicate `p` returns `true`, and the second contains those for which `p` returns `false`. The list's elements are examined in order, from left to right.

This is a monadic version of `List.partition`.

Example:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function posOrNeg (x : Int) : Except String Bool :=
  if x > 0 then pure true
  else if x < 0 then pure false
  else throw "Zero is not positive or negative"
```

```text
#eval [-1, 2, 3].partitionM posOrNeg
```

```proofscript
Except.ok ([2, 3], [-1])
```

```text
#eval [0, 2, 3].partitionM posOrNeg
```

```proofscript
Except.error "Zero is not positive or negative"
```

<a id="List___partitionMap"></a>

**def**

```text
List.partitionMap.{u_1, u_2, u_3} {α : Type u_1} {β : Type u_2}
  {γ : Type u_3} (f : α → β ⊕ γ) (l : List α) : List β × List γ
```

Applies a function that returns a disjoint union to each element of a list, collecting the `Sum.inl` and `Sum.inr` results into separate lists.

Examples:

- `[0, 1, 2, 3].partitionMap (fun x => if x % 2 = 0 then .inl x else .inr x) = ([0, 2], [1, 3])`
- `[0, 1, 2, 3].partitionMap (fun x => if x = 0 then .inl x else .inr x) = ([0], [1, 2, 3])`

<a id="List___groupByKey"></a>

**def**

```text
List.groupByKey.{u, v} {α : Type u} {β : Type v} [BEq α] [Hashable α]
  (key : β → α) (xs : List β) : Std.HashMap α (List β)
```

Groups the elements of a list `xs` according to the function `key`, returning a hash map in which each group is associated with its key. Groups preserve the relative order of elements in `xs`.

Example:

```proofscript
#eval [0, 1, 2, 3, 4, 5, 6].groupByKey (· % 2)
```

```proofscript
Std.HashMap.ofList [(0, [0, 2, 4, 6]), (1, [1, 3, 5])]
```

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Element-Predicates"></a>
#### 20.15.3.13. Element Predicates

<a id="List___contains"></a>

**def**

```text
List.contains.{u} {α : Type u} [BEq α] (as : List α) (a : α) : Bool
```

Checks whether `a` is an element of `as`, using `==` to compare elements.

`O(|as|)`. `List.elem` is a synonym that takes the element before the list.

The preferred simp normal form is `l.contains a`, and when `LawfulBEq α` is available, `l.contains a = true ↔ a ∈ l` and `l.contains a = false ↔ a ∉ l`.

Examples:

- `[1, 4, 2, 3, 3, 7].contains 3 = true`
- `List.contains [1, 4, 2, 3, 3, 7] 5 = false`

<a id="List___elem"></a>

**def**

```text
List.elem.{u} {α : Type u} [BEq α] (a : α) (l : List α) : Bool
```

Checks whether `a` is an element of `l`, using `==` to compare elements.

`O(|l|)`. `List.contains` is a synonym that takes the list before the element.

The preferred simp normal form is `l.contains a`. When `LawfulBEq α` is available, `l.contains a = true ↔ a ∈ l` and `l.contains a = false ↔ a ∉ l`.

Example:

- `List.elem 3 [1, 4, 2, 3, 3, 7] = true`
- `List.elem 5 [1, 4, 2, 3, 3, 7] = false`

<a id="List___all"></a>

**def**

```text
List.all.{u} {α : Type u} : List α → (α → Bool) → Bool
```

Returns `true` if `p` returns `true` for every element of `l`.

`O(|l|)`. Short-circuits upon encountering the first `false`.

Examples:

- `[a, b, c].all p = (p a && (p b && p c))`
- `[2, 4, 6].all (· % 2 = 0) = true`
- `[2, 4, 5, 6].all (· % 2 = 0) = false`

<a id="List___allM"></a>

**def**

```text
List.allM.{u, v} {m : Type → Type u} [Monad m] {α : Type v}
  (p : α → m Bool) (l : List α) : m Bool
```

Returns true if the monadic predicate `p` returns `true` for every element of `l`.

`O(|l|)`. Short-circuits upon encountering the first `false`. The elements in `l` are examined in order from left to right.

<a id="List___any"></a>

**def**

```text
List.any.{u} {α : Type u} (l : List α) (p : α → Bool) : Bool
```

Returns `true` if `p` returns `true` for any element of `l`.

`O(|l|)`. Short-circuits upon encountering the first `true`.

Examples:

- `[2, 4, 6].any (· % 2 = 0) = true`
- `[2, 4, 6].any (· % 2 = 1) = false`
- `[2, 4, 5, 6].any (· % 2 = 0) = true`
- `[2, 4, 5, 6].any (· % 2 = 1) = true`

<a id="List___anyM"></a>

**def**

```text
List.anyM.{u, v} {m : Type → Type u} [Monad m] {α : Type v}
  (p : α → m Bool) (l : List α) : m Bool
```

Returns true if the monadic predicate `p` returns `true` for any element of `l`.

`O(|l|)`. Short-circuits upon encountering the first `true`. The elements in `l` are examined in order from left to right.

<a id="List___and"></a>

**def**

```text
List.and (bs : List Bool) : Bool
```

Returns `true` if every element of `bs` is the value `true`.

`O(|bs|)`. Short-circuits at the first `false` value.

- `[true, true, true].and = true`
- `[true, false, true].and = false`
- `[true, false, false].and = false`
- `[].and = true`

<a id="List___or"></a>

**def**

```text
List.or (bs : List Bool) : Bool
```

Returns `true` if `true` is an element of the list `bs`.

`O(|bs|)`. Short-circuits at the first `true` value.

- `[true, true, true].or = true`
- `[true, false, true].or = true`
- `[false, false, false].or = false`
- `[false, false, true].or = true`
- `[].or = false`

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Comparisons"></a>
#### 20.15.3.14. Comparisons

<a id="List___beq"></a>

**def**

```text
List.beq.{u} {α : Type u} [BEq α] : List α → List α → Bool
```

Checks whether two lists have the same length and their elements are pairwise `BEq`. Normally used via the `==` operator.

<a id="List___isEqv"></a>

**def**

```text
List.isEqv.{u} {α : Type u} (as bs : List α) (eqv : α → α → Bool) : Bool
```

Returns `true` if `as` and `bs` have the same length and they are pairwise related by `eqv`.

`O(min |as| |bs|)`. Short-circuits at the first non-related pair of elements.

Examples:

- `[1, 2, 3].isEqv [2, 3, 4] (· < ·) = true`
- `[1, 2, 3].isEqv [2, 2, 4] (· < ·) = false`
- `[1, 2, 3].isEqv [2, 3] (· < ·) = false`

<a id="List___isPerm"></a>

**def**

```text
List.isPerm.{u} {α : Type u} [BEq α] : List α → List α → Bool
```

Returns `true` if `l₁` and `l₂` are permutations of each other. `O(|l₁| * |l₂|)`.

The relation `List.Perm` is a logical characterization of permutations. When the `BEq α` instance corresponds to `DecidableEq α`, `isPerm l₁ l₂ ↔ l₁ ~ l₂` (use the theorem `isPerm_iff`).

<a id="List___isPrefixOf"></a>

**def**

```text
List.isPrefixOf.{u} {α : Type u} [BEq α] : List α → List α → Bool
```

Checks whether the first list is a prefix of the second.

The relation `List.IsPrefixOf` expresses this property with respect to logical equality.

Examples:

- `[1, 2].isPrefixOf [1, 2, 3] = true`
- `[1, 2].isPrefixOf [1, 2] = true`
- `[1, 2].isPrefixOf [1] = false`
- `[1, 2].isPrefixOf [1, 1, 2, 3] = false`

<a id="List___isPrefixOf___"></a>

**def**

```text
List.isPrefixOf?.{u} {α : Type u} [BEq α] (l₁ l₂ : List α) :
  Option (List α)
```

If the first list is a prefix of the second, returns the result of dropping the prefix.

In other words, `isPrefixOf? l₁ l₂` returns `some t` when `l₂ == l₁ ++ t`.

Examples:

- `[1, 2].isPrefixOf? [1, 2, 3] = some [3]`
- `[1, 2].isPrefixOf? [1, 2] = some []`
- `[1, 2].isPrefixOf? [1] = none`
- `[1, 2].isPrefixOf? [1, 1, 2, 3] = none`

<a id="List___isSublist"></a>

**def**

```text
List.isSublist.{u} {α : Type u} [BEq α] : List α → List α → Bool
```

True if the first list is a potentially non-contiguous sub-sequence of the second list, comparing elements with the `==` operator.

The relation `List.Sublist` is a logical characterization of this property.

Examples:

- `[1, 3].isSublist [0, 1, 2, 3, 4] = true`
- `[1, 3].isSublist [0, 1, 2, 4] = false`

<a id="List___isSuffixOf"></a>

**def**

```text
List.isSuffixOf.{u} {α : Type u} [BEq α] (l₁ l₂ : List α) : Bool
```

Checks whether the first list is a suffix of the second.

The relation `List.IsSuffixOf` expresses this property with respect to logical equality.

Examples:

- `[2, 3].isSuffixOf [1, 2, 3] = true`
- `[2, 3].isSuffixOf [1, 2, 3, 4] = false`
- `[2, 3].isSuffixOf [1, 2] = false`
- `[2, 3].isSuffixOf [1, 1, 2, 3] = true`

<a id="List___isSuffixOf___"></a>

**def**

```text
List.isSuffixOf?.{u} {α : Type u} [BEq α] (l₁ l₂ : List α) :
  Option (List α)
```

If the first list is a suffix of the second, returns the result of dropping the suffix from the second.

In other words, `isSuffixOf? l₁ l₂` returns `some t` when `l₂ == t ++ l₁`.

Examples:

- `[2, 3].isSuffixOf? [1, 2, 3] = some [1]`
- `[2, 3].isSuffixOf? [1, 2, 3, 4] = none`
- `[2, 3].isSuffixOf? [1, 2] = none`
- `[2, 3].isSuffixOf? [1, 1, 2, 3] = some [1, 1]`

<a id="List___le"></a>

**def**

```text
List.le.{u} {α : Type u} [LT α] (as bs : List α) : Prop
```

Non-strict ordering of lists with respect to a strict ordering of their elements.

`as ≤ bs` if `¬ bs < as`.

This relation can be treated as a lexicographic order if the underlying `LT α` instance is well-behaved. In particular, it should be irreflexive, asymmetric, and antisymmetric. These requirements are precisely formulated in `List.cons_le_cons_iff`. If these hold, then `as ≤ bs` if and only if:

- `as` is empty, or
- both `as` and `bs` are non-empty, and the head of `as` is less than the head of `bs`, or
- both `as` and `bs` are non-empty, their heads are equal, and the tail of `as` is less than or equal to the tail of `bs`.

<a id="List___lt"></a>

**def**

```text
List.lt.{u} {α : Type u} [LT α] : List α → List α → Prop
```

Lexicographic ordering of lists with respect to an ordering on their elements.

`as < bs` if

- `as` is empty and `bs` is non-empty, or
- both `as` and `bs` are non-empty, and the head of `as` is less than the head of `bs`, or
- both `as` and `bs` are non-empty, their heads are equal, and the tail of `as` is less than the tail of `bs`.

<a id="List___lex"></a>

**def**

```text
List.lex.{u} {α : Type u} [BEq α] (l₁ l₂ : List α)
  (lt : α → α → Bool := by exact (· < ·)) : Bool
```

Compares lists lexicographically with respect to a comparison on their elements.

The lexicographic order with respect to `lt` is:

- `[].lex (b :: bs)` is `true`
- `as.lex [] = false` is `false`
- `(a :: as).lex (b :: bs)` is true if `lt a b` or `a == b` and `lex lt as bs` is true.

<a id="The-Lean-Language-Reference--Basic-Types--Linked-Lists--API-Reference--Termination-Helpers"></a>
#### 20.15.3.15. Termination Helpers

<a id="List___attach"></a>

**def**

```text
List.attach.{u_1} {α : Type u_1} (l : List α) : List { x // x ∈ l }
```

“Attaches” the proof that the elements of `l` are in fact elements of `l`, producing a new list with the same elements but in the subtype `{ x // x ∈ l }`.

`O(1)`.

This function is primarily used to allow definitions by [well-founded recursion](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=well-founded-recursion) that use higher-order functions (such as `List.map`) to prove that an value taken from a list is smaller than the list. This allows the well-founded recursion mechanism to prove that the function terminates.

<a id="List___attachWith"></a>

**def**

```text
List.attachWith.{u_1} {α : Type u_1} (l : List α) (P : α → Prop)
  (H : ∀ (x : α), x ∈ l → P x) : List { x // P x }
```

“Attaches” individual proofs to a list of values that satisfy a predicate `P`, returning a list of elements in the corresponding subtype `{ x // P x }`.

`O(1)`.

<a id="List___unattach"></a>

**def**

```text
List.unattach.{u_1} {α : Type u_1} {p : α → Prop}
  (l : List { x // p x }) : List α
```

Maps a list of terms in a subtype to the corresponding terms in the type by forgetting that they satisfy the predicate.

This is the inverse of `List.attachWith` and a synonym for `l.map (·.val)`.

Mostly this should not be needed by users. It is introduced as an intermediate step by lemmas such as `map_subtype`, and is ideally subsequently simplified away by `unattach_attach`.

This function is usually inserted automatically by Lean as an intermediate step while proving termination. It is rarely used explicitly in code. It is introduced as an intermediate step during the elaboration of definitions by [well-founded recursion](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=well-founded-recursion). If this function is encountered in a proof state, the right approach is usually the tactic `simp [List.unattach, -List.map_subtype]`.

<a id="List___pmap"></a>

**def**

```text
List.pmap.{u_1, u_2} {α : Type u_1} {β : Type u_2} {P : α → Prop}
  (f : (a : α) → P a → β) (l : List α) (H : ∀ (a : α), a ∈ l → P a) :
  List β
```

Maps a partially defined function (defined on those terms of `α` that satisfy a predicate `P`) over a list `l : List α`, given a proof that every element of `l` in fact satisfies `P`.

`O(|l|)`. `List.pmap`, named for “partial map,” is the equivalent of `List.map` for such partial functions.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
The syntax `[a, b, c]` is shorthand for `a :: b :: c :: []`, or
`List.cons a (List.cons b (List.cons c List.nil))`. It allows conveniently constructing
list literals.

For lists of length at least 64, an alternative desugaring strategy is used
which uses let bindings as intermediates as in
`let left := [d, e, f]; a :: b :: c :: left` to avoid creating very deep expressions.
Note that this changes the order of evaluation, although it should not be observable
unless you use side effecting operations like `dbg_trace`.


Conventions for notations in identifiers:

 * The recommended spelling of `[]` in identifiers is `nil`.

 * The recommended spelling of `[a]` in identifiers is `singleton`.
```


### Display 2


```text
The list whose first element is `head`, where `tail` is the rest of the list.
Usually written `head :: tail`.


Conventions for notations in identifiers:

 * The recommended spelling of `::` in identifiers is `cons`.
```


### Display 3


```text
The first list is a prefix of the second.

`IsPrefix l₁ l₂`, written `l₁ <+: l₂`, means that there exists some `t : List α` such that `l₂` has
the form `l₁ ++ t`.

The function `List.isPrefixOf` is a Boolean equivalent.


Conventions for notations in identifiers:

 * The recommended spelling of `<+:` in identifiers is `prefix` (not `isPrefix`).
```


### Display 4


```text
The first list is a suffix of the second.

`IsSuffix l₁ l₂`, written `l₁ <:+ l₂`, means that there exists some `t : List α` such that `l₂` has
the form `t ++ l₁`.

The function `List.isSuffixOf` is a Boolean equivalent.


Conventions for notations in identifiers:

 * The recommended spelling of `<:+` in identifiers is `suffix` (not `isSuffix`).
```


### Display 5


```text
The first list is a contiguous sub-list of the second list. Typically written with the `<:+:`
operator.

In other words, `l₁ <:+: l₂` means that there exist lists `s : List α` and `t : List α` such that
`l₂` has the form `s ++ l₁ ++ t`.


Conventions for notations in identifiers:

 * The recommended spelling of `<:+:` in identifiers is `infix` (not `isInfix`).
```


### Display 6


```text
The first list is a non-contiguous sub-list of the second list. Typically written with the `<+`
operator.

In other words, `l₁ <+ l₂` means that `l₁` can be transformed into `l₂` by repeatedly inserting new
elements.
```


### Display 7


```text
Two lists are permutations of each other if they contain the same elements, each occurring the same
number of times but not necessarily in the same order.

One list can be proven to be a permutation of another by showing how to transform one into the other
by repeatedly swapping adjacent elements.

`List.isPerm` is a Boolean equivalent of this relation.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
some 1Almost! 6
Almost! 5
```


### Display 2


```text
some 10Almost! 6
Almost! 5
```


### Display 3


```text
[1, 2, 2]Checking 1
Checking 2
Checking 5
Checking 2
Checking 7
Checking 7
```


### Display 4


```text
[1, 2, 2]Checking 7
Checking 7
Checking 2
Checking 5
Checking 2
Checking 1
```


### Display 5


```text
[10, 14, 14]
```


### Display 6


```text
[10, 14, 14]Examining 1
Examining 2
Examining 5
Examining 2
Examining 7
Examining 7
```


### Display 7


```text
Std.HashMap.ofList [(0, [0, 2, 4, 6]), (1, [1, 3, 5])]
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
xs:List Nat⊢ List.foldl (fun x1 x2 => x1 + x2) 1 xs > 0
```


### Display 2


```text
xxs:List Nat⊢ 0 < 1xxs:List Nat⊢ ∀ (b : Nat), 0 < b → ∀ (a : Nat), a ∈ xs → 0 < b + a
```


### Display 3


```text
xxs:List Nat⊢ 0 < 1
```


### Display 4


```text
All goals completed! 🐙
```


### Display 5


```text
xxs:List Nat⊢ ∀ (b : Nat), 0 < b → ∀ (a : Nat), a ∈ xs → 0 < b + a
```


### Display 6


```text
xxs:List Natb✝:Nata✝²:0 < b✝a✝¹:Nata✝:a✝¹ ∈ xs⊢ 0 < b✝ + a✝¹
```


### Display 7


```text
xs:List Nat⊢ List.foldr (fun x1 x2 => x1 + x2) 1 xs > 0
```


### Display 8


```text
xxs:List Nat⊢ 0 < 1xxs:List Nat⊢ ∀ (b : Nat), 0 < b → ∀ (a : Nat), a ∈ xs → 0 < a + b
```


### Display 9


```text
xxs:List Nat⊢ ∀ (b : Nat), 0 < b → ∀ (a : Nat), a ∈ xs → 0 < a + b
```


### Display 10


```text
xxs:List Natb✝:Nata✝²:0 < b✝a✝¹:Nata✝:a✝¹ ∈ xs⊢ 0 < a✝¹ + b✝
```

