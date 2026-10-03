<a id="The-Lean-Language-Reference--Iterators--Consuming-Iterators"></a>

# ProofScript — 22.3. Consuming Iterators

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Iterator definitions describe state and stepping; consumers observe a sequence through the permitted interfaces. Combinators such as mapping and filtering transform that process without automatically inheriting termination, productivity, effect or allocation guarantees. Preserve the distinction between finite consumers and potentially unbounded iteration. Iterator proofs belong to the native abstraction and its law dependencies.

**Compiler and coverage boundary.** Version the iterator library and its instances. A foreign async stream additionally needs backpressure, cancellation and lifetime contracts; it is not an ordinary iterator by spelling alone.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Iterators/Consuming-Iterators/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Iterators/Consuming-Iterators/index.html). Source Git blob: `58e02c6eff2a38d137a1216b7592126e05482c98`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 22.3. Consuming Iterators

There are three primary ways to consume an iterator:

  Converting it to a sequential data structure

The functions `Iter.toList`, `Iter.toArray`, and their monadic equivalents `IterM.toList` and `IterM.toArray`, construct a lists or arrays that contain the values from the iterator, in order. Only [finite iterators](../Iterator-Definitions/index.md#--tech-term-Finite) can be converted to sequential data structures.

  `for` loops

A `for` loop can consume an iterator, making each value available in its body. This requires that the iterator have an instance of `IteratorLoop` for the loop's monad.

  Stepping through iterators

Iterators can provide their values one-by-one, with client code explicitly requesting each new value in turn. When stepped through, iterators perform only enough computation to yield the requested value.

<a id="Converting-Iterators-to-Lists"></a>
Converting Iterators to Lists 

In `countdown`, an iterator over a range is transformed into an iterator over strings using `Iter.map`. This call to `Iter.map` does not result in any iteration over the range until `Iter.toList` is called, at which point each element of the range is produced and transformed into a string.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="countdown-_LPAR_in-Converting-Iterators-to-Lists_RPAR_"></a>


```proofscript
const countdown : String :=
  let steps : Iter String := (0...10).iter.map (s!"{10 - ·}!\n")
  String.join steps.toList

#eval IO.println countdown
```

```lean
10!
9!
8!
7!
6!
5!
4!
3!
2!
1!
```

<a id="Converting-Infinite-Iterators-to-Lists"></a>
Converting Infinite Iterators to Lists 

Attempting to construct a list of all the natural numbers from an iterator will produce an endless loop:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const allNats : List Nat :=
  let steps : Iter Nat := (0...*).iter
  steps.toList
```

The combinator `Iter.ensureTermination` results in an iterator where non-termination is ruled out. These iterators are guaranteed to terminate after finitely many steps, and thus cannot be used when Lean cannot prove the iterator finite.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const allNats : List Nat :=
  let steps := (0...*).iter.ensureTermination
  steps.toList
```

The resulting error message states that there is no `Finite` instance:

```lean
failed to synthesize instance of type class
  Finite (Rxi.Iterator Nat) Id

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

<a id="Consuming-Iterators-in-Loops"></a>
Consuming Iterators in Loops 

This program creates an iterator of strings from a range, and then consumes the strings in a `for` loop:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="countdown-_LPAR_in-Consuming-Iterators-in-Loops_RPAR_"></a>


```proofscript
function countdown (n : Nat) : IO Unit := do
  let steps : Iter String := (0...n).iter.map (s!"{n - ·}!")
  for i in steps do
    IO.println i
  IO.println "Blastoff!"

#eval countdown 5
```

```lean
5!
4!
3!
2!
1!
Blastoff!
```

<a id="Consuming-Iterators-Directly"></a>
Consuming Iterators Directly 

The function `countdown` calls the range iterator's `step` function directly, handling each of the three possible cases.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="countdown-_LPAR_in-Consuming-Iterators-Directly_RPAR_"></a>
<a id="countdown___go-_LPAR_in-Consuming-Iterators-Directly_RPAR_"></a>


```proofscript
function countdown (n : Nat) : IO Unit := do
  let steps : Iter Nat := (0...n).iter
  go steps
where
  go iter := do
    match iter.step with
    | .done _ => pure ()
    | .skip iter' _ => go iter'
    | .yield iter' i _ => do
      IO.println s!"{i}!"
      if i == 2 then
        IO.println s!"Almost there..."
      go iter'
  termination_by iter.finitelyManySteps
```

<a id="The-Lean-Language-Reference--Iterators--Consuming-Iterators--Stepping-Iterators"></a>
### 22.3.1. Stepping Iterators

Iterators are manually stepped using `Iter.step` or `IterM.step`.

<a id="Std___Iter___step"></a>

**def**

```text
Std.Iter.step.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) :
  it.Step
