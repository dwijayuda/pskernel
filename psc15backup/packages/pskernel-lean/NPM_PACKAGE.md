# `@proofscript/pskernel-lean` npm package

`packages/pskernel-lean` is the npm-facing Lean kernel provider package for PSC2.

## Package identity

Current package:

```text
@proofscript/pskernel-lean@4.34.0
```

The package name describes the provider implementation. The package version tracks the Lean semantic baseline:

```text
Lean 4.34.0 -> @proofscript/pskernel-lean@4.34.0
```

Do not encode the Lean version into the package name. Future execution variants should follow the same rule, for example:

```text
@proofscript/pskernel-lean-wasm@4.34.0
```

The exact Lean source commit remains part of provider metadata and runtime identity:

```text
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
```

A package with a different Lean version or source commit must not silently claim the same provider identity.

## Public JavaScript API

Use the package entry point rather than importing files under `host/` directly:

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

Supported exports are also available through:

```text
@proofscript/pskernel-lean/node
@proofscript/pskernel-lean/metadata
```

`host/node-provider.mjs` is implementation structure. Consumers should use the npm exports contract.

## PSC2 workspace consumption

The PSC2 self-host workspace declares:

```json
{
  "optionalDependencies": {
    "@proofscript/pskernel-lean": "4.34.0"
  }
}
```

It is deliberately optional. Ordinary PSC2 bootstrap and fixed-point operation must remain possible without installing or running the Lean provider.

Host orchestration resolves the package boundary in this order:

1. use the installed `@proofscript/pskernel-lean` package when Node can resolve it;
2. in a zero-install repository checkout, fall back to the local package's public `index.mjs` entry point;
3. never import `host/node-provider.mjs` directly from compiler/CLI orchestration.

This preserves a normal npm package boundary while allowing the current repository to run without a root `npm install` of all unpublished internal workspaces.

## Workspace membership is not bootstrap membership

`pskernel-lean` is a normal `packages/*` npm workspace. This does **not** make it part of PSC2's first fixed-point closure.

Its ProofScript package metadata remains:

```json
{
  "bootstrap": false,
  "portable": false,
  "role": "external-lean-kernel-provider"
}
```

`bootstrap-closure-contract.mjs` continues to forbid `pskernel-lean` from the portable bootstrap closure.

The intended boundary is:

```text
portable/generated PSC2 compiler
        |
        | canonical admissions
        v
host-selected KernelProvider
        |
        +--> @proofscript/pskernel-lean
        |
        +--> future @proofscript/pskernel
        |
        +--> future @proofscript/pskernel-lean-wasm
```

Lean-specific execution must stay on the host/provider side of this boundary.

## Native executable distribution

`@proofscript/pskernel-lean@4.34.0` bundles verified native executables directly in the package for:

```text
linux-x64
linux-arm64
darwin-x64
darwin-arm64
win32-x64
```

Supported-platform consumers do not need Lean, Lake, a C++ compiler, an install-time download, or a provider environment variable.

The package-local resolver chooses the provider in this order:

1. explicit `PSC_LEAN_KERNEL_PROVIDER_BIN` / `binaryPath` override;
2. bundled native executable for `process.platform` + `process.arch`;
3. source-checkout Lake output as a development fallback;
4. fail closed for unsupported/missing providers.

The bundled path is indexed by `PREBUILT_MANIFEST.json`. Before spawn, the adapter validates the package/provider/Lean identity and recomputes SHA-256 against the selected executable.

Windows ARM64 is not included in the Lean 4.34 matrix. It fails explicitly instead of silently running an x64 executable or downloading another artifact.

No install/postinstall script downloads or compiles native code. Installation is side-effect-free.

## Native build and assembly evidence

The distribution workflow builds each target on a native runner rather than cross-compiling the first matrix. Each build:

- verifies Lean `4.34.0` and exact `lean --githash`;
- builds the provider;
- strips release symbols;
- runs `--health` after stripping;
- runs positive semantic acceptance and negative kernel-rejection fixtures after stripping;
- inspects dynamic dependencies;
- proves standalone execution with the repository Lake build tree hidden;
- stages only the provider executable plus provenance metadata.

Assembly requires exactly five mutually consistent artifacts, verifies their SHA-256 and identity, generates `PREBUILT_MANIFEST.json`, runs `npm pack`, and executes the packed package in a clean consumer before the distribution can be committed.

The normal provider workflow then independently packs, installs, resolves, and executes the **committed package bytes** on all five supported target runners.

The native files are unsigned/not notarized. Do not make a stronger release-signing claim until a later signing milestone implements it.

## Consumer verification

CI installs the packed package into a clean temporary npm project and imports it by package name. This verifies that the `files` and `exports` contracts work independently of the monorepo layout.

For every supported native target, CI also verifies that with `PSC_LEAN_KERNEL_PROVIDER_BIN` unset:

- the resolver selects the package-local target binary;
- manifest digest verification succeeds;
- valid canonical admissions are accepted;
- codec-valid but ill-typed admissions are rejected by the Lean kernel.

CI additionally verifies that PSC2 host orchestration uses the package boundary and does not reach directly into the provider implementation path.

## Semantic contract

Packaging does not change what acceptance means. `checkCanonicalAdmissions` still sends canonical checked-admissions v2 to the pinned Lean provider and validates:

- protocol `pskernel-lean/1`;
- provider identity `lean4-cpp`;
- Lean version `4.34.0`;
- exact Lean source commit;
- provider profile `lean4.34-core`;
- boolean acceptance result.

See `INTEGRATION.md` for the semantic/trust boundary, `BUILDING.md` for source-build instructions, and `PREBUILT_MANIFEST.json` for the exact committed native artifact set.
