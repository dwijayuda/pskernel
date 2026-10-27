# Existing PSC1 npm packages

This work delivers package interfaces around the existing compiler. Full compiler
IR modularization and modular self-hosting are deferred. Existing directories and
npm names are retained; no compiler or kernel is reimplemented.

## Inventory at PR196

The live baseline is173ecdc9f7131366d376c80886a7843a402d363b.
There are25 directories under packages/,24 with existing npm names. The internal
compiler-unified directory has no npm name and is not renamed or published.
The existing qualified root and both kernel distributions already have executable
artifacts. Most workspace source manifests advertise nonexistent dist files.
[Machine contract](../../NPM_PACKAGE_CONTRACT.json) retains the exact old exports;
Linux inventory/build receipts retain complete source files and dependency data.

| Existing package | Current source | Tracked dist at baseline | Original npm entry | Problem | Minimal repair |
| --- | --- | --- | --- | --- | --- |
| @proofscript/backend-common | src/ (5 files) | absent | none | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| @proofscript/backend-js | src/ (8 files) | absent | ./dist/index.js | Absent dist/stale metadata | Transparent adapter over existing checked root API |
| @proofscript/backend-php | src/ (5 files) | absent | none | Absent dist/stale metadata | Transparent adapter over existing checked root API |
| @proofscript/backend-python | src/ (5 files) | absent | none | Absent dist/stale metadata | Transparent adapter over existing checked root API |
| @proofscript/backend-rust | src/ (11 files) | absent | ./dist/index.js | Absent dist/stale metadata | Transparent adapter over existing checked root API |
| @proofscript/backend-ts | src/ (10 files) | absent | ./dist/index.js | Absent dist/stale metadata | Transparent adapter over existing checked root API |
| @proofscript/backend-wasm | src/ (31 files) | absent | ./dist/index.js | Absent dist/stale metadata | Transparent adapter over existing checked root API |
| @proofscript/bootstrap | src/ (1 files) | absent | ./dist/index.js | Absent dist/stale metadata | Transparent adapter over existing checked root API |
| @proofscript/bridge | src/ (5 files) | absent | ./dist/index.js | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| @proofscript/cli | src/ (1 files) | absent | ./dist/index.js | Absent dist/stale metadata | Transparent adapter over existing checked root API |
| @proofscript/compiler-ir | src/ (10 files) | absent | ./dist/index.js | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| @proofscript/compiler | src/ (5 files) | absent | ./dist/index.js | Absent dist/stale metadata | Transparent adapter over existing checked root API |
| @proofscript/core | src/ (8 files) | absent | ./dist/index.js | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| @proofscript/elab | src/ (17 files) | absent | ./dist/index.js | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| @proofscript/environment | src/ (9 files) | absent | ./dist/index.js | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| @proofscript/erasure | src/ (6 files) | absent | ./dist/index.js | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| @proofscript/foundation | src/ (6 files) | absent | ./dist/index.js | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| @proofscript/meta | src/ (6 files) | absent | ./dist/index.js | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| proofscript | existing provider/CLI source or distribution | absent | legacy bin/psc.js (absent) | Absent dist/stale metadata | One qualified shared implementation and existing CLI |
| @proofscript/pskernel-core | src/ (79 files) | absent | ./dist/index.js | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| @proofscript/pskernel-lean-wasm | existing provider/CLI source or distribution | absent | index.mjs; qualified provider available | No conventional workspace build for published prebuilt | Reuse exact provider under dist; preserve canonical sources |
| @proofscript/pskernel-lean | existing provider/CLI source or distribution | absent | index.mjs; qualified provider available | No conventional workspace build for published prebuilt | Reuse exact provider under dist; preserve canonical sources |
| @proofscript/stdlib | canonical stdlib/ProofScript | absent | ./dist/index.mjs | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |
| @proofscript/syntax | src/ (17 files) | absent | ./dist/index.js | Absent dist/stale metadata | Verified source API; explicit shared compiler entry |

## What the public interfaces provide

proofscript remains the single implementation owner. It packages the previously
qualified self-hosted JS/TS compiler, the existing checked host and default genuine
official Lean4.35.0 linear-memory Wasm checker. It contains all four core output
emitters. Optional Rust/Wasm execution engines and Python/PHP providers retain
their separate installation policy.

@proofscript/compiler and CLI/bootstrap interfaces transparently re-export the
existing root checked API. Backend compile adapters select their existing output
target and refuse a conflicting target option. The ./compiler subpath exposes the
full checked API explicitly.

Other source packages expose sourcePackage and readSources. These capture their
own canonical sources, verify recorded bytes/hashes and order local imports.
They do not expose private low-level compiler functions or implement a second
language resolver. Source import records describe data dependencies; executable
npm adapters depend on the existing root, which does not import them back.
Package metadata and source snapshots grant no checking or publication authority.

The frozen compiler's sole export is psCompilerServiceCandidate. A foundation
package therefore cannot honestly re-export psNameAppendStr from that executor.
The source interface is explicit about this limitation. readSources returns only
variants that exist; requesting a missing .ps variant refuses. No automatic
Lean-to-PS rewrite is performed. The stdlib build copies its existing canonical
stdlib/ProofScript files into the npm source snapshot without translation.

