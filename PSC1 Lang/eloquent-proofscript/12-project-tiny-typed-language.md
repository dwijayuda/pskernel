# 12. Project: A Tiny Typed Language

Building a small language is an excellent way to understand what a compiler is
actually doing.

For PSC1, the project is more useful if we build a **typed expression
language** rather than an untyped evaluator.

The project has five layers:

```text
text
-> tokens
-> AST
-> type checking
-> evaluation
```

This mirrors a small version of PSC1's own pipeline without pretending to
reimplement PSC1.

## 1. The expression AST

```proofscript
inductive TinyExpr where {
  | nat(value: Nat);
  | bool(value: Bool);
  | add(left: TinyExpr, right: TinyExpr);
  | equal(left: TinyExpr, right: TinyExpr);
};
```

This is syntax as data.

## 2. Types as data

```proofscript
inductive TinyType where {
  | nat;
  | bool;
};
```

## 3. Typed failure

```proofscript
inductive TinyError where {
  | expectedNat;
  | incompatibleEquality;
};
```

A checker can return:

```text
PsResult(TinyType, TinyError)
```

instead of throwing a host exception.

## 4. Type checking

Conceptually:

```text
typeOf : TinyExpr -> PsResult TinyType TinyError
```

Rules:

- Nat literal -> Nat
- Bool literal -> Bool
- add -> both operands Nat, result Nat
- equal -> both operands same supported type, result Bool

The recursive checker follows the recursive AST.

## 5. Evaluation

Do not represent runtime values as a backend union.

Use an inductive:

```proofscript
inductive TinyValue where {
  | nat(value: Nat);
  | bool(value: Bool);
};
```

Then:

```text
eval : TinyExpr -> PsResult TinyValue TinyError
```

can mirror the type rules.

## 6. Parsing

Use the text/lexer techniques from Chapter 9 to recognize a deliberately small
syntax such as:

```text
42
true
add(1, 2)
equal(add(1, 2), 3)
```

The exact parser grammar is up to the exercise.

## 7. A theorem target

Once the checker and evaluator exist, an advanced target is a preservation-like
property:

```text
if typeOf(expr) = ok(t)
and eval(expr) = ok(v)
then v has runtime shape corresponding to t
```

You do not need to prove this before the project is useful.

The important lesson is the separation:

```text
syntax structure
!= type checking
!= execution
```

PSC1 itself makes that separation even sharper by adding elaboration,
pskernel admission, erasure, and VerifiedIR.

## Exercises

1. Add multiplication.
2. Add an `if` expression whose condition must be Bool and whose branches
   have the same TinyType.
3. Add source spans to TinyExpr nodes.
4. Make checker errors carry spans.
5. Split lexer, parser, AST, checker, evaluator, and main program into modules.
6. Compare this pipeline to PSC1's actual parser -> Meta/Elab -> pskernel path.
