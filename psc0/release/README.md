# ProofScript compiler preview

This package installs **psc**: the ProofScript command-line compiler with pinned PSKernel Core admission, checked RuntimeIR emission, and TypeScript 7.0.2 validation.

Version **0.1.0-preview.5** retains the **psc-ts-library/1** checked project profile: selected exports from pure acyclic `.ps` modules, one shared TypeScript bundle, neighboring TypeScript facades, and a bounded runtime interface. Four examples ship with the existing initializer and **psc-command/1** extension protocol. The optional **psdev** package enables one-shot builds and host-owned **dev --watch** scheduling.

This candidate supports Linux x64 and Windows x64. Consumer Node ranges are >=22.23.3 <23 or >=26.7.0 <27; the installation qualification exercises Node22.23.3 and Node26.7.0. Bootstrap remains Node22.23.3/Lean4.34.0/TS7.0.2. Installing the prebuilt package requires no Lean toolchain or repository checkout.

The preview is distributed as candidate tarballs, not yet published to npm. The package is UNLICENSED pending a distribution-license decision. Ownership of the npm product name proofscript does not imply ownership of every demo name or npm scope.

## Install and start a project

From an extracted candidate on Windows PowerShell:

```powershell
$candidate = (Resolve-Path .\platform).Path
npm install --global --ignore-scripts "$candidate\proofscript-0.1.0-preview.5.tgz"
psc.cmd version
psc.cmd init my-app
Set-Location my-app
npm install --save-dev --save-exact --ignore-scripts "$candidate\proofscript-0.1.0-preview.5.tgz"
npm run check
npm run build
```

On Linux, use psc instead of psc.cmd and your absolute candidate tarball path. The explicit psc.cmd spelling uses npm's Windows command shim; a bare psc may select a PowerShell script subject to your local execution policy.

The initializer creates three files:

- package.json: private project, exact compiler version, check/build scripts and checked profile.
- src/Main.ps: a Nat constant, answer = 42.
- PROOFSCRIPT.md: local installation, build, TypeScript adoption and optional extension instructions.

Init performs no installation, executes no project scripts, and starts no background service. For an unpublished preview, the local tarball install is required before the generated npm scripts can run. A future published release can use the ordinary registry installation recipe. Commit the resulting lockfile and retain the preview inputs while they remain unpublished.

The generated scripts use the documented local launcher path:

```sh
node ./node_modules/proofscript/bin/psc.mjs check src/Main.ps
node ./node_modules/proofscript/bin/psc.mjs build src/Main.ps --out src/Main.ts
```

This avoids selecting a different package's psc executable from node_modules/.bin. Ordinary npm scripts still resolve node through their environment. Controlled CI should use its provisioned absolute Node executable, the explicit local launcher, a locked install and a controlled environment.

## Commands

| Command | Behavior |
| --- | --- |
| psc init [directory] | Create a starter in a new or empty directory, or add source/guide to an existing npm project. Default directory is the current directory. |
| psc check [entry.ps or entry.lean] | Check canonical declarations with the pinned native Core provider. |
| psc build [entry] [--out file.ts or file.js] | Check admission and the original RuntimeIR, validate with TS7, then publish owned output. |
| psc dev [entry] --once [--out file.ts] | Run one checked build through an enabled command guest. |
| psc dev [entry] --watch [--tsc] [--json] | Watch saved project source and check each generation; optional pinned TS7 compilation. |
| psc query entry.ps --stdin [--json] | Check an unsaved editor buffer and its saved import closure, emit only structured diagnostics, never source or target artifacts. |
| psc examples | Show the installed locations of the four examples. |
| psc extensions | Inspect configured command packages without executing a guest. |
| psc version | Report this compiler's version and installed runtime identities. |

Every command supports --json except help. No command automatically switches from a global compiler to project code, fetches an extension, or falls back to another provider.

The only root project configuration is package.json:

```json
{
  "proofscript": {
    "profile": "checked",
    "entry": "src/Main.ps",
    "out": "src/Main.ts",
    "extensions": []
  }
}
```

With no explicit entry, check/build/dev use proofscript.entry relative to that root. For a build using the configured entry, proofscript.out supplies the output. An explicit --out is relative to the caller's working directory. An explicitly supplied entry without --out writes a neighboring .ts file. For a project with explicit `proofscript.exports`, the configured output always denotes its shared library bundle, including when an entry argument is supplied. Library builds require an explicit `.ts` bundle path distinct from their neighboring facades.

Configuration paths use forward slashes and stay within the project. Source containment, Windows path validation and existing output ownership checks still apply. Unsupported profiles, verification settings, flags or ambiguous extension registrations fail explicitly.

