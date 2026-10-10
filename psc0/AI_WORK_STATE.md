# PSC0 AI work state — source-library disclosure implementation

## Scope (2026-10-11)

Continue PSC0-ARCH/1 on `psc0/npm-modular-packages-v1`, repository `dwijayuda/pskernel`, starting at `8c100a74f9724f39e55d3e707484a7e1be75de8a`. This is the narrow source-library transparency/INV-12 step, not executable guest support or full P3.

The previous target-toolchain milestone is completed: source `494a0a715ebd1e29eba2d146903bb6a3a722be06`, successful run `38086137673`, 66/66 host tests on Linux/Node22 and Windows/Node26. Its full AI state is preserved at [AI_WORK_STATE_TARGET_8c100a.md](docs/history/AI_WORK_STATE_TARGET_8c100a.md), exact blob `cb6330c50ac297923c22b41aa19f2a8c8d056ebb`. Do not restart earlier milestones.

## Changes being qualified

One parent-owned `npm-cli/library-disclosure.mjs` records declared vs actually loaded source libraries, exact snapshot manifest/module hashes, versions, namespaces and declared script names. It grants no proof authority, observes no installation history, authenticates no publisher, and executes no external JS. Root/library `proofscript.extensions` is explicitly unsupported; the existing source-library schema remains exactly its three documented fields.

`source-graph.mjs` records resolved aliases before realpath-based compilation deduplication, seals the inventory and binds its digest into the existing source snapshot. `build.mjs` reports host-owned stderr diagnostics before admission, even with `--json`, and binds the same inventory digest into the checked handle/receipt. Packages cannot supply a logging callback or suppress switch. No CLI or default-package expansion is added.

`source snapshot.fileEvidence` exposes only immutable fingerprints of bytes already captured, including BOMs; it does not read again. Existing capture/revalidation, kernel admission, frontend subprocess, target execution and publication ownership are retained.

## Validation strategy

Use the existing fast Linux/Windows workflow and exact retained compiler/kernel artifacts; add focused source-library tests plus an installed check reusing the earlier tiny source-library application. Verify exact metadata/source identity, duplicate/transitive/alias accounting, immutable disclosure, changed-input refusal, package claims cannot promote authority, no package entrypoint/script execution and rejected unsupported execution requests. Invalid library terms must still fail and preserve the previous executable.

This checkpoint has not yet been claimed successful; read live CI and update this file with the actual result. Do not weaken existing test assertions to promote a result.

## Preserved self-host and kernel boundaries

Language: bounded `ps-0.9-r3`, new-only; strict entry `psCompilerSh1TypeScriptSources`. Qualified compiler source `1fa5559a72b293defc56ef7e7020cf82d4b44b79`; 69 source files, 64-module bootstrap closure; inventory SHA `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de`. Keep selected R seed, TypeScript7.0.2, Node22.23.3 bootstrap and Lean4.34.0. The existing source-identity guard and baselines are unchanged.

Retain runtime source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, run `38075437516`, artifact `11678641329` (expires 2026-11-09). No compiler/kernel regeneration, C2/C3, portable-language rewrite or new npm dependency. Kernel implementation and adapter are owned by another branch and MUST NOT change here.

GitHub/cloud CI only. No local files/checkouts/builds/tests, Desktop Commander, force push, npm publication, main merge or unrequested release. Verify live HEAD before writes and use expected-HEAD non-force updates. Preserve concurrent work.

## Explicit limits

This remains a trusted host with source-only libraries, not a hostile-JS sandbox. The OS can redirect diagnostics; compromised host code is outside this protection. npm install lifecycle execution predates the compiler and is not made safe by library import. Hashes are byte identity, not publisher authenticity or consistency proofs. Full PSCV/axiom/effect policy, arbitrary executable guests, independent backend compilation, formal target preservation and a new installed self-host fixed point remain separate.
