# 16. Project: A Tiny Compiler Pipeline

The final project builds a miniature compiler architecture.

It deliberately resembles the major stages of ProofScript without attempting
to implement all of PSC1.

## Goal

Compile a tiny typed expression language through:

```text
source
-> tokens
-> AST
-> type check
-> small executable IR
-> evaluator or emitter
```

Keep each stage separate.

## Stage 1: source positions

Define:

```proofscript
structure Span where {
  start: Nat;
  end: Nat;
}
```

Every token and AST node should carry a span.

This makes later errors source-oriented.

## Stage 2: tokens

Define an inductive token kind:

```proofscript
inductive TokenKind where {
  | nat(value: Nat);
  | identifier(name: String);
  | plus;
  | leftParen;
  | rightParen;
};
```

Wrap it with a span.

## Stage 3: AST

```proofscript
inductive Expr where {
  | nat(span: Span, value: Nat);
  | variable(span: Span, name: String);
  | add(span: Span, left: Expr, right: Expr);
};
```

The parser produces this structure.

## Stage 4: checked expression

Do not let an arbitrary parsed tree flow directly into code generation.

Introduce a checked representation or typed result.

For the tiny language, the only runtime type may initially be Nat.

A checker can reject unknown variables or invalid forms.

## Stage 5: tiny IR

Define a representation that contains only executable operations:

```proofscript
inductive TinyIR where {
  | constNat(value: Nat);
  | add(left: TinyIR, right: TinyIR);
};
```

Names and source decorations disappear once resolved.

## Stage 6: evaluator

```proofscript
function runIR(ir: TinyIR): Nat :=
  match ir with {
    | .constNat value => value;
    | .add left right => runIR(left) + runIR(right);
  };
```

This gives you an executable semantics for the tiny IR.

## Stage 7: preservation test

For accepted closed expressions, compare:

```text
source evaluator result
==
IR evaluator result
```

Even before a formal compiler-correctness proof, this is a useful differential
gate.

## Stage 8: theorem

Prove the easiest preservation theorem first.

For example, a literal:

```text
compile(nat n) = constNat n
runIR(compile(nat n)) = n
```

Then extend to addition.

This illustrates the path from testing to proof.

## Stage 9: target emitter

As an optional exercise, emit TypeScript or a small textual target from
`TinyIR`.

The emitter must not re-type-check or reinterpret the source language.

It receives already checked, simplified runtime meaning.

## What this teaches about ProofScript

The real compiler has more stages:

```text
.ps / bounded .lean
-> source frontend
-> Meta/Elab
-> pskernel
-> CheckedCore
-> Erasure
-> VerifiedIR
-> backend
```

The same architectural principle applies:

> each stage should have one job, and target code generation should not become
> a second semantic frontend.

## Extensions

1. Add Bool.
2. Add `if`.
3. Add local variables.
4. Add source-map information.
5. Add a second emitter.
6. Prove an addition-preservation theorem.
7. Differential-test two emitters against the IR evaluator.
