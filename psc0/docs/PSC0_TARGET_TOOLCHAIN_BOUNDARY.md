# PSC0 target-toolchain identity boundary

Status: coherent implementation prepared; qualification is not yet claimed. This is a host-only slice of PSC0-ARCH/1's target and release binding obligations, not a new backend, compiler language, kernel or complete P4/P6.

## Contract

The checked parent selects installed TypeScript **7.0.2** and its exact `@typescript/typescript-<os>-<arch>` package. It captures the complete regular-file inventory of both packages, including native executable and library bytes, before execution. Directory additions/removals, file changes, executable-permission changes and nested symlinks are detected/refused. Root npm symlinks may resolve once; nested `node_modules` are excluded and the selected native dependency is separately captured.

Capture uses bounded streaming (not UTF-8 decoding for binaries): at most 4,096 entries, 24 directory levels, 128 MiB per file and 256 MiB aggregate per toolchain. The identities describe **installed captured bytes**, not authenticated registry provenance. The installation/OS remains trusted and transient filesystem races are not claimed eliminated.

The official TypeScript launcher delegates directly to its platform executable. This host executes that same selected native binary without a shell, second package lookup or JS wrapper process. The parent can terminate/reap it on cancellation, wall-time limit or diagnostic overflow. It does not import target compiler JS into the proof-authority process. The sanitized environment permits only required system/temp paths and fixed locale, not arbitrary preload/Go runtime variables or PATH overrides.

For the currently generated monolithic TypeScript program, the target plan retains ES2022/module/strict/declaration/source-map flags, ignores project configuration, disables adding imported target files with `noResolve`, and supplies a newly created empty `typeRoots` directory so ambient npm typings do not enter the program. Foreign TypeScript linking is not implemented by this profile. Source libraries still compile through the existing ProofScript source graph.

A parent-owned plan hash binds target identity, flags, environment and limits to the checked frontend handle and audit receipt. The actual generated TypeScript input and all four outputs are byte-hashed; output files are bounded regular UTF-8 files. Identity is revalidated before/after the native process and again at the existing single publication boundary. Target failure/drift/cancellation cannot replace the prior executable. `psc check` does not require or execute TypeScript.

## Evidence required

Keep the old 50 tests and both installed source-edition suites. Add negative toolchain-tree, metadata, native subprocess, cancellation and output-budget tests. On Linux/Node22 and Windows/Node26, compare `.ts`, `.js`, `.d.ts` and `.js.map` bytes against the retained original TypeScript launcher on the same bounded generated input, verify isolation from inherited ambient typings, and refuse toolchain-byte drift without publishing. Do not change compiler/kernel sources, source-identity baselines, seed or language. Reuse retained artifacts; no C2/C3, full generation or npm publication.

## Research basis

- Microsoft TypeScript `packages/typescript/lib/getExePath.js` and `lib/tsc.js`, source `aa8149273b23401f0a79a5f0384c42de51888693`: installed platform resolution and transparent native delegation. https://github.com/microsoft/TypeScript/blob/aa8149273b23401f0a79a5f0384c42de51888693/packages/typescript/lib/tsc.js
- TypeScript `noResolve`: https://www.typescriptlang.org/tsconfig/noResolve.html
- TypeScript `typeRoots`: https://www.typescriptlang.org/tsconfig/typeRoots.html
- Node22 child-process argument, environment, cancellation and close semantics: https://nodejs.org/download/release/v22.23.3/docs/api/child_process.html

The retained **7.0.2** bytes and actual installed comparison are authoritative for this release; newer upstream source alone is not evidence about those retained bytes. No universal target-semantic-preservation or hostile-guest-sandbox guarantee is asserted.
