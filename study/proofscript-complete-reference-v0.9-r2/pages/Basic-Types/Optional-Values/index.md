<a id="option"></a>

# ProofScript — 20.12. Optional Values

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Optional-Values/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Optional-Values/index.html). Source Git blob: `e77c408a96dfbffb6ab27d2f73e871232fa68f5c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.12. Optional Values

`Option α` is the type of values which are either `some v` for some `v` `:` `α`, or `none`. In functional programming, this type is used similarly to nullable types: `none` represents the absence of a value. Additionally, partial functions from `α` to `β` can be represented by the type `α → Option β`, where `none` results when the function is undefined for some input. Computationally, these partial functions represent the possibility of failure or errors, and they correspond to a program that can terminate early but not throw an informative exception.

`Option` can also be thought of as being similar to a list that contains at most one element. From this perspective, iterating over `Option` consists of carrying out an operation only when a value is present. The `Option` API makes frequent use of this perspective.

<a id="Options-as-Nullability"></a>
Options as Nullability 

The function `Std.HashMap.get?` looks up a specified key `a : α` inside a `HashMap α β`:

```proofscript
Std.HashMap.get?.{u, v} {α : Type u} {β : Type v}
  [BEq α] [Hashable α]
  (m : HashMap α β) (a : α) :
  Option β
```

Because there is no way to know in advance whether the key is actually in the map, the return type is `Option β`, where `none` means the key was not in the map, and `some b` means that the key was found and `b` is the value retrieved.

The `xs[i]` syntax, which is used to index into collections when there is an available proof that `i` is a valid index into `xs`, has a variant `xs[i]?` that returns an optional value depending on whether the given index is valid. If `m` `:` `HashMap α β` and `a` `:` `α`, then `m[a]?` is equivalent to `HashMap.get? m a`.

<a id="Options-as-Safe-Nullability"></a>
Options as Safe Nullability 

In many programming languages, it is important to remember to check for the null value. When using `Option`, the type system requires these checks in the right places: `Option α` and `α` are not the same type, and converting from one to the other requires handling the case of `none`. This can be done via helpers such as `Option.getD`, or with pattern matching.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="postalCodes-_LPAR_in-Options-as-Safe-Nullability_RPAR_"></a>


```proofscript
const postalCodes : Std.HashMap Nat String :=
  Std.HashMap.emptyWithCapacity 1 |>.insert 12345 "Schenectady"
```

```proofscript
#eval postalCodes[12346]?.getD "not found"
```

```lean
"not found"
```

```proofscript
#eval
  match postalCodes[12346]? with
  | none => "not found"
  | some city => city
```

```lean
"not found"
```

```proofscript
#eval
  if let some city := postalCodes[12345]? then
    city
  else
    "not found"
```

```lean
"Schenectady"
```

<a id="Option___none"></a>

**inductive type**

```text
Option.{u} (α : Type u) : Type u
```

Optional values, which are either `some` around a value from the underlying type or `none`.

`Option` can represent nullable types or computations that might fail. In the codomain of a function type, it can also represent partiality.

**Constructors**

```text
Option.none.{u} {α : Type u} : Option α
```

No value.

```text
Option.some.{u} {α : Type u} (val : α) : Option α
```

Some value of type `α`.

<a id="The-Lean-Language-Reference--Basic-Types--Optional-Values--Coercions"></a>
### 20.12.1. Coercions

There is a [coercion](../../Coercions/index.md#--tech-term-coercion) from `α` to `Option α` that wraps a value in `some`. This allows `Option` to be used in a style similar to nullable types in other languages, where values that are missing are indicated by `none` and values that are present are not specially marked.

<a id="Coercions-and--Option"></a>
Coercions and `Option` 

In `getAlpha`, a line of input is read. If the line consists only of letters (after removing whitespace from the beginning and end of it), then it is returned; otherwise, the function returns `none`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="getAlpha-_LPAR_in-Coercions-and--Option_RPAR_"></a>


```proofscript
const getAlpha : IO (Option String.Slice) := do
  let line := (← (← IO.getStdin).getLine).trimAscii
  if !line.isEmpty && line.all Char.isAlpha then
    return line
  else
    return none
