# The Basics

PSC1 combines ordinary typed programming with a dependent proof system.

You can start productively without using the proof system at all, but the same
language eventually lets types state stronger relationships and lets theorems
verify them.

## Definitions

The canonical definition keyword is `def`.

```proofscript
def answer : Nat := 42;
```

PSC1 also preserves two ergonomic aliases:

```proofscript
const otherAnswer : Nat := 42;

function add(x : Nat, y : Nat) : Nat :=
  x + y;
```

All three use one semantic definition mechanism.

### When to use each

Use:

- `def` when you want the canonical general spelling;
- `const` for a parameterless declaration;
- `function` for a declaration with explicit parameters.

A `const` may still hold a function value:

```proofscript
const increment : Nat -> Nat :=
  fun x => x + 1;
```

This is valid because `const` describes the declaration shape, not whether the
value's type is a function.

This is invalid:

```proofscript
const add(x : Nat) : Nat := x + 1;
```

because declaration parameters belong on `def` or `function`.

## Type annotations

A declaration can state its result type:

```proofscript
const enabled : Bool := true;
```

Function parameters carry their own types:

```proofscript
function twice(x : Nat) : Nat :=
  x + x;
```

Types are checked before executable lowering.

## Calls

PSC1 supports adjacent call syntax:

```proofscript
add(10, 32)
```

This is a friendly source decoration over curried function application.

```text
add(10, 32)
```

has the semantic shape:

```text
(add 10) 32
```

The distinction matters for higher-order and dependent functions.

## Lexical `let`

Use `let` to name an intermediate value.

```proofscript
function calculate(x : Nat) : Nat :=
  let doubled : Nat := x * 2;
  let adjusted : Nat := doubled + 1;
  adjusted;
```

A `let` is a lexical binding.

Do not assume it means mutable JavaScript `let`.

## Conditionals

```proofscript
function choose(flag : Bool, left : Nat, right : Nat) : Nat :=
  if (flag) {
    left
  } else {
    right
  };
```

The braced PSC1 form has one expression per branch.

Ordinary supported Lean-style conditionals may also exist in the bounded
profile:

```proofscript
if flag then left else right
```

These are alternate source forms for the same conditional semantics.

## Operators

Current everyday Nat/Bool expression support includes:

```text
!                 Bool negation
* / %             Nat arithmetic
+ -               Nat arithmetic
< <= > >=         Nat relations
== !=             Bool-valued equality/inequality
&&                Bool conjunction
||                Bool disjunction
```

PSC1's source precedence is documented separately and canonical Lean emission
adds parentheses when target precedence differs.

## Definition is not equality

Compare:

```proofscript
const x : Nat := 1;
```

with:

```proofscript
theorem xEqualsX : x = x := by rfl;
```

`:=` introduces a value.

`=` forms a proposition.

`==` computes a `Bool` where supported.

## Source comments and adjacency

Whitespace and comments can matter to syntax ownership.

```text
f(x)        PSC1 D-CALL
f (x)       protected Lean-compatible neighbor
f/-c-/(x)  not D-CALL
```

PSC1 does not globally rewrite all call-like text.

## What is checked?

The conceptual path is:

```text
source
-> AST
-> Meta/Elab
-> pskernel
```

Only after checked semantics does executable code continue through erasure and
VerifiedIR.

## The trusted boundary

A frontend bug should not be able to turn an invalid theorem into a valid proof
as long as pskernel checks the resulting declaration.

That is why parser/elaborator/tactic convenience is kept separate from kernel
authority.

## Unsupported forms

PSC1 intentionally fails closed.

If you write:

- a Lean macro the bounded frontend does not support;
- a JavaScript expression with truthiness semantics;
- an unsupported tactic;
- an unregistered source syntax extension;

the correct behavior is rejection, not a guessed approximation.

## Next

Continue to [Everyday Types](./02-everyday-types.md).
