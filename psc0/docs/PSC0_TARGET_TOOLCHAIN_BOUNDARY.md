# PSC0 target-toolchain identity boundary

**Status: bounded installed qualification passed.** Source `494a0a715ebd1e29eba2d146903bb6a3a722be06`, [fast run38086137673](https://github.com/dwijayuda/pskernel/actions/runs/38086137673),66/66 host tests on Linux/Node22.23.3 and Windows/Node26.7.0, both PS/Lean installed editions. This is a host-only target/publication identity milestone, not complete PSC0-ARCH/1 P4/P6 or a backend soundness proof. The [validation ledger](PSC0_TARGET_TOOLCHAIN_VALIDATION.md) records the initial incorrect test premise and correction.

## Contract and owners

The parent selects installed TypeScript **7.0.2** and its exact `@typescript/typescript-<os>-<arch>` package. `target-files.mjs` captures the regular-file inventory of both packages, including native executable and libraries, before execution. Additions/removals, file content or executable-permission changes and nested symlinks are refused when observed. Root npm symlinks resolve once; immediate `node_modules` children are excluded and the selected native dependency is a separate captured root.

Binary-safe capture is bounded:4,096 entries,24 directory levels,128MiB/file,256MiB aggregate. The selected Linux installation contained530 files/30,443,488 bytes and Windows529 files/30,862,525 bytes. These identities describe captured installed bytes, **not authenticated registry provenance**.

`target-process.mjs` executes the same native binary to which TypeScript's official launcher delegates, without a shell, PATH lookup or JS wrapper subprocess. Parent cancellation, wall-time and diagnostic limits terminate and reap that selected process before completion. It does not load target-compiler JS into the proof-authority process. Only required system/temp paths and fixed locale survive environment filtering; arbitrary Node/Go/preload/PATH overrides do not.

`target-toolchain.mjs` owns one monolithic generated-TS profile: ES2022/module/strict/declaration/map flags, `--ignoreConfig`, `--noResolve` and a newly created private empty `typeRoots`. TypeScript6+ already defaults `types` to `[]`; this implementation explicitly fixes target options rather than claiming it repairs automatic type-package inclusion in TypeScript7. Foreign TypeScript linking is outside this profile; ordinary ProofScript source libraries still compile through the existing checked source graph.

A parent-owned plan hash binds selected installation, target flags, environment and limits to the checked frontend handle and audit receipt. Actual generated input and four output products are bounded regular-file hashes. Target identity is revalidated before/after native execution and again at the existing single publication switch. Failure/drift/cancellation cannot authorize a replacement executable. `psc check` neither requires nor invokes the target compiler.

## Qualified evidence

The unchanged prior50 unit tests plus16 new target tests passed on both OSes. Actual native and retained-launcher `.ts/.js/.d.ts/.js.map` products were byte-identical on the checked source-library fixture in each source edition. The fixture separately verifies default ambient-type exclusion, an explicit foreign-type syntax-error control and exclusion of surrounding project config. All target products must be freshly generated; controls cannot leave files that would mask a noEmit error.

Actual isolated native executable and declaration-library changes were refused. Native drift at the publication boundary preserved the previous executable. Both source editions retained the exact64-module installed bootstrap closure and69 unchanged qualified compiler source files. No compiler/kernel or full fixed-point generation occurred. See [machine evidence](PSC0_TARGET_TOOLCHAIN_QUALIFICATION.json).

## Limits and remaining obligations

The target process has a180s compile wall limit/1MiB diagnostic limit; version inspection uses15s/4KiB; each product is limited to32MiB. These are not total native RSS or filesystem-IO deadlines. The OS, installation owner and native compiler remain trusted. Transient filesystem races, external dynamic-library changes, hostile native-code isolation and registry/builder authentication are not proved or fully prevented. A byte-identical bounded fixture is not universal target-semantic preservation. Receipts remain audit data, never transferable proof authority.

## Research references

- Microsoft TypeScript launcher/platform selection, inspected source `aa8149273b23401f0a79a5f0384c42de51888693`: https://github.com/microsoft/TypeScript/blob/aa8149273b23401f0a79a5f0384c42de51888693/packages/typescript/lib/tsc.js
- TypeScript6 `types` default change: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html
- TypeScript noResolve: https://www.typescriptlang.org/tsconfig/noResolve.html
- TypeScript typeRoots: https://www.typescriptlang.org/tsconfig/typeRoots.html
- Node22 child-process lifetime/environment/cancellation: https://nodejs.org/download/release/v22.23.3/docs/api/child_process.html

The retained **7.0.2 bytes and actual installed comparisons** are authoritative evidence for this milestone; a newer upstream source alone would not qualify the retained runtime.
