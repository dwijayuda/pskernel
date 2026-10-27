# PSC1 AI work state

Updated 2026-10-27 Asia/Jakarta. Active [PR #198](https://github.com/dwijayuda/pskernel/pull/198), branch `feat/psc1-npm-umbrella-20261027`, based on qualified PR #197 HEAD `9d0e23c34484e4b1159f3e2428f5452139df530a`.
GitHub/Linux CI only; expected-HEAD single-parent/non-force updates. No merge or registry publication.

## Completed: automatic core npm installation

Cohort .13 makes proofscript an umbrella over all 20 existing core @proofscript
packages. The existing @proofscript/compiler owns the shared qualified implementation.
Adapters depend on compiler; no package depends back on root. The static contract
checks all declared workspace runtime/peer edges for cycles. Python/PHP/native and
Rust/Wasm engine/SDK payloads remain explicit optional packages.
All 25 directories and 24 npm names are preserved. Twelve source interfaces remain
source snapshots, not private executable compiler APIs. No new internal compiler
partitioning or modular G2/G3 is required.

[Package guide](docs/guides/npm-packages.md),
[finite contract](NPM_PACKAGE_CONTRACT.json),
[exact .13 receipt](docs/PSC1_NPM_UMBRELLA_QUALIFICATION_2026-10-27.json).
The previous .12 qualification remains preserved in its dated receipt and PR #197.

## Actual qualification

Implementation acbf4e70 is retained. Final qualified HEAD `892e1895b6be54f2fff4957a66b34d293c4105b8`
passes [40509034127](https://github.com/dwijayuda/pskernel/actions/runs/40509034127),
job122205738648, tested merge `10a6d84e07d24bde3587e5a951ca55d4a5243361`:
**53/53 finite package cases and 125 advertised exports** pass.
The root-only fixture installs its one tarball offline with an empty npm cache,
checks all 20 core packages/86 core exports, Node/Bun shared API identity, actual
local/global CLI check/build and confirmed checked JS publication.
All seven checked targets, both source grammars, optional Rust/Wasm compiler engines,
strict typings, actual source-snapshot compilation, all 24 package builds/installs,
exact clean/build/pack reproduction and semantic/dependency/tamper refusals pass.
Genuine native and Wasm Lean providers each pass 14 acceptance/refusal fixtures.
All 61 original Rust SDK pins pass unchanged.

Root-only installation contains exactly one JS/TS executor pair. Bundled packages
may remain in proofscript/node_modules rather than the project's top-level
node_modules. Use proofscript/compiler, proofscript/foundation, proofscript/elab
or proofscript/backend-js without relying on hoisting. Installing standalone
packages explicitly may produce a separate npm scope; both scopes retain exact
qualified bytes, shared API identity within their scope and fail-closed tamper
rejection. No synthetic global compiler singleton was added.

Initial40506390847 found the SDK helper's old owner path after all package builds
and graph checks passed. 40506787126 passed root-only installation/compilation but
exposed the old cross-scope function-identity assumption. The final suite keeps
identity assertions in both real scopes, enforces a single default executor pair,
checks every standalone executor's exact bytes and rejects tampering in both owners.

## Artifacts and installation

[Default ZIP 12736333322](https://github.com/dwijayuda/pskernel/actions/runs/40509034127/artifacts/12736333322): 8917501 bytes, 21 matching tarballs.
[Optional ZIP 12736781848](https://github.com/dwijayuda/pskernel/actions/runs/40509034127/artifacts/12736781848): 198623191 bytes, nine tarballs.
Root proofscript-0.1.0-psc1.13.tgz: 4455215 bytes, SHA256 `62d8b6843328e197a3fcb4acf47bd497c2642a4bfab9b4920808e1dcbf2ee9d3`.
Standalone compiler tarball: 3270363 bytes. Full per-package hashes/sizes
are in the receipt, PACKAGES.json and SHA256SUMS.

Install only the root tarball for the default toolchain:

    npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.13.tgz
    npx --no-install psc --help

No source build or installation/download hook. Optional offline consumers must
supply exact matching dependency tarballs; automatic registry installation is
not yet available because no registry publication is authorized.

## Preserved trust and qualification

All 49 original compiler/host execution files retain exact bytes. Only named
package/seal metadata is regenerated for the new physical owner/layout/cohort.
Canonical .lean/.ps/compiler/kernel/production host bodies are unchanged.
Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, independent admission,
strict original/transformed IR, source/logical-body pairing, semantic fuel,
240-second compiler requests, 120-second checker requests and memory/stack/safety
limits remain unchanged. Kernel Wasm remains genuine C++/Emscripten linear memory.
Owned code is Apache-2.0; all qualified-input/upstream notices remain.

Frozen G3 source identity stays122 modules/4742 members and closure
073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9.
Current development source has125 source-import modules. No new fixed-point claim.
Final current-source [40509034008](https://github.com/dwijayuda/pskernel/actions/runs/40509034008)
passes all16 selected jobs (benchmark intentionally skipped), all37 Practical Core
criteria/zero blocked, both grammars/scoped seven-backend execution, retained modular
pilots/source bindings and selected generated G1/closure checks at892e1895,
tested merge10a6d84e07d24bde3587e5a951ca55d4a5243361.
The superseded40507930222 was cancelled; it is not failure evidence.
The separate older .11 CLI workflow40507924067 also passes all9 jobs, including
runtime/refusal/installable checks. Its .11 tarball is compatibility context and
must not replace the .13 umbrella artifacts.
No new code failure remains. All24 .13 tarball hashes match the earlier qualified
40507930195; the root tarball SHA256 above is unchanged. This final update changes
only work-state/evidence/guides and requires the ordinary documentation/static gate.
Previous qualifications and all commit history remain preserved.

## Remaining work

This npm umbrella milestone is qualified on Linux. No failing package-contract case.
Non-Linux release consumers/durability, permanent qualified-input retention,
the user-arranged human maintainer trial and authorized final publication remain.
Follow the dependency-ordered roadmap for further language/CLI work.
Full compiler-internal modularization remains deferred. PR #195/#196 qualifications
and the separate unqualified partition branch b9461a3c are preserved; no old work
was overwritten. Do not resume that research as a prerequisite for npm usability.
