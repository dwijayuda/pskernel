# PSC1 Language Surface Quick Reference

This page is a lookup sheet, not a tutorial.

## Definitions

```proofscript
def answer: Nat := 42;

const answer2: Nat := 42;

function add(x: Nat, y: Nat): Nat :=
  x + y;
```

Rules:

- `def`: canonical general form;
- `const`: no declaration parameters;
- `function`: requires an explicit declaration parameter group;
- all three use one definition semantics;
- canonical Lean uses `def`.

## Binders

```text
(x : A)        explicit
{α : Type}     implicit
{{α : Type}}   strict implicit where supported
[C α]          instance implicit
```

## Calls

```proofscript
f()
f(x)
f(x, y)
f((x, y))
```

D-CALL requires adjacency.

```text
f(x)       D-CALL
f (x)      protected Lean-style neighbor
f/-c-/(x) not D-CALL
```

## Lambdas

```proofscript
fun x => x
fun (x: Nat) => x + 1
```

## Function types

```proofscript
Nat -> Nat
(x: Nat) -> Fin x -> Nat
```

## Local binding

```proofscript
let x: Nat := 1;
body
```

## If

```proofscript
if (condition) {
  thenExpr
} else {
  elseExpr
}
```

Each branch is one expression.

## Structure

```proofscript
structure Point where {
  x: Nat;
  y: Nat;
}
```

## Record value

```proofscript
{ x := 1, y := 2 }
```

## Inductive

```proofscript
inductive PsOption(α: Type) where {
  | none;
  | some(value: α);
};
```

## Match

```proofscript
match value with {
  | .none => fallback;
  | .some x => x;
}
```

## Where

```proofscript
def f(x: Nat): Nat :=
  helper(x)
where {
  helper(y: Nat): Nat := y + 1;
}
```

## Theorem

```proofscript
theorem selfEq {α: Type}(x: α): x = x := by rfl;
```

## Current bounded tactic family

```text
exact
assumption
intro
apply
refine
constructor
cases
induction
rfl
rw
simp only
exact?
```

Each has a bounded current semantic scope; this list does not imply full Lean
tactic parity.

## Import

```proofscript
import Foo.Bar
```

## Runtime external

```proofscript
extern function hostFn(value: String): String
  from "host-lib"
  import hostFn;
```

Current FFI is a post-v0.7 repository extension.

## Frozen scalar names

```text
Nat Int
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
Float Float32
Bool Char String Unit
```

The exact operation/conversion matrix is still an open SH7 freeze obligation on
the baseline used by this branch.

## Everyday data capabilities

```text
List / current PsList
Option / current PsOption
Result/Except-style error data / current PsResult
Prod
Array
ordered Map
ordered Set
```

Exact stdlib names may evolve independently of the language mechanisms.

## Operator precedence in current shared source grammar

From weak to strong:

```text
||
&&
== !=
< <= > >=
+ -
* / %
```

Application binds tighter.

Propositional `=` is handled separately in the theorem/type grammar and
function arrows are weaker than equality.

## Rejected semantic shortcuts

Not PSC1 semantics:

- JavaScript truthiness;
- `any` proof escape;
- implicit `null`/`undefined`;
- prototype inheritance;
- `this`;
- function hoisting;
- unrestricted early `return`;
- Promise semantics silently replacing PSC effects;
- TypeScript `<T>` replacing dependent binders.
