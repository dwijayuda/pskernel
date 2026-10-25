# Checked output and transactional publication

This host-only change reuses the qualified 122-module compiler closure
`073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9`.
The frontend, elaborator, strict original/transformed IR, official independent
Lean 4.35 admission and all four genuine G3 executors are unchanged.
[Exact qualification](PSC1_CHECKED_PUBLICATION_QUALIFICATION_2026-10-26.json)
distinguishes implemented, tested, qualified and incomplete work.

## Engine, output and checker

`engine` selects execution of the same self-hosted compiler; `target` selects its
existing output emitter; `kernel` selects genuine independent checking.
The root embeds JS/TS execution and defaults to the official C++ Lean kernel
compiled by Emscripten to linear-memory Wasm. Rust/compiler-Wasm executors and
native checking are optional. Compiler-Wasm retains its GC architecture.

Checked `js`, `ts`, `rust` and `wasm-core` outputs use the same private session.
Source, project and generated wire fields cannot select tools or publish.
Candidate-only APIs retain no admission or publication authority.
Native distribution seven-target support and optional Python/PHP are preserved.
Wasm-component/optional-provider checked dispatch in this slim API is unfinished.

## Installation and output consumers

Use the exact unpublished artifacts linked by the qualification receipt and
Node22.23.3. Install the root from its local tarball with scripts disabled.
The bundled independent Wasm checker is mandatory. No compiler SDK is downloaded
or built by install or compile requests.

For TS output, explicitly install the included TypeScript7.0.2 and matching
`@typescript/typescript-linux-x64@7.0.2` tarballs together. Both complete resource
inventories are pinned; the host invokes the native compiler directly under its
240-second bound. Strict mode, noEmitOnError, declaration generation and full
library checking are required. Checked TS publication contains source, declarations,
emitted ESM and the fixed consumer configuration.

For Rust output, install the included
`@proofscript/rust-target-consumer-linux-x64@0.1.0-psc1.6` tarball and provision the
official Rust1.90.0 Linux x64 toolchain explicitly. Default SDK location is
`~/.rustup/toolchains/1.90.0-x86_64-unknown-linux-gnu`; an explicit host
`rustToolchainRoot` / CLI `--rust-toolchain-root` may locate the same exact SDK.
Every selected SDK resource must match the trusted inventory. Version text alone
does not authorize a tool. The optional consumer contains locked BigInt rlibs
and a pinned Syn2.0.106 syntax/public-value inspector, not another PSC1 compiler.
The target is type-checked as a Rust rlib; no source-supplied Cargo manifest,
build script, arbitrary dependency or registry access participates in a request.

Rust publication contains `target.rs`, `libproofscript.rlib` and a consumer receipt.
Link an application with the same pinned toolchain and dependency directory:

```sh
rustc --edition=2021 consumer.rs \
  --extern proofscript_generated=/absolute/generation/libproofscript.rlib \
  -L dependency=/absolute/node_modules/@proofscript/rust-target-consumer-linux-x64/deps \
  -o application
```

Wasm output needs no additional SDK. The checked output includes the actual GC
binary, existing typed transport and a loader whose default export is the API.
The closed standalone ABI covers Nat, Int, Bool, String and Unit declarations.
Unsupported types and callback IO refuse explicitly; this is not universal ABI
support. Kernel-Wasm remains a separate linear-memory module.

The default JS output and all four compiler executors remain usable without
output SDKs. A missing, corrupt, wrong-version or unsupported selected consumer
fails explicitly; it does not change target, engine or checker.

## API and CLI

```js
import {build, compile, readPublication} from 'proofscript';
import {pathToFileURL} from 'node:url';

const options = {
  entryModule: 'Entry',
  sources: [{module:'Entry', kind:'lean', text:'def answer : Nat := 42\n'}],
  target: 'wasm-core',
  publicationProtocol: 'portable-file',
};
const checked = compile(options);
console.log(checked.sourceEncoding); // psc1-wasm-hex/1; other sources use utf8
const published = build({...options, out:'dist/program'});
const current = readPublication({out:'dist/program', publicationProtocol:'portable-file'});
const {default: api} = await import(pathToFileURL(published.runtimeArtifact).href);
console.log(api.answer);
```

For dynamic imports use `pathToFileURL(published.runtimeArtifact).href` when passing
an absolute filesystem path, especially on Windows. Publication itself currently
requires Linux. The reader verifies integrity; reading a manifest does not
independently re-admit its logical graph or create publication authority.

```sh
psc build Main.lean --target ts --publication-protocol portable-file --out dist/ts
psc build Main.ps --target rust --publication-protocol portable-file --out dist/rust
psc build Main.ps --target wasm-core --publication-protocol portable-file --out dist/wasm
```

CLI project JSON still accepts only entryModule, sources and optional assurance.
Targets, protocols, SDK roots, output paths and checkers are host options.

## Commit and reader protocol

The default legacy layout retains `current -> generations/<manifest-sha256>`.
Explicit `portable-file` instead atomically replaces a canonical regular
`current.json` containing schema, generation and manifest hash.
Stores cannot silently mix layouts or upgrade themselves.

A writer captures the previous pointer, acquires an exclusive lock, refuses stale
state, verifies private-session files/tools, flushes all files, seals and verifies
the complete generation, flushes directories and replaces one pointer.
New directory entries are flushed on Linux. All returned artifact paths name the
immutable generation, so later publication cannot redirect an existing reader.

Pre-commit failures leave the old pointer. A failure after replacement throws
`PSC1_SERVICE_PUBLICATION_COMMITTED_DURABILITY_UNCERTAIN` and exposes
`committedPublication` with durability `unconfirmed`. The new generation may
already be visible; callers must not assume rollback or blindly retry.
The reader reports a recorded commit, not proof that an earlier fsync completed.

A killed writer can leave a diagnostic lock and a sealed orphan generation.
Automatic stale-lock takeover and automatic recovery are deliberately refused.
Readers can still use a valid prior pointer. Administrative recovery must first
establish that no publisher owns the lock; no unsafe automatic recovery command
is supplied in this milestone.

The portable file format avoids a symlink privilege requirement. Actual atomic
replacement, directory flushing and failure behavior are platform-specific.
Linux-only tests cannot qualify macOS/Windows durability, so other OS commits
remain disabled. Compile-only temporary staging is separate from commit authority.
This milestone is not a final universal-platform release or a power-loss test.

## Evidence and continuation

The receipt records actual Linux filesystem faults/SIGKILL, stale writers,
sealed-file tamper, reader validation and committed cleanup failure, followed by
all four executors/both grammars and actual published scalar, Unicode and IO
consumers. Existing offline/global/kernel/application/backend and public-type
regressions remain required. Runtime observations and exact fixed points are
evidence within their scope, not compiler semantic-preservation proofs.

Compiler/tools240s, checker120s, source limits, semantic fuel, memory/stack/lifetime
limits, trust0 and official Lean4.35 bounds remain unchanged.
The separate G2/G3 profiles and unqualified original240s self-compilation target
are preserved. Follow the [roadmap](PSC1_DEVELOPMENT_ROADMAP.md) for remaining
platform, component/provider, source-package and final clean release work.
No merge or npm publication is authorized.
