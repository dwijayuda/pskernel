# 8. Bugs, Errors, and Proof Failures

Programs fail in different ways.

PSC1 is easier to reason about when those failure classes stay distinct.

## Type errors

A type error means the source cannot be elaborated into the required typed term.

Example:

```proofscript
const broken: Bool := 42;
```

This should fail before runtime.

## Pattern errors

An unsupported or incomplete pattern form is a source/elaboration issue.

PSC1 deliberately fails closed rather than approximating full Lean pattern
semantics.

## Expected recoverable failure

Use a typed result when failure is part of normal operation.

```proofscript
inductive PsResult(α: Type, ε: Type) where {
  | ok(value: α);
  | error(error: ε);
};
```

A parser that encounters invalid input should normally return or propagate
typed failure rather than rely on a JavaScript exception as language meaning.

## Unexpected programmer failure

Some failures indicate a bug or violated internal invariant.

These should be reported loudly with source spans and diagnostics.

Do not catch every host exception and reinterpret it as an expected PSC1 error.

That can hide real bugs.

## Proof failures

A failed proof is also a useful diagnostic.

For example:

```proofscript
theorem wrong(x: Nat): x = x + 1 := by rfl;
```

should fail because the target is not definitionally reflexive.

The checker is telling us that the claimed invariant does not follow from the
proof we supplied.

## Tactic failures

A tactic can fail because:

- a candidate has the wrong type;
- no assumption matches;
- rewriting finds no supported occurrence;
- a constructor creates unsupported subgoals;
- bounded search finds no complete proof;
- the requested behavior lies outside the current tactic subset.

This is not permission to weaken the theorem.

## Diagnostics and spans

Compiler-quality errors need:

- source location;
- offending construct;
- expected vs actual semantic shape;
- stable error category where practical.

The current self-hosting plan treats names, spans, and diagnostics as required
compiler data precisely because a compiler must explain failure, not merely
reject input.

## Rollback

Speculative parsing or elaboration may try an alternative and fail.

State introduced during the failed branch must not leak.

The compiler effect therefore needs transaction-like rollback.

This is the typed/semantic analogue of exception-safe cleanup, but it is part of
the explicit compiler-effect model rather than implicit host exception
semantics.

## Testing negative behavior

A language implementation needs negative tests as much as positive tests.

For each supported form, test nearby unsupported forms:

```text
accepted feature
protected neighboring syntax
wrong type
wrong arity
unresolved hole
unsupported tactic
ambiguous module
```

Fail-closed behavior is part of correctness.

## Exercises

1. Write one source example that should fail parsing and one that should fail
   elaboration. Explain the difference.
2. Change a working theorem so `rfl` no longer applies. Read the resulting
   diagnostic.
3. Model a parser error with `PsResult` rather than a sentinel Nat/String.
4. Describe a speculative parser branch that must restore its input position
   after failure.
