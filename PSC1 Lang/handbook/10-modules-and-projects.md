# Modules and Projects

PSC1 projects are organized around logical module names, source roots, and a
single checked dependency graph.

A module's source file may be native ProofScript or the bounded supported Lean
subset, but both converge before semantic acceptance.

## Imports

A module imports another logical module with:

```proofscript
import ProofScript.Data.Option
```

The logical name is mapped to a path below the project's source roots.

For example:

```text
ProofScript.Data.Option
```

maps to a candidate path such as:

```text
ProofScript/Data/Option.ps
```

or:

```text
ProofScript/Data/Option.lean
```

## One logical module, one source

PSC1 project resolution requires exactly one source candidate for a logical
module.

If both:

```text
Foo/Bar.ps
Foo/Bar.lean
```

exist under the searched roots for `Foo.Bar`, the project fails with an
ambiguity diagnostic.

Likewise, if two configured roots each contain a matching source, the resolver
does not silently choose the first root.

This rule keeps builds deterministic.

## `psconfig.json`

Current project configuration:

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

## Entry source

`entry` identifies the project entry.

Current normal entries may be:

- `.ps`;
- supported bounded `.lean`.

The source extension selects a frontend, not a different semantic checker.

## Source roots

If `sourceRoots` is empty or omitted, imports resolve relative to the entry
source directory.

If it contains project-relative directories:

```json
{
  "sourceRoots": ["src", "vendor"]
}
```

all configured roots are searched.

Each root must be a non-empty relative path.

## Dependency graph

Modules are built in deterministic dependency order.

A module receives the checked declarations of its transitive imports, not
unrelated sibling declarations.

This prevents accidental ambient project state from changing the meaning of a
module.

## Mixed-source projects

A project can intentionally mix supported source forms:

```text
Main.ps
  imports Data

Data.lean
  imports Logic

Logic.ps
```

All three eventually contribute to the same checked environment.

The source kind affects parsing and canonical printing.

It does not affect proof authority or backend semantics.

## Canonical source identity

The dual-source design can normalize equivalent source forms to a common
canonical identity/hash.

For example, a ProofScript `function` and an equivalent Lean `def` can
represent the same checked declaration even though their source text differs.

This is more useful than demanding byte-identical source.

## Checked module artifacts

ProofScript's broader architecture supports deterministic checked module
artifacts containing:

- declaration payload;
- semantic/kernel compatibility metadata;
- dependency integrity;
- artifact integrity.

A valid artifact hash is not permission to skip kernel admission.

Integrity and proof validity are separate ideas.

## Build cache

A compiler can cache checked module work using semantic/source/dependency
integrity keys.

A cache hit is an optimization.

It must not create a second semantic path with weaker checks.

## npm is the package substrate

ProofScript intends to live in the JavaScript/npm ecosystem instead of
reimplementing an entire package manager.

That means:

- `package.json` can manage JavaScript ecosystem packages;
- `psconfig.json` configures ProofScript compilation;
- runtime FFI dependencies are explicitly declared;
- generated JavaScript can participate in npm projects.

npm metadata does not define proof semantics.

## `psc init`

Current application scaffold:

```bash
psc init my-app
```

creates:

```text
my-app/
  src/main.ps
  psconfig.json
  package.json
  .gitignore
```

For a library:

```bash
psc init my-lib --lib
```

uses `src/index.ps`.

## Check, build, and run

```bash
psc check
psc build
psc run -- 1
```

All three use the one checked semantic pipeline.

The historical `--verified` concept no longer selects a stronger separate
path; the checked-core path is unconditional.

## Project integrity vs runtime dependency integrity

Logical module/project integrity tracks the checked ProofScript dependency
graph.

Runtime npm dependency integrity tracks the external host code required by FFI.

They must remain distinct because host package identity does not change the
meaning of a theorem into proof evidence.

## Editors

The language service should use the same project/source-resolution model as the
compiler.

That keeps:

- diagnostics;
- go-to-definition;
- imports;
- source kind;
- checked project context;

consistent between editor and CLI.

## What modules do not imply

PSC1 modules do not automatically mean:

- JavaScript runtime module objects;
- CommonJS semantics;
- TypeScript namespaces;
- Lean's full command/module system;
- first-root-wins path lookup.

Backend and host module formats belong downstream.

## Next

Continue to [Interop and FFI](./11-interop-and-ffi.md).
