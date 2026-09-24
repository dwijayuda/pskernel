# Lean 4.34 study → pskernel / ProofScript package roadmap

This roadmap is derived from the uploaded Lean 4.34.0 source tree and the current
pskernel architecture. It is intentionally **not** a directory-for-directory port
of Lean. The goal is to preserve Lean's useful architectural seams while building
an npm-native ProofScript ecosystem.

## What Lean 4.34 actually separates

Approximate source sizes in the 4.34.0 tree:

| Lean subsystem | Files | Approx. lines | Role |
| --- | ---: | ---: | --- |
| `src/kernel` | 36 | 8k | trusted type checker, declarations, inductives, quotient |
| `src/library` | 42 | 8k | module I/O, IR interpreter, printing, misc host services |
| `src/runtime` | 78 | 17.5k | allocation, objects, IO, threads, libuv, numeric runtime |
| `Lean.Parser` | 17 | 7.8k | syntax categories, parser combinators, commands/terms/tactics |
| `Lean.PrettyPrinter` | 13 | 5.1k | delaboration, parenthesizing, formatting |
| `Lean.Meta` | 478 | 97k | metavariables, unification, TC synthesis, tactics/meta services |
| `Lean.Elab` | 316 | 75k | term/command elaboration, macros, notation, declarations |
| `Lean.Compiler` | 117 | 26.8k | IR/LCNF, lowering and code generation |
| `Lean.Server` | 44 | 13.9k | LSP/server workers, completion, references, RPC |
| `Lake` | 159 | 29.8k | project/package/build system |
| `Init` | 648 | 214k | foundational library/runtime-facing definitions |
| `Std` | 488 | 199k | standard library |

The key conclusion is that finishing the kernel does **not** imply porting Lean.Meta
or Lean.Elab wholesale. Those layers are an order of magnitude larger and should be
introduced incrementally.

## Lean architectural lessons we should preserve

### Trusted kernel remains small

Lean keeps the trusted kernel in `src/kernel`. The compiler, parser, elaborator,
server and most library services are outside it. pskernel should preserve the same
property.

### Native compiler execution is not kernel definitional reduction

Lean `v4.34.0` still contains the deprecated `Lean.reduceNat` / `Lean.reduceBool` in-kernel compiler-interpreter path. pskernel keeps only an explicit `NativeEvaluator` interface in the kernel boundary; an implementation capable of reproducing Lean's compiler-IR execution is an optional TCB extension and remains a separate compatibility gate. This is distinct from ProofScript's ordinary compiler/backend IR and from native proof tactics in meta/tactic tooling.

### Module persistence is a separate layer

Lean's `Environment.ModuleData` stores module constants and extension entries, while
the `.olean` storage mechanism is implemented through compacted runtime images and
`src/library/module.cpp`.

For ProofScript/npm, do **not** copy the `.olean` memory-image format. Define a
portable, deterministic JS-friendly checked-module format instead.

### Meta is not the kernel

Lean.Meta adds metavariables, unification modulo definitional equality, transparency,
typeclass synthesis, tactic infrastructure and many construction utilities. These
features are essential to a pleasant theorem prover, but they should consume the
kernel API rather than become part of pskernel.

### Elaboration is its own large subsystem

Lean.Elab owns term/command elaboration, macros, notation, declarations, patterns,
mutual definitions/inductives, deriving, info trees and frontend processing. A
ProofScript elaborator should be layered on top of a smaller Meta package.

### Incremental language processing should be below LSP

Lean 4.34 has `Lean.Language` snapshot/task abstractions used by the server. This is
a useful boundary for ProofScript: incremental document processing should be a
language-service package that the LSP package consumes.

## Recommended package graph

```text
                         @proofscript/conformance
                                   |
                                   v
@proofscript/cli ---> @proofscript/kernel <--- @proofscript/browser
        |                    ^   ^
        |                    |   |
        v                    |
@proofscript/lean4export     |
        |                    |
        +----> @proofscript/module
                         ^
                         |
                 @proofscript/meta
                         ^
                         |
                @proofscript/elab
                  ^          ^
                  |          |
        @proofscript/syntax  @proofscript/pretty
                  |
                  v
             source text

@proofscript/elab ---> @proofscript/compiler-ir ---> @proofscript/backend-ts
                                |
                                v
                        @proofscript/runtime

@proofscript/language ---> @proofscript/lsp
          ^
          |
   syntax + elab + module

@proofscript/project
  uses npm + module + compiler + language tooling
```

Package names above are the preferred eventual public namespace. During certification,
private transitional package names such as `pskernel-cli` are acceptable.

# Phase A — build now, without destabilizing the kernel

## A1. Kernel public API

Status: started.

Lean analogue:
- `src/kernel/*`
- selected public environment/declaration types

