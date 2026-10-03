<a id="lifting-monads"></a>

# ProofScript — 18.2. Lifting Monads

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functor, applicative and monad interfaces are ordinary typeclasses and definitions. Their laws are separate propositions, not automatic consequences of defining methods. The order of StateT and ExceptT changes failure and state behavior. do is native sequencing, not a JavaScript statement language. Local mutation, loops and return use that grammar and its scope.

**Compiler and coverage boundary.** Native semicolons within do and local let expressions remain valid. Do not remove all semicolons, reinterpret every newline, or assume discarding a state value reverses external effects.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Functors___-Monads-and--do--Notation/Lifting-Monads/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Functors___-Monads-and--do--Notation/Lifting-Monads/index.html). Source Git blob: `02085765f1898971f58e037d801fbab85187be90`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 18.2. Lifting Monads

When one monad is at least as capable as another, then actions from the latter monad can be used in a context that expects actions from the former. This is called 
<a id="--tech-term-lifting"></a>
*lifting* the action from one monad to another. Lean automatically inserts lifts when they are available; lifts are defined in the `MonadLift` type class. Automatic monad lifting is attempted before the general [coercion](../../Coercions/index.md#--tech-term-coercion) mechanism.

<a id="MonadLift___mk"></a>

**type class**

```text
MonadLift.{u, v, w} (m : semiOutParam (Type u → Type v))
  (n : Type u → Type w) : Type (max (max (u + 1) v) w)
```

Computations in the monad `m` can be run in the monad `n`. These translations are inserted automatically by the compiler.

Usually, `n` consists of some number of monad transformers applied to `m`, but this is not mandatory.

New instances should use this class, `MonadLift`. Clients that require one monad to be liftable into another should instead request `MonadLiftT`, which is the reflexive, transitive closure of `MonadLift`.

**Instance Constructor**

```text
MonadLift.mk.{u, v, w}
```

**Methods**

```text
monadLift : {α : Type u} → m α → n α
```

Translates an action from monad `m` into monad `n`.

[Lifting](index.md#--tech-term-lifting) between monads is reflexive and transitive:

- Any monad can run its own actions.
- Lifts from `m` to `m'` and from `m'` to `n` can be composed to yield a lift from `m` to `n`. The utility type class `MonadLiftT` constructs lifts via the reflexive and transitive closure of `MonadLift` instances. Users should not define new instances of `MonadLiftT`, but it is useful as an instance implicit parameter to a polymorphic function that needs to run actions from multiple monads in some user-provided monad.

<a id="MonadLiftT___mk"></a>

**type class**

```text
MonadLiftT.{u, v, w} (m : Type u → Type v) (n : Type u → Type w) :
  Type (max (max (u + 1) v) w)
```

Computations in the monad `m` can be run in the monad `n`. These translations are inserted automatically by the compiler.

Usually, `n` consists of some number of monad transformers applied to `m`, but this is not mandatory.

This is the reflexive, transitive closure of `MonadLift`. Clients that require one monad to be liftable into another should request an instance of `MonadLiftT`. New instances should instead be defined for `MonadLift` itself.

**Instance Constructor**

```text
MonadLiftT.mk.{u, v, w}
```

**Methods**

```text
monadLift : {α : Type u} → m α → n α
```

Translates an action from monad `m` into monad `n`.

<a id="Monad-Lifts-in-Function-Signatures"></a>
Monad Lifts in Function Signatures 

The function `IO.withStdin` has the following signature:

```proofscript
IO.withStdin.{u} {m : Type → Type u} {α : Type}
  [Monad m] [MonadFinally m] [MonadLiftT BaseIO m]
  (h : IO.FS.Stream) (x : m α) :
  m α
```

Because it doesn't require its parameter to precisely be in `IO`, it can be used in many monads, and the body does not need to restrict itself to `IO`. The instance implicit parameter `MonadLiftT BaseIO m` allows the reflexive transitive closure of `MonadLift` to be used to assemble the lift.

When a term of type `n β` is expected, but the provided term has type `m α`, and the two types are not definitionally equal, Lean attempts to insert lifts and coercions before reporting an error. There are the following possibilities:

1. If `m` and `n` can be unified to the same monad, then `α` and `β` are not the same. In this case, no monad lifts are necessary, but the value in the monad must be [coerced](../../Coercions/index.md#--tech-term-coercion). If the appropriate coercion is found, then a call to `Lean.Internal.coeM` is inserted, which has the following signature:

   

  ```proofscript
  Lean.Internal.coeM.{u, v} {m : Type u → Type v} {α β : Type u}
    [(a : α) → CoeT α a β] [Monad m]
    (x : m α) :
    m β
  ```
2. If `α` and `β` can be unified, then the monads differ. In this case, a monad lift is necessary to transform an expression with type `m α` to `n α`. If `m` can be lifted to `n` (that is, there is an instance of `MonadLiftT m n`) then a call to `liftM`, which is an alias for `MonadLiftT.monadLift`, is inserted.

   

  ```proofscript
  liftM.{u, v, w}
    {m : Type u → Type v} {n : Type u → Type w}
    [self : MonadLiftT m n] {α : Type u} :
    m α → n α
  ```
3. If neither `m` and `n` nor `α` and `β` can be unified, but `m` can be lifted into `n` and `α` can be [coerced](../../Coercions/index.md#--tech-term-coercion) to `β`, then a lift and a coercion can be combined. This is done by inserting a call to `Lean.Internal.liftCoeM`:

   

  ```proofscript
  Lean.Internal.liftCoeM.{u, v, w}
    {m : Type u → Type v} {n : Type u → Type w}
    {α β : Type u}
    [MonadLiftT m n] [(a : α) → CoeT α a β] [Monad n]
    (x : m α) :
    n β
  ```

As their names suggest, `Lean.Internal.coeM` and `Lean.Internal.liftCoeM` are implementation details, not part of the public API. In the resulting terms, occurrences of `Lean.Internal.coeM`, `Lean.Internal.liftCoeM`, and coercions are unfolded.

<a id="Lifting--IO--Monads"></a>
Lifting `IO` Monads 

There is an instance of `MonadLift BaseIO IO`, so any `BaseIO` action can be run in `IO` as well:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="fromBaseIO-_LPAR_in-Lifting--IO--Monads_RPAR_"></a>


```proofscript
function fromBaseIO (act : BaseIO α) : IO α := act
```

Behind the scenes, `liftM` is inserted:

```proofscript
#check fun {α} (act : BaseIO α) => (act : IO α)
```

```lean
fun {α} act => liftM act : {α : Type} → BaseIO α → EIO IO.Error α
```

<a id="Lifting-Transformed-Monads"></a>
Lifting Transformed Monads 

There are also instances of `MonadLift` for most of the standard library's [monad transformers](../Varieties-of-Monads/index.md#--tech-term-monad-transformer), so base monad actions can be used in transformed monads without additional work. For example, state monad actions can be lifted across reader and exception transformers, allowing compatible monads to be intermixed freely:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function incrBy (n : Nat) : StateM Nat Unit := modify (· + n)

const incrOrFail : ReaderT Nat (ExceptT String (StateM Nat)) Unit := do
  if (← read) > 5 then throw "Too much!"
  incrBy (← read)
```

Disabling lifting causes an error:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
set_option autoLift false

function incrBy (n : Nat) : StateM Nat Unit := modify (. + n)

const incrOrFail : ReaderT Nat (ExceptT String (StateM Nat)) Unit := do
  if (← read) > 5 then throw "Too much!"
  incrBy (← read)
```

```lean
Type mismatch
  incrBy __do_lift✝
has type
  StateM Nat Unit
but is expected to have type
  ReaderT Nat (ExceptT String (StateM Nat)) Unit
```

Automatic lifting can be disabled by setting `autoLift` to `false`.

<a id="autoLift"></a>

**option**

```text
autoLift
```

Default value: `true`

Insert monadic lifts (i.e., `liftM` and coercions) when needed.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Lifting-Monads--Reversing-Lifts"></a>
### 18.2.1. Reversing Lifts

Monad lifting is not always sufficient to combine monads. Many operations provided by monads are higher order, taking an action *in the same monad* as a parameter. Even if these operations are lifted to some more powerful monad, their arguments are still restricted to the original monad.

There are two type classes that support this kind of “reverse lifting”: `MonadFunctor` and `MonadControl`. An instance of `MonadFunctor m n` explains how to interpret a fully-polymorphic function in `m` into `n`. This polymorphic function must work for *all* types `α`: it has type `{α : Type u} → m α → n α`. Such a function can be thought of as one that may have effects, but can't do so based on specific values that are provided. An instance of `MonadControl m n` explains how to interpret an arbitrary action from `m` into `n`, while at the same time providing a “reverse interpreter” that allows the `m` action to run `n` actions.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Lifting-Monads--Reversing-Lifts--Monad-Functors"></a>
#### 18.2.1.1. Monad Functors

<a id="MonadFunctor___mk"></a>

**type class**

```text
MonadFunctor.{u, v, w} (m : semiOutParam (Type u → Type v))
  (n : Type u → Type w) : Type (max (max (u + 1) v) w)
```

A way to interpret a fully-polymorphic function in `m` into `n`. Such a function can be thought of as one that may change the effects in `m`, but can't do so based on specific values that are provided.

Clients of `MonadFunctor` should typically use `MonadFunctorT`, which is the reflexive, transitive closure of `MonadFunctor`. New instances should be defined for `MonadFunctor.`

**Instance Constructor**

```text
MonadFunctor.mk.{u, v, w}
```

**Methods**

```text
monadMap : {α : Type u} → ({β : Type u} → m β → m β) → n α → n α
```

Lifts a fully-polymorphic transformation of `m` into `n`.

<a id="MonadFunctorT___mk"></a>

**type class**

```text
MonadFunctorT.{u, v, w} (m : Type u → Type v) (n : Type u → Type w) :
  Type (max (max (u + 1) v) w)
```

A way to interpret a fully-polymorphic function in `m` into `n`. Such a function can be thought of as one that may change the effects in `m`, but can't do so based on specific values that are provided.

This is the reflexive, transitive closure of `MonadFunctor`. It automatically chains together `MonadFunctor` instances as needed. Clients of `MonadFunctor` should typically use `MonadFunctorT`, but new instances should be defined for `MonadFunctor`.

**Instance Constructor**

```text
MonadFunctorT.mk.{u, v, w}
```

**Methods**

```text
monadMap : {α : Type u} → ({β : Type u} → m β → m β) → n α → n α
```

Lifts a fully-polymorphic transformation of `m` into `n`.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Lifting-Monads--Reversing-Lifts--Reversible-Lifting-with--MonadControl"></a>
#### 18.2.1.2. Reversible Lifting with MonadControl

<a id="MonadControl___mk"></a>

**type class**

```text
MonadControl.{u, v, w} (m : semiOutParam (Type u → Type v))
  (n : Type u → Type w) : Type (max (max (u + 1) v) w)
```

A way to lift a computation from one monad to another while providing the lifted computation with a means of interpreting computations from the outer monad. This provides a means of lifting higher-order operations automatically.

Clients should typically use `control` or `controlAt`, which request an instance of `MonadControlT`: the reflexive, transitive closure of `MonadControl`. New instances should be defined for `MonadControl` itself.

**Instance Constructor**

```text
MonadControl.mk.{u, v, w}
```

**Methods**

```text
stM : Type u → Type u
```

A type that can be used to reconstruct both a returned value and any state used by the outer monad.

```text
liftWith : {α : Type u} → (({β : Type u} → n β → m (MonadControl.stM m n β)) → m α) → n α
```

Lifts an action from the inner monad `m` to the outer monad `n`. The inner monad has access to a reverse lifting operator that can run an `n` action, returning a value and state together.

```text
restoreM : {α : Type u} → m (MonadControl.stM m n α) → n α
```

Lifts a monadic action that returns a state and a value in the inner monad to an action in the outer monad. The extra state information is used to restore the results of effects from the reverse lift passed to `liftWith`'s parameter.

<a id="MonadControlT___mk"></a>

**type class**

```text
MonadControlT.{u, v, w} (m : Type u → Type v) (n : Type u → Type w) :
  Type (max (max (u + 1) v) w)
```

A way to lift a computation from one monad to another while providing the lifted computation with a means of interpreting computations from the outer monad. This provides a means of lifting higher-order operations automatically.

Clients should typically use `control` or `controlAt`, which request an instance of `MonadControlT`: the reflexive, transitive closure of `MonadControl`. New instances should be defined for `MonadControl` itself.

**Instance Constructor**

```text
MonadControlT.mk.{u, v, w}
```

**Methods**

```text
stM : Type u → Type u
```

A type that can be used to reconstruct both a returned value and any state used by the outer monad.

```text
liftWith : {α : Type u} → (({β : Type u} → n β → m (stM m n β)) → m α) → n α
```

Lifts an action from the inner monad `m` to the outer monad `n`. The inner monad has access to a reverse lifting operator that can run an `n` action, returning a value and state together.

```text
restoreM : {α : Type u} → stM m n α → n α
```

Lifts a monadic action that returns a state and a value in the inner monad to an action in the outer monad. The extra state information is used to restore the results of effects from the reverse lift passed to `liftWith`'s parameter.

<a id="control"></a>

**def**

```text
control.{u, v, w} {m : Type u → Type v} {n : Type u → Type w}
  [MonadControlT m n] [Bind n] {α : Type u}
  (f : ({β : Type u} → n β → m (stM m n β)) → m (stM m n α)) : n α
```

Lifts an operation from an inner monad to an outer monad, providing it with a reverse lifting operator that allows outer monad computations to be run in the inner monad. The lifted operation is required to return extra information that is required in order to reconstruct the reverse lift's effects in the outer monad; this extra information is determined by `stM`.

This function takes the inner monad as an implicit parameter. Use `controlAt` to specify it explicitly.

<a id="controlAt"></a>

**def**

```text
controlAt.{u, v, w} (m : Type u → Type v) {n : Type u → Type w}
  [MonadControlT m n] [Bind n] {α : Type u}
  (f : ({β : Type u} → n β → m (stM m n β)) → m (stM m n α)) : n α
```

Lifts an operation from an inner monad to an outer monad, providing it with a reverse lifting operator that allows outer monad computations to be run in the inner monad. The lifted operation is required to return extra information that is required in order to reconstruct the reverse lift's effects in the outer monad; this extra information is determined by `stM`.

This function takes the inner monad as an explicit parameter. Use `control` to infer the monad.

<a id="Exceptions-and-Lifting"></a>
Exceptions and Lifting 

One example is `Except.tryCatch`:

```proofscript
Except.tryCatch.{u, v} {ε : Type u} {α : Type v}
  (ma : Except ε α) (handle : ε → Except ε α) :
  Except ε α
```

Both of its parameters are in `Except ε`. `MonadLift` can lift the entire application of the handler. The function `getBytes`, which extracts the single bytes from an array of `Nat`s using state and exceptions, is written without [`do`](../Syntax/index.md#Lean___Parser___Term___do)-notation or automatic lifting in order to make its structure explicit.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="getByte-_LPAR_in-Exceptions-and-Lifting_RPAR_"></a>
<a id="getBytes-_LPAR_in-Exceptions-and-Lifting_RPAR_"></a>


```proofscript
set_option autoLift false

function getByte (n : Nat) : Except String UInt8 :=
  if n < 256 then
    pure n.toUInt8
  else throw s!"Out of range: {n}"

function getBytes (input : Array Nat) :
    StateT (Array UInt8) (Except String) Unit := do
  input.forM fun i =>
    liftM (Except.tryCatch (some <$> getByte i) fun _ => pure none) >>=
      fun
        | some b => modify (·.push b)
        | none => pure ()
```

```proofscript
#eval getBytes #[1, 58, 255, 300, 2, 1000000] |>.run #[] |>.map (·.2)
```

```lean
Except.ok #[1, 58, 255, 2]
```

`getBytes` uses an `Option` returned from the lifted action to signal the desired state updates. This quickly becomes unwieldy if there is more than one way to react to the inner action, such as saving handled exceptions. Ideally, state updates would be performed within the `tryCatch` call directly.

Attempting to save bytes and handled exceptions does not work, however, because the arguments to `Except.tryCatch` have type `Except String Unit`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function getBytes' (input : Array Nat) :
    StateT (Array String)
      (StateT (Array UInt8)
        (Except String)) Unit := do
  input.forM fun i =>
    liftM
      (Except.tryCatch
        (getByte i >>= fun b =>
         modifyThe (Array UInt8) (·.push b))
        fun e =>
          modifyThe (Array String) (·.push e))
```

```lean
failed to synthesize instance of type class
  MonadStateOf (Array String) (Except String)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Because `StateT` has a `MonadControl` instance, `control` can be used instead of `liftM`. It provides the inner action with an interpreter for the outer monad. In the case of `StateT`, this interpreter expects that the inner monad returns a tuple that includes the updated state, and takes care of providing the initial state and extracting the updated state from the tuple.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function getBytes' (input : Array Nat) :
    StateT (Array String)
      (StateT (Array UInt8)
        (Except String)) Unit := do
  input.forM fun i =>
    control fun run =>
      (Except.tryCatch
        (getByte i >>= fun b =>
         run (modifyThe (Array UInt8) (·.push b))))
        fun e =>
          run (modifyThe (Array String) (·.push e))
```

```proofscript
#eval
  getBytes' #[1, 58, 255, 300, 2, 1000000]
  |>.run #[] |>.run #[]
  |>.map (fun (((), bytes), errs) => (bytes, errs))
```

```lean
Except.ok (#["Out of range: 300", "Out of range: 1000000"], #[1, 58, 255, 2])
```

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
fun {α} act => liftM act : {α : Type} → BaseIO α → EIO IO.Error α
```


### Display 2


```text
Type mismatch
  incrBy __do_lift✝
has type
  StateM Nat Unit
but is expected to have type
  ReaderT Nat (ExceptT String (StateM Nat)) Unit
```


### Display 3


```text
Except.ok #[1, 58, 255, 2]
```


### Display 4


```text
failed to synthesize instance of type class
  MonadStateOf (Array UInt8) (Except String)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 5


```text
failed to synthesize instance of type class
  MonadStateOf (Array String) (Except String)

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 6


```text
Except.ok (#["Out of range: 300", "Out of range: 1000000"], #[1, 58, 255, 2])
```

