# PSC1 native npm toolchain and source packages

Current native provider/package checkpoint: review70522c25ea3826c05ba2e80f7f1e9c7df0b58213, tested merge063d1da64db9beb69a8303af5a2a8788233dc7dd, [Linux40106542849](https://github.com/dwijayuda/pskernel/actions/runs/40106542849). All three unpublished matching tarballs and exact hashes are in the [provider receipt](PSC1_BACKEND_PROVIDER_QUALIFICATION_2026-10-24.json). The [provider guide](PSC1_BACKEND_PROVIDERS.md) defines the default/add-on boundary. The older [candidate guide](PSC1_RELEASE_CANDIDATE.md) retains historical package evidence. Publication remains separate.

## Current implementation

The compiler is the checked native Lean 4.35.0 executable. The npm launcher verifies
its protocol, compiler profile, Lean version and exact Lean source commit before
forwarding commands. There is no archived generated-JavaScript compiler or checker
fallback.

`node scripts/npm-native-distribution.mjs` packages an already built native
compiler and tests unpublished tarballs in Linux CI. It does not build a self-host
generation or establish behavioral verification.

The package is named `proofscript`, version `0.1.0-psc1.3`, and remains
`private: true`. It contains:

| Included item | Responsibility |
| --- | --- |
| `native/bin/psc1` | One compiler, official pinned Lean admission provider, compiled Core prelude and five built-in targets: JS/TS/Rust/Wasm core/component |
| Explicit Python/PHP add-ons | Separate emit-only executables/resources; core-pinned exact build; neither is a default dependency |
| `native/lib/` when needed | Non-system Lean shared libraries observed from the executable |
| `npm-cli/psc.js` | Identity-checked command transport |
| `npm-cli/libraries.mjs` | Declarative npm metadata and filesystem path transport |
| `host-tools/` | Target validation, provenance and transactional publication |
| Bundled production npm dependencies | Exact host parser/formatter graph from its integrity lock |
| Source pin and distribution manifest | Compiler identity, source commit, binary digests and platform qualification |
| Lean and dependency notices | Notices retained with the bundled implementation |

The initial tarball qualifies Linux x64 with glibc. Its receipt records the actual
tested glibc version; it does not claim a lower minimum version or Windows/macOS
support. Node >=22 is required. Python, PHP, Cargo, Rustfmt, Wasm tools and the
TypeScript consumer checker are not installed merely by installing `proofscript`.
Selected targets report their separate validation/runtime requirements.

Native identity reports five built-in targets, two optional targets and the provider protocol. The distribution test independently installs each optional add-on and executes both grammars across all seven targets. Inclusion and installation are separate from feature-level qualification; the
[backend conformance record](PSC1_BACKEND_CONFORMANCE.md) remains authoritative.

## Build and install the unpublished package

From the `psc1` directory in the qualified Linux environment:

```sh
npm --prefix host-tools --workspaces=false ci --ignore-scripts
lake build psc1 psc1_backend_python psc1_backend_php
node scripts/npm-library-resolution-tests.mjs
node scripts/npm-native-distribution.mjs
```

The distribution command creates and tests a tarball under
`dist/scoped-correctness/npm-native/run-*/tarballs/`. Download the corresponding
CI artifact to obtain the tested tarball, then install that file:

```sh
npm install ./proofscript-0.1.0-psc1.3.tgz
npx psc --identity
# Install either optional backend only when required, from the same artifact:
npm install ./proofscript-backend-python-0.1.0-psc1.3.tgz
npm install ./proofscript-backend-php-0.1.0-psc1.3.tgz
npx psc build src/Main.ps --target js --out dist/Main.js
npx psc build src/Main.ps --targets ts,js --out-dir dist
```

No package was published to a registry or attached to a release. The CI package
contains its production host dependencies and needs no install script or network
binary download. The initial pack operation installs the locked build-time host
dependencies; the later consumer installation is tested offline.

The receipt includes both the checked-out CI commit and, for pull-request runs,
the branch-head commit. The native binary hash identifies the actual executable.
The installed native entrypoint also locates its host files without relying on the
npm launcher or an original development checkout.

## Why the historical packer does not qualify this compiler

The inherited `scripts/npm-distribution.mjs` packages PSC0 generated compiler/checker
assets and source facades. Its assumptions do not match the native launcher.
Current root commands use `npm-cli/psc.js` and `npm:pack:native`; historical
commands are explicitly named `npm:archive:psc0` and `npm:inspect:psc0`.
The historical script and recovery artifacts retain their original provenance.

## Portable optional libraries

A source package is an ordinary npm package containing supported `.ps` or
`.lean` files. The source-library contract supports portable source only: no compiler plugins, macros, FFI, runtime adapters, kernel extensions or new axioms. The separately versioned backend-provider contract does not change source-library authority.

A consumer registers a module prefix and declares its npm dependency:

```json
{
  "dependencies": { "@example/naturals": "1.0.0" },
  "proofscript": { "libraries": { "Demo": "@example/naturals" } }
}
```

The library exports its JSON metadata as data and declares the exact source profile:

```json
{
  "name": "@example/naturals",
  "version": "1.0.0",
  "files": ["src/"],
  "exports": { "./package.json": "./package.json" },
  "proofscript": {
    "library": {
      "schemaVersion": 2,
      "kind": "portable-source",
      "modulePrefix": "Demo",
      "sourceRoot": "src",
      "sourceKind": "ps",
      "publicModules": ["Demo.Math"],
      "compilerProfile": "psc1-checked-direct/1",
      "leanVersion": "4.35.0",
      "leanCommit": "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
    }
  }
}
```

`import Demo.Math` resolves `src/Demo/Math.ps`. A package can import another
module under its own prefix, including internal source omitted from
`publicModules`. Another package or consumer can import only declared public
modules. A transitive dependency has its own `dependencies` and
`proofscript.libraries` entries, resolved relative to the importing package.
This respects nested npm dependency installations.

Prefixes describe source locations. They do not automatically namespace declaration
identifiers. Library authors must use nonconflicting declaration names within the
current source subset; duplicates still fail native elaboration.

Package source symlinks may not escape their package root. Ambiguous local source
variants, incompatible pins, undeclared dependencies, mismatched package identities,
forbidden authority fields and private-module imports are rejected. Portable
libraries cannot import compiler-owned `Ps` or `ProofScript` modules through a
workspace fallback. Ordinary compiler development retains the existing native
loader, including its established non-ASCII local-module behavior.

## Admission and provenance

The resolver never imports or executes a guest JavaScript entry point. It transports
metadata and the selected source path to the native loader. That loader captures,
parses and elaborates source; the pinned Lean kernel independently admits the
resulting declarations before erasure and executable IR validation.

A compatible manifest supplies no proof authority. Ill-typed dependency source
still fails. Source and artifact digests cover the bytes actually compiled,
independently of npm installation bookkeeping. Generic artifact manifests do not
yet capture package.json/lockfile metadata as package-version provenance.

Use an npm lockfile for deterministic dependency installation. A signed catalogue,
package proof cache or content-addressed package certification mechanism is
separate work and is not claimed.

## Qualification and retained artifacts

The metadata test runs ten boundary groups, including private source, symlink
containment, identity/profile enforcement, forbidden authority, absence of guest
module evaluation and nested dependency resolution.

The distribution test packs the core plus two explicit optional providers, installs the core locally and globally
offline with an initially empty npm cache, compares native/npm identities, checks
installed native library resolution, builds and executes JavaScript without
installing TypeScript, then invokes the source-library canary. It also independently type-checks/executes installed TS, runs Rust/core-Wasm/component consumers, installs each optional backend offline, executes both source grammars, and checks26 absence/identity/integrity refusals without output changes.

That canary creates and packs two independent `.ps` libraries. The second imports
the first and its own private module. A consumer installs both local tarballs,
checks a four-source closure and executes `answer = 42`. Only the entry API is
exported. Direct private imports, incompatible pins and an ill-typed transitive
dependency must fail while preserving the previous output and manifest. This
proves transitive source and installed-package resolution, not registry retrieval
of a transitive dependency.

Tarballs, machine-readable receipts and source/output bundles remain under
`dist/scoped-correctness/npm-native/`. Duplicate temporary compiler installations
are removed after every qualification succeeds. Exact successful run and compiler
commit are recorded in [backend conformance](PSC1_BACKEND_CONFORMANCE.md).

## Remaining boundaries

The portable semantic compiler does not depend on npm transport. The native host
currently launches the metadata resolver per import edge. Metadata caching in one
captured session is a possible performance improvement if measurement justifies it.

General host/runtime adapter plugins, conflicting global declaration names across
simultaneous library versions, binary platform packages and non-Linux qualification
remain separate work. Built-in runtime helper selection stays with each backend;
optional source libraries do not install a global generated-program runtime.

## Primary references

- [npm package metadata](https://docs.npmjs.com/cli/v11/configuring-npm/package-json/)
- [npm pack](https://docs.npmjs.com/cli/v11/commands/npm-pack/)
- [Node module resolution](https://nodejs.org/api/modules.html#loading-from-node_modules-folders)
- [Node package exports](https://nodejs.org/api/packages.html#package-entry-points)

## Control/data continuation canary

The continuation's installed two-package canary compiles real transitive source
containing an Id do block, a lexical mutable local, assignment, a conditional and
early return. The installed native compiler independently admits the source graph,
and generated JS executes `answer = 42`. The canary receipt records these
`checkedControlFlow` forms. Existing private-module/profile/ill-typed-transitive
refusals and preservation of an earlier output remain mandatory.

See [the control/data checkpoint](PSC1_PRACTICAL_CORE_CONTROL_DATA.md) for the
observed exact head and workflow. This evidence covers the installed selected
source path; it does not qualify all fourteen families, a new public aggregate
ABI, non-Linux package installation, or npm registry publication.