Responsibilities:
- trusted declaration admission
- type inference/checking
- definitional equality/reduction
- inductive/quotient/primitive checking
- stable immutable AST/environment API

Trust: **TCB**.

Do not move internal kernel source files into subpackages while Full Std certification
is in progress.

## A2. `@proofscript/module` — highest-value next package

Lean analogue:
- `Lean.Environment.ModuleData`
- `src/library/module.cpp`
- module import/finalization portions of `Lean.Environment`

Purpose:
- portable serialization of checked declarations
- dependency manifests
- content hashes / kernel-version fingerprints
- deterministic ordering
- optional non-TCB metadata sections
- streaming load into an existing kernel Environment
- npm-friendly distribution of verified libraries

Suggested format properties:
- canonical JSON/CBOR or another deterministic cross-platform encoding
- explicit format version
- explicit target kernel compatibility (`Lean 4.34.0` semantics / pskernel API version)
- declaration hash and whole-module hash
- dependencies by module/package + integrity hash
- no executable JS inside the trusted declaration section
- optional sections for source maps, pretty names, docs, compiler IR

This package is the bridge from “a checker” to “libraries distributed through npm”.

Trust: transport/serialization is **outside the logical TCB** if every loaded
declaration is replayed through the kernel. A future certified fast-load mode can
have a separate trust story.

## A3. `@proofscript/conformance`

Lean analogue:
- `Lean.Replay`
- Lean Kernel Arena style testing
- kernel regression suites

Purpose:
- Arena runner
- differential tests against official Lean
- adversarial source/corpus orchestration
- standardized JSON/JUnit reports
- release evidence manifest

Trust: **test only / outside TCB**.

This should absorb current `scripts/arena-*`, differential and adversarial
orchestration without moving the actual kernel.

## A4. `@proofscript/lean4export`

Lean analogue:
- `Lean.Replay`
- module/environment export transport

Purpose:
- launch a pinned Lean release
- produce canonical declaration streams
- stream into pskernel
- validate exporter + Lean versions
- module/corpus sharding
- convert Lean environments into `@proofscript/module`

Trust: **outside TCB**; imported declarations are still checked.

## A5. `@proofscript/cli`

Status: scaffold started as private `pskernel-cli`.

Purpose:
- `pskernel check`
- `pskernel replay`
- `pskernel inspect`
- `pskernel module pack/unpack/verify`
- `pskernel arena`
- JSON progress/results

Trust: **outside TCB**.

## A6. `@proofscript/browser`

Purpose:
- Web Worker wrapper
- streaming declaration checking
- cancellation/progress
- browser persistence/cache integration

Lean analogue:
- host/service layer, not a direct Lean package

Trust: **outside TCB**.

# Phase B — ProofScript theorem-prover frontend

Do this after the kernel/module boundary is stable.

## B1. `@proofscript/syntax`

Lean analogue:
- `Lean.Parser.Types`
- `Lean.Parser.Basic`
- term/command parser modules

Purpose:
- source positions/ranges
- tokens
- syntax trees
- parser combinators
- ProofScript term/command grammar
- error recovery
- syntax extension hooks only where needed

Do **not** port Lean's full syntax-extension system initially. ProofScript's goal is a
small, learnable language.

Trust: **outside TCB**.

## B2. `@proofscript/pretty`

Lean analogue:
- `Lean.PrettyPrinter`

Purpose:
- kernel Expr → user-facing ProofScript syntax
- precedence/parenthesization
- declaration/goal formatting
- diagnostic rendering

Trust: **outside TCB**.

Keep this independent from kernel correctness; pretty-printing must never change
admission.

## B3. `@proofscript/meta`

Lean analogue:
- the foundational portion of `Lean.Meta`
- `Lean.MetavarContext`
- `Lean.Meta.Basic`
- `WHNF`, `InferType`, `ExprDefEq`, `SynthInstance`

This is the most important language package after syntax.

Minimum v1 scope:
- metavariable context + assignments
- local/meta contexts
- unification modulo kernel defeq
- transparency modes
- expected-type propagation
- coercion hooks
- basic typeclass/instance synthesis
- telescope helpers
- goal representation

Do not begin with all 97k lines of Lean.Meta. Tactics, simp, discrimination trees,
congruence theorem generation, etc. can be later packages/features.

Trust: **outside TCB** because final declarations are rechecked by the kernel.

## B4. `@proofscript/elab`

Lean analogue:
- `Lean.Elab.Term`
- `Lean.Elab.Command`
- declaration elaboration
- selected notation/macro support

Minimum v1:
- names/scopes/imports
- binders
- applications
- lambdas/Pi/let
- definitions/theorems
- inductives
- expected types
- implicit arguments
- holes/goals
- source diagnostics
- produce kernel declarations and submit them to pskernel

