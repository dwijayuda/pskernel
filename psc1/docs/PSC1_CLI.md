# ProofScript CLI

This guide describes the new host CLI candidate (proofscript0.1.0-psc1.8).
It does not describe the unchanged .7 artifact. Use the exact tarballs from the
qualified Linux Actions run; nothing has been published to the npm registry.

## Start a project

After installing the candidate tarball into your project, run:

```sh
npm exec -- psc init
npm exec -- psc --showConfig
npm exec -- psc check
npm exec -- psc build --out dist/app --publication-protocol portable-file
```

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
change is seen by the next invocation. There is no implicit source discovery,
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

## Engine, target and independent checker

--engine selects which qualified self-hosted compiler executes: js (default),
ts, rust or wasm-core. --target selects its output: js (default), ts, rust,
wasm-core, wasm-component, python or php. Selecting the TS engine does not
implicitly select TS output. --kernel wasm (default), native or both selects
independent Lean checking. --provider remains a checker alias.

The default checker is the genuine official Lean4.35 C++ kernel compiled with
Emscripten to linear-memory Wasm. Compiler Wasm uses GC. No frontend or proof
checking is replaced by this adapter.

Optional Rust/Wasm engines and non-JS output consumers/providers keep their
exact package and platform requirements. Missing optional dependencies refuse
with their existing pinned package diagnostic. The CLI does not install them
or download an SDK. --rust-toolchain-root remains an explicit host-owned path.
See the existing checked-dispatch installation guide for those dependencies;
use this candidate's root and optional tarballs from its package receipt.
Rust/Wasm engines retain .7 payload packages. The component/Python/PHP tools
are .8 metadata-only repacks: identical workers/runtimes, without a reverse
root peer dependency that could make npm prune the installed compiler.

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
SIGINT/SIGTERM to130/143. Diagnostics retain a32MiB cap; stdout is streamed.

A publication error can occur after commitment. In particular,
PSC1_SERVICE_PUBLICATION_COMMITTED_DURABILITY_UNCERTAIN means inspect the
store; do not assume rollback. The adapter adds a hint but retains the exact
original error. A signal/kill can leave existing publisher locks/orphans.
The CLI does not take over stale locks or remove prior generations.

## Bounds and scope

File projects allow at most4096 explicitly declared sources. Every input and
total captured source text are bounded by128MiB, and the encoded source project
must also fit128MiB. Existing inner request/response bounds still apply.
Files use fatal UTF8 decoding with BOM preservation, regular-file checks,
bounded reads, snapshot change checks and relative non-symlink path traversal.
A same-user hostile directory owner racing path components is not an OS
sandbox threat model; use a stable host-owned project directory.

The project adapter does not change independent checker120s, per compiler/tool
request240s, semantic fuel, original/transformed strict IR, source/body pairing,
memory/stack, optional-tool lifetime policies or negative tests. It does not
promote the current123-module development compiler into the frozen122-module
G3 payloads. It does not qualify a new G2/G3 chain.

Actual Linux npm execution is required before marking this candidate usable.
Portable Node implementation does not establish actual Windows/macOS
publication. A public arbitrary extension SDK, watch/incremental compilation,
richer compiler-origin structured diagnostics and final registry publication
remain separate work. The independent human maintainer trial remains pending
its arranged participant; CLI automation is not human usability evidence.
