# ProofScript CLI UX

Status: PSC-LANG-1 command design and initial implementation.

## Goals

The `psc` command is the normal developer interface. `pskernel` remains the low-level kernel/replay/module tool.

The command vocabulary intentionally follows familiar JavaScript/TypeScript tooling:

- `psc init` — scaffold a project;
- `psc check` — validate without emitting;
- `psc build` — create build artifacts;
- `psc run` — build and run the exported `main`;
- `psc clean` — remove generated output;
- `psc emit-lean` — inspect the canonical Lean lowering.

Configuration lives in `psconfig.json`, analogous to `tsconfig.json`. `-p/--project` selects a config file or directory.

## Current build pipelines

The default/legacy software lane remains:

```text
.ps
→ v0.6.1 compiler-ready reference parser
→ initial software type checker
→ canonical Lean source
→ generated TypeScript
→ TypeScript Compiler API
→ .js + .d.ts + .js.map
```

The verified lane can now branch after one pskernel-admitted compiler IR:

```text
.ps / supported .lean
→ Lean-compatible elaboration
→ pskernel checked core
→ verified erasure
→ compiler IR
   ├→ TypeScript → JavaScript
   └→ Wasm lowering → typed WasmIR → Binaryen → .wasm/.wat
```

Generated TypeScript remains as evidence/debugging output for W1 Wasm builds.
The Wasm backend is untrusted execution infrastructure and has no proof authority.

## Commands

### psc init

```bash
psc init
psc init my-app
psc init my-lib --lib
```

Creates `psconfig.json`, `package.json`, `.gitignore`, and a reference-valid `.ps` source file.

### psc check

```bash
psc check
psc check src/main.ps
psc check -p ./psconfig.json
psc check --json
psc check --verified --target wasm
```

No build artifacts are written. The Wasm form performs target-capability
lowering/validation in memory and fails closed when the verified runtime IR is
outside the current W1 subset.

Current claim ceiling: the initial software subset is parsed and type-checked. Theorem/proof declarations are not yet elaborated into pskernel by this command.

### psc build

```bash
psc build
psc build src/main.ps
psc build src/main.ps --verified --target wasm
```

The default target produces TypeScript, JavaScript, TypeScript declarations,
source maps when available, canonical Lean, and a manifest. W1 Wasm builds also
produce `.wasm` and `.wat`, while retaining the canonical TS/JS evidence
artifacts and recording the Binaryen version/profile in the manifest.

### psc run

```bash
psc run -- 42
psc run src/main.ps -- 42
```

`psc run --target wasm` currently fails closed. The Wasm argument/result ABI
must be specified before direct CLI execution is enabled.

Builds the project, loads the emitted ESM module, invokes exported `main`, converts CLI arguments according to the verified IR parameter types, and prints a non-Unit result.

Primitive `Nat`, `Int`, `Bool`, `String`, and `Unit` arguments retain the compact CLI forms. Supported structures and ADTs use a strict JSON boundary. Nested `Nat`/`Int` values are decimal JSON strings to avoid host-number precision loss; structures use exact field objects; ADTs use `{"$ctor":"constructor", ...fields}`. Structured results are encoded back to the same JSON-safe form. Function-typed, unknown, and unresolved type-parameter values fail closed.

### psc emit-lean

Prints the canonical Lean lowering for review and debugging.

## Planned familiar extensions

After the vertical compiler is stable:

- `--watch` on check/build/run;
- `psc test`;
- `psc fmt`;
- `psc info`;
- `psc lsp`;
- `psc doctor`;
- shell completions;
- npm package and monorepo filters.

These are intentionally deferred until the language/compiler pipeline is real enough to serve them.
