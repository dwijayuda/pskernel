# 3. Functions

Functions are the main way PSC1 turns repeated details into reusable concepts.

## Named functions

```proofscript
function square(x: Nat): Nat :=
  x * x;
```

A public function signature states the contract visible to callers.

## Anonymous functions

```proofscript
fun (x: Nat) => x + 1
```

A lambda is a value.

## Function types

```proofscript
Nat -> Nat
```

describes a function from a natural number to a natural number.

## Functions as values

```proofscript
const increment: Nat -> Nat :=
  fun x => x + 1;
```

Functions can be passed to other functions.

## Higher-order parameters

```proofscript
function applyTwice(f: Nat -> Nat, x: Nat): Nat :=
  f(f(x));
```

This capability will become central in Chapter 5.

## Lexical scope and closures

A lambda can refer to values in the lexical environment in which it was
created.

Conceptually:

```proofscript
function addBy(amount: Nat): Nat -> Nat :=
  fun x => x + amount;
```

The returned function retains the semantic value of `amount`.

The backend may implement the closure using objects, heap records, or Wasm GC,
but those representations do not define source semantics.

## Recursion

```proofscript
function sumTo(n: Nat): Nat :=
  if (n == 0) {
    0
  } else {
    n + sumTo(n - 1)
  };
```

For the first PSC1 profile, structural recursion over inductive data is the most
important guaranteed recursive pattern.

Recursion over numeric measures can require termination support beyond the
smallest structural subset, so use current compiler gates as the final
implementation authority.

## Pure functions and side effects

Portable ordinary functions are pure.

Reading a file, clock, network, random source, or process state is not an
invisible property of a normal function.

Those capabilities belong behind an explicit effect boundary.

## Growing functions

A useful design technique is to begin with a concrete function, notice the
varying piece, and turn that piece into a parameter.

Example evolution:

```proofscript
function increment(x: Nat): Nat := x + 1;
```

to:

```proofscript
function transform(f: Nat -> Nat, x: Nat): Nat :=
  f(x);
```

The second function captures the reusable idea.

## Exercises

1. Write `compose(f, g, x)` for `Nat -> Nat` functions.
2. Write `applyThreeTimes`.
3. Write `makeAdder(amount)` returning a closure.
4. Explain why closure semantics cannot be defined as "a JavaScript object with
   captured properties".
