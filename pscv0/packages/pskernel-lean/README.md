# `@proofscript/pskernel-lean`

Official Lean-backed kernel provider for ProofScript PSC2.

Current package identity:

```text
@proofscript/pskernel-lean@4.34.0
```

The package version tracks the Lean semantic baseline. Do not put the Lean version in the package name. A future WebAssembly transport should therefore be named, for example:

```text
@proofscript/pskernel-lean-wasm@4.34.0
```

The native provider is pinned more precisely to:

```text
Lean version: 4.34.0
Lean tag:     v4.34.0
Lean commit:  293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
protocol:     pskernel-lean/1
profile:      lean4.34-core
```

`LEAN_SOURCE_PIN.json` is the machine-readable identity. Do not silently change the Lean version or source commit.

## Purpose

This package provides an **external assurance kernel** for PSC2. It accepts PSC canonical checked-admissions and asks the pinned official Lean kernel to accept or reject the corresponding semantic declarations.

```text
PSC source
  -> generated PSC2 compiler
  -> canonical checked-admissions v2
  -> @proofscript/pskernel-lean
  -> Lean 4.34 kernel
  -> accept / reject
```

It is deliberately **not** part of the first PSC2 fixed-point bootstrap closure. npm workspace membership does not make it part of the portable compiler.

## Public npm API

Use the package entry point:

```js
import {
  checkCanonicalAdmissions,
  defaultLeanKernelProviderBinary,
  leanKernelProviderCommit,
  leanKernelProviderName,
  leanKernelProviderProtocol,
  leanKernelProviderVersion,
} from '@proofscript/pskernel-lean';
```

Additional supported exports:

```text
@proofscript/pskernel-lean/node
@proofscript/pskernel-lean/metadata
```

Consumers should not import `host/node-provider.mjs` by repository-relative path. That file is implementation structure; `index.mjs` / npm `exports` are the package boundary.

PSC2 host orchestration prefers the installed package. In a zero-install repository checkout it falls back only to the local package's public `index.mjs`, so development and installed use share the same API.

The self-host workspace declares the package as an optional dependency:

```json
{
  "optionalDependencies": {
    "@proofscript/pskernel-lean": "4.34.0"
  }
}
```

It is optional because normal bootstrap/fixed-point operation must remain independent of Lean.

## Semantic checking path

The provider does **not** generate `.lean` text and does not ask Lean's parser/elaborator to reinterpret PSC source.

The path is direct semantic conversion:

```text
PSC canonical admissions JSON
  -> canonical PSC decoder
  -> PSC Core values
  -> Lean Name / Level / Expr / Declaration
  -> Lean.Environment.addDeclCore
  -> accept / reject
```

Admission starts from a trust-level-0 empty Lean environment. The provider reconstructs PSC2's own pinned prelude and submits every admitted declaration through the Lean kernel.

Because the PSC prelude contains forward references, replay is dependency-aware: only `unknownConstant` failures are deferred; every other kernel failure is immediately fatal, and unresolved declarations with no progress fail closed.

## Canonical request

`--check` receives one complete checked-admissions v2 document on stdin:

```json
{
  "admissions": [],
  "format": "proofscript-checked-admissions",
  "version": 2
}
```

Malformed input, unknown tags, metas/free variables, unsupported Core forms, version mismatches, and non-round-trippable reducibility heights fail closed.

A successful response includes the exact provider identity:

```json
{
  "protocol": "pskernel-lean/1",
  "provider": "lean4-cpp",
  "leanVersion": "4.34.0",
  "leanCommit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b",
  "profile": "lean4.34-core",
  "accepted": true
}
```

Kernel rejection returns `accepted:false` plus a stable `errorKind` and, when applicable, `declarationIndex`.

## Native executable

In this repository, build and test the provider from `psc15selfhost/`:

```text
npm run check:kernel:lean434:pin
npm run build:kernel:lean434
npm run test:kernel:lean434
```

Direct development commands:

```text
lake build psc2_lean_kernel_provider
lake exe psc2_lean_kernel_provider --version
lake exe psc2_lean_kernel_provider --health
cat admissions.json | lake exe psc2_lean_kernel_provider --check
```

For normal installed-package use, the Node adapter resolves the verified bundled native executable automatically. `PSC_LEAN_KERNEL_PROVIDER_BIN` or the `binaryPath` option remains an explicit override for development, assurance experiments, and custom-provider testing.

### npm native distribution

`@proofscript/pskernel-lean@4.34.0` bundles native provider executables for:

```text
linux-x64
linux-arm64
darwin-x64
darwin-arm64
win32-x64
```

