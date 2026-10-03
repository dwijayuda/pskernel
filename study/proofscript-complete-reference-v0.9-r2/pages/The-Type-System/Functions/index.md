<a id="functions"></a>

# ProofScript — 4.1. Functions

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functions, propositions, universes, inductives and quotients retain their Lean meaning. A proof is an inhabitant of a proposition; Boolean truth is not the same object. Parameters may determine later parameter types. Universe levels cannot be approximated as machine integer ranks. Inductive constructors require the native positivity, universe, parameter and index checks. Quotient eliminators must respect their relation, rather than use runtime object identity.

**Compiler and coverage boundary.** Use exact declared core rules and axiom policies. Library names and hash matches alone cannot authorize primitive reductions. Soundness and exact acceptance equivalence are distinct obligations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Type-System/Functions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Type-System/Functions/index.html). Source Git blob: `74773c55fd7be7f0f512e557bef5e6ce242e424a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 4.1. Functions

Function types are a built-in feature of Lean. 
<a id="--tech-term-Functions"></a>
Functions map the values of one type (the 
<a id="--tech-term-domain"></a>
*domain*) into those of another type (the 
<a id="--tech-term-codomain"></a>
*codomain*), and 
<a id="--tech-term-function-types"></a>
*function types* specify the domain and codomain of functions.

There are two kinds of function type:

<a id="--tech-term-Dependent"></a>
Dependent

Dependent function types explicitly name the parameter, and the function's codomain may refer explicitly to this name. Because types can be computed from values, a dependent function may return values from any number of different types, depending on its argument.Dependent functions are sometimes referred to as 
<a id="--tech-term-dependent-products"></a>
*dependent products*, because they correspond to an indexed product of sets.

<a id="--tech-term-Non-Dependent"></a>
Non-Dependent

Non-dependent function types do not include a name for the parameter, and the codomain does not vary based on the specific argument provided.

<a id="Dependent-Function-Types"></a>
Dependent Function Types 

The function `two` returns values in different types, depending on which argument it is called with:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="two-_LPAR_in-Dependent-Function-Types_RPAR_"></a>


```proofscript
const two : (b : Bool) → if b then Unit × Unit else String :=
  fun b =>
    match b with
    | true => ((), ())
    | false => "two"
```

The body of the function cannot be written with `if...then...else...` because it does not refine types the same way that [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match) does.

In Lean's core language, all function types are dependent: non-dependent function types are dependent function types in which the parameter name does not occur in the [codomain](index.md#--tech-term-codomain). Additionally, two dependent function types that have different parameter names may be definitionally equal if renaming the parameter makes them equal. However, the Lean elaborator does not introduce a local binding for non-dependent functions' parameters.

<a id="Definitional-Equality-of-Dependent-and-Non-Dependent-Functions"></a>
Definitional Equality of Dependent and Non-Dependent Functions 

The types `(x : Nat) → String` and `Nat → String` are definitionally equal:

```proofscript
example : ((x : Nat) → String) = (Nat → String) :=
  rfl
```

Similarly, the types `(n : Nat) → n + 1 = 1 + n` and `(k : Nat) → k + 1 = 1 + k` are definitionally equal:

```proofscript
example : ((n : Nat) → n + 1 = 1 + n) = ((k : Nat) → k + 1 = 1 + k) :=
  rfl
```

<a id="Non-Dependent-Functions-Don___t-Bind-Variables"></a>
Non-Dependent Functions Don't Bind Variables 

A dependent function is required in the following statement that all elements of an array are non-zero:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function AllNonZero (xs : Array Nat) : Prop :=
  (i : Nat) → (lt : i < xs.size) → xs[i] ≠ 0
```

This is because the elaborator for array access requires a proof that the index is in bounds. The non-dependent version of the statement does not introduce this assumption:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function AllNonZero (xs : Array Nat) : Prop :=
  (i : Nat) → (i < xs.size) → xs[i] ≠ 0
```

```lean
failed to prove index is valid, possible solutions:
  - Use `have`-expressions to prove the index is valid
  - Use `a[i]!` notation instead, runtime check is performed, and 'Panic' error message is produced if index is not valid
  - Use `a[i]?` notation instead, result is an `Option` type
  - Use `a[i]'h` notation instead, where `h` is a proof that index is valid
xs:Array Nati:Nat⊢ i < xs.size
```

While the core type theory does not feature [implicit](../../Terms/Functions/index.md#--tech-term-implicit) parameters, function types do include an indication of whether the parameter is implicit. This information is used by the Lean elaborator, but it does not affect type checking or definitional equality in the core theory and can be ignored when thinking only about the core type theory.

<a id="Definitional-Equality-of-Implicit-and-Explicit-Function-Types"></a>
Definitional Equality of Implicit and Explicit Function Types 

The types `{α : Type} → (x : α) → α` and `(α : Type) → (x : α) → α` are definitionally equal, even though the first parameter is implicit in one and explicit in the other.

```proofscript
example :
    ({α : Type} → (x : α) → α)
    =
    ((α : Type) → (x : α) → α)
  := rfl
