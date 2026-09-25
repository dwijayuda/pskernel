# 8. Bugs, Errors, and Proofs

A type system can catch many mistakes before execution.

A proof system can catch some deeper mistakes before execution.

Neither removes the need to design, test, and debug programs.

## Syntax errors

The parser should reject malformed source immediately.

A good diagnostic should include:

- the source span;
- what was found;
- what category was expected;
- enough context to repair the program.

PSC1's self-host plan requires real source spans and diagnostics rather than
string-only error messages.

## Type errors

Consider a function that expects a natural number:

```proofscript
function increment(x: Nat): Nat :=
  x + 1;
```

Passing a `String` is rejected before runtime.

This prevents a large class of mistakes that a dynamically typed language can
carry deeper into execution.

## Explicit recoverable errors

Expected failure belongs in the type.

The current stdlib uses:

```proofscript
inductive PsResult(α: Type, ε: Type) where {
  | ok(value: α);
  | error(error: ε);
};
```

A parser, resolver, or file decoder can therefore return a typed error instead
of crashing or inventing a sentinel value.

## Optional results

Absence is different from failure.

```proofscript
PsOption(α)
```

is appropriate when "not found" is an ordinary outcome.

Use `PsResult` when the caller needs failure information.

## Host exceptions

A JavaScript host API may throw.

That does not make exceptions PSC1's portable error semantics.

The adapter should translate recoverable host failure into the declared PSC1
effect or Result channel.

## Assertions versus proofs

A runtime assertion asks:

> Is this condition true *during this execution*?

A theorem asks:

> Can this proposition be established for all values described by the theorem?

Both are useful, but they answer different questions.

## A small theorem

```proofscript
theorem optionGetOrElseSome {α: Type}
(value: α, fallback: α):
optionGetOrElse(PsOption.some(value), fallback) = value :=
  by rfl;
```

The theorem establishes a reusable property of the function.

## Proof failures are diagnostics

When a theorem does not close, inspect:

- the local assumptions;
- the goal;
- the constructor/recursor shape;
- the exact equality direction;
- whether the desired fact is definitional or needs a lemma.

Proof-state feedback should help locate the missing reasoning step.

## Tests still matter

A theorem proves exactly its proposition.

It does not automatically prove:

- the parser accepts every intended program;
- diagnostics are pleasant;
- the CLI uses the right file;
- every backend preserves runtime semantics;
- the application matches user requirements.

Use tests for those properties.

## Negative tests

For a language implementation, rejection tests are especially important.

Examples:

- malformed syntax must fail;
- ambiguous imports must fail;
- unsupported Lean syntax must fail;
- invalid proof terms must fail;
- FFI signatures outside the bounded profile must fail.

Fail-closed behavior is part of correctness.

## Debugging generated targets

Generated TypeScript or Rust can help diagnose a compiler problem, but the
source-level bug should ultimately be explained in PSC1 terms.

Do not ask users to reverse-engineer backend artifacts for ordinary errors.

## Exercises

1. Design a `ParseError` inductive with at least two useful cases.
2. Rewrite a sentinel-returning function to use `PsOption`.
3. Rewrite an error-prone function to use `PsResult`.
4. State one theorem that catches a bug a unit test might miss.
5. Give one example of a property that is better tested than proved.
