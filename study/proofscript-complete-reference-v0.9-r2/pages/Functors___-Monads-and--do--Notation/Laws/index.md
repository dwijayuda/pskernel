<a id="monad-laws"></a>

# ProofScript — 18.1. Laws

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functor, applicative and monad interfaces are ordinary typeclasses and definitions. Their laws are separate propositions, not automatic consequences of defining methods. The order of StateT and ExceptT changes failure and state behavior. do is native sequencing, not a JavaScript statement language. Local mutation, loops and return use that grammar and its scope.

**Compiler and coverage boundary.** Native semicolons within do and local let expressions remain valid. Do not remove all semicolons, reinterpret every newline, or assume discarding a state value reverses external effects.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Functors___-Monads-and--do--Notation/Laws/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Functors___-Monads-and--do--Notation/Laws/index.html). Source Git blob: `333c667a2693f8897c539d9e12d33740f165ac26`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 18.1. Laws

Having `map`, `pure`, `seq`, and `bind` operators with the appropriate types is not really sufficient to have a functor, applicative functor, or monad. These operators must additionally satisfy certain axioms, which are often called the 
<a id="--tech-term-laws"></a>
*laws* of the type class.

For a functor, the `map` operation must preserve identity and function composition. In other words, given a purported `Functor` `f`, for all `x`​`:`​`f α`:

- `id <$> x = x`, and
- for all function `g` and `h`, `(h ∘ g) <$> x = h <$> g <$> x`.

Instances that violate these assumptions can be very surprising! Additionally, because `Functor` includes `mapConst` to enable instances to provide a more efficient implementation, a lawful functor's `mapConst` should be equivalent to its default implementation.

The Lean standard library does not require proofs of these properties in every instance of `Functor`. Nonetheless, if an instance violates them, then it should be considered a bug. When proofs of these properties are necessary, an instance implicit parameter of type `LawfulFunctor f` can be used. The `LawfulFunctor` class includes the necessary proofs.

<a id="LawfulFunctor___mk"></a>

**type class**

```text
LawfulFunctor.{u, v} (f : Type u → Type v) [Functor f] : Prop
```

A functor satisfies the functor laws.

The `Functor` class contains the operations of a functor, but does not require that instances prove they satisfy the laws of a functor. A `LawfulFunctor` instance includes proofs that the laws are satisfied. Because `Functor` instances may provide optimized implementations of `mapConst`, `LawfulFunctor` instances must also prove that the optimized implementation is equivalent to the standard implementation.

**Instance Constructor**

```text
LawfulFunctor.mk.{u, v}
```

**Methods**

```text
map_const : ∀ {α β : Type u}, Functor.mapConst = Functor.map ∘ Function.const β
```

The `mapConst` implementation is equivalent to the default implementation.

```text
id_map : ∀ {α : Type u} (x : f α), id <$> x = x
```

The `map` implementation preserves identity.

```text
comp_map : ∀ {α β γ : Type u} (g : α → β) (h : β → γ) (x : f α), (h ∘ g) <$> x = h <$> g <$> x
```

The `map` implementation preserves function composition.

In addition to proving that the potentially-optimized `SeqLeft.seqLeft` and `SeqRight.seqRight` operations are equivalent to their default implementations, Applicative functors `f` must satisfy four laws.

<a id="LawfulApplicative___mk"></a>

**type class**

```text
LawfulApplicative.{u, v} (f : Type u → Type v) [Applicative f] : Prop
```

An applicative functor satisfies the laws of an applicative functor.

The `Applicative` class contains the operations of an applicative functor, but does not require that instances prove they satisfy the laws of an applicative functor. A `LawfulApplicative` instance includes proofs that the laws are satisfied.

Because `Applicative` instances may provide optimized implementations of `seqLeft` and `seqRight`, `LawfulApplicative` instances must also prove that the optimized implementation is equivalent to the standard implementation.

