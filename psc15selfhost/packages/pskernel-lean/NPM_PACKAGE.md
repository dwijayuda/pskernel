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

Host orchestration resolves the provider in this order:

1. use the installed `@proofscript/pskernel-lean` package when Node can resolve it;
2. in a zero-install repository checkout, fall back to the local package's public `index.mjs` entry point;
3. never import `host/node-provider.mjs` directly from compiler/CLI orchestration.

This preserves a normal npm package boundary while allowing the current repository to run without a root `npm install` of all unpublished internal workspaces.

## Workspace membership is not bootstrap membership

`pskernel-lean` is now a normal `packages/*` npm workspace. This does **not** make it part of PSC2's first fixed-point closure.

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

## Native executable distribution status

The npm package API exists now, but this package does **not yet ship prebuilt native executables for every supported OS/architecture**.

In this repository, build the native provider with:

```text
npm run build:kernel:lean434
```

The Node adapter then finds the Lake output automatically.

An external npm consumer can currently supply a native provider path with:

```text
PSC_LEAN_KERNEL_PROVIDER_BIN=/absolute/path/to/psc2_lean_kernel_provider
```

or pass `binaryPath` to `checkCanonicalAdmissions`.

Do not claim that an npm install alone provides a runnable native kernel until prebuilt platform artifacts are actually packaged.

A later distribution layer may add platform-specific native packages while preserving this public JavaScript API. The WASM transport should be published separately as `@proofscript/pskernel-lean-wasm` rather than changing the semantics of the native package.

## Consumer verification

CI installs this package into a clean temporary npm project and imports it by package name. This verifies that the `files` and `exports` contracts work independently of the monorepo layout.

CI also verifies that PSC2 host orchestration contains the package import boundary and does not reach directly into the provider implementation path.

## Semantic contract

Packaging does not change what acceptance means. `checkCanonicalAdmissions` still sends canonical checked-admissions v2 to the pinned Lean provider and validates:

- protocol `pskernel-lean/1`;
- provider identity `lean4-cpp`;
- Lean version `4.34.0`;
- exact Lean source commit;
- boolean acceptance result.

See `INTEGRATION.md` for the semantic/trust boundary and `BUILDING.md` for native build instructions.
