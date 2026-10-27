# ProofScript CLI

This guide covers the runtime/watch candidate `proofscript@0.1.0-psc1.11`.
Its [runtime/watch receipt](../PSC1_RUNTIME_WATCH_QUALIFICATION_2026-10-27.json)
records qualification separately; the previous .9 layout evidence below does not
qualify the .10 package. Install only the matching candidate whose receipt passed. [The layout receipt](../PSC1_LAYOUT_QUALIFICATION_2026-10-26.json)
records actual CI status, exact source/package identities and artifact information.
Use its root and matching optional tarballs only after its installed gate passes.
The preceding .8 qualification remains in the
[original CLI receipt](../PSC1_CLI_QUALIFICATION_2026-10-26.json).
GitHub Actions artifact downloads require GitHub sign-in. Extract the archive and
find slim-universal/tarballs/ plus slim-universal/package-receipt.json. Its receipt
contains the root hash/size and all exact optional versions; never mix tarballs
from different receipts. Nothing is published to the npm registry.

## Start a project

With Node >=22.23.3, copy the root tarball into your project directory. Initialize
package.json if needed, then install and run:

```sh
npm init -y
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.11.tgz
npm exec -- psc init
npm exec -- psc --showConfig
npm exec -- psc check
npm exec -- psc build --out dist/app --publication-protocol portable-file
```

For the default JS output, save this as observe.mjs after building:

```js
import {readPublication} from 'proofscript';
import {pathToFileURL} from 'node:url';

const current = readPublication({
  out: 'dist/app',
  publicationProtocol: 'portable-file',
});
if (!current) throw new Error('Build the project first.');
const app = await import(pathToFileURL(current.target).href);
console.log(String(app.answer)); // 42
```

Run node observe.mjs from the project directory. The lookup verifies the
publication inventory and returns its immutable generation. Manifest integrity
does not replace the original independent checking. Executing your application
is a separate explicit action from compiling it.

init creates Main.ps and proofscript.json. Use init --kind lean for Main.lean.
Existing files refuse initialization; there is no force overwrite option.
Creation is exclusive but is not a two-file transaction: a late error creating
the config can leave the new source file, which is deliberately preserved.

The default source is:

```lean
def answer : Nat := 42
```

The generated project is editable source metadata:

```json
{
  "schema": "proofscript-project/1",
  "entryModule": "Main",
  "files": [
    {"module": "Main", "path": "Main.ps"}
  ]
}
```

Add imports in the program and list every dependency explicitly, in the
compiler's expected dependency order. Module names may be dotted. Paths are
relative to this project file; they use forward slashes. The CLI snapshots
exact bytes before creating the existing checked compiler session. A file
change is seen by the next invocation or watch rebuild. There is no implicit source discovery,
glob expansion, npm source loading, JavaScript project configuration or plugin
execution. Existing inline {entryModule,sources,assurance} projects still work.

check/compile/build with no source use proofscript.json in the current
directory only. The CLI does not search parent directories. -p accepts either
a JSON file or a directory containing proofscript.json. Explicit sources and
-p cannot be combined. Existing single-file commands still work:

```sh
psc check Main.lean
psc compile Main.ps --engine ts
psc build -p examples/project -o dist/example
psc build Main.ps --target ts --out dist/ts
psc --help
```

## Live source changes

Use the same checked build with --watch (aliases -w and -watch):

```sh
npm exec -- psc build --out dist/app --publication-protocol portable-file --watch
npm exec -- psc build Main.ps --target ts --out dist/ts --watch
npm exec -- psc build Main.lean --target rust --out dist/rust -w
npm exec -- psc build -p . --target wasm-core --out dist/wasm -watch
npm exec -- psc check --watch
```

TS/Rust output still needs the exact optional consumers/SDKs described below.
Use the immutable artifact/runtimeArtifact paths in each success receipt: TS
includes target.ts, target.mjs and target.d.ts; Rust includes target.rs and a
checked rlib; Wasm includes target.wasm and its typed JS transport. JS target
uses target.mjs. File extensions .js/.ts/.rs are output representations, not
different source grammars. The compiler never executes an application on save.

Only declared inputs and the selected project JSON are observed. A 500ms
metadata poll detects dependencies, atomic editor replacements, deletions,
recreation and project file-list edits. It avoids recursive watcher platform/
inode differences and output-triggered loops. Saves debounce; attempts run
serially. Every attempt performs a full bounded source recapture, genuine
independent admission and the existing target consumer checks. This first
version has no incremental semantic cache or claim of TypeScript watch speed.

Edits during checking mark the next attempt dirty. A private worker verifies
the captured identity before execution and again immediately before publication;
a superseded result refuses publication. A save after that last guard is
processed by the next queued attempt. Failed/invalid/missing sources retain
the last committed generation and resume after repair. No automatic SDK
installation, source globs or plugin execution occurs. Existing publisher
lock/orphan recovery and retained generation policies remain; watch does not
silently remove output history.

