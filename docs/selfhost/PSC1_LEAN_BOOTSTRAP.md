# PSC1 Lean bootstrap architecture

Branch: `selfhost/psc1-lean-bootstrap`

This branch starts the first real ProofScript self-host implementation. The
bootstrap host is **official Lean 4.34 + Lake**, not the current TypeScript
ProofScript compiler.

The TypeScript implementation remains valuable as a behavioral oracle and
architecture reference, but the new compiler source is written as if the PSC1
language specification were already fully implemented.

## Bootstrap model

Temporary host:

```text
PSC1-constrained compiler.lean
        |
        | lake build
        v
official Lean 4.34 elaborator + kernel
        |
        v
native/Lean bootstrap compiler executable
```

Future ProofScript path:

```text
the same compiler.lean
        |
        | ProofScript frontend for supported .lean
        v
pskernel checked core
        |
        v
verified IR -> TypeScript -> JavaScript

compiler.lean <-> canonical compiler.ps
```

The architecture of the semantic compiler must therefore be valid for both
source spellings. Lake is temporary build infrastructure, not a semantic
dependency of ProofScript.

## Why Lean + Lake first

Using official Lean first lets compiler implementation proceed from the PSC1
spec instead of waiting for PSC0 to implement every PSC1 source feature.

It also gives every portable semantic module an immediate independent check by
the official Lean elaborator/kernel.

PSC0 remains useful for:
- differential behavior tests;
- harvesting algorithms and regressions;
- measuring which planned PSC1 features PSC0 still lacks;
- checking the currently supported intersection when possible.

PSC0 compatibility is informative during this branch, not the authority that
defines what PSC1 source may contain.

## Source authority

Portable compiler source must stay inside the intersection of:

1. semantics promised by the PSC1 specification;
2. constructs we are willing to support in canonical `.ps`;
3. ordinary Lean syntax accepted by official Lean 4.34.

The fact that Lean accepts a construct does not make it part of PSC1.

Portable semantic modules must not depend on Lean's implementation APIs,
metaprogramming framework, macro system, unsafe escape hatches, or IO.

A lightweight source-profile audit guards against accidental dependencies such
as `Lean.*`, `Std.*`, `unsafe`, `syntax`, `macro`, `elab`,
`implemented_by`, `extern`, `run_tac`, and direct `IO` in portable
compiler modules.

Host wrappers may use Lean IO because they are explicitly outside the portable
semantic compiler.

## Architectural references

Use the three existing implementations for different lessons.

### ProofScript TypeScript implementation

Treat the current packages as the behavioral oracle:

```text
syntax
environment / project
meta
elab
checked-core
erasure
compiler-ir
backend-ts
cli
```

Do not mechanically port npm package boundaries or TypeScript helper classes.

### Lean 4.34

Use Lean for dependent-language architecture:

- explicit environment and declaration admission;
- parser state and deterministic recovery;
- Meta state and transactional metavariable assignments;
- elaboration as construction of kernel-checkable terms;
- a small kernel-facing core separated from the rich frontend;
- bootstrap staging and fixed-point discipline.

Do not copy Lean's macros, quotations, arbitrary custom elaborators,
environment-extension ecosystem, broad tactic platform, or transformer stack
unless ProofScript later demonstrates a real need.

### TypeScript compiler

Use TypeScript's traditional phase separation as a practical organizational
lesson:

```text
SourceFile / Program
  -> parse
  -> bind/name graph
  -> check
  -> transform/emit
```

ProofScript should borrow the clean idea of a project/program graph and a
separate name-binding/indexing phase, not TypeScript's structural type system or
JavaScript-compatibility complexity.

## Chosen hybrid architecture

The self-hosted semantic compiler is organized around these boundaries:

```text
Host / Project
      |
      v
Source text
      |
      v
Lexer
      |
      v
Parser
      |
      v
Syntax AST
      |
      v
ModuleGraph + Resolver
      |
      v
Environment
      |
      v
Meta
      |
      v
Elaborator
      |
      v
Lean-compatible Core
      |
      v
KernelBridge / pskernel
      |
      v
CheckedCore
      |
      v
Erasure
      |
      v
VerifiedIR
      |
      v
TypeScript emitter
```

The important split is:

- **ModuleGraph/Resolver** borrows the useful TypeScript Binder/Program idea:
  imports, declaration identities, qualified names, duplicate detection and
  deterministic module ordering.
- **Meta/Elab** follows Lean's model: expected types, metavariables,
  definitional equality, implicit insertion, instance synthesis and creation of
  kernel-checkable terms.
- There is no second semantic type checker after elaboration. pskernel is the
  independent final admission authority.

## npm-workspace topology is the long-term topology

The existing `packages/*` npm-workspace structure is not temporary scaffolding.
Keep the package boundaries that already express useful responsibilities and
make the self-hosted compiler grow into those packages instead of creating a
second permanent compiler tree.

