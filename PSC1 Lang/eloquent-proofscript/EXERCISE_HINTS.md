# Exercise Hints

Use this file after making a real attempt.

The hints are intentionally smaller than full solutions.

## Chapter 1

For `triple`, reuse multiplication rather than repeated addition unless you
are specifically exploring operator behavior.

For the equality exercise, remember:

```text
== -> Bool
=  -> Prop
```

## Chapter 2

Nested `if` expressions are enough for the classification exercise.

Do not introduce mutation just because a JavaScript version might use a
variable updated several times.

## Chapter 3

For composition, think:

```text
f(g(x))
```

For `makeAdder`, the returned lambda may mention `amount`.

## Chapter 4

A recursive list function always has two structural cases:

```text
nil
cons head tail
```

The recursive call should use `tail`.

## Chapter 5

A fold needs:

- an accumulator type;
- an initial value;
- a step function.

If you can define a problem entirely by those three pieces, it probably does
not need new syntax.

## Chapter 6

For the traffic light, use constructors representing states rather than a
structure with an arbitrary string field.

For a typeclass, identify the operation that should be selected by type.

## Chapter 7

Keep route search pure.

Represent the worklist and visited set as arguments/results.

For the first theorem, prove something about one helper rather than the whole
search algorithm.

## Chapter 8

Ask whether failure is:

- ordinary absence -> Option;
- informative recoverable failure -> Result;
- impossible under a proved precondition -> proof-carrying API.

## Chapter 9

A recursive call parser can:

1. parse an atom;
2. inspect whether `(` follows;
3. parse zero or more arguments;
4. build an application node;
5. repeat if another call follows.

## Chapter 10

If two roots both resolve `Foo.Bar`, the correct result is an ambiguity error,
not "pick the first."

## Chapter 11

A file read is effectful because the same path can yield different results at
different times and the operation can fail for external reasons.

## Chapter 12

Keep syntax, values, and types as three different inductives.

Do not let the evaluator accept syntax that the type checker says is invalid if
you are testing a checked pipeline.

## Chapter 13

Use `cases` when the proposition follows by examining constructors.

Use `induction` when recursive substructure needs an induction hypothesis.

## Chapter 14

A proof-carrying API is appropriate when callers usually already know/prove the
invariant.

Option/Result is often nicer when invalid input is ordinary.

## Chapter 15

Ask whether an API's result depends on hidden external state.

If yes, it cannot be treated as an ordinary portable pure function without an
explicit capability contract.

## Chapter 16

Start with literals.

Only after:

```text
parse/check/compile/run
```

works for a literal should you add recursive addition.

Small stages make compiler bugs much easier to isolate.