```

<a id="The-Lean-Language-Reference--The-Type-System--Functions--Function-Abstractions"></a>
### 4.1.1. Function Abstractions

In Lean's type theory, functions are created using 
<a id="--tech-term-function-abstractions"></a>
*function abstractions* that bind a variable. In various communities, function abstractions are also known as *lambdas*, due to Alonzo Church's notation for them, or *anonymous functions* because they don't need to be defined with a name in the global environment. When the function is applied, the result is found by [β-reduction](../index.md#--tech-term-___): substituting the argument for the bound variable. In compiled code, this happens strictly: the argument must already be a value. When type checking, there are no such restrictions; the equational theory of definitional equality allows β-reduction with any term.

In Lean's [term language](../../Terms/Functions/index.md#function-terms), function abstractions may take multiple parameters or use pattern matching. These features are translated to simpler operations in the core language, where all functions abstractions take exactly one parameter. Not all functions originate from abstractions: [type constructors](../Inductive-Types/index.md#--tech-term-type-constructors), [constructors](../Inductive-Types/index.md#--tech-term-constructors), and [recursors](../Inductive-Types/index.md#--tech-term-recursor) may have function types, but they cannot be defined using function abstractions alone.

<a id="currying"></a>
### 4.1.2. Currying

In Lean's core type theory, every function maps each element of the [domain](index.md#--tech-term-domain) to a single element of the [codomain](index.md#--tech-term-codomain). In other words, every function expects exactly one parameter. Multiple-parameter functions are implemented by defining higher-order functions that, when supplied with the first parameter, return a new function that expects the remaining parameters. This encoding is called 
<a id="--tech-term-currying"></a>
*currying*, popularized by and named after Haskell B. Curry. Lean's syntax for defining functions, specifying their types, and applying them creates the illusion of multiple-parameter functions, but the result of elaboration contains only single-parameter functions.

<a id="function-extensionality"></a>
### 4.1.3. Extensionality

Definitional equality of functions in Lean is 
<a id="--tech-term-intensional"></a>
*intensional*. This means that definitional equality is defined *syntactically*, modulo renaming of bound variables and [reduction](../index.md#--tech-term-reduction). To a first approximation, this means that two functions are definitionally equal if they implement the same algorithm, rather than the usual mathematical notion of equality that states that two functions are equal if they map equal elements of the [domain](index.md#--tech-term-domain) to equal elements of the [codomain](index.md#--tech-term-codomain).

Definitional equality is used by the type checker, so it's important that it be predictable. The syntactic character of intensional equality means that the algorithm to check it can be feasibly specified. Checking extensional equality involves proving essentially arbitrary theorems about equality of functions, and there is no clear specification for an algorithm to check it. This makes extensional equality a poor choice for a type checker. Function extensionality is instead made available as a reasoning principle that can be invoked when proving the [proposition](../Propositions/index.md#--tech-term-Propositions) that two functions are equal.

In addition to reduction and renaming of bound variables, definitional equality does support one limited form of extensionality, called [*η-equivalence*](../index.md#--tech-term-___-equivalence), in which functions are equal to abstractions whose bodies apply them to the argument. Given `f` with type `(x : α) → β x`, `f` is definitionally equal to `fun x => f x`.

When reasoning about functions, the theorem `funext`Unlike some intensional type theories, `funext` is a theorem in Lean. It can be proved [using quotient types](../Quotients/index.md#quotient-funext). or the corresponding tactics `funext` or `ext` can be used to prove that two functions are equal if they map equal inputs to equal outputs.

<a id="funext"></a>

**theorem**

```text
funext.{u, v} {α : Sort u} {β : α → Sort v} {f g : (x : α) → β x}
  (h : ∀ (x : α), f x = g x) : f = g
```

**Function extensionality.** If two functions return equal results for all possible arguments, then they are equal.

It is called “extensionality” because it provides a way to prove two objects equal based on the properties of the underlying mathematical functions, rather than based on the syntax used to denote them. Function extensionality is a theorem that can be [proved using quotient types](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=quotient-funext).

<a id="totality"></a>
### 4.1.4. Totality and Termination

Functions can be defined recursively using `def`. From the perspective of Lean's logic, all functions are 
<a id="--tech-term-total"></a>
*total*, meaning that they map each element of the [domain](index.md#--tech-term-domain) to an element of the [codomain](index.md#--tech-term-codomain) in finite time.Some programming language communities use the term *total* in a different sense, where functions are considered total if they do not crash due to unhandled cases but non-termination is ignored. The values of total functions are defined for all type-correct arguments, and they cannot fail to terminate or crash due to a missing case in a pattern match.

While the logical model of Lean considers all functions to be total, Lean is also a practical programming language that provides certain “escape hatches”. Functions that have not been proven to terminate can still be used in Lean's logic as long as their [codomain](index.md#--tech-term-codomain) is proven nonempty. These functions are treated as uninterpreted functions by Lean's logic, and their computational behavior is ignored. In compiled code, these functions are treated just like any others. Other functions may be marked unsafe; these functions are not available to Lean's logic at all. The section on [partial and unsafe function definitions](../../Definitions/Recursive-Definitions/index.md#partial-unsafe) contains more detail on programming with recursive functions.

Similarly, operations that should fail at runtime in compiled code, such as out-of-bounds access to an array, can only be used when the resulting type is known to be inhabited. These operations result in an arbitrarily chosen inhabitant of the type in Lean's logic (specifically, the one specified in the type's `Inhabited` instance).

<a id="Panic"></a>
Panic 

The function `thirdChar` extracts the third element of an array, or panics if the array has two or fewer elements:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="thirdChar-_LPAR_in-Panic_RPAR_"></a>


```proofscript
function thirdChar (xs : Array Char) : Char := xs[2]!
```

The (nonexistent) third elements of `#['!']` and `#['-', 'x']` are equal, because they result in the same arbitrarily-chosen character:

