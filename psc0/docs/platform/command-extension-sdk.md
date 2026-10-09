# One-shot isolated command extensions

## Implemented scope

The first command extension profile is `psc-command/1`. It supports one explicitly enabled `command:dev` operation used by `psc dev --once`. A package returns a build request; the release-owned host supplies the entry, output and checked profile, then uses the existing admission, RuntimeIR, TypeScript and publication transaction.

This is a bounded command slice of the architecture plan. It does not complete the planned macro/tactic examples, source/module export ABI (T1), live watch (T2), language server, generic plugin services or formal isolation refinement. Ordinary `psc check` and `psc build` keep working without activating command packages. No compiler or kernel source imports this tooling, and the selected compiler/seed and bootstrap pins are unchanged.

## Package and activation

The repository contains private, unpublished `psdev@0.1.0-preview.2` and `@psc-demo/pshello@0.1.0-preview.2` examples. npm name/scope ownership is not established by these examples. They are packed directly as separate candidate tarballs, with no lifecycle script, runtime npm dependency or local build requirement.

```sh
npm install --save-dev --save-exact --ignore-scripts <psdev-candidate.tgz>
```

Add an explicit entry to the root project's existing `package.json` and retain its npm lockfile:

```json
{
  "proofscript": {
    "profile": "checked",
    "extensions": [
      { "package": "psdev", "enable": ["command:dev"] }
    ]
  }
}
```

Run `psc dev src/Main.ps --once --out src/Main.ts`; PowerShell users can invoke npm's `psc.cmd` shim. The scaffold's `proofscript.entry` and `proofscript.out` may supply the paths. The host accepts a build request only for those host-selected paths and the checked profile. A guest cannot replace them, add compiler flags, change the kernel or obtain a different publication path.

The resolver accepts one root `dependencies` or `devDependencies` entry with an exact version or a direct `file:...tgz` spec. It requires npm lockfile v3, the exact root dependency declaration, the `node_modules/<name>` entry, matching installed package name/version, a resolved archive identity and canonical SHA512 integrity data. Linked directories, npm aliases, version ranges, ancestor/global search and workspace hoisting are outside this initial profile. A missing enabled package produces a failure; no build downloads or substitutes it.

The lockfile integrity string is recorded archive provenance, not an independent verification of every installed file. npm performs archive-integrity checking during the controlled installation. PSC additionally records raw root package, lockfile, extension package, descriptor and module hashes and checks that captured inputs remain current. The installed smoke checks the downloaded archive's SHA512 against the npm lockfile. Installing with scripts enabled happens before this boundary and cannot be protected retroactively by Wasm.

A different package name, including an independent scope, uses exactly the same protocol and activation grant. There is no online catalog, allowlist or name-prefix discovery. The `pshello` fixture deliberately uses the same tiny module under a separate identity. Only one provider of `command:dev` may be enabled, so conflicting registrations fail explicitly.

## Data descriptor

Every package carries `proofscript-extension.json` and `command.wasm`. The descriptor has exactly these fields:

```json
{
  "schemaVersion": 1,
  "protocol": "psc-command/1",
  "operations": [
    "command:dev"
  ],
  "entry": "command.wasm",
  "sha256": "63b9c0f41bfc46a06b148a92b370c73f950d1b89b544b290cc7e83e15998e279"
}
```

The descriptor's module digest must match the actual captured bytes. Its fields do not confer trust: the host independently fixes the supported operation, import set, profile, ABI and limits. Package `main`, JavaScript callbacks, lifecycle hooks and optional claims such as `trusted` are never used as host entry points. Unknown descriptor authority fields or additional operations fail validation.

## Wasm ABI and limits

```wat
(module
  (func (export "psc_event") (param $event i32) (result i32)
    local.get $event
    i32.eqz))
```

The host sends only initial event `0`. Return `1` to request the checked build, or `0` to decline it. Any other return value fails. A declined proposal does not obtain a successful-build capability. The guest receives no files, source code, paths, environment variables, arbitrary objects or request callbacks.

The module has exactly one `(i32) -> i32` function and the fixed `psc_event` export. This intentionally small profile permits only type, function, export and code sections, with restricted i32 arithmetic and structured control flow. It rejects imports, linear memory, tables, globals, starts, data/elements, custom sections, references/GC, calls/recursion, threads/atomics, SIMD and future instruction prefixes. General C/Rust Wasm output is not automatically compatible; the supplied WAT and prepared binary are a simple SDK example, not a general compiler framework.

| Budget | Host-enforced limit |
| --- | --- |
| Module | 4096 bytes |
| Linear memory | Zero |
| Local i32 variables | 32 plus the event parameter |
| Structured control depth | 32 including the function body |
| Guest event | One integer; only initial event 0 |
| Guest result | One integer: 0 or 1 |
| Invocation time | Parent timer terminates the worker after 2000 ms |
| Worker JS heap | 16 MiB old generation and 4 MiB young generation |
| Worker stack/code range | 2 MiB stack and 16 MiB code range |

