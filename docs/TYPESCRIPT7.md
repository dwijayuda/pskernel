# TypeScript 7 development toolchain

The current root workspace and PSC0 use **TypeScript 7.0.2**, with Node **22.23.3** in their qualification workflows. Future development does not install or execute a TypeScript 5/6 compiler API package. Historical source revisions and evidence retain the producer versions that actually created them.

The root workspace is separate from the PSC0 self-hosted compiler. PSC0's selected seed, bounded source language and current qualification status are recorded in [PSC0 CURRENT](../psc0/docs/selfhost-language/CURRENT.md). A successful root compiler gate does not qualify or promote a PSC0 seed.

## Root compiler adapter

[TypeScript 7.0 does not provide the old compiler API](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/). The exported synchronous `compileTypeScript(source, fileName)` function in [typescript-compiler.ts](../packages/backend-ts/src/typescript-compiler.ts) therefore invokes the exact installed 7.0.2 package's JavaScript `bin.tsc` launcher through Node. It verifies both package metadata and the actual reported version. There is no alternate compiler fallback.

The adapter preserves the supplied source as a virtual root: it creates a unique temporary sibling of the logical `.ts` file and emits into a private temporary output directory. It never overwrites an existing logical source or its JavaScript, declaration, or source-map files. Relative imports and package exports resolve from the logical source directory. It returns the root's products even when a relative TypeScript dependency also emits files.

The generated JavaScript and declaration strings keep their public API shape. Diagnostic positions and source-map references name the logical source; temporary names do not escape in returned products. Map references use URL-escaped file names. All private files are removed on success or failure.

The supported host contract is an ordinary `.ts` logical name with an existing writable parent directory. The project CLI already creates its output directory before calling the adapter. A direct API caller must do the same. A root self-import or triple-slash reference whose resolution depends on the original basename is refused with `PS_TS_VIRTUAL_SELF_REFERENCE_UNSUPPORTED`, because staging must not substitute stale disk content for the supplied virtual source. Basename-dependent compiler output is also refused. This adapter does not claim a general arbitrary-filesystem compiler-host overlay.

The positional invocation explicitly preserves ES2022 target/modules, bundler resolution, strict checking, declaration/source-map output, no emission on error, skipped library checking, and automatic ambient type discovery. `--ignoreConfig` prevents a surrounding unrelated config from changing those settings. Project builds still use their explicit `tsc -p` configuration.

## Workspace migration

The root manifest and all 20 package manifests pin 7.0.2. The backend retains TypeScript as a runtime dependency because compilation is part of its exported Node API. Root and backend Node types are explicit. Ten package configs previously used `baseUrl: "."`; TypeScript 7 removes that option, and the existing relative `paths` mappings remain unchanged. Every package already sets `rootDir: "."` and `outDir: "dist"`, preserving the existing exported `dist/src/` layout.

The separate `selfhost/` host and generated-compiler CLI also require 7.0.2 before positional compilation and pass `--ignoreConfig`. Historical PSC0 replay recipes remain at their original revisions; current PSC0 recovery uses its independently qualified native TypeScript 7 route.

## Daily commands

After the exact generated lock is committed, install and use the current workspace normally:

```sh
npm ci --ignore-scripts --no-audit --no-fund
npm run build:src
npm run test:packages
npm run test:package-integration
```

For a local backend change after its dependencies are built:

```sh
npm run test --workspace @proofscript/backend-ts
```

That package test includes the focused virtual-source, import-resolution, diagnostic, map, refusal and cleanup contract. The root's existing ordered package gate runs it too.

## Qualification and exact lock evidence

The [root-only workflow](../.github/workflows/root-typescript7-qualify.yml) runs on the dedicated `psc0/typescript-7-only-v1` branch when a source push includes `[root-ts7-qualify]`. It does not launch the PSC0 qualification workflow.

Its [runner](../scripts/root-typescript7-qualify.mjs) resolves a new npm lock only when direct workspace dependencies differ from that lock. Initial migration uses `npm install --package-lock-only --ignore-scripts`, so resolving away an old lock does not execute an old compiler. Once the new lock is committed, subsequent runs use `npm ci` directly.

The runner authenticates the actual installed package, launcher version, exact lock, and all 21 direct package manifests. It then runs the root build, existing package tests, the two remaining conformance/lean4export package builds, package integration, and architecture/package checks once, in that order. No Lean corpus/oracle replay or PSC0 seed selection is part of this gate.

The artifact retains the actual npm-generated `package-lock.json`, installed-package metadata, installed profile, command output, and qualification receipt. Each JSON evidence file is read back and logged with its exact UTF-8 content, byte length, and SHA-256; large files use numbered chunks that reconstruct by concatenating decoded content with no separator. Registry integrity values and lock bytes are never invented or reconstructed from a summary.

A passing receipt is required before claiming this root migration verified. Source drafts and the workflow's existence are not execution evidence.