Keep macro/notation extensibility intentionally smaller than Lean initially.

Trust: **outside TCB**.

## B5. `@proofscript/tactic` — after Meta + Elab

Lean analogue:
- `Lean.Meta.Tactic`
- `Lean.Elab.Tactic`

Start with a deliberately small tactic API:
- exact
- intro
- apply
- assumption
- constructor
- cases
- induction
- rewrite
- simp (later milestone)

Proof terms produced by tactics are checked by pskernel.

Trust: **outside TCB**.

# Phase C — software/compiler stack

## C1. `@proofscript/compiler-ir`

Lean analogue:
- `Lean.Compiler.IR`
- especially modern `Lean.Compiler.LCNF`

Purpose:
- typed compiler-oriented IR separate from logical kernel Expr
- closure conversion/lambda lifting
- erased/irrelevant term handling
- specialization
- optimization/pass framework

Important lesson from Lean: **do not use kernel Expr as the final code-generation IR**.

Trust: compiler output correctness is separate from proof-checking TCB unless runtime
behavior is itself being formally related to source semantics.

## C2. `@proofscript/runtime`

Lean analogue:
- `src/runtime`
- selected `Init` computational primitives

For the JS ecosystem this should be much smaller than Lean's native runtime.

Responsibilities:
- Nat/Int/UInt representations
- Char/String semantics
- arrays/ByteArray
- tagged algebraic values
- runtime equality/hash helpers
- IO/task abstractions where ProofScript supports them

Prefer native JS values when semantics can be preserved cheaply; provide wrappers only
where Lean-compatible semantics require them.

## C3. `@proofscript/backend-ts`

Purpose:
- compiler-ir → readable TypeScript/JavaScript
- ESM modules
- source maps
- imports against `@proofscript/runtime`

This is the primary runtime backend for the current project mission.

## C4. Later backends

Only after the TS path is stable:
- `@proofscript/backend-wasm`
- Rust/Go/Java/PHP/Python packages if the language strategy still requires them

Avoid designing the core around hypothetical backends before TS is production-grade.

# Phase D — IDE and project ecosystem

## D1. `@proofscript/language`

Lean analogue:
- `Lean.Language.Basic`
- `Lean.Language.Lean`
- snapshot/task reuse and incremental frontend processing

Purpose:
- document snapshots
- incremental parse/elaboration
- cancellation
- diagnostics
- info trees/source-to-expression mapping
- reusable API shared by CLI, editor integrations and LSP

This should sit below the LSP protocol package.

## D2. `@proofscript/lsp`

Lean analogue:
- `Lean.Server`

Purpose:
- completion
- hover
- go-to-definition
- references
- semantic tokens
- inlay hints
- code actions
- diagnostics
- cancellation

Do not reimplement parsing/elaboration inside the LSP package. It should consume
`@proofscript/language`.

## D3. `@proofscript/project`

Lean analogue:
- Lake's config/build/project responsibilities

But do **not** clone Lake.

ProofScript already targets npm, so prefer:
- `package.json`
- npm/pnpm workspaces
- normal npm dependency resolution
- a small `proofscript` config section/file only for compiler-specific settings
- incremental build cache keyed by module hashes

This package should orchestrate existing JS tooling, not create a second package manager.

# Phase E — libraries distributed as npm packages

After `@proofscript/module`, Meta/Elab and the TS backend are stable:

- `@proofscript/core` / prelude
- `@proofscript/std`
- verified data structures
- theorem/proof libraries
- eventually math-oriented libraries

A future mathlib port should be **many npm modules/packages backed by portable checked
module artifacts**, not one giant source translation committed into the kernel repo.

# Immediate build order

Recommended next work while Full Std is being certified:

1. **Finish `@proofscript/module` design + MVP.**
2. Extract **`@proofscript/conformance`** from current Arena/differential scripts.
3. Extract **`@proofscript/lean4export`** process/stream orchestration.
4. Mature **CLI** around those APIs.
5. Add **browser worker wrapper**.
6. Then start **`@proofscript/syntax`**.
7. Build a deliberately small **`@proofscript/meta`**.
8. Build **`@proofscript/elab`**.
9. Add tactics.
10. Build compiler IR → runtime → TS backend.
11. Build incremental language service → LSP.
12. Add project tooling and standard libraries.

# What not to build yet

- A full port of all `Lean.Meta`.
- A full port of all `Lean.Elab`.
- A direct JS clone of Lean's native runtime/GC.
- A direct parser for compacted `.olean` memory images as the main package format.
- A Lake clone.
- Full LSP logic before an incremental language-service API exists.
- Native compiler-IR execution inside the normal kernel package.
- Physical micro-packaging of trusted kernel internals before Full Std is closed.

These would increase maintenance and drift risk without helping the immediate ProofScript goal.
