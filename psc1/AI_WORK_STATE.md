# PSC1 AI work state

Updated 2026-10-27 Asia/Jakarta. Active [PR #197](https://github.com/dwijayuda/pskernel/pull/197), branch `feat/psc1-simple-npm-packages-20261027`, based on PR #196 at `173ecdc9f7131366d376c80886a7843a402d363b`.
GitHub/Linux CI only; single-parent expected-HEAD/non-force history. No merge or npm publication.
Previous work state is preserved exactly in [history](docs/history/AI_WORK_STATE_BEFORE_SIMPLE_NPM_2026-10-27.md), baseline blob `79a5f936f912d2916e0d59fda739100f6e47e131`.

## Completed: simple existing npm package distribution

[Exact receipt](docs/PSC1_SIMPLE_NPM_PACKAGE_QUALIFICATION_2026-10-27.json),
[package guide](docs/guides/npm-packages.md), [finite contract](NPM_PACKAGE_CONTRACT.json).

All 25 existing directories and 24 npm names are retained. The unnamed compiler-unified directory remains internal source.
All 24 named manifests/build contracts are repaired: one shared root, nine checked API adapters, twelve verified source interfaces and two independent providers.
Five already-working qualified distributions are reused: proofscript, both Lean providers and optional Python/PHP emit-only bundles.
No new compiler-internal module is individually compiled. Source-only packages do not expose private elaborator/Core functions.

Implementation `9aefeeb469b4e350348d365ff3e1c149df82ac71` passes all 42 finite package cases in [40497178826](https://github.com/dwijayuda/pskernel/actions/runs/40497178826).
The stdlib README correction at `c5c15582158e251eb4b843589e2bb55b3ab0ffc4` passes the complete 42-case package contract again in [40501926898](https://github.com/dwijayuda/pskernel/actions/runs/40501926898), tested merge `6e03dde724459b5d1048480aab00a107895c36c2`.
The 103 advertised exports, all 24 fresh offline installs/build commands, Node/Bun shared API identity, exact clean/build/pack reproduction, real local/global CLI check/build, both source grammars, all seven checked targets, optional Rust/Wasm engines, strict public declarations and negative/tamper/dependency cases pass.
Both genuine providers pass 14 acceptance/refusal cases each. All 49 existing root execution files retain exact qualified bytes; only named package/seal metadata is regenerated.
Node 22.23.3 covers the complete new contract; Bun 1.4.4 covers shared API/source identity. Prior .11 runtime/watch qualification is retained separately.

Full current-source [40497179005](https://github.com/dwijayuda/pskernel/actions/runs/40497179005) passes all 16 selected jobs and 37/37 Practical Core criteria at implementation 9aefeeb, tested merge `c61e541bf593b5c279f05640a9b52814b0d07be5`.
Subsequent edits change documentation only. This is not new modular G2/G3 or final cross-platform release qualification.

## Installable artifacts and identities

Default ZIP: [12732813811](https://github.com/dwijayuda/pskernel/actions/runs/40501926898/artifacts/12732813811), 5073851 bytes, 21 tarballs.
Optional ZIP: [12732714143](https://github.com/dwijayuda/pskernel/actions/runs/40501926898/artifacts/12732714143), 198623181 bytes, nine tarballs.
The extra six optional engine/SDK archives retain their original exact versions and hashes; there are 24 rebuilt named packages overall.
Root `proofscript-0.1.0-psc1.12.tgz`: 3836354 bytes, SHA256 `9a66dcd0f92aaa60f600674fb91b31bc0d67b211d1e9e004146baa8e96502fcc`.
Native kernel tarball: 6453041 bytes. Every package size/hash and exact source import inventory accompanies the artifacts.

The default root owns the qualified JS/TS executors and bundles the genuine Lean Wasm checker. Native checking, Python/PHP, Rust/Wasm compiler engines and SDKs remain optional.
No install hooks or compiler source builds are needed. Minimum Node policy remains >=22.23.3; exact CI tools are qualification identities.
Owned source/adapters use Apache-2.0; qualified-input and upstream notices are retained.
Kernel wrapper version `4.35.0-psc1.12` does not change Lean semantic identity `4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Canonical .lean/.ps/compiler/kernel/production host implementations are unchanged; genuine C++ native and Emscripten linear-memory Wasm payloads remain unchanged.
Strict original/transformed IR, official independent admission, logical-body pairing, semantic fuels, 240-second compiler requests, 120-second checking and memory/stack safety limits remain unchanged.

Frozen G3 executors retain 122 source modules/4742 members and closure `073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9`.
Current development source has 125 source-import modules. Do not conflate their identities or claim new fixed points.

## Remaining scope and continuation

This simple npm milestone is complete in the documented Linux scope. No remaining package failure in the 42-case contract.
Before universal registry release: qualify actual non-Linux SDK/provider/publication consumers, permanently retain pinned bootstrap assets, and obtain merge/publication authorization.
The user-arranged independent human maintainer trial remains pending.
The dependency-ordered roadmap retains diagnostics, component String/IO and other finite release work.

Full internal compiler partitioning, recursive-group packaging and modular G1/G2/G3 are deferred.
PR #195/#196 qualified component work remains intact. Separate branch `feat/psc1-modular-partitions-20261027` retains unqualified intermediate implementation `b9461a3c6cd556a2c73abdee5cd9156e745c7f5d` (failed run 40489837660); it is not part of PR #197.
Actual graph measurement at 177e41a3 passes 40488488194: 125 modules, 3154 original/3950 specialized/4520 fused values, no cross-source runtime SCC larger than one, 111938 ms/maxRSS 389420 KiB. This is measurement, not successful emission or self-hosting.
