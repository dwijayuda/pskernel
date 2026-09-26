# 5. Terms and Expressions

Terms are the main units of PSC1 programs and proofs.

## Identifiers

Identifiers resolve through the local context and checked environment according
to the bounded name-resolution rules.

## Function application

PSC1-owned adjacent call:

```proofscript
f(x, y)
```

normalizes to curried application.

Whitespace can distinguish D-CALL ownership:

```text
f(x)   D-CALL
f (x)  bounded Lean-compatible neighbor
```

## Lambdas

```proofscript
fun x => body
fun (x: Nat) => body
```

## Type ascription

Type annotations/ascriptions use the supported colon grammar.

Canonical PSC1 formatting is `x: T`.

## Let

```proofscript
let x: Nat := value;
body
```

## Conditionals

PSC1 supports bounded Lean-compatible conditionals and an owned braced form:

```proofscript
if (condition) {
  thenValue
} else {
  elseValue
}
```

Braces contain expressions, not arbitrary JS statements.

## Pattern matching

```proofscript
match value with {
  | .none => fallback;
  | .some x => x;
}
```

The first freeze focuses on ordinary single-scrutinee matching.

## Operators

Current common binary precedence from weak to strong:

```text
||
&&
== !=
< <= > >=
+ -
* / %
```

Application binds more tightly.

Propositional `=` is handled separately and function arrows are weaker.

## Holes

Synthetic holes are allowed only in the bounded refinement/elaboration shapes
explicitly implemented.

Unresolved holes may not survive checked admission.

## Proof terms

A `by` block invokes the bounded tactic elaborator to construct an ordinary
proof term.

## Quotation and macros

Lean quotation/antiquotation and arbitrary user syntax extension are not part
of the PSC1 first core.

They are studied as implementation references, not inherited automatically.
