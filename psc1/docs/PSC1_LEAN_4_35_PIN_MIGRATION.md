# PSC1 native Lean 4.35 pin migration

## Target and evidence boundary

The active native source uses stable Lean 4.35.0 at
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The authoritative current pin is
[`NATIVE_SOURCE_PIN.json`](../NATIVE_SOURCE_PIN.json). An isolated focused Linux
run must qualify this migration before language feature evidence is added.
Historical 4.34 passing runs and prebuilt bundles are not relabeled.

## Scoped upstream compatibility audit

Directory-identity comparison of the pinned 4.34 and 4.35 `src/kernel/` trees
found 35 of 37 file blobs unchanged. The changed files are:

- `environment.cpp`: diagnostics flag declaration corrected from `uint8*` to `uint8`.
- `type_checker.cpp`: native reduction through `Lean.reduceBool` and
  `Lean.reduceNat` removed, including WHNF, definitional equality and globals.

The current owned provider therefore refuses every `nativeEvaluator = some …`
at construction and session preflight. The default `none` provider and resource
policy remain the ordinary checking path. Retained low-level capability source
is historical and does not enable this removed rule through the current contract.

Source inspection found `Environment.addDeclCore`, `mkEmptyEnvironment 0`, the
Lean declaration constructors and the kernel exception cases used here compatible.
Active owned Prelude/SelfHostPrelude/SelfHostProd declarations are reconstructed
and replayed by the independently pinned official Lean provider. Compilation and
focused execution remain required evidence beyond this source inspection.

## Exact identity and publication

The compiler reports actual `Lean.versionString` and `Lean.githash`, and rejects
mismatches with the provider constants. The npm transport checks both fields
against the current pin before forwarding commands. Staging includes both fields;
the transactional publisher rejects mismatches before publishing. Manifests record
the logical checker version and commit. Tests cover historical, missing and wrong
commit launcher identities, ordinary admission, and native evaluator refusal.

## Historical scope

Package-local native 4.34 `LEAN_SOURCE_PIN.json`, `PREBUILT_MANIFEST.json`,
vendored C++ and binaries, plus the entire Wasm provider package, remain archived.
The archived npm runtime, release recipes, checked-kernel generation selectors and
self-host receipts do not provide a fallback for the current native compiler.
No package publishing, Wasm provider migration, full kernel census/fixed point,
compiler self-host qualification or unrestricted backend preservation is claimed.

## Primary source locations

- [Stable tag](https://github.com/leanprover/lean4/releases/tag/v4.35.0)
- [4.35 kernel tree](https://github.com/leanprover/lean4/tree/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel)
- [4.34 kernel tree](https://github.com/leanprover/lean4/tree/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/kernel)
- [Environment API](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Environment.lean)
- [Declaration API](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Declaration.lean)
- [Native runtime identity](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Meta/Defs.lean)
