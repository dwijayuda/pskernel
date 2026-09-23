# Master package plan

Status: living plan.

## Design objective

Build ProofScript as an npm-native verified programming/theorem-proving ecosystem around a small Lean-4.34-compatible TypeScript kernel.

## Non-negotiable architecture
- The canonical compiler path is source -> syntax -> Lean-compatible elaboration
  -> @proofscript/checked-core -> @proofscript/erasure -> compiler IR
  -> TypeScript -> tsc -> JavaScript.
- @proofscript/checked-core is the only frontend/compiler semantic handoff and
  is constructed by pskernel re-admission.
- The legacy software checker is transitional coverage only; it must not become
  a second type theory or automatic fallback.

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
- `@proofscript/checked-core`
- `@proofscript/erasure`
- `@proofscript/compiler-ir`
- `@proofscript/runtime`
- `@proofscript/backend-ts`
- `@proofscript/compiler`

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


## PSC-LANG-1 vertical compiler checkpoint

The first reference-backed language slice now follows:

```text
ProofScript v0.7 track
  + v0.6.1 compiler-ready surface baseline
→ syntax AST
→ initial software type checker
→ canonical Lean source
→ TypeScript source
→ TypeScript Compiler API
→ JavaScript / .d.ts / source map
```

The normal developer CLI is `psc` with `init`, `check`, `build`, `run`, `emit-lean`, and `clean`. The low-level `pskernel` CLI remains available for replay/module workflows.

This checkpoint does not claim theorem-prover completion: theorem/proof syntax, elaboration to kernel Expr, contracts, and pskernel admission remain the next vertical milestones.


## Verified-core convergence checkpoint

The preferred compiler path is now executable for the first generic function
slice:

```text
.ps
-> @proofscript/syntax
-> @proofscript/meta / @proofscript/elab
-> @proofscript/checked-core (pskernel re-admission)
-> @proofscript/erasure
-> verified @proofscript/compiler-ir
-> @proofscript/backend-ts
-> TypeScript Compiler API
-> .js / .d.ts / source map
```

`psc check --verified` and `psc build --verified` expose this path without
fallback. The previous software checker/compiler lane remains temporary until
verified-core coverage catches up.
