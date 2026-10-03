<a id="monads-and-do"></a>

# ProofScript — 18. Functors, Monads and do-Notation

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functor, applicative and monad interfaces are ordinary typeclasses and definitions. Their laws are separate propositions, not automatic consequences of defining methods. The order of StateT and ExceptT changes failure and state behavior. do is native sequencing, not a JavaScript statement language. Local mutation, loops and return use that grammar and its scope.

## ProofScript way of writing it


```proofscript
function total(xs: List Nat): Nat :=
  Id.run(do {
    let mut result := 0
    for x in xs do {
      result := result + x
    }
    return result
  })
```

**Compiler and coverage boundary.** Native semicolons within do and local let expressions remain valid. Do not remove all semicolons, reinterpret every newline, or assume discarding a state value reverses external effects.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Functors___-Monads-and--do--Notation/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Functors___-Monads-and--do--Notation/index.html). Source Git blob: `df5888c30950ae9b3a4b3f650a011476844a777e`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 18. Functors, Monads and do-Notation

The type classes `Functor`, `Applicative`, and `Monad` provide fundamental tools for functional programming.An introduction to programming with these abstractions is available in [*Functional Programming in Lean*](https://lean-lang.org/functional_programming_in_lean/functor-applicative-monad.html). While they are inspired by the concepts of functors and monads in category theory, the versions used for programming are more limited. The type classes in Lean's standard library represent the concepts as used for programming, rather than the general mathematical definition.

Instances of 
<a id="--tech-term-Functor"></a>
`Functor` allow an operation to be applied consistently throughout some polymorphic context. Examples include transforming each element of a list by applying a function and creating new `IO` actions by arranging for a pure function to be applied to the result of an existing `IO` action. Instances of 
<a id="--tech-term-Monad"></a>
`Monad` allow side effects with data dependencies to be encoded; examples include using a tuple to simulate mutable state, a sum type to simulate exceptions, and representing actual side effects with `IO`. 
<a id="--tech-term-Applicative-functors"></a>
`Applicative` functors occupy a middle ground: like monads, they allow functions computed with effects to be applied to arguments that are computed with effects, but they do not allow sequential data dependencies where the output of an effect forms an input into another effectful operation.

The additional type classes `Pure`, `Bind`, `SeqLeft`, `SeqRight`, and `Seq` capture individual operations from `Applicative` and `Monad`, allowing them to be overloaded and used with types that are not necessarily `Applicative` functors or `Monad`s. The `Alternative` type class describes applicative functors that additionally have some notion of failure and recovery.

<a id="Functor___mk"></a>

**type class**

```text
Functor.{u, v} (f : Type u → Type v) : Type (max (u + 1) v)
```

A functor in the sense used in functional programming, which means a function `f : Type u → Type v` has a way of mapping a function over its contents. This `map` operator is written `<$>`, and overloaded via `Functor` instances.

This `map` function should respect identity and function composition. In other words, for all terms `v : f α`, it should be the case that:

- `id <$> v = v`
- For all functions `h : β → γ` and `g : α → β`, `(h ∘ g) <$> v = h <$> g <$> v`

While all `Functor` instances should live up to these requirements, they are not required to *prove* that they do. Proofs may be required or provided via the `LawfulFunctor` class.

Assuming that instances are lawful, this definition corresponds to the category-theoretic notion of [functor](https://en.wikipedia.org/wiki/Functor) in the special case where the category is the category of types and functions between them.

**Instance Constructor**

```text
Functor.mk.{u, v}
```

**Methods**

```text
map : {α β : Type u} → (α → β) → f α → f β
```

Applies a function inside a functor. This is used to overload the `<$>` operator.

When mapping a constant function, use `Functor.mapConst` instead, because it may be more efficient.

Conventions for notations in identifiers:

- The recommended spelling of `<$>` in identifiers is `map`.

```text
mapConst : {α β : Type u} → α → f β → f α
```

Mapping a constant function.

Given `a : α` and `v : f β`, `mapConst a v` is equivalent to `(fun _ => a) <$> v`. For some functors, this can be implemented more efficiently; for all other functors, the default implementation may be used.

<a id="Pure___mk"></a>

**type class**

```text
Pure.{u, v} (f : Type u → Type v) : Type (max (u + 1) v)
```

The `pure` function is overloaded via `Pure` instances.

`Pure` is typically accessed via `Monad` or `Applicative` instances.

**Instance Constructor**

```text
Pure.mk.{u, v}
```

**Methods**

```text
pure : {α : Type u} → α → f α
```

Given `a : α`, then `pure a : f α` represents an action that does nothing and returns `a`.

Examples:

- `(pure "hello" : Option String) = some "hello"`
- `(pure "hello" : Except (Array String) String) = Except.ok "hello"`
- `(pure "hello" : StateM Nat String).run 105 = ("hello", 105)`

<a id="Seq___mk"></a>

**type class**

```text
Seq.{u, v} (f : Type u → Type v) : Type (max (u + 1) v)
```

The `<*>` operator is overloaded using the function `Seq.seq`.

While `<$>` from the class `Functor` allows an ordinary function to be mapped over its contents, `<*>` allows a function that's “inside” the functor to be applied. When thinking about `f` as possible side effects, this captures evaluation order: `seq` arranges for the effects that produce the function to occur prior to those that produce the argument value.

For most applications, `Applicative` or `Monad` should be used rather than `Seq` itself.

**Instance Constructor**

```text
Seq.mk.{u, v}
```

**Methods**

```text
seq : {α β : Type u} → f (α → β) → (Unit → f α) → f β
```

The implementation of the `<*>` operator.

In a monad, `mf <*> mx` is the same as `do let f ← mf; x ← mx; pure (f x)`: it evaluates the function first, then the argument, and applies one to the other.

To avoid surprising evaluation semantics, `mx` is taken "lazily", using a `Unit → f α` function.

Conventions for notations in identifiers:

- The recommended spelling of `<*>` in identifiers is `seq`.

<a id="SeqLeft___mk"></a>

**type class**

```text
SeqLeft.{u, v} (f : Type u → Type v) : Type (max (u + 1) v)
```

The `<*` operator is overloaded using `seqLeft`.

When thinking about `f` as potential side effects, `<*` evaluates first the left and then the right argument for their side effects, discarding the value of the right argument and returning the value of the left argument.

For most applications, `Applicative` or `Monad` should be used rather than `SeqLeft` itself.

**Instance Constructor**

```text
SeqLeft.mk.{u, v}
```

**Methods**

```text
seqLeft : {α β : Type u} → f α → (Unit → f β) → f α
```

Sequences the effects of two terms, discarding the value of the second. This function is usually invoked via the `<*` operator.

Given `x : f α` and `y : f β`, `x <* y` runs `x`, then runs `y`, and finally returns the result of `x`.

The evaluation of the second argument is delayed by wrapping it in a function, enabling “short-circuiting” behavior from `f`.

Conventions for notations in identifiers:

- The recommended spelling of `<*` in identifiers is `seqLeft`.

<a id="SeqRight___mk"></a>

**type class**

```text
SeqRight.{u, v} (f : Type u → Type v) : Type (max (u + 1) v)
```

The `*>` operator is overloaded using `seqRight`.

When thinking about `f` as potential side effects, `*>` evaluates first the left and then the right argument for their side effects, discarding the value of the left argument and returning the value of the right argument.

For most applications, `Applicative` or `Monad` should be used rather than `SeqRight` itself.

**Instance Constructor**

```text
SeqRight.mk.{u, v}
```

**Methods**

```text
seqRight : {α β : Type u} → f α → (Unit → f β) → f β
```

Sequences the effects of two terms, discarding the value of the first. This function is usually invoked via the `*>` operator.

Given `x : f α` and `y : f β`, `x *> y` runs `x`, then runs `y`, and finally returns the result of `y`.

The evaluation of the second argument is delayed by wrapping it in a function, enabling “short-circuiting” behavior from `f`.

Conventions for notations in identifiers:

- The recommended spelling of `*>` in identifiers is `seqRight`.

<a id="Applicative___mk"></a>

**type class**

```text
Applicative.{u, v} (f : Type u → Type v) : Type (max (u + 1) v)
```

An [applicative functor](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=monads-and-do) is more powerful than a `Functor`, but less powerful than a `Monad`.

Applicative functors capture sequencing of effects with the `<*>` operator, overloaded as `seq`, but not data-dependent effects. The results of earlier computations cannot be used to control later effects.

Applicative functors should satisfy four laws. Instances of `Applicative` are not required to prove that they satisfy these laws, which are part of the `LawfulApplicative` class.

**Instance Constructor**

```text
Applicative.mk.{u, v}
```

**Extends**

- <a id="0-Functor-Applicative"></a>
  `Functor f`
- <a id="1-Pure-Applicative"></a>
  `Pure f`
- <a id="2-Seq-Applicative"></a>
  `Seq f`
- <a id="3-SeqLeft-Applicative"></a>
  `SeqLeft f`
- <a id="4-SeqRight-Applicative"></a>
  `SeqRight f`

**Methods**

```text
map : {α β : Type u} → (α → β) → f α → f β
```

 Inherited from 

1. `Functor f`
2. `Pure f`
3. `Seq f`
4. `SeqLeft f`
5. `SeqRight f`

```text
mapConst : {α β : Type u} → α → f β → f α
```

 Inherited from 

1. `Functor f`
2. `Pure f`
3. `Seq f`
4. `SeqLeft f`
5. `SeqRight f`

```text
pure : {α : Type u} → α → f α
```

 Inherited from 

1. `Functor f`
2. `Pure f`
3. `Seq f`
4. `SeqLeft f`
5. `SeqRight f`

```text
seq : {α β : Type u} → f (α → β) → (Unit → f α) → f β
```

 Inherited from 

1. `Functor f`
2. `Pure f`
3. `Seq f`
4. `SeqLeft f`
5. `SeqRight f`

```text
seqLeft : {α β : Type u} → f α → (Unit → f β) → f α
```

 Inherited from 

1. `Functor f`
2. `Pure f`
3. `Seq f`
4. `SeqLeft f`
5. `SeqRight f`

```text
seqRight : {α β : Type u} → f α → (Unit → f β) → f β
```

 Inherited from 

1. `Functor f`
2. `Pure f`
3. `Seq f`
4. `SeqLeft f`
5. `SeqRight f`

<a id="Lists-with-Lengths-as-Applicative-Functors"></a>
Lists with Lengths as Applicative Functors 

The structure `LenList` pairs a list with a proof that it has the desired length. As a consequence, its `zipWith` operator doesn't require a fallback in case the lengths of its inputs differ.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="LenList-_LPAR_in-Lists-with-Lengths-as-Applicative-Functors_RPAR_"></a>
<a id="LenList___list-_LPAR_in-Lists-with-Lengths-as-Applicative-Functors_RPAR_"></a>
<a id="LenList___lengthOk-_LPAR_in-Lists-with-Lengths-as-Applicative-Functors_RPAR_"></a>
<a id="LenList___head-_LPAR_in-Lists-with-Lengths-as-Applicative-Functors_RPAR_"></a>
<a id="LenList___tail-_LPAR_in-Lists-with-Lengths-as-Applicative-Functors_RPAR_"></a>
<a id="LenList___map-_LPAR_in-Lists-with-Lengths-as-Applicative-Functors_RPAR_"></a>
<a id="LenList___zipWith-_LPAR_in-Lists-with-Lengths-as-Applicative-Functors_RPAR_"></a>


```proofscript
structure LenList (length : Nat) (α : Type u) where
  list : List α
  lengthOk : list.length = length

function LenList.head (xs : LenList (n + 1) α) : α :=
  xs.list.head <| by
    intro h
    cases xs
    simp_all
    subst_eqs

function LenList.tail (xs : LenList (n + 1) α) : LenList n α :=
  match xs with
  | ⟨_ :: xs', _⟩ => ⟨xs', by simp_all⟩

def LenList.map (f : α → β) (xs : LenList n α) : LenList n β where
  list := xs.list.map f
  lengthOk := by
    cases xs
    simp [List.length_map, *]

def LenList.zipWith (f : α → β → γ)
    (xs : LenList n α) (ys : LenList n β) :
    LenList n γ where
  list := xs.list.zipWith f ys.list
  lengthOk := by
    cases xs; cases ys
    simp [List.length_zipWith, *]
```

The well-behaved `Applicative` instance applies functions to arguments element-wise. Because `Applicative` extends `Functor`, a separate `Functor` instance is not necessary, and `map` can be defined as part of the `Applicative` instance.

```proofscript
instance : Applicative (LenList n) where
  map := LenList.map
  pure x := {
    list := List.replicate n x
    lengthOk := List.length_replicate
  }
  seq {α β} fs xs := fs.zipWith (· ·) (xs ())
```

The well-behaved `Monad` instance takes the diagonal of the results of applying the function:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="LenList___list_length_eq-_LPAR_in-Lists-with-Lengths-as-Applicative-Functors_RPAR_"></a>
<a id="LenList___diagonal-_LPAR_in-Lists-with-Lengths-as-Applicative-Functors_RPAR_"></a>


```proofscript
@[simp]
theorem LenList.list_length_eq (xs : LenList n α) :
    xs.list.length = n := by
  cases xs
  simp [*]

function LenList.diagonal (square : LenList n (LenList n α)) : LenList n α :=
  match n with
  | 0 => ⟨[], rfl⟩
  | n' + 1 => {
    list :=
      square.head.head :: (square.tail.map (·.tail)).diagonal.list
    lengthOk := by simp
  }
```

<a id="Alternative___mk"></a>

**type class**

```text
Alternative.{u, v} (f : Type u → Type v) : Type (max (u + 1) v)
```

An `Alternative` functor is an `Applicative` functor that can "fail" or be "empty" and a binary operation `<|>` that “collects values” or finds the “left-most success”.

Important instances include

- `Option`, where `failure := none` and `<|>` returns the left-most `some`.
- Parser combinators typically provide an `Applicative` instance for error-handling and backtracking.

Error recovery and state can interact subtly. For example, the implementation of `Alternative` for `OptionT (StateT σ Id)` keeps modifications made to the state while recovering from failure, while `StateT σ (OptionT Id)` discards them.

**Instance Constructor**

```text
Alternative.mk.{u, v}
```

**Extends**

- <a id="0-Applicative-Alternative"></a>
  `Applicative f`

**Methods**

```text
map : {α β : Type u} → (α → β) → f α → f β
```

 Inherited from 

1. `Applicative f`

```text
mapConst : {α β : Type u} → α → f β → f α
```

 Inherited from 

1. `Applicative f`

```text
pure : {α : Type u} → α → f α
```

 Inherited from 

1. `Applicative f`

```text
seq : {α β : Type u} → f (α → β) → (Unit → f α) → f β
```

 Inherited from 

1. `Applicative f`

```text
seqLeft : {α β : Type u} → f α → (Unit → f β) → f α
```

 Inherited from 

1. `Applicative f`

```text
seqRight : {α β : Type u} → f α → (Unit → f β) → f β
```

 Inherited from 

1. `Applicative f`

```text
failure : {α : Type u} → f α
```

Produces an empty collection or recoverable failure. The `<|>` operator collects values or recovers from failures. See `Alternative` for more details.

```text
orElse : {α : Type u} → f α → (Unit → f α) → f α
```

Depending on the `Alternative` instance, collects values or recovers from `failure`s by returning the leftmost success. Can be written using the `<|>` operator syntax.

<a id="Bind___mk"></a>

**type class**

```text
Bind.{u, v} (m : Type u → Type v) : Type (max (u + 1) v)
```

The `>>=` operator is overloaded via instances of `bind`.

`Bind` is typically used via `Monad`, which extends it.

**Instance Constructor**

```text
Bind.mk.{u, v}
```

**Methods**

```text
bind : {α β : Type u} → m α → (α → m β) → m β
```

Sequences two computations, allowing the second to depend on the value computed by the first.

If `x : m α` and `f : α → m β`, then `x >>= f : m β` represents the result of executing `x` to get a value of type `α` and then passing it to `f`.

Conventions for notations in identifiers:

- The recommended spelling of `>>=` in identifiers is `bind`.

<a id="Monad___mk"></a>

**type class**

```text
Monad.{u, v} (m : Type u → Type v) : Type (max (u + 1) v)
```

[Monads](https://en.wikipedia.org/wiki/Monad_%28functional_programming%29) are an abstraction of sequential control flow and side effects used in functional programming. Monads allow both sequencing of effects and data-dependent effects: the values that result from an early step may influence the effects carried out in a later step.

The `Monad` API may be used directly. However, it is most commonly accessed through [`do`-notation](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=do-notation).

Most `Monad` instances provide implementations of `pure` and `bind`, and use default implementations for the other methods inherited from `Applicative`. Monads should satisfy certain laws, but instances are not required to prove this. An instance of `LawfulMonad` expresses that a given monad's operations are lawful.

**Instance Constructor**

```text
Monad.mk.{u, v}
```

**Extends**

- <a id="0-Applicative-Monad"></a>
  `Applicative m`
- <a id="1-Bind-Monad"></a>
  `Bind m`

**Methods**

```text
map : {α β : Type u} → (α → β) → m α → m β
```

 Inherited from 

1. `Applicative m`
2. `Bind m`

```text
mapConst : {α β : Type u} → α → m β → m α
```

 Inherited from 

1. `Applicative m`
2. `Bind m`

```text
pure : {α : Type u} → α → m α
```

 Inherited from 

1. `Applicative m`
2. `Bind m`

```text
seq : {α β : Type u} → m (α → β) → (Unit → m α) → m β
```

 Inherited from 

1. `Applicative m`
2. `Bind m`

```text
seqLeft : {α β : Type u} → m α → (Unit → m β) → m α
```

 Inherited from 

1. `Applicative m`
2. `Bind m`

```text
seqRight : {α β : Type u} → m α → (Unit → m β) → m β
```

 Inherited from 

1. `Applicative m`
2. `Bind m`

```text
bind : {α β : Type u} → m α → (α → m β) → m β
```

 Inherited from 

1. `Applicative m`
2. `Bind m`

1. [18.1. Laws](Laws/index.md#monad-laws)
2. [18.2. Lifting Monads](Lifting-Monads/index.md#lifting-monads)
3. [18.3. Syntax](Syntax/index.md#The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Syntax)
4. [18.4. API Reference](API-Reference/index.md#The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--API-Reference)
5. [18.5. Varieties of Monads](Varieties-of-Monads/index.md#monad-varieties)

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
α:Type uβ:Type un:Natxs:LenList (n + 1) α⊢ xs.list ≠ []
```


### Display 2


```text
α:Type uβ:Type un:Natxs:LenList (n + 1) αh:xs.list = []⊢ False
```


### Display 3


```text
mkα:Type uβ:Type un:Natlist✝:List αlengthOk✝:list✝.length = n + 1h:{ list := list✝, lengthOk := lengthOk✝ }.list = []⊢ False
```


### Display 4


```text
mkα:Type uβ:Type un:Natlist✝:List αlengthOk✝:list✝.length = n + 1h:list✝ = []⊢ False
```


### Display 5


```text
All goals completed! 🐙
```


### Display 6


```text
α:Type uβ:Type un:Natxs:LenList (n + 1) αhead✝:αxs':List αlengthOk✝:(head✝ :: xs').length = n + 1⊢ xs'.length = n
```


### Display 7


```text
α:Type uβ:Type un:Natf:α → βxs:LenList n α⊢ (List.map f xs.list).length = n
```


### Display 8


```text
mkα:Type uβ:Type un:Natf:α → βlist✝:List αlengthOk✝:list✝.length = n⊢ (List.map f { list := list✝, lengthOk := lengthOk✝ }.list).length = n
```


### Display 9


```text
α:Type uβ:Type uγ:Type ?u.15n:Natf:α → β → γxs:LenList n αys:LenList n β⊢ (List.zipWith f xs.list ys.list).length = n
```


### Display 10


```text
mkα:Type uβ:Type uγ:Type ?u.15n:Natf:α → β → γys:LenList n βlist✝:List αlengthOk✝:list✝.length = n⊢ (List.zipWith f { list := list✝, lengthOk := lengthOk✝ }.list ys.list).length = n
```


### Display 11


```text
mk.mkα:Type uβ:Type uγ:Type ?u.15n:Natf:α → β → γlist✝¹:List αlengthOk✝¹:list✝.length = nlist✝:List βlengthOk✝:list✝.length = n⊢ (List.zipWith f { list := list✝¹, lengthOk := lengthOk✝¹ }.list { list := list✝, lengthOk := lengthOk✝ }.list).length =
  n
```


### Display 12


```text
α:Type un:Natxs:LenList n α⊢ xs.list.length = n
```


### Display 13


```text
mkα:Type un:Natlist✝:List αlengthOk✝:list✝.length = n⊢ { list := list✝, lengthOk := lengthOk✝ }.list.length = n
```


### Display 14


```text
α:Type uβ:Type un:Natn':Natsquare:LenList (n' + 1) (LenList (n' + 1) α)⊢ (square.head.head :: (diagonal (map (fun x => x.tail) square.tail)).list).length = n' + 1
```

