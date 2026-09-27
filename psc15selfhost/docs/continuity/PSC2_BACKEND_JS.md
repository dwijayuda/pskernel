# PSC2 direct JavaScript workstream

Date: 2026-09-27
Branch: `psc2/backend-js`
Base: `120ab07bcbf837dc8bcad5d5bc239e86760aa28f`
Parent workstream: `psc2/minimal-selfhost-psc15`
Workspace: `psc15selfhost/`

## User intent

Study the minimal PSC15 self-host branch and `PSC2_NEXT_BOOTSTRAP.md`, create
a separate branch for the JS backend, and keep its implementation in the actual
PSC1-compatible `.lean` subset so it can participate in self-hosting.

This branch owns direct JS work. It must not push its changes to the active
minimal-selfhost or kernel-core branches. Preserve npm package boundaries.

## Authorization update (2026-09-27)

The user instructed: "Safely ignore the requirement of freezing TS first, work
on backend js now to be merge later". This supersedes the development-order
restriction recorded below. Implement on this branch now, preserve the TS root,
and leave integration and authority cutover gated. No merge is authorized by this
instruction. The next-bootstrap architecture and semantic requirements still apply.

## Initial study result and original prerequisite

This commit establishes the workstream and design, not an implemented backend.
There is no `backend-js` package or direct-JS fixed point yet.

The base's `STATUS.md` still requires runtime fixed-point evidence. The next
bootstrap document (D1 and sections 11 and 15) explicitly says to freeze the
current TS fixed point before starting direct-JS implementation. Honor that
ordering. Preparing this isolated branch does not replace or freeze that path.

At the study checkpoint, the base's GitHub Actions run `36314738889` was still
in progress. Its workflow, `PSC2 minimal kernel`, tests kernel parity and source
compatibility; it does not execute `npm run fixed-point`. Even a successful run
of that workflow is not Generation A fixed-point evidence.

Before implementing the design, obtain the successful TS fixed-point source and
compiler comparisons for a specific commit, with toolchain and artifact hashes.
Synchronize that frozen baseline into this branch without rewriting either
workstream's history. The parent workstream owns repairs to its current fixed
point; do not duplicate that work here or silently bypass it.

## Repository study

The architecture already provides the correct seam:

`Compiler.Api -> AdmissionReadyModule -> validated preparation -> VerifiedIR`.

`PsCompilerAdmissionReadyModule` is not kernel-issued `CheckedCore`. Preserve
that distinction in the JS adapter and generated artifact descriptions.

`packages/compiler-ir/src/Ps/CompilerIr/Model.lean` defines literals, variables,
intrinsics, typed lambdas and lets, calls, conditionals, records, projections,
constructors, and matches. It also carries declarations, imports, structures,
inductives and semantic machine-integer types. This is the backend input contract.

The TS backend currently owns representation and emission in `Type.lean`,
`Expr.lean`, and `Module.lean`. `Compiler.lean` is a thin composition adapter.
Study it for differential cases; do not import it into direct JS or strip types
from its emitted text. Its module banner currently mentions admitted checked
core, although the architecture documents the weaker admission-ready boundary;
do not copy that assurance claim into new output.

`check-psc1-source.mjs` is a lexical audit. It cannot establish executable source
compatibility. `check-kernel-core-source.mjs` illustrates the stronger requirement
to invoke `lake exe psc1 check` on the real source closure, but its kernel-only
import resolver cannot be reused unchanged for backend modules.

## Baseline checks actually run

Commands below ran from `psc15selfhost/` at the recorded base on 2026-09-27.

| Command | Result |
| --- | --- |
| `npm run check:workspace` | PASS; 20 workspaces |
| `npm run check:source:bootstrap` | PASS; lexical audit of 59 modules, 12 roots |
| `npm run check:layout` | PASS; 15 module sections, 4 consumers |
| `npm run check:bootstrap-closure` | PASS; 54 closure modules, 12 packages |
| `npm run check:ir-neutrality` | PASS; 2 IR source files |
| `npm run check:semantic-boundaries` | PASS; 100 production Lean modules |
| `npm run build:lean` | BLOCKED; exit 127, `lake: not found` |
| `npm run test:bootstrap` | Not run; Lean toolchain unavailable |
| `npm run fixed-point` | Not run; no runtime fixed-point claim |

No JS execution, differential, source round-trip, compiler fixed-point, or formal
preservation result is claimed by this documentation commit.

## Continue here

Read the [backend design](../design/PSC2_BACKEND_JS.md), then the current parent
branch status and its actual fixed-point evidence. Recheck branch HEADs because
other sessions are actively working. Do not mistake this recorded base for the
latest upstream commit.

After the prerequisite closes, begin with failing literal/module differential
fixtures, implement the smallest portable slice, then expand coverage only with
source compilation and execution evidence. Keep a distinction between Lean build,
PSC1 source compatibility, JS differential parity, and actual self-host fixed point.
