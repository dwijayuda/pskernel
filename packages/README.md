# ProofScript packages

The repository uses npm workspaces for `packages/*`. These packages are the
bootstrap implementation around the independent TypeScript Lean 4.34 kernel.

## Execution priority

ProofScript package work is governed by
`docs/plans/07_SELF_HOSTING_FOUNDATION.md`.

Until the self-hosting foundation closes, do not expand package infrastructure
merely for completeness. New work must either close a self-hosting gate, supply
a standard-library prerequisite required by the compiler, or maintain an
existing gate.

The former `@proofscript/language` software checker was retired on
2026-09-24. There is one semantic compiler path:

```text
.ps / supported .lean
-> syntax
-> Meta / Elab
-> pskernel admission
-> checked core
-> erasure
-> verified compiler IR
-> TypeScript
-> tsc
-> JavaScript
```

## Status source of truth

See `package-map.json` for package path, phase, trust classification,
implementation status, and dependency direction.

Current package groups include:

- kernel ecosystem: `cli`, `module`, `conformance`, `lean4export`, `browser`;
- frontend: `syntax`, `pretty`, `meta`, `elab`, `tactic`, `environment`;
- checked compiler: `checked-core`, `erasure`, `compiler-ir`, `runtime`,
  `backend-ts`, `compiler`;
- tooling: `language-service`, `lsp`, `project`.

## Trust rule

A support package may parse, elaborate, compile, transport, display, or
orchestrate declarations, but it does not make them trusted. Logical authority
remains pskernel admission.

The TypeScript kernel stays independently checkable and must not depend on
outer ProofScript packages.

## Source language policy during bootstrap

TypeScript remains the bootstrap and host implementation language while the
SH1-SH7 foundation is being closed.

New **semantic** compiler logic should be designed so it can move to the frozen
Lean bootstrap subset and then to ProofScript without redesign. TypeScript is
also expected to remain for explicit host adapters such as Node filesystem,
npm/module resolution, the TypeScript Compiler API, and VS Code transport.

Once SH7 closes, compiler-owned semantics migrate in the order defined by the
self-hosting plan: bounded `.lean` first, then `.ps`.

## Cross-package gates

`npm run test:packages` compiles/tests the workspace packages.
`npm run test:package-integration` exercises the cross-package checked-core
pipeline. `npm run check:architecture` enforces dependency direction and
rejects reintroduction of the retired legacy semantic path.