A normal supported-platform consumer does not need Lean, Lake, a C++ toolchain, an install-time download, or `PSC_LEAN_KERNEL_PROVIDER_BIN`.

Runtime selection is fail-closed and ordered as:

```text
1. explicit PSC_LEAN_KERNEL_PROVIDER_BIN / binaryPath override
2. verified package-local prebuilt for process.platform + process.arch
3. source-checkout Lake binary development fallback
4. explicit unsupported/missing-provider failure
```

`PREBUILT_MANIFEST.json` records the exact package/provider/Lean identity plus the source commit, byte size, and SHA-256 for every bundled target. The adapter validates the target manifest entry and digest before spawning a bundled provider.

The package does not silently emulate another architecture. Windows ARM64 is not part of the Lean 4.34 native matrix and fails as unsupported unless the caller deliberately supplies a custom provider override.

The distribution workflow builds each binary on its native GitHub runner, strips release symbols, re-runs `--health` and positive/negative kernel admissions after stripping, inspects dynamic dependencies, proves standalone execution with the Lake build tree hidden, and only then assembles the npm package. The committed tarball surface is independently installed and executed on all five supported target runners by the provider workflow.

The bundled binaries are currently unsigned/not notarized. Do not claim code signing or notarization until a later release-signing milestone actually implements it.

A future `@proofscript/pskernel-lean-wasm@4.34.0` should preserve the same canonical request/response semantics and JavaScript-facing provider contract.

## PSC CLI integration

With a generated PSC2 compiler:

```text
psc check Main.ps --kernel lean434
psc build Main.ps --out Main.js --kernel lean434
```

The gated build order is fail-closed:

```text
flatten project
  -> generated compiler canonical admissions
  -> @proofscript/pskernel-lean check
  -> only if accepted: TypeScript generation
  -> JavaScript compilation
```

If Lean rejects the module, requested code generation must not proceed.

Builds without `--kernel lean434` keep the existing fixed-point behavior and do not require this package to execute.

## Package / bootstrap boundary

This package is a normal npm workspace under `packages/*`, but its ProofScript metadata remains:

```json
{
  "bootstrap": false,
  "portable": false,
  "role": "external-lean-kernel-provider"
}
```

`bootstrap-closure-contract.mjs` explicitly forbids `pskernel-lean` from the first portable closure.

The long-term architecture remains:

```text
AdmissionReadyModule
       |
       v
host-selected KernelProvider
   /          |           \
  v           v            v
PSC kernel   Lean native   Lean WASM
  |            |             |
  +------------+-------------+
               |
         CheckedModule
               |
             erasure
               |
          VerifiedIR
```

A later provider-neutral `CheckedModule` / `CheckedCore` must be produced only after a selected kernel provider accepts the canonical Core. Do not rename the current codec-valid `AdmissionReadyModule` to `CheckedCore`.

## Copied Lean sources

The package also retains pinned copies of:

```text
kernel/
runtime/
util/
```

The current provider executable does not directly build those copies as a standalone library; it links through the pinned official Lean distribution. The copies are retained for a later standalone native/WASM provider behind the same protocol.

Do not expose Lean C++ classes or `lean_object` pointers as the stable PSC API. The stable provider boundary should remain bytes/text in and bytes/text out.

## What acceptance proves

An accepted response means the submitted canonical PSC declarations were accepted by this exact Lean 4.34 provider path on top of the provider-owned PSC2 prelude.

It does **not** prove full Lean frontend equivalence, full PSC/Lean equivalence, or that the future PSC-native kernel is already equivalent to Lean.

## Documentation

- `NPM_PACKAGE.md` — npm naming, consumption, and distribution contract.
- `INTEGRATION.md` — semantic and host-provider boundary.
- `BUILDING.md` — native build/run instructions.
- `LEAN_SOURCE_PIN.json` — exact Lean identity.
- `PREBUILT_MANIFEST.json` — committed native artifact identity/digests.

## Required regression gates

Keep tests for all of these when changing the package:

- exact Lean version/source commit pin;
- package manifest and npm exports;
- clean external npm install/import;
- five-target packed npm consumer execution;
- bundled target selection and SHA-256 validation;
- normal workspace membership;
- explicit bootstrap exclusion;
- PSC Core -> Lean semantic conversion;
- provider-owned prelude admission at trust level 0;
- canonical codec compatibility;
- valid semantic acceptance;
- codec-valid but ill-typed kernel rejection;
- stdin/stdout process protocol;
- Node host adapter;
- generated compiler -> package -> native provider path;
- `psc check --kernel lean434`;
- `psc build --kernel lean434` fail-before-codegen behavior.