```

In the successful case, there is no explicit `some` wrapped around `line`. The `some` is automatically inserted by the coercion.

<a id="The-Lean-Language-Reference--Basic-Types--Optional-Values--API-Reference"></a>
### 20.12.2. API Reference

<a id="The-Lean-Language-Reference--Basic-Types--Optional-Values--API-Reference--Extracting-Values"></a>
#### 20.12.2.1. Extracting Values

<a id="Option___get"></a>

**def**

```text
Option.get.{u} {α : Type u} (o : Option α) : o.isSome = true → α
```

Extracts the value from an option that can be proven to be `some`.

<a id="Option___get___"></a>

**def**

```text
Option.get!.{u} {α : Type u} [Inhabited α] : Option α → α
```

Extracts the value from an `Option`, panicking on `none`.

<a id="Option___getD"></a>

**def**

```text
Option.getD.{u_1} {α : Type u_1} (opt : Option α) (dflt : α) : α
```

Gets an optional value, returning a given default on `none`.

This function is `@[macro_inline]`, so `dflt` will not be evaluated unless `opt` turns out to be `none`.

Examples:

- `(some "hello").getD "goodbye" = "hello"`
- `none.getD "goodbye" = "goodbye"`

<a id="Option___getDM"></a>

**def**

```text
Option.getDM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1}
  [Pure m] (x : Option α) (y : m α) : m α
```

Gets the value in an option, monadically computing a default value on `none`.

This is the monadic analogue of `Option.getD`.

<a id="Option___getM"></a>

**def**

```text
Option.getM.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1}
  [Alternative m] : Option α → m α
```

Lifts an optional value to any `Alternative`, sending `none` to `failure`.

<a id="Option___elim"></a>

**def**

```text
Option.elim.{u_1, u_2} {α : Type u_1} {β : Sort u_2} :
  Option α → β → (α → β) → β
```

A case analysis function for `Option`.

Given a value for `none` and a function to apply to the contents of `some`, `Option.elim` checks which constructor a given `Option` consists of, and uses the appropriate argument.

`Option.elim` is an elimination principle for `Option`. In particular, it is a non-dependent version of `Option.recOn`. It can also be seen as a combination of `Option.map` and `Option.getD`.

Examples:

- `(some "hello").elim 0 String.length = 5`
- `none.elim 0 String.length = 0`

<a id="Option___elimM"></a>

**def**

```text
Option.elimM.{u_1, u_2} {m : Type u_1 → Type u_2} {α β : Type u_1}
  [Monad m] (x : m (Option α)) (y : m β) (z : α → m β) : m β
```

A monadic case analysis function for `Option`.

Given a fallback computation for `none` and a monadic operation to apply to the contents of `some`, `Option.elimM` checks which constructor a given `Option` consists of, and uses the appropriate argument.

`Option.elimM` can also be seen as a combination of `Option.mapM` and `Option.getDM`. It is a monadic analogue of `Option.elim`.

<a id="Option___merge"></a>

**def**

```text
Option.merge.{u_1} {α : Type u_1} (fn : α → α → α) :
  Option α → Option α → Option α
