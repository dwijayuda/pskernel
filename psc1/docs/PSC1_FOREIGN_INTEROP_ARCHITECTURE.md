# PSC1 foreign interoperability architecture

Status: architecture decision; implementation milestones below remain unqualified. Source baseline: `da880d864ca5f9e35729255fd7e4f8a17953cd39`, Lean 4.35.0. This document does not assert existing foreign-import support.

## Evidence and boundary

`npm-cli/libraries.mjs` implements declarative `portable-source` schema v2 packages. `contract` requires the exact compiler/Lean profile, public module ownership and a contained source path; it explicitly rejects `axioms`, `plugins`, `kernel`, `trust`, `ffi` and `runtimeAdapter`. `resolveImportedSource` resolves dependencies from the actual importing package. `scripts/npm-library-resolution-tests.mjs` covers those refusals and confirms that source resolution does not execute a package's JavaScript entrypoint. Preserve this contract rather than extending it silently into executable loading.

`packages/compiler-ir/src/Ps/CompilerIr/Model.lean` has `PsVerifiedIrExternalImport {localName, source, importedName, type}`. This is transport and typing shape, not dependency identity, authorization, effect semantics or logical admission. `packages/backend-rust/src/Ps/BackendRust/Module.lean` explicitly refuses imports in `psRustEmitSelectedValidatedModule` with `PSC1_RUST_EXTERNAL_IMPORT_UNSUPPORTED`. A new source spelling cannot by itself establish working interop.

`host/src/Ps/Host/SourceSnapshot.lean` captures dependency-ordered exact source bytes once. `host-tools/artifacts.mjs` owns formatting and target tooling; its current Rust artifact path creates Cargo metadata, generates a lockfile and checks with `--locked`. Foreign package resolution and target tooling belong to that host layer, outside portable compiler semantics and independent logical checking.

## Decision

Use three separate package contracts:

1. Portable source libraries: existing v2 contract, independently elaborated/admitted with ordinary source; no foreign or trust authority.
2. Portable capability interfaces: checked types and request/result data, with explicit per-target implementations and missing-target refusal. A portable interface does not imply identical foreign implementation behavior.
3. Target foreign adapters: optional runtime packages with a versioned descriptor and ordinary executable assurance. An adapter may implement a capability; it may not introduce a theorem, unchecked logical constant, new axiom or checker plugin.

Keep the initial compiler bootstrap independent of general foreign imports. Filesystem, package lookup, checker invocation and artifact publication use its explicit host protocol. Reuse that capability boundary for typed I/O; do not require npm/Cargo/PyPI/Composer integration before the first JS/Rust fixed point.

Start with hand-authored, concrete, synchronous wrappers. Prefer existing module imports plus a descriptor for the first implementation; defer `foreign import "npm:..."` syntax until the descriptor and admission/runtime separation are qualified. Ecosystem prefixes identify a package manager, not a portable semantic meaning.

## Adapter descriptor v1

Proposed fields (this is a specification, not a trusted token):

```json
{
  "schema": "psc1-foreign-adapter/1",
  "interfaceId": "example.text/1",
  "interfaceDigest": "sha256:<checked-interface-bytes>",
  "targets": ["js", "ts"],
  "ecosystem": "npm",
  "package": "@example/text",
  "resolvedVersion": "<exact>",
  "lockDigest": "sha256:<lock-bytes>",
  "contentDigest": "sha256:<resolved-package-bytes>",
  "adapterDigest": "sha256:<wrapper-bytes>",
  "environment": "node",
  "moduleMode": "esm",
  "entry": "./psc1-adapter.mjs",
  "operations": [{
    "id": "length",
    "request": "text-request/1",
    "response": "nat-result/1",
    "effect": "foreign",
    "async": false
  }],
  "contract": "external-unverified"
}
```

Validate identities, types, source containment, entry exports, environment, effect, target availability and exact locked dependency resolution before emission. Store the descriptor, lock identity, wrapper hash and selected operations in artifact provenance. Recompute digests from captured bytes; caller-supplied digest strings do not confer authority. Do not fetch or install dependencies while compiling; installation is an explicit package-manager operation.

The checked language constructs request data and consumes typed result data. A runtime interpreter performs selected requests. Checked specifications describe possible responses without asserting that a foreign implementation meets a postcondition. Behavioral verification requires an explicit relation and evidence; successful execution or a `.d.ts`/`.pyi` file is insufficient. Keep foreign execution out of definitional reduction and proof checking. The first implementation must demonstrate that the capability program and wrappers are admissible without adding unchecked logical constants; merely introducing an external-import IR record does not satisfy this requirement.

## Type and runtime policy

