# PSC1 Reference

The reference pages are for quick lookup.

Use the [Handbook](../handbook/README.md) when you want an explanation and
learning sequence.

Use the normative [PSC1 Language Reference](../PSC1_LANGUAGE_REFERENCE.md) when
you need exact semantic/conformance authority.

## Reference pages

- [Language Surface Quick Reference](./language-surface.md)
- [PSC CLI Reference](./cli.md)
- [psconfig.json Reference](./psconfig.md)

For exact grammar and precedence:

- [Syntax and Grammar](../SYNTAX_AND_GRAMMAR.md)

For runtime/scalar/backend semantics:

- [Semantics, Runtime, and Effects](../SEMANTICS_RUNTIME_AND_EFFECTS.md)

For implementation status and claim boundaries:

- [Conformance, Portability, and Status](../CONFORMANCE_PORTABILITY_AND_STATUS.md)

## Quick language identity

```text
source semantics:
  Lean-compatible dependent/proof core
  + small registered ProofScript surface

checked authority:
  pskernel

execution:
  CheckedCore -> Erasure -> VerifiedIR -> backend

current primary backend:
  TypeScript -> tsc -> JavaScript

planned/shared backends:
  Rust
  direct WebAssembly
```

## Three punctuation rules

```text
:=  definition/binding
=   proposition equality
==  Bool equality
```

## Three declaration spellings

```text
def       canonical general definition
const     parameterless def alias
function  parameterized def alias; explicit parameters required
```

## Source kinds

```text
.ps       native ProofScript
.lean     bounded supported Lean subset
```

Both converge into the same semantic pipeline.
