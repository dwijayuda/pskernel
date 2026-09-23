# ProofScript standard library

This directory is the first standard-library tranche authored in ProofScript
and compiled by the same verified project pipeline as user code.

## Current modules

- `ProofScript.Data.Option`: `PsOption`, map/get-or-else/or-else/is-some helpers.
- `ProofScript.Data.Result`: `PsResult`, value/error mapping, get-or-else,
  and Option conversion.
- `ProofScript.Data.List`: `PsList`, structural map/append/length/head helpers.

The `Ps*` type names are intentional and temporary. Lean's Prelude already
owns `Option` and `List`, while the current verified runtime erasure only
assigns executable representations to inductives admitted by the checked
source project. The stdlib therefore does not shadow Lean's built-ins or add
an erasure special case.

The three modules now contain nine pskernel-admitted theorems in total:
baseline reflexivity plus definitional computation laws for Option, Result, and
List helpers. These laws deliberately use ordinary `Eq` proof terms and kernel
definitional equality; they do not add a stdlib-only proof rule.

Stronger algebraic laws should be added only when the required induction,
rewriting, and branch-proof surface is supported faithfully.

`test/main.ps` is an end-to-end dogfood program. It imports the library
modules, runs generic ADT helpers and structural recursion, and is executed by
the repository package-integration gate through:

```text
ProofScript source modules
  -> mixed/project resolver
  -> Lean-compatible elaboration
  -> pskernel checked core
  -> erasure
  -> verified compiler IR
  -> TypeScript
  -> JavaScript
```

## Current dogfood checkpoint

The end-to-end stdlib test now exercises:

- `optionOrElse`;
- `resultGetOrElse`;
- generic `listMap`;
- structurally recursive `listAppend` with an invariant second list;
- `listLength`;
- nine admitted stdlib theorems;
- zero runtime external assumptions.

For input `9`, the current dogfood `main` returns `22`.
