# 9. Text, Unicode, and Parsing

Compiler programs spend a large amount of time turning text into structure.

PSC1's own self-hosting workload makes text handling a first-class programming
topic.

## Strings are not arrays of bytes

A source file is stored as bytes, but programmers think in characters and
source positions.

Those views cannot be casually interchanged.

The current ProofScript stdlib uses Lean-compatible raw string positions:

```proofscript
structure SourceSpan where {
  start: String.Pos.Raw;
  stop: String.Pos.Raw;
}
```

and helpers such as:

```proofscript
function rawPos(byteIdx: Nat): String.Pos.Raw :=
  String.Pos.Raw.mk(byteIdx);
```

## Byte offsets

`String.Pos.Raw` represents a raw UTF-8 byte position.

This is useful for:

- slicing original source;
- stable source spans;
- communicating positions through compiler layers.

Do not silently replace it with JavaScript UTF-16 code-unit indexing.

## Character classification

The current stdlib contains small ASCII-oriented helpers for the first lexer
slice:

```text
isAsciiDigit
isAsciiLower
isAsciiUpper
isAsciiIdentifierStart
isAsciiIdentifierRest
isAsciiWhitespace
```

This is intentionally modest.

A language lexer can start with a bounded identifier policy while still using a
Unicode-correct string representation.

## Slicing spans

The stdlib provides a shape like:

```proofscript
function sliceSpan(s: String, span: SourceSpan): String :=
  String.Internal.extract(s, span.start, span.stop);
```

The key contract is that the positions and string operations agree on the same
semantic indexing model.

## Tokenization

A useful lexer separates:

```text
source text
-> cursor
-> token kind + token text + source span
```

The self-host compiler already models token kinds and source spans as ordinary
typed data.

## Parsing recursive syntax

Once tokens exist, recursive syntax is naturally represented with inductive
ASTs and recursive parser functions.

A parser should return:

- a successful AST plus remaining/cursor state; or
- a typed diagnostic.

## Regular expressions

Regular expressions are useful host/library tools, but PSC1 does not need
regex syntax as a core language feature for its first freeze.

A parser implemented in PSC1 should not depend on a JavaScript regex engine if
that would make its semantics unavailable to Rust/Wasm.

A host-specific parser helper can exist behind a target-specific capability, but
portable compiler source should prefer portable text operations.

## Exercises

1. Use `SourceSpan` to represent the span of a two-character ASCII
   identifier.
2. Write a function that classifies an ASCII digit.
3. Extend a two-character identifier scanner to a structurally recursive or
   controlled-partial scanner appropriate to your local compiler subset.
4. Explain why JavaScript string indexing is not a portable specification for
   PSC1 source positions.
