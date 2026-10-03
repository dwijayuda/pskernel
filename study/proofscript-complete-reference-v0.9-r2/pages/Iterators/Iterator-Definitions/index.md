<a id="The-Lean-Language-Reference--Iterators--Iterator-Definitions"></a>

# ProofScript — 22.2. Iterator Definitions

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Iterator definitions describe state and stepping; consumers observe a sequence through the permitted interfaces. Combinators such as mapping and filtering transform that process without automatically inheriting termination, productivity, effect or allocation guarantees. Preserve the distinction between finite consumers and potentially unbounded iteration. Iterator proofs belong to the native abstraction and its law dependencies.

**Compiler and coverage boundary.** Version the iterator library and its instances. A foreign async stream additionally needs backpressure, cancellation and lifetime contracts; it is not an ordinary iterator by spelling alone.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Iterators/Iterator-Definitions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Iterators/Iterator-Definitions/index.html). Source Git blob: `328bd9a3b7936400c689e07e476633af45df404b`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 22.2. Iterator Definitions

Iterators may be either monadic or pure, and they may be finite, productive, or potentially infinite. 
<a id="--tech-term-Monadic"></a>
*Monadic* iterators use side effects in some [monad](../../Functors___-Monads-and--do--Notation/index.md#--tech-term-Monad) to emit each value, and must therefore be used in the monad, while 
<a id="--tech-term-pure"></a>
*pure* iterators do not require side effects. For example, iterating over all files in a directory requires the `IO` monad. Pure iterators have type `Iter`, while monadic iterators are represented by `IterM`.

<a id="Std___Iter___mk"></a>

**structure**

```text
Std.Iter.{w} {α : Type w} (β : Type w) : Type w
```

An iterator that sequentially emits values of type `β`. It may be finite or infinite.

See the root module `Std.Data.Iterators` for a more comprehensive overview over the iterator framework.

See `Std.Data.Iterators.Producers` for ways to iterate over common data structures. By convention, the monadic iterator associated with an object can be obtained via dot notation. For example, `List.iterM IO` creates an iterator over a list in the monad `IO`.

See `Init.Data.Iterators.Consumers` for ways to use an iterator. For example, `it.toList` will convert an iterator `it` into a list and `it.ensureTermination.toList` guarantees that this operation will terminate, given a proof that the iterator is finite. It is also always possible to manually iterate using `it.step`, relying on the termination measures `it.finitelyManySteps` and `it.finitelyManySkips`.

See `IterM` for iterators that operate in a monad.

Internally, `Iter β` wraps an element of type `α` containing state information. The type `α` determines the implementation of the iterator using a typeclass mechanism. The concrete typeclass implementing the iterator is `Iterator α m β`.

When using combinators, `α` can become very complicated. It is an implicit parameter of `α` so that the pretty printer will not print this large type by default. If a declaration returns an iterator, the following will not work:

```text
def x : Iter Nat := [1, 2, 3].iter
```

Instead the declaration type needs to be completely omitted:

```text
def x := [1, 2, 3].iter

-- if you want to ensure that `x` is an iterator emitting `Nat`
def x := ([1, 2, 3].iter : Iter Nat)
```

**Constructor**

```text
Std.Iter.mk.{w}
```

**Fields**

```text
internalState : α
```

Internal implementation detail of the iterator.

<a id="Std___IterM___mk"></a>

**structure**

```text
Std.IterM.{w, w'} {α : Type w} (m : Type w → Type w') (β : Type w) :
  Type w
```

An iterator that sequentially emits values of type `β` in the monad `m`. It may be finite or infinite.

See the root module `Std.Data.Iterators` for a more comprehensive overview over the iterator framework.

See `Std.Data.Iterators.Producers` for ways to iterate over common data structures. By convention, the monadic iterator associated with an object can be obtained via dot notation. For example, `List.iterM IO` creates an iterator over a list in the monad `IO`.

See `Init.Data.Iterators.Consumers` for ways to use an iterator. For example, `it.toList` will convert an iterator `it` into a list and `it.ensureTermination.toList` guarantees that this operation will terminate, given a proof that the iterator is finite. It is also always possible to manually iterate using `it.step`, relying on the termination measures `it.finitelyManySteps` and `it.finitelyManySkips`.

See `Iter` for a more convenient interface in case that no monadic effects are needed (`m = Id`).

Internally, `IterM m β` wraps an element of type `α` containing state information. The type `α` determines the implementation of the iterator using a typeclass mechanism. The concrete typeclass implementing the iterator is `Iterator α m β`.

When using combinators, `α` can become very complicated. It is an implicit parameter of `α` so that the pretty printer will not print this large type by default. If a declaration returns an iterator, the following will not work:

```text
def x : IterM IO Nat := [1, 2, 3].iterM IO
```

Instead the declaration type needs to be completely omitted:

```text
def x := [1, 2, 3].iterM IO

-- if you want to ensure that `x` is an iterator in `IO` emitting `Nat`
def x := ([1, 2, 3].iterM IO : IterM IO Nat)
```

**Constructor**

```text
Std.IterM.mk.{w, w'}
```

Wraps the state of an iterator into an `Iter` object.

**Fields**

```text
internalState : α
```

Internal implementation detail of the iterator.

The types `Iter` and `IterM` are merely wrappers around an internal state. This inner state type is the implicit parameter to the iterator types. For basic producer iterators, like the one that results from `List.iter`, this type is fairly simple; however, iterators that result from [combinators](../index.md#--tech-term-Combinators) use polymorphic state types that can grow large. Because Lean elaborates the specified return type of a function before elaborating its body, it may not be possible to automatically determine the internal state type of an iterator type returned by a function. In these cases, it can be helpful to omit the return type from the signature and instead place a type annotation on the definition's body, which allows the specific iterator combinators invoked from the body to be used to determine the state type.

<a id="Iterator-State-Types"></a>
Iterator State Types 

Writing the internal state type explicitly for list and array iterators is feasible:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="reds-_LPAR_in-Iterator-State-Types_RPAR_"></a>


```proofscript
const reds := ["red", "crimson"]

example : @Iter (ListIterator String) String := reds.iter

example : @Iter (ArrayIterator String) String := reds.toArray.iter
```

However, the internal state type of a use of the `Iter.map` combinator is quite complicated:

```proofscript
example :
    @Iter
      (Map (ListIterator String) Id Id @id fun x : String =>
        pure x.length)
      Nat :=
  reds.iter.map String.length
```

Omitting the state type leads to an error:

```proofscript
example : Iter Nat := reds.iter.map String.length
```

```lean
don't know how to synthesize implicit argument `α`
  @Iter ?m.1 Nat
context:
⊢ Type

Note: Because this declaration's type has been explicitly provided, all parameter types and holes (e.g., `_`) in its header are resolved before its body is processed; information from the declaration body cannot be used to infer what these values should be
```

Rather than writing the state type by hand, it can be convenient to omit the return type and instead provide the annotation around the term:

```proofscript
example := (reds.iter.map String.length : Iter Nat)

example :=
  show Iter Nat from
  reds.iter.map String.length
```

The actual process of iteration consists of producing a sequence of iteration steps when requested. Each step returns an updated iterator with a new internal state along with either a data value (in `IterStep.yield`), an indicator that the caller should request a data value again (`IterStep.skip`), or an indication that iteration is finished (`IterStep.done`). Without the ability to `skip`, it would be much more difficult to work with iterator combinators such as `Iter.filter` that do not yield values for all of those yielded by the underlying iterator. With `skip`, the implementation of `filter` doesn't need to worry about whether the underlying iterator is [finite](index.md#--tech-term-Finite) in order to be a well-defined function, and reasoning about its finiteness can be carried out in separate proofs. Additionally, `filter` would require an inner loop, which is much more difficult for the compiler to inline.

<a id="Std___IterStep___yield"></a>

**inductive type**

```text
Std.IterStep.{u_1, u_2} (α : Sort u_1) (β : Sort u_2) :
  Sort (max (max 1 u_1) u_2)
```

`IterStep α β` represents a step taken by an iterator (`Iter β` or `IterM m β`).

**Constructors**

```text
Std.IterStep.yield.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  (it : α) (out : β) : IterStep α β
```

`IterStep.yield it out` describes the situation that an iterator emits `out` and provides `it` as the succeeding iterator.

```text
Std.IterStep.skip.{u_1, u_2} {α : Sort u_1} {β : Sort u_2}
  (it : α) : IterStep α β
```

`IterStep.skip it` describes the situation that an iterator does not emit anything in this iteration and provides `it'` as the succeeding iterator.

Allowing `skip` steps is necessary to generate efficient code from a loop over an iterator.

```text
Std.IterStep.done.{u_1, u_2} {α : Sort u_1} {β : Sort u_2} :
  IterStep α β
```

`IterStep.done` describes the situation that an iterator has finished and will neither emit more values nor cause any monadic effects. In this case, no succeeding iterator is provided.

Steps taken by `Iter` and `IterM` are respectively represented by the types `Iter.Step` and `IterM.Step`. Both types of step are wrappers around `IterStep` that include [additional proofs](index.md#iterator-plausibility) that are used to track termination behavior.

<a id="Std___Iter___Step"></a>

**def**

```text
Std.Iter.Step.{w} {α β : Type w} [Iterator α Id β] (it : Iter β) :
  Type w
```

The type of the step object returned by `Iter.step`, containing an `IterStep` and a proof that this is a plausible step for the given iterator.

<a id="Std___IterM___Step"></a>

**def**

```text
Std.IterM.Step.{w, w'} {α : Type w} {m : Type w → Type w'} {β : Type w}
  [Iterator α m β] (it : IterM m β) : Type w
```

The type of the step object returned by `IterM.step`, containing an `IterStep` and a proof that this is a plausible step for the given iterator.

Steps are produced from iterators using `Iterator.step`, which is a method of the `Iterator` type class. `Iterator` is used for both pure and monadic iterators; pure iterators can be completely polymorphic in the choice of monad, which allows callers to instantiate it with `Id`.

<a id="Std___Iterator___mk"></a>

**type class**

```text
Std.Iterator.{w, w'} (α : Type w) (m : Type w → Type w')
  (β : outParam (Type w)) : Type (max w w')
```

The step function of an iterator in `Iter (α := α) β` or `IterM (α := α) m β`.

In order to allow intrinsic termination proofs when iterating with the `step` function, the step object is bundled with a proof that it is a "plausible" step for the given current iterator.

**Instance Constructor**

```text
Std.Iterator.mk.{w, w'}
```

**Methods**

```text
IsPlausibleStep : IterM m β → IterStep (IterM m β) β → Prop
```

A relation that governs the allowed steps from a given iterator.

The "plausible" steps are those which make sense for a given state; plausibility can ensure properties such as the successor iterator being drawn from the same collection, that an iterator resulting from a skip will return the same next value, or that the next item yielded is next one in the original collection.

```text
step : (it : IterM m β) → m (Std.Shrink (PlausibleIterStep (Iterator.IsPlausibleStep it)))
```

Carries out a step of iteration.

<a id="iterator-plausibility"></a>
### 22.2.1. Plausibility

In addition to the step function, instances of `Iterator` include a relation `Iterator.IsPlausibleStep`. This relation exists because most iterators both maintain invariants over their internal state and yield values in a predictable manner. For example, array iterators track both an array and a current index into it. Stepping an array iterator results in an iterator over the same underlying array; it yields a value when the index is small enough, or is done otherwise. The 
<a id="--tech-term-plausible-steps"></a>
*plausible steps* from an iterator state are those which are related to it via the iterator's implementation of `IsPlausibleStep`. Tracking plausibility at the logical level makes it feasible to reason about termination behavior for monadic iterators.

Both `Iter.Step` and `IterM.Step` are defined in terms of `PlausibleIterStep`; thus, both types can be used with [leading dot notation](../../Terms/Identifiers/index.md#--tech-term-leading-dot-notation) for its namespace. An `Iter.Step` or `IterM.Step` can be analyzed using the three [match pattern functions](../../Terms/Pattern-Matching/index.md#match_pattern-functions) `PlausibleIterStep.yield`, `PlausibleIterStep.skip`, and `PlausibleIterStep.done`. These functions pair the information in the underlying `IterStep` with the surrounding proof object.

<a id="Std___PlausibleIterStep"></a>

**def**

```text
Std.PlausibleIterStep.{u, w} {α : Type u} {β : Type w}
  (IsPlausibleStep : IterStep α β → Prop) : Type (max 0 u w)
```

A variant of `IterStep` that bundles the step together with a proof that it is "plausible". The plausibility predicate will later be chosen to assert that a state is a plausible successor of another state. Having this proof bundled up with the step is important for termination proofs.

See `IterM.Step` and `Iter.Step` for the concrete choice of the plausibility predicate.

<a id="Std___PlausibleIterStep___yield"></a>

**def**

```text
Std.PlausibleIterStep.yield.{u, w} {α : Type u} {β : Type w}
  {IsPlausibleStep : IterStep α β → Prop} (it' : α) (out : β)
  (h : IsPlausibleStep (IterStep.yield it' out)) :
  PlausibleIterStep IsPlausibleStep
```

Match pattern for the `yield` case. See also `IterStep.yield`.

<a id="Std___PlausibleIterStep___skip"></a>

**def**

```text
Std.PlausibleIterStep.skip.{u, w} {α : Type u} {β : Type w}
  {IsPlausibleStep : IterStep α β → Prop} (it' : α)
  (h : IsPlausibleStep (IterStep.skip it')) :
  PlausibleIterStep IsPlausibleStep
```

Match pattern for the `skip` case. See also `IterStep.skip`.

<a id="Std___PlausibleIterStep___done"></a>

**def**

```text
Std.PlausibleIterStep.done.{u, w} {α : Type u} {β : Type w}
  {IsPlausibleStep : IterStep α β → Prop}
  (h : IsPlausibleStep IterStep.done) :
  PlausibleIterStep IsPlausibleStep
```

Match pattern for the `done` case. See also `IterStep.done`.

<a id="The-Lean-Language-Reference--Iterators--Iterator-Definitions--Finite-and-Productive-Iterators"></a>
### 22.2.2. Finite and Productive Iterators

Not all iterators are guaranteed to return a finite number of results; it is perfectly sensible to iterate over all of the natural numbers. Similarly, not all iterators are guaranteed to either return a single result or terminate; iterators may be defined using arbitrary programs. Thus, Lean divides iterators into three termination classes:

- <a id="--tech-term-Finite"></a>
  *Finite* iterators are guaranteed to finish iterating after a finite number of steps. These iterators have a `Finite` instance.
- <a id="--tech-term-Productive"></a>
  *Productive* iterators are guaranteed to yield a value or terminate in finitely many steps, but they may yield infinitely many values. These iterators have a `Productive` instance.
- All other iterators, whose termination behavior is unknown. These iterators have neither instance.

All finite iterators are necessarily productive.

<a id="Std___Iterators___Finite___mk"></a>

**type class**

```text
Std.Iterators.Finite.{w, w'} (α : Type w) (m : Type w → Type w')
  {β : Type w} [Iterator α m β] : Prop
```

`Finite α m` asserts that `IterM (α := α) m` terminates after finitely many steps. Technically, this means that the relation of plausible successors is well-founded. Given this typeclass, termination proofs for well-founded recursion over an iterator `it` can use `it.finitelyManySteps` as a termination measure.

**Instance Constructor**

```text
Std.Iterators.Finite.mk.{w, w'}
```

**Methods**

```text
wf : WellFounded IterM.IsPlausibleSuccessorOf
```

The relation of plausible successors is well-founded.

<a id="Std___Iterators___Productive___mk"></a>

**type class**

```text
Std.Iterators.Productive.{u_1, u_2} (α : Type u_1)
  (m : Type u_1 → Type u_2) {β : Type u_1} [Iterator α m β] : Prop
```

`Productive α m` asserts that `IterM (α := α) m` terminates or emits a value after finitely many skips. Technically, this means that the relation of plausible successors during skips is well-founded. Given this typeclass, termination proofs for well-founded recursion over an iterator `it` can use `it.finitelyManySkips` as a termination measure.

**Instance Constructor**

```text
Std.Iterators.Productive.mk.{u_1, u_2}
```

**Methods**

```text
wf : WellFounded IterM.IsPlausibleSkipSuccessorOf
```

The relation of plausible successors during skips is well-founded.

Lean's standard library provides many functions that iterate over an iterator. These consumer functions usually do not make any assumptions about the underlying iterator. In particular, such functions may run forever for certain iterators.

Sometimes, it is of utmost importance that a function does terminate. For these cases, the combinator `Iter.ensureTermination` results in an iterator that provides variants of consumers that are guaranteed to terminate. They usually require proof that the involved iterator is finite.

<a id="Std___Iter___ensureTermination"></a>

**def**

```text
Std.Iter.ensureTermination.{w} {α β : Type w} (it : Iter β) :
  Iter.Total β
```

For an iterator `it`, `it.ensureTermination` provides variants of consumers that always terminate.

<a id="Std___IterM___ensureTermination"></a>

**def**

```text
Std.IterM.ensureTermination.{w, w'} {α β : Type w}
  {m : Type w → Type w'} (it : IterM m β) : IterM.Total m β
```

For an iterator `it`, `it.ensureTermination` provides variants of consumers that always terminate.

<a id="Iterating-Over--Nat"></a>
Iterating Over `Nat`  

To write an iterator that yields each natural number in turn, the first step is to implement its internal state. This iterator only needs to remember the next natural number:
<a id="Nats-_LPAR_in-Iterating-Over--Nat_RPAR_"></a>
<a id="Nats___next-_LPAR_in-Iterating-Over--Nat_RPAR_"></a>


```proofscript
structure Nats where
  next : Nat
```

This iterator will only ever yield the next natural number. Thus, its step function will never return `skip` or `done`. Whenever it yields a value, the value will be the internal state's `next` field, and the successor iterator's `next` field will be one greater. The `grind` tactic suffices to show that the step is indeed plausible:

```proofscript
instance [Pure m] : Iterator Nats m Nat where
  IsPlausibleStep it
    | .yield it' n =>
      n = it.internalState.next ∧
      it'.internalState.next = n + 1
    | _ => False
  step it :=
    let n := it.internalState.next
    pure <| .deflate <|
      .yield { it with internalState.next := n + 1 } n (by grind)
```

Whenever an iterator is defined, an `IteratorLoop` instance should be provided. They are required for most consumers of iterators such as `Iter.toList` or the `for` loops. One can use their default implementations as follows:

```proofscript
instance [Pure m] [Monad n] : IteratorLoop Nats m n :=
  .defaultImplementation
```

This `step` function is productive because it never returns `skip`. Thus, the proof that each chain of `skip`s has finite length can rely on the fact that when `it` is a `Nats` iterator, `Iterator.IsPlausibleStep it (.skip it') = False`:

```proofscript
instance [Pure m] : Productive Nats m where
  wf := .intro <| fun _ => .intro _ nofun
```

Because there are infinitely many `Nat`s, the iterator is not finite.

A `Nats` iterator can be created using this function:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Nats___iter-_LPAR_in-Iterating-Over--Nat_RPAR_"></a>


```proofscript
const Nats.iter : Iter (α := Nats) Nat :=
  IterM.mk { next := 0 } |>.toIter
```

One can print all natural numbers by running the following function:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="f-_LPAR_in-Iterating-Over--Nat_RPAR_"></a>


```proofscript
const f : IO Unit := do
  for x in Nats.iter do
    IO.println s!"{x}"
```

This function never terminates, printing all natural numbers in increasing order, one after another.

This iterator is most useful with combinators such as `Iter.zip`:

```proofscript
#eval show IO Unit from do
  let xs : List String := ["cat", "dog", "pachycephalosaurus"]
  for (x, y) in Nats.iter.zip xs.iter do
    IO.println s!"{x}: {y}"
```

```lean
0: cat
1: dog
2: pachycephalosaurus
```

In contrast to the previous example, this loop terminates because `xs.iter` is a finite iterator, One can make sure that a loop actually terminates by providing a `Finite` instance:

```proofscript
#check type_of% (Nats.iter.zip ["cat", "dog"].iter).internalState

#synth Finite (Zip Nats Id (ListIterator String) String) Id
```

```lean
Zip Nats Id (ListIterator String) String : Type
```

```lean
Zip.instFinite₂
```

In contrast, `Nats.iter` has no `Finite` instance because it yields infinitely many values:

```proofscript
#synth Finite Nats Id
```

```lean
failed to synthesize
  Finite Nats Id

Hint: Additional diagnostic information may be available using the `set_option diagnostics true` command.
```

Because there are infinitely many `Nat`s, using `Iter.ensureTermination` results in an error:

```proofscript
#eval show IO Unit from do
  for x in Nats.iter.ensureTermination do
    IO.println s!"{x}"
```

```lean
failed to synthesize instance of type class
  ForIn IO (Iter.Total Nat) ?α

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

<a id="Iterating-Over-Triples"></a>
Iterating Over Triples 

The type `Triple` contains three values of the same type:
<a id="Triple-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="Triple___fst-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="Triple___snd-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="Triple___thd-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>


```proofscript
structure Triple α where
  fst : α
  snd : α
  thd : α
```

The internal state of an iterator over `Triple` can consist of a triple paired with a current position. This position may either be one of the fields or an indication that iteration is finished.
<a id="TriplePos-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TriplePos___fst-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TriplePos___snd-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TriplePos___thd-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TriplePos___done-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>


```proofscript
inductive TriplePos where
  | fst | snd | thd | done
```

Positions can be used to look up elements:
<a id="Triple___get___-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>


```proofscript
def Triple.get? (xs : Triple α) (pos : TriplePos) : Option α :=
  match pos with
  | .fst => some xs.fst
  | .snd => some xs.snd
  | .thd => some xs.thd
  | _ => none
```

Each field's position has a successor position:
<a id="TriplePos___Succ-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TriplePos___Succ___fst-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TriplePos___Succ___snd-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TriplePos___Succ___thd-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>


```proofscript
@[grind, grind cases]
inductive TriplePos.Succ : TriplePos → TriplePos → Prop where
  | fst : Succ .fst .snd
  | snd : Succ .snd .thd
  | thd : Succ .thd .done
```

The iterator itself pairs a triple with the position of the next element:
<a id="TripleIterator-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TripleIterator___triple-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TripleIterator___pos-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>


```proofscript
structure TripleIterator α where
  triple : Triple α
  pos : TriplePos
```

Iteration begins at `fst`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Triple___iter-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>


```proofscript
function Triple.iter (xs : Triple α) : Iter (α := TripleIterator α) α :=
  IterM.mk {triple := xs, pos := .fst : TripleIterator α} |>.toIter
```

There are two plausible steps: either the iterator's position has a successor, in which case the next iterator is one that points at the same triple with the successor position, or it does not, in which case iteration is complete.
<a id="TripleIterator___IsPlausibleStep-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TripleIterator___IsPlausibleStep___yield-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="TripleIterator___IsPlausibleStep___done-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>


```proofscript
@[grind]
inductive TripleIterator.IsPlausibleStep :
    @IterM (TripleIterator α) m α →
    IterStep (@IterM (TripleIterator α) m α) α →
    Prop where
  | yield :
    it.internalState.triple = it'.internalState.triple →
    it.internalState.pos.Succ it'.internalState.pos →
    it.internalState.triple.get? it.internalState.pos = some out →
    IsPlausibleStep it (.yield it' out)
  | done :
    it.internalState.pos = .done →
    IsPlausibleStep it .done
```

The corresponding step function yields the iterator and value describe by the relation:

```proofscript
instance [Pure m] : Iterator (TripleIterator α) m α where
  IsPlausibleStep := TripleIterator.IsPlausibleStep
  step
    | ⟨xs, pos⟩ =>
      pure <| .deflate <|
      match pos with
      | .fst => .yield ⟨xs, .snd⟩ xs.fst ?_
      | .snd => .yield ⟨xs, .thd⟩ xs.snd ?_
      | .thd => .yield ⟨xs, .done⟩ xs.thd ?_
      | .done => .done <| ?_
where finally
  all_goals grind [Triple.get?]
```

This iterator can now be converted to an array:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="abc-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>


```proofscript
const abc : Triple Char := ⟨'a', 'b', 'c'⟩
```

```proofscript
#eval abc.iter.toArray
```

```lean
#['a', 'b', 'c']
```

In general, `Iter.toArray` might run forever. One can prove that `abc` is finite, and the above example will terminate after finitely many steps, by constructing a `Finite (Triple Char) Id` instance. It's easiest to start at `TriplePos.done` and work backwards toward `TriplePos.fst`, showing that each position in turn has a finite chain of successors:
<a id="acc_done-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="acc_thd-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="acc_snd-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>
<a id="acc_fst-_LPAR_in-Iterating-Over-Triples_RPAR_"></a>


```proofscript
@[grind! .]
theorem acc_done [Pure m] :
    Acc (IterM.IsPlausibleSuccessorOf (m := m))
      ⟨{ triple, pos := .done : TripleIterator α}⟩ :=
  Acc.intro _ fun
    | _, ⟨_, ⟨_, h⟩⟩ => by
      cases h <;> grind [IterStep.successor_done]

@[grind! .]
theorem acc_thd [Pure m] :
    Acc (IterM.IsPlausibleSuccessorOf (m := m))
      ⟨{ triple, pos := .thd : TripleIterator α}⟩ :=
  Acc.intro _ fun
    | ⟨{ triple, pos }⟩, ⟨h, h', h''⟩ => by
      cases h'' <;> grind [IterStep.successor_yield]

@[grind! .]
theorem acc_snd [Pure m] :
    Acc (IterM.IsPlausibleSuccessorOf (m := m))
      ⟨{ triple, pos := .snd : TripleIterator α}⟩ :=
  Acc.intro _ fun
    | ⟨{ triple, pos }⟩, ⟨h, h', h''⟩ => by
      cases h'' <;> grind [IterStep.successor_yield]

@[grind! .]
theorem acc_fst [Pure m] :
    Acc (IterM.IsPlausibleSuccessorOf (m := m))
      ⟨{ triple, pos := .fst : TripleIterator α}⟩ :=
  Acc.intro _ fun
    | ⟨{ triple, pos }⟩, ⟨h, h', h''⟩ => by
      cases h'' <;> grind [IterStep.successor_yield]

instance [Pure m] : Finite (TripleIterator α) m where
  wf := .intro <| fun
    | { internalState := { triple, pos } } => by
      cases pos <;> grind
```

To enable the iterator in `for` loops, an instance of `IteratorLoop` are needed:

```proofscript
instance [Monad m] [Monad n] :
    IteratorLoop (TripleIterator α) m n :=
  .defaultImplementation
```

```proofscript
#eval show IO Unit from do
  for x in abc.iter do
    IO.println x
```

```lean
a
b
c
```

<a id="Iterators-and-Effects"></a>
Iterators and Effects 

One way to iterate over the contents of a file is to read a specified number of bytes from a `Stream` at each step. When EOF is reached, the iterator can close the file by letting its reference count drop to zero:
<a id="FileIterator-_LPAR_in-Iterators-and-Effects_RPAR_"></a>
<a id="FileIterator___stream___-_LPAR_in-Iterators-and-Effects_RPAR_"></a>
<a id="FileIterator___count-_LPAR_in-Iterators-and-Effects_RPAR_"></a>


```proofscript
structure FileIterator where
  stream? : Option IO.FS.Stream
  count : USize := 8192
```

An iterator can be created by opening a file and converting its handle to a stream:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="iterFile-_LPAR_in-Iterators-and-Effects_RPAR_"></a>


```proofscript
function iterFile
    (path : System.FilePath)
    (count : USize := 8192) :
    IO (IterM (α := FileIterator) IO ByteArray) := do
  let h ← IO.FS.Handle.mk path .read
  let stream? := some (IO.FS.Stream.ofHandle h)
  return IterM.mk { stream?, count }
```

For this iterator, a `yield` is plausible when the file is still open, and `done` is plausible when the file is closed. The actual step function performs a read and closes the file if no bytes were returned:

```proofscript
instance : Iterator FileIterator IO ByteArray where
  IsPlausibleStep it
    | .yield .. =>
      it.internalState.stream?.isSome
    | .skip .. => False
    | .done => it.internalState.stream?.isNone
  step it := do
    match h : it.internalState.stream? with
    | none => return .deflate <| .done (by simp [h])
    | some stream =>
      let bytes ← stream.read it.internalState.count
      let it' :=
        { it with internalState.stream? :=
          if bytes.size == 0 then none else some stream
        }
      return .deflate <| .yield it' bytes (by simp [h])
```

To use it in loops, an `IteratorLoop` instance will be necessary.

```proofscript
instance [Monad n] : IteratorLoop FileIterator IO n :=
  .defaultImplementation
```

This is enough support code to use the iterator to calculate file sizes:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="fileSize-_LPAR_in-Iterators-and-Effects_RPAR_"></a>


```proofscript
function fileSize (name : System.FilePath) : IO Nat := do
  let mut size := 0
  let f := (← iterFile name)
  for bytes in f do
    size := size + bytes.size
  return size
```

<a id="The-Lean-Language-Reference--Iterators--Iterator-Definitions--Accessing-Elements"></a>
### 22.2.3. Accessing Elements

Some iterators support efficient random access. For example, an array iterator can skip any number of elements in constant time by incrementing the index that it maintains into the array.

<a id="Std___IteratorAccess___mk"></a>

**type class**

```text
Std.IteratorAccess.{w, w'} (α : Type w) (m : Type w → Type w')
  {β : Type w} [Iterator α m β] : Type (max w w')
```

`IteratorAccess α m` provides efficient implementations for random access or iterators that support it. `it.nextAtIdx? n` either returns the step in which the `n`th value of `it` is emitted (necessarily of the form `.yield _ _`) or `.done` if `it` terminates before emitting the `n`th value.

For monadic iterators, the monadic effects of this operation may differ from manually iterating to the `n`-th value because `nextAtIdx?` can take shortcuts. By the signature, the return value is guaranteed to plausible in the sense of `IterM.IsPlausibleNthOutputStep`.

This class is experimental and users of the iterator API should not explicitly depend on it.

**Instance Constructor**

```text
Std.IteratorAccess.mk.{w, w'}
```

**Methods**

```text
nextAtIdx? : (it : IterM m β) → (n : Nat) → m (PlausibleIterStep (IterM.IsPlausibleNthOutputStep n it))
```

`nextAtIdx? it n` either returns the step in which the `n`th value of `it` is emitted (necessarily of the form `.yield _ _`) or `.done` if `it` terminates before emitting the `n`th value.

<a id="Std___IterM___nextAtIdx___"></a>

**def**

```text
Std.IterM.nextAtIdx?.{u_1, u_2} {α : Type u_1} {m : Type u_1 → Type u_2}
  {β : Type u_1} [Iterator α m β] [IteratorAccess α m] (it : IterM m β)
  (n : Nat) :
  m (PlausibleIterStep (IterM.IsPlausibleNthOutputStep n it))
```

Returns the step in which `it` yields its `n`-th element, or `.done` if it terminates earlier. In contrast to `step`, this function will always return either `.yield` or `.done` but never a `.skip` step.

For monadic iterators, the monadic effects of this operation may differ from manually iterating to the `n`-th value because `nextAtIdx?` can take shortcuts. By the signature, the return value is guaranteed to plausible in the sense of `IterM.IsPlausibleNthOutputStep`.

This function is only available for iterators that explicitly support it by implementing the `IteratorAccess` typeclass.

<a id="The-Lean-Language-Reference--Iterators--Iterator-Definitions--Loops"></a>
### 22.2.4. Loops

<a id="Std___IteratorLoop___mk"></a>

**type class**

```text
Std.IteratorLoop.{w, w', x, x'} (α : Type w) (m : Type w → Type w')
  {β : Type w} [Iterator α m β] (n : Type x → Type x') :
  Type (max (max (max (w + 1) w') (x + 1)) x')
```

`IteratorLoop α m` provides efficient implementations of loop-based consumers for `α`-based iterators. The basis is a `ForIn`-style loop construct.

Its behavior for well-founded loops is fully characterized by the `LawfulIteratorLoop` type class.

This class is experimental and users of the iterator API should not explicitly depend on it. They can, however, assume that consumers that require an instance will work for all iterators provided by the standard library.

**Instance Constructor**

```text
Std.IteratorLoop.mk.{w, w', x, x'}
```

**Methods**

```text
forIn : ((γ : Type w) → (δ : Type x) → (γ → n δ) → m γ → n δ) →
  (γ : Type x) →
    (plausible_forInStep : β → γ → ForInStep γ → Prop) →
      (it : IterM m β) →
        γ → ((b : β) → it.IsPlausibleIndirectOutput b → (c : γ) → n (Subtype (plausible_forInStep b c))) → n γ
```

Iteration over the iterator `it` in the manner expected by `for` loops.

<a id="Std___IteratorLoop___defaultImplementation"></a>

**def**

```text
Std.IteratorLoop.defaultImplementation.{w, w', x, x'} {β α : Type w}
  {m : Type w → Type w'} {n : Type x → Type x'} [Monad n]
  [Iterator α m β] : IteratorLoop α m n
```

This is the default implementation of the `IteratorLoop` class. It simply iterates through the iterator using `IterM.step`. For certain iterators, more efficient implementations are possible and should be used instead.

<a id="Std___LawfulIteratorLoop___mk"></a>

**type class**

```text
Std.LawfulIteratorLoop.{w, w', x, x'} {β : Type w} (α : Type w)
  (m : Type w → Type w') (n : Type x → Type x') [Monad m] [Monad n]
  [Iterator α m β] [i : IteratorLoop α m n] : Prop
```

Asserts that a given `IteratorLoop` instance is equal to `IteratorLoop.defaultImplementation`. (Even though equal, the given instance might be vastly more efficient.)

**Instance Constructor**

```text
Std.LawfulIteratorLoop.mk.{w, w', x, x'}
```

**Methods**

```text
lawful : ∀ (lift : (γ : Type w) → (δ : Type x) → (γ → n δ) → m γ → n δ) [Std.Internal.LawfulMonadLiftBindFunction lift]
  (γ : Type x) (it : IterM m β) (init : γ) (Pl : β → γ → ForInStep γ → Prop),
  IteratorLoop.WellFounded α m Pl →
    ∀ (f : (b : β) → it.IsPlausibleIndirectOutput b → (c : γ) → n (Subtype (Pl b c))),
      IteratorLoop.forIn lift γ Pl it init f = IteratorLoop.forIn lift γ Pl it init f
```

The implementation of `IteratorLoop.forIn` in `i` is equal to the default implementation.

<a id="The-Lean-Language-Reference--Iterators--Iterator-Definitions--Universe-Levels"></a>
### 22.2.5. Universe Levels

To make the [universe levels](../../The-Type-System/Universes/index.md#--tech-term-level) of iterators more flexible, a wrapper type `Shrink` is applied around the result of `Iterator.step`. This type is presently a placeholder. It is present to reduce the scope of the breaking change when the full implementation is available.

<a id="Std___Shrink"></a>

**def**

```text
Std.Shrink.{u} (α : Type u) : Type u
```

Currently, `Shrink α` is just a wrapper around `α`.

In the future, `Shrink` should allow shrinking `α` into a potentially smaller universe, given a proof that `α` is actually small, just like Mathlib's `Shrink`, except that the latter's conversion functions are noncomputable. Until then, `Shrink α` is always in the same universe as `α`.

This no-op type exists so that fewer breaking changes will be needed when the real `Shrink` type is available and the iterators will be made more flexible with regard to universes.

The conversion functions `Shrink.deflate` and `Shrink.inflate` form an equivalence between `α` and `Shrink α`, but this equivalence is intentionally not definitional.

<a id="Std___Shrink___inflate"></a>

**def**

```text
Std.Shrink.inflate.{u_1} {α : Type u_1} (x : Std.Shrink α) : α
```

Converts elements of `Shrink α` into elements of `α`.

<a id="Std___Shrink___deflate"></a>

**def**

```text
Std.Shrink.deflate.{u_1} {α : Type u_1} (x : α) : Std.Shrink α
```

Converts elements of `α` into elements of `Shrink α`.

<a id="The-Lean-Language-Reference--Iterators--Iterator-Definitions--Basic-Iterators"></a>
### 22.2.6. Basic Iterators

In addition to the iterators provided by collection types, there are two basic iterators that are not connected to any underlying data structure. `Iter.empty` finishes iteration immediately after yielding no data, and `Iter.repeat` yields the same element forever. These iterators are primarily useful as parts of larger iterators built with combinators.

<a id="Std___Iter___empty"></a>

**def**

```text
Std.Iter.empty.{w} (β : Type w) : Iter β
```

Returns an iterator that terminates immediately.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___IterM___empty"></a>

**def**

```text
Std.IterM.empty.{w, w'} (m : Type w → Type w') (β : Type w) : IterM m β
```

Returns an iterator that terminates immediately.

**Termination properties:**

- `Finite` instance: always
- `Productive` instance: always

<a id="Std___Iter___repeat"></a>

**def**

```text
Std.Iter.repeat.{w} {α : Type w} (f : α → α) (init : α) : Iter α
```

Creates an infinite iterator from an initial value `init` and a function `f : α → α`. First it yields `init`, and in each successive step, the iterator applies `f` to the previous value. So if the iterator just emitted `a`, in the next step it will yield `f a`. In other words, the `n`-th value is `Nat.repeat f n init`.

For example, if `f := (· + 1)` and `init := 0`, then the iterator emits all natural numbers in order.

**Termination properties:**

- `Finite` instance: not available and never possible
- `Productive` instance: always

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
don't know how to synthesize implicit argument `α`
  @Iter ?m.1 Nat
context:
⊢ Type

Note: Because this declaration's type has been explicitly provided, all parameter types and holes (e.g., `_`) in its header are resolved before its body is processed; information from the declaration body cannot be used to infer what these values should be
```


### Display 2


```text
0: cat
1: dog
2: pachycephalosaurus
```


### Display 3


```text
Zip Nats Id (ListIterator String) String : Type
```


### Display 4


```text
Zip.instFinite₂
```


### Display 5


```text
failed to synthesize
  Finite Nats Id

Hint: Additional diagnostic information may be available using the `set_option diagnostics true` command.
```


### Display 6


```text
failed to synthesize instance of type class
  ForIn IO (Iter.Total Nat) ?α

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 7


```text
#['a', 'b', 'c']
```


### Display 8


```text
a
b
c
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
m:Type → Type ?u.3inst✝:Pure mit:IterM m Natn:Nat := it.internalState.next⊢ match
  IterStep.yield
    {
      internalState :=
        let __src := it.internalState;
        { next := n + 1 } }
    n with
| IterStep.yield it' n => n = it.internalState.next ∧ it'.internalState.next = n + 1
| x => False
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
m:Type u_1 → Type u_2α:Type u_1triple:Triple αinst✝:Pure mx✝:IterM m αw✝:IterStep (IterM m α) αleft✝:w✝.successor = some x✝h:{ internalState := { triple := triple, pos := TriplePos.done } }.IsPlausibleStep w✝⊢ Acc IterM.IsPlausibleSuccessorOf x✝
```


### Display 4


```text
yieldm:Type u_1 → Type u_2α:Type u_1triple:Triple αinst✝:Pure mx✝:IterM m αout✝:αit'✝:IterM m αa✝²:{ internalState := { triple := triple, pos := TriplePos.done } }.internalState.triple = it'✝.internalState.triplea✝¹:{ internalState := { triple := triple, pos := TriplePos.done } }.internalState.pos.Succ it'✝.internalState.posa✝:{ internalState := { triple := triple, pos := TriplePos.done } }.internalState.triple.get?
    { internalState := { triple := triple, pos := TriplePos.done } }.internalState.pos =
  some out✝left✝:(IterStep.yield it'✝ out✝).successor = some x✝⊢ Acc IterM.IsPlausibleSuccessorOf x✝donem:Type u_1 → Type u_2α:Type u_1triple:Triple αinst✝:Pure mx✝:IterM m αa✝:{ internalState := { triple := triple, pos := TriplePos.done } }.internalState.pos = TriplePos.doneleft✝:IterStep.done.successor = some x✝⊢ Acc IterM.IsPlausibleSuccessorOf x✝
```


### Display 5


```text
m:Type u_1 → Type u_2α:Type u_1triple✝:Triple αinst✝:Pure mtriple:Triple αpos:TriplePosh:IterStep (IterM m α) αh':h.successor = some { internalState := { triple := triple, pos := pos } }h'':{ internalState := { triple := triple✝, pos := TriplePos.thd } }.IsPlausibleStep h⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := pos } }
```


### Display 6


```text
yieldm:Type u_1 → Type u_2α:Type u_1triple✝:Triple αinst✝:Pure mtriple:Triple αpos:TriplePosout✝:αit'✝:IterM m αa✝²:{ internalState := { triple := triple✝, pos := TriplePos.thd } }.internalState.triple = it'✝.internalState.triplea✝¹:{ internalState := { triple := triple✝, pos := TriplePos.thd } }.internalState.pos.Succ it'✝.internalState.posa✝:{ internalState := { triple := triple✝, pos := TriplePos.thd } }.internalState.triple.get?
    { internalState := { triple := triple✝, pos := TriplePos.thd } }.internalState.pos =
  some out✝h':(IterStep.yield it'✝ out✝).successor = some { internalState := { triple := triple, pos := pos } }⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := pos } }donem:Type u_1 → Type u_2α:Type u_1triple✝:Triple αinst✝:Pure mtriple:Triple αpos:TriplePosa✝:{ internalState := { triple := triple✝, pos := TriplePos.thd } }.internalState.pos = TriplePos.doneh':IterStep.done.successor = some { internalState := { triple := triple, pos := pos } }⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := pos } }
```


### Display 7


```text
m:Type u_1 → Type u_2α:Type u_1triple✝:Triple αinst✝:Pure mtriple:Triple αpos:TriplePosh:IterStep (IterM m α) αh':h.successor = some { internalState := { triple := triple, pos := pos } }h'':{ internalState := { triple := triple✝, pos := TriplePos.snd } }.IsPlausibleStep h⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := pos } }
```


### Display 8


```text
yieldm:Type u_1 → Type u_2α:Type u_1triple✝:Triple αinst✝:Pure mtriple:Triple αpos:TriplePosout✝:αit'✝:IterM m αa✝²:{ internalState := { triple := triple✝, pos := TriplePos.snd } }.internalState.triple = it'✝.internalState.triplea✝¹:{ internalState := { triple := triple✝, pos := TriplePos.snd } }.internalState.pos.Succ it'✝.internalState.posa✝:{ internalState := { triple := triple✝, pos := TriplePos.snd } }.internalState.triple.get?
    { internalState := { triple := triple✝, pos := TriplePos.snd } }.internalState.pos =
  some out✝h':(IterStep.yield it'✝ out✝).successor = some { internalState := { triple := triple, pos := pos } }⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := pos } }donem:Type u_1 → Type u_2α:Type u_1triple✝:Triple αinst✝:Pure mtriple:Triple αpos:TriplePosa✝:{ internalState := { triple := triple✝, pos := TriplePos.snd } }.internalState.pos = TriplePos.doneh':IterStep.done.successor = some { internalState := { triple := triple, pos := pos } }⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := pos } }
```


### Display 9


```text
m:Type u_1 → Type u_2α:Type u_1triple✝:Triple αinst✝:Pure mtriple:Triple αpos:TriplePosh:IterStep (IterM m α) αh':h.successor = some { internalState := { triple := triple, pos := pos } }h'':{ internalState := { triple := triple✝, pos := TriplePos.fst } }.IsPlausibleStep h⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := pos } }
```


### Display 10


```text
yieldm:Type u_1 → Type u_2α:Type u_1triple✝:Triple αinst✝:Pure mtriple:Triple αpos:TriplePosout✝:αit'✝:IterM m αa✝²:{ internalState := { triple := triple✝, pos := TriplePos.fst } }.internalState.triple = it'✝.internalState.triplea✝¹:{ internalState := { triple := triple✝, pos := TriplePos.fst } }.internalState.pos.Succ it'✝.internalState.posa✝:{ internalState := { triple := triple✝, pos := TriplePos.fst } }.internalState.triple.get?
    { internalState := { triple := triple✝, pos := TriplePos.fst } }.internalState.pos =
  some out✝h':(IterStep.yield it'✝ out✝).successor = some { internalState := { triple := triple, pos := pos } }⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := pos } }donem:Type u_1 → Type u_2α:Type u_1triple✝:Triple αinst✝:Pure mtriple:Triple αpos:TriplePosa✝:{ internalState := { triple := triple✝, pos := TriplePos.fst } }.internalState.pos = TriplePos.doneh':IterStep.done.successor = some { internalState := { triple := triple, pos := pos } }⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := pos } }
```


### Display 11


```text
m:Type u_1 → Type u_2α:Type u_1inst✝:Pure mtriple:Triple αpos:TriplePos⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := pos } }
```


### Display 12


```text
fstm:Type u_1 → Type u_2α:Type u_1inst✝:Pure mtriple:Triple α⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := TriplePos.fst } }sndm:Type u_1 → Type u_2α:Type u_1inst✝:Pure mtriple:Triple α⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := TriplePos.snd } }thdm:Type u_1 → Type u_2α:Type u_1inst✝:Pure mtriple:Triple α⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := TriplePos.thd } }donem:Type u_1 → Type u_2α:Type u_1inst✝:Pure mtriple:Triple α⊢ Acc IterM.IsPlausibleSuccessorOf { internalState := { triple := triple, pos := TriplePos.done } }
```


### Display 13


```text
it:IterM IO ByteArrayh:it.internalState.stream? = none⊢ match IterStep.done with
| IterStep.yield it_1 out => it.internalState.stream?.isSome = true
| IterStep.skip it => False
| IterStep.done => it.internalState.stream?.isNone = true
```


### Display 14


```text
it:IterM IO ByteArraystream:IO.FS.Streamh:it.internalState.stream? = some streambytes:ByteArrayit':IterM IO ByteArray := 
  {
    internalState :=
      let __src := it.internalState;
      { stream? := if (bytes.size == 0) = true then none else some stream, count := __src.count } }⊢ match IterStep.yield it' bytes with
| IterStep.yield it_1 out => it.internalState.stream?.isSome = true
| IterStep.skip it => False
| IterStep.done => it.internalState.stream?.isNone = true
```

