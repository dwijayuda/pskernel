<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--API-Reference"></a>

# ProofScript — 18.4. API Reference

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functor, applicative and monad interfaces are ordinary typeclasses and definitions. Their laws are separate propositions, not automatic consequences of defining methods. The order of StateT and ExceptT changes failure and state behavior. do is native sequencing, not a JavaScript statement language. Local mutation, loops and return use that grammar and its scope.

**Compiler and coverage boundary.** Native semicolons within do and local let expressions remain valid. Do not remove all semicolons, reinterpret every newline, or assume discarding a state value reverses external effects.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Functors___-Monads-and--do--Notation/API-Reference/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Functors___-Monads-and--do--Notation/API-Reference/index.html). Source Git blob: `0c28fab09fc6e6f8001883cb1fa0a20977a68f71`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 18.4. API Reference

In addition to the general functions described here, there are some functions that are conventionally defined as part of the API of in the namespace of each collection type:

- `mapM` maps a monadic function.
- `forM` maps a monadic function, throwing away the result.
- `filterM` filters using a monadic predicate, returning the values that satisfy it.

<a id="Monadic-Collection-Operations"></a>
Monadic Collection Operations 

`Array.filterM` can be used to write a filter that depends on a side effect.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="values-_LPAR_in-Monadic-Collection-Operations_RPAR_"></a>
<a id="main-_LPAR_in-Monadic-Collection-Operations_RPAR_"></a>


```proofscript
const values := #[1, 2, 3, 5, 8]
const main : IO Unit := do
  let filtered ← values.filterM fun v => do
    repeat
      IO.println s!"Keep {v}? [y/n]"
      let answer := (← (← IO.getStdin).getLine).trimAscii.copy
      if answer == "y" then return true
      if answer == "n" then return false
    return false
  IO.println "These values were kept:"
  for v in filtered do
    IO.println s!" * {v}"
```

 `stdin``y``n``oops``y``n``y`  `stdout``Keep 1? [y/n]``Keep 2? [y/n]``Keep 3? [y/n]``Keep 3? [y/n]``Keep 5? [y/n]``Keep 8? [y/n]``These values were kept:``* 1``* 3``* 8`   

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--API-Reference--Discarding-Results"></a>
### 18.4.1. Discarding Results

The `discard` function is especially useful when using an action that returns a value only for its side effects.

<a id="Functor___discard"></a>

**def**

```text
Functor.discard.{u, v} {f : Type u → Type v} {α : Type u} [Functor f]
  (x : f α) : f PUnit
```

Discards the value in a functor, retaining the functor's structure.

Discarding values is especially useful when using `Applicative` functors or `Monad`s to implement effects, and some operation should be carried out only for its effects. In `do`-notation, statements whose values are discarded must return `Unit`, and `discard` can be used to explicitly discard their values.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--API-Reference--Control-Flow"></a>
### 18.4.2. Control Flow

<a id="guard"></a>

**def**

```text
guard.{v} {f : Type → Type v} [Alternative f] (p : Prop) [Decidable p] :
  f Unit
```

If the proposition `p` is true, does nothing, else fails (using `failure`).

<a id="optional"></a>

**def**

```text
optional.{u, v} {f : Type u → Type v} [Alternative f] {α : Type u}
  (x : f α) : f (Option α)
```

Returns `some x` if `f` succeeds with value `x`, else returns `none`.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--API-Reference--Lifting-Boolean-Operations"></a>
### 18.4.3. Lifting Boolean Operations

<a id="andM"></a>

**def**

```text
andM.{u, v} {m : Type u → Type v} {β : Type u} [Monad m] [ToBool β]
  (x y : m β) : m β
```

Converts the result of the monadic action `x` to a `Bool`. If it is `true`, returns `y`; otherwise, returns the original result of `x`.

This is a monadic counterpart to the short-circuiting `&&` operator, usually accessed via the `<&&>` operator.

Conventions for notations in identifiers:

- The recommended spelling of `<&&>` in identifiers is `andM`.

<a id="orM"></a>

**def**

```text
orM.{u, v} {m : Type u → Type v} {β : Type u} [Monad m] [ToBool β]
  (x y : m β) : m β
```

Converts the result of the monadic action `x` to a `Bool`. If it is `true`, returns it and ignores `y`; otherwise, runs `y` and returns its result.

This is a monadic counterpart to the short-circuiting `||` operator, usually accessed via the `<||>` operator.

Conventions for notations in identifiers:

- The recommended spelling of `<||>` in identifiers is `orM`.

<a id="notM"></a>

**def**

```text
notM.{v} {m : Type → Type v} [Functor m] (x : m Bool) : m Bool
```

Runs a monadic action and returns the negation of its result.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--API-Reference--Kleisli-Composition"></a>
### 18.4.4. Kleisli Composition

<a id="--tech-term-Kleisli-composition"></a>
*Kleisli composition* is the composition of monadic functions, analogous to `Function.comp` for ordinary functions.

<a id="Bind___kleisliRight"></a>

**def**

```text
Bind.kleisliRight.{u, u_1, u_2} {α : Type u} {m : Type u_1 → Type u_2}
  {β γ : Type u_1} [Bind m] (f₁ : α → m β) (f₂ : β → m γ) (a : α) : m γ
```

Left-to-right composition of Kleisli arrows.

Conventions for notations in identifiers:

- The recommended spelling of `>=>` in identifiers is `kleisliRight`.

<a id="Bind___kleisliLeft"></a>

**def**

```text
Bind.kleisliLeft.{u, u_1, u_2} {α : Type u} {m : Type u_1 → Type u_2}
  {β γ : Type u_1} [Bind m] (f₂ : β → m γ) (f₁ : α → m β) (a : α) : m γ
```

Right-to-left composition of Kleisli arrows.

Conventions for notations in identifiers:

- The recommended spelling of `<=<` in identifiers is `kleisliLeft`.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--API-Reference--Re-Ordered-Operations"></a>
### 18.4.5. Re-Ordered Operations

Sometimes, it can be convenient to partially apply a function to its second argument. These functions reverse the order of arguments, making it this easier.

<a id="Functor___mapRev"></a>

**def**

```text
Functor.mapRev.{u, v} {f : Type u → Type v} [Functor f] {α β : Type u} :
  f α → (α → β) → f β
```

Maps a function over a functor, with parameters swapped so that the function comes last.

This function is `Functor.map` with the parameters reversed, typically used via the `<&>` operator.

Conventions for notations in identifiers:

- The recommended spelling of `<&>` in identifiers is `mapRev`.

<a id="Bind___bindLeft"></a>

**def**

```text
Bind.bindLeft.{u, u_1} {α : Type u} {m : Type u → Type u_1} {β : Type u}
  [Bind m] (f : α → m β) (ma : m α) : m β
```

Same as `Bind.bind` but with arguments swapped.

Conventions for notations in identifiers:

- The recommended spelling of `=<<` in identifiers is `bindLeft`.
