# PSC1 native compiler architecture

Updated 2026-10-20. Active scope: **PSC1 Practical Core — v7.2 subset**.
The implementation is handwritten Lean, pinned to Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The previous bootstrap architecture is
preserved verbatim in [the historical document](docs/history/ARCHITECTURE_BEFORE_SEVEN_BACKENDS_2026-10-20.md).

## Actual execution pipeline

1. `Ps.Host.SourceSnapshot` captures the entry and dependency source bytes and syntax once.
2. `Ps.Host.ProjectCompiler`, syntax, environment, meta and elaborator packages construct
   the dependency-ordered canonical Core closure.
3. `Ps.Compiler.Api` prepares the exact immutable admission graph.
   `Ps.Host.LeanChecked` submits that graph to the independent official Lean kernel.
4. In ordinary mode, `Ps.Compiler.Ordinary` pairs the opaque logical declaration with
   its separately admitted executable body; graph identity is recomputed before erasure.
5. `Ps.Erasure` removes proofs and type-only declarations and selects referenced runtime
   prelude declarations. `Ps.CompilerIr` checks the resulting typed executable IR.
6. `Ps.BackendCommon.Plan` shares target identities, public capability checks and the
   closed specialization/revalidation plan. JS, TS, Python, PHP and both Wasm paths use
   that closed plan; Rust retains its checked generic IR.
7. Direct backend packages lower and print target code. Host tools perform target syntax
   checking, formatting, final source-map observation and filesystem publication.
8. Complete checksummed bundles are staged privately and exposed by one atomic generation
   pointer. Failed builds preserve an already published generation.

The constructor of `PsHostDirectPrepared` is private. Public executable commands require
this admitted session; an arbitrary IR wrapper or npm manifest cannot authorize output.
`PsValidatedIrModule` is data with public construction, so every target entry must validate
it again. IR typing is not a proof of semantic preservation.

## Package direction

| Responsibility | Source |
| --- | --- |
| Source positions, names, diagnostics | `packages/foundation` |
| Both supported input grammars and shared AST | `packages/syntax` |
| Canonical logical terms/declarations | `packages/core` |
| Resolution, prelude and elaboration | `packages/environment`, `packages/meta`, `packages/elab` |
| Canonical admission transport | `packages/bridge` |
| Logical/executable pairing and orchestration | `packages/compiler` |
| Proof erasure and typed executable IR | `packages/erasure`, `packages/compiler-ir` |
| Shared target identity and closed planning | `packages/backend-common` |
| Independent direct printers and runtime catalogues | `packages/backend-*` |
| Independent official Lean admission | `packages/pskernel-lean/provider` |
| Captured projects, target tools and publication | `host`, `host-tools` |
| One CLI model; npm process launcher | `packages/cli/src/Main.lean`, `npm-cli` |

Semantic compiler packages do not import target printers. Host code composes the built-in
backends into one executable. Python/PHP support does not require installing either
interpreter to parse, elaborate, admit, or erase source. Selecting a target requires its
actual validation tools before publication. Compiler installation and target execution
environments are separate.

## Current boundaries

The qualified parent checkpoint is `ea03ce125ad4d4902070d6fef92d92b51cb2e857`,
[Linux run 39349606554](https://github.com/dwijayuda/pskernel/actions/runs/39349606554).
It qualifies bounded JS, TS, Rust, core Wasm and Bool-only component Wasm behavior.
New backend qualification is recorded separately in `docs/PSC1_BACKEND_CONFORMANCE.md`;
a source file or target enum is not execution evidence.

The independent official Lean kernel is the direct admission provider. The owned
PSKernel-Core is separately integrated and natively regression-tested. There is no
automatic fallback, new axiom policy, or behavioral certificate.

The executable IR remains expression-oriented: typed calls, lets, lambdas,
conditionals, records, constructors and matches. The control/data continuation
uses those same operations. Lexical mutable binding identities track successive
immutable Core values. Branch and finite-loop continuations carry the visible
state; early return bypasses the continuation. List/Nat iteration uses two total
checked helper definitions, and Array iteration uses the existing fold.

Selected ordinary while loops first elaborate through a temporary internal marker.
A checked Core lifting pass captures lexical values, specializes the state/step
continuation into a private partial helper, requires fully saturated direct tail
recurrence, and rechecks the helper and rewritten source. Every marker is removed
before admission. Temporary self/type headers are elaborator context only; they
are not admitted source axioms. The unchanged ordinary preparation independently
admits each opaque witness and exact body, then rechecks immutable graph pairing.

Tuples and array literals use existing datatype constructors. Optional lookup binds
receiver/index once and scans through the checked Array fold to construct Option.
No procedural IR, unchecked loop opcode, host mutable cell or execution fuel is added.

See [control/data architecture and scope](docs/PSC1_PRACTICAL_CORE_CONTROL_DATA.md)
for supported effects, closure restrictions, finite-loop space use, optional-lookup
cost, native admission/execution distinctions and exact qualification.

## Runtime ownership

A logical prelude declaration is checked source and may enter the shared erasure closure.
A target runtime helper implements a target representation and belongs to its backend.
The old `npm-runtime` directory contains historical generated-compiler packaging support;
it is not an implicit dependency of newly generated Python/PHP programs.

Runtime-free programs should use native target values and operators. Helpers must be
selected by required operations and their dependencies; emitted bundles record the
runtime contract/version and checksums. A shared external runtime mode is not implemented; generated bundles include their
selected readable helpers.

## Direct TS and JS

DirectTS prints TypeScript. DirectJS prints JavaScript without invoking a TypeScript
compiler. Combined output captures and admits source once, shares the closed public
plan, prints both independently and validates both before publication. A TypeScript checker
used in CI is an independent consumer test, not a hidden DirectJS code generator.

## npm and future self-hosting

The native npm package must carry the compiler, exact pin, host tool dependencies and
portable source library resolver. Installed source libraries are resolved as source and
re-enter captured independent admission. Package metadata is not proof evidence.

The minimal future self-host import closure remains semantic compiler plus one selected
backend. New host-only providers, npm tooling and additional backends do not automatically
enter that closure. No compiler/kernel fixed-point or full self-host qualification is
part of this milestone.

See [backend decisions](docs/PSC1_BACKEND_ARCHITECTURE.md), the runtime contract,
npm ecosystem document and machine-readable qualification records for precise limits.
