<a id="The-Lean-Language-Reference--Iterators--Iterator-Combinators"></a>

# ProofScript — 22.4. Iterator Combinators

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Iterator definitions describe state and stepping; consumers observe a sequence through the permitted interfaces. Combinators such as mapping and filtering transform that process without automatically inheriting termination, productivity, effect or allocation guarantees. Preserve the distinction between finite consumers and potentially unbounded iteration. Iterator proofs belong to the native abstraction and its law dependencies.

**Compiler and coverage boundary.** Version the iterator library and its instances. A foreign async stream additionally needs backpressure, cancellation and lifetime contracts; it is not an ordinary iterator by spelling alone.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Iterators/Iterator-Combinators/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Iterators/Iterator-Combinators/index.html). Source Git blob: `16170664a2f12e7702d3a952b661219cc2e1a4f1`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 22.4. Iterator Combinators

The documentation for iterator combinators often includes 
<a id="--tech-term-marble-diagrams"></a>
*marble diagrams* that show the relationship between the elements returned by the underlying iterators and the elements returned by the combinator's iterator. Marble diagrams provide examples, not full specifications. These diagrams consist of a number of rows. Each row shows an example of an iterator's output, where `-` indicates a `skip`, a term indicates a value returned with `yield`, and `⊥` indicates the end of iteration. Spaces indicate that iteration did not occur. Unbound identifiers in the marble diagram stand for arbitrary values of the iterator's element type.

Vertical alignment in the marble diagram indicates a causal relationship: when two elements are aligned, it means that consuming the iterator in the lower row results in the upper rows being consumed. In particular, consuming up to the nth column of the lower iterator results in the consumption of the first n columns from the upper iterator.

A marble diagram for an identity iterator combinator that returns each element from the underlying iterator looks like this:

```text
it    ---a-----b---c----d⊥
it.id ---a-----b---c----d⊥
```

A marble diagram for an iterator combinator that duplicates each element of the underlying iterator looks like this:

```text
it           ---a  ---b  ---c  ---d⊥
it.double    ---a-a---b-b---c-c---d-d⊥
```

The marble diagram for `Iter.filter` shows how some elements of the underlying iterator do not occur in the filtered iterator, but also that stepping the filtered iterator results in a `skip` when the underlying iterator returns a value that doesn't satisfy the predicate:

```text
it            ---a--b--c--d-e--⊥
it.filter     ---a-----c-------⊥
```

The diagram requires an explanatory note:

> (given that `f a = f c = true` and `f b = f d = d e = false`)

The diagram for `Iter.zip` shows how consuming the combined iterator consumes the underlying iterators:

```text
left               --a        ---b        --c
right                 --x         --y        --⊥
left.zip right     -----(a, x)------(b, y)-----⊥
```

The zipped iterator emits `skip`s so long as `left` does. When `left` emits `a`, the zipped iterator emits one more `skip`. After this, the zipped iterator switches to consuming `right`, and it emits `skip`s so long as `right` does. When `right` emits `x`, the zipped iterator emits the pair `(a, x)`. This interleaving of `left` and `right` continues until one of them stops, at which point the zipped iterator stops. Blank spaces in the upper rows of the marble diagram indicate that the iterator is not being consumed at that step.

<a id="The-Lean-Language-Reference--Iterators--Iterator-Combinators--Pure-Combinators"></a>
### 22.4.1. Pure Combinators

<a id="Std___IterM___mk-next"></a>

**constructor of Std.IterM**

```text
Std.IterM.mk.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w}
  (internalState : α) : IterM m β
```

Wraps the state of an iterator into an `Iter` object.

<a id="Std___Iter___toIterM"></a>

**def**

```text
Std.Iter.toIterM.{w} {α β : Type w} (it : Iter β) : IterM Id β
```

Converts a pure iterator (`Iter β`) into a monadic iterator (`IterM Id β`) in the identity monad `Id`.

<a id="Std___Iter___take"></a>

**def**

```text
Std.Iter.take.{w} {α β : Type w} [Iterator α Id β] (n : Nat)
  (it : Iter β) : Iter β
```

Given an iterator `it` and a natural number `n`, `it.take n` is an iterator that outputs up to the first `n` of `it`'s values in order and then terminates.

**Marble diagram:**

```proofscript
it          ---a----b---c--d-e--⊥
it.take 3   ---a----b---c⊥

it          ---a--⊥
it.take 3   ---a--⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is productive
- `Productive` instance: only if `it` is productive

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it`.

<a id="Std___Iter___takeWhile"></a>

**def**

```text
Std.Iter.takeWhile.{w} {α β : Type w} (P : β → Bool) (it : Iter β) :
  Iter β
```

Given an iterator `it` and a predicate `P`, `it.takeWhile P` is an iterator that outputs the values emitted by `it` until one of those values is rejected by `P`. If some emitted value is rejected by `P`, the value is dropped and the iterator terminates.

**Marble diagram:**

Assuming that the predicate `P` accepts `a` and `b` but rejects `c`:

```proofscript
it               ---a----b---c--d-e--⊥
it.takeWhile P   ---a----b---⊥

it               ---a----⊥
it.takeWhile P   ---a----⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

Depending on `P`, it is possible that `it.takeWhile P` is finite (or productive) although `it` is not. In this case, the `Finite` (or `Productive`) instance needs to be proved manually.

**Performance:**

This combinator calls `P` on each output of `it` until the predicate evaluates to false. Then it terminates.

<a id="Std___Iter___toTake"></a>

**def**

```text
Std.Iter.toTake.{w} {α β : Type w} [Iterator α Id β] [Finite α Id]
  (it : Iter β) : Iter β
```

This combinator is only useful for advanced use cases.

Given a finite iterator `it`, returns an iterator that behaves exactly like `it` but is of the same type as `it.take n`.

**Marble diagram:**

```proofscript
it          ---a----b---c--d-e--⊥
it.toTake   ---a----b---c--d-e--⊥
```

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it`.

<a id="Std___Iter___drop"></a>

**def**

```text
Std.Iter.drop.{w} {α β : Type w} (n : Nat) (it : Iter β) : Iter β
```

Given an iterator `it` and a natural number `n`, `it.drop n` is an iterator that forwards all of `it`'s output values except for the first `n`.

**Marble diagram:**

```proofscript
it          ---a----b---c--d-e--⊥
it.drop 3   ---------------d-e--⊥

it          ---a--⊥
it.drop 3   ------⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

**Performance:**

Currently, this combinator incurs an additional O(1) cost with each output of `it`, even when the iterator does not drop any elements anymore.

<a id="Std___Iter___dropWhile"></a>

**def**

```text
Std.Iter.dropWhile.{w} {α β : Type w} (P : β → Bool) (it : Iter β) :
  Iter β
```

Given an iterator `it` and a predicate `P`, `it.dropWhile P` is an iterator that emits the values emitted by `it` starting from the first value that is rejected by `P`. The elements before are dropped.

In situations where `P` is monadic, use `dropWhileM` instead.

**Marble diagram:**

Assuming that the predicate `P` accepts `a` and `b` but rejects `c`:

```proofscript
it               ---a----b---c--d-e--⊥
it.dropWhile P   ------------c--d-e--⊥

it               ---a----⊥
it.dropWhile P   --------⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite

Depending on `P`, it is possible that `it.dropWhileM P` is productive although `it` is not. In this case, the `Productive` instance needs to be proved manually.

