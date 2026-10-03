<a id="The-Lean-Language-Reference--Iterators--Reasoning-About-Iterators"></a>

# ProofScript — 22.5. Reasoning About Iterators

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Iterator definitions describe state and stepping; consumers observe a sequence through the permitted interfaces. Combinators such as mapping and filtering transform that process without automatically inheriting termination, productivity, effect or allocation guarantees. Preserve the distinction between finite consumers and potentially unbounded iteration. Iterator proofs belong to the native abstraction and its law dependencies.

**Compiler and coverage boundary.** Version the iterator library and its instances. A foreign async stream additionally needs backpressure, cancellation and lifetime contracts; it is not an ordinary iterator by spelling alone.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Iterators/Reasoning-About-Iterators/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Iterators/Reasoning-About-Iterators/index.html). Source Git blob: `df3011337c3777854e345671b572ea3046b2fdf6`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 22.5. Reasoning About Iterators

<a id="The-Lean-Language-Reference--Iterators--Reasoning-About-Iterators--Reasoning-About-Consumers"></a>
### 22.5.1. Reasoning About Consumers

The iterator library provides a large number of useful lemmas. Most theorems about finite iterators can be proven by rewriting the statement to one about lists, using the fact that the correspondence between iterator combinators and corresponding list operations has already been proved. In practice, many of these theorems are already registered as `simp` lemmas.