Both Lean providers retain genuine official C++ implementations. Their compiled
payloads live under dist/implementation while current canonical provider source
and build metadata remain unchanged. New npm wrapper versions4.35.0-psc1.12
distinguish the repack from old4.35.0 archives; Lean semantic identity stays4.35.0.

## Build and install

Use Linux CI or a development environment with the pinned artifact inputs:

    cd psc1
    npm run check:workspace
    npm run build:packages
    cd packages/foundation
    npm run clean
    npm run build
    npm pack

The root npm run build runs the package build. The previous compiler build is
still available as npm run build:compiler. Source builds use pinned qualified
GitHub artifacts and require a read-only Actions token to retrieve missing
inputs. They never run during npm installation. Previously verified inputs and
unchanged package outputs are cached by exact identities; missing dependencies,
changed inputs, invalid exports and incompatible versions fail.

CI retains unpublished tarballs with SHA256SUMS. For a fresh default installation:

    npm install -g ./proofscript-0.1.0-psc1.12.tgz
    psc --help
    psc init --kind lean
    psc check Main.lean
    psc build Main.lean --target js --out dist/app

The root bundles its compatible default Wasm kernel, so this install needs no
source build, native compiler, target SDK or network binary download. Additional
source/compiler adapters must be installed from the same exact .12 cohort. For
example, install the root tarball and foundation/compiler tarballs together with
npm install --offline --ignore-scripts <matching tarball paths>.

    import {compile} from '@proofscript/compiler';
    import {readSources} from '@proofscript/foundation';
    const ownedFoundationSources = readSources();
    // Supply an explicit, complete source closure to compile; snapshots never
    // bypass the production frontend, strict IR or independent checking.

Runtime syntax and target-tool requirements remain those of the existing CLI.
Native/Python/PHP release consumers remain Linux-qualified only. SDKs and optional
engines are explicit; no install hook downloads them. Kernel Wasm uses linear
memory and compiler Wasm retains GC.

## Acceptance and evidence

The focused Linux workflow builds/packs every existing named package, imports all
advertised exports after fresh offline installation, checks one shared runtime
identity, exercises local/global CLI, genuine kernel acceptance and rejection,
both source grammars, representative checked outputs and old-bundle parity.
It checks source/executable tampering, broken exports, missing dependencies,
incompatible versions and exact clean/build/pack reproduction.

Compiler code and old G1/G2/G3 identities stay unchanged. npm installation and
adapter tests do not establish a new fixed point or a formal source/backend
preservation proof. Full internal physical module independence is deferred.
Registry publication and merging require separate authorization.

## Qualified package results

The dated qualification receipt records all42 finite distribution cases,103
advertised imports, both genuine providers'14 acceptance/refusal cases each,
strict public typings, both grammars, all seven checked targets, optional engines,
source-snapshot compilation and exact clean/build/pack reproduction.

The default ZIP has21 matching tarballs; the optional ZIP has nine. There are
24 rebuilt named packages, including twelve source-only interfaces, nine checked
API adapters, one shared root and two independent provider wrappers. No new
individual compiler-internal module is compiled. Their genuine qualified
executors and providers are reused at their original identities.

Root proofscript-0.1.0-psc1.12.tgz: 3836354 bytes, SHA256 9a66dcd0f92aaa60f600674fb91b31bc0d67b211d1e9e004146baa8e96502fcc.
Native provider proofscript-pskernel-lean-4.35.0-psc1.12.tgz: 6453041 bytes.
All package sizes/hashes and complete source import inventories accompany the
delivery. The exact existing compiler execution files are checked against the
qualified input, separately from explicit package/seal metadata changes.

A complete source-package example, executed in CI:

    import {readSources} from '@proofscript/foundation';
    import {compile} from '@proofscript/compiler';

    const sources = [...readSources()];
    const imports = sources.map(source => 'import ' + source.module).join('\n');
    sources.push({
      module: 'Entry',
      kind: 'lean',
      text: imports +
        '\ndef answer : String := psNameToString (psNameAppendStr PsName.anonymous "café")\n'
    });
    const result = compile({sources, entryModule: 'Entry'});
    // result.logicalAdmission is 'accepted'; result.source is checked JS.
    // CI executes that output and observes answer === 'café'.

This explicit capture is different from registering a portable external library.
The existing reserved namespace policy still applies. Source-only npm packages
do not automatically acquire library, kernel, FFI or publication authority.

[Exact qualification and all tarball sizes/hashes](../PSC1_SIMPLE_NPM_PACKAGE_QUALIFICATION_2026-10-27.json).
[Default ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40501926898/artifacts/12732813811) and [optional ZIP](https://github.com/dwijayuda/pskernel/actions/runs/40501926898/artifacts/12732714143).
Full source run40497179005 retains all 16 selected jobs and 37/37 Core criteria.
The final documentation tarball refresh passes [40501926898](https://github.com/dwijayuda/pskernel/actions/runs/40501926898).