```proofscript
example : thirdChar #['!'] = thirdChar #['-', 'x'] := rfl
```

Indeed, both are equal to `'A'`, which happens to be the default fallback for `Char`:

```proofscript
example : thirdChar #['!'] = 'A' := rfl
example : thirdChar #['-', 'x'] = 'A' := rfl
```

<a id="function-api"></a>
### 4.1.5. API Reference

The `Function` namespace contains general-purpose helpers for working with functions.

<a id="Function___comp"></a>

**def**

```text
Function.comp.{u, v, w} {α : Sort u} {β : Sort v} {δ : Sort w}
  (f : β → δ) (g : α → β) : α → δ
```

Function composition, usually written with the infix operator `∘`. A new function is created from two existing functions, where one function's output is used as input to the other.

Examples:

- `Function.comp List.reverse (List.drop 2) [3, 2, 4, 1] = [1, 4]`
- `(List.reverse ∘ List.drop 2) [3, 2, 4, 1] = [1, 4]`

Conventions for notations in identifiers:

- The recommended spelling of `∘` in identifiers is `comp`.

<a id="Function___const"></a>

**def**

```text
Function.const.{u, v} {α : Sort u} (β : Sort v) (a : α) : β → α
```

The constant function that ignores its argument.

If `a : α`, then `Function.const β a : β → α` is the “constant function with value `a`”. For all arguments `b : β`, `Function.const β a b = a`. It is often written directly as `fun _ => a`.

Examples:

- `Function.const Bool 10 true = 10`
- `Function.const Bool 10 false = 10`
- `Function.const String 10 "any string" = 10`

<a id="Function___curry"></a>

**def**

```text
Function.curry.{u_1, u_2, u_3} {α : Type u_1} {β : Type u_2}
  {φ : Sort u_3} : (α × β → φ) → α → β → φ
```

Transforms a function from pairs into an equivalent two-parameter function.

Examples:

- `Function.curry (fun (x, y) => x + y) 3 5 = 8`
- `Function.curry Prod.swap 3 "five" = ("five", 3)`

<a id="Function___uncurry"></a>

**def**

```text
Function.uncurry.{u_1, u_2, u_3} {α : Type u_1} {β : Type u_2}
  {φ : Sort u_3} : (α → β → φ) → α × β → φ
```

Transforms a two-parameter function into an equivalent function from pairs.

Examples:

- `Function.uncurry List.drop (1, ["a", "b", "c"]) = ["b", "c"]`
- `[("orange", 2), ("android", 3) ].map (Function.uncurry String.take) = ["or", "and"]`

<a id="function-api-properties"></a>
#### 4.1.5.1. Properties

<a id="Function___Injective"></a>

**def**

```text
Function.Injective.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  (f : α → β) : Prop
```

A function `f : α → β` is called injective if `f x = f y` implies `x = y`.

<a id="Function___Surjective"></a>

**def**

```text
Function.Surjective.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  (f : α → β) : Prop
```

A function `f : α → β` is called surjective if every `b : β` is equal to `f a` for some `a : α`.

<a id="Function___LeftInverse"></a>

**def**

```text
Function.LeftInverse.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  (g : β → α) (f : α → β) : Prop
```

`LeftInverse g f` means that `g` is a left inverse to `f`. That is, `g ∘ f = id`.

<a id="Function___HasLeftInverse"></a>

**def**

```text
Function.HasLeftInverse.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  (f : α → β) : Prop
```

`HasLeftInverse f` means that `f` has an unspecified left inverse.

<a id="Function___RightInverse"></a>

**def**

```text
Function.RightInverse.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  (g : β → α) (f : α → β) : Prop
```

`RightInverse g f` means that `g` is a right inverse to `f`. That is, `f ∘ g = id`.

<a id="Function___HasRightInverse"></a>

**def**

```text
Function.HasRightInverse.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  (f : α → β) : Prop
```

`HasRightInverse f` means that `f` has an unspecified right inverse.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
failed to prove index is valid, possible solutions:
  - Use `have`-expressions to prove the index is valid
  - Use `a[i]!` notation instead, runtime check is performed, and 'Panic' error message is produced if index is not valid
  - Use `a[i]?` notation instead, result is an `Option` type
  - Use `a[i]'h` notation instead, where `h` is a proof that index is valid
xs:Array Nati:Nat⊢ i < xs.size
```