Each success is one unchanged JSON receipt line on stdout. Progress and errors
go to stderr; --diagnostics=json uses proofscript-watch-event/1 for progress and
the existing diagnostic schema for errors. No terminal clearing or fabricated
compiler spans. Ctrl+C exits130; SIGTERM exits143. Linux termination targets
the attempt's process group with a2s kill escalation. --showConfig and --watch
are deliberately incompatible.

## Runtime compatibility

Node's user requirement is >=22.23.3, matching the bundled kernel's minimum,
not one exact patch. Newer Node majors are allowed. CI records exact
tested runtime versions and executable hashes separately. The new Node/Bun
matrix must pass before claiming this candidate qualified; later untested
versions are a compatibility policy, not automatically new CI evidence.

Bun >=1.4.4 is the additional runtime under qualification. After the npm tarball
installation above, run the locally installed CLI explicitly under Bun:

```sh
bun --no-install --no-env-file run --bun psc check
bun --no-install --no-env-file run --bun psc build --out dist/app --watch
```

The --bun flag matters: Bun otherwise respects a CLI's Node shebang. Installed
Bun runtime tests use actual Bun processes; npm remains the tested installer.
The host-controlled child launches disable automatic installs, macros and implicit env files.
Bun's --check has different behavior from Node's parse-only check, so the host
uses an explicit Bun JS parser and still runs the mandatory separate export/API
consumer. Default independent checking stays the genuine official Lean Wasm
kernel. Deno/other runtimes, additional platforms, Bun package-manager offline
installation and performance qualification remain unqualified.

## Engine, target and independent checker

--engine selects which qualified self-hosted compiler executes: js (default),
ts, rust or wasm-core. --target selects its output: js (default), ts, rust,
wasm-core, wasm-component, python or php. Selecting the TS engine does not
implicitly select TS output. --kernel wasm (default), native or both selects
independent Lean checking. --provider remains a checker alias.

| Command | Executing compiler | Output | Independent checker |
| --- | --- | --- | --- |
| psc compile Main.ps | JS | JS | Lean Wasm |
| psc compile Main.ps --engine ts | TS | JS | Lean Wasm |
| psc build Main.ps --target ts --out dist/ts | JS | TS, with the explicit pinned SDK | Lean Wasm |
| psc compile Main.ps --engine rust --kernel both | Optional Rust engine | JS | Wasm and native Lean |

The default checker is the genuine official Lean 4.35 C++ kernel compiled with
Emscripten to linear-memory Wasm. Compiler Wasm uses GC. No frontend or proof
checking is replaced by this adapter.

Optional Rust/Wasm engines and non-JS output consumers/providers keep their
exact package and platform requirements. Missing optional dependencies refuse
with their existing pinned package diagnostic. The CLI does not install them
or download an SDK. --rust-toolchain-root remains an explicit host-owned path.
Rust output requires the exact qualified 1.90.0 SDK resource hashes, including
rustup bookkeeping; an ambient installation's version number alone is insufficient.
With the matching optional Rust consumer installed, use a fresh isolated SDK on
qualified Linux x64 rather than modifying your existing toolchain:

```sh
RUSTUP_HOME="$PWD/.proofscript-sdk/rustup" rustup toolchain install 1.90.0 --profile minimal
npm exec -- psc build Main.ps --target rust --out dist/rust --rust-toolchain-root "$PWD/.proofscript-sdk/rustup/toolchains/1.90.0-x86_64-unknown-linux-gnu" --watch
```

The CLI checks every resource and never rewrites a mismatching SDK.
See the existing checked-dispatch installation guide for those dependencies;
use this candidate's root and optional tarballs from its package receipt.
Rust/Wasm engines use .11 host/metadata repacks with exactly retained G3 native/
Wasm compiler payloads. The Rust transport uses the shared minimum runtime policy;
both optional packages' npm engines accept newer Node versions. Their manifests
and resource pins are refreshed explicitly. Component/Python/PHP tools are .11
metadata-only repacks with identical workers/runtimes and no reverse root peer
that could make npm prune the installed compiler.

Projects contain sources and optional assurance only. They cannot choose
engine, kernel, output, SDKs, checkers, services or publication policy. Pass
those options on the command line or in your own package.json scripts:

```json
{
  "scripts": {
    "check": "psc check",
    "build": "psc build --out dist/app --publication-protocol portable-file"
  }
}
```

npm run check / npm run build use your locally installed executable.
npm exec -- psc ... forwards options after npm's -- separator. proofscript,
psc and psc1 are aliases of the same installed entry point. Source checkout
npm run psc remains the existing native development wrapper, not this package.

## Outputs, errors and inspection

check runs the existing checked target pipeline, including target emission
and consumer validation. It suppresses the returned source field. It is not a
new frontend-only typecheck or a faster implementation of TypeScript's noEmit.

compile returns checked source and receipt as JSON on stdout and publishes no
generation. build requires explicit --out, returns immutable artifact and
runtimeArtifact paths, and retains existing Linux-qualified transactions.
Read build's artifact path from its receipt; do not guess current symlink names.
Publication stores retain the existing non-symlink directory policy. A helper
cannot bypass it by sharing an output root through a symlink.
The build receipt and publication manifest remain the existing schemas.

