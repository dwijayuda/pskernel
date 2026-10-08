# PSC0 legacy — out-of-closure archives

This folder preserves the non-bootstrap components from the original
October 3, 2026 `psc15selfhost/` tree. This was a *move without content
rewriting* for the archived source trees and receipts. The historical
source commit is `d4298a712d1e2ea6505185d311e9af10a698b2ca`.

## Moved package trees

- `packages/backend-rust` and `packages/backend-wasm`: backend extensions,
  not part of the compiler-only TypeScript fixed-point import closure.
- `packages/project`: module-graph extension. It remains referenced
  by the compiler regression Lake target, but not the fixed-point root.
- `packages/pskernel`: historical PSC1 kernel/reference package.
- `packages/pskernel-core`: experimental owned kernel, not the default
  Lean-WASM checker; its host adapter can still select it explicitly.

Rust/Wasm extension test fixtures, the Rust toolchain pin, owned-kernel
test scripts/fixtures, owned-kernel continuity records and historical
workstream coordination notes are archived under the matching
`legacy/test`, `legacy/scripts`, `legacy/docs` paths.

## Operational boundaries

The compiler-only 55-module source closure and the Lean-WASM default
checker are still outside `legacy/`. The active Lake and npm test
defaults no longer execute the archived optional Rust/Wasm and
experimental kernel workstreams. Archived experiments are preserved
for reference; they may need standalone harness configuration and are
**not** represented as passing in the reorganized tree.

The Lean 4.34 native host-provider code remains in the active tree
because the checked bootstrap seed imports it, and both host providers
remain *outside* the compiler source closure.

No changes outside `psc0/` are part of this archive operation.
