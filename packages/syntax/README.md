# @proofscript/syntax

Untrusted ProofScript source-syntax infrastructure for the v0.7 language track.

Current MVP scope:

- source positions and spans;
- preserved whitespace and Lean `--` / nested `/- -/` comment trivia;
- Unicode and dotted identifiers;
- string and basic numeric tokens;
- punctuation/operator tokens;
- exact token adjacency for v0.7 `D-CALL` ownership;
- span-bearing lexical errors;
- pinned ProofScript/Lean semantic-version metadata and surface feature IDs.

This package is **not** a full Lean parser, elaborator, theorem checker, or trusted component. Unknown punctuation can be tokenized without implying that the parser accepts it. Logical authority remains pskernel declaration admission.

The lexical model deliberately preserves the distinction between:

```text
f(x)             adjacent D-CALL candidate
f (x)            not adjacent; defer/native-neighbor candidate
f/-comment-/(x)  trivia-separated; not D-CALL
```

Parser/category ownership will be implemented in later Phase-B packages against the v0.7 reference.


## D-CALL parser MVP

The first feature-scoped parser/lowerer covers the v0.7 direct cases:

```text
add(1, 2)       -> add 1 2
f((x, y))       -> f (x, y)
f()             -> f ()
g(f(x), h(y))   -> g (f x) (h y)
```

Protected neighbors such as `f (x)`, `f (x, y)`, and comment-separated `f/-c-/(x)` return `DEFER`.

This is intentionally not yet the full inherited Lean term grammar. Arbitrary Lean subterms inside D-CALL arguments will be supported through the later recursive term/category parser rather than by ad-hoc text rewriting.


### Inherited Lean application arguments

D-CALL arguments now accept the small inherited Lean application-term slice needed for ordinary space-applied terms:

```text
apply(f x, xs)   -> apply (f x) xs
f g(x)           -> f (g x)
```

Plain Lean application remains owned by Lean: `f x` still returns `DEFER` when no D-CALL appears. This is not yet the full inherited Lean term grammar; operators, lambdas, type annotations, and other term forms remain later Phase-B parser obligations.


## Reusable term parser core

The inherited Lean term slice is now parsed by a reusable `TermParser` rather than being embedded in the D-CALL implementation. Its current deliberately small grammar covers:

- identifiers, numeric literals, and string literals;
- parenthesized groups;
- tuple syntax;
- whitespace-separated application;
- Lean 4.34 parenthesized type ascription, including `(e : T)` and `(e :)`.

Feature-specific postfix syntax plugs into this parser through guarded extension hooks. A hook must either consume input and return a node, or consume nothing and defer; violating that contract fails closed. D-CALL is the first such postfix extension.

This does not claim full Lean term parsing. Operators, lambdas, binders, named arguments, and other inherited forms remain later Phase-B work.
