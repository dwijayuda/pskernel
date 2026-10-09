# TypeScript 7 development toolchain

The current root workspace and PSC0 use **TypeScript 7.0.2**, with Node **22.23.3** in their qualification workflows. Future development does not install or execute a TypeScript 5/6 compiler API package. Historical source revisions and evidence retain the producer versions that actually created them.

The root workspace is separate from the PSC0 self-hosted compiler. PSC0's selected seed, bounded source language and current qualification status are recorded in [PSC0 CURRENT](../psc0/docs/selfhost-language/CURRENT.md). A successful root compiler gate does not qualify or promote a PSC0 seed.

## Qualified root checkpoint

The root TypeScript 7 migration passed on **9 October 2026** at source [`9d150afbec1feda8c97058aa56aa5ab92347d96d`](https://github.com/dwijayuda/pskernel/commit/9d150afbec1feda8c97058aa56aa5ab92347d96d), on branch `psc0/typescript-7-only-v1`. [Workflow run 37951869293](https://github.com/dwijayuda/pskernel/actions/runs/37951869293), job `113892421469`, completed successfully. The evidence is bound to that exact source revision.

The final run authenticated the actual installed **TypeScript 7.0.2** launcher and **Node v22.23.3**, all **21** source/lock compiler pins, and the committed npm lock. It used `npm ci` directly: `lockGenerated=false` and `retiredCompilerRuntimeUsed=false`.

| Required phase | Final result |
| --- | --- |
| Clean dependency installation | Passed |
| Root TypeScript build | Passed |
| Existing ordered package tests, including the new adapter contract | Passed |
| Conformance package build | Passed |
| Lean exporter package TypeScript build | Passed |
| Package integration | Passed |
| Package map, source shape, VS Code shape/smoke, and architecture checks | Passed |

All seven recorded commands exited with code `0`. The focused adapter contract completed all **11 obligations**: supplied virtual source and existing-product preservation, logical map naming, config-independent positional compilation, relative TypeScript imports, package-export imports, root-output selection, logical diagnostic positions, self-reference refusal, declaration-input refusal, missing-directory refusal, and cleanup.

The [actual qualification receipt](../psc0/docs/selfhost-language/root-typescript7-qualification.json), [evidence provenance](../psc0/docs/selfhost-language/root-typescript7-evidence.json), and [complete primary log](../psc0/docs/selfhost-language/evidence-logs/root-typescript7-qualification.log) are retained in the repository. The receipt is **3,485 UTF-8 bytes** with SHA-256 `a6f2b2e31ca61a8249954d43849bb622d01b876db7f8046a67353ce82e9de39a`. The committed lock is **21,592 bytes** with SHA-256 `69c5e49b040ff3d45909e15cf1e2123af39fa223b00a7241b533c022a49e33e1`.

The qualification covers the root host adapter, package builds/tests, integration, and repository boundaries. It does not establish a PSC0 fixed point, provider acceptance, cold F recovery, native Lean bootstrap qualification, or a seed promotion.

## Root compiler adapter

[TypeScript 7.0 does not provide the old compiler API](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/). The exported synchronous `compileTypeScript(source, fileName)` function in [typescript-compiler.ts](../packages/backend-ts/src/typescript-compiler.ts) therefore invokes the exact installed 7.0.2 package's JavaScript `bin.tsc` launcher through Node. It verifies both package metadata and the actual reported version. There is no alternate compiler fallback.

The adapter preserves the supplied source as a virtual root: it creates a unique temporary sibling of the logical `.ts` file and emits into a private temporary output directory. It never overwrites an existing logical source or its JavaScript, declaration, or source-map files. Relative imports and package exports resolve from the logical source directory. It returns the root's products even when a relative TypeScript dependency also emits files.

The generated JavaScript and declaration strings keep their public API shape. Diagnostic positions and source-map references name the logical source; temporary names do not escape in returned products. Map references use URL-escaped file names. All private files are removed on success or failure.

The supported host contract is an ordinary `.ts` logical name with an existing writable parent directory. The project CLI already creates its output directory before calling the adapter. A direct API caller must do the same. A root self-import or triple-slash reference whose resolution depends on the original basename is refused with `PS_TS_VIRTUAL_SELF_REFERENCE_UNSUPPORTED`, because staging must not substitute stale disk content for the supplied virtual source. Basename-dependent compiler output is also refused. This adapter does not claim a general arbitrary-filesystem compiler-host overlay.

The positional invocation explicitly preserves ES2022 target/modules, bundler resolution, strict checking, declaration/source-map output, no emission on error, skipped library checking, and automatic ambient type discovery. `--ignoreConfig` prevents a surrounding unrelated config from changing those settings. Project builds still use their explicit `tsc -p` configuration.

## Workspace migration

The root manifest and all 20 package manifests pin 7.0.2. The backend retains TypeScript as a runtime dependency because compilation is part of its exported Node API. Root and backend Node types are explicit. Ten package configs previously used `baseUrl: "."`; TypeScript 7 removes that option, and the existing relative `paths` mappings remain unchanged. Every package already sets `rootDir: "."` and `outDir: "dist"`, preserving the existing exported `dist/src/` layout.

The separate `selfhost/` host and generated-compiler CLI also require 7.0.2 before positional compilation and pass `--ignoreConfig`. Historical PSC0 replay recipes remain at their original revisions; current PSC0 recovery uses its independently qualified native TypeScript 7 route.

The compiler package retains its existing `typescript+lean+proofscript-bootstrap` inventory and paired `src/ProofScript/Compiler/Data.lean` / `Data.ps` sources. The package map now agrees with that manifest, and the map guard requires exact nonempty source-language agreement for all 20 outer packages. Its dependency, trust, status, cycle, and authored-source checks remain in place. The historical native bootstrap target is unchanged and was not exercised by this root gate.

## Daily commands

The exact npm-generated lock is committed and verified. Install and use the current workspace normally:

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

The final receipt's file bytes, hashes, source/run identity, exact command sequence, and installed profile were independently checked from the complete primary log and actual GitHub API responses. The adapter contract is a compact stdout record; its 11 obligations are identified separately from the actual JSON receipt files. Artifact `11626670229` contains **13,228 bytes**; its archive SHA-256 is `a424a5c9bacbc31caf51160c471266401d0d4c520b87bce7cb3100c60d552cf6`. The archive digest and individual receipt-file hashes identify different byte sequences.

### Earlier attempts and corrections

The evidence provenance retains the exact logs, actual receipts, run/job/artifact API responses, and file-authentication reports for all three earlier attempts. Each earlier qualification receipt remains `passed=false`.

| Attempt | Exact source | Result and correction |
| --- | --- | --- |
| [37949490366](https://github.com/dwijayuda/pskernel/actions/runs/37949490366) | [`a02f03b9`](https://github.com/dwijayuda/pskernel/commit/a02f03b97bb3385b66ad670dabf7f13d334fc79f) | Failed during package tests because the new footer assertion required a final newline. The assertion was corrected to accept the adapter's documented LF, CRLF, or end-of-file spelling. Adapter behavior was unchanged. This attempt generated the exact new lock through the metadata-only command before installing the current compiler. |
| [37950075083](https://github.com/dwijayuda/pskernel/actions/runs/37950075083) | [`3fce771a`](https://github.com/dwijayuda/pskernel/commit/3fce771a3607341ce0c9dfc1f1fa3974e2f0dbab) | Package tests, all 11 adapter obligations, and the conformance build passed. The exporter build exposed its existing subprocess type mismatch. A type-only correction describes the actual ignored stdin and piped stdout/stderr; executable behavior is unchanged. |
| [37950522687](https://github.com/dwijayuda/pskernel/actions/runs/37950522687) | [`5d3cbc82`](https://github.com/dwijayuda/pskernel/commit/5d3cbc82cb8759b909d1a957d6a22d542509d8c5) | All preceding builds, package tests, and package integration passed. Package boundaries found the compiler's mixed-source inventory mismatch. The package map was aligned with the existing manifest, and exact language equality was enforced for all outer packages. |
| [37951869293](https://github.com/dwijayuda/pskernel/actions/runs/37951869293) | [`9d150afb`](https://github.com/dwijayuda/pskernel/commit/9d150afbec1feda8c97058aa56aa5ab92347d96d) | Passed the complete unchanged seven-phase root gate. |

Before the final run, the complete remaining boundary surface was reviewed together: all 178 TypeScript sources in the 12 guarded directories, all 10 editor inputs, the complete package graph and manifests, the 19 erasure source modules, the compiler module, and the explicit verified pipeline/emitter boundaries. That static review found no additional required correction. The final run then executed the existing boundary gates successfully.
