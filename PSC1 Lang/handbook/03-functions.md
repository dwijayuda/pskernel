# Functions

Functions are PSC1's primary abstraction mechanism.

PSC1 deliberately prefers functions and data over adding many specialized
language constructs.

## Named functions

```proofscript
function add(x : Nat, y : Nat) : Nat :=
  x + y;
```

The declaration includes:

- the function name;
- explicit parameters;
- each parameter type;
- result type;
- body.

`function` is source sugar for the ordinary definition mechanism.

## Canonical `def`

The same semantic family can be written:

```proofscript
def add(x : Nat, y : Nat) : Nat :=
  x + y;
```

Canonical source translation is allowed to normalize a `function` declaration
to `def`.

## Anonymous functions

```proofscript
fun x => x + 1
```

or with an explicit type:

```proofscript
fun (x : Nat) => x + 1
```

PSC1 deliberately keeps `fun` rather than borrowing JavaScript arrow syntax.

The reason is semantic clarity: this is a lambda in the dependent function
system.

## Function values

A function is a value and may be stored or passed.

```proofscript
const increment : Nat -> Nat :=
  fun x => x + 1;
```

## Higher-order functions

```proofscript
function applyTwice(
  f : Nat -> Nat,
  x : Nat
) : Nat :=
  f(f(x));
```

The current stdlib uses higher-order functions for operations such as list and
array mapping/folding.

## Curried semantics

A type such as:

```text
Nat -> Nat -> Nat
```

is read as a function returning a function.

D-CALL makes ordinary multi-argument source pleasant:

```proofscript
add(x, y)
```

while preserving the curried semantic core.

## Generic functions

```proofscript
function identity {α : Type}(x : α) : α :=
  x;
```

The implicit `α` parameter describes a relationship between input and output.

The important part is not merely "this accepts many types". It says:

> Whatever the actual input type is, the output is that same type.

## Multiple type parameters

```proofscript
function first {α : Type}{β : Type}
(x : α, y : β) : α :=
  x;
```

Each type parameter remains available in later parameter/result types.

## Function types can be dependent

Ordinary arrow:

```proofscript
Nat -> Nat
```

Dependent arrow:

```proofscript
(x : Nat) -> Fin x -> Nat
```

The second input type depends on the value of the first input.

This is beyond ordinary TypeScript generic function typing.

## Expected types and inference

The Meta/Elab layer can use expected types to fill supported implicit
information.

That convenience must still produce an ordinary checked term.

If required implicit/universe/class information cannot be resolved under the
bounded profile, elaboration fails rather than guessing.

## Local functions

PSC1's v0.7 surface has a braced `where` form for local declarations.

```proofscript
def f(x : Nat) : Nat :=
  helper(x)
where {
  helper(y : Nat) : Nat := y + 1;
}
```

Local/mutual recursion syntax is not a first-freeze requirement unless real
compiler source needs it. Top-level helpers remain a valid small-language
alternative.

## Functions and effects

An ordinary function is semantically pure with respect to portable PSC1.

Host I/O must not be hidden behind a normal pure-looking declaration unless the
capability is explicitly classified as a trusted pure/deterministic runtime
assumption.

Effectful computation belongs in an effect type/abstraction.

## Functions and proofs

A function can compute a runtime result.

A proof is also a term, but proofs inhabit propositions and may erase at
runtime.

The common type theory is what lets ordinary programming and theorem proving
compose.

## No JavaScript function semantics

PSC1 `function` does not imply:

- hoisting;
- dynamic `this`;
- constructor calls;
- prototype properties;
- rest/spread semantics;
- implicit `arguments`;
- unrestricted early `return`.

Each of those would require an explicit PSC1 feature and semantic rule.

## Good PSC1 function design

Prefer:

- explicit input/output types at public boundaries;
- small pure functions;
- generic parameters when they express a real relation;
- algebraic data instead of hidden sentinel values;
- explicit effects at host boundaries;
- functions over adding syntax.

This style also makes code easier to verify and easier to lower across multiple
backends.

## Next

Continue to [Data and Pattern Matching](./04-data-and-pattern-matching.md).