```

Makes a single step with the given iterator `it`, potentially emitting a value and providing a succeeding iterator. If this function is used recursively, termination can sometimes be proved with the termination measures `it.finitelyManySteps` and `it.finitelyManySkips`.

<a id="Std___IterM___step"></a>

**def**

```text
Std.IterM.step.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w}
  [Iterator α m β] (it : IterM m β) : m (Std.Shrink it.Step)
```

Makes a single step with the given iterator `it`, potentially emitting a value and providing a succeeding iterator. If this function is used recursively, termination can sometimes be proved with the termination measures `it.finitelyManySteps` and `it.finitelyManySkips`.

<a id="The-Lean-Language-Reference--Iterators--Consuming-Iterators--Stepping-Iterators--Termination"></a>
#### 22.3.1.1. Termination

When manually stepping an finite iterator, the termination measures `finitelyManySteps` and `finitelyManySkips` can be used to express that each step brings iteration closer to the end. The proof automation for [well-founded recursion](../../Definitions/Recursive-Definitions/index.md#well-founded-recursion) is pre-configured to prove that recursive calls after steps reduce these measures.

<a id="Finitely-Many-Skips"></a>
Finitely Many Skips 

This function returns the first element of an iterator, if there is one, or `none` otherwise. Because the iterator must be productive, it is guaranteed to return an element after at most a finite number of `skip`s. This function terminates even for infinite iterators.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="getFirst-_LPAR_in-Finitely-Many-Skips_RPAR_"></a>


```proofscript
function getFirst {α β} [Iterator α Id β] [Productive α Id]
    (it : @Iter α β) : Option β :=
  match it.step with
  | .done .. => none
  | .skip it' .. => getFirst it'
  | .yield _ x .. => pure x
termination_by it.finitelyManySkips
```

<a id="Std___Iter___finitelyManySteps"></a>

**def**

```text
Std.Iter.finitelyManySteps.{w} {α β : Type w} [Iterator α Id β]
  [Finite α Id] (it : Iter β) : IterM.TerminationMeasures.Finite α Id
```

Termination measure to be used in well-founded recursive functions recursing over a finite iterator (see also `Finite`).

<a id="Std___IterM___finitelyManySteps"></a>

**def**

```text
Std.IterM.finitelyManySteps.{w, w'} {α : Type w} {m : Type w → Type w'}
  {β : Type w} [Iterator α m β] [Finite α m] (it : IterM m β) :
  IterM.TerminationMeasures.Finite α m
