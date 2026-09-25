# 9. Text and Parsing

Compilers spend much of their time turning text into structured data.

PSC1 must therefore be able to express real lexers and parsers in its own
language.

## Text values

`String` and `Char` are language-level text types.

They must behave consistently across the JavaScript, Rust, and Wasm targets.

A self-host compiler cannot define string semantics as "whatever JavaScript's
UTF-16 methods happen to do."

## From text to tokens

A lexer usually transforms:

```text
source String
-> sequence of tokens
```

A useful token carries more than a word:

```text
kind
text/value
source span
```

Source spans allow later diagnostics to point back to the original program.

## From tokens to syntax

A parser transforms a token stream into an AST.

A recursive language naturally suggests recursive parsing.

For example, a tiny expression AST might be:

```proofscript
inductive TinyExpr where {
  | nat(value: Nat);
  | add(left: TinyExpr, right: TinyExpr);
  | variable(name: String);
};
```

Nested source becomes nested data.

## Let grammar drive data design

If the grammar has several expression categories, represent them explicitly.

Avoid a generic "object with a type string and arbitrary fields" when an
inductive can make invalid AST states unrepresentable.

## Parser results

A parser should expose failure:

```text
parseExpression: ParserState -> PsResult(ParseResult, ParseError)
```

The exact self-host parser API may differ, but the contract should preserve:

- success value;
- remaining/input state;
- source span;
- typed error.

## Recursive descent

A parser function can mirror the recursive grammar:

```text
parseExpr
  -> parseAtom
  -> parseApplication / operator continuation
  -> recursively parse subexpressions
```

This approach is simple enough to self-host and easy to debug.

## Precedence

PSC1 has a fixed operator table.

The parser must encode the language's precedence rather than relying on a host
parser.

Current common precedence from weak to strong is:

```text
||
&&
== !=
< <= > >=
+ -
* / %
```

Application binds more tightly.

Propositional `=` and arrows have their own grammar roles.

## Whitespace-sensitive ownership

One subtle PSC1 rule is D-CALL adjacency:

```text
f(x)       PSC1 D-CALL
f (x)      protected Lean-compatible neighbor
f/-c-/(x) not D-CALL
```

A self-hosted parser must preserve this distinction.

## Comments

Comment handling belongs in lexical/source preprocessing rules.

Comments must not accidentally turn a protected neighbor into owned syntax.

## Why regex is not a language requirement

Regular expressions are useful tools, but PSC1 does not need regex syntax in
the language to build a compiler.

A small explicit lexer over characters can be:

- portable;
- easier to verify;
- easier to self-host;
- less dependent on backend regex differences.

A regex library can still exist later.

## Parsing is not elaboration

The parser answers:

> What syntax is this?

The elaborator answers:

> What typed term does this syntax mean?

Keeping those stages separate makes diagnostics and trust boundaries clearer.

## Exercises

1. Define an inductive token kind for numbers, names, parentheses, commas, and
   one operator.
2. Define a token structure containing a span.
3. Sketch a recursive parser for nested calls.
4. Explain why `f(x)` and `f (x)` cannot be normalized before lexical
   ownership is known.
5. Design one parser error that reports both an expected token and its span.