```

Applies a function to a two optional values if both are present. Otherwise, if one value is present, it is returned and the function is not used.

The value is `some (fn a b)` if the inputs are `some a` and `some b`. Otherwise, the behavior is equivalent to `Option.orElse`: if only one input is `some x`, then the value is `some x`, and if both are `none`, then the value is `none`.

Examples:

- `Option.merge (· + ·) none (some 3) = some 3`
- `Option.merge (· + ·) (some 2) (some 3) = some 5`
- `Option.merge (· + ·) (some 2) none = some 2`
- `Option.merge (· + ·) none none = none`

<a id="The-Lean-Language-Reference--Basic-Types--Optional-Values--API-Reference--Properties-and-Comparisons"></a>
#### 20.12.2.2. Properties and Comparisons

<a id="Option___isNone"></a>

**def**

```text
Option.isNone.{u_1} {α : Type u_1} : Option α → Bool
```

Returns `true` on `none` and `false` on `some x`.

This function is more flexible than `(· == none)` because it does not require a `BEq α` instance.

Examples:

- `(none : Option Nat).isNone = true`
- `(some Nat.add).isNone = false`

<a id="Option___isSome"></a>

**def**

```text
Option.isSome.{u_1} {α : Type u_1} : Option α → Bool
```

Returns `true` on `some x` and `false` on `none`.

<a id="Option___isEqSome"></a>

**def**

```text
Option.isEqSome.{u_1} {α : Type u_1} [BEq α] : Option α → α → Bool
```

Checks whether an optional value is both present and equal to some other value.

Given `x? : Option α` and `y : α`, `x?.isEqSome y` is equivalent to `x? == some y`. It is more efficient because it avoids an allocation.

Ordering of optional values typically uses the `DecidableEq (Option α)`, `LT (Option α)`, `Min (Option α)`, and `Max (Option α)` instances.

<a id="Option___min"></a>

**def**

```text
Option.min.{u_1} {α : Type u_1} [Min α] : Option α → Option α → Option α
```

The minimum of two optional values, with `none` treated as the least element. This function is usually accessed through the `Min (Option α)` instance, rather than directly.

Prior to `nightly-2025-02-27`, `none` was treated as the greatest element, so `min none (some x) = min (some x) none = some x`.

Examples:

- `Option.min (some 2) (some 5) = some 2`
- `Option.min (some 5) (some 2) = some 2`
- `Option.min (some 2) none = none`
- `Option.min none (some 5) = none`
- `Option.min none none = none`

<a id="Option___max"></a>

**def**

```text
Option.max.{u_1} {α : Type u_1} [Max α] : Option α → Option α → Option α
```

The maximum of two optional values.

This function is usually accessed through the `Max (Option α)` instance, rather than directly.

Examples:

- `Option.max (some 2) (some 5) = some 5`
- `Option.max (some 5) (some 2) = some 5`
- `Option.max (some 2) none = some 2`
- `Option.max none (some 5) = some 5`
- `Option.max none none = none`

<a id="Option___lt"></a>

**def**

```text
Option.lt.{u_1, u_2} {α : Type u_1} {β : Type u_2} (r : α → β → Prop) :
  Option α → Option β → Prop
```

Lifts an ordering relation to `Option`, such that `none` is the least element.

It can be understood as adding a distinguished least element, represented by `none`, to both `α` and `β`.

This definition is part of the implementation of the `LT (Option α)` instance. However, because it can be used with heterogeneous relations, it is sometimes useful on its own.

Examples:

- `Option.lt (fun n k : Nat => n < k) none none = False`
- `Option.lt (fun n k : Nat => n < k) none (some 3) = True`
- `Option.lt (fun n k : Nat => n < k) (some 3) none = False`
- `Option.lt (fun n k : Nat => n < k) (some 4) (some 5) = True`
- `Option.lt (fun n k : Nat => n < k) (some 4) (some 4) = False`

<a id="Option___decidableEqNone"></a>

**def**

```text
Option.decidableEqNone.{u_1} {α : Type u_1} (o : Option α) :
  Decidable (o = none)
```

Equality with `none` is decidable even if the wrapped type does not have decidable equality.

<a id="The-Lean-Language-Reference--Basic-Types--Optional-Values--API-Reference--Conversion"></a>
#### 20.12.2.3. Conversion

<a id="Option___toArray"></a>

**def**

```text
Option.toArray.{u_1} {α : Type u_1} : Option α → Array α
```

Converts an optional value to an array with zero or one element.

Examples:

- `(some "value").toArray = #["value"]`
- `none.toArray = #[]`

<a id="Option___toList"></a>

**def**

```text
Option.toList.{u_1} {α : Type u_1} : Option α → List α
```

Converts an optional value to a list with zero or one element.

Examples:

- `(some "value").toList = ["value"]`
- `none.toList = []`

<a id="Option___repr"></a>

**def**

```text
Option.repr.{u_1} {α : Type u_1} [Repr α] : Option α → Nat → Std.Format
```

Returns a representation of an optional value that should be able to be parsed as an equivalent optional value.

This function is typically accessed through the `Repr (Option α)` instance.

<a id="Option___format"></a>

**def**

```text
Option.format.{u} {α : Type u} [Std.ToFormat α] : Option α → Std.Format
```

Formats an optional value, with no expectation that the Lean parser should be able to parse the result.

This function is usually accessed through the `ToFormat (Option α)` instance.

<a id="The-Lean-Language-Reference--Basic-Types--Optional-Values--API-Reference--Control"></a>
#### 20.12.2.4. Control

`Option` can be thought of as describing a computation that may fail to return a value. The `Monad Option` instance, along with `Alternative Option`, is based on this understanding. Returning `none` can also be thought of as throwing an exception that contains no interesting information, which is captured in the `MonadExcept Unit Option` instance.

