# ProofScript PSC1 in 5 Minutes

This page gives the shortest useful tour of PSC1.

## Define values

```proofscript
const answer: Nat := 42;
```

`const` is a parameterless alias of the ordinary definition mechanism.

## Define functions

```proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y;
```

Call with:

```proofscript
add(20, 22)
```

## Use local bindings

```proofscript
function doubleAfterIncrement(x: Nat): Nat :=
  let y: Nat := x + 1;
  y * 2;
```

## Choose with `if`

```proofscript
function maxNat(x: Nat, y: Nat): Nat :=
  if (x >= y) {
    x
  } else {
    y
  };
```

The braces contain expressions, not generic statements.

## Define data

```proofscript
inductive PsOption(α: Type) where {
  | none;
  | some(value: α);
};
```

## Pattern match

```proofscript
function optionGetOrElse {α: Type}
(value: PsOption(α), fallback: α): α :=
  match value with {
    | .none => fallback;
    | .some x => x;
  };
```

## Write generic functions

```proofscript
function identity {α: Type}(x: α): α :=
  x;
```

`α` is an implicit type parameter.

## Function types

```proofscript
Nat -> Nat
```

PSC1 also supports dependent function types in its core profile:

```proofscript
(x: Nat) -> Fin x -> Nat
```

Later argument types can depend on earlier values.

## Prove a proposition

```proofscript
theorem selfEq {α: Type}(x: α): x = x := by rfl;
```

`=` is propositional equality.

For Bool-valued equality, use the supported `==` behavior:

```proofscript
function isOne(x: Nat): Bool :=
  x == 1;
```

## Recursive data and functions

The stdlib currently uses source like:

```proofscript
inductive PsList(α: Type) where {
  | nil;
  | cons(head: α, tail: PsList(α));
};

function listLength {α: Type}(xs: PsList(α)): Nat :=
  match xs with {
    | .nil => 0;
    | .cons head tail => 1 + listLength(tail);
  };
```

This is structural recursion.

## Import modules

```proofscript
import ProofScript.Data.Option
```

Logical module names resolve to one `.ps` or supported `.lean` source under
the project's source roots.

Ambiguity is an error; root order is not a hidden precedence rule.

## Use npm code through an explicit boundary

Current bounded form:

```proofscript
extern function hostShout(value: String): String
  from "host-lib"
  import shout;
```

The npm implementation is a runtime assumption, not proof evidence.

## Create a project

```bash
psc init my-app
cd my-app
psc check
psc build
psc run -- 1
```

Current `psc init` creates:

```text
my-app/
  src/main.ps
  psconfig.json
  package.json
  .gitignore
```

The generated entry is currently equivalent to:

```proofscript
const answer: Nat := 42;
function main(x: Nat): Nat :=
  let y: Nat := x + answer;
  y;
```

## What happens when you build?

```text
source
-> Lean-compatible elaboration
-> pskernel
-> CheckedCore
-> Erasure
-> VerifiedIR
-> TypeScript
-> tsc
-> JavaScript
```

There is no fallback software checker.

## Why VerifiedIR?

PSC1 intends the same pure library semantics to support:

```text
VerifiedIR
  -> TypeScript/JavaScript
  -> Rust/native
  -> direct WebAssembly
```

Target representations are not allowed to redefine the language.

## Three rules to remember

1. `:=` defines; `=` proves equality; `==` computes a Bool equality.
2. Lean-compatible semantics do not mean every Lean syntax feature is PSC1.
3. Generated runtime behavior is not proof evidence; pskernel checks proofs and
   declarations.

## Next

Read:

- [The Basics](../../handbook/01-the-basics.md)
- [Everyday Types](../../handbook/02-everyday-types.md)
- [Functions](../../handbook/03-functions.md)