## Add a .ps file to an existing TypeScript project

Run psc init . from the existing npm project. This adds src/Main.ps and PROOFSCRIPT.md while preserving package.json, scripts, dependencies, tsconfig.json and unrelated source. The guide gives optional configuration additions; it does not silently replace your build command.

Existing src/Main.ps, src/Main.ts, src/Main.checked.json or PROOFSCRIPT.md cause a clear conflict refusal. Directory links and ambiguous Windows output paths are refused. The initializer creates absent files exclusively; an I/O failure can leave some newly created starter files and reports them. It is not a multi-file atomic transaction.

Install the exact compiler locally, then invoke:

```sh
node ./node_modules/proofscript/bin/psc.mjs check src/Main.ps
node ./node_modules/proofscript/bin/psc.mjs build src/Main.ps --out src/Main.ts
```

An ES2022/NodeNext TypeScript consumer can import the generated constant:

```ts
import { answer } from "./Main.js";

const value: bigint = answer;
if (value !== 42n) throw new Error("unexpected result");
console.log(value);
```

Run PSC before your TypeScript build. The original existing-typescript example covers one source bundle and a constant export. Use the checked-library profile below when exported functions and datatypes cross module boundaries. Do not independently compile every `.ps` file's full import closure and mix the resulting opaque identities.

## Checked libraries in an existing TypeScript project

The `examples/platform/checked-library` directory contains `src/Quantity.ps`, `src/Main.ps` and a handwritten `src/consumer.ts`. Quantity defines a datatype and a constructor function; Main imports Quantity and exposes reader and identity functions.

Start the example in a fresh copied directory. When converting an already-built single-source starter, `src/Main.ts` belongs to `src/Main.checked.json`; the new library receipt does not automatically adopt it. Stop build/watch processes, confirm which files are generated and still match that receipt, and archive those old generated outputs together with the receipt before the first library build. Preserve handwritten or edited files.

Select public names explicitly in the project package.json:

```json
{
  "proofscript": {
    "profile": "checked",
    "entry": "src/Main.ps",
    "out": "src/generated/library.ts",
    "exports": {
      "src/Quantity.ps": ["Quantity", "makeQuantity"],
      "src/Main.ps": ["readQuantity", "sameQuantity"]
    }
  }
}
```

Run the locally pinned PSC build, then run the existing TypeScript build only if PSC succeeds. The shipped example provides scripts using the exact local compiler launcher and TypeScript 7.0.2. It targets ES2022 with strict NodeNext module settings:

```sh
node ./node_modules/proofscript/bin/psc.mjs build
node ./node_modules/typescript/bin/tsc --project tsconfig.json
```

In automation, join these steps with a success dependency such as `&&`; independent file watching does not establish build ordering.

One successful library generation owns:

- `src/generated/library.ts`: the entire checked runtime and public wrappers.
- `src/Quantity.ts` and `src/Main.ts`: thin re-exports from that same bundle.
- `src/generated/library.checked.json`: one completed-generation receipt covering all generated TypeScript bytes.

The handwritten consumer uses ordinary neighboring imports:

```ts
import { makeQuantity, type Quantity } from "./Quantity.js";
import { readQuantity, sameQuantity } from "./Main.js";

const quantity: Quantity = makeQuantity(42n);
if (readQuantity(quantity) !== 42n) throw new Error("unexpected quantity");
if (sameQuantity(quantity) !== quantity) throw new Error("identity changed");
```

Only selected names owned by their authored source become public. Importing a declaration does not let another source claim it as its own export. Unselected dependencies participate in preparation and admission but receive no public facade.

### Bounded public interface

| ProofScript type | TypeScript interface and runtime rule |
| --- | --- |
| Nat | `bigint`; negative and non-bigint arguments are refused. |
| Int | `bigint`; non-bigint arguments are refused. |
| Bool | `boolean`. |
| String | `string` without isolated UTF-16 surrogates; valid astral characters are accepted. |
| Unit | `undefined`. |
| Selected monomorphic datatype or structure | An opaque frozen handle, recognized by bundle-private maps. |

Functions check their exact argument count and supported inbound values. A handle can be passed between facades from the same bundle; returning the same underlying value preserves its handle identity. Forged objects, lookalikes, proxies and handles from another bundle are refused. Raw runtime constructors and internal definitions are not exposed by this profile.

The first profile refuses public implicit, proof-dependent, generic, higher-order, callback and array signatures. Authored nullary definitions become constants. Unsupported public interfaces fail the build rather than weakening its checks. No arbitrary TypeScript FFI is admitted.