**Performance:**

This combinator calls `P` on each output of `it` until the predicate evaluates to false. After that, the combinator incurs an additional O(1) cost for each value emitted by `it`.

<a id="Std___Iter___stepSize"></a>

**def**

```text
Std.Iter.stepSize.{u_1} {α β : Type u_1} [Iterator α Id β]
  [IteratorAccess α Id] (it : Iter β) (n : Nat) : Iter β
```

Produces an iterator that emits one value of `it`, then drops `n - 1` elements, then emits another value, and so on. In other words, it emits every `n`-th value of `it`, starting with the first one.

If `n = 0`, the iterator behaves like for `n = 1`: It emits all values of `it`.

**Marble diagram:**

```proofscript
it               ---1----2----3---4----5
it.stepSize 2    ---1---------3--------5
```

**Availability:**

This operation is currently only available for iterators implementing `IteratorAccess`, such as `PRange.iter` range iterators.

**Termination properties:**

- `Finite` instance: only if the base iterator `it` is finite
- `Productive` instance: always

<a id="Std___Iter___map"></a>

**def**

```text
Std.Iter.map.{w} {α β γ : Type w} [Iterator α Id β] (f : β → γ)
  (it : Iter β) : Iter γ
```

If `it` is an iterator, then `it.map f` is another iterator that applies a function `f` to all values emitted by `it` and emits the result.

In situations where `f` is monadic, use `mapM` instead.

**Marble diagram:**

```proofscript
it         ---a --b --c --d -e ----⊥
it.map     ---a'--b'--c'--d'-e'----⊥
```