The current TypeScript implementation and the future Lean/ProofScript
implementation should therefore converge structurally:

```text
packages/
  syntax/
  meta/
  elab/
  checked-core/
  erasure/
  compiler-ir/
  backend-ts/
  compiler/
  module/
  project/
  runtime/
  ...
```

Do **not** require every current package to become portable/self-hosted. Split
packages into two classes.

### Portable dual-source semantic/compiler packages

These should eventually contain the canonical paired source forms and compile
through both bootstrap lanes:

- `syntax`
- `meta`
- `elab`
- `checked-core`
- `erasure`
- `compiler-ir`
- `backend-ts`
- `compiler`
- the semantic/data portion of `environment`, `module`, `project`, `pretty`,
  `runtime` and `tactic` when used by PSC1

Their long-term shape is:

```text
packages/syntax/
  package.json
  src/
    ... existing TypeScript PSC0 implementation ...
    ProofScript/
      Syntax/
        Foo.lean
        Foo.ps
  dist/
    js/
    types/
    proofscript/
```

The exact subdirectory may evolve, but `.lean` and `.ps` counterparts should
live in the **same npm package and same logical module tree**. They are two
source spellings of one semantic module, not independent implementations.

### Host/tooling packages

Packages whose purpose is intrinsically Node/browser/editor/build integration
may remain TypeScript:

- `cli`
- `lsp`
- `language-service` host adapters
- `browser` host adapters
- npm/filesystem/project discovery adapters
- VS Code/editor transport
- TypeScript Compiler API invocation

Portable logic should move downward into the semantic packages instead of
forcing host APIs into PSC1.

### Kernel package

The independent TypeScript kernel stays a separate trust boundary. Its eventual
npm identity should be:

```text
@proofscript/kernel
```

It does **not** become part of the self-hosted compiler implementation merely
because it is distributed from the same monorepo.

The present repository-root kernel layout is a bootstrap packaging detail.
Moving or wrapping it under `packages/kernel` may happen later when that
migration is low-risk; self-hosting must not be blocked on that directory move.

## Dual build model

During bootstrap the repository intentionally has two build systems over the
same logical compiler packages.

### Lean/Lake bootstrap build

Lake compiles the `.lean` side:

```text
packages/*/src/**/Module.lean
        |
        v
      Lake
        |
        v
 official Lean 4.34
        |
        v
 Lean-hosted PSC compiler
```

### JavaScript/ProofScript build

The npm/JS build compiles either canonical source spelling through ProofScript:

```text
Module.ps   --\
             +-> psc -> checked core -> IR -> Module.ts -> tsc -> Module.js
Module.lean --/
```

Both source spellings must converge on the same checked-core and verified-IR
identity for the supported subset.

Long term Lake disappears from the normal user path, while the npm workspace
and JS build remain:

```text
npm install
  -> psc
  -> .ps/.lean
  -> .ts
  -> .js
```

Lake remains only as an independent bootstrap/reference checker when useful.

## Paired-source rule

For a portable semantic module, the intended steady state is conceptually:

```text
packages/meta/src/ProofScript/Meta/Foo.lean
packages/meta/src/ProofScript/Meta/Foo.ps
```

Both represent one module. They must not drift into two hand-maintained
implementations.

During the Lean-first bootstrap:

1. `.lean` is authored first;
2. canonical `.ps` is generated/updated from it;
3. both are checked for semantic identity;
4. after the self-host transition, `.ps` becomes authoritative and canonical
   `.lean` becomes the generated/reference form.

The repository may temporarily commit both forms because dual-kernel review and
bootstrap reproducibility are valuable, but one form must always be designated
authoritative for a given bootstrap stage.

## Package-local outputs

Keep generated output package-local, following npm expectations. A target shape
is:

```text
packages/<name>/dist/
  ts/            generated TypeScript
  js/            JavaScript runtime
  types/         .d.ts
  proofscript/   checked module artifacts / manifests
```

The exact directory spelling can remain compatible with existing package
scripts initially. The invariant is that generated files do not become semantic
source and that npm packages can publish JS/types plus ProofScript checked
artifacts from one package.

## Package manifests and semantic manifests

`package.json` remains the npm package/workspace manifest. Add a `proofscript`
field over time rather than inventing a separate registry or package manager.

```json
{
  "name": "@proofscript/syntax",
  "proofscript": {
    "sourceRoots": ["src"],
    "artifactRoot": "dist/proofscript",
    "modules": ["ProofScript.Syntax"]
  }
}
```

A ProofScript package may therefore ship:

- `.ps` source;
- canonical/reference `.lean` source when desired;
- generated `.ts`/`.js`/`.d.ts`;
- checked pskernel module artifacts;
- semantic dependency/integrity metadata.