These guards protect the application value boundary under ordinary trusted JavaScript runtime assumptions. They do not provide proof authority or isolation from arbitrary code running in the same JavaScript realm. The npm extension boundary remains the separate constrained Wasm protocol described below.

`psc check` checks declarations without publishing output or requesting the public ABI/target-emission checks. Its library receipt reports `abiStatus: "not-requested"`; successful library builds report `"checked-bounded"`. A check-only receipt does not authorize generation.

Every selected source must be in the entry's local acyclic `.ps` closure. Bundle and facade paths remain inside the project, with one consistent directory capitalization. Npm/workspace source resolution and true separate compilation remain later work.

The publisher leases the old and new destination directories, checks prior ownership and source/configuration freshness, stages new files and backups in separate namespaces, and writes the receipt last. It refuses handwritten neighbors and modified generated files. Failed checks retain the last completed generation. That old generation is not evidence for an invalid new source revision, so downstream TypeScript builds must depend on PSC success.

## Examples

Use psc examples --json to obtain exact installed paths.

| Directory under this package | Example |
| --- | --- |
| examples/platform/checked-nat | Nat42, default entry/output configuration, local check/build scripts. |
| examples/platform/existing-typescript | Checked Main.ps, a handwritten consumer.ts, ES2022/NodeNext configuration. |
| examples/platform/checked-library | Two .ps modules, explicit exports, a shared opaque datatype and checked neighboring TS facades. |
| examples/platform/rejected-source | An ill-typed source that must be refused without publishing output. |

Copy an example to a project you own before building. Do not generate output into the compiler's installation directory. The example READMEs explain installation and expected behavior.

## Install and activate the psdev command demo

The candidate also includes psdev-0.1.0-preview.5.tgz. It is an optional, separately installable npm package. The compiler does not depend on it, and installation alone does not activate it.

In the initialized project, using the PowerShell candidate variable from above:

```powershell
npm install --save-dev --save-exact --ignore-scripts "$candidate\psdev-0.1.0-preview.5.tgz"
```

Set the existing root proofscript.extensions array to:

```json
[
  { "package": "psdev", "enable": ["command:dev"] }
]
```

Then:

```sh
node ./node_modules/proofscript/bin/psc.mjs extensions --json
node ./node_modules/proofscript/bin/psc.mjs dev --once --json
```

The first command resolves data and reports configured packages with loadedExtensions empty. The second reports actual execution and, when the guest requests it, performs the same protected checked build. The result contains command, extensions and receipt; the saved Main.checked.json contains the identical executed extension record.

Only direct, physically installed root node_modules dependencies with a matching npm v3 lock entry are supported by this first resolver. Exact registry versions and local candidate tarballs are supported dependency forms. Linked directories, npm aliases, workspace/ancestor/global fallback and automatic downloads are not supported. Keep the package-lock.json produced by npm. The lock integrity is recorded provenance; it is not a publisher signature or proof that all installed package bytes are immutable.

## Third-party demo

The independently named package @psc-demo/pshello uses the same protocol and authority boundary. Its candidate filename is psc-demo-pshello-0.1.0-preview.5.tgz. It is an illustrative private package, not a claim that this npm scope is owned or published.

Install that candidate locally with --save-dev --save-exact --ignore-scripts, and replace the single command:dev entry with:

```json
[
  { "package": "@psc-demo/pshello", "enable": ["command:dev"] }
]
```

Run dev --once again. Its actual package name and digests appear in disclosure and the checked receipt. A package is not accepted because it is called psdev or belongs to an official-looking scope. There is no publisher-name allowlist for this constrained command interface. Enabling two providers for command:dev is an ambiguity error.

## Extension boundary

The loader reads a fixed data descriptor, proofscript-extension.json, and its pinned command.wasm. It never imports the npm package's JavaScript entrypoint. A strict 4 KiB WebAssembly profile permits one i32 command function and a small integer/control subset. It rejects imports, memory, tables, globals, start functions, calls, reference/GC instructions and other unsupported sections.

The only guest output is an integer requesting no action or one host-selected checked build. The guest receives no source paths, source bytes, filesystem, network, process, terminal, provider, admission or publication capability. A trusted adapter executes it using V8 WebAssembly in a dedicated worker, with a two-second wall deadline and bounded profile structure. WebAssembly confinement is the guest security boundary; the worker supplies cancellation, not a separate operating-system sandbox. Node/V8 and the adapter remain trusted implementation assumptions. This is not deterministic fuel metering, a proof of the engine, or a process-wide memory/availability guarantee.

