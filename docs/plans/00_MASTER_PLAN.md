# Master package plan

Status: living plan.

> **Execution priority override (2026-09-24):** ProofScript package/infrastructure
> expansion is subordinate to `07_SELF_HOSTING_FOUNDATION.md`. On `main`,
> work must first retire the legacy semantic lane and close the language/runtime
> features required to self-host the compiler. Existing package milestones remain
> useful architecture references, but they are not permission to expand unrelated
> infrastructure before the self-hosting foundation closes. TypeScript kernel
> hardening continues separately on `kernel/lean434-study-hardening`.

## Design objective

Build ProofScript as an npm-native verified programming/theorem-proving ecosystem around a small Lean-4.34-compatible TypeScript kernel.

## Non-negotiable architecture
- The canonical compiler path is source -> syntax -> Lean-compatible elaboration
  -> @proofscript/checked-core -> @proofscript/erasure -> compiler IR
  -> TypeScript -> tsc -> JavaScript.
- @proofscript/checked-core is the only frontend/compiler semantic handoff and
  is constructed by pskernel re-admission.
- The legacy software checker/software-IR lane is retired. No second semantic
  checker or fallback lane may be reintroduced.

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

language-service -> syntax/meta/elab/checked-core/project
lsp -> language-service
project -> module/compiler/npm

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
- `@proofscript/lsp`: foundation
- `@proofscript/project`: foundation

The root `test:packages` gate compiles and executes the workspace foundations. The retired software checker is not part of this graph.


## PSC-LANG-1 vertical compiler checkpoint

The first reference-backed language slice now follows:

```text
ProofScript v0.7 track
  + v0.6.1 compiler-ready surface baseline
→ syntax AST
→ Lean-compatible Meta / Elab
→ pskernel admission
→ checked core
→ erasure / verified compiler IR
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

`psc check`, `psc build`, and `psc run` now use this path unconditionally.
The former `--verified` option is only a deprecated compatibility marker; it no
longer selects a different semantic pipeline.


## Active language completion execution plan

The concrete language-completion/anti-drift sequence is maintained in:

- `docs/plans/05_LANGUAGE_COMPLETION.md`

That plan defines acceptance gates for verified-core closure, dependent ADTs
and recursion, Meta/Elab convergence, theorem prover v1, npm/JS interop,
controlled effects, standard library work, and production hardening. Execution
priority is overridden by `07_SELF_HOSTING_FOUNDATION.md`.