--showConfig prints project location, declared source paths, exact byte
counts/hashes and command-line selections. It does not invoke a compiler,
resolve an SDK, admit a proof or publish output. logicalAdmission:not-run and
publication:not-requested are explicit. Legacy inline sources are labelled
legacy-inline and omitted from this display.

--version prints a package name/version. --identity retains verified JSON
installation metadata and compiler identities. Use --identity in scripts that
previously consumed JSON from --version. This is the one intentional
presentation change; compiler success JSON remains unchanged.

Failures use nonzero exit codes and stderr. --diagnostics json gives one
proofscript-cli-diagnostic/1 JSON diagnostic containing code, original message
and an optional actionable hint. --diagnostics text is the default. No source
location, type explanation or admission result is fabricated by the host.
The original compiler diagnostic remains present. Process interruption maps
SIGINT/SIGTERM to 130/143. Diagnostics retain a 32 MiB cap; stdout is streamed.

A publication error can occur after commitment. In particular,
PSC1_SERVICE_PUBLICATION_COMMITTED_DURABILITY_UNCERTAIN means inspect the
store; do not assume rollback. The adapter adds a hint but retains the exact
original error. A signal/kill can leave existing publisher locks/orphans.
The CLI does not take over stale locks or remove prior generations.

## Bounds and scope

File projects allow at most 4,096 explicitly declared sources. Every input and
total captured source text are bounded by 128 MiB, and the encoded source project
must also fit 128 MiB. Existing inner request/response bounds still apply.
Both grammars are tested separately; the adapter adds no mixed-grammar semantics.
Files use fatal UTF8 decoding with BOM preservation, regular-file checks,
bounded reads, snapshot change checks and relative non-symlink path traversal.
A same-user hostile directory owner racing path components is not an OS
sandbox threat model; use a stable host-owned project directory.

The project adapter does not change independent checker 120s, per compiler/tool
request 240s, semantic fuel, original/transformed strict IR, source/body pairing,
memory/stack, optional-tool lifetime policies or negative tests. It does not
promote the later development compiler into the frozen 122-module
G3 payloads. It does not qualify a new G2/G3 chain.

The preceding CLI behavior passed its recorded Linux run, including all existing
application/kernel/dispatch/publication/type regressions and the new CLI tasks.
Portable Node implementation does not establish actual Windows/macOS
publication. A public arbitrary extension SDK, incremental semantic caching,
richer compiler-origin structured diagnostics and final registry publication
remain separate work. The independent human maintainer trial remains pending
its arranged participant; CLI automation is not human usability evidence.

## Find the implementation

The developer adapter is deliberately separate from checking authority:

| Responsibility | Source |
| --- | --- |
| Help, diagnostics, child transport and signals | [proofscript-cli.mjs](https://github.com/dwijayuda/pskernel/blob/7c27d754550ed92cd8ab19a51f8c768a919963b0/psc1/npm-cli/proofscript-cli.mjs#L66) |
| Finite options and source-only project capture | [cli-project.mjs](https://github.com/dwijayuda/pskernel/blob/7c27d754550ed92cd8ab19a51f8c768a919963b0/psc1/npm-cli/cli-project.mjs#L62) |
| Watch supervision / guarded attempt | [cli-watch.mjs](../../npm-cli/cli-watch.mjs), [cli-watch-worker.mjs](../../npm-cli/cli-watch-worker.mjs) |
| Runtime requirements / syntax consumer | [runtime-policy.mjs](../../host-tools/runtime-policy.mjs) |
| Bounded exact-byte file snapshots | [readInput](https://github.com/dwijayuda/pskernel/blob/7c27d754550ed92cd8ab19a51f8c768a919963b0/psc1/npm-cli/cli-project.mjs#L19) |
| Exclusive initialization | [initializeProject](https://github.com/dwijayuda/pskernel/blob/7c27d754550ed92cd8ab19a51f8c768a919963b0/psc1/npm-cli/cli-project.mjs#L205) |
| Existing checked command and API, unchanged | [universal-cli.mjs](https://github.com/dwijayuda/pskernel/blob/7c27d754550ed92cd8ab19a51f8c768a919963b0/psc1/npm-cli/universal-cli.mjs), [universal.mjs](https://github.com/dwijayuda/pskernel/blob/7c27d754550ed92cd8ab19a51f8c768a919963b0/psc1/npm-cli/universal.mjs) |

The source snapshot is passed as private source data to the existing command.
It cannot nominate a checker, SDK or service executable. Follow the existing
compilation walkthrough/pass contracts for the inner independent admission,
strict IR, target validation and publication boundaries.

## License

ProofScript-owned components use Apache-2.0. The installable ZIP and owned npm
tarballs include LICENSE and NOTICE. Upstream dependency/runtime notices retain
their original terms. [Licensing policy](../reference/licensing.md).
The compiler's license does not determine a user's application license.
