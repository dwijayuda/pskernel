# 13. Language Extension Boundary

Lean is intentionally extensible.

PSC1 intentionally freezes a smaller language surface.

## Why PSC1 is closed by default

A self-hosted compiler must own the language it accepts.

If arbitrary macros, syntax categories, and custom elaborators are silently
inherited, then the standalone PSC1 implementation would effectively need to
reimplement large parts of Lean's metaprogramming system before it can define
its own accepted source.

## Registered PSC1 extensions

PSC1 owns a finite set of source decorations/forms such as:

- D-CALL;
- explicit parameter-group conveniences;
- declaration semicolons where registered;
- `const`;
- `function`;
- braced `if`;
- braced structure/class/inductive/match/where forms;
- the current explicit runtime `extern function` extension.

Each needs exact parser ownership and canonical lowering.

## Bounded Lean-compatible forms

PSC1 may accept selected Lean-like forms because they map cleanly to the frozen
semantic AST.

Acceptance is explicit.

"Lean accepts it" is not a standalone PSC1 grammar rule.

## Deferred systems

The first core does not require:

- arbitrary `syntax`;
- arbitrary `macro`;
- quotations/antiquotations;
- custom elaborators;
- custom tactics;
- broad environment extensions;
- unrestricted attributes;
- compile-time interpreter escape hatches;
- unrestricted unsafe implementation replacement.

## Extension admission rule

A new language feature should define:

1. syntax ownership/discriminator;
2. AST representation or normalization;
3. elaboration semantics;
4. kernel-facing meaning;
5. printer/canonical source behavior;
6. backend/runtime meaning if executable;
7. positive tests;
8. negative/protected-neighbor tests;
9. portability classification;
10. trust classification.

## Library-first principle

If a reusable function/typeclass/library can express a convenience without new
syntax, prefer the library.

This keeps PSC1 small while allowing its ecosystem to grow.
