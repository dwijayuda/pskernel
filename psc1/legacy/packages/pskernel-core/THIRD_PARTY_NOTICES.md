# Source references and release licensing

This package's algorithms were developed with the repository's checked-in
Lean 4.34.0 kernel sources as reference, particularly `kernel/level.cpp`,
`kernel/abstract.cpp`, and binding/type-checker interfaces. Those upstream files
carry Microsoft Corporation copyright notices and the Apache License 2.0.
Lean4Lean was a secondary research reference, not a runtime dependency.

The new source in this checkpoint is not copied from `pskernel-core.old`, and
no implementation is imported from Lean, Lean4Lean, KernelOne, or that old package.
Development-only tests use the explicitly pinned PSC compiler and Lean provider
identified in `manifests/TOOLCHAIN.json`.

This note does not settle the repository owner's public distribution license or
all attribution obligations. That review remains an explicit blocked release gate.
No license approval, npm namespace ownership, or publishing credentials are implied.
