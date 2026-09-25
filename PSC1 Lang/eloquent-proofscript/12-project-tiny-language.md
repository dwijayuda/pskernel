# 12. Project: A Tiny Programming Language

A small language implementation is one of the best ways to understand a
programming language.

This project builds a tiny expression language **in PSC1**.

The goal is not to reproduce ProofScript.

The goal is to make parsing, ASTs, environments, evaluation, and typed failure
concrete.

## The language

Our tiny language has:

- natural literals;
- Bool literals;
- variables;
- addition;
- conditionals;
- local bindings.

A possible AST:

```proofscript
inductive TinyExpr where {
  | nat(value: Nat);
  | bool(value: Bool);
  | variable(name: String);
  | add(left: TinyExpr, right: TinyExpr);
  | ifThenElse(
      condition: TinyExpr,
      thenExpr: TinyExpr,
      elseExpr: TinyExpr
    );
  | letBind(
      name: String,
      value: TinyExpr,
      body: TinyExpr
    );
};
```

## Runtime values

Do not mix syntax nodes directly with evaluated values.

```proofscript
inductive TinyValue where {
  | nat(value: Nat);
  | bool(value: Bool);
};
```

This separation makes invalid evaluator cases visible.

## Errors

```proofscript
inductive TinyError where {
  | unknownName(name: String);
  | expectedNat;
  | expectedBool;
};
```

The evaluator returns:

```text
PsResult(TinyValue, TinyError)
```

instead of throwing an unchecked host exception.

## Environment

Use an ordered map or another explicit persistent mapping:

```text
String -> TinyValue
```

Each `let` evaluates its value, extends the environment, then evaluates the
body in the extended environment.

## Evaluation

A conceptual evaluator:

```text
eval: Env -> TinyExpr -> PsResult(TinyValue, TinyError)
```

Pattern match on the AST.

For `add`:

1. evaluate left;
2. require a Nat value;
3. evaluate right;
4. require a Nat value;
5. return their sum.

For `ifThenElse`:

1. evaluate condition;
2. require Bool;
3. evaluate only the selected branch.

## Parsing

Keep parsing separate from evaluation.

Pipeline:

```text
String
-> tokens
-> TinyExpr
-> TinyValue or TinyError
```

A parser error and an evaluator error are different categories.

## Source spans

As an extension, attach a span to every syntax node.

Then an `expectedNat` error can report the exact source expression that
produced the wrong value.

## Add a checker

The project becomes more interesting when you add a static type checker.

```proofscript
inductive TinyType where {
  | nat;
  | bool;
};
```

Then define conceptually:

```text
infer: TypeEnv -> TinyExpr -> PsResult(TinyType, TinyTypeError)
```

Now many evaluator errors can be rejected before execution.

## A proof opportunity

Once `infer` and `eval` exist, state a preservation-style property for a
small subset:

> If an expression checks as Nat and evaluation succeeds, the resulting value
> is a Nat value.

You do not need to prove the full theorem immediately.

Start with literals or addition.

## Why this project matters to PSC1

ProofScript itself must eventually:

```text
parse
-> elaborate/check
-> produce checked core
-> erase
-> lower to IR
-> emit target code
```

This tiny project makes those stages less mysterious.

## Exercises

1. Add multiplication.
2. Add equality returning Bool.
3. Add a `not` expression.
4. Add source spans to errors.
5. Add a static checker for literals and addition.
6. Prove one small checker/evaluator consistency theorem.