The supervisor owns every PSC_EXTENSIONS report. It reports before execution, captures actual state and records completed execution in the checked receipt. The guest cannot emit arbitrary diagnostics or status text. Root configuration, lockfile, installed metadata, descriptor and module identities are checked again before publication. Changed inputs, denied operations, malformed Wasm, traps and timeouts cannot authorize output.

Lifecycle scripts execute before compiler isolation could help. The supported install instructions use --ignore-scripts and the demo packages require no installation scripts. An arbitrary local process with filesystem authority remains outside the guest-confinement threat model.

## What the checked output means

A successful build checks native kernel admission, the current RuntimeIR invariants, emission from that same original IR, and TS7 target acceptance. It does not prove all intended specifications or compiler semantics. Receipts keep semanticPreservationProved, pscvVerified and strictSh1Qualified false.

The output publisher refuses unowned or manually edited destinations. Failed checks preserve the previous completed generation. It uses a staged ownership and recovery protocol with receipt commitment last, not atomic visibility of multiple files to arbitrary watchers. Follow its recovery-required diagnostics if cleanup or rollback cannot finish safely.

The T2 watcher uses the same checked host through cancellable supervised subprocesses:
```sh
node ./node_modules/proofscript/bin/psc.mjs dev --watch --tsc
```
It requires one explicitly enabled command:dev package. Optional --tsc runs pinned TypeScript 7 with tsconfig.json only after PSC accepts the generation. The status stream distinguishes pending, checking, checked, ready, rejected and stopped; --json emits one JSON object per line. Invalid source preserves the last accepted files but never marks them current. The monitor watches the source directory recursively, project metadata and the selected extension package, and periodically rechecks known accepted inputs. Filesystem events can be delayed or missed; this is not instantaneous global freshness or atomic multi-file visibility for independent watchers. Restart after changing the entry or enabled extension identity. Downstream TS failure never marks the application ready. Broader ABI/FFI, general macros/tactics/backends, npm/workspace resolution and LSP remain later work. This package implements a command extension demo, not the complete extension framework.

## Self-host and later proofs

T1 adds portable compiler code for owned project preparation and checked public emission, so it requires a newly qualified source closure and generated compiler. The assembled release records their exact identities. The selected authoring seed, native provider algorithms and bootstrap pins remain unchanged. Init, publication, CLI orchestration and the optional demos stay outside the compiler's self-host import graph.

Full assurance remains a later gate. The accepted proof layout is psc0/proofs/**/*.proof.lean, with full Lean outside the bootstrap cycle. The obligations include authored export ownership, Core/IR/public signature correspondence, runtime value guards and opaque identity, source/configuration binding, complete-generation publication, and preservation through compiler generation. The command decoder and host request composition remain separate obligations; every third-party scheduler need not have its own theorem when the host validates its bounded requests.

JavaScript is a planned intermediate target for the same PSKernel Core before Wasm. It is not the selected provider in this preview. The current Core probe identified a standard-environment compatibility gap before JS generation; current native admission remains mandatory. See [KERNEL_JS_PLAN.md](https://github.com/dwijayuda/pskernel/blob/psc0/platform-t1-v1/psc0/KERNEL_JS_PLAN.md) for the exact evidence and promotion gates.

For the precise current qualification, platform limits, pinned identities and architecture roadmap, see [PLATFORM_IMPLEMENTATION.md](https://github.com/dwijayuda/pskernel/blob/psc0/platform-t1-v1/psc0/PLATFORM_IMPLEMENTATION.md) and [PSC0_ARCHITECTURE_PLAN.md](https://github.com/dwijayuda/pskernel/blob/psc0/platform-t1-v1/psc0/PSC0_ARCHITECTURE_PLAN.md).

## Optional pslsp diagnostics pilot

Install the matching private `pslsp-0.1.0-preview.5.tgz` beside the exact
`proofscript-0.1.0-preview.5.tgz`. Start the language server from the
chosen project root, through an editor LSP client or a test harness:

```sh
node ./node_modules/pslsp/bin/pslsp.mjs --stdio
```

It supports framed LSP 3.17 initialize/shutdown/exit, full-document
open/change/close/save and versioned diagnostics. Each unsaved `.ps` buffer
is checked by the pinned `psc query` command using the existing native Core
admission path, without writing to the project's generated `.ts` files.
Syntax spans use UTF-16 editor positions when available; other source failures
are explicitly source-unlocated rather than falsely positioned. Queries prove
neither target correctness nor global project contract coverage. The server
does not advertise hover, completion or go-to-definition. It is editor tooling
and not an implicitly activated command extension or a kernel provider.

See the separate pslsp README and the qualifying installed editor test.