The lemmas have a very predictable naming system, and many are in the [default simp set](../../The-Simplifier/Simp-sets/index.md#--tech-term-default-simp-set). Some of the most important include:

- Consumer lemmas such as `Iter.all_toList`, `Iter.any_toList`, and `Iter.foldl_toList` that introduce lists as a model.
- Simplification lemmas such as `Iter.toList_map` that `Iter.toList_filter` push the list model “inwards” in the goal.
- Producer lemmas such as `List.toList_iter` and `Array.toList_iter` that replace a producer with a list model, removing iterators from the goal entirely.

The latter two categories are typically automatic with `simp`.

<a id="Reasoning-via-Lists"></a>
Reasoning via Lists 

Every element returned by an iterator that multiplies the numbers consumed some other iterator by two is even. To prove this statement, `Iter.all_toList`, `Iter.toList_map`, and `Array.toList_iter` are used to replace the statement about iterators with one about lists, after which `simp` discharges the goal:

```proofscript
example (l : Array Nat) :
    (l.iter.map (· * 2)).all (· % 2 = 0) := by
  rw [← Iter.all_toList]
  rw [Iter.toList_map]
  rw [Array.toList_iter]
  simp
```

In fact, because most of the needed lemmas are in the [default simp set](../../The-Simplifier/Simp-sets/index.md#--tech-term-default-simp-set), the proof can be quite short:

```proofscript
example (l : Array Nat) :
    (l.iter.map (· * 2)).all (· % 2 = 0) := by
  simp [← Iter.all_toList]
```

<a id="The-Lean-Language-Reference--Iterators--Reasoning-About-Iterators--Stepwise-Reasoning"></a>
### 22.5.2. Stepwise Reasoning

When there are not enough lemmas to prove a property by rewriting to a list model, it can be necessary to prove things about iterators by reasoning directly about their step functions. The induction principles in this section are useful for stepwise reasoning.

<a id="Std___Iter___inductSkips"></a>

**def**

```text
Std.Iter.inductSkips.{x, u_1} {α β : Type u_1} [Iterator α Id β]
  [Productive α Id] (motive : Iter β → Sort x)
  (step :
    (it : Iter β) →
      ({it' : Iter β} →
          it.IsPlausibleStep (IterStep.skip it') → motive it') →
        motive it)
  (it : Iter β) : motive it
```

Induction principle for productive iterators: One can define a function `f` that maps every iterator `it` to an element of `motive it` by defining `f it` in terms of the values of `f` on the plausible skip successors of `it'.

<a id="Std___IterM___inductSkips"></a>

**def**

```text
Std.IterM.inductSkips.{x, u_1, u_2} {α : Type u_1}
  {m : Type u_1 → Type u_2} {β : Type u_1} [Iterator α m β]
  [Productive α m] (motive : IterM m β → Sort x)
  (step :
    (it : IterM m β) →
      ({it' : IterM m β} →
          it.IsPlausibleStep (IterStep.skip it') → motive it') →
        motive it)
  (it : IterM m β) : motive it
```

Induction principle for productive monadic iterators: One can define a function `f` that maps every iterator `it` to an element of `motive it` by defining `f it` in terms of the values of `f` on the plausible skip successors of `it'.

<a id="Std___Iter___inductSteps"></a>

**def**

```text
Std.Iter.inductSteps.{x, u_1} {α β : Type u_1} [Iterator α Id β]
  [Finite α Id] (motive : Iter β → Sort x)
  (step :
    (it : Iter β) →
      ({it' : Iter β} →
          {out : β} →
            it.IsPlausibleStep (IterStep.yield it' out) → motive it') →
        ({it' : Iter β} →
            it.IsPlausibleStep (IterStep.skip it') → motive it') →
          motive it)
  (it : Iter β) : motive it
```

Induction principle for finite iterators: One can define a function `f` that maps every iterator `it` to an element of `motive it` by defining `f it` in terms of the values of `f` on the plausible successors of `it'.

<a id="Std___IterM___inductSteps"></a>

**def**

```text
Std.IterM.inductSteps.{x, u_1, u_2} {α : Type u_1}
  {m : Type u_1 → Type u_2} {β : Type u_1} [Iterator α m β] [Finite α m]
  (motive : IterM m β → Sort x)
  (step :
    (it : IterM m β) →
      ({it' : IterM m β} →
          {out : β} →
            it.IsPlausibleStep (IterStep.yield it' out) → motive it') →
        ({it' : IterM m β} →
            it.IsPlausibleStep (IterStep.skip it') → motive it') →
          motive it)
  (it : IterM m β) : motive it
```

Induction principle for finite monadic iterators: One can define a function `f` that maps every iterator `it` to an element of `motive it` by defining `f it` in terms of the values of `f` on the plausible successors of `it'.

The standard library also includes lemmas for the stepwise behavior of all the producers and combinators. Examples include `List.step_iter_nil`, `List.step_iter_cons`, `IterM.step_map`.

<a id="The-Lean-Language-Reference--Iterators--Reasoning-About-Iterators--Monads-for-Reasoning"></a>
### 22.5.3. Monads for Reasoning

<a id="Std___Iterators___PostconditionT___mk"></a>

**structure**

```text
Std.Iterators.PostconditionT.{w, w'} (m : Type w → Type w')
  (α : Type w) : Type (max w w')
```

`PostconditionT m α` represents an operation in the monad `m` together with a intrinsic proof that some postcondition holds for the `α` valued monadic result. It consists of a predicate `P` about `α` and an element of `m ({ a // P a })` and is a helpful tool for intrinsic verification, notably termination proofs, in the context of iterators.

`PostconditionT m` is a monad if `m` is. However, note that `PostconditionT m α` is a structure, so that the compiler will generate inefficient code from recursive functions returning `PostconditionT m α`. Optimizations for `ReaderT`, `StateT` etc. aren't applicable for structures.

Moreover, `PostconditionT m α` is not a well-behaved monad transformer because `PostconditionT.lift` neither commutes with `pure` nor with `bind`.

**Constructor**

```text
Std.Iterators.PostconditionT.mk.{w, w'}
```

**Fields**

```text
Property : α → Prop
```

A predicate that holds for the return value(s) of the `m`-monadic operation.

```text
operation : m (Subtype self.Property)
```

The actual monadic operation. Its return value is bundled together with a proof that it satisfies `Property`.

<a id="Std___Iterators___PostconditionT___run"></a>

**def**

```text
Std.Iterators.PostconditionT.run.{w, w'} {m : Type w → Type w'}
  [Monad m] {α : Type w} (x : PostconditionT m α) : m α
```

Converts an operation from `PostConditionT m` to `m`, discarding the postcondition.

<a id="Std___Iterators___PostconditionT___lift"></a>

**def**

```text
Std.Iterators.PostconditionT.lift.{w, w'} {α : Type w}
  {m : Type w → Type w'} [Functor m] (x : m α) : PostconditionT m α
```

Lifts an operation from `m` to `PostconditionT m` without asserting any nontrivial postcondition.

Caution: `lift` is not a lawful lift function. For example, `pure a : PostconditionT m α` is not the same as `PostconditionT.lift (pure a : m α)`.

<a id="Std___Iterators___PostconditionT___liftWithProperty"></a>

**def**

```text
Std.Iterators.PostconditionT.liftWithProperty.{w, w'} {α : Type w}
  {m : Type w → Type w'} {P : α → Prop} (x : m { α // P α }) :
  PostconditionT m α
```

Lifts a monadic value from `m { a : α // P a }` to a value `PostconditionT m α`.

<a id="Std___Iter___IsPlausibleIndirectOutput___direct"></a>

**inductive predicate**

```text
Std.Iter.IsPlausibleIndirectOutput.{w} {α β : Type w}
  [Iterator α Id β] : Iter β → β → Prop
```

Asserts that a certain iterator `it` could plausibly yield the value `out` after an arbitrary number of steps.

**Constructors**

```text
Std.Iter.IsPlausibleIndirectOutput.direct.{w} {α β : Type w}
  [Iterator α Id β] {it : Iter β} {out : β} :
  it.IsPlausibleOutput out →
    it.IsPlausibleIndirectOutput out
```

The output value could plausibly be emitted in the next step.

```text
Std.Iter.IsPlausibleIndirectOutput.indirect.{w}
  {α β : Type w} [Iterator α Id β] {it it' : Iter β}
  {out : β} :
  it'.IsPlausibleSuccessorOf it →
    it'.IsPlausibleIndirectOutput out →
      it.IsPlausibleIndirectOutput out
```

The output value could plausibly be emitted in a step after the next step.

<a id="Std___Iterators___HetT___mk"></a>

**structure**

```text
Std.Iterators.HetT.{w, w', v} (m : Type w → Type w') (α : Type v) :
  Type (max v w')
```

If `m` is a monad, then `HetT m` is a monad that has two features:

- It generalizes `m` to arbitrary universes.
- It tracks a postcondition property that holds for the monadic return value, similarly to `PostconditionT`.

This monad is noncomputable and is merely a vehicle for more convenient proofs, especially proofs about the equivalence of iterators, because it avoids universe issues and spares users the work to handle the postconditions manually.

Caution: Just like `PostconditionT`, this is not a lawful monad transformer. To lift from `m` to `HetT m`, use `HetT.lift`.

Because this monad is fundamentally universe-polymorphic, it is recommended for consistency to always use the methods `HetT.pure`, `HetT.map` and `HetT.bind` instead of the homogeneous versions `Pure.pure`, `Functor.map` and `Bind.bind`.

**Constructor**

```text
Std.Iterators.HetT.mk.{w, w', v}
```

**Fields**

```text
Property : α → Prop
```

A predicate that holds for the return value(s) of the `m`-monadic operation.

```text
small : Std.Internal.Small (Subtype self.Property)
```

A proof that the possible return values are equivalent to a `w`-small type.

```text
operation : m (Std.Internal.USquash (Subtype self.Property))
```

The actual monadic operation. Its return value is bundled together with a proof that it satisfies `Property` and squashed so that it fits into the monad `m`.

<a id="Std___IterM___stepAsHetT"></a>

**def**

```text
Std.IterM.stepAsHetT.{u_1, u_2} {α : Type u_1} {m : Type u_1 → Type u_2}
  {β : Type u_1} [Iterator α m β] [Monad m] (it : IterM m β) :
  HetT m (IterStep (IterM m β) β)
```

A noncomputable variant of `IterM.step` using the `HetT` monad. It is used in the definition of the equivalence relations on iterators, namely `IterM.Equiv` and `Iter.Equiv`.

<a id="Std___Iterators___HetT___lift"></a>

**def**

```text
Std.Iterators.HetT.lift.{w, w'} {α : Type w} {m : Type w → Type w'}
  [Monad m] (x : m α) : HetT m α
```

Lifts `x : m α` into `HetT m α` with the trivial postcondition.

Caution: This is not a lawful monad lifting function

<a id="Std___Iterators___HetT___prun"></a>

**def**

```text
Std.Iterators.HetT.prun.{u_1, u_2, u_3} {m : Type u_1 → Type u_2}
  {α : Type u_3} {β : Type u_1} [Monad m] (x : HetT m α)
  (f : (a : α) → x.Property a → m β) : m β
```

Applies the given function to the result of the contained `m`-monadic operation with a proof that the postcondition property holds, returning another operation in `m`.

<a id="Std___Iterators___HetT___pure"></a>

**def**

```text
Std.Iterators.HetT.pure.{w, w', v} {m : Type w → Type w'} [Pure m]
  {α : Type v} (a : α) : HetT m α
```

A universe-heterogeneous version of `Pure.pure`. Given `a : α`, it returns an element of `HetT m α` with the postcondition `(a = ·)`.

<a id="Std___Iterators___HetT___map"></a>

**def**

```text
Std.Iterators.HetT.map.{w, w', u, v} {m : Type w → Type w'} [Functor m]
  {α : Type u} {β : Type v} (f : α → β) (x : HetT m α) : HetT m β
```

A universe-heterogeneous version of `Functor.map`.

<a id="Std___Iterators___HetT___pmap"></a>

**def**

```text
Std.Iterators.HetT.pmap.{w, w', u, v} {m : Type w → Type w'} [Functor m]
  {α : Type u} {β : Type v} (x : HetT m α)
  (f : (a : α) → x.Property a → β) : HetT m β
```

A generalization of `HetT.map` that provides the postcondition property to the mapping function.

<a id="Std___Iterators___HetT___bind"></a>

**def**

```text
Std.Iterators.HetT.bind.{w, w', u, v} {m : Type w → Type w'} [Monad m]
  {α : Type u} {β : Type v} (x : HetT m α) (f : α → HetT m β) : HetT m β
```

A universe-heterogeneous version of `Bind.bind`.

<a id="Std___Iterators___HetT___pbind"></a>

**def**

```text
Std.Iterators.HetT.pbind.{w, w', u, v} {m : Type w → Type w'} [Monad m]
  {α : Type u} {β : Type v} (x : HetT m α)
  (f : (a : α) → x.Property a → HetT m β) : HetT m β
```

A generalization of `HetT.bind` that provides the postcondition property to the mapping function.

<a id="The-Lean-Language-Reference--Iterators--Reasoning-About-Iterators--Equivalence"></a>
### 22.5.4. Equivalence

Iterator equivalence is defined in terms of the observable behavior of iterators, rather than their implementations. In particular, the internal state is ignored.

<a id="Std___Iter___Equiv"></a>

**def**

```text
Std.Iter.Equiv.{u_1} {α₁ α₂ β : Type u_1} [Iterator α₁ Id β]
  [Iterator α₂ Id β] (ita : Iter β) (itb : Iter β) : Prop
```

Equivalence relation on iterators. Equivalent iterators behave the same as long as the internal state of them is not directly inspected.

Two iterators (possibly of different types) are equivalent if they have the same `Iterator.IsPlausibleStep` relation and their step functions are the same *up to equivalence of the successor iterators*. This coinductive definition captures the idea that the only relevant feature of an iterator is its step function. Other information retrievable from the iterator -- for example, whether it is a list iterator or an array iterator -- is totally irrelevant for the equivalence judgement.

<a id="Std___IterM___Equiv"></a>

**def**

```text
Std.IterM.Equiv.{w, w'} {m : Type w → Type w'} [Monad m] [LawfulMonad m]
  {β α₁ α₂ : Type w} [Iterator α₁ m β] [Iterator α₂ m β]
  (ita : IterM m β) (itb : IterM m β) : Prop
```

Equivalence relation on monadic iterators. Equivalent iterators behave the same as long as the internal state of them is not directly inspected.

Two iterators (possibly of different types) are equivalent if they have the same `Iterator.IsPlausibleStep` relation and their step functions are the same *up to equivalence of the successor iterators*. This coinductive definition captures the idea that the only relevant feature of an iterator is its step function. Other information retrievable from the iterator -- for example, whether it is a list iterator or an array iterator -- is totally irrelevant for the equivalence judgement.

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
l:Array Nat⊢ Iter.all (fun x => decide (x % 2 = 0)) (Iter.map (fun x => x * 2) l.iter) = true
```


### Display 2


```text
l:Array Nat⊢ ((Iter.map (fun x => x * 2) l.iter).toList.all fun x => decide (x % 2 = 0)) = true
```


### Display 3


```text
l:Array Nat⊢ ((List.map (fun x => x * 2) l.iter.toList).all fun x => decide (x % 2 = 0)) = true
```


### Display 4


```text
l:Array Nat⊢ ((List.map (fun x => x * 2) l.toList).all fun x => decide (x % 2 = 0)) = true
```


### Display 5


```text
All goals completed! 🐙
```

