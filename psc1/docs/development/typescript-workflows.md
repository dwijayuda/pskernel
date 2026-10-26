# TypeScript workflow research and ProofScript CLI decisions

Researched 2026-10-26 from official TypeScript, npm, Node and VS Code documentation.
This is an implementation decision record, not a survey of all developers.
The behavior hypotheses below are inferences from supported workflows; real
user testing is still needed. The unassisted maintainer exercise is separate.

## What to learn from TypeScript

1. TypeScript exposes project configuration, explicit -p selection, init,
   help/version and showConfig. A project file makes repeated invocations
   reproducible. Its source-file CLI mode can ignore project configuration,
   which is an easy ambiguity to avoid in a new CLI.
   [Official compiler CLI](https://www.typescriptlang.org/docs/handbook/compiler-options.html),
   [project definition](https://www.typescriptlang.org/docs/handbook/tsconfig-json.html).

2. Local npm scripts and npm exec make tool versions project-owned rather than
   dependent on a global installation. npm's -- separator matters for forwarding
   flags. Newcomers need one runnable sequence, while automation needs stable
   stdout and exit behavior.
   [npm scripts](https://docs.npmjs.com/cli/v11/using-npm/scripts/),
   [npm exec](https://docs.npmjs.com/cli/commands/npm-exec/).

3. TypeScript's watch/incremental machinery is an actual compiler dependency
   strategy, not just a file-watcher around one shell command. Watch
   configuration has platform-specific concerns. ProofScript cannot claim
   equivalent performance or transactional semantics by adding --watch to a loop.
   [Watch configuration](https://www.typescriptlang.org/docs/handbook/configuring-watch.html),
   [incremental builds](https://www.typescriptlang.org/tsconfig/incremental.html),
   [official compiler API](https://github.com/microsoft/TypeScript/wiki/Using-the-Compiler-API).

4. TypeScript explains compiler errors in terms users can understand.
   VSCode integrates compilation as tasks and problem matching, but an adapter
   must receive real compiler-origin positions to populate a useful problem.
   Guessing spans from substrings is unsafe for imports, generated declarations
   and Unicode.
   [Understanding errors](https://www.typescriptlang.org/docs/handbook/2/understanding-errors.html),
   [VSCode task/problem matching](https://code.visualstudio.com/docs/editor/tasks).

5. TypeScript favors understandable JavaScript, existing runtime behavior,
   cross-platform tooling and composability; its design explicitly does not
   promise a sound type system. Its default noEmitOnError behavior permits
   emission after errors. Those trust/emission choices cannot be copied into
   ProofScript's fail-closed independent admission/publication model.
   [Design goals](https://github.com/microsoft/TypeScript/wiki/TypeScript-Design-Goals),
   [noEmitOnError](https://www.typescriptlang.org/tsconfig/noEmitOnError.html).

6. Node spawn supports argument arrays without shell interpretation, streams
   with backpressure and child close/error events. A CLI can keep signals and
   bounded diagnostic capture without blocking its parent event loop during
   the existing synchronous compiler session.
   [Node child process](https://nodejs.org/docs/latest-v22.x/api/child_process.html).

## Developer behaviors to support and test

| Workflow hypothesis | Concrete task | Acceptance |
| --- | --- | --- |
| New user starts by asking for help | psc / psc --help | Exit0, complete commands/engine/target distinction; no compiler or kernel load |
| User creates a project once and edits source files repeatedly | init; edit Main.ps; check/build | Editable source plus source-only config; each invocation captures current exact bytes |
| User needs to understand why a project selected a source | --showConfig / -p path | Exact source paths, bytes/hashes, no admission or output claims |
| User automates checks through npm | npm run check / npm exec -- psc check | Actual local/global installed bin shims, stable JSON success and nonzero refusal |
| User confuses output language with compiler implementation | --engine ts versus --target ts | Explicit help, all seven targets and optional dependency diagnostics |
| CI/tools need parseable errors | --diagnostics json | Schema/code/original message; stdout stays clean on refusal |
| User fixes an error after a successful build | ill-typed source; rebuild same out | Existing generation pointer and bytes retained; no weakened independent checking |
| User runs in paths containing spaces or with Unicode source | file project in space directory | No shell concatenation; exact bytes and runtime observations |

These hypotheses do not establish frequency or measured satisfaction. Actual
installed tests exercise the tasks; participant feedback must establish
understandability. Keep timings as observations rather than performance claims.

## Current implementation boundary

The new proofscript-cli.mjs handles presentation, finite argv validation,
project capture and process transport. cli-project.mjs handles source-only
configuration and bounded snapshots. Both delegate to the byte-unchanged
universal-cli.mjs and universal.mjs checked session. New entry points are
manifest-pinned host resources; neither creates a second compiler.

The file project is intentionally smaller than tsconfig. It has no inheritance,
plugins, executable JavaScript, globs or compiler/SDK/output selection. It lists
all modules in deterministic compiler order. Explicit command-line host options
are composed only by the existing checked API. No parent-directory project
search makes unrelated parent files silently control an invocation.

The adapter uses ordinary Node APIs and no new runtime dependency. Existing
official Lean4.35, strict IR, negative tests, resource bounds and fixed-point
identities remain unchanged. The .8 candidate changes host entry points and
package documentation only. A fast assembler verifies a previously successful
exact .7 installed artifact, compares every retained production host source
against the current checkout, preserves every executable payload byte, and rebuilds only
the host root manifest/package. Real installed testing also exposed reverse
optional peers from the three emit-only component/Python/PHP tools to exactly
the .7 root. Installing these after a .8 root let npm prune that root. The .8
tool metadata repacks remove this unnecessary reverse dependency; workers,
runtimes and all other tool files remain byte-identical. The root still
requires each exact optional tool version, manifest and resource hash. This
separates npm installation topology from checking authority. Canonical full
assembly uses the same new CLI and decoupled emit-only package metadata.

The older seven-target capability document deliberately continues describing
the qualified .7 artifact; the new CLI guide explicitly labels the .8 candidate.
Do not retroactively assign new CLI behavior to the old tarball.

## Ordered follow-through

1. Qualify this finite project/CLI task matrix on real installed artifacts,
   then rerun all existing local/global/kernel/publication/application/backend
   and packed-type regressions. Preserve failed attempts and exact hashes.
2. Gather the independently arranged human exercise result and a small CLI
   task trial. Record help needed and ambiguities; do not infer usability from CI.
3. Add compiler-origin structured diagnostic transport, with exact source
   identity/spans and explicit unlocated errors, before claiming editor problem
   matching or a language server.
4. Consider watch only after dependency identities, cancellation, stale-input
   refusal and publication ordering have exact tests. Never reuse old admission
   because an mtime looks unchanged.
5. Add general package resolution/extensions only under the existing closed
   authority constraints. Keep platform release execution and authorization
   distinct from Linux development qualification.

## Exact source during application replay

The installed application regression originally captures compiler sources from
its working directory and checks their exact closure against the package.
The new development tree already has the PR #190 body-preserving module extraction;
it has 123 modules, while the unchanged packaged G3 has 122. Comparing these as
if they were one source identity would be incorrect.

The CLI application supervisor extracts the exact ancestral commit 8383c698 compiler
source in Linux CI, checks its ancestry, and invokes the unchanged current
application test there against the new installed package. All existing source,
census, contract, admission and runtime assertions remain. A separate receipt
records snapshot and tested commits. The ordinary source workflow continues to
test the actual current 123-module tree. Neither route promotes that tree to G3.

## Qualified result

[CLI/toolchain run 40314294152](https://github.com/dwijayuda/pskernel/actions/runs/40314294152)
passes 19 source groups, 55 installed requests and every preserved installed,
application, kernel, dispatch, publication and packed-type gate. The exact
[dated receipt](../PSC1_CLI_QUALIFICATION_2026-10-26.json) records source/package
identities and failed attempts. [Ordinary source 40314305497](https://github.com/dwijayuda/pskernel/actions/runs/40314305497)
passes all 37 finite Practical Core criteria. This is a Linux engineering
qualification; independent human comprehension, watch/editor features and final
universal release remain separate.
