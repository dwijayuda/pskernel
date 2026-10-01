# Dual-source Lean Interop

PSC1 supports native `.ps` source and a bounded compatible `.lean` source
profile.

The purpose is semantic interoperability, not pretending ProofScript is full
Lean.

## Two source frontends

Conceptually:

```text
main.ps
  -> ProofScript frontend
  -> shared AST

Main.lean
  -> bounded Lean-subset frontend
  -> shared AST
```

After that point, both use the same semantic path.

## Why support `.lean`?

The Lean subset is useful for:

- bootstrap compiler source;
- canonical reference artifacts;
- differential checking;
- migration;
- interoperability with the pinned semantic model;
- independent official Lean checking during the bootstrap phase.

## Why not simply accept all Lean?

A standalone ProofScript compiler is intended to own a small language.

Full Lean source would pull in large systems such as:

- arbitrary syntax extensions;
- macros and quotations;
- custom elaborators;
- generalized environment extensions;
- broad attributes;
- metaprogramming APIs;
- unsafe implementation facilities.

PSC1 accepts only the subset it explicitly supports.

Unknown Lean syntax fails closed.

## Canonical translation

Current user-facing command:

```bash
psc translate input.ps --to lean
psc translate Input.lean --to ps
```

Translation is semantic canonicalization.

It does not promise to preserve:

- comments;
- exact whitespace;
- every parenthesis;
- original alias spelling;
- unsupported macro notation.

## `const` and `function` normalize to `def`

ProofScript:

```proofscript
const answer: Nat := 42;
function add(x: Nat, y: Nat): Nat := x + y;
```

Canonical Lean uses ordinary definitions:

```lean
def answer : Nat := 42
def add (x : Nat) (y : Nat) : Nat := x + y
```

The spelling may change while checked semantics stay the same.

## D-CALL translation

ProofScript:

```proofscript
add(1, 2)
```

canonicalizes to ordinary Lean application.

Likewise, braced PSC1 forms lower to the corresponding Lean-compatible
construct.

## Semantic round-trip, not textual round-trip

The important equivalence is:

```text
.ps
-> checked declarations
-> VerifiedIR
```

versus:

```text
.ps
-> canonical .lean
-> bounded Lean parser
-> checked declarations
-> VerifiedIR
```

and the reverse supported path.

Equal meaning is stronger and more useful than preserving decorative source
characters.

## Canonical source hashes

The implementation can normalize equivalent `.ps` and supported `.lean`
source into a shared canonical source identity.

That provides a practical regression gate for source-front-end equivalence.

## Mixed projects

Source kinds can mix across imports:

```text
App.ps
  imports Data

Data.lean
  imports Logic

Logic.ps
```

The final environment is still one checked project.

## What source kind may change

Source kind may affect:

- parser;
- printer;
- diagnostics;
- editor mode;
- reporting.

It must not change:

- kernel authority;
- type semantics;
- checked-core meaning;
- erasure semantics;
- backend semantics.

## Translation can legitimately fail

Not every ProofScript feature has a lossless Lean source representation.

The current named npm FFI is the key example.

```proofscript
extern function hostShout(value: String): String
  from "host-lib"
  import shout;
```

Lean can represent a logical declaration/assumption, but the npm binding
metadata is extra.

A translator must fail rather than silently throw that metadata away and claim
equivalence.

## Bootstrap source transition

During the current self-host work, handwritten compiler source stays in the
bounded Lean subset.

The target sequence is:

```text
compiler.lean
-> completed compiler
-> generated canonical compiler.ps
-> parse/elaborate/check
-> compare CheckedCore
-> compare VerifiedIR
-> compare generated target behavior
```

Only after this parity campaign should `.ps` become the authoritative
maintained compiler source.

## After the transition

Long term:

- `.ps` is the normal authoring language;
- canonical `.lean` remains useful as generated/reference material where
  lossless;
- Lake/official Lean can remain a bootstrap/reference checker;
- normal compilation no longer requires Lean as the everyday host.

## What "Lean-compatible" should mean

Use precise statements such as:

> This PSC1 feature lowers to and is checked against the pinned Lean 4.34
> semantics.

Avoid vague claims such as:

> PSC1 supports Lean.

The latter can be misread as full parser, elaborator, tactic, macro, library,
and kernel equivalence.

## Where to go next

You have reached the end of the handbook.

For exact details continue with:

- [PSC1 Language Reference](../PSC1_LANGUAGE_REFERENCE.md)
- [Syntax and Grammar](../SYNTAX_AND_GRAMMAR.md)
- [Semantics, Runtime, and Effects](../SEMANTICS_RUNTIME_AND_EFFECTS.md)
- [Conformance, Portability, and Status](../CONFORMANCE_PORTABILITY_AND_STATUS.md)
- [Reference Index](../reference/README.md)
