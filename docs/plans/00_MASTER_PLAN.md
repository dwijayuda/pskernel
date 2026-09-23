# Master package plan

Status: living plan.

## Design objective

Build ProofScript as an npm-native verified programming/theorem-proving ecosystem around a small Lean-4.34-compatible TypeScript kernel.

## Non-negotiable architecture

- pskernel stays small and independently checkable.
- Parser, elaborator, tactics, compiler, LSP, browser hosting and project tooling stay outside the default TCB.
- Native compiler-IR execution is an optional TCB extension.
- Support packages depend on the kernel public façade; the kernel never depends on them.
- Do not physically fragment `src/core` / `src/kernel` while Full Std certification is active.
- npm remains the package/dependency substrate; do not clone Lake.

## Phases

### Phase A — kernel ecosystem

Packages:
- `@proofscript/module`
- `@proofscript/conformance`
- `@proofscript/lean4export`
- `@proofscript/cli`
- `@proofscript/browser`

Exit criteria:
- stable kernel API
- portable checked-module MVP
- Arena/differential tooling extracted behind APIs
- CLI can check/replay/module-inspect
- browser worker can stream verification
- no support package can bypass kernel admission

### Phase B — theorem-prover frontend

Packages:
- `@proofscript/syntax`
- `@proofscript/pretty`
- `@proofscript/meta`
- `@proofscript/elab`
- `@proofscript/tactic`

Exit criteria:
- source text → syntax → elaborated kernel declarations
- implicit arguments and holes
- metavariables/unification
- basic typeclass synthesis
- basic proof goals/tactics
- every produced declaration is rechecked by pskernel

### Phase C — software/compiler stack

Packages:
- `@proofscript/compiler-ir`
- `@proofscript/runtime`
- `@proofscript/backend-ts`

Exit criteria:
- kernel terms lower into a compiler-specific IR
- proof/irrelevant content erased where semantics permit
- executable ESM emitted for supported software subset
- runtime semantics documented and tested

### Phase D — language tooling

Packages:
- `@proofscript/language`
- `@proofscript/lsp`
- `@proofscript/project`

Exit criteria:
- incremental document snapshots
- cancellation/reuse
- diagnostics/info mapping
- editor protocol features
- npm-oriented project build/cache orchestration

### Phase E — verified library ecosystem

Initial packages:
- ProofScript prelude/core
- standard library
- data structures
- verified software libraries
- later math-oriented libraries

Distribution should use checked module artifacts with dependency/integrity hashes.

## Dependency rule

```text
syntax -> meta -> elab -> kernel
pretty <- syntax/meta/elab

elab -> compiler-ir -> backend-ts -> runtime

module -> kernel
lean4export -> module/kernel
cli -> module/kernel/conformance
browser -> module/kernel
conformance -> kernel

language -> syntax/meta/elab/module
lsp -> language
project -> module/compiler/language/npm

```

No reverse dependency from the kernel into any outer layer.


## Implementation status checkpoint

Current Phase-A implementation status:

- kernel public API: active
- `@proofscript/module`: MVP
- `@proofscript/conformance`: MVP
- `@proofscript/lean4export`: MVP
- CLI: prototype with module pack/verify/inspect/check
- browser: scaffold only

The MVP packages remain private and are not wired as root npm workspaces while Full Std certification is active.


## Outer-package foundation checkpoint

Current outer-package foundation status:

- `@proofscript/browser`: foundation
- `@proofscript/syntax`: D-CALL parser MVP on reusable term parser
- `@proofscript/pretty`: foundation
- `@proofscript/meta`: foundation
- `@proofscript/elab`: foundation
- `@proofscript/tactic`: foundation
- `@proofscript/compiler-ir`: foundation
- `@proofscript/runtime`: foundation
- `@proofscript/backend-ts`: foundation
- `@proofscript/language`: foundation
- `@proofscript/lsp`: foundation
- `@proofscript/project`: foundation

The root `test:packages` gate compiles and executes these TypeScript foundations without enabling npm workspaces. Existing Phase-A module/conformance/export/CLI packages retain their separate MVP/prototype status.
