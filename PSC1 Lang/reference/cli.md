# PSC CLI Reference

Source authority: current `packages/cli/src/help.ts` on the repository
baseline studied for this branch.

## Usage

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

Create a project and `psconfig.json`.

```bash
psc init
psc init my-app
psc init my-lib --lib
psc init my-app -y
```

Current default application entry:

```text
src/main.ps
```

Library entry:

```text
src/index.ps
```

## `psc check`

Parse and check a native `.ps` or supported `.lean` entry through pskernel.

```bash
psc check
psc check src/main.ps
psc check Main.lean
psc check -p path/to/project
psc check --json
```

No alternate legacy checker is selected.

## `psc build`

Build through:

```text
CheckedCore
-> Erasure
-> VerifiedIR
-> TypeScript
-> JavaScript/.d.ts/source maps
```

according to configuration.

## `psc run`

Build and invoke exported `main`.

```bash
psc run -- 1
psc run src/main.ps -- hello
```

Primitive CLI arguments currently include compact handling for:

- Nat;
- Int;
- Bool;
- String;
- Unit.

Supported structures/ADTs use the strict checked JSON ABI.

## `psc translate`

```bash
psc translate input.ps --to lean
psc translate Input.lean --to ps
```

Performs canonical source translation for the supported common subset.

Lossy translation must fail.

## `psc emit-lean`

```bash
psc emit-lean input.ps
```

Print canonical Lean lowering for supported source.

## `psc clean`

Remove the configured output directory.

## `-p, --project`

Select a `psconfig.json` file or a directory containing it.

Without `-p`, the CLI searches upward from the working context for
`psconfig.json`.

## `--json`

Where supported, request machine-readable command output.

## Historical `--verified`

The old flag may be accepted as a deprecated compatibility marker in parts of
the CLI history, but it no longer selects a separate stronger semantic
pipeline.

The checked-core path is the normal path.

## Bootstrap CLI note

The self-host workspace also contains bootstrap-specific `psc1` commands and
diagnostic helpers.

Those are not the normal public `psc` command reference and should not be
mixed into everyday user docs.
