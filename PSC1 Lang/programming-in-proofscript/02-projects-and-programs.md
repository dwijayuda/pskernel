# 2. Projects and Programs

PSC1 uses a familiar JavaScript-ecosystem project shape while keeping its own
semantic compiler configuration.

## Create an application

```bash
psc init my-app
cd my-app
psc check
psc build
psc run -- 1
```

The current scaffold contains:

```text
my-app/
  src/main.ps
  psconfig.json
  package.json
  .gitignore
```

## A program entry

A minimal application may look like:

```proofscript
const answer: Nat := 42;

function main(x: Nat): Nat :=
  x + answer;
```

`psc run -- 1` builds the checked program and invokes exported `main`.

## The project configuration

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

PSC1's first frozen profile is narrower than "all syntax historically described
by v0.7"; the active self-host profile and conformance docs define the claim
ceiling.

## Modules

```proofscript
import ProofScript.Data.Option
import ProofScript.Data.List
```

A logical name maps to exactly one `.ps` or supported `.lean` source under
the project roots.

Ambiguity is an error. Root order does not silently choose a winner.

## Libraries

```bash
psc init my-lib --lib
```

uses `src/index.ps` as the initial entry.

PSC1 libraries can later be distributed through npm while preserving their
ProofScript sources and generated artifacts.

## Check vs build vs run

`psc check` verifies the project without treating target emission as semantic
authority.

`psc build` continues from checked core through erasure and VerifiedIR.

`psc run` executes the generated runtime artifact.

Conceptually:

```text
check: source -> pskernel checked declarations

build: checked declarations -> erasure -> VerifiedIR -> backend

run: build -> host invocation of main
```

## Dual-source projects

PSC1 can mix native `.ps` and the bounded supported `.lean` subset.

Both source kinds converge before kernel admission.

The extension chooses a frontend and printer, not a stronger or weaker checker.

## Generated TypeScript

The primary runtime backend currently emits TypeScript and uses pinned `tsc`
to produce JavaScript, declarations, and source maps.

Generated TypeScript is intentionally inspectable, but it does not redefine
PSC1 semantics.

## Runtime dependencies

Host/npm dependencies must be explicitly declared.

That keeps ordinary PSC1 source portable and makes target-specific assumptions
visible.

## Editor feedback

The repository contains a language service/VS Code integration. The intended
experience, learned from Lean's editor-driven workflow, is that source spans,
diagnostics, type information, and proof state become available while editing
rather than only after a batch build.

## Next

Continue to
[Propositions, Proofs, and Safe Indexing](./03-propositions-proofs-and-indexing.md).