npm owns distribution/version/install. ProofScript owns logical module identity,
semantic compatibility and checked artifacts.

## Portable module layout

Initial logical modules:

1. `ProofScript.Compiler.Data`
   - SourcePos / Span / Diagnostic
2. `ProofScript.Compiler.Name`
   - qualified compiler names
3. `ProofScript.Compiler.Collections`
   - only compiler-specific helpers missing from the small standard library
4. `ProofScript.Compiler.Json`
   - canonical JSON value/parser/encoder
5. `ProofScript.Compiler.KernelCodec`
   - versioned pskernel request/response data
6. `ProofScript.Compiler.Syntax`
   - tokens and canonical source AST
7. `ProofScript.Compiler.ModuleGraph`
   - module/import graph and deterministic ordering
8. `ProofScript.Compiler.Resolver`
   - declarations, qualified lookup and duplicate/ambiguity handling
9. `ProofScript.Compiler.Core`
   - Lean-compatible kernel-facing expression/declaration data
10. `ProofScript.Compiler.Meta`
    - metavariables, constraints, rollback and bounded unification
11. `ProofScript.Compiler.Elab`
    - source AST -> Core
12. `ProofScript.Compiler.CheckedCore`
    - admitted declaration/module identities; no second checker
13. `ProofScript.Compiler.IR`
    - small executable verified IR
14. `ProofScript.Compiler.Erase`
    - CheckedCore -> VerifiedIR
15. `ProofScript.Compiler.EmitTS`
    - deterministic VerifiedIR -> TypeScript
16. `ProofScript.Compiler.Driver`
    - semantic orchestration

Physical files may combine logical modules when that makes the implementation
smaller. PSC1 should not recreate Lean's directory count.

## Host boundary

The following remain host adapters, not portable semantic compiler modules:

- filesystem/path/process arguments;
- Lake during the Lean bootstrap era;
- npm/Node package resolution;
- TypeScript compiler invocation;
- JavaScript execution;
- transport to the independent TypeScript pskernel.

The initial kernel transport remains the versioned canonical String/JSON
protocol. This avoids making portable compiler source depend on TypeScript
classes.

## Development order

Now that Lean itself can build the compiler, we do not need to order work around
what PSC0 can already execute. Instead use dependency order:

```text
Data / Name
  -> collections needed by compiler
  -> JSON / KernelCodec
  -> Syntax
  -> ModuleGraph / Resolver
  -> Core
  -> Meta
  -> Elab
  -> CheckedCore
  -> IR
  -> Erase
  -> EmitTS
  -> Driver
```

Lexer/parser may start once the Syntax/Text foundation is ready. They no longer
need to wait until emitter work is complete.

However, keep interfaces narrow enough that pure backend work and frontend work
can progress independently.

## Build stages

### L0 — Lean-hosted compiler source

```text
compiler.lean --Lean 4.34/Lake--> psc-lean
```

Required:
- `lake build` succeeds;
- portable source profile passes;
- compiler modules avoid Lean implementation APIs.

### L1 — usable Lean-hosted ProofScript compiler

The executable can parse/elaborate the frozen PSC1 source subset and communicate
with pskernel.

### L2 — ProofScript compiles the same Lean source

```text
compiler.lean --PSC0/compatible ProofScript compiler--> compiler.ts/js
```

This becomes required only after the necessary PSC1 source features exist in
the ProofScript compiler implementation.

### L3 — first self-host

```text
compiler.lean --PSC1--> PSC2
```

Require stable checked-core/IR fingerprints and equivalent output.

### L4 — source transition

```text
compiler.lean <-> compiler.ps
compiler.ps --PSC1--> next compiler
```

Canonical Lean and ProofScript forms must represent the same compiler
semantics.

## Verification trajectory

Lean hosting gives an immediate extra assurance layer:

```text
portable compiler.lean
        |
        +-> official Lean kernel accepts it
        |
        +-> later pskernel accepts the same semantic declarations
```

That still proves only that the compiler and its explicit proofs are
well-formed. Compiler correctness remains a separate goal.

After ordinary self-hosting, add semantic-preservation theorems for:
- erasure;
- primitive/ADT lowering;
- recursion lowering;
- VerifiedIR transformations;
- TypeScript emission subset.

## Immediate rule

Do not wait for PSC0 feature completion to write compiler modules that are
already legal PSC1 and ordinary Lean.

Do not use Lean-only conveniences merely because Lake permits them.

The source should look structurally like code we are willing to maintain later
as `.ps`.

New bootstrap work should prefer the long-term `packages/*` responsibility
boundaries. The existing `selfhost/src` tree is a seed/smoke area, not a new
permanent parallel compiler architecture. Once the first paired package module
is green, move subsequent semantic implementation into the corresponding npm
workspace package.