<a id="Option___guard"></a>

**def**

```text
Option.guard.{u_1} {α : Type u_1} (p : α → Bool) (a : α) : Option α
```

Returns `none` if a value doesn't satisfy a Boolean predicate, or the value itself otherwise.

From the perspective of `Option` as computations that might fail, this function is a run-time assertion operator in the `Option` monad.

Examples:

- `Option.guard (· > 2) 1 = none`
- `Option.guard (· > 2) 5 = some 5`

<a id="Option___bind"></a>

**def**

```text
Option.bind.{u_1, u_2} {α : Type u_1} {β : Type u_2} :
  Option α → (α → Option β) → Option β
```

Sequencing of `Option` computations.

From the perspective of `Option` as computations that might fail, this function sequences potentially-failing computations, failing if either fails. From the perspective of `Option` as a collection with at most one element, the function is applied to the element if present, and the final result is empty if either the initial or the resulting collections are empty.

This function is often accessed via the `>>=` operator from the `Bind (Option α)` instance, or implicitly via `do`-notation, but it is also idiomatic to call it using [generalized field notation](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=generalized-field-notation).

Examples:

- `none.bind (fun x => some x) = none`
- `(some 4).bind (fun x => some x) = some 4`
- `none.bind (Option.guard (· > 2)) = none`
- `(some 2).bind (Option.guard (· > 2)) = none`
- `(some 4).bind (Option.guard (· > 2)) = some 4`

<a id="Option___bindM"></a>

**def**

```text
Option.bindM.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3}
  {β : Type u_1} [Pure m] (f : α → m (Option β)) :
  Option α → m (Option β)
```

Runs the monadic action `f` on `o`'s value, if any, and returns the result, or `none` if there is no value.

From the perspective of `Option` as a collection with at most one element, the monadic the function is applied to the element if present, and the final result is empty if either the initial or the resulting collections are empty.

<a id="Option___join"></a>

**def**

```text
Option.join.{u_1} {α : Type u_1} (x : Option (Option α)) : Option α
```

Flattens nested optional values, preserving any value found.

This is analogous to `List.flatten`.

Examples:

- `none.join = none`
- `(some none).join = none`
- `(some (some v)).join = some v`

<a id="Option___sequence"></a>

**def**

```text
Option.sequence.{u, u_1} {m : Type u → Type u_1} [Applicative m]
  {α : Type u} : Option (m α) → m (Option α)
```

Converts an optional monadic computation into a monadic computation of an optional value.

This function only requires `m` to be an applicative functor.

Example:

```proofscript
#eval show IO (Option String) from
  Option.sequence <| some do
    IO.println "hello"
    return "world"
```

```text
hello
```

```proofscript
some "world"
```

<a id="Option___tryCatch"></a>

**def**

```text
Option.tryCatch.{u_1} {α : Type u_1} (x : Option α)
  (handle : Unit → Option α) : Option α
```

Recover from failing `Option` computations with a handler function.

This function is usually accessed through the `MonadExceptOf Unit Option` instance.

Examples:

- `Option.tryCatch none (fun () => some "handled") = some "handled"`
- `Option.tryCatch (some "succeeded") (fun () => some "handled") = some "succeeded"`

<a id="Option___or"></a>

**def**

```text
Option.or.{u_1} {α : Type u_1} : Option α → Option α → Option α
```

Returns the first of its arguments that is `some`, or `none` if neither is `some`.

This is similar to the `<|>` operator, also known as `OrElse.orElse`, but both arguments are always evaluated without short-circuiting.

<a id="Option___orElse"></a>

**def**

```text
Option.orElse.{u_1} {α : Type u_1} :
  Option α → (Unit → Option α) → Option α
```

Implementation of `OrElse`'s `<|>` syntax for `Option`. If the first argument is `some a`, returns `some a`, otherwise evaluates and returns the second argument.

See also `or` for a version that is strict in the second argument.

<a id="The-Lean-Language-Reference--Basic-Types--Optional-Values--API-Reference--Iteration"></a>
#### 20.12.2.5. Iteration

`Option` can be thought of as a collection that contains at most one value. From this perspective, iteration operators can be understood as performing some operation on the contained value, if present, or doing nothing if not.

<a id="Option___all"></a>

**def**