(given that `f a = a'`, `f b = b'` etc.)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f`.

<a id="Std___Iter___mapM"></a>

**def**

```text
Std.Iter.mapM.{w, w'} {α β γ : Type w} [Iterator α Id β]
  {m : Type w → Type w'} [Monad m] [MonadAttach m] (f : β → m γ)
  (it : Iter β) : IterM m γ
```

If `it` is an iterator, then `it.mapM f` is another iterator that applies a monadic function `f` to all values emitted by `it` and emits the result.

The base iterator `it` being monadic in `m`, `f` can return values in any monad `n` for which a `MonadLiftT m n` instance is available.

If `f` is pure, then the simpler variant `it.map` can be used instead.

**Marble diagram (without monadic effects):**

```proofscript
it          ---a --b --c --d -e ----⊥
it.mapM     ---a'--b'--c'--d'-e'----⊥
```

(given that `f a = pure a'`, `f b = pure b'` etc.)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` is an `ExceptT` monad and will always fail, then `it.mapM` will be finite even if `it` isn't. In such cases, the termination proof needs to be done manually.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f`.

<a id="Std___Iter___mapWithPostcondition"></a>

**def**

```text
Std.Iter.mapWithPostcondition.{w, w'} {α β γ : Type w} [Iterator α Id β]
  {m : Type w → Type w'} [Monad m] (f : β → PostconditionT m γ)
  (it : Iter β) : IterM m γ
```

*Note: This is a very general combinator that requires an advanced understanding of monads, dependent types and termination proofs. The variants `map` and `mapM` are easier to use and sufficient for most use cases.*

If `it` is an iterator, then `it.mapWithPostcondition f` is another iterator that applies a monadic function `f` to all values emitted by `it` and emits the result.

`f` is expected to return `PostconditionT n _`, where `n` is an arbitrary monad. The `PostconditionT` transformer allows the caller to intrinsically prove properties about `f`'s return value in the monad `n`, enabling termination proofs depending on the specific behavior of `f`.

**Marble diagram (without monadic effects):**

```proofscript
it                          ---a --b --c --d -e ----⊥
it.mapWithPostcondition     ---a'--b'--c'--d'-e'----⊥
```

(given that `f a = pure a'`, `f b = pure b'` etc.)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` is an `ExceptT` monad and will always fail, then `it.mapWithPostcondition` will be finite even if `it` isn't.

In such situations, the missing instances can be proved manually if the postcondition bundled in the `PostconditionT n` monad is strong enough. In the given example, a suitable postcondition might be `fun _ => False`.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f`.

<a id="Std___Iter___uLift"></a>

**def**

```text
Std.Iter.uLift.{v, u} {α β : Type u} (it : Iter β) : Iter (ULift β)
```

Transforms an iterator with values in `β` into one with values in `ULift β`.

Most other combinators like `map` cannot switch between universe levels. This combinators makes it possible to transition to a higher universe.

**Marble diagram:**

```proofscript
it            ---a    ----b    ---c    --d    ---⊥
it.uLift n    ---.up a----.up b---.up c--.up d---⊥
```

**Termination properties:**

- `Finite`: only if the original iterator is finite
- `Productive`: only if the original iterator is productive

<a id="Std___Iter___flatMap"></a>

**def**

```text
Std.Iter.flatMap.{w} {α β α₂ γ : Type w} [Iterator α Id β]
  [Iterator α₂ Id γ] (f : β → Iter γ) (it : Iter β) : Iter γ
```

Let `it` be an iterator and `f` a function mapping `it`'s outputs to iterators. Then `it.flatMap f` is an iterator that goes over `it` and for each output, it applies `f` and iterates over the resulting iterator. `it.flatMap f` emits all values obtained from the inner iterators -- first, all of the first inner iterator, then all of the second one, and so on.

**Marble diagram:**

```text
it                 ---a      --b      c    --d -⊥
f a                    a1-a2⊥
f b                             b1-b2⊥
f c                                    c1-c2⊥
f d                                           ⊥
it.flatMap         ----a1-a2----b1-b2--c1-c2----⊥
```

**Termination properties:**

- `Finite` instance: only if `it` and the inner iterators are finite
- `Productive` instance: only if `it` is finite and the inner iterators are productive

For certain functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided out of the box. For example, if the outer iterator is productive and the inner iterators are productive *and provably never empty*, then the resulting iterator is also productive.

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it` or an internal iterator.

For each value emitted by the outer iterator `it`, this combinator calls `f`.

<a id="Std___Iter___flatMapM"></a>

**def**

```text
Std.Iter.flatMapM.{w, w'} {α β α₂ γ : Type w} {m : Type w → Type w'}
  [Monad m] [MonadAttach m] [Iterator α Id β] [Iterator α₂ m γ]
  (f : β → m (IterM m γ)) (it : Iter β) : IterM m γ
```

Let `it` be an iterator and `f` a monadic function mapping `it`'s outputs to iterators. Then `it.flatMapM f` is an iterator that goes over `it` and for each output, it applies `f` and iterates over the resulting iterator. `it.flatMapM f` emits all values obtained from the inner iterators -- first, all of the first inner iterator, then all of the second one, and so on.

**Marble diagram (without monadic effects):**

```text
it                 ---a      --b      c    --d -⊥
f a                    a1-a2⊥
f b                             b1-b2⊥
f c                                    c1-c2⊥
f d                                           ⊥
it.flatMapM        ----a1-a2----b1-b2--c1-c2----⊥
```

**Termination properties:**

- `Finite` instance: only if `it` and the inner iterators are finite
- `Productive` instance: only if `it` is finite and the inner iterators are productive

For certain functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided out of the box. For example, if the outer iterator is productive and the inner iterators are productive *and provably never empty*, then the resulting iterator is also productive.

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it` or an internal iterator.

For each value emitted by the outer iterator `it`, this combinator calls `f`.

<a id="Std___Iter___flatMapAfter"></a>

**def**

```text
Std.Iter.flatMapAfter.{w} {α β α₂ γ : Type w} [Iterator α Id β]
  [Iterator α₂ Id γ] (f : β → Iter γ) (it₁ : Iter β)
  (it₂ : Option (Iter γ)) : Iter γ
```

Let `it₁` and `it₂` be iterators and `f` a function mapping `it₁`'s outputs to iterators of the same type as `it₂`. Then `it₁.flatMapAfter f it₂` first goes over `it₂` and then over `it₁.flatMap f it₂`, emitting all their values.

The main purpose of this combinator is to represent the intermediate state of a `flatMap` iterator that is currently iterating over one of the inner iterators.

**Marble diagram:**

```text
it₁                            --b      c    --d -⊥
it₂                      a1-a2⊥
f b                               b1-b2⊥
f c                                      c1-c2⊥
f d                                             ⊥
it.flatMapAfter  f it₂   a1-a2----b1-b2--c1-c2----⊥
```

**Termination properties:**

- `Finite` instance: only if `it₁`, `it₂` and the inner iterators are finite
- `Productive` instance: only if `it₁` is finite and `it₂` and the inner iterators are productive

For certain functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided out of the box. For example, if the outer iterator is productive and the inner iterators are productive *and provably never empty*, then the resulting iterator is also productive.

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it₁`, `it₂` or an internal iterator.

For each value emitted by the outer iterator `it₁`, this combinator calls `f`.

<a id="Std___Iter___flatMapAfterM"></a>

**def**

```text
Std.Iter.flatMapAfterM.{w, w'} {α β α₂ γ : Type w}
  {m : Type w → Type w'} [Monad m] [MonadAttach m] [Iterator α Id β]
  [Iterator α₂ m γ] (f : β → m (IterM m γ)) (it₁ : Iter β)
  (it₂ : Option (IterM m γ)) : IterM m γ
```

Let `it₁` and `it₂` be iterators and `f` a monadic function mapping `it₁`'s outputs to iterators of the same type as `it₂`. Then `it₁.flatMapAfterM f it₂` first goes over `it₂` and then over `it₁.flatMap f it₂`, emitting all their values.

The main purpose of this combinator is to represent the intermediate state of a `flatMap` iterator that is currently iterating over one of the inner iterators.

**Marble diagram (without monadic effects):**

```text
it₁                            --b      c    --d -⊥
it₂                      a1-a2⊥
f b                               b1-b2⊥
f c                                      c1-c2⊥
f d                                             ⊥
it.flatMapAfterM f it₂   a1-a2----b1-b2--c1-c2----⊥
```

**Termination properties:**

- `Finite` instance: only if `it₁`, `it₂` and the inner iterators are finite
- `Productive` instance: only if `it₁` is finite and `it₂` and the inner iterators are productive

For certain functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided out of the box. For example, if the outer iterator is productive and the inner iterators are productive *and provably never empty*, then the resulting iterator is also productive.

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it₁`, `it₂` or an internal iterator.

For each value emitted by the outer iterator `it₁`, this combinator calls `f`.

<a id="Std___Iter___filter"></a>

**def**

```text
Std.Iter.filter.{w} {α β : Type w} [Iterator α Id β] (f : β → Bool)
  (it : Iter β) : Iter β
```

If `it` is an iterator, then `it.filter f` is another iterator that applies a predicate `f` to all values emitted by `it` and emits them only if they are accepted by `f`.

In situations where `f` is monadic, use `filterM` instead.

**Marble diagram (without monadic effects):**

```proofscript
it            ---a--b--c--d-e--⊥
it.filter     ---a-----c-------⊥
```

(given that `f a = f c = true` and `f b = f d = d e = false`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite`

For certain mapping functions `f`, the resulting iterator will be productive even though no `Productive` instance is provided. For example, if `f` always returns `True`, the resulting iterator will be productive as long as `it` is. In such situations, the missing instance needs to be proved manually.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f` and matches on the returned value.

<a id="Std___Iter___filterM"></a>

**def**

```text
Std.Iter.filterM.{w, w'} {α β : Type w} [Iterator α Id β]
  {m : Type w → Type w'} [Monad m] [MonadAttach m]
  (f : β → m (ULift Bool)) (it : Iter β) : IterM m β
```

If `it` is an iterator, then `it.filterM f` is another iterator that applies a monadic predicate `f` to all values emitted by `it` and emits them only if they are accepted by `f`.

If `f` is pure, then the simpler variant `it.filter` can be used instead.

**Marble diagram (without monadic effects):**

```proofscript
it             ---a--b--c--d-e--⊥
it.filterM     ---a-----c-------⊥
```

(given that `f a = f c = pure true` and `f b = f d = d e = pure false`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite`

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` is an `ExceptT` monad and will always fail, then `it.filterWithPostcondition` will be finite -- and productive -- even if `it` isn't. In such cases, the termination proof needs to be done manually.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f`.

<a id="Std___Iter___filterWithPostcondition"></a>

**def**

```text
Std.Iter.filterWithPostcondition.{w, w'} {α β : Type w}
  [Iterator α Id β] {m : Type w → Type w'} [Monad m]
  (f : β → PostconditionT m (ULift Bool)) (it : Iter β) : IterM m β
```

*Note: This is a very general combinator that requires an advanced understanding of monads, dependent types and termination proofs. The variants `filter` and `filterM` are easier to use and sufficient for most use cases.*

If `it` is an iterator, then `it.filterWithPostcondition f` is another iterator that applies a monadic predicate `f` to all values emitted by `it` and emits them only if they are accepted by `f`.

`f` is expected to return `PostconditionT n (ULift Bool)`, where `n` is an arbitrary monad. The `PostconditionT` transformer allows the caller to intrinsically prove properties about `f`'s return value in the monad `n`, enabling termination proofs depending on the specific behavior of `f`.

**Marble diagram (without monadic effects):**

```proofscript
it                             ---a--b--c--d-e--⊥
it.filterWithPostcondition     ---a-----c-------⊥
```

(given that `f a = f c = pure true` and `f b = f d = d e = pure false`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite`

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` is an `ExceptT` monad and will always fail, then `it.filterWithPostcondition` will be finite -- and productive -- even if `it` isn't.

In such situations, the missing instances can be proved manually if the postcondition bundled in the `PostconditionT n` monad is strong enough. In the given example, a suitable postcondition might be `fun _ => False`.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f`.

<a id="Std___Iter___filterMap"></a>

**def**

```text
Std.Iter.filterMap.{w} {α β γ : Type w} [Iterator α Id β]
  (f : β → Option γ) (it : Iter β) : Iter γ
```

If `it` is an iterator, then `it.filterMap f` is another iterator that applies a function `f` to all values emitted by `it`. `f` is expected to return an `Option`. If it returns `none`, then nothing is emitted; if it returns `some x`, then `x` is emitted.

In situations where `f` is monadic, use `filterMapM` instead.

**Marble diagram:**

```proofscript
it               ---a --b--c --d-e--⊥
it.filterMap     ---a'-----c'-------⊥
```

(given that `f a = some a'`, `f c = c'` and `f b = f d = d e = none`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite`

For certain mapping functions `f`, the resulting iterator will be productive even though no `Productive` instance is provided. For example, if `f` never returns `none`, then this combinator will preserve productiveness. In such situations, the missing instance needs to be proved manually.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f` and matches on the returned `Option` value.

<a id="Std___Iter___filterMapM"></a>

**def**

```text
Std.Iter.filterMapM.{w, w'} {α β γ : Type w} [Iterator α Id β]
  {m : Type w → Type w'} [Monad m] [MonadAttach m]
  (f : β → m (Option γ)) (it : Iter β) : IterM m γ
```

If `it` is an iterator, then `it.filterMapM f` is another iterator that applies a monadic function `f` to all values emitted by `it`. `f` is expected to return an `Option` inside the monad. If `f` returns `none`, then nothing is emitted; if it returns `some x`, then `x` is emitted.

If `f` is pure, then the simpler variant `it.filterMap` can be used instead.

**Marble diagram (without monadic effects):**

```proofscript
it                ---a --b--c --d-e--⊥
it.filterMapM     ---a'-----c'-------⊥
```

(given that `f a = pure (some a)'`, `f c = pure (some c')` and `f b = f d = d e = pure none`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite`

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` never returns `none`, then this combinator will preserve productiveness. If `f` is an `ExceptT` monad and will always fail, then `it.filterMapM` will be finite even if `it` isn't. In such cases, the termination proof needs to be done manually.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f` and matches on the returned `Option` value.

<a id="Std___Iter___filterMapWithPostcondition"></a>

**def**

```text
Std.Iter.filterMapWithPostcondition.{w, w'} {α β γ : Type w}
  [Iterator α Id β] {m : Type w → Type w'} [Monad m]
  (f : β → PostconditionT m (Option γ)) (it : Iter β) : IterM m γ
```

*Note: This is a very general combinator that requires an advanced understanding of monads, dependent types and termination proofs. The variants `filterMap` and `filterMapM` are easier to use and sufficient for most use cases.*

If `it` is an iterator, then `it.filterMapWithPostcondition f` is another iterator that applies a monadic function `f` to all values emitted by `it`. `f` is expected to return an `Option` inside the monad. If `f` returns `none`, then nothing is emitted; if it returns `some x`, then `x` is emitted.

`f` is expected to return `PostconditionT n (Option _)`, where `n` is an arbitrary monad. The `PostconditionT` transformer allows the caller to intrinsically prove properties about `f`'s return value in the monad `n`, enabling termination proofs depending on the specific behavior of `f`.

**Marble diagram (without monadic effects):**

```proofscript
it                                ---a --b--c --d-e--⊥
it.filterMapWithPostcondition     ---a'-----c'-------⊥
```

(given that `f a = pure (some a')`, `f c = pure (some c')` and `f b = f d = d e = pure none`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` never returns `none`, then this combinator will preserve productiveness. If `f` is an `ExceptT` monad and will always fail, then `it.filterMapWithPostcondition` will be finite even if `it` isn't. In the first case, consider using the `map`/`mapM`/`mapWithPostcondition` combinators instead, which provide more instances out of the box.

In such situations, the missing instances can be proved manually if the postcondition bundled in the `PostconditionT n` monad is strong enough. If `f` always returns `some _`, a suitable postcondition is `fun x => x.isSome`; if `f` always fails, a suitable postcondition might be `fun _ => False`.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f` and matches on the returned `Option` value.

<a id="Std___Iter___zip"></a>

**def**

```text
Std.Iter.zip.{w} {α₁ β₁ α₂ β₂ : Type w} [Iterator α₁ Id β₁]
  [Iterator α₂ Id β₂] (left : Iter β₁) (right : Iter β₂) :
  Iter (β₁ × β₂)
```

Given two iterators `left` and `right`, `left.zip right` is an iterator that yields pairs of outputs of `left` and `right`. When one of them terminates, the `zip` iterator will also terminate.

**Marble diagram:**

```proofscript
left               --a        ---b        --c
right                 --x         --y        --⊥
left.zip right     -----(a, x)------(b, y)-----⊥
```

**Termination properties:**

- `Finite` instance: only if either `left` or `right` is finite and the other is productive
- `Productive` instance: only if `left` and `right` are productive

There are situations where `left.zip right` is finite (or productive) but none of the instances above applies. For example, if `left` immediately terminates but `right` always skips, then `left.zip.right` is finite even though no `Finite` (or even `Productive`) instance is available. Such instances need to be proved manually.

**Performance:**

This combinator incurs an additional O(1) cost with each step taken by `left` or `right`.

Right now, the compiler does not unbox the internal state, leading to worse performance than theoretically possible.

<a id="Std___Iter___attachWith"></a>

**def**

```text
Std.Iter.attachWith.{w} {α β : Type w} [Iterator α Id β] (it : Iter β)
  (P : β → Prop)
  (h : ∀ (out : β), it.IsPlausibleIndirectOutput out → P out) :
  Iter { out // P out }
```

“Attaches” individual proofs to an iterator of values that satisfy a predicate `P`, returning an iterator with values in the corresponding subtype `{ x // P x }`.

**Termination properties:**

- `Finite` instance: only if the base iterator is finite
- `Productive` instance: only if the base iterator is productive

<a id="The-Lean-Language-Reference--Iterators--Iterator-Combinators--Monadic-Combinators"></a>
### 22.4.2. Monadic Combinators

<a id="Std___IterM___toIter"></a>

**def**

```text
Std.IterM.toIter.{w} {α β : Type w} (it : IterM Id β) : Iter β
```

Converts a monadic iterator (`IterM Id β`) over `Id` into a pure iterator (`Iter β`).

<a id="Std___IterM___take"></a>

**def**

```text
Std.IterM.take.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w}
  [Iterator α m β] (n : Nat) (it : IterM m β) : IterM m β
```

Given an iterator `it` and a natural number `n`, `it.take n` is an iterator that outputs up to the first `n` of `it`'s values in order and then terminates.

**Marble diagram:**

```proofscript
it          ---a----b---c--d-e--⊥
it.take 3   ---a----b---c⊥

it          ---a--⊥
it.take 3   ---a--⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is productive
- `Productive` instance: only if `it` is productive

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it`.

<a id="Std___IterM___takeWhile"></a>

**def**

```text
Std.IterM.takeWhile.{w, w'} {α : Type w} {m : Type w → Type w'}
  {β : Type w} [Monad m] (P : β → Bool) (it : IterM m β) : IterM m β
```

Given an iterator `it` and a predicate `P`, `it.takeWhile P` is an iterator that outputs the values emitted by `it` until one of those values is rejected by `P`. If some emitted value is rejected by `P`, the value is dropped and the iterator terminates.

In situations where `P` is monadic, use `takeWhileM` instead.

**Marble diagram (ignoring monadic effects):**

Assuming that the predicate `P` accepts `a` and `b` but rejects `c`:

```proofscript
it               ---a----b---c--d-e--⊥
it.takeWhile P   ---a----b---⊥

it               ---a----⊥
it.takeWhile P   ---a----⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

Depending on `P`, it is possible that `it.takeWhile P` is finite (or productive) although `it` is not. In this case, the `Finite` (or `Productive`) instance needs to be proved manually.

**Performance:**

This combinator calls `P` on each output of `it` until the predicate evaluates to false. Then it terminates.

<a id="Std___IterM___takeWhileM"></a>

**def**

```text
Std.IterM.takeWhileM.{w, w'} {α : Type w} {m : Type w → Type w'}
  {β : Type w} [Monad m] [MonadAttach m] (P : β → m (ULift Bool))
  (it : IterM m β) : IterM m β
```

Given an iterator `it` and a monadic predicate `P`, `it.takeWhileM P` is an iterator that outputs the values emitted by `it` until one of those values is rejected by `P`. If some emitted value is rejected by `P`, the value is dropped and the iterator terminates.

If `P` is pure, then the simpler variant `takeWhile` can be used instead.

**Marble diagram (ignoring monadic effects):**

Assuming that the predicate `P` accepts `a` and `b` but rejects `c`:

```proofscript
it                ---a----b---c--d-e--⊥
it.takeWhileM P   ---a----b---⊥

it                ---a----⊥
it.takeWhileM P   ---a----⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

Depending on `P`, it is possible that `it.takeWhileM P` is finite (or productive) although `it` is not. In this case, the `Finite` (or `Productive`) instance needs to be proved manually.

**Performance:**

This combinator calls `P` on each output of `it` until the predicate evaluates to false. Then it terminates.

<a id="Std___IterM___takeWhileWithPostcondition"></a>

**def**

```text
Std.IterM.takeWhileWithPostcondition.{w, w'} {α : Type w}
  {m : Type w → Type w'} {β : Type w}
  (P : β → PostconditionT m (ULift Bool)) (it : IterM m β) : IterM m β
```

*Note: This is a very general combinator that requires an advanced understanding of monads, dependent types and termination proofs. The variants `takeWhile` and `takeWhileM` are easier to use and sufficient for most use cases.*

Given an iterator `it` and a monadic predicate `P`, `it.takeWhileWithPostcondition P` is an iterator that emits the values emitted by `it` until one of those values is rejected by `P`. If some emitted value is rejected by `P`, the value is dropped and the iterator terminates.

`P` is expected to return `PostconditionT m (ULift Bool)`. The `PostconditionT` transformer allows the caller to intrinsically prove properties about `P`'s return value in the monad `m`, enabling termination proofs depending on the specific behavior of `P`.

**Marble diagram (ignoring monadic effects):**

Assuming that the predicate `P` accepts `a` and `b` but rejects `c`:

```proofscript
it                                ---a----b---c--d-e--⊥
it.takeWhileWithPostcondition P   ---a----b---⊥

it                                ---a----⊥
it.takeWhileWithPostcondition P   ---a----⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

Depending on `P`, it is possible that `it.takeWhileWithPostcondition P` is finite (or productive) although `it` is not. In this case, the `Finite` (or `Productive`) instance needs to be proved manually.

**Performance:**

This combinator calls `P` on each output of `it` until the predicate evaluates to false. Then it terminates.

<a id="Std___IterM___toTake"></a>

**def**

```text
Std.IterM.toTake.{w, w'} {α : Type w} {m : Type w → Type w'}
  {β : Type w} [Iterator α m β] [Finite α m] (it : IterM m β) :
  IterM m β
```

This combinator is only useful for advanced use cases.

Given a finite iterator `it`, returns an iterator that behaves exactly like `it` but is of the same type as `it.take n`.

**Marble diagram:**

```proofscript
it          ---a----b---c--d-e--⊥
it.toTake   ---a----b---c--d-e--⊥
```

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it`.

<a id="Std___IterM___drop"></a>

**def**

```text
Std.IterM.drop.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w}
  (n : Nat) (it : IterM m β) : IterM m β
```

Given an iterator `it` and a natural number `n`, `it.drop n` is an iterator that forwards all of `it`'s output values except for the first `n`.

**Marble diagram:**

```proofscript
it          ---a----b---c--d-e--⊥
it.drop 3   ---------------d-e--⊥

it          ---a--⊥
it.drop 3   ------⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

**Performance:**

Currently, this combinator incurs an additional O(1) cost with each output of `it`, even when the iterator does not drop any elements anymore.

<a id="Std___IterM___dropWhile"></a>

**def**

```text
Std.IterM.dropWhile.{w, w'} {α : Type w} {m : Type w → Type w'}
  {β : Type w} [Monad m] (P : β → Bool) (it : IterM m β) : IterM m β
```

Given an iterator `it` and a predicate `P`, `it.dropWhile P` is an iterator that emits the values emitted by `it` starting from the first value that is rejected by `P`. The elements before are dropped.

In situations where `P` is monadic, use `dropWhileM` instead.

**Marble diagram (ignoring monadic effects):**

Assuming that the predicate `P` accepts `a` and `b` but rejects `c`:

```proofscript
it               ---a----b---c--d-e--⊥
it.dropWhile P   ------------c--d-e--⊥

it               ---a----⊥
it.dropWhile P   --------⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite

**Performance:**

This combinator calls `P` on each output of `it` until the predicate evaluates to false. After that, the combinator incurs an addictional O(1) cost for each value emitted by `it`.

<a id="Std___IterM___dropWhileM"></a>

**def**

```text
Std.IterM.dropWhileM.{w, w'} {α : Type w} {m : Type w → Type w'}
  {β : Type w} [Monad m] [MonadAttach m] (P : β → m (ULift Bool))
  (it : IterM m β) : IterM m β
```

Given an iterator `it` and a monadic predicate `P`, `it.dropWhileM P` is an iterator that emits the values emitted by `it` starting from the first value that is rejected by `P`. The elements before are dropped.

If `P` is pure, then the simpler variant `dropWhile` can be used instead.

**Marble diagram (ignoring monadic effects):**

Assuming that the predicate `P` accepts `a` and `b` but rejects `c`:

```proofscript
it                ---a----b---c--d-e--⊥
it.dropWhileM P   ------------c--d-e--⊥

it                ---a----⊥
it.dropWhileM P   --------⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite

Depending on `P`, it is possible that `it.dropWhileM P` is finite (or productive) although `it` is not. In this case, the `Finite` (or `Productive`) instance needs to be proved manually.

**Performance:**

This combinator calls `P` on each output of `it` until the predicate evaluates to false. After that, the combinator incurs an addictional O(1) cost for each value emitted by `it`.

<a id="Std___IterM___dropWhileWithPostcondition"></a>

**def**

```text
Std.IterM.dropWhileWithPostcondition.{w, w'} {α : Type w}
  {m : Type w → Type w'} {β : Type w}
  (P : β → PostconditionT m (ULift Bool)) (it : IterM m β) : IterM m β
```

*Note: This is a very general combinator that requires an advanced understanding of monads, dependent types and termination proofs. The variants `dropWhile` and `dropWhileM` are easier to use and sufficient for most use cases.*

Given an iterator `it` and a monadic predicate `P`, `it.dropWhileWithPostcondition P` is an iterator that emits the values emitted by `it` starting from the first value that is rejected by `P`. The elements before are dropped.

`P` is expected to return `PostconditionT m (ULift Bool)`. The `PostconditionT` transformer allows the caller to intrinsically prove properties about `P`'s return value in the monad `m`, enabling termination proofs depending on the specific behavior of `P`.

**Marble diagram (ignoring monadic effects):**

Assuming that the predicate `P` accepts `a` and `b` but rejects `c`:

```proofscript
it                                ---a----b---c--d-e--⊥
it.dropWhileWithPostcondition P   ------------c--d-e--⊥

it                                ---a----⊥
it.dropWhileWithPostcondition P   --------⊥
```

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite

Depending on `P`, it is possible that `it.dropWhileWithPostcondition P` is finite (or productive) although `it` is not. In this case, the `Finite` (or `Productive`) instance needs to be proved manually.

**Performance:**

This combinator calls `P` on each output of `it` until the predicate evaluates to false. After that, the combinator incurs an additional O(1) cost for each value emitted by `it`.

<a id="Std___IterM___stepSize"></a>

**def**

```text
Std.IterM.stepSize.{u_1, u_2} {α : Type u_1} {m : Type u_1 → Type u_2}
  {β : Type u_1} [Iterator α m β] [IteratorAccess α m] [Monad m]
  (it : IterM m β) (n : Nat) : IterM m β
```

Produces an iterator that emits one value of `it`, then drops `n - 1` elements, then emits another value, and so on. In other words, it emits every `n`-th value of `it`, starting with the first one.

If `n = 0`, the iterator behaves like for `n = 1`: It emits all values of `it`.

**Marble diagram:**

```proofscript
it               ---1----2----3---4----5
it.stepSize 2    ---1---------3--------5
```

**Availability:**

This operation is currently only available for iterators implementing `IteratorAccess`, such as `PRange.iter` range iterators.

**Termination properties:**

- `Finite` instance: only if the base iterator `it` is finite
- `Productive` instance: always

<a id="Std___IterM___map"></a>

**def**

```text
Std.IterM.map.{w, w'} {α β γ : Type w} {m : Type w → Type w'}
  [Iterator α m β] [Monad m] (f : β → γ) (it : IterM m β) : IterM m γ
```

If `it` is an iterator, then `it.map f` is another iterator that applies a function `f` to all values emitted by `it` and emits the result.

In situations where `f` is monadic, use `mapM` instead.

**Marble diagram:**

```proofscript
it         ---a --b --c --d -e ----⊥
it.map     ---a'--b'--c'--d'-e'----⊥
```

(given that `f a = a'`, `f b = b'` etc.)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f`.

<a id="Std___IterM___mapM"></a>

**def**

```text
Std.IterM.mapM.{w, w', w''} {α β γ : Type w} {m : Type w → Type w'}
  {n : Type w → Type w''} [Iterator α m β] [Monad n] [MonadAttach n]
  [MonadLiftT m n] (f : β → n γ) (it : IterM m β) : IterM n γ
```

If `it` is an iterator, then `it.mapM f` is another iterator that applies a monadic function `f` to all values emitted by `it` and emits the result.

The base iterator `it` being monadic in `m`, `f` can return values in any monad `n` for which a `MonadLiftT m n` instance is available.

If `f` is pure, then the simpler variant `it.map` can be used instead.

**Marble diagram (without monadic effects):**

```proofscript
it          ---a --b --c --d -e ----⊥
it.mapM     ---a'--b'--c'--d'-e'----⊥
```

(given that `f a = pure a'`, `f b = pure b'` etc.)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` is an `ExceptT` monad and will always fail, then `it.mapM` will be finite even if `it` isn't. In such cases, the termination proof needs to be done manually.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f`.

<a id="Std___IterM___mapWithPostcondition"></a>

**def**

```text
Std.IterM.mapWithPostcondition.{w, w', w''} {α β γ : Type w}
  {m : Type w → Type w'} {n : Type w → Type w''} [Monad n]
  [MonadLiftT m n] [Iterator α m β] (f : β → PostconditionT n γ)
  (it : IterM m β) : IterM n γ
```

*Note: This is a very general combinator that requires an advanced understanding of monads, dependent types and termination proofs. The variants `map` and `mapM` are easier to use and sufficient for most use cases.*

If `it` is an iterator, then `it.mapWithPostcondition f` is another iterator that applies a monadic function `f` to all values emitted by `it` and emits the result.

`f` is expected to return `PostconditionT n _`. The base iterator `it` being monadic in `m`, `n` can be different from `m`, but `it.mapWithPostcondition f` expects a `MonadLiftT m n` instance. The `PostconditionT` transformer allows the caller to intrinsically prove properties about `f`'s return value in the monad `n`, enabling termination proofs depending on the specific behavior of `f`.

**Marble diagram (without monadic effects):**

```proofscript
it                          ---a --b --c --d -e ----⊥
it.mapWithPostcondition     ---a'--b'--c'--d'-e'----⊥
```

(given that `f a = pure a'`, `f b = pure b'` etc.)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is productive

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` is an `ExceptT` monad and will always fail, then `it.mapWithPostcondition` will be finite even if `it` isn't.

In such situations, the missing instances can be proved manually if the postcondition bundled in the `PostconditionT n` monad is strong enough. In the given example, a suitable postcondition might be `fun _ => False`.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f`.

<a id="Std___IterM___uLift"></a>

**def**

```text
Std.IterM.uLift.{v, u, v', u'} {α β : Type u} {m : Type u → Type u'}
  (it : IterM m β) (n : Type (max u v) → Type v')
  [lift : MonadLiftT m (ULiftT n)] : IterM n (ULift β)
```

Transforms an `m`-monadic iterator with values in `β` into an `n`-monadic iterator with values in `ULift β`. Requires a `MonadLift m (ULiftT n)` instance.

**Marble diagram:**

```proofscript
it            ---a    ----b    ---c    --d    ---⊥
it.uLift n    ---.up a----.up b---.up c--.up d---⊥
```

**Termination properties:**

- `Finite`: only if the original iterator is finite
- `Productive`: only if the original iterator is productive

<a id="Std___IterM___flatMap"></a>

**def**

```text
Std.IterM.flatMap.{w, w'} {α β α₂ γ : Type w} {m : Type w → Type w'}
  [Monad m] [Iterator α m β] [Iterator α₂ m γ] (f : β → IterM m γ)
  (it : IterM m β) : IterM m γ
```

Let `it` be an iterator and `f` a function mapping `it`'s outputs to iterators. Then `it.flatMap f` is an iterator that goes over `it` and for each output, it applies `f` and iterates over the resulting iterator. `it.flatMap f` emits all values obtained from the inner iterators -- first, all of the first inner iterator, then all of the second one, and so on.

**Marble diagram:**

```text
it                 ---a      --b      c    --d -⊥
f a                    a1-a2⊥
f b                             b1-b2⊥
f c                                    c1-c2⊥
f d                                           ⊥
it.flatMap         ----a1-a2----b1-b2--c1-c2----⊥
```

**Termination properties:**

- `Finite` instance: only if `it` and the inner iterators are finite
- `Productive` instance: only if `it` is finite and the inner iterators are productive

For certain functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided out of the box. For example, if the outer iterator is productive and the inner iterators are productive *and provably never empty*, then the resulting iterator is also productive.

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it` or an internal iterator.

For each value emitted by the outer iterator `it`, this combinator calls `f`.

<a id="Std___IterM___flatMapM"></a>

**def**

```text
Std.IterM.flatMapM.{w, w'} {α β α₂ γ : Type w} {m : Type w → Type w'}
  [Monad m] [MonadAttach m] [Iterator α m β] [Iterator α₂ m γ]
  (f : β → m (IterM m γ)) (it : IterM m β) : IterM m γ
```

Let `it` be an iterator and `f` a monadic function mapping `it`'s outputs to iterators. Then `it.flatMapM f` is an iterator that goes over `it` and for each output, it applies `f` and iterates over the resulting iterator. `it.flatMapM f` emits all values obtained from the inner iterators -- first, all of the first inner iterator, then all of the second one, and so on.

**Marble diagram (without monadic effects):**

```text
it                 ---a      --b      c    --d -⊥
f a                    a1-a2⊥
f b                             b1-b2⊥
f c                                    c1-c2⊥
f d                                           ⊥
it.flatMapM        ----a1-a2----b1-b2--c1-c2----⊥
```

**Termination properties:**

- `Finite` instance: only if `it` and the inner iterators are finite
- `Productive` instance: only if `it` is finite and the inner iterators are productive

For certain functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided out of the box. For example, if the outer iterator is productive and the inner iterators are productive *and provably never empty*, then the resulting iterator is also productive.

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it` or an internal iterator.

For each value emitted by the outer iterator `it`, this combinator calls `f`.

<a id="Std___IterM___flatMapAfter"></a>

**def**

```text
Std.IterM.flatMapAfter.{w, w'} {α β α₂ γ : Type w}
  {m : Type w → Type w'} [Monad m] [Iterator α m β] [Iterator α₂ m γ]
  (f : β → IterM m γ) (it₁ : IterM m β) (it₂ : Option (IterM m γ)) :
  IterM m γ
```

Let `it₁` and `it₂` be iterators and `f` a function mapping `it₁`'s outputs to iterators of the same type as `it₂`. Then `it₁.flatMapAfter f it₂` first goes over `it₂` and then over `it₁.flatMap f it₂`, emitting all their values.

The main purpose of this combinator is to represent the intermediate state of a `flatMap` iterator that is currently iterating over one of the inner iterators.

**Marble diagram:**

```text
it₁                            --b      c    --d -⊥
it₂                      a1-a2⊥
f b                               b1-b2⊥
f c                                      c1-c2⊥
f d                                             ⊥
it.flatMapAfter  f it₂   a1-a2----b1-b2--c1-c2----⊥
```

**Termination properties:**

- `Finite` instance: only if `it₁`, `it₂` and the inner iterators are finite
- `Productive` instance: only if `it₁` is finite and `it₂` and the inner iterators are productive

For certain functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided out of the box. For example, if the outer iterator is productive and the inner iterators are productive *and provably never empty*, then the resulting iterator is also productive.

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it₁`, `it₂` or an internal iterator.

For each value emitted by the outer iterator `it₁`, this combinator calls `f`.

<a id="Std___IterM___flatMapAfterM"></a>

**def**

```text
Std.IterM.flatMapAfterM.{w, w'} {α β α₂ γ : Type w}
  {m : Type w → Type w'} [Monad m] [MonadAttach m] [Iterator α m β]
  [Iterator α₂ m γ] (f : β → m (IterM m γ)) (it₁ : IterM m β)
  (it₂ : Option (IterM m γ)) : IterM m γ
```

Let `it₁` and `it₂` be iterators and `f` a monadic function mapping `it₁`'s outputs to iterators of the same type as `it₂`. Then `it₁.flatMapAfterM f it₂` first goes over `it₂` and then over `it₁.flatMap f it₂`, emitting all their values.

The main purpose of this combinator is to represent the intermediate state of a `flatMap` iterator that is currently iterating over one of the inner iterators.

**Marble diagram (without monadic effects):**

```text
it₁                            --b      c    --d -⊥
it₂                      a1-a2⊥
f b                               b1-b2⊥
f c                                      c1-c2⊥
f d                                             ⊥
it.flatMapAfterM f it₂   a1-a2----b1-b2--c1-c2----⊥
```

**Termination properties:**

- `Finite` instance: only if `it₁`, `it₂` and the inner iterators are finite
- `Productive` instance: only if `it₁` is finite and `it₂` and the inner iterators are productive

For certain functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided out of the box. For example, if the outer iterator is productive and the inner iterators are productive *and provably never empty*, then the resulting iterator is also productive.

**Performance:**

This combinator incurs an additional O(1) cost with each output of `it₁`, `it₂` or an internal iterator.

For each value emitted by the outer iterator `it₁`, this combinator calls `f`.

<a id="Std___IterM___filter"></a>

**def**

```text
Std.IterM.filter.{w, w'} {α β : Type w} {m : Type w → Type w'}
  [Iterator α m β] [Monad m] (f : β → Bool) (it : IterM m β) : IterM m β
```

If `it` is an iterator, then `it.filter f` is another iterator that applies a predicate `f` to all values emitted by `it` and emits them only if they are accepted by `f`.

In situations where `f` is monadic, use `filterM` instead.

**Marble diagram (without monadic effects):**

```proofscript
it            ---a--b--c--d-e--⊥
it.filter     ---a-----c-------⊥
```

(given that `f a = f c = true` and `f b = f d = d e = false`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite`

For certain mapping functions `f`, the resulting iterator will be productive even though no `Productive` instance is provided. For example, if `f` always returns `True`, the resulting iterator will be productive as long as `it` is. In such situations, the missing instance needs to be proved manually.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f` and matches on the returned value.

<a id="Std___IterM___filterM"></a>

**def**

```text
Std.IterM.filterM.{w, w', w''} {α β : Type w} {m : Type w → Type w'}
  {n : Type w → Type w''} [Iterator α m β] [Monad n] [MonadAttach n]
  [MonadLiftT m n] (f : β → n (ULift Bool)) (it : IterM m β) : IterM n β
```

If `it` is an iterator, then `it.filterM f` is another iterator that applies a monadic predicate `f` to all values emitted by `it` and emits them only if they are accepted by `f`.

The base iterator `it` being monadic in `m`, `f` can return values in any monad `n` for which a `MonadLiftT m n` instance is available.

If `f` is pure, then the simpler variant `it.filter` can be used instead.

**Marble diagram (without monadic effects):**

```proofscript
it             ---a--b--c--d-e--⊥
it.filterM     ---a-----c-------⊥
```

(given that `f a = f c = pure true` and `f b = f d = d e = pure false`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite`

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` is an `ExceptT` monad and will always fail, then `it.filterWithPostcondition` will be finite -- and productive -- even if `it` isn't. In such cases, the termination proof needs to be done manually.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f`.

<a id="Std___IterM___filterWithPostcondition"></a>

**def**

```text
Std.IterM.filterWithPostcondition.{w, w', w''} {α β : Type w}
  {m : Type w → Type w'} {n : Type w → Type w''} [Monad n]
  [MonadLiftT m n] [Iterator α m β]
  (f : β → PostconditionT n (ULift Bool)) (it : IterM m β) : IterM n β
```

*Note: This is a very general combinator that requires an advanced understanding of monads, dependent types and termination proofs. The variants `filter` and `filterM` are easier to use and sufficient for most use cases.*

If `it` is an iterator, then `it.filterWithPostcondition f` is another iterator that applies a monadic predicate `f` to all values emitted by `it` and emits them only if they are accepted by `f`.

`f` is expected to return `PostconditionT n (ULift Bool)`. The base iterator `it` being monadic in `m`, `n` can be different from `m`, but `it.filterWithPostcondition f` expects a `MonadLiftT m n` instance. The `PostconditionT` transformer allows the caller to intrinsically prove properties about `f`'s return value in the monad `n`, enabling termination proofs depending on the specific behavior of `f`.

**Marble diagram (without monadic effects):**

```proofscript
it                             ---a--b--c--d-e--⊥
it.filterWithPostcondition     ---a-----c-------⊥
```

(given that `f a = f c = pure true` and `f b = f d = d e = pure false`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite`

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` is an `ExceptT` monad and will always fail, then `it.filterWithPostcondition` will be finite -- and productive -- even if `it` isn't.

In such situations, the missing instances can be proved manually if the postcondition bundled in the `PostconditionT n` monad is strong enough. In the given example, a suitable postcondition might be `fun _ => False`.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f`.

<a id="Std___IterM___filterMap"></a>

**def**

```text
Std.IterM.filterMap.{w, w'} {α β γ : Type w} {m : Type w → Type w'}
  [Iterator α m β] [Monad m] (f : β → Option γ) (it : IterM m β) :
  IterM m γ
```

If `it` is an iterator, then `it.filterMap f` is another iterator that applies a function `f` to all values emitted by `it`. `f` is expected to return an `Option`. If it returns `none`, then nothing is emitted; if it returns `some x`, then `x` is emitted.

In situations where `f` is monadic, use `filterMapM` instead.

**Marble diagram:**

```proofscript
it               ---a --b--c --d-e--⊥
it.filterMap     ---a'-----c'-------⊥
```

(given that `f a = some a'`, `f c = c'` and `f b = f d = d e = none`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite`

For certain mapping functions `f`, the resulting iterator will be productive even though no `Productive` instance is provided. For example, if `f` never returns `none`, then this combinator will preserve productiveness. In such situations, the missing instance needs to be proved manually.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f` and matches on the returned `Option` value.

<a id="Std___IterM___filterMapM"></a>

**def**

```text
Std.IterM.filterMapM.{w, w', w''} {α β γ : Type w}
  {m : Type w → Type w'} {n : Type w → Type w''} [Iterator α m β]
  [Monad n] [MonadAttach n] [MonadLiftT m n] (f : β → n (Option γ))
  (it : IterM m β) : IterM n γ
```

If `it` is an iterator, then `it.filterMapM f` is another iterator that applies a monadic function `f` to all values emitted by `it`. `f` is expected to return an `Option` inside the monad. If `f` returns `none`, then nothing is emitted; if it returns `some x`, then `x` is emitted.

The base iterator `it` being monadic in `m`, `f` can return values in any monad `n` for which a `MonadLiftT m n` instance is available.

If `f` is pure, then the simpler variant `it.filterMap` can be used instead.

**Marble diagram (without monadic effects):**

```proofscript
it                ---a --b--c --d-e--⊥
it.filterMapM     ---a'-----c'-------⊥
```

(given that `f a = pure (some a)'`, `f c = pure (some c')` and `f b = f d = d e = pure none`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite`

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` never returns `none`, then this combinator will preserve productiveness. If `f` is an `ExceptT` monad and will always fail, then `it.filterMapM` will be finite even if `it` isn't. In such cases, the termination proof needs to be done manually.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f` and matches on the returned `Option` value.

<a id="Std___IterM___filterMapWithPostcondition"></a>

**def**

```text
Std.IterM.filterMapWithPostcondition.{w, w', w''} {α β γ : Type w}
  {m : Type w → Type w'} {n : Type w → Type w''} [MonadLiftT m n]
  [Iterator α m β] (f : β → PostconditionT n (Option γ))
  (it : IterM m β) : IterM n γ
```

*Note: This is a very general combinator that requires an advanced understanding of monads, dependent types and termination proofs. The variants `filterMap` and `filterMapM` are easier to use and sufficient for most use cases.*

If `it` is an iterator, then `it.filterMapWithPostcondition f` is another iterator that applies a monadic function `f` to all values emitted by `it`. `f` is expected to return an `Option` inside the monad. If `f` returns `none`, then nothing is emitted; if it returns `some x`, then `x` is emitted.

`f` is expected to return `PostconditionT n (Option _)`. The base iterator `it` being monadic in `m`, `n` can be different from `m`, but `it.filterMapWithPostcondition f` expects a `MonadLiftT m n` instance. The `PostconditionT` transformer allows the caller to intrinsically prove properties about `f`'s return value in the monad `n`, enabling termination proofs depending on the specific behavior of `f`.

**Marble diagram (without monadic effects):**

```proofscript
it                                ---a --b--c --d-e--⊥
it.filterMapWithPostcondition     ---a'-----c'-------⊥
```

(given that `f a = pure (some a)'`, `f c = pure (some c')` and `f b = f d = d e = pure none`)

**Termination properties:**

- `Finite` instance: only if `it` is finite
- `Productive` instance: only if `it` is finite

For certain mapping functions `f`, the resulting iterator will be finite (or productive) even though no `Finite` (or `Productive`) instance is provided. For example, if `f` never returns `none`, then this combinator will preserve productiveness. If `f` is an `ExceptT` monad and will always fail, then `it.filterMapWithPostcondition` will be finite even if `it` isn't. In the first case, consider using the `map`/`mapM`/`mapWithPostcondition` combinators instead, which provide more instances out of the box.

In such situations, the missing instances can be proved manually if the postcondition bundled in the `PostconditionT n` monad is strong enough. If `f` always returns `some _`, a suitable postcondition is `fun x => x.isSome`; if `f` always fails, a suitable postcondition might be `fun _ => False`.

**Performance:**

For each value emitted by the base iterator `it`, this combinator calls `f` and matches on the returned `Option` value.

<a id="Std___IterM___zip"></a>

**def**

```text
Std.IterM.zip.{w, w'} {m : Type w → Type w'} {α₁ β₁ : Type w}
  [Iterator α₁ m β₁] {α₂ β₂ : Type w} (left : IterM m β₁)
  (right : IterM m β₂) : IterM m (β₁ × β₂)
```

Given two iterators `left` and `right`, `left.zip right` is an iterator that yields pairs of outputs of `left` and `right`. When one of them terminates, the `zip` iterator will also terminate.

**Marble diagram:**

```proofscript
left               --a        ---b        --c
right                 --x         --y        --⊥
left.zip right     -----(a, x)------(b, y)-----⊥
```

**Termination properties:**

- `Finite` instance: only if either `left` or `right` is finite and the other is productive
- `Productive` instance: only if `left` and `right` are productive

There are situations where `left.zip right` is finite (or productive) but none of the instances above applies. For example, if the computation happens in an `Except` monad and `left` immediately fails when calling `step`, then `left.zip right` will also do so. In such a case, the `Finite` (or `Productive`) instance needs to be proved manually.

**Performance:**

This combinator incurs an additional O(1) cost with each step taken by `left` or `right`.

Right now, the compiler does not unbox the internal state, leading to worse performance than possible.

<a id="Std___IterM___attachWith"></a>

**def**

```text
Std.IterM.attachWith.{w, w'} {α β : Type w} {m : Type w → Type w'}
  [Monad m] [Iterator α m β] (it : IterM m β) (P : β → Prop)
  (h : ∀ (out : β), it.IsPlausibleIndirectOutput out → P out) :
  IterM m { out // P out }
```

“Attaches” individual proofs to an iterator of values that satisfy a predicate `P`, returning an iterator with values in the corresponding subtype `{ x // P x }`.

**Termination properties:**

- `Finite` instance: only if the base iterator is finite
- `Productive` instance: only if the base iterator is productive