Initial values: Unit, Bool, scalar Unicode String, checked bounded integer conversions, exact Nat/Int encoded explicitly, and concrete immutable products/lists/options/results after marshalling is tested. Refuse arbitrary dependent types, proof values, open generics, raw pointers, borrowed references, implicit object identity and unserializable closures. A JavaScript `number` is not an exact Nat; a foreign integer needs a range check or exact representation. Copy mutable foreign collections into PSC persistent values. Validate all returned data before it reaches generated code.

Rust wrappers accept owned values or temporary borrows entirely inside the wrapper. No borrow may escape into PSC1; opaque resources use a target-owned handle with explicit lifetime/drop policy in a later extension. Do not attempt generic Rust trait or lifetime inference from source metadata. Native Rust crate calls through generated Rust wrappers do not require a C ABI; separate C/FFI adapters do.

Map declared foreign failures into a typed result. Keep runtime traps, invalid marshalling, cancellation and host failure distinct from source `Except` errors. Async operations, callbacks, reentrancy and cancellation require an explicit later protocol; never silently block or convert promises to synchronous results.

## Target adapters

| Target | Selected approach | Initial limitations |
| --- | --- | --- |
| JS/TS | ESM wrapper, explicit Node/browser environment and package subpath; CJS uses a wrapper selected under correct resolver conditions | `.d.ts` assists binding generation; it is not implementation or a semantic guarantee |
| Rust | Generated module/crate wrapper, exact Cargo manifest/lock and ordinary safe Rust API | Concrete owned types; traits/generics/borrows remain wrapper internals |
| Python | Explicit module/import-name mapping and wrapper; pinned distribution identity | Distribution name need not equal module name; `.pyi` only suggests types; no runtime introspection during compile |
| PHP | Composer-locked package plus generated wrapper and its autoloader | Class/method/static/function forms explicit; current export-map module is not itself PSR-4 class output |
| Wasm | Concrete WIT interface and qualified component adapter when available | Does not make an npm/Cargo/PyPI/Composer package portable automatically |

## Dependency-ordered implementation gates

I1: Introduce descriptor parsing/validation only. Accept an inert valid fixture; reject unsupported schema/target, ambiguous package, altered digest, private entry, unknown operation/type/effect and attempted logical authority. Preserve prior artifacts on every refusal.

I2: JS/TS synchronous vertical slice. One real local locked npm fixture, two concrete operations and typed failure. Execute generated JS and independently printed TS; include Unicode, very large exact values or checked range rejection, malformed return and effect ordering. Compilation must not execute the foreign package. Record lock/wrapper/runtime identities. Independently admit capability declarations without unchecked foreign axioms.

I3: Rust equivalent interface implementation. Cargo `--locked`; generated Rust executes the same request/result contract. Test owned strings/collections, failure, malformed conversion and absence of an adapter. No C ABI is needed for ordinary Rust crate calls.

I4: Python/PHP concrete adapters after I1-I3. Test package-to-module distinction, `.pyi` mismatch, exceptions, PHP autoload/class resolution and minimum supported interpreters. Refuse incompatible targets rather than silently replacing the dependency.

I5: Async/callback/resource handles only after explicit ownership, cancellation, scheduling and reentrancy tests. Automated bindings produce reviewable adapter drafts; unsupported type constructs are refused. Later behavioral contracts need separate evidence.

## Primary references checked 21 October 2026

- Node package exports/conditions: https://nodejs.org/api/packages.html . Package resolution distinguishes import/require and environment conditions; the compiler must retain that selection.
- npm lock identity: https://docs.npmjs.com/cli/v11/configuring-npm/package-lock-json/ . Record resolved entries and integrity, not a floating semver range alone.
- TypeScript declarations: https://www.typescriptlang.org/docs/handbook/2/type-declarations.html . Declarations contain type information and do not supply runtime implementation.
- Cargo lockfiles: https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html . Cargo owns exact resolved revisions; retain the generated lock.
- Rust borrowing: https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html . Keep native lifetime obligations inside wrappers.
- Rust foreign calls: https://doc.rust-lang.org/nomicon/ffi.html . Raw external declarations require correctly authored signatures and wrappers.
- Python stubs: https://typing.python.org/en/latest/spec/distributing.html . Stubs can be maintained separately from implementations.
- pip reproducibility: https://pip.pypa.io/en/stable/topics/secure-installs/ . For reproducible fixtures use pinned distributions with complete hashes.
- Composer: https://getcomposer.org/doc/01-basic-usage.md and https://getcomposer.org/doc/04-schema.md#psr-4 . Preserve lock identity and use the package's supported autoloader.

These sources establish ecosystem behavior. The PSC1 architecture choices above are engineering decisions inferred from that behavior and the inspected compiler boundaries.
