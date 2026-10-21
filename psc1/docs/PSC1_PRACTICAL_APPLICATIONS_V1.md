# Practical CLI and JSON file application v1

The independently authored PracticalCli .lean/.ps modules parse a UTF8 argument
vector and transform a bounded JSON array of records. Thin host programs encode
argv as JSON; source code owns command recognition, validation, transformation,
typed IO sequencing and diagnostics.

Commands: `--help` or `transform INPUT OUTPUT`. Success exits 0; source usage,
JSON or typed IO failure exits 2. Denied required host capabilities exit 78 before
guest invocation (and before dynamic guest loading). Foreign host defects retain
their exception/trap channel. No source argument grants a host capability.

Each record requires String `text` and integer JSON `count`. The transformation
prefixes text with `processed:`, preserves count and emits canonical objects with
sorted keys. Extra input fields are dropped. Empty arrays are valid. Duplicate
keys, trailing commas, malformed JSON, isolated surrogates and invalid record shapes refuse.
The existing checked JSON subset and its fuel limits remain unchanged.

Read/write paths are relative to the configured held root. Host capability,
no-follow, UTF8, regular-file, size and atomic-write policies remain mandatory.
Processing errors preserve the previous destination. Successful output is written
before the final console acknowledgment; a later console error cannot undo it.

`docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json` requires twenty-one actual
process-level scenarios for both source grammars and all seven backends. Node
hosts JS/TS/core Wasm; Rust, Python and PHP use their standalone adapters; Wasm
components use the pinned Wasmtime Python adapter. Rust guest/host lock graphs
are merged without version reselection. TypeScript uses the pinned strict checker.

`scripts/practical-application-tests.mjs` executes the generated programs and
checks exact exit codes, console text, file contents and preservation. An
independent official Lean reference supplies the Unicode record transform.
Receipts and all required full qualification must pass at the same commit before
the two application acceptance rows become qualified. This is not compiler
release readiness or a proof of backend preservation.

The host entry points in scripts/practical-application-{node.mjs,python.py,
php.php,rust.rs} are executable examples of the narrow public IO ABI. Compile
test/applications/PracticalCli/Run.lean (or Run.ps) with
`psc1 build ... --target TARGET --abi io-dispatcher --assurance ordinary --out PATH`.
Provide a host config JSON granting readUtf8, writeUtf8 and writeLine explicitly.
Node usage: `node scripts/practical-application-node.mjs js MODULE CONFIG transform INPUT OUTPUT`.
The compiler never grants host access from source text or a manifest.

Library, compiler-like and 100000-item measured workload acceptance remain
separate finite release blockers. G2/G3 remain deferred until stable feature freeze.