**Instance Constructor**

```text
LawfulApplicative.mk.{u, v}
```

**Extends**

- <a id="0-LawfulFunctor-LawfulApplicative"></a>
  `LawfulFunctor f`

**Methods**

```text
map_const : ∀ {α β : Type u}, Functor.mapConst = Functor.map ∘ Function.const β
```

 Inherited from 

1. `LawfulFunctor f`

```text
id_map : ∀ {α : Type u} (x : f α), id <$> x = x
```

 Inherited from 

1. `LawfulFunctor f`

```text
comp_map : ∀ {α β γ : Type u} (g : α → β) (h : β → γ) (x : f α), (h ∘ g) <$> x = h <$> g <$> x
```

 Inherited from 

1. `LawfulFunctor f`

```text
seqLeft_eq : ∀ {α β : Type u} (x : f α) (y : f β), x <* y = Function.const β <$> x <*> y
```

`seqLeft` is equivalent to the default implementation.

```text
seqRight_eq : ∀ {α β : Type u} (x : f α) (y : f β), x *> y = Function.const α id <$> x <*> y
```

`seqRight` is equivalent to the default implementation.

```text
pure_seq : ∀ {α β : Type u} (g : α → β) (x : f α), pure g <*> x = g <$> x
```

`pure` before `seq` is equivalent to `Functor.map`.

This means that `pure` really is pure when occurring immediately prior to `seq`.

```text
map_pure : ∀ {α β : Type u} (g : α → β) (x : α), g <$> pure x = pure (g x)
```

Mapping a function over the result of `pure` is equivalent to applying the function under `pure`.

This means that `pure` really is pure with respect to `Functor.map`.

```text
seq_pure : ∀ {α β : Type u} (g : f (α → β)) (x : α), g <*> pure x = (fun h => h x) <$> g
```

`pure` after `seq` is equivalent to `Functor.map`.

This means that `pure` really is pure when occurring just after `seq`.

```text
seq_assoc : ∀ {α β γ : Type u} (x : f α) (g : f (α → β)) (h : f (β → γ)), h <*> (g <*> x) = Function.comp <$> h <*> g <*> x
```

`seq` is associative.

Changing the nesting of `seq` calls while maintaining the order of computations results in an equivalent computation. This means that `seq` is not doing any more than sequencing.

The 
<a id="--tech-term-monad-laws"></a>
monad laws specify that `pure` followed by `bind` should be equivalent to function application (that is, `pure` has no effects), that `bind` followed by `pure` around a function application is equivalent to `map`, and that `bind` is associative.

<a id="LawfulMonad___mk"></a>

**type class**

```text
LawfulMonad.{u, v} (m : Type u → Type v) [Monad m] : Prop
```

Lawful monads are those that satisfy a certain behavioral specification. While all instances of `Monad` should satisfy these laws, not all implementations are required to prove this.

`LawfulMonad.mk'` is an alternative constructor that contains useful defaults for many fields.

**Instance Constructor**

```text
LawfulMonad.mk.{u, v}
```

**Extends**

- <a id="0-LawfulApplicative-LawfulMonad"></a>
  `LawfulApplicative m`

**Methods**

```text
map_const : ∀ {α β : Type u}, Functor.mapConst = Functor.map ∘ Function.const β
```

 Inherited from 

1. `LawfulApplicative m`

```text
id_map : ∀ {α : Type u} (x : m α), id <$> x = x
```

 Inherited from 

1. `LawfulApplicative m`

```text
comp_map : ∀ {α β γ : Type u} (g : α → β) (h : β → γ) (x : m α), (h ∘ g) <$> x = h <$> g <$> x
```

 Inherited from 

1. `LawfulApplicative m`

```text
seqLeft_eq : ∀ {α β : Type u} (x : m α) (y : m β), x <* y = Function.const β <$> x <*> y
```

 Inherited from 

