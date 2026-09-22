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
