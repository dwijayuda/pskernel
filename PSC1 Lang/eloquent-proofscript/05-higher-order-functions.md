# 5. Higher-Order Functions

Abstraction lets a program speak in the vocabulary of its problem rather than
in the mechanics of every traversal.

Higher-order functions are one of PSC1's most important abstraction tools.

## A map function

The current PSC1 stdlib uses:

```proofscript
function listMap {α: Type}{β: Type}
(f: α -> β, xs: PsList(α)): PsList(β) :=
  match xs with {
    | .nil => PsList.nil;
    | .cons head tail =>
      PsList.cons(f(head), listMap(f, tail));
  };
```

A caller can then say:

```proofscript
listMap(fun x => x + 1, xs)
```

instead of rewriting the recursion every time.

## Array map

```proofscript
function arrayMap {α: Type}{β: Type}
(f: α -> β, xs: Array(α)): Array(β) :=
  Array.map(f, xs);
```

The abstraction describes transformation directly.

## Folding

A fold reduces a collection to a summary.

The current stdlib exposes an array fold shape:

```proofscript
function arrayFoldl {α: Type}{β: Type}
(f: β -> α -> β, init: β, xs: Array(α)): β :=
  ...
```

From folds we can express many traversals without adding new language syntax.

## Predicates as values

```proofscript
function arrayAny {α: Type}
(predicate: α -> Bool, xs: Array(α)): Bool :=
  ...
```

A predicate is just a function value returning `Bool`.

## Option bind

The stdlib includes:

```proofscript
function optionBind {α: Type}{β: Type}
(value: PsOption(α), f: α -> PsOption(β)): PsOption(β) :=
  match value with {
    | .none => PsOption.none;
    | .some x => f(x);
  };
```

This captures the repeated "if present, continue; if absent, stop" pattern.

## Result bind

Similarly:

```proofscript
function resultBind {α: Type}{β: Type}{ε: Type}
(value: PsResult(α, ε), f: α -> PsResult(β, ε)): PsResult(β, ε) :=
  ...
```

This provides typed error propagation as a reusable abstraction.

## Composability

Small reusable functions are valuable because they can be combined.

A good abstraction:

- removes incidental detail;
- preserves the important contract;
- composes with other abstractions;
- remains easy to test and reason about.

## Libraries before syntax

When repetition can be abstracted by a function such as `map`, `fold`,
`bind`, or `compare`, PSC1 prefers that library abstraction over adding a
new keyword.

This is a central small-language design rule.

## Exercises

1. Implement `listMap` for a custom recursive list.
2. Define `listFold` and use it to compute a length or sum.
3. Define `optionMap2` from two optional values.
4. Express "all array elements satisfy a predicate" using a fold.