1. `LawfulApplicative m`

```text
seqRight_eq : ∀ {α β : Type u} (x : m α) (y : m β), x *> y = Function.const α id <$> x <*> y
```

 Inherited from 

1. `LawfulApplicative m`

```text
pure_seq : ∀ {α β : Type u} (g : α → β) (x : m α), pure g <*> x = g <$> x
```

 Inherited from 

1. `LawfulApplicative m`

```text
map_pure : ∀ {α β : Type u} (g : α → β) (x : α), g <$> pure x = pure (g x)
```

 Inherited from 

1. `LawfulApplicative m`

```text
seq_pure : ∀ {α β : Type u} (g : m (α → β)) (x : α), g <*> pure x = (fun h => h x) <$> g
```

 Inherited from 

1. `LawfulApplicative m`

```text
seq_assoc : ∀ {α β γ : Type u} (x : m α) (g : m (α → β)) (h : m (β → γ)), h <*> (g <*> x) = Function.comp <$> h <*> g <*> x
```

 Inherited from 

1. `LawfulApplicative m`

```text
bind_pure_comp : ∀ {α β : Type u} (f : α → β) (x : m α),
  (do
      let a ← x
      pure (f a)) =
    f <$> x
```

A `bind` followed by `pure` composed with a function is equivalent to a functorial map.

This means that `pure` really is pure after a `bind` and has no effects.

```text
bind_map : ∀ {α β : Type u} (f : m (α → β)) (x : m α),
  (do
      let x_1 ← f
      x_1 <$> x) =
    f <*> x
```

A `bind` followed by a functorial map is equivalent to `Applicative` sequencing.

This means that the effect sequencing from `Monad` and `Applicative` are the same.

```text
pure_bind : ∀ {α β : Type u} (x : α) (f : α → m β), pure x >>= f = f x
```

`pure` followed by `bind` is equivalent to function application.

This means that `pure` really is pure before a `bind` and has no effects.

```text
bind_assoc : ∀ {α β γ : Type u} (x : m α) (f : α → m β) (g : β → m γ), x >>= f >>= g = x >>= fun x => f x >>= g
```

`bind` is associative.

Changing the nesting of `bind` calls while maintaining the order of computations results in an equivalent computation. This means that `bind` is not doing more than data-dependent sequencing.

<a id="LawfulMonad___mk___"></a>

**theorem**

```text
LawfulMonad.mk'.{u, v} (m : Type u → Type v) [Monad m]
  (id_map : ∀ {α : Type u} (x : m α), id <$> x = x)
  (pure_bind :
    ∀ {α β : Type u} (x : α) (f : α → m β), pure x >>= f = f x)
  (bind_assoc :
    ∀ {α β γ : Type u} (x : m α) (f : α → m β) (g : β → m γ),
      x >>= f >>= g = x >>= fun x => f x >>= g)
  (map_const :
    ∀ {α β : Type u} (x : α) (y : m β),
      Functor.mapConst x y = Function.const β x <$> y := by
    intros; rfl)
  (seqLeft_eq :
    ∀ {α β : Type u} (x : m α) (y : m β),
      x <* y = do
        let a ← x
        let _ ← y
        pure a := by
    intros; rfl)
  (seqRight_eq :
    ∀ {α β : Type u} (x : m α) (y : m β),
      x *> y = do
        let _ ← x
        y := by
    intros; rfl)
  (bind_pure_comp :
    ∀ {α β : Type u} (f : α → β) (x : m α),
      (do
          let y ← x
          pure (f y)) =
        f <$> x := by
    intros; rfl)
  (bind_map :
    ∀ {α β : Type u} (f : m (α → β)) (x : m α),
      (do
          let x_1 ← f
          x_1 <$> x) =
        f <*> x := by
    intros; rfl) :
  LawfulMonad m
```

An alternative constructor for `LawfulMonad` which has more defaultable fields in the common case.