```text
Option.all.{u_1} {α : Type u_1} (p : α → Bool) : Option α → Bool
```

Checks whether an optional value either satisfies a Boolean predicate or is `none`.

Examples:

- `(some 33).all (· % 2 == 0) = false
- `(some 22).all (· % 2 == 0) = true
- `none.all (fun x : Nat => x % 2 == 0) = true

<a id="Option___any"></a>

**def**

```text
Option.any.{u_1} {α : Type u_1} (p : α → Bool) : Option α → Bool
```

Checks whether an optional value is not `none` and satisfies a Boolean predicate.

Examples:

- `(some 33).any (· % 2 == 0) = false
- `(some 22).any (· % 2 == 0) = true
- `none.any (fun x : Nat => true) = false

<a id="Option___filter"></a>

**def**

```text
Option.filter.{u_1} {α : Type u_1} (p : α → Bool) : Option α → Option α
```

Keeps an optional value only if it satisfies a Boolean predicate.

If `Option` is thought of as a collection that contains at most one element, then `Option.filter` is analogous to `List.filter` or `Array.filter`.

Examples:

- `(some 5).filter (· % 2 == 0) = none`
- `(some 4).filter (· % 2 == 0) = some 4`
- `none.filter (fun x : Nat => x % 2 == 0) = none`
- `none.filter (fun x : Nat => true) = none`

<a id="Option___filterM"></a>

**def**

```text
Option.filterM.{u_1} {m : Type → Type u_1} {α : Type} [Applicative m]
  (p : α → m Bool) : Option α → m (Option α)
```

Keeps an optional value only if it satisfies a monadic Boolean predicate.

If `Option` is thought of as a collection that contains at most one element, then `Option.filterM` is analogous to `List.filterM`.

<a id="Option___forM"></a>

**def**

```text
Option.forM.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3}
  [Pure m] : Option α → (α → m PUnit) → m PUnit
```

Executes a monadic action on an optional value if it is present, or does nothing if there is no value.

Examples:

```proofscript
#eval ((some 5).forM set : StateM Nat Unit).run 0
```

```proofscript
((), 5)
```

```proofscript
#eval (none.forM (fun x : Nat => set x) : StateM Nat Unit).run 0
```

```proofscript
((), 0)
```

<a id="Option___map"></a>

**def**

```text
Option.map.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → β) :
  Option α → Option β
```

Apply a function to an optional value, if present.

From the perspective of `Option` as a container with at most one value, this is analogous to `List.map`. It can also be accessed via the `Functor Option` instance.

Examples:

- `(none : Option Nat).map (· + 1) = none`
- `(some 3).map (· + 1) = some 4`

<a id="Option___mapA"></a>

**def**

```text
Option.mapA.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3}
  {β : Type u_1} [Applicative m] (f : α → m β) : Option α → m (Option β)
```

Applies a function in some applicative functor to an optional value, returning `none` with no effects if the value is missing.

This is an alias for `Option.mapM`, which already works for applicative functors.

<a id="Option___mapM"></a>

**def**

```text
Option.mapM.{u_1, u_2, u_3} {m : Type u_1 → Type u_2} {α : Type u_3}
  {β : Type u_1} [Applicative m] (f : α → m β) : Option α → m (Option β)
```

Applies a function in some applicative functor to an optional value, returning `none` with no effects if the value is missing.

Runs a monadic function `f` on an optional value, returning the result. If the optional value is `none`, the function is not called and the result is also `none`.

From the perspective of `Option` as a container with at most one element, this is analogous to `List.mapM`, returning the result of running the monadic function on all elements of the container.

This function only requires `m` to be an applicative functor. An alias `Option.mapA` is provided.

<a id="The-Lean-Language-Reference--Basic-Types--Optional-Values--API-Reference--Recursion-Helpers"></a>
#### 20.12.2.6. Recursion Helpers

<a id="Option___attach"></a>

**def**

```text
Option.attach.{u_1} {α : Type u_1} (xs : Option α) :
  Option { x // xs = some x }
```

“Attaches” a proof that an optional value, if present, is indeed this value, returning a subtype that expresses this fact.

This function is primarily used to allow definitions by well-founded recursion that use iteration operators (such as `Option.map`) to prove that an optional value drawn from a parameter is smaller than the parameter. This allows the well-founded recursion mechanism to prove that the function terminates.

<a id="Option___attachWith"></a>

