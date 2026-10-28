# PSC1 npm distributions

The qualified .13 reference and the genuine modular preview are separate cohorts.
The new [modular preview guide](../architecture/installed-modular-toolchain.md)
provides its verified ZIP, installation, API transition and exact qualification.
It executes the compiler through 127 source-owned units in 15 executable owners,
with a thin psc CLI and 20 bundled core packages. Python/PHP stay optional leaves.
Its finite Linux install/watch/application tests pass; new modular G2/G3/fixed
points and final release promotion remain pending.

The rest of this page describes the preserved **.13 reference**, including its
compatibility ./compiler facades. Those obsolete lower checked aliases are removed
explicitly in the versioned modular preview; checked root APIs remain. Do not mix
engine/provider cohorts or infer that .13's whole-compiler files describe the preview.

## Qualified .13 reference

The .13 cohort makes one proofscript installation include all 20 existing core
@proofscript packages. It preserves the 25 existing directories and 24 npm names.
The unnamed compiler-unified source directory remains internal and has no invented
npm name. Its whole-compiler executor remains unchanged; modular G2/G3 are not qualified
by this reference distribution.

## Installation and use

Extract the qualified ZIP, then install only its root tarball:

    npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.13.tgz
    npx --no-install psc --help

For a global CLI, use npm install -g with the same tarball. Node >=22.23.3 is the
supported minimum. Exact Node/Bun/SDK versions in receipts identify tested tools.
There are no install hooks, source builds or network toolchain downloads.

All 20 core packages are declared required dependencies and bundled into the
root tarball. npm can retain them under:

    node_modules/proofscript/node_modules/@proofscript/

Do not depend on npm hoisting a transitive dependency. The root exposes every
core package through a stable subpath:

    import {compile} from 'proofscript';
    import {readSources} from 'proofscript/foundation';
    import {compile as compileJs} from 'proofscript/backend-js';
    import {sourcePackage} from 'proofscript/elab';

    const result = compile({
      sources: [{module:'Main',kind:'lean',text:'def answer : Nat := 42'}],
      entryModule:'Main'
    });
    // result.logicalAdmission === 'accepted'; result.source is checked JS.

Bare-name imports such as @proofscript/foundation remain available after explicitly
installing that existing package. Installing standalone core tarballs alongside the
bundled root may produce another npm scope. API identity is shared within each
scope; there is no invented process-global compiler singleton. The ordinary root-only
installation contains exactly one pair of qualified JS/TS executors.
Do not install every standalone tarball merely to obtain core packages; the root
already contains them.

## Dependency direction

    proofscript -> all 20 required core packages
      adapters/source interfaces -> @proofscript/compiler
        -> @proofscript/pskernel-lean-wasm

The existing compiler package physically owns the unchanged qualified compiler and
host payload. No package has a dependency back on proofscript. The workspace
validator traverses runtime and peer edges, rejects cycles, checks exact versions,
and verifies the complete root dependency/bundle set.

Python/PHP, native checking, Rust/Wasm compiler execution engines, TypeScript,
Rust target consumers and component SDKs remain explicit optional packages.
Missing tools refuse; no command downloads or substitutes a tool.
Offline optional installation must supply its exact dependencies as matching tarballs.
Existing optional engine/SDK archives retain their original versions and hashes.

Both .lean/.ps compiler inputs remain supported. Source packages expose only
variants actually present in their canonical sources. They do not translate Lean
to PS, register external libraries, or expose private low-level compiler functions.
The existing reserved namespace and admission/publication authority policies remain.

## Existing packages

