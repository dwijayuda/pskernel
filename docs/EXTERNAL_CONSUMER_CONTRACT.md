# External consumer contract — feasibility spike

Status: experimental on `integration/proofscript-extraction-feasibility`.

This document does **not** make the root package a published release. It defines
the smallest package/API boundary needed to test ProofScript consuming the
standalone kernel without copying trusted source.

## Dependency direction

```text
ProofScript -> lean-ts-kernel
```

The reverse dependency is forbidden.

## Stable façade used by the spike

External consumers may use only the root package exports from `src/index.ts`:

- `Name` constructors/comparison;
- universe `Level` constructors/operations;
- kernel `Expr` constructors;
- `Environment`;
- `Kernel` admission;
- `TypeChecker` when diagnostic/inference access is actually required;
- inductive admission through the explicitly exported `addInductive` API.

Imports from `src/core/*` or `src/kernel/*` are not part of the consumer
contract.

## Packaging

The repository remains `private: true`; the spike does not authorize npm
publication. A `prepare` script builds the root façade when the repository is
used as a git dependency. The `files` allowlist keeps the packed consumer
surface limited to built root library output and trust-boundary documentation.

## Gate

```bash
npm run test:public-consumer
```

The test imports the package by its own public package name and admits the
dependent identity function using only the public façade.

## Non-goals

This spike does not expose parser, elaborator, tactics, compiler, runtime,
TypeScript backend, language service, or LSP from the kernel package. Those
remain outside the TCB and are candidates to live in the ProofScript product
repository.
