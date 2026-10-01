# PSC1 Tooling and Projects

This page describes the current normal developer workflow from the repository
implementation, not older aspirational CLI spellings.

## The `psc` command

Current command surface:

```text
psc init [dir] [--lib] [-y]
psc check [entry.ps|entry.lean] [-p, --project <path>] [--json]
psc build [entry.ps|entry.lean] [-p, --project <path>] [--json]
psc run [entry.ps|entry.lean] [-p, --project <path>] [--json] [-- <args...>]
psc translate <entry.ps|entry.lean> --to ps|lean [-p, --project <path>]
psc emit-lean [entry.ps|entry.lean] [-p, --project <path>]
psc clean [-p, --project <path>]
psc --version
psc --help
```

## `psc init`

Create an application:

```bash
psc init my-app
```

Create a library:

```bash
psc init my-lib --lib
```

The current scaffold writes:

- `psconfig.json`;
- a `src/` entry source;
- `package.json`;
- `.gitignore`.

For an application the entry defaults to `src/main.ps`.

For a library it defaults to `src/index.ps`.

## `psc check`

```bash
psc check
psc check src/main.ps
psc check -p ./psconfig.json
psc check --json
```

`check` parses `.ps` or supported `.lean`, elaborates through the
Lean-compatible semantic path, and checks declarations through pskernel.

There is no legacy semantic fallback.

## `psc build`

```bash
psc build
psc build src/main.ps
```

The current pipeline is:

```text
source
-> Lean-compatible elaboration
-> pskernel checked core
-> erasure
-> VerifiedIR
-> TypeScript
-> JavaScript/.d.ts/source maps according to configuration
```

Generated TypeScript is an implementation artifact. It is not the source
language's semantic definition.

## `psc run`

```bash
psc run -- 42
psc run src/main.ps -- 42
```

The command builds through the checked-core path and invokes exported
`main`.

Current compact CLI parameter forms cover:

- `Nat`;
- `Int`;
- `Bool`;
- `String`;
- `Unit`.

Supported structures and ADTs use a strict checked JSON ABI.

Nested `Nat`/`Int` values use decimal JSON strings to avoid accidental
JavaScript number precision loss.

ADT values use a shape such as:

```json
{"$ctor":"some","value":"42"}
```

Exact accepted shapes are derived from checked runtime metadata. Unknown,
function-typed, malformed, or unresolved dependent shapes fail closed.

## `psc translate`

Translate between the two supported source surfaces:

```bash
psc translate src/main.ps --to lean
psc translate Main.lean --to ps
```

Translation is canonicalization, not formatting preservation.

A translation may normalize:

- whitespace;
- parentheses;
- binder spelling;
- `const`/`function` aliases to ordinary `def`.

It must not silently drop semantics.

For example, current npm FFI metadata cannot be faithfully represented by
ordinary Lean source, so a translation that would lose that metadata must fail.

## `psc emit-lean`

```bash
psc emit-lean src/main.ps
```

This prints canonical Lean lowering for the supported reference slice.

It is useful for:

- semantic inspection;
- debugging;
- differential/reference workflows.

## `psc clean`

Removes the configured output directory.

## `psconfig.json`

Current schema:

```json
{
  "languageVersion": "0.7",
  "entry": "src/main.ps",
  "sourceRoots": [],
  "runtimeDependencies": {},
  "compilerOptions": {
    "outDir": "dist",
    "emitTypeScript": true,
    "declaration": true,
    "sourceMap": true
  }
}
```

### `languageVersion`

The current CLI accepts the `0.7` language track.

PSC1 scope additionally follows the repository's self-host/freeze rules
documented in this branch.

### `entry`

Project entry source.

It may be `.ps` or the supported bounded `.lean` source profile.

### `sourceRoots`

An array of non-empty relative paths.

If empty or omitted, imports resolve below the entry source directory.

If configured, each logical module is searched under every source root for both
`.ps` and `.lean`.

Exactly one candidate must exist.

This means source-root order is not a hidden "first match wins" precedence
rule.

### `runtimeDependencies`

An object mapping npm package roots to **exact versions**.

Example:

```json
{
  "runtimeDependencies": {
    "host-lib": "1.2.3",
    "@scope/tool": "4.0.0"
  }
}
```

The first FFI policy does not accept semver ranges here.

External source declarations may refer to bounded public package subpaths, but
the config remains keyed by package root.

### `compilerOptions.outDir`

Output directory, default `dist`.

### `emitTypeScript`

Whether TypeScript source is retained/emitted as configured by the compiler.

### `declaration`

Controls declaration output in the current TypeScript backend.

### `sourceMap`

Controls source-map output.

## Logical module resolution

Given:

```proofscript
import Foo.Bar
```

and a source root `src`, the resolver considers:

```text
src/Foo/Bar.ps
src/Foo/Bar.lean
```

If both exist, resolution fails with ambiguity.

If multiple configured roots provide a candidate, resolution also fails.

This deterministic rule matters for reproducible checked environments.

## Runtime dependency assurance

For projects using extern runtime bindings, current repository work additionally
tracks runtime dependency integrity/lock information separately from logical
project integrity.

That metadata improves reproducibility but still does **not** make npm code
proof evidence.

## Editor model

The repository contains a ProofScript language service and VS Code integration.

`.ps` is the native ProofScript language.

Supported `.lean` integration is opt-in/manual so ProofScript does not
unconditionally steal `.lean` files from the normal Lean extension.

The language service uses the same source-kind/project resolution concepts as
the CLI.

## Planned commands are not current commands

Older design docs mention possible future features such as watch mode, test,
format, info, doctor, or shell completion.

Do not teach them as current CLI commands until the executable `psc --help`
surface contains them.

For exact current syntax see [../reference/cli.md](../reference/cli.md).
