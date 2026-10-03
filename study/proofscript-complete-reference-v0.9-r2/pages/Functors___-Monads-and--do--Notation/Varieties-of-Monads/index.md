<a id="monad-varieties"></a>

# ProofScript — 18.5. Varieties of Monads

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functor, applicative and monad interfaces are ordinary typeclasses and definitions. Their laws are separate propositions, not automatic consequences of defining methods. The order of StateT and ExceptT changes failure and state behavior. do is native sequencing, not a JavaScript statement language. Local mutation, loops and return use that grammar and its scope.

**Compiler and coverage boundary.** Native semicolons within do and local let expressions remain valid. Do not remove all semicolons, reinterpret every newline, or assume discarding a state value reverses external effects.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.html). Source Git blob: `4b71a74465e788a29a323934c2639cfa1edf64d8`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 18.5. Varieties of Monads

The `IO` monad has many, many effects, and is used for writing programs that need to interact with the world. It is described in [its own section](../../IO/index.md#io). Programs that use `IO` are essentially black boxes: they are typically not particularly amenable to verification.

Many algorithms are easiest to express with a much smaller set of effects. These effects can often be simulated; for example, mutable state can be simulated by passing around a tuple that contains both the program's value and the state. These simulated effects are easier to reason formally about, because they are defined using ordinary code rather than new language primitives.

The standard library provides abstractions for working with commonly-used effects. Many frequently-used effects fall into a small number of categories:

<a id="--tech-term-State-monads"></a>
State monads have mutable state

Computations that have access to some data that may be modified by other parts of the computation use *mutable state*. State can be implemented in a variety of ways, described in the section on [state monads](index.md#state-monads) and captured in the `MonadState` type class.

<a id="--tech-term-Reader-monads"></a>
Reader monads are parameterized computations

Computations that can read the value of some parameter provided by a context exist in most programming languages, but many languages that feature state and exceptions as first-class features do not have built-in facilities for defining new parameterized computations. Typically, these computations are provided with a parameter value when invoked, and sometimes they can locally override it. Parameter values have *dynamic extent*: the value provided most recently in the call stack is the one that is used. They can be simulated by passing a value unchanged through a sequence of function calls; however, this technique can make code harder to read and introduces a risk that the values may be passed incorrectly to further calls by mistake. They can also be simulated using mutable state with a careful discipline surrounding the modification of the state. Monads that maintain a parameter, potentially allowing it to be overridden in a section of the call stack, are called *reader monads*. Reader monads are captured in the `MonadReader` type class. Additionally, reader monads that allow the parameter value to be locally overridden are captured in the `MonadWithReader` type class.

<a id="--tech-term-Exception-monads"></a>
Exception monads have exceptions

Computations that may terminate early with an exceptional value use *exceptions*. They are typically modeled with a sum type that has a constructor for ordinary termination and a constructor for early termination with errors. Exception monads are described in the section on [exception monads](index.md#exception-monads), and captured in the `MonadExcept` type class.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--Monad-Type-Classes"></a>
### 18.5.1. Monad Type Classes

Using type classes like `MonadState` and `MonadExcept` allow client code to be polymorphic with respect to monads. Together with automatic lifting, this allows programs to be reusable in many different monads and makes them more robust to refactoring.

It's important to be aware that effects in a monad may not interact in only one way. For example, a monad with state and exceptions may or may not roll back state changes when an exception is thrown. If this matters for the correctness of a function, then it should use a more specific signature.

<a id="Effect-Ordering"></a>
Effect Ordering 

The function `sumNonFives` adds the contents of a list using a state monad, terminating early if it encounters a `5`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="sumNonFives-_LPAR_in-Effect-Ordering_RPAR_"></a>


```proofscript
function sumNonFives {m}
    [Monad m] [MonadState Nat m] [MonadExcept String m]
    (xs : List Nat) :
    m Unit := do
  for x in xs do
    if x == 5 then
      throw "Five was encountered"
    else
      modify (· + x)
```

Running it in one monad returns the state at the time that `5` was encountered:

```proofscript
#eval
  sumNonFives (m := ExceptT String (StateM Nat))
    [1, 2, 3, 4, 5, 6] |>.run |>.run 0
```

```lean
(Except.error "Five was encountered", 10)
```

In another, the state is discarded:

```proofscript
#eval
  sumNonFives (m := StateT Nat (Except String))
    [1, 2, 3, 4, 5, 6] |>.run 0
```

```lean
Except.error "Five was encountered"
```

In the second case, an exception handler would roll back the state to its value at the start of the `try`. The following function is thus incorrect:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="sumUntilFive-_LPAR_in-Effect-Ordering_RPAR_"></a>


```proofscript
/-- Computes the sum of the non-5 prefix of a list. -/
function sumUntilFive {m}
    [Monad m] [MonadState Nat m] [MonadExcept String m]
    (xs : List Nat) :
    m Nat := do
  MonadState.set 0
  try
    sumNonFives xs
  catch _ =>
    pure ()
  get
```

In one monad, the answer is correct:

```proofscript
#eval
  sumUntilFive (m := ExceptT String (StateM Nat))
    [1, 2, 3, 4, 5, 6] |>.run |>.run' 0
```

```lean
Except.ok 10
```

In the other, it is not:

```proofscript
#eval
  sumUntilFive (m := StateT Nat (Except String))
    [1, 2, 3, 4, 5, 6] |>.run' 0
```

```lean
Except.ok 0
```

A single monad may support multiple version of the same effect. For example, there might be a mutable `Nat` and a mutable `String` or two separate reader parameters. As long as they have different types, it should be convenient to access both. In typical use, some monadic operations that are overloaded in type classes have type information available for [instance synthesis](../../Type-Classes/index.md#--tech-term-synthesizes), while others do not. For example, the argument passed to `set` determines the type of the state to be used, while `get` takes no such argument. The type information present in applications of `set` can be used to pick the correct instance when multiple states are available, which suggests that the type of the mutable state should be an input parameter or [semi-output parameter](../../Type-Classes/Instance-Synthesis/index.md#--tech-term-Semi-output-parameters) so that it can be used to select instances. The lack of type information present in uses of `get`, on the other hand, suggests that the type of the mutable state should be an [output parameter](../../Type-Classes/Instance-Synthesis/index.md#--tech-term-output-parameter) in `MonadState`, so type class synthesis determines the state's type from the monad itself.

This dichotomy is solved by having two versions of many of the effect type classes. The version with a semi-output parameter has the suffix `-Of`, and its operations take types explicitly as needed. Examples include `MonadStateOf`, `MonadReaderOf`, and `MonadExceptOf`. The operations with explicit type parameters have names ending in `-The`, such as `getThe`, `readThe`, and `tryCatchThe`. The name of the version with an output parameter is undecorated. The standard library exports a mix of operations from the `-Of` and undecorated versions of each type class, based on what has good inference behavior in typical use cases.

| Operation | From Class | Notes |
| --- | --- | --- |
| `get` | `MonadState` | Output parameter improves type inference |
| `set` | `MonadStateOf` | Semi-output parameter uses type information from `set`'s argument |
| `modify` | `MonadState` | Output parameter is needed to allow functions without annotations |
| `modifyGet` | `MonadState` | Output parameter is needed to allow functions without annotations |
| `read` | `MonadReader` | Output parameter is needed due to lack of type information from arguments |
| `readThe` | `MonadReaderOf` | Semi-output parameter uses the provided type to guide synthesis |
| `withReader` | `MonadWithReader` | Output parameter avoids the need for type annotations on the function |
| `withTheReader` | `MonadWithReaderOf` | Semi-output parameter uses provided type to guide synthesis |
| `throw` | `MonadExcept` | Output parameter enables the use of constructor dot notation for the exception |
| `throwThe` | `MonadExceptOf` | Semi-output parameter uses provided type to guide synthesis |
| `tryCatch` | `MonadExcept` | Output parameter enables the use of constructor dot notation for the exception |
| `tryCatchThe` | `MonadExceptOf` | Semi-output parameter uses provided type to guide synthesis |

<a id="State-Types"></a>
State Types 

The state monad `M` has two separate states: a `Nat` and a `String`.
<a id="M-_LPAR_in-State-Types_RPAR_"></a>


```proofscript
abbrev M := StateT Nat (StateM String)
```

Because `get` is an alias for `MonadState.get`, the state type is an output parameter. This means that Lean selects a state type automatically, in this case the one from the outermost monad transformer:

```proofscript
#check (get : M _)
```

```lean
get : M Nat
```

Only the outermost may be used, because the type of the state is an output parameter.

```proofscript
#check (get : M String)
```

```lean
failed to synthesize instance of type class
  MonadState String M

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Providing the state type explicitly using `getThe` from `MonadStateOf` allows both states to be read.

```proofscript
#check ((getThe String, getThe Nat) : M String × M Nat)
```

```lean
(getThe String, getThe Nat) : M String × M Nat
```

Setting a state works for either type, because the state type is a [semi-output parameter](../../Type-Classes/Instance-Synthesis/index.md#--tech-term-Semi-output-parameters) on `MonadStateOf`.

```proofscript
#check (set 4 : M Unit)
```

```lean
set 4 : M PUnit
```

```proofscript
#check (set "Four" : M Unit)
```

```lean
set "Four" : M PUnit
```

<a id="monad-transformers"></a>
### 18.5.2. Monad Transformers

A 
<a id="--tech-term-monad-transformer"></a>
*monad transformer* is a function that, when provided with a monad, gives back a new monad. Typically, this new monad has all the effects of the original monad along with some additional ones.

A monad transformer consists of the following:

- A function `T` that constructs the new monad's type from an existing monad
- A `run` function that adapts a `T m α` into some variant of `m`, often requiring additional parameters and returning a more specific type under `m`
- An instance of `[Monad m] → Monad (T m)` that allows the transformed monad to be used as a monad
- An instance of `MonadLift` that allows the original monad's code to be used in the transformed monad
- If possible, an instance of `MonadControl m (T m)` that allows actions from the transformed monad to be used in the original monad

Typically, a monad transformer also provides instances of one or more type classes that describe the effects that it introduces. The transformer's `Monad` and `MonadLift` instances make it practical to write code in the transformed monad, while the type class instances allow the transformed monad to be used with polymorphic functions.

<a id="The-Identity-Monad-Transformer-"></a>
The Identity Monad Transformer  

The identity monad transformer neither adds nor removes capabilities to the transformed monad. Its definition is the identity function, suitably specialized:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="IdT-_LPAR_in-The-Identity-Monad-Transformer-_RPAR_"></a>


```proofscript
function IdT (m : Type u → Type v) : Type u → Type v := m
```

Similarly, the `run` function requires no additional arguments and just returns an `m α`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="IdT___run-_LPAR_in-The-Identity-Monad-Transformer-_RPAR_"></a>


```proofscript
function IdT.run (act : IdT m α) : m α := act
```

The monad instance relies on the monad instance for the transformed monad, selecting it via [type ascriptions](../../Terms/Type-Ascription/index.md#--tech-term-Type-ascriptions):

```proofscript
instance [Monad m] : Monad (IdT m) where
  pure x := (pure x : m _)
  bind x f := (x >>= f : m _)
```

Because `IdT m` is definitionally equal to `m`, the `MonadLift m (IdT m)` instance doesn't need to modify the action being lifted:

```proofscript
instance : MonadLift m (IdT m) where
  monadLift x := x
```

The `MonadControl` instance is similarly simple.

```proofscript
instance [Monad m] : MonadControl m (IdT m) where
  stM α := α
  liftWith f := f (fun x => Id.run <| pure x)
  restoreM v := v
```

The Lean standard library provides transformer versions of many different monads, including `ReaderT`, `ExceptT`, and `StateT`, along with variants using other representations such as `StateCpsT`, `StateRefT`, and `ExceptCpsT`. Additionally, the `EStateM` monad is equivalent to combining `ExceptT` and `StateT`, but it can use a more specialized representation to improve performance.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--Identity"></a>
### 18.5.3. Identity

The identity monad `Id` has no effects whatsoever. Both `Id` and the corresponding implementation of `pure` are the identity function, and `bind` is reversed function application. The identity monad has two primary use cases:

1. It can be the type of a [`do`](../Syntax/index.md#Lean___Parser___Term___do) block that implements a pure function with local effects.
2. It can be placed at the bottom of a stack of monad transformers.

<a id="Id"></a>

**def**

```text
Id.{u} (type : Type u) : Type u
```

The identity function on types, used primarily for its `Monad` instance.

The identity monad is useful together with monad transformers to construct monads for particular purposes. Additionally, it can be used with `do`-notation in order to use control structures such as local mutability, `for`-loops, and early returns in code that does not otherwise use monads.

Examples:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function containsFive (xs : List Nat) : Bool := Id.run do
  for x in xs do
    if x == 5 then return true
  return false
```

```text
#eval containsFive [1, 3, 5, 7]
```

```proofscript
true
```

<a id="Id___run"></a>

**def**

```text
Id.run.{u_1} {α : Type u_1} (x : Id α) : α
```

Runs a computation in the identity monad.

This function is the identity function. Because its parameter has type `Id α`, it causes `do`-notation in its arguments to use the `Monad Id` instance.

<a id="Local-Effects-with-the-Identity-Monad"></a>
Local Effects with the Identity Monad 

This code block implements a countdown procedure by using simulated local mutability in the identity monad.

```proofscript
#eval Id.run do
  let mut xs := []
  for x in [0:10] do
    xs := x :: xs
  pure xs
```

```lean
[9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
```

<a id="state-monads"></a>
### 18.5.4. State

[State monads](index.md#--tech-term-State-monads) provide access to a mutable value. The underlying implementation may use a tuple to simulate mutability, or it may use something like `ST.Ref` to ensure mutation. Even those implementations that use a tuple may in fact use mutation at run-time due to Lean's use of mutation when there are unique references to values, but this requires a programming style that prefers `modify` and `modifyGet` over `get` and `set`.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--State--General-State-API"></a>
#### 18.5.4.1. General State API

<a id="MonadState___mk"></a>

**type class**

```text
MonadState.{u, v} (σ : outParam (Type u)) (m : Type u → Type v) :
  Type (max (u + 1) v)
```

State monads provide a value of a given type (the *state*) that can be retrieved or replaced. Instances may implement these operations by passing state values around, by using a mutable reference cell (e.g. `ST.Ref σ`), or in other ways.

In this class, `σ` is an `outParam`, which means that it is inferred from `m`. `MonadStateOf σ` provides the same operations, but allows `σ` to influence instance synthesis.

The mutable state of a state monad is visible between multiple `do`-blocks or functions, unlike [local mutable state](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=do-notation-let-mut) in `do`-notation.

**Instance Constructor**

```text
MonadState.mk.{u, v}
```

**Methods**

```text
get : m σ
```

Retrieves the current value of the monad's mutable state.

```text
set : σ → m PUnit
```

Replaces the current value of the mutable state with a new one.

```text
modifyGet : {α : Type u} → (σ → α × σ) → m α
```

Applies a function to the current state that both computes a new state and a value. The new state replaces the current state, and the value is returned.

It is equivalent to `do let (a, s) := f (← get); set s; pure a`. However, using `modifyGet` may lead to higher performance because it doesn't add a new reference to the state value. Additional references can inhibit in-place updates of data.

<a id="MonadState___get"></a>

**def**

```text
MonadState.get.{u, v} {σ : outParam (Type u)} {m : Type u → Type v}
  [self : MonadState σ m] : m σ
```

Retrieves the current value of the monad's mutable state.

<a id="modify"></a>

**def**

```text
modify.{u, v} {σ : Type u} {m : Type u → Type v} [MonadState σ m]
  (f : σ → σ) : m PUnit
```

Mutates the current state, replacing its value with the result of applying `f` to it.

Use `modifyThe` to explicitly select a state type to modify.

It is equivalent to `do set (f (← get))`. However, using `modify` may lead to higher performance because it doesn't add a new reference to the state value. Additional references can inhibit in-place updates of data.

<a id="MonadState___modifyGet"></a>

**def**

```text
MonadState.modifyGet.{u, v} {σ : outParam (Type u)}
  {m : Type u → Type v} [self : MonadState σ m] {α : Type u} :
  (σ → α × σ) → m α
```

Applies a function to the current state that both computes a new state and a value. The new state replaces the current state, and the value is returned.

It is equivalent to `do let (a, s) := f (← get); set s; pure a`. However, using `modifyGet` may lead to higher performance because it doesn't add a new reference to the state value. Additional references can inhibit in-place updates of data.

<a id="getModify"></a>

**def**

```text
getModify.{u, v} {σ : Type u} {m : Type u → Type v} [MonadState σ m]
  (f : σ → σ) : m σ
```

Replaces the state with the result of applying `f` to it. Returns the old value of the state.

It is equivalent to `get <* modify f` but may be more efficient.

<a id="MonadStateOf___mk"></a>

**type class**

```text
MonadStateOf.{u, v} (σ : semiOutParam (Type u)) (m : Type u → Type v) :
  Type (max (u + 1) v)
```

State monads provide a value of a given type (the *state*) that can be retrieved or replaced. Instances may implement these operations by passing state values around, by using a mutable reference cell (e.g. `ST.Ref σ`), or in other ways.

In this class, `σ` is a `semiOutParam`, which means that it can influence the choice of instance. `MonadState σ` provides the same operations, but requires that `σ` be inferable from `m`.

The mutable state of a state monad is visible between multiple `do`-blocks or functions, unlike [local mutable state](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=do-notation-let-mut) in `do`-notation.

**Instance Constructor**

```text
MonadStateOf.mk.{u, v}
```

**Methods**

```text
get : m σ
```

Retrieves the current value of the monad's mutable state.

```text
set : σ → m PUnit
```

Replaces the current value of the mutable state with a new one.

```text
modifyGet : {α : Type u} → (σ → α × σ) → m α
```

Applies a function to the current state that both computes a new state and a value. The new state replaces the current state, and the value is returned.

It is equivalent to `do let (a, s) := f (← get); set s; pure a`. However, using `modifyGet` may lead to higher performance because it doesn't add a new reference to the state value. Additional references can inhibit in-place updates of data.

<a id="getThe"></a>

**def**

```text
getThe.{u, v} (σ : Type u) {m : Type u → Type v} [MonadStateOf σ m] :
  m σ
```

Gets the current state that has the explicitly-provided type `σ`. When the current monad has multiple state types available, this function selects one of them.

<a id="modifyThe"></a>

**def**

```text
modifyThe.{u, v} (σ : Type u) {m : Type u → Type v} [MonadStateOf σ m]
  (f : σ → σ) : m PUnit
```

Mutates the current state that has the explicitly-provided type `σ`, replacing its value with the result of applying `f` to it. When the current monad has multiple state types available, this function selects one of them.

It is equivalent to `do set (f (← get))`. However, using `modify` may lead to higher performance because it doesn't add a new reference to the state value. Additional references can inhibit in-place updates of data.

<a id="modifyGetThe"></a>

**def**

```text
modifyGetThe.{u, v} {α : Type u} (σ : Type u) {m : Type u → Type v}
  [MonadStateOf σ m] (f : σ → α × σ) : m α
```

Applies a function to the current state that has the explicitly-provided type `σ`. The function both computes a new state and a value. The new state replaces the current state, and the value is returned.

It is equivalent to `do let (a, s) := f (← getThe σ); set s; pure a`. However, using `modifyGetThe` may lead to higher performance because it doesn't add a new reference to the state value. Additional references can inhibit in-place updates of data.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--State--Tuple-Based-State-Monads"></a>
#### 18.5.4.2. Tuple-Based State Monads

The tuple-based state monads represent a computation with states that have type `σ` yielding values of type `α` as functions that take a starting state and yield a value paired with a final state, e.g. `σ → α × σ`. The `Monad` operations thread the state correctly through the computation.

<a id="StateM"></a>

**def**

```text
StateM.{u} (σ α : Type u) : Type u
```

A tuple-based state monad.

Actions in `StateM σ` are functions that take an initial state and return a value paired with a final state.

<a id="StateT"></a>

**def**

```text
StateT.{u, v} (σ : Type u) (m : Type u → Type v) (α : Type u) :
  Type (max u v)
```

Adds a mutable state of type `σ` to a monad.

Actions in the resulting monad are functions that take an initial state and return, in `m`, a tuple of a value and a state.

<a id="StateT___run"></a>

**def**

```text
StateT.run.{u, v} {σ : Type u} {m : Type u → Type v} {α : Type u}
  (x : StateT σ m α) (s : σ) : m (α × σ)
```

Executes an action from a monad with added state in the underlying monad `m`. Given an initial state, it returns a value paired with the final state.

<a id="StateT___get"></a>

**def**

```text
StateT.get.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m] :
  StateT σ m σ
```

Retrieves the current value of the monad's mutable state.

This increments the reference count of the state, which may inhibit in-place updates.

<a id="StateT___set"></a>

**def**

```text
StateT.set.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m] :
  σ → StateT σ m PUnit
```

Replaces the mutable state with a new value.

<a id="StateT___orElse"></a>

**def**

```text
StateT.orElse.{u, v} {σ : Type u} {m : Type u → Type v} [Alternative m]
  {α : Type u} (x₁ : StateT σ m α) (x₂ : Unit → StateT σ m α) :
  StateT σ m α
```

Recovers from errors. The state is rolled back on error recovery. Typically used via the `<|>` operator.

<a id="StateT___failure"></a>

**def**

```text
StateT.failure.{u, v} {σ : Type u} {m : Type u → Type v} [Alternative m]
  {α : Type u} : StateT σ m α
```

Fails with a recoverable error. The state is rolled back on error recovery.

<a id="StateT___run___"></a>

**def**

```text
StateT.run'.{u, v} {σ : Type u} {m : Type u → Type v} [Functor m]
  {α : Type u} (x : StateT σ m α) (s : σ) : m α
```

Executes an action from a monad with added state in the underlying monad `m`. Given an initial state, it returns a value, discarding the final state.

<a id="StateT___bind"></a>

**def**

```text
StateT.bind.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m]
  {α β : Type u} (x : StateT σ m α) (f : α → StateT σ m β) :
  StateT σ m β
```

Sequences two actions. Typically used via the `>>=` operator.

<a id="StateT___modifyGet"></a>

**def**

```text
StateT.modifyGet.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m]
  {α : Type u} (f : σ → α × σ) : StateT σ m α
```

Applies a function to the current state that both computes a new state and a value. The new state replaces the current state, and the value is returned.

It is equivalent to `do let (a, s) := f (← StateT.get); StateT.set s; pure a`. However, using `StateT.modifyGet` may lead to better performance because it doesn't add a new reference to the state value, and additional references can inhibit in-place updates of data.

<a id="StateT___lift"></a>

**def**

```text
StateT.lift.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m]
  {α : Type u} (t : m α) : StateT σ m α
```

Runs an action from the underlying monad in the monad with state. The state is not modified.

This function is typically implicitly accessed via a `MonadLiftT` instance as part of [automatic lifting](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=monad-lifting).

<a id="StateT___map"></a>

**def**

```text
StateT.map.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m]
  {α β : Type u} (f : α → β) (x : StateT σ m α) : StateT σ m β
```

Modifies the value returned by a computation. Typically used via the `<$>` operator.

<a id="StateT___pure"></a>

**def**

```text
StateT.pure.{u, v} {σ : Type u} {m : Type u → Type v} [Monad m]
  {α : Type u} (a : α) : StateT σ m α
```

Returns the given value without modifying the state. Typically used via `Pure.pure`.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--State--State-Monads-in-Continuation-Passing-Style"></a>
#### 18.5.4.3. State Monads in Continuation Passing Style

Continuation-passing-style state monads represent stateful computations as functions that, for any type whatsoever, take an initial state and a continuation (modeled as a function) that accepts a value and an updated state. An example of such a type is `(δ : Type u) → σ → (α → σ → δ) → δ`, though `StateCpsT` is a transformer that can be applied to any monad. State monads in continuation passing style have different performance characteristics than tuple-based state monads; for some applications, it may be worth benchmarking them.

<a id="StateCpsT"></a>

**def**

```text
StateCpsT.{u, v} (σ : Type u) (m : Type u → Type v) (α : Type u) :
  Type (max (u + 1) v)
```

An alternative implementation of a state monad transformer that internally uses continuation passing style instead of tuples.

<a id="StateCpsT___lift"></a>

**def**

```text
StateCpsT.lift.{u, v} {α σ : Type u} {m : Type u → Type v} [Monad m]
  (x : m α) : StateCpsT σ m α
```

Runs an action from the underlying monad in the monad with state. The state is not modified.

This function is typically implicitly accessed via a `MonadLiftT` instance as part of [automatic lifting](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=monad-lifting).

<a id="StateCpsT___runK"></a>

**def**

```text
StateCpsT.runK.{u, v} {α σ : Type u} {m : Type u → Type v} {β : Type u}
  (x : StateCpsT σ m α) (s : σ) (k : α → σ → m β) : m β
```

Runs a stateful computation that's represented using continuation passing style by providing it with an initial state and a continuation.

<a id="StateCpsT___run___"></a>

**def**

```text
StateCpsT.run'.{u, v} {α σ : Type u} {m : Type u → Type v} [Monad m]
  (x : StateCpsT σ m α) (s : σ) : m α
```

Executes an action from a monad with added state in the underlying monad `m`. Given an initial state, it returns a value, discarding the final state.

<a id="StateCpsT___run"></a>

**def**

```text
StateCpsT.run.{u, v} {α σ : Type u} {m : Type u → Type v} [Monad m]
  (x : StateCpsT σ m α) (s : σ) : m (α × σ)
```

Executes an action from a monad with added state in the underlying monad `m`. Given an initial state, it returns a value paired with the final state.

While the state is internally represented in continuation passing style, the resulting value is the same as for a non-CPS state monad.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--State--State-Monads-from-Mutable-References"></a>
#### 18.5.4.4. State Monads from Mutable References

The monad `StateRefT σ m` is a specialized state monad transformer that can be used when `m` is a monad to which `ST` computations can be lifted. It implements the operations of `MonadState` using an `ST.Ref`, rather than pure functions. This ensures that mutation is actually used at run time.

`ST` and `EST` require a phantom type parameter that's used together with `runST`'s polymorphic function argument to encapsulate mutability. Rather than require this as a parameter to the transformer, an auxiliary type class `STWorld` is used to propagate it directly from `m`.

The transformer itself is defined as a [syntax extension](../../Notations-and-Macros/Defining-New-Syntax/index.md#syntax-ext) and an [elaborator](../../Notations-and-Macros/Elaborators/index.md#elaborators), rather than an ordinary function. This is because `STWorld` has no methods: it exists only to propagate information from the inner monad to the transformed monad. Nonetheless, its instances are terms; keeping them around could lead to unnecessarily large types.

<a id="STWorld___mk"></a>

**type class**

```text
STWorld (σ : outParam Type) (m : Type → Type) : Type
```

An auxiliary class used to infer the “state” of `EST` and `ST` monads.

**Instance Constructor**

```text
STWorld.mk
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**StateRefT**

The syntax for `StateRefT σ m` accepts two arguments:

<a id="Lean___Parser___Term___stateRefT"></a>

```ebnf
term ::= ...
    | StateRefT term (macroDollarArg
       | term)
```

Its elaborator synthesizes an instance of `STWorld ω m` to ensure that `m` supports mutable references. Having discovered the value of `ω`, it then produces the term `StateRefT' ω σ m`, discarding the synthesized instance.

<a id="StateRefT___"></a>

**def**

```text
StateRefT' (ω σ : Type) (m : Type → Type) (α : Type) : Type
```

A state monad that uses an actual mutable reference cell (i.e. an `ST.Ref ω σ`).

The macro `StateRefT σ m α` infers `ω` from `m`. It should normally be used instead.

<a id="StateRefT______get"></a>

**def**

```text
StateRefT'.get {ω σ : Type} {m : Type → Type} [MonadLiftT (ST ω) m] :
  StateRefT' ω σ m σ
```

Retrieves the current value of the monad's mutable state.

This increments the reference count of the state, which may inhibit in-place updates.

<a id="StateRefT______set"></a>

**def**

```text
StateRefT'.set {ω σ : Type} {m : Type → Type} [MonadLiftT (ST ω) m]
  (s : σ) : StateRefT' ω σ m PUnit
```

Replaces the mutable state with a new value.

<a id="StateRefT______modifyGet"></a>

**def**

```text
StateRefT'.modifyGet {ω σ : Type} {m : Type → Type} {α : Type}
  [MonadLiftT (ST ω) m] (f : σ → α × σ) : StateRefT' ω σ m α
```

Applies a function to the current state that both computes a new state and a value. The new state replaces the current state, and the value is returned.

It is equivalent to a `get` followed by a `set`. However, using `modifyGet` may lead to higher performance because it doesn't add a new reference to the state value. Additional references can inhibit in-place updates of data.

<a id="StateRefT______run"></a>

**def**

```text
StateRefT'.run {ω σ : Type} {m : Type → Type} [Monad m]
  [MonadLiftT (ST ω) m] {α : Type} (x : StateRefT' ω σ m α) (s : σ) :
  m (α × σ)
```

Executes an action from a monad with added state in the underlying monad `m`. Given an initial state, it returns a value paired with the final state.

The monad `m` must support `ST` effects in order to create and mutate reference cells.

<a id="StateRefT______run___"></a>

**def**

```text
StateRefT'.run' {ω σ : Type} {m : Type → Type} [Monad m]
  [MonadLiftT (ST ω) m] {α : Type} (x : StateRefT' ω σ m α) (s : σ) :
  m α
```

Executes an action from a monad with added state in the underlying monad `m`. Given an initial state, it returns a value, discarding the final state.

The monad `m` must support `ST` effects in order to create and mutate reference cells.

<a id="StateRefT______lift"></a>

**def**

```text
StateRefT'.lift {ω σ : Type} {m : Type → Type} {α : Type} (x : m α) :
  StateRefT' ω σ m α
```

Runs an action from the underlying monad in the monad with state. The state is not modified.

This function is typically implicitly accessed via a `MonadLiftT` instance as part of [automatic lifting](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=monad-lifting).

<a id="reader-monad"></a>
### 18.5.5. Reader

<a id="MonadReader___mk"></a>

**type class**

```text
MonadReader.{u, v} (ρ : outParam (Type u)) (m : Type u → Type v) :
  Type v
```

Reader monads provide the ability to implicitly thread a value through a computation. The value can be read, but not written. A `MonadWithReader ρ` instance additionally allows the value to be locally overridden for a sub-computation.

In this class, `ρ` is an `outParam`, which means that it is inferred from `m`. `MonadReaderOf ρ` provides the same operations, but allows `ρ` to influence instance synthesis.

**Instance Constructor**

```text
MonadReader.mk.{u, v}
```

**Methods**

```text
read : m ρ
```

Retrieves the local value.

Use `readThe` to explicitly specify a type when more than one value is available.

<a id="MonadReaderOf___mk"></a>

**type class**

```text
MonadReaderOf.{u, v} (ρ : semiOutParam (Type u)) (m : Type u → Type v) :
  Type v
```

Reader monads provide the ability to implicitly thread a value through a computation. The value can be read, but not written. A `MonadWithReader ρ` instance additionally allows the value to be locally overridden for a sub-computation.

In this class, `ρ` is a `semiOutParam`, which means that it can influence the choice of instance. `MonadReader ρ` provides the same operations, but requires that `ρ` be inferable from `m`.

**Instance Constructor**

```text
MonadReaderOf.mk.{u, v}
```

**Methods**

```text
read : m ρ
```

Retrieves the local value.

<a id="readThe"></a>

**def**

```text
readThe.{u, v} (ρ : Type u) {m : Type u → Type v} [MonadReaderOf ρ m] :
  m ρ
```

Retrieves the local value whose type is `ρ`. This is useful when a monad supports reading more than one type of value.

Use `read` for a version that expects the type `ρ` to be inferred from `m`.

<a id="MonadWithReader___mk"></a>

**type class**

```text
MonadWithReader.{u, v} (ρ : outParam (Type u)) (m : Type u → Type v) :
  Type (max (u + 1) v)
```

A reader monad that additionally allows the value to be locally overridden.

In this class, `ρ` is an `outParam`, which means that it is inferred from `m`. `MonadWithReaderOf ρ` provides the same operations, but allows `ρ` to influence instance synthesis.

**Instance Constructor**

```text
MonadWithReader.mk.{u, v}
```

**Methods**

```text
withReader : {α : Type u} → (ρ → ρ) → m α → m α
```

Locally modifies the reader monad's value while running an action.

During the inner action `x`, reading the value returns `f` applied to the original value. After control returns from `x`, the reader monad's value is restored.

<a id="MonadWithReaderOf___mk"></a>

**type class**

```text
MonadWithReaderOf.{u, v} (ρ : semiOutParam (Type u))
  (m : Type u → Type v) : Type (max (u + 1) v)
```

A reader monad that additionally allows the value to be locally overridden.

In this class, `ρ` is a `semiOutParam`, which means that it can influence the choice of instance. `MonadWithReader ρ` provides the same operations, but requires that `ρ` be inferable from `m`.

**Instance Constructor**

```text
MonadWithReaderOf.mk.{u, v}
```

**Methods**

```text
withReader : {α : Type u} → (ρ → ρ) → m α → m α
```

Locally modifies the reader monad's value while running an action.

During the inner action `x`, reading the value returns `f` applied to the original value. After control returns from `x`, the reader monad's value is restored.

<a id="withTheReader"></a>

**def**

```text
withTheReader.{u, v} (ρ : Type u) {m : Type u → Type v}
  [MonadWithReaderOf ρ m] {α : Type u} (f : ρ → ρ) (x : m α) : m α
```

Locally modifies the reader monad's value while running an action, with the reader monad's local value type specified explicitly. This is useful when a monad supports reading more than one type of value.

During the inner action `x`, reading the value returns `f` applied to the original value. After control returns from `x`, the reader monad's value is restored.

Use `withReader` for a version that expects the local value's type to be inferred from `m`.

<a id="ReaderT"></a>

**def**

```text
ReaderT.{u, v} (ρ : Type u) (m : Type u → Type v) (α : Type u) :
  Type (max u v)
```

Adds the ability to access a read-only value of type `ρ` to a monad. The value can be locally overridden by `withReader`, but it cannot be mutated.

Actions in the resulting monad are functions that take the local value as a parameter, returning ordinary actions in `m`.

<a id="ReaderM"></a>

**def**

```text
ReaderM.{u} (ρ α : Type u) : Type u
```

A monad with access to a read-only value of type `ρ`. The value can be locally overridden by `withReader`, but it cannot be mutated.

<a id="ReaderT___run"></a>

**def**

```text
ReaderT.run.{u, v} {ρ : Type u} {m : Type u → Type v} {α : Type u}
  (x : ReaderT ρ m α) (r : ρ) : m α
```

Executes an action from a monad with a read-only value in the underlying monad `m`.

<a id="ReaderT___read"></a>

**def**

```text
ReaderT.read.{u, v} {ρ : Type u} {m : Type u → Type v} [Monad m] :
  ReaderT ρ m ρ
```

Retrieves the reader monad's local value. Typically accessed via `read`, or via `readThe` when more than one local value is available.

<a id="ReaderT___adapt"></a>

**def**

```text
ReaderT.adapt.{u, v} {ρ : Type u} {m : Type u → Type v} {ρ' α : Type u}
  (f : ρ' → ρ) : ReaderT ρ m α → ReaderT ρ' m α
```

Modifies a reader monad's local value with `f`. The resulting computation applies `f` to the incoming local value and passes the result to the inner computation.

<a id="ReaderT___pure"></a>

**def**

```text
ReaderT.pure.{u, v} {ρ : Type u} {m : Type u → Type v} [Monad m]
  {α : Type u} (a : α) : ReaderT ρ m α
```

Returns the provided value `a`, ignoring the reader monad's local value. Typically used via `Pure.pure`.

<a id="ReaderT___bind"></a>

**def**

```text
ReaderT.bind.{u, v} {ρ : Type u} {m : Type u → Type v} [Monad m]
  {α β : Type u} (x : ReaderT ρ m α) (f : α → ReaderT ρ m β) :
  ReaderT ρ m β
```

Sequences two reader monad computations. Both are provided with the local value, and the second is passed the value of the first. Typically used via the `>>=` operator.

<a id="ReaderT___orElse"></a>

**def**

```text
ReaderT.orElse.{u_1, u_2} {m : Type u_1 → Type u_2} {ρ α : Type u_1}
  [Alternative m] (x₁ : ReaderT ρ m α) (x₂ : Unit → ReaderT ρ m α) :
  ReaderT ρ m α
```

Recovers from errors. The same local value is provided to both branches. Typically used via the `<|>` operator.

<a id="ReaderT___failure"></a>

**def**

```text
ReaderT.failure.{u_1, u_2} {m : Type u_1 → Type u_2} {ρ α : Type u_1}
  [Alternative m] : ReaderT ρ m α
```

Fails with a recoverable error.

<a id="option-monad"></a>
### 18.5.6. Option

Ordinarily, `Option` is thought of as data, similarly to a nullable type. It can also be considered as a monad, and thus a way of performing computations. The `Option` monad and its transformer `OptionT` can be understood as describing computations that may terminate early, discarding the results. Callers can check for early termination and invoke a fallback if desired using `OrElse.orElse` or by treating it as a `MonadExcept Unit`.

<a id="OptionT"></a>

**def**

```text
OptionT.{u, v} (m : Type u → Type v) (α : Type u) : Type v
```

Adds the ability to fail to a monad. Unlike ordinary exceptions, there is no way to signal why a failure occurred.

<a id="OptionT___run"></a>

**def**

```text
OptionT.run.{u, v} {m : Type u → Type v} {α : Type u}
  (x : OptionT m α) : m (Option α)
```

Executes an action that might fail in the underlying monad `m`, returning `none` in case of failure.

<a id="OptionT___lift"></a>

**def**

```text
OptionT.lift.{u, v} {m : Type u → Type v} [Monad m] {α : Type u}
  (x : m α) : OptionT m α
```

Converts a computation from the underlying monad into one that could fail, even though it does not.

This function is typically implicitly accessed via a `MonadLiftT` instance as part of [automatic lifting](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=monad-lifting).

<a id="OptionT___mk"></a>

**def**

```text
OptionT.mk.{u, v} {m : Type u → Type v} {α : Type u}
  (x : m (Option α)) : OptionT m α
```

Converts an action that returns an `Option` into one that might fail, with `none` indicating failure.

<a id="OptionT___pure"></a>

**def**

```text
OptionT.pure.{u, v} {m : Type u → Type v} [Monad m] {α : Type u}
  (a : α) : OptionT m α
```

Succeeds with the provided value.

<a id="OptionT___bind"></a>

**def**

```text
OptionT.bind.{u, v} {m : Type u → Type v} [Monad m] {α β : Type u}
  (x : OptionT m α) (f : α → OptionT m β) : OptionT m β
```

Sequences two potentially-failing actions. The second action is run only if the first succeeds.

<a id="OptionT___fail"></a>

**def**

```text
OptionT.fail.{u, v} {m : Type u → Type v} [Monad m] {α : Type u} :
  OptionT m α
```

A recoverable failure.

<a id="OptionT___orElse"></a>

**def**

```text
OptionT.orElse.{u, v} {m : Type u → Type v} [Monad m] {α : Type u}
  (x : OptionT m α) (y : Unit → OptionT m α) : OptionT m α
```

Recovers from failures. Typically used via the `<|>` operator.

<a id="OptionT___tryCatch"></a>

**def**

```text
OptionT.tryCatch.{u, v, u_1} {m : Type u → Type v} [Monad m]
  {α : Type u} (x : OptionT m α) (handle : PUnit → OptionT m α) :
  OptionT m α
```

Handles failures by treating them as exceptions of type `Unit`.

<a id="exception-monads"></a>
### 18.5.7. Exceptions

Exception monads describe computations that terminate early (fail). Failing computations provide their caller with an *exception* value that describes *why* they failed. In other words, computations either return a value or an exception. The inductive type `Except` captures this pattern, and is itself a monad.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--Exceptions--Exceptions"></a>
#### 18.5.7.1. Exceptions

<a id="Except___error"></a>

**inductive type**

```text
Except.{u, v} (ε : Type u) (α : Type v) : Type (max u v)
```

`Except ε α` is a type which represents either an error of type `ε` or a successful result with a value of type `α`.

`Except ε : Type u → Type v` is a `Monad` that represents computations that may throw exceptions: the `pure` operation is `Except.ok` and the `bind` operation returns the first encountered `Except.error`.

**Constructors**

```text
Except.error.{u, v} {ε : Type u} {α : Type v} :
  ε → Except ε α
```

A failure value of type `ε`

```text
Except.ok.{u, v} {ε : Type u} {α : Type v} : α → Except ε α
```

A success value of type `α`

<a id="Except___pure"></a>

**def**

```text
Except.pure.{u, u_1} {ε : Type u} {α : Type u_1} (a : α) : Except ε α
```

A successful computation in the `Except ε` monad: `a` is returned, and no exception is thrown.

<a id="Except___bind"></a>

**def**

```text
Except.bind.{u, u_1, u_2} {ε : Type u} {α : Type u_1} {β : Type u_2}
  (ma : Except ε α) (f : α → Except ε β) : Except ε β
```

Sequences two operations that may throw exceptions, allowing the second to depend on the value returned by the first.

If the first operation throws an exception, then it is the result of the computation. If the first succeeds but the second throws an exception, then that exception is the result. If both succeed, then the result is the result of the second computation.

This is the implementation of the `>>=` operator for `Except ε`.

<a id="Except___map"></a>

**def**

```text
Except.map.{u, u_1, u_2} {ε : Type u} {α : Type u_1} {β : Type u_2}
  (f : α → β) : Except ε α → Except ε β
```

Transforms a successful result with a function, doing nothing when an exception is thrown.

Examples:

- `(pure 2 : Except String Nat).map toString = pure "2"`
- `(throw "Error" : Except String Nat).map toString = throw "Error"`

<a id="Except___mapError"></a>

**def**

```text
Except.mapError.{u, u_1, u_2} {ε : Type u} {ε' : Type u_1}
  {α : Type u_2} (f : ε → ε') : Except ε α → Except ε' α
```

Transforms exceptions with a function, doing nothing on successful results.

Examples:

- `(pure 2 : Except String Nat).mapError (·.length) = pure 2`
- `(throw "Error" : Except String Nat).mapError (·.length) = throw 5`

<a id="Except___tryCatch"></a>

**def**

```text
Except.tryCatch.{u, u_1} {ε : Type u} {α : Type u_1} (ma : Except ε α)
  (handle : ε → Except ε α) : Except ε α
```

Handles exceptions thrown in the `Except ε` monad.

If `ma` is successful, its result is returned. If it throws an exception, then `handle` is invoked on the exception's value.

Examples:

- `(pure 2 : Except String Nat).tryCatch (pure ·.length) = pure 2`
- `(throw "Error" : Except String Nat).tryCatch (pure ·.length) = pure 5`
- `(throw "Error" : Except String Nat).tryCatch (fun x => throw ("E: " ++ x)) = throw "E: Error"`

<a id="Except___orElseLazy"></a>

**def**

```text
Except.orElseLazy.{u, u_1} {ε : Type u} {α : Type u_1} (x : Except ε α)
  (y : Unit → Except ε α) : Except ε α
```

Recovers from exceptions thrown in the `Except ε` monad. Typically used via the `<|>` operator.

`Except.tryCatch` is a related operator that allows the recovery procedure to depend on *which* exception was thrown.

<a id="Except___isOk"></a>

**def**

```text
Except.isOk.{u, u_1} {ε : Type u} {α : Type u_1} : Except ε α → Bool
```

Returns `true` if the value is `Except.ok`, `false` otherwise.

<a id="Except___toOption"></a>

**def**

```text
Except.toOption.{u, u_1} {ε : Type u} {α : Type u_1} :
  Except ε α → Option α
```

Returns `none` if an exception was thrown, or `some` around the value on success.

Examples:

- `(pure 10 : Except String Nat).toOption = some 10`
- `(throw "Failure" : Except String Nat).toOption = none`

<a id="Except___toBool"></a>

**def**

```text
Except.toBool.{u, u_1} {ε : Type u} {α : Type u_1} : Except ε α → Bool
```

Returns `true` if the value is `Except.ok`, `false` otherwise.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--Exceptions--Type-Class"></a>
#### 18.5.7.2. Type Class

<a id="MonadExcept___mk"></a>

**type class**

```text
MonadExcept.{u, v, w} (ε : outParam (Type u)) (m : Type v → Type w) :
  Type (max (max u (v + 1)) w)
```

Exception monads provide the ability to throw errors and handle errors.

In this class, `ε` is an `outParam`, which means that it is inferred from `m`. `MonadExceptOf ε` provides the same operations, but allows `ε` to influence instance synthesis.

`MonadExcept.tryCatch` is used to desugar `try ... catch ...` steps inside `do`-blocks when the handlers do not have exception type annotations.

**Instance Constructor**

```text
MonadExcept.mk.{u, v, w}
```

**Methods**

```text
throw : {α : Type v} → ε → m α
```

Throws an exception of type `ε` to the nearest enclosing handler.

```text
tryCatch : {α : Type v} → m α → (ε → m α) → m α
```

Catches errors thrown in `body`, passing them to `handler`. Errors in `handler` are not caught.

<a id="MonadExcept___ofExcept"></a>

**def**

```text
MonadExcept.ofExcept.{u_1, u_2, u_3} {m : Type u_1 → Type u_2}
  {ε : Type u_3} {α : Type u_1} [Monad m] [MonadExcept ε m] :
  Except ε α → m α
```

Re-interprets an `Except ε` action in an exception monad `m`, succeeding if it succeeds and throwing an exception if it throws an exception.

<a id="MonadExcept___orElse"></a>

**def**

```text
MonadExcept.orElse.{u, v, w} {ε : Type u} {m : Type v → Type w}
  [MonadExcept ε m] {α : Type v} (t₁ : m α) (t₂ : Unit → m α) : m α
```

Unconditional error recovery that ignores which exception was thrown. Usually used via the `<|>` operator.

If both computations throw exceptions, then the result is the second exception.

<a id="MonadExcept___orelse___"></a>

**def**

```text
MonadExcept.orelse'.{u, v, w} {ε : Type u} {m : Type v → Type w}
  [MonadExcept ε m] {α : Type v} (t₁ t₂ : m α)
  (useFirstEx : Bool := true) : m α
```

An alternative unconditional error recovery operator that allows callers to specify which exception to throw in cases where both operations throw exceptions.

By default, the first is thrown, because the `<|>` operator throws the second.

<a id="MonadExceptOf___mk"></a>

**type class**

```text
MonadExceptOf.{u, v, w} (ε : semiOutParam (Type u))
  (m : Type v → Type w) : Type (max (max u (v + 1)) w)
```

Exception monads provide the ability to throw errors and handle errors.

In this class, `ε` is a `semiOutParam`, which means that it can influence the choice of instance. `MonadExcept ε` provides the same operations, but requires that `ε` be inferable from `m`.

`tryCatchThe`, which takes an explicit exception type, is used to desugar `try ... catch ...` steps inside `do`-blocks when the handlers have type annotations.

**Instance Constructor**

```text
MonadExceptOf.mk.{u, v, w}
```

**Methods**

```text
throw : {α : Type v} → ε → m α
```

Throws an exception of type `ε` to the nearest enclosing `catch`.

```text
tryCatch : {α : Type v} → m α → (ε → m α) → m α
```

Catches errors thrown in `body`, passing them to `handler`. Errors in `handler` are not caught.

<a id="throwThe"></a>

**def**

```text
throwThe.{u, v, w} (ε : Type u) {m : Type v → Type w}
  [MonadExceptOf ε m] {α : Type v} (e : ε) : m α
```

Throws an exception, with the exception type specified explicitly. This is useful when a monad supports throwing more than one type of exception.

Use `throw` for a version that expects the exception type to be inferred from `m`.

<a id="tryCatchThe"></a>

**def**

```text
tryCatchThe.{u, v, w} (ε : Type u) {m : Type v → Type w}
  [MonadExceptOf ε m] {α : Type v} (x : m α) (handle : ε → m α) : m α
```

Catches errors, recovering using `handle`. The exception type is specified explicitly. This is useful when a monad supports throwing or handling more than one type of exception.

Use `tryCatch`, for a version that expects the exception type to be inferred from `m`.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--Exceptions--___Finally___-Computations"></a>
#### 18.5.7.3. “Finally” Computations

<a id="MonadFinally___mk"></a>

**type class**

```text
MonadFinally.{u, v} (m : Type u → Type v) : Type (max (u + 1) v)
```

Monads that provide the ability to ensure an action happens, regardless of exceptions or other failures.

`MonadFinally.tryFinally'` is used to desugar `try ... finally ...` syntax.

**Instance Constructor**

```text
MonadFinally.mk.{u, v}
```

**Methods**

```text
tryFinally' : {α β : Type u} → m α → (Option α → m β) → m (α × β)
```

Runs an action, ensuring that some other action always happens afterward.

More specifically, `tryFinally' x f` runs `x` and then the “finally” computation `f`. If `x` succeeds with some value `a : α`, `f (some a)` is returned. If `x` fails for `m`'s definition of failure, `f none` is returned.

`tryFinally'` can be thought of as performing the same role as a `finally` block in an imperative programming language.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--Exceptions--Transformer"></a>
#### 18.5.7.4. Transformer

<a id="ExceptT"></a>

**def**

```text
ExceptT.{u, v} (ε : Type u) (m : Type u → Type v) (α : Type u) : Type v
```

Adds exceptions of type `ε` to a monad `m`.

<a id="ExceptT___lift"></a>

**def**

```text
ExceptT.lift.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m]
  {α : Type u} (t : m α) : ExceptT ε m α
```

Runs a computation from an underlying monad in the transformed monad with exceptions.

<a id="ExceptT___run"></a>

**def**

```text
ExceptT.run.{u, v} {ε : Type u} {m : Type u → Type v} {α : Type u}
  (x : ExceptT ε m α) : m (Except ε α)
```

Use a monadic action that may throw an exception as an action that may return an exception's value.

This is the inverse of `ExceptT.mk`.

<a id="ExceptT___pure"></a>

**def**

```text
ExceptT.pure.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m]
  {α : Type u} (a : α) : ExceptT ε m α
```

Returns the value `a` without throwing exceptions or having any other effect.

<a id="ExceptT___bind"></a>

**def**

```text
ExceptT.bind.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m]
  {α β : Type u} (ma : ExceptT ε m α) (f : α → ExceptT ε m β) :
  ExceptT ε m β
```

Sequences two actions that may throw exceptions. Typically used via `do`-notation or the `>>=` operator.

<a id="ExceptT___bindCont"></a>

**def**

```text
ExceptT.bindCont.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m]
  {α β : Type u} (f : α → ExceptT ε m β) : Except ε α → m (Except ε β)
```

Handles exceptions thrown by an action that can have no effects *other* than throwing exceptions.

<a id="ExceptT___tryCatch"></a>

**def**

```text
ExceptT.tryCatch.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m]
  {α : Type u} (ma : ExceptT ε m α) (handle : ε → ExceptT ε m α) :
  ExceptT ε m α
```

Handles exceptions produced in the `ExceptT ε` transformer.

<a id="ExceptT___mk"></a>

**def**

```text
ExceptT.mk.{u, v} {ε : Type u} {m : Type u → Type v} {α : Type u}
  (x : m (Except ε α)) : ExceptT ε m α
```

Use a monadic action that may return an exception's value as an action in the transformed monad that may throw the corresponding exception.

This is the inverse of `ExceptT.run`.

<a id="ExceptT___map"></a>

**def**

```text
ExceptT.map.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m]
  {α β : Type u} (f : α → β) (x : ExceptT ε m α) : ExceptT ε m β
```

Transforms a successful computation's value using `f`. Typically used via the `<$>` operator.

<a id="ExceptT___adapt"></a>

**def**

```text
ExceptT.adapt.{u, v} {ε : Type u} {m : Type u → Type v} [Monad m]
  {ε' α : Type u} (f : ε → ε') : ExceptT ε m α → ExceptT ε' m α
```

Transforms exceptions using the function `f`.

This is the `ExceptT` version of `Except.mapError`.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--Exceptions--Exception-Monads-in-Continuation-Passing-Style"></a>
#### 18.5.7.5. Exception Monads in Continuation Passing Style

Continuation-passing-style exception monads represent potentially-failing computations as functions that take success and failure continuations, both of which return the same type, returning that type. They must work for *any* return type. An example of such a type is `(β : Type u) → (α → β) → (ε → β) → β`. `ExceptCpsT` is a transformer that can be applied to any monad, so `ExceptCpsT ε m α` is actually defined as `(β : Type u) → (α → m β) → (ε → m β) → m β`. Exception monads in continuation passing style have different performance characteristics than `Except`-based state monads; for some applications, it may be worth benchmarking them.

<a id="ExceptCpsT"></a>

**def**

```text
ExceptCpsT.{u, v} (ε : Type u) (m : Type u → Type v) (α : Type u) :
  Type (max (u + 1) v)
```

Adds exceptions of type `ε` to a monad `m`.

Instead of using `Except ε` to model exceptions, this implementation uses continuation passing style. This has different performance characteristics from `ExceptT ε`.

<a id="ExceptCpsT___runCatch"></a>

**def**

```text
ExceptCpsT.runCatch.{u_1, u_2} {m : Type u_1 → Type u_2} {α : Type u_1}
  [Monad m] (x : ExceptCpsT α m α) : m α
```

Returns the value of a computation, forgetting whether it was an exception or a success.

This corresponds to early return.

<a id="ExceptCpsT___runK"></a>

**def**

```text
ExceptCpsT.runK.{u, u_1} {m : Type u → Type u_1} {β ε α : Type u}
  (x : ExceptCpsT ε m α) (ok : α → m β) (error : ε → m β) : m β
```

Use a monadic action that may throw an exception by providing explicit success and failure continuations.

<a id="ExceptCpsT___run"></a>

**def**

```text
ExceptCpsT.run.{u, u_1} {m : Type u → Type u_1} {ε α : Type u} [Monad m]
  (x : ExceptCpsT ε m α) : m (Except ε α)
```

Use a monadic action that may throw an exception as an action that may return an exception's value.

<a id="ExceptCpsT___lift"></a>

**def**

```text
ExceptCpsT.lift.{u_1, u_2} {m : Type u_1 → Type u_2} {α ε : Type u_1}
  [Monad m] (x : m α) : ExceptCpsT ε m α
```

Run an action from the transformed monad in the exception monad.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--Combined-Error-and-State-Monads"></a>
### 18.5.8. Combined Error and State Monads

The `EStateM` monad has both exceptions and mutable state. `EStateM ε σ α` is logically equivalent to `ExceptT ε (StateM σ) α`. While `ExceptT ε (StateM σ)` evaluates to the type `σ → Except ε α × σ`, the type `EStateM ε σ α` evaluates to `σ → EStateM.Result ε σ α`. `EStateM.Result` is an inductive type that's very similar to `Except`, except both constructors have an additional field for the state. In compiled code, this representation removes one level of indirection from each monadic bind.

<a id="EStateM"></a>

**def**

```text
EStateM.{u} (ε σ α : Type u) : Type u
```

A combined state and exception monad in which exceptions do not automatically roll back the state.

Instances of `EStateM.Backtrackable` provide a way to roll back some part of the state if needed.

`EStateM ε σ` is equivalent to `ExceptT ε (StateM σ)`, but it is more efficient.

<a id="EStateM___Result___ok"></a>

**inductive type**

```text
EStateM.Result.{u} (ε σ α : Type u) : Type u
```

The value returned from a combined state and exception monad in which exceptions do not automatically roll back the state.

`Result ε σ α` is equivalent to `Except ε α × σ`, but using a single combined inductive type yields a more efficient data representation.

**Constructors**

```text
EStateM.Result.ok.{u} {ε σ α : Type u} :
  α → σ → EStateM.Result ε σ α
```

A success value of type `α` and a new state `σ`.

```text
EStateM.Result.error.{u} {ε σ α : Type u} :
  ε → σ → EStateM.Result ε σ α
```

An exception of type `ε` and a new state `σ`.

<a id="EStateM___run"></a>

**def**

```text
EStateM.run.{u} {ε σ α : Type u} (x : EStateM ε σ α) (s : σ) :
  EStateM.Result ε σ α
```

Executes an `EStateM` action with the initial state `s`. The returned value includes the final state and indicates whether an exception was thrown or a value was returned.

<a id="EStateM___run___"></a>

**def**

```text
EStateM.run'.{u} {ε σ α : Type u} (x : EStateM ε σ α) (s : σ) : Option α
```

Executes an `EStateM` with the initial state `s` for the returned value `α`, discarding the final state. Returns `none` if an unhandled exception was thrown.

<a id="EStateM___adaptExcept"></a>

**def**

```text
EStateM.adaptExcept.{u} {ε σ α ε' : Type u} (f : ε → ε')
  (x : EStateM ε σ α) : EStateM ε' σ α
```

Transforms exceptions with a function, doing nothing on successful results.

<a id="EStateM___fromStateM"></a>

**def**

```text
EStateM.fromStateM {ε σ α : Type} (x : StateM σ α) : EStateM ε σ α
```

Converts a state monad action into a state monad action with exceptions.

The resulting action does not throw an exception.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--Combined-Error-and-State-Monads--State-Rollback"></a>
#### 18.5.8.1. State Rollback

Composing `StateT` and `ExceptT` in different orders causes exceptions to interact differently with state. In one ordering, state changes are rolled back when exceptions are caught; in the other, they persist. The latter option matches the semantics of most imperative programming languages, but the former is very useful for search-based problems. Often, some but not all state should be rolled back; this can be achieved by “sandwiching” `ExceptT` between two separate uses of `StateT`.

To avoid yet another layer of indirection via the use of `StateT σ (EStateM ε σ') α`, `EStateM` offers the `EStateM.Backtrackable` [type class](../../Type-Classes/index.md#--tech-term-type-class). This class specifies some part of the state that can be saved and restored. `EStateM` then arranges for the saving and restoring to take place around error handling.

<a id="EStateM___Backtrackable___mk"></a>

**type class**

```text
EStateM.Backtrackable.{u} (δ : outParam (Type u)) (σ : Type u) : Type u
```

Exception handlers in `EStateM` save some part of the state, determined by `δ`, and restore it if an exception is caught. By default, `δ` is `Unit`, and no information is saved.

**Instance Constructor**

```text
EStateM.Backtrackable.mk.{u}
```

**Methods**

```text
save : σ → δ
```

Extracts the information in the state that should be rolled back if an exception is handled.

```text
restore : σ → δ → σ
```

Updates the current state with the saved information that should be rolled back. This updated state becomes the current state when an exception is handled.

There is a universally-applicable instance of `Backtrackable` that neither saves nor restores anything. Because instance synthesis chooses the most recent instance first, the universal instance is used only if no other instance has been defined.

<a id="EStateM___nonBacktrackable"></a>

**def**

```text
EStateM.nonBacktrackable.{u} {σ : Type u} :
  EStateM.Backtrackable PUnit σ
```

A fallback `Backtrackable` instance that saves no information from a state. This allows every type to be used as a state in `EStateM`, with no rollback.

Because this is the first declared instance of `Backtrackable _ σ`, it will be picked only if there are no other `Backtrackable _ σ` instances registered.

<a id="The-Lean-Language-Reference--Functors___-Monads-and--do--Notation--Varieties-of-Monads--Combined-Error-and-State-Monads--Implementations"></a>
#### 18.5.8.2. Implementations

These functions are typically not called directly, but rather are accessed through their corresponding type classes.

<a id="EStateM___map"></a>

**def**

```text
EStateM.map.{u} {ε σ α β : Type u} (f : α → β) (x : EStateM ε σ α) :
  EStateM ε σ β
```

Transforms the value returned from an `EStateM ε σ` action using a function.

<a id="EStateM___pure"></a>

**def**

```text
EStateM.pure.{u} {ε σ α : Type u} (a : α) : EStateM ε σ α
```

Returns a value without modifying the state or throwing an exception.

<a id="EStateM___bind"></a>

**def**

```text
EStateM.bind.{u} {ε σ α β : Type u} (x : EStateM ε σ α)
  (f : α → EStateM ε σ β) : EStateM ε σ β
```

Sequences two `EStateM ε σ` actions, passing the returned value from the first into the second.

<a id="EStateM___orElse"></a>

**def**

```text
EStateM.orElse.{u} {ε σ α δ : Type u} [EStateM.Backtrackable δ σ]
  (x₁ : EStateM ε σ α) (x₂ : Unit → EStateM ε σ α) : EStateM ε σ α
```

Failure handling that does not depend on specific exception values.

The `Backtrackable δ σ` instance is used to save a snapshot of part of the state prior to running `x₁`. If an exception is caught, the state is updated with the saved snapshot, rolling back part of the state. If no instance of `Backtrackable` is provided, a fallback instance in which `δ` is `Unit` is used, and no information is rolled back.

<a id="EStateM___orElse___"></a>

**def**

```text
EStateM.orElse'.{u} {ε σ α δ : Type u} [EStateM.Backtrackable δ σ]
  (x₁ x₂ : EStateM ε σ α) (useFirstEx : Bool := true) : EStateM ε σ α
```

Alternative orElse operator that allows callers to select which exception should be used when both operations fail. The default is to use the first exception since the standard `orElse` uses the second.

<a id="EStateM___seqRight"></a>

**def**

```text
EStateM.seqRight.{u} {ε σ α β : Type u} (x : EStateM ε σ α)
  (y : Unit → EStateM ε σ β) : EStateM ε σ β
```

Sequences two `EStateM ε σ` actions, running `x` before `y`. The first action's return value is ignored.

<a id="EStateM___tryCatch"></a>

**def**

```text
EStateM.tryCatch.{u} {ε σ δ : Type u} [EStateM.Backtrackable δ σ]
  {α : Type u} (x : EStateM ε σ α) (handle : ε → EStateM ε σ α) :
  EStateM ε σ α
```

Handles exceptions thrown in the combined error and state monad.

The `Backtrackable δ σ` instance is used to save a snapshot of part of the state prior to running `x`. If an exception is caught, the state is updated with the saved snapshot, rolling back part of the state. If no instance of `Backtrackable` is provided, a fallback instance in which `δ` is `Unit` is used, and no information is rolled back.

<a id="EStateM___throw"></a>

**def**

```text
EStateM.throw.{u} {ε σ α : Type u} (e : ε) : EStateM ε σ α
```

Throws an exception of type `ε` to the nearest enclosing handler.

<a id="EStateM___get"></a>

**def**

```text
EStateM.get.{u} {ε σ : Type u} : EStateM ε σ σ
```

Retrieves the current value of the monad's mutable state.

<a id="EStateM___set"></a>

**def**

```text
EStateM.set.{u} {ε σ : Type u} (s : σ) : EStateM ε σ PUnit
```

Replaces the current value of the mutable state with a new one.

<a id="EStateM___modifyGet"></a>

**def**

```text
EStateM.modifyGet.{u} {ε σ α : Type u} (f : σ → α × σ) : EStateM ε σ α
```

Applies a function to the current state that both computes a new state and a value. The new state replaces the current state, and the value is returned.

It is equivalent to `do let (a, s) := f (← get); set s; pure a`. However, using `modifyGet` may lead to higher performance because it doesn't add a new reference to the state value. Additional references can inhibit in-place updates of data.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
A state monad that uses an actual mutable reference cell (i.e. an `ST.Ref`).

This is syntax, rather than a function, to make it easier to use. Its elaborator synthesizes an
appropriate parameter for the underlying monad's `ST` effects, then passes it to `StateRefT'`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
(Except.error "Five was encountered", 10)
```


### Display 2


```text
Except.error "Five was encountered"
```


### Display 3


```text
Except.ok 10
```


### Display 4


```text
Except.ok 0
```


### Display 5


```text
get : M Nat
```


### Display 6


```text
failed to synthesize instance of type class
  MonadState String M

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 7


```text
(getThe String, getThe Nat) : M String × M Nat
```


### Display 8


```text
set 4 : M PUnit
```


### Display 9


```text
set "Four" : M PUnit
```


### Display 10


```text
[9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
```

