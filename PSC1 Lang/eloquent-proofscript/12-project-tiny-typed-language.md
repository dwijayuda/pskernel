# 12. Project: A Tiny Typed Language

Building a small language is an excellent way to understand what a compiler is
actually doing.

This project builds a **typed expression language** in PSC1. It is deliberately
small, but it includes enough structure to make parsing, environments, static
checking, evaluation, and proof opportunities concrete.

The project pipeline is:

```text
text
-> tokens
-> AST
-> type checking
-> evaluation
```

This mirrors a small part of PSC1's own compiler without pretending to
reimplement ProofScript.

## 1. The expression AST

Start with syntax as algebraic data:

```proofscript
inductive TinyExpr where {
  | nat(value: Nat);
  | bool(value: Bool);
  | variable(name: String);
  | add(left: TinyExpr, right: TinyExpr);
  | equal(left: TinyExpr, right: TinyExpr);
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

Unlike a JavaScript object carrying a string tag plus arbitrary properties, the
inductive itself constrains which fields belong to each syntax form.

## 2. Types as data

```proofscript
inductive TinyType where {
  | nat;
  | bool;
};
```

A static checker returns a TinyType or a typed error.

## 3. Runtime values

Do not use the syntax AST itself as the runtime value representation.

```proofscript
inductive TinyValue where {
  | nat(value: Nat);
  | bool(value: Bool);
};
```

This keeps syntax, types, and values separate.

## 4. Errors

```proofscript
inductive TinyError where {
  | unknownName(name: String);
  | expectedNat;
  | expectedBool;
  | incompatibleEquality;
  | branchTypeMismatch;
};
```

Checker and evaluator failures should use a typed Result channel rather than
unchecked host exceptions.

## 5. Environments

Variables require environments.

Conceptually:

```text
ValueEnv = String -> TinyValue
TypeEnv  = String -> TinyType
```

In PSC1, use an ordered map or another explicit persistent mapping.

A `letBind` evaluates/checks the bound expression, extends the environment,
then processes the body under that extension.

## 6. Type checking

Define conceptually:

```text
typeOf: TypeEnv -> TinyExpr -> PsResult(TinyType, TinyError)
```

Rules:

- Nat literal -> Nat
- Bool literal -> Bool
- variable -> lookup in TypeEnv
- add -> both operands Nat, result Nat
- equal -> both operands same supported type, result Bool
- if -> condition Bool, both branches same type
- let -> type-check value, extend TypeEnv, check body

The recursive checker follows the recursive AST.

## 7. Evaluation

Define conceptually:

```text
eval: ValueEnv -> TinyExpr -> PsResult(TinyValue, TinyError)
```

Rules mirror the checker:

- literals produce values;
- variable looks up the ValueEnv;
- add requires Nat values;
- equality compares compatible runtime values;
- if evaluates only the selected branch;
- let evaluates the bound value, extends ValueEnv, then evaluates the body.

The evaluator should not contain a second parser or type system.

## 8. Parsing

Use Chapter 9's text/lexer techniques to recognize a small concrete syntax.

For example:

```text
42
true
add(1, 2)
equal(add(1, 2), 3)
if(true, 1, 2)
let(x, 10, add(x, 1))
```

Keep parser errors distinct from type-checking and evaluation errors.

## 9. Source spans

Extend TinyExpr so each node carries a source span.

Then errors can identify the expression that caused them.

This is an important step toward compiler-quality diagnostics.

## 10. A preservation-style theorem

Once `typeOf` and `eval` exist, state a property such as:

> If an expression checks as Nat and evaluation succeeds, the resulting value
> has the Nat runtime constructor.

Do not start by proving the whole language.

Prove progressively:

1. literals;
2. addition;
3. equality;
4. conditionals;
5. let bindings.

That mirrors good proof engineering: stabilize executable semantics first, then
prove reusable invariants.

## 11. Why this project matters to PSC1

ProofScript itself must eventually:

```text
parse
-> elaborate/check
-> pskernel admission
-> CheckedCore
-> erasure
-> VerifiedIR
-> backend
```

The tiny-language project teaches the same separation on a scale small enough
to understand in one sitting.

## Exercises

1. Add multiplication.
2. Add Boolean negation.
3. Add source spans to AST nodes and errors.
4. Split lexer, parser, AST, checker, evaluator, and main into modules.
5. Add a type-safe `lessThan` operator.
6. Add a `let` test where shadowing is visible.
7. Prove the checker/evaluator consistency property for Nat literals.
8. Extend that proof to addition.