The short structural decoder is not a general Wasm validator. After it excludes unsupported features and bounds local allocations, V8 performs full binary/type validation. The worker receives a copied byte array; those are the same bytes whose hash and descriptor were recorded. The module cannot import host functions or other guest modules, share memory, or grow a guest heap. Guest decisions cannot induce an unbounded host query loop: the host accepts at most one checked build request per command, and the existing kernel and target subprocess budgets still apply.

## Real boundary and assumptions

The security boundary is WebAssembly's validated, capability-free guest execution. A worker thread alone does not sandbox arbitrary JavaScript. Only the fixed release-owned adapter executes JavaScript inside the worker; npm package JavaScript is never imported, evaluated or passed to a Node VM. No WASI is installed and no automatic native/JavaScript fallback exists.

The parent uses a fixed release-owned worker URL, clears inherited worker execution arguments/environment, captures worker stdout/stderr and rejects unexpected output without forwarding its bytes. The guest can return only one bounded integer through the trusted adapter. It has no terminal or receipt channel. The host emits escaped JSON disclosure before constructing the worker, records instantiation acknowledgement and the final outcome, and preserves failed-attempt identities.

This narrowly qualified profile uses V8 already shipped with supported Node runtimes, rather than adding a separate Wasmtime native payload to both consumer platforms. Node/V8 identity is recorded for every invocation. The engine, adapter, decoder, process runtime, authentic launcher and OS are explicit implementation assumptions. This is a deliberate narrow-profile choice, not a claim that every V8 Wasm feature or Node worker is safe for general plugins.

Node's worker resource limits do not constrain all external allocations or provide a hard process-RSS ceiling. The profile therefore forbids guest memory, tables, GC allocation and calls in addition to bounding input/code/locals. The parent timer is wall-time cancellation, not deterministic instruction fuel or a real-time scheduling theorem. Engine defects, process-wide out-of-memory, hardware side channels, hostile replacement of the installation and OS compromise are outside the demonstrated confinement claim. A richer extension ABI must receive its own resource and isolation qualification; full Wasmtime or an OS-sandbox compatibility mode remains an explicit later decision.

Primary references: [WebAssembly security model](https://webassembly.org/docs/security/), [Node 22.23.3 worker resource limits](https://nodejs.org/download/release/v22.23.3/docs/api/worker_threads.html), and [Wasmtime security assumptions](https://docs.wasmtime.dev/security.html).

## Trusted host API and publication

The release-owned implementation exposes these internal host functions:

- `validateCommandExtensionConfig(entries)` validates only the root data shape; it performs no file access or execution.
- `discoverCommandExtensions({ projectRoot, projectMetadata })` resolves installed data and returns frozen selections. Each selection exposes a configured `.report`; captured bytes and input identities stay in a private WeakMap.
- `executeCommandExtension(selection, { event: 0, onState, signal })` executes one captured module. The synchronous release-owned `onState` receives immutable `attempted`, `executing`, `instantiated` and `completed` or `failed` records. No asynchronous reporting callback is accepted.
- `completedCommandRecords(execution)` accepts only a genuine successful execution with `requestBuild: true`; forged object shapes and declined requests fail. It supplies the actual immutable receipt records.
- `assertCommandExtensionCurrent(execution)` rechecks the captured root configuration, lockfile, metadata, descriptor, payload and package directory identity before acceptance/publication.

The actual-load record includes package/version, resolved project location, actual module and metadata hashes, lockfile identity/integrity, fixed protocol/operation/grants, empty imports, Node/V8, limits and state. The host's mandatory stderr summary precedes any guest execution. Successful checked-build receipts retain the same completed record. If a worker terminates before confirming instantiation, the failed record reports `instantiated: null` instead of falsely claiming it never ran.

No guest controls a record, hash, assurance flag or output path. The host still performs the complete existing admission/IR/TypeScript/publication sequence. Correctness and isolation implementation proofs remain later gates; these tests do not establish logical consistency, compiler semantic preservation or full PSCV coverage.

## Focused qualification

The Actions-only source tests exercise explicit activation and third-party naming; ignored malicious JS entry points; package/lock/module identity and tampering; linked packages; protected result ownership; policy changes before publication; valid import/memory modules rejected before instantiation; recursion/local/nesting/input bounds; traps, malformed Wasm, invalid replies, infinite loops, cancellation and mandatory disclosure. Installed-package smoke separately tests genuine no-script npm installation, one-shot neighboring TS build, receipt identity, invalid-source preservation, tampered payload rejection and the independent-name fixture on supported Windows/Linux consumer environments.

The canonical prepared demo is 44 bytes, with SHA256 `63b9c0f41bfc46a06b148a92b370c73f950d1b89b544b290cc7e83e15998e279`. Its meaningful WAT source, exact byte identity and full V8 validation are retained in the source gate. No WAT toolchain or extension package is an input to the compiler bootstrap cycle.
