<a id="The-Lean-Language-Reference--IO--Mutable-References"></a>

# ProofScript — 21.4. Mutable References

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

**Compiler and coverage boundary.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [IO/Mutable-References/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/IO/Mutable-References/index.html). Source Git blob: `7866174bf5004aac79388e0bb56270fe446eb115`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 21.4. Mutable References

While ordinary [state monads](../../Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#--tech-term-State-monads) encode stateful computations with tuples that track the contents of the state along with the computation's value, Lean's runtime system also provides mutable references that are always backed by mutable memory cells. Mutable references have a type `IO.Ref` that indicates that a cell is mutable, and reads and writes must be explicit. `IO.Ref` is implemented using `ST.Ref`, so the entire [`ST.Ref` API](index.md#mutable-st-references) may also be used with `IO.Ref`.

<a id="IO___Ref"></a>

**def**

```text
IO.Ref (α : Type) : Type
```

Mutable reference cells that contain values of type `α`. These cells can read from and mutated in the `IO` monad.

<a id="IO___mkRef"></a>

**def**

```text
IO.mkRef {α : Type} (a : α) : BaseIO (IO.Ref α)
```

Creates a new mutable reference cell that contains `a`.

<a id="mutable-st-references"></a>
### 21.4.1. State Transformers

Mutable references are often useful in contexts where arbitrary side effects are undesired. They can give a significant speedup when Lean is unable to optimize pure operations into mutation, and some algorithms are more easily expressed using mutable references than with state monads. Additionally, it has a property that other side effects do not have: if all of the mutable references used by a piece of code are created during its execution, and no mutable references from the code escape to other code, then the result of evaluation is deterministic.

The `ST` monad is a restricted version of `IO` in which mutable state is the only side effect, and mutable references cannot escape.`ST` was first described by John Launchbury and Simon L Peyton Jones, 1994. “Lazy functional state threads”. In *Proceedings of the ACM SIGPLAN 1994 Conference on Programming Language Design and Implementation.*. `ST` takes a type parameter that is never used to classify any terms. The `runST` function, which allow escape from `ST`, requires that the `ST` action that is passed to it can instantiate this type parameter with *any* type. This unknown type does not exist except as a parameter to a function, which means that values whose types are “marked” by it cannot escape its scope.

<a id="ST"></a>

**def**

```text
ST (σ α : Type) : Type
```

A restricted version of `IO` in which mutable state is the only side effect.

It is possible to run `ST` computations in a non-monadic context using `runST`.

<a id="runST"></a>

**def**

```text
runST {α : Type} (x : (σ : Type) → ST σ α) : α
```

Runs an `ST` computation, in which mutable state via `ST.Ref` is the only side effect.

As with `IO` and `EIO`, there is also a variation of `ST` that takes a custom error type as a parameter. Here, `ST` is analogous to `BaseIO` rather than `IO`, because `ST` cannot result in errors being thrown.

<a id="EST"></a>

**def**

```text
EST (ε σ α : Type) : Type
```

A restricted version of `IO` in which mutable state and exceptions are the only side effects.

It is possible to run `EST` computations in a non-monadic context using `runEST`.

<a id="runEST"></a>

**def**

```text
runEST {ε α : Type} (x : (σ : Type) → EST ε σ α) : Except ε α
```

Runs an `EST` computation, in which mutable state and exceptions are the only side effects.

<a id="ST___Ref___mk"></a>

**structure**

```text
ST.Ref (σ α : Type) : Type
```

Mutable reference cells that contain values of type `α`. These cells can read from and mutated in the `ST σ` monad.

**Constructor**

```text
ST.Ref.mk
```

<a id="ST___mkRef"></a>

**def**

```text
ST.mkRef {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type}
  (a : α) : m (ST.Ref σ α)
```

Creates a new mutable reference that contains the provided value `a`.

<a id="The-Lean-Language-Reference--IO--Mutable-References--State-Transformers--Reading-and-Writing"></a>
#### 21.4.1.1. Reading and Writing

<a id="ST___Ref___get"></a>

**def**

```text
ST.Ref.get {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type}
  (r : ST.Ref σ α) : m α
```

Reads the value of a mutable reference.

<a id="ST___Ref___set"></a>

**def**

```text
ST.Ref.set {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m] {α : Type}
  (r : ST.Ref σ α) (a : α) : m Unit
```

Replaces the value of a mutable reference.

<a id="Data-races-with--get--and--set"></a>
Data races with `get` and `set` 
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-Data-races-with--get--and--set_RPAR_"></a>


```proofscript
const main : IO Unit := do
  let balance ← IO.mkRef (100 : Int)

  let mut orders := #[]
  IO.println "Sending out orders..."
  for _ in [0:100] do
    let o ← IO.asTask (prio := .dedicated) do
      let cost ← IO.rand 1 100
      IO.sleep (← IO.rand 10 100).toUInt32
      if cost < (← balance.get) then
        IO.sleep (← IO.rand 10 100).toUInt32
        balance.set ((← balance.get) - cost)
    orders := orders.push o

  -- Wait until all orders are completed
  for o in orders do
    match o.get with
    | .ok () => pure ()
    | .error e => throw e

  if (← balance.get) < 0 then
    IO.eprintln "Final balance is negative!"
  else
    IO.println "Final balance is zero or positive."
```

 `stdout``Sending out orders...`  `stderr``Final balance is negative!`  
<a id="ST___Ref___modify"></a>

**def**

```text
ST.Ref.modify {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m]
  {α : Type} (r : ST.Ref σ α) (f : α → α) : m Unit
```

Atomically modifies a mutable reference cell by replacing its contents with the result of a function call.

<a id="Avoiding-data-races-with--modify"></a>
Avoiding data races with `modify` 

This program launches 100 threads. Each thread simulates a purchase attempt: it generates a random price, and if the account balance is sufficient, it decrements it by the price. The balance check and the computation of the new value occur in an atomic call to `ST.Ref.modify`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-Avoiding-data-races-with--modify_RPAR_"></a>


```proofscript
const main : IO Unit := do
  let balance ← IO.mkRef (100 : Int)

  let mut orders := #[]
  IO.println "Sending out orders..."
  for _ in [0:100] do
    let o ← IO.asTask (prio := .dedicated) do
      let cost ← IO.rand 1 100
      IO.sleep (← IO.rand 10 100).toUInt32
      balance.modify fun b =>
        if cost < b then
          b - cost
        else b
    orders := orders.push o

  -- Wait until all orders are completed
  for o in orders do
    match o.get with
    | .ok () => pure ()
    | .error e => throw e

  if (← balance.get) < 0 then
    IO.eprintln "Final balance negative!"
  else
    IO.println "Final balance is zero or positive."
```

 `stdout``Sending out orders...``Final balance is zero or positive.`  `stderr``<empty>`  
<a id="ST___Ref___modifyGet"></a>

**def**

```text
ST.Ref.modifyGet {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m]
  {α β : Type} (r : ST.Ref σ α) (f : α → β × α) : m β
```

Atomically modifies a mutable reference cell by replacing its contents with the result of a function call that simultaneously computes a value to return.

<a id="ST___Ref___swap"></a>

**def**

```text
ST.Ref.swap {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m]
  {α : Type} (r : ST.Ref σ α) (a : α) : m α
```

Atomically swaps the value of a mutable reference cell with another value. The reference cell's original value is returned.

<a id="The-Lean-Language-Reference--IO--Mutable-References--State-Transformers--Comparisons"></a>
#### 21.4.1.2. Comparisons

<a id="ST___Ref___ptrEq"></a>

**def**

```text
ST.Ref.ptrEq {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m]
  {α : Type} (r1 r2 : ST.Ref σ α) : m Bool
```

Checks whether two reference cells are in fact aliases for the same cell.

Even if they contain the same value, two references allocated by different executions of `IO.mkRef` or `ST.mkRef` are distinct. Modifying one has no effect on the other. Likewise, a single reference cell may be aliased, and modifications to one alias also modify the other.

<a id="The-Lean-Language-Reference--IO--Mutable-References--State-Transformers--ST--Backed-State-Monads"></a>
#### 21.4.1.3. ST-Backed State Monads

<a id="ST___Ref___toMonadStateOf"></a>

**def**

```text
ST.Ref.toMonadStateOf {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m]
  {α : Type} (r : ST.Ref σ α) : MonadStateOf α m
```

Creates a `MonadStateOf` instance from a reference cell.

This allows programs written against the [state monad](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=state-monads) API to be executed using a mutable reference cell to track the state.

<a id="ref-locks"></a>
### 21.4.2. Concurrency

Mutable references can be used as a locking mechanism. *Taking* the contents of the reference causes attempts to take it or to read from it to block until it is `set` again. This is a low-level feature that can be used to implement other synchronization mechanisms; it's usually better to rely on higher-level abstractions when possible.

<a id="ST___Ref___take"></a>

**unsafe def**

```text
ST.Ref.take {σ : Type} {m : Type → Type} [MonadLiftT (ST σ) m]
  {α : Type} (r : ST.Ref σ α) : m α
```

Reads the value of a mutable reference cell, removing it.

This causes subsequent attempts to read from or take the reference cell to block until a new value is written using `ST.Ref.set`.

<a id="Reference-Cells-as-Locks"></a>
Reference Cells as Locks 

This program launches 100 threads. Each thread simulates a purchase attempt: it generates a random price, and if the account balance is sufficient, it decrements it by the price. If the balance is not sufficient, then it is not decremented. Because each thread `take`s the balance cell prior to checking it and only returns it when it is finished, the cell acts as a lock. Unlike using `ST.Ref.modify`, which atomically modifies the contents of the cell using a pure function, other `IO` actions may occur in the critical section. This program's `main` function is marked `unsafe` because `take` itself is unsafe.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-Reference-Cells-as-Locks_RPAR_"></a>


```proofscript
unsafe const main : IO Unit := do
  let balance ← IO.mkRef (100 : Int)
  let validationUsed ← IO.mkRef false

  let mut orders := #[]

  IO.println "Sending out orders..."
  for _ in [0:100] do
    let o ← IO.asTask (prio := .dedicated) do
      let cost ← IO.rand 1 100
      IO.sleep (← IO.rand 10 100).toUInt32
      let b ← balance.take
      if cost ≤ b then
        balance.set (b - cost)
      else
        balance.set b
        validationUsed.set true
    orders := orders.push o

  -- Wait until all orders are completed
  for o in orders do
    match o.get with
    | .ok () => pure ()
    | .error e => throw e

  if (← validationUsed.get) then
    IO.println "Validation prevented a negative balance."

  if (← balance.get) < 0 then
    IO.eprintln "Final balance negative!"
  else
    IO.println "Final balance is zero or positive."
```

The program's output is:

  `stdout``Sending out orders...``Validation prevented a negative balance.``Final balance is zero or positive.`
