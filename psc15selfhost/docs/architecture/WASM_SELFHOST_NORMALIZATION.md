# Backend Wasm self-host normalization

**Status:** implementation migration for `@proofscript/backend-wasm-next`.

## Goal

Make the existing backend-wasm Lean source consumable by the ProofScript compiler/self-host path without changing Wasm semantics and without using parser-error/fix loops as the migration method.

The normalization method is:

```text
static incompatibility inventory
  -> mechanical rewrite families
  -> one whole-closure PSC check
```

## Closed rewrite families

The following implementation-source forms are forbidden by the Wasm self-host style gate and currently have a required count of zero:

- term-level list construction with `x :: xs`;
- singleton-list match patterns such as `[x]`;
- `.map`;
- `.any`;
- `.foldl`;
- numeric tuple projections `.1` / `.2`.

Replacements use explicit, backend-local helpers:

```text
List.cons / List.nil
psWasmListMap
psWasmListAny
psWasmListFoldl
psWasmPairFirst
psWasmPairSecond
```

These helpers are deliberately written in the proven explicit recursive style.

## Supported syntax intentionally retained

The following forms are **not** normalization failures:

### Equation-style definitions

PSC2 explicitly supports Lean-like equation clauses where the pattern compiler can lower them soundly. Backend-wasm therefore retains equation-style definitions rather than rewriting dozens of valid functions into hand-nested matches.

### `++` append notation

PSC2 Standard supports controlled notation and append operations. Backend-wasm retains valid String/List append expressions rather than replacing them solely for stylistic similarity with compiler-internal source.

The style gate reports these constructs only as inventory information.

## Dependency cleanup

`Ps.BackendWasm.Lower` no longer imports `Ps.BackendWasm.Binary`.

The semantic lowering and binary encoding paths are independent:

```text
VerifiedIR -> Lower -> PsWasmModule
PsWasmModule -> Binary -> bytes
```

The whole-self-host entry imports both paths only for closure validation.

## Whole-closure gate

```text
test/BackendWasmSelfHostEntry.lean
```

imports:

```text
Ps.BackendWasm.Binary
Ps.BackendWasm.Lower
```

Cloud CI runs exactly one PSC check of that entry after the static rewrite families and ordinary Wasm regression tests:

```text
lake exe psc1 check test/BackendWasmSelfHostEntry.lean
```

This is the authority for the claim that the complete backend-wasm source closure is self-host consumable.

## Semantic preservation

The normalization changes source shape only. Existing Wasm semantic/binary regression suites remain mandatory:

```text
lake exe psc1_backend_wasm_tests
lake exe psc1_backend_wasm_binary_smoke
```

No `pskernel-core` source or semantics are part of this workstream.
