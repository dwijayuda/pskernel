# Recursion and Totality

Compilers need recursion. Proof systems also need a principled story about when
recursive definitions are logically admissible.

PSC1 keeps those concerns explicit.

## Structural recursion

The preferred first mechanism is structural recursion.

Example from the current stdlib shape:

```proofscript
function listLength {α: Type}(xs: PsList(α)): Nat :=
  match xs with {
    | .nil => 0;
    | .cons head tail => 1 + listLength(tail);
  };
```

The recursive call is on the structurally smaller `tail`.

## Why structural recursion matters

Structural recursion provides an understandable route to totality:

- the recursive data has a finite constructor structure;
- each recursive call moves to a smaller recursive component;
- evaluation cannot recurse forever on a finite input through that path.

The exact kernel/elaboration acceptance rules remain part of the Lean-compatible
semantic model.

## Recursive data and recursive functions are separate checks

An inductive must first be well-formed, including positivity/universe
requirements.

A recursive function must then meet the supported recursion/termination
requirements.

The parser recognizing a recursive name is not enough.

## Recursive map

```proofscript
function listMap {α: Type}{β: Type}
(f: α -> β, xs: PsList(α)): PsList(β) :=
  match xs with {
    | .nil => PsList.nil;
    | .cons head tail =>
      PsList.cons(f(head), listMap(f, tail));
  };
```

This combines:

- generic types;
- higher-order functions;
- pattern matching;
- structural recursion.

That combination is central to PSC1's self-hosting usefulness.

## Recursion and proofs

Induction follows the same data structure.

A theorem about recursive lists can introduce an induction hypothesis for the
tail case.

That correspondence between data recursion and proof induction is one reason
PSC1 preserves Lean-compatible recursor semantics.

## Controlled `partial def`

The first PSC1 language/capability profile also permits a controlled executable
`partial def` boundary.

Why?

Some compiler algorithms are awkward to express under the deliberately bounded
first termination elaborator even though they are reasonable executable code.

The key rule is:

> Executable partiality is not proof authority.

A partial function cannot be used to smuggle nontermination or arbitrary
runtime evaluation into kernel proof checking.

## Total vs executable-only code

A useful mental model is:

- total/accepted recursive definitions can participate in the checked logical
  model according to their admitted semantics;
- controlled partial definitions are executable capabilities with a narrower
  assurance role.

The exact boundary must stay visible.

## Mutual recursion

Lean supports rich mutual recursion facilities.

PSC1 does not require all of that syntax for the first freeze.

If a compiler algorithm can be written with:

- top-level helpers;
- one structural dispatcher;
- ordinary data;

then that smaller mechanism is preferred.

Mutual/local recursion can become required only when real compiler code
demonstrates the need.

## Well-founded recursion

General well-founded recursion is powerful.

It also pulls in more elaboration/termination infrastructure.

Therefore it is optional/non-blocking for the first PSC1 freeze unless the
compiler truly requires it.

## Loops

PSC1 does not need imperative loops to have general recursive computation.

The first freeze can use:

- structural recursion;
- library folds;
- higher-order traversal;
- explicit state effects.

`for`, `while`, `break`, and `continue` may exist as optional
desugarings/conveniences later.

They must not introduce backend-specific control semantics.

## Avoiding accidental backend recursion semantics

JavaScript stack depth, Rust recursion optimization, and Wasm tail-call support
are target/runtime matters.

They may affect performance or implementation strategy, but they do not define
whether a source recursive definition is semantically admissible.

## Recursive compiler implementation

The self-host plan explicitly requires recursive compiler functionality for:

- lexing/parsing traversal;
- syntax trees;
- name/environment operations;
- Meta/elaboration;
- recursive data lowering.

SH7's composition gate must prove the selected recursion mechanisms compose in
a real multi-module compiler-like program.

## Next

Continue to [Effects and `do`](./09-effects-and-do.md).