| npm name | Interface/implementation | Installation |
| --- | --- | --- |
| @proofscript/backend-common | source-only | Automatic core |
| @proofscript/backend-js | shared-backend-adapter | Automatic core |
| @proofscript/backend-php | shared-backend-adapter | Optional |
| @proofscript/backend-python | shared-backend-adapter | Optional |
| @proofscript/backend-rust | shared-backend-adapter | Automatic core |
| @proofscript/backend-ts | shared-backend-adapter | Automatic core |
| @proofscript/backend-wasm | shared-backend-adapter | Automatic core |
| @proofscript/bootstrap | shared-compiler-adapter | Automatic core |
| @proofscript/bridge | source-only | Automatic core |
| @proofscript/cli | shared-compiler-adapter | Automatic core |
| @proofscript/compiler | qualified-shared-compiler | Automatic core |
| @proofscript/compiler-ir | source-only | Automatic core |
| @proofscript/core | source-only | Automatic core |
| @proofscript/elab | source-only | Automatic core |
| @proofscript/environment | source-only | Automatic core |
| @proofscript/erasure | source-only | Automatic core |
| @proofscript/foundation | source-only | Automatic core |
| @proofscript/meta | source-only | Automatic core |
| proofscript | core-package-umbrella | Automatic core root |
| @proofscript/pskernel-core | source-only | Automatic core |
| @proofscript/pskernel-lean | independent-kernel | Optional |
| @proofscript/pskernel-lean-wasm | independent-kernel | Automatic core |
| @proofscript/stdlib | source-only | Automatic core |
| @proofscript/syntax | source-only | Automatic core |

The twelve source-only interfaces expose sourcePackage/readSources and an explicit
./compiler entry. CLI/bootstrap/backend adapters use the existing checked compiler.
Backend compile adapters select their declared target and reject conflicting options.
Source snapshots verify exact byte hashes and bounded local import order; callers
still provide a complete explicit source closure to the production compiler.
The old baseline inventory and source counts remain in the [.12 guide at its exact
commit](https://github.com/dwijayuda/pskernel/blob/9d0e23c34484e4b1159f3e2428f5452139df530a/psc1/docs/guides/npm-packages.md).

## Build contracts

    cd psc1
    npm run check:workspace
    npm run build
    npm run build:packages
    cd packages/foundation
    npm run clean
    npm run build
    npm pack

build and build:packages build the existing package DAG. The old compiler build
is retained as build:compiler. Package builds use pinned qualified GitHub artifacts;
a read-only Actions token is needed to retrieve missing build inputs. Installation
does not invoke this process. Exact dependency tarball hashes and input fingerprints
support safe reuse. Missing/incompatible dependencies, bad exports and cycles fail.

The original .12 manifests advertised absent dist files and stale PSC0 metadata.
All 24 names now retain conventional build/clean/pack, honest exports/types/files,
exact dependencies, original source directories and Apache-2.0 owned code.
Upstream and qualified-input notices remain included.

## Verification boundaries

The compiler and genuine official Lean 4.35.0 providers are reused at their exact
qualified source/execution identities. The default checker remains the C++ kernel
compiled with Emscripten to linear-memory Wasm; compiler Wasm retains GC.
The sealed service retains its proofscript logical identity while the physical
npm implementation owner is @proofscript/compiler.

Only package/seal metadata is regenerated. No canonical .lean/.ps/compiler/kernel/
production host body changes. Original/transformed IR validation, independent
admission, source/logical-body pairing, semantic fuel, process limits, memory/stack
policies, negative tests, unsupported-ABI refusals and safe publication remain.
Installation is not a proof of semantic preservation or a new fixed point.

The finite [package contract](../../NPM_PACKAGE_CONTRACT.json) covers root-only
offline local/global installation, all core exports, Node/Bun API identity in both
scopes, one default executor pair, exact standalone bytes, both source grammars,
seven checked targets, genuine native/Wasm acceptance/refusal, accurate types,
optional engines, semantic/tamper/dependency refusals and reproducible builds.

[Exact .13 qualification](../PSC1_NPM_UMBRELLA_QUALIFICATION_2026-10-27.json)
records all 53 cases/125 exports at892e1895, [run40509034127](https://github.com/dwijayuda/pskernel/actions/runs/40509034127).
[Default ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40509034127/artifacts/12736333322) is 8917501 bytes; its root tarball is 4455215 bytes.
[Optional ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40509034127/artifacts/12736781848) is 198623191 bytes.
All package sizes/hashes accompany the delivery. Full source40509034008 passes all16 selected jobs/37 Core criteria and scoped seven-backend execution. The older .11 CLI compatibility run40507924067 also passes; the delivered umbrella remains .13. Universal non-Linux consumers, permanent bootstrap retention and the arranged
independent human maintainer trial remain separate release tasks.
No merge or npm registry publication is authorized.