```

Termination measure to be used in well-founded recursive functions recursing over a finite iterator (see also `Finite`).

<a id="Std___IterM___TerminationMeasures___Finite___mk"></a>

**structure**

```text
Std.IterM.TerminationMeasures.Finite.{w, w'} (α : Type w)
  (m : Type w → Type w') {β : Type w} [Iterator α m β] : Type w
```

This type is a wrapper around `IterM` so that it becomes a useful termination measure for recursion over finite iterators. See also `IterM.finitelyManySteps` and `Iter.finitelyManySteps`.

**Constructor**

```text
Std.IterM.TerminationMeasures.Finite.mk.{w, w'}
```

**Fields**

```text
it : IterM m β
```

The wrapped iterator.

In the wrapper, its finiteness is used as a termination measure.

<a id="Std___Iter___finitelyManySkips"></a>

**def**

```text
Std.Iter.finitelyManySkips.{w} {α β : Type w} [Iterator α Id β]
  [Productive α Id] (it : Iter β) :
  IterM.TerminationMeasures.Productive α Id
```

Termination measure to be used in well-founded recursive functions recursing over a productive iterator (see also `Productive`).

<a id="Std___IterM___finitelyManySkips"></a>

**def**

```text
Std.IterM.finitelyManySkips.{w, w'} {α : Type w} {m : Type w → Type w'}
  {β : Type w} [Iterator α m β] [Productive α m] (it : IterM m β) :
  IterM.TerminationMeasures.Productive α m
```

Termination measure to be used in well-founded recursive functions recursing over a productive iterator (see also `Productive`).

<a id="Std___IterM___TerminationMeasures___Productive___mk"></a>

**structure**

```text
Std.IterM.TerminationMeasures.Productive.{w, w'} (α : Type w)
  (m : Type w → Type w') {β : Type w} [Iterator α m β] : Type w
```

This type is a wrapper around `IterM` so that it becomes a useful termination measure for recursion over productive iterators. See also `IterM.finitelyManySkips` and `Iter.finitelyManySkips`.

**Constructor**

```text
Std.IterM.TerminationMeasures.Productive.mk.{w, w'}
```

**Fields**

```text
it : IterM m β
```

The wrapped iterator.

In the wrapper, its productivity is used as a termination measure.

<a id="The-Lean-Language-Reference--Iterators--Consuming-Iterators--Consuming-Pure-Iterators"></a>
### 22.3.2. Consuming Pure Iterators

<a id="Std___Iter___fold"></a>

**def**

```text
Std.Iter.fold.{w, x} {α β : Type w} {γ : Type x} [Iterator α Id β]
  [IteratorLoop α Id Id] (f : γ → β → γ) (init : γ) (it : Iter β) : γ
```

Folds a function over an iterator from the left, accumulating a value starting with `init`. The accumulated value is combined with the each element of the list in order, using `f`.

It is equivalent to `it.toList.foldl`.

<a id="Std___Iter___foldM"></a>

**def**

```text
Std.Iter.foldM.{x, x', w} {m : Type x → Type x'} [Monad m]
  {α β : Type w} {γ : Type x} [Iterator α Id β] [IteratorLoop α Id m]
  (f : γ → β → m γ) (init : γ) (it : Iter β) : m γ
```

Folds a monadic function over an iterator from the left, accumulating a value starting with `init`. The accumulated value is combined with the each element of the list in order, using `f`.

It is equivalent to `it.toList.foldlM`.

<a id="Std___Iter___length"></a>

**def**

```text
Std.Iter.length.{w} {α β : Type w} [Iterator α Id β]
  [IteratorLoop α Id Id] (it : Iter β) : Nat
```

Steps through the whole iterator, counting the number of outputs emitted.

**Performance**:

This function's runtime is linear in the number of steps taken by the iterator.

<a id="Std___Iter___any"></a>

**def**

```text
Std.Iter.any.{w} {α β : Type w} [Iterator α Id β] [IteratorLoop α Id Id]
  (p : β → Bool) (it : Iter β) : Bool
```

Returns `true` if the pure predicate `p` returns `true` for any element emitted by the iterator `it`.

`O(|xs|)`. Short-circuits upon encountering the first match. The elements in `it` are examined in order of iteration.

<a id="Std___Iter___anyM"></a>

**def**

```text
Std.Iter.anyM.{w, w'} {α β : Type w} {m : Type → Type w'} [Monad m]
  [Iterator α Id β] [IteratorLoop α Id m] (p : β → m Bool)
  (it : Iter β) : m Bool
```

Returns `true` if the monadic predicate `p` returns `true` for any element emitted by the iterator `it`.

`O(|xs|)`. Short-circuits upon encountering the first match. The elements in `it` are examined in order of iteration.

<a id="Std___Iter___all"></a>

**def**

```text
Std.Iter.all.{w} {α β : Type w} [Iterator α Id β] [IteratorLoop α Id Id]
  (p : β → Bool) (it : Iter β) : Bool
```

Returns `true` if the pure predicate `p` returns `true` for all element emitted by the iterator `it`.

`O(|xs|)`. Short-circuits upon encountering the first match. The elements in `it` are examined in order of iteration.

<a id="Std___Iter___allM"></a>

**def**

```text
Std.Iter.allM.{w, w'} {α β : Type w} {m : Type → Type w'} [Monad m]
  [Iterator α Id β] [IteratorLoop α Id m] (p : β → m Bool)
  (it : Iter β) : m Bool
```

Returns `true` if the monadic predicate `p` returns `true` for all element emitted by the iterator `it`.

`O(|xs|)`. Short-circuits upon encountering the first match. The elements in `it` are examined in order of iteration.

<a id="Std___Iter___find___"></a>

**def**

```text
Std.Iter.find?.{w} {α β : Type w} [Iterator α Id β]
  [IteratorLoop α Id Id] (it : Iter β) (f : β → Bool) : Option β
```

Returns the first output of the iterator for which the predicate `p` returns `true`, or `none` if no such output is found.

`O(|it|)`. Short-circuits upon encountering the first match. The elements in `it` are examined in order of iteration.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.find?` always terminates after finitely many steps.

Examples:

- `[7, 6, 5, 8, 1, 2, 6].iter.find? (· < 5) = some 1`
- `[7, 6, 5, 8, 1, 2, 6].iter.find? (· < 1) = none`

<a id="Std___Iter___findM___"></a>

**def**

```text
Std.Iter.findM?.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m]
  [Iterator α Id β] [IteratorLoop α Id m] (it : Iter β)
  (f : β → m (ULift Bool)) : m (Option β)
```

Returns the first output of the iterator for which the monadic predicate `p` returns `true`, or `none` if no such element is found.

`O(|it|)`. Short-circuits when `f` returns `true`. The outputs of `it` are examined in order of iteration.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.findM?` always terminates after finitely many steps.

Example:

```text
#eval [7, 6, 5, 8, 1, 2, 6].iter.findM? fun i => do
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

<a id="Std___Iter___findSome___"></a>

**def**

```text
Std.Iter.findSome?.{w, x} {α β : Type w} {γ : Type x} [Iterator α Id β]
  [IteratorLoop α Id Id] (it : Iter β) (f : β → Option γ) : Option γ
```

Returns the first non-`none` result of applying `f` to each output of the iterator, in order. Returns `none` if `f` returns `none` for all outputs.

`O(|it|)`. Short-circuits when `f` returns `some _`.The outputs of `it` are examined in order of iteration.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.findSome?` always terminates after finitely many steps.

Examples:

- `[7, 6, 5, 8, 1, 2, 6].iter.findSome? (fun x => if x < 5 then some (10 * x) else none) = some 10`
- `[7, 6, 5, 8, 1, 2, 6].iter.findSome? (fun x => if x < 1 then some (10 * x) else none) = none`

<a id="Std___Iter___findSomeM___"></a>

**def**

```text
Std.Iter.findSomeM?.{w, x, w'} {α β : Type w} {γ : Type x}
  {m : Type x → Type w'} [Monad m] [Iterator α Id β]
  [IteratorLoop α Id m] (it : Iter β) (f : β → m (Option γ)) :
  m (Option γ)
```

Returns the first non-`none` result of applying the monadic function `f` to each output of the iterator, in order. Returns `none` if `f` returns `none` for all outputs.

`O(|it|)`. Short-circuits when `f` returns `some _`. The outputs of `it` are examined in order of iteration.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.findSomeM?` always terminates after finitely many steps.

Example:

```proofscript
#eval [7, 6, 5, 8, 1, 2, 6].iter.findSomeM? fun i => do
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

<a id="Std___Iter___atIdx___"></a>

**def**

```text
Std.Iter.atIdx?.{u_1} {α β : Type u_1} [Iterator α Id β]
  [IteratorAccess α Id] (n : Nat) (it : Iter β) : Option β
```

Returns the `n`-th value emitted by `it`, or `none` if `it` terminates earlier.

For monadic iterators, the monadic effects of this operation may differ from manually iterating to the `n`-th value because `atIdx?` can take shortcuts. By the signature, the return value is guaranteed to plausible in the sense of `IterM.IsPlausibleNthOutputStep`.

This function is only available for iterators that explicitly support it by implementing the `IteratorAccess` typeclass.

<a id="Std___Iter___atIdxSlow___"></a>

**def**

```text
Std.Iter.atIdxSlow?.{u_1} {α β : Type u_1} [Iterator α Id β] (n : Nat)
  (it : Iter β) : Option β
```

If possible, takes `n` steps with the iterator `it` and returns the `n`-th emitted value, or `none` if `it` finished before emitting `n` values.

If the iterator is not productive, this function might run forever in an endless loop of iterator steps. The variant `it.ensureTermination.atIdxSlow?` is guaranteed to terminate after finitely many steps.

<a id="The-Lean-Language-Reference--Iterators--Consuming-Iterators--Consuming-Monadic-Iterators"></a>
### 22.3.3. Consuming Monadic Iterators

<a id="Std___IterM___drain"></a>

**def**

```text
Std.IterM.drain.{w, w'} {α : Type w} {m : Type w → Type w'} [Monad m]
  {β : Type w} [Iterator α m β] (it : IterM m β) [IteratorLoop α m m] :
  m PUnit
```

Iterates over the whole iterator, applying the monadic effects of each step, discarding all emitted values.

<a id="Std___IterM___fold"></a>

**def**

```text
Std.IterM.fold.{w, w'} {m : Type w → Type w'} {α β γ : Type w} [Monad m]
  [Iterator α m β] [IteratorLoop α m m] (f : γ → β → γ) (init : γ)
  (it : IterM m β) : m γ
```

Folds a function over an iterator from the left, accumulating a value starting with `init`. The accumulated value is combined with the each element of the list in order, using `f`.

It is equivalent to `it.toList.foldl`.

<a id="Std___IterM___foldM"></a>

**def**

```text
Std.IterM.foldM.{w, w', w''} {m : Type w → Type w'}
  {n : Type w → Type w''} [Monad n] {α β γ : Type w} [Iterator α m β]
  [IteratorLoop α m n] [MonadLiftT m n] (f : γ → β → n γ) (init : γ)
  (it : IterM m β) : n γ
```

Folds a monadic function over an iterator from the left, accumulating a value starting with `init`. The accumulated value is combined with the each element of the list in order, using `f`.

The monadic effects of `f` are interleaved with potential effects caused by the iterator's step function. Therefore, it may *not* be equivalent to `(← it.toList).foldlM`.

<a id="Std___IterM___length"></a>

**def**

```text
Std.IterM.length.{w, w'} {α : Type w} {m : Type w → Type w'}
  {β : Type w} [Iterator α m β] [IteratorLoop α m m] [Monad m]
  (it : IterM m β) : m (ULift Nat)
```

Steps through the whole iterator, counting the number of outputs emitted.

**Performance**:

This function's runtime is linear in the number of steps taken by the iterator.

<a id="Std___IterM___any"></a>

**def**

```text
Std.IterM.any.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m]
  [Iterator α m β] [IteratorLoop α m m] (p : β → Bool)
  (it : IterM m β) : m (ULift Bool)
```

Returns `ULift.up true` if the pure predicate `p` returns `true` for any element emitted by the iterator `it`.

`O(|it|)`. Short-circuits upon encountering the first match. The outputs of `it` are examined in order of iteration.

<a id="Std___IterM___anyM"></a>

**def**

```text
Std.IterM.anyM.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m]
  [Iterator α m β] [IteratorLoop α m m] (p : β → m (ULift Bool))
  (it : IterM m β) : m (ULift Bool)
```

Returns `ULift.up true` if the monadic predicate `p` returns `ULift.up true` for any element emitted by the iterator `it`.

`O(|it|)`. Short-circuits upon encountering the first match. The outputs of `it` are examined in order of iteration.

<a id="Std___IterM___all"></a>

**def**

```text
Std.IterM.all.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m]
  [Iterator α m β] [IteratorLoop α m m] (p : β → Bool)
  (it : IterM m β) : m (ULift Bool)
```

Returns `ULift.up true` if the pure predicate `p` returns `true` for all elements emitted by the iterator `it`.

`O(|it|)`. Short-circuits upon encountering the first mismatch. The outputs of `it` are examined in order of iteration.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.toListRev` always terminates after finitely many steps.

<a id="Std___IterM___allM"></a>

**def**

```text
Std.IterM.allM.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m]
  [Iterator α m β] [IteratorLoop α m m] (p : β → m (ULift Bool))
  (it : IterM m β) : m (ULift Bool)
```

Returns `ULift.up true` if the monadic predicate `p` returns `ULift.up true` for all elements emitted by the iterator `it`.

`O(|it|)`. Short-circuits upon encountering the first mismatch. The outputs of `it` are examined in order of iteration.

<a id="Std___IterM___find___"></a>

**def**

```text
Std.IterM.find?.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m]
  [Iterator α m β] [IteratorLoop α m m] (it : IterM m β)
  (f : β → Bool) : m (Option β)
```

Returns the first output of the iterator for which the predicate `p` returns `true`, or `none` if no such output is found.

`O(|it|)`. Short-circuits upon encountering the first match. The elements in `it` are examined in order of iteration.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.find?` always terminates after finitely many steps.

Examples:

- `([7, 6, 5, 8, 1, 2, 6].iterM Id).find? (· < 5) = pure (some 1)`
- `([7, 6, 5, 8, 1, 2, 6].iterM Id).find? (· < 1) = pure none`

<a id="Std___IterM___findM___"></a>

**def**

```text
Std.IterM.findM?.{w, w'} {α β : Type w} {m : Type w → Type w'} [Monad m]
  [Iterator α m β] [IteratorLoop α m m] (it : IterM m β)
  (f : β → m (ULift Bool)) : m (Option β)
```

Returns the first output of the iterator for which the monadic predicate `p` returns `true`, or `none` if no such element is found.

`O(|it|)`. Short-circuits when `f` returns `true`. The outputs of `it` are examined in order of iteration.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.findM?` always terminates after finitely many steps.

Example:

```text
#eval ([7, 6, 5, 8, 1, 2, 6].iterM IO).findM? fun i => do
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

<a id="Std___IterM___findSome___"></a>

**def**

```text
Std.IterM.findSome?.{w, w'} {α β γ : Type w} {m : Type w → Type w'}
  [Monad m] [Iterator α m β] [IteratorLoop α m m] (it : IterM m β)
  (f : β → Option γ) : m (Option γ)
```

Returns the first non-`none` result of applying `f` to each output of the iterator, in order. Returns `none` if `f` returns `none` for all outputs.

`O(|it|)`. Short-circuits when `f` returns `some _`.The outputs of `it` are examined in order of iteration.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.findSome?` always terminates after finitely many steps.

Examples:

- `([7, 6, 5, 8, 1, 2, 6].iterM Id).findSome? (fun x => if x < 5 then some (10 * x) else none) = pure (some 10)`
- `([7, 6, 5, 8, 1, 2, 6].iterM Id).findSome? (fun x => if x < 1 then some (10 * x) else none) = pure none`

<a id="Std___IterM___findSomeM___"></a>

**def**

```text
Std.IterM.findSomeM?.{w, w'} {α β γ : Type w} {m : Type w → Type w'}
  [Monad m] [Iterator α m β] [IteratorLoop α m m] (it : IterM m β)
  (f : β → m (Option γ)) : m (Option γ)
```

Returns the first non-`none` result of applying the monadic function `f` to each output of the iterator, in order. Returns `none` if `f` returns `none` for all outputs.

`O(|it|)`. Short-circuits when `f` returns `some _`. The outputs of `it` are examined in order of iteration.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.findSomeM?` always terminates after finitely many steps.

Example:

```proofscript
#eval ([7, 6, 5, 8, 1, 2, 6].iterM IO).findSomeM? fun i => do
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

<a id="Std___IterM___atIdx___"></a>

**def**

```text
Std.IterM.atIdx?.{u_1, u_2} {α : Type u_1} {m : Type u_1 → Type u_2}
  {β : Type u_1} [Iterator α m β] [IteratorAccess α m] [Monad m]
  (it : IterM m β) (n : Nat) : m (Option β)
```

Returns the `n`-th value emitted by `it`, or `none` if `it` terminates earlier.

For monadic iterators, the monadic effects of this operation may differ from manually iterating to the `n`-th value because `atIdx?` can take shortcuts. By the signature, the return value is guaranteed to plausible in the sense of `IterM.IsPlausibleNthOutputStep`.

This function is only available for iterators that explicitly support it by implementing the `IteratorAccess` typeclass.

<a id="The-Lean-Language-Reference--Iterators--Consuming-Iterators--Collectors"></a>
### 22.3.4. Collectors

Collectors consume an iterator, returning all of its data in a list or array. To be collected, an iterator must be finite.

<a id="Std___Iter___toArray"></a>

**def**

```text
Std.Iter.toArray.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) :
  Array β
```

Traverses the given iterator and stores the emitted values in an array.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.toArray` always terminates after finitely many steps.

<a id="Std___IterM___toArray"></a>

**def**

```text
Std.IterM.toArray.{w, w'} {α β : Type w} {m : Type w → Type w'}
  [Monad m] [Iterator α m β] (it : IterM m β) : m (Array β)
```

Traverses the given iterator and stores the emitted values in an array.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.toArray` always terminates after finitely many steps.

<a id="Std___Iter___toList"></a>

**def**

```text
Std.Iter.toList.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) :
  List β
```

Traverses the given iterator and stores the emitted values in a list. Because lists are prepend-only, `toListRev` is usually more efficient that `toList`.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.toList` always terminates after finitely many steps.

<a id="Std___IterM___toList"></a>

**def**

```text
Std.IterM.toList.{w, w'} {α : Type w} {m : Type w → Type w'} [Monad m]
  {β : Type w} [Iterator α m β] (it : IterM m β) : m (List β)
```

Traverses the given iterator and stores the emitted values in a list. Because lists are prepend-only, `toListRev` is usually more efficient that `toList`.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.toList` always terminates after finitely many steps.

<a id="Std___Iter___toListRev"></a>

**def**

```text
Std.Iter.toListRev.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) :
  List β
```

Traverses the given iterator and stores the emitted values in reverse order in a list. Because lists are prepend-only, this `toListRev` is usually more efficient that `toList`.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.toListRev` always terminates after finitely many steps.

<a id="Std___IterM___toListRev"></a>

**def**

```text
Std.IterM.toListRev.{w, w'} {α : Type w} {m : Type w → Type w'}
  [Monad m] {β : Type w} [Iterator α m β] (it : IterM m β) : m (List β)
```

Traverses the given iterator and stores the emitted values in reverse order in a list. Because lists are prepend-only, this `toListRev` is usually more efficient that `toList`.

If the iterator is not finite, this function might run forever. The variant `it.ensureTermination.toListRev` always terminates after finitely many steps.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
10!
9!
8!
7!
6!
5!
4!
3!
2!
1!
```


### Display 2


```text
failed to synthesize instance of type class
  Finite (Rxi.Iterator Nat) Id

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 3


```text
5!
4!
3!
2!
1!
Blastoff!
```


### Display 4


```text
some 10Almost! 6
Almost! 5
```