**def**

```text
Option.attachWith.{u_1} {α : Type u_1} (xs : Option α) (P : α → Prop)
  (H : ∀ (x : α), xs = some x → P x) : Option { x // P x }
```

“Attaches” a proof that some predicate holds for an optional value, if present, returning a subtype that expresses this fact.

This function is primarily used to implement `Option.attach`, which allows definitions by well-founded recursion that use iteration operators (such as `Option.map`) to prove that an optional value drawn from a parameter is smaller than the parameter. This allows the well-founded recursion mechanism to prove that the function terminates.

<a id="Option___unattach"></a>

**def**

```text
Option.unattach.{u_1} {α : Type u_1} {p : α → Prop}
  (o : Option { x // p x }) : Option α
```

Remove an attached proof that the value in an `Option` is indeed that value.

This function is usually inserted automatically by Lean, rather than explicitly in code. It is introduced as an intermediate step during the elaboration of definitions by well-founded recursion.

If this function is encountered in a proof state, the right approach is usually the tactic `simp [Option.unattach, -Option.map_subtype]`.

It is a synonym for `Option.map Subtype.val`.

<a id="The-Lean-Language-Reference--Basic-Types--Optional-Values--API-Reference--Reasoning"></a>
#### 20.12.2.7. Reasoning

<a id="Option___choice"></a>

**def**

```text
Option.choice.{u_1} (α : Type u_1) : Option α
```

An optional arbitrary element of a given type.

If `α` is non-empty, then there exists some `v : α` and this arbitrary element is `some v`. Otherwise, it is `none`.

<a id="Option___pbind"></a>

**def**

```text
Option.pbind.{u_1, u_2} {α : Type u_1} {β : Type u_2} (o : Option α)
  (f : (a : α) → o = some a → Option β) : Option β
```

Given an optional value and a function that can be applied when the value is `some`, returns the result of applying the function if this is possible.

The function `f` is *partial* because it is only defined for the values `a : α` such that `o = some a`. This restriction allows the function to use the fact that it can only be called when `o` is not `none`: it can relate its argument to the optional value `o`. Its runtime behavior is equivalent to that of `Option.bind`.

Examples:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function attach (v : Option α) : Option { y : α // v = some y } :=
  v.pbind fun x h => some ⟨x, h⟩
```

```text
#reduce attach (some 3)
```

```proofscript
some ⟨3, ⋯⟩
```

```text
#reduce attach none
```

```proofscript
none
```

<a id="Option___pelim"></a>

**def**

```text
Option.pelim.{u_1, u_2} {α : Type u_1} {β : Sort u_2} (o : Option α)
  (b : β) (f : (a : α) → o = some a → β) : β
```

Given an optional value and a function that can be applied when the value is `some`, returns the result of applying the function if this is possible, or a fallback value otherwise.

The function `f` is *partial* because it is only defined for the values `a : α` such that `o = some a`. This restriction allows the function to use the fact that it can only be called when `o` is not `none`: it can relate its argument to the optional value `o`. Its runtime behavior is equivalent to that of `Option.elim`.

Examples:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function attach (v : Option α) : Option { y : α // v = some y } :=
  v.pelim none fun x h => some ⟨x, h⟩
```

```text
#reduce attach (some 3)
```

```proofscript
some ⟨3, ⋯⟩
```

```text
#reduce attach none
```

```proofscript
none
```

<a id="Option___pmap"></a>

**def**

```text
Option.pmap.{u_1, u_2} {α : Type u_1} {β : Type u_2} {p : α → Prop}
  (f : (a : α) → p a → β) (o : Option α) :
  (∀ (a : α), o = some a → p a) → Option β
```

Given a function from the elements of `α` that satisfy `p` to `β` and a proof that an optional value satisfies `p` if it's present, applies the function to the value.

Examples:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function attach (v : Option α) : Option { y : α // v = some y } :=
  v.pmap (fun a (h : a ∈ v) => ⟨_, h⟩) (fun _ h => h)
```

```text
#reduce attach (some 3)
```

```proofscript
some ⟨3, ⋯⟩
```

```text
#reduce attach none
```

```proofscript
none
```

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
"not found"
```


### Display 2


```text
"Schenectady"
```


### Display 3


```text
some "world"hello
```


### Display 4


```text
((), 5)
```


### Display 5


```text
((), 0)
```

