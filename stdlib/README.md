# ProofScript standard library

This directory is the first standard-library tranche authored in ProofScript
and compiled by the same verified project pipeline as user code.

## Current modules

- `ProofScript.Data.Option`: `PsOption`, map/get-or-else/is-some helpers.
- `ProofScript.Data.Result`: `PsResult`, value/error mapping and Option conversion.
- `ProofScript.Data.List`: `PsList`, structural map/length/head helpers.

The `Ps*` type names are intentional and temporary. Lean's Prelude already
owns `Option` and `List`, while the current verified runtime erasure only
assigns executable representations to inductives admitted by the checked
source project. The stdlib therefore does not shadow Lean's built-ins or add
an erasure special case.

Each module also contains a small kernel-checked theorem so standard-library
source exercises both programming and proof admission. Stronger algebraic laws
should be added only when the required proof surface is supported faithfully.

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
