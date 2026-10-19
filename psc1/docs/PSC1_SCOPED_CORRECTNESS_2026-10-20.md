# PSC1 scoped correctness repair — qualified 2026-10-20

## Exact qualification

Implementation commit: `f933691a1d6fa578c59623636afbb02119909837`.
Branch: `fix/psc1-scoped-correctness-20261020`.

[Linux Actions run 39332460452](https://github.com/dwijayuda/pskernel/actions/runs/39332460452)
completed successfully on that exact implementation. Job `118333724117` passed all
steps. Qualification finished on October 20, 2026 at 05:08 Jakarta time.

The run contains:

- Native compiler and focused executable build: 233 Lake build jobs, success.
- Corrected PSKernel-Core native build: 163 Lake build jobs, success; 15 explicit
  kernel cache/scope/string/universe regressions passed. Build jobs are not tests.
- Host formatting, source-map, WIT and transaction unit tests: 14 passed.
- Scoped native VLQ/WIT/forged-IR assertions: 23 passed.
- Existing specialization, native source-map and independent Lean provider suites:
  all passed; their internal assertion counts are not added to the figures above.
- Source-to-backend integration groups: 24 passed, including 10 explicit refusals
  of unqualified scalar capabilities. They are not 24 supported language features.
- Additional source edge groups: 4 passed — imported generic specialization, exact
  Core/target symbol identity, empty public modules and non-tail Nat recursion at
  depth 100,000 in emitted DirectJS.

[Readable example/evidence artifact 12224164905](https://github.com/dwijayuda/pskernel/actions/runs/39332460452/artifacts/12224164905)
contains 35 files: actual generated JS, TS, declarations, source maps, Rust crate,
core/component Wasm, WAT, WIT, checked-source snapshots, manifests, dependency lock
and JSON test reports. Archive SHA-256:
`981902c3e3bbba31043e895042806b09e56ea92545bac883f5f8926837851b48`.

A later documentation-only commit does not change these tested implementation
bytes. Its own Actions status is separate from this exact qualification record.

## Scope and trust boundaries

The implementation is based on bounded hardening
`0fd7b9aa8bc2f51b21e0cd9477edde35063de0e4`, which integrated the corrected
PSKernel-Core source from the `0a53836489c4e88f46df8f5b8b0c19cc41bafbbb` lineage.
The repair preserves Lean 4.34.0, the existing source-language capabilities, kernel
fuel policy and negative checks. It adds no substantial language feature, unchecked
admission mode, full self-host suite or automatic npm publication.

The corrected **PSKernel-Core is integrated in source and regression-tested**.
The **independent official Lean 4.34.0 kernel is the current direct-output admission
provider**. This does not claim that PSKernel-Core is already the default direct
provider or that either source checker proves backend semantic preservation.

## Checked output architecture

```text
captured dependency-ordered source bytes and parsed syntax
  -> existing resolver/elaborator
  -> exact immutable canonical declaration graph
  -> independent official Lean 4.34.0 kernel admission
  -> erasure of that same accepted graph
  -> bounded typed-IR validation
  -> entry public API resolved through erasure's collision-aware Core-name map
  -> checked target plan:
       JS/TS: one closed specialized IR, input/output rechecked
       Rust: existing checked generic IR, target validation
       Wasm: existing checked target specialization and lowering
  -> privately linked dependencies and selected public exports
  -> target printing/checking and readable formatting
  -> final-layout source maps where applicable
  -> complete checksummed staged generation
  -> one atomic current-pointer replacement
```

Each source file is read once into a captured immutable closure. No target or
source-map phase rereads source after admission. Canonical paths, cycle detection
and dependency-order elaboration are retained. This is not a claim that every file
was atomically observed at one instant on a locked filesystem.

Public JS signatures are generated from the same revalidated specialized plan as
JS implementation output. Internal generic helpers can specialize without being
exported or causing every raw generic declaration to fail `.d.ts` generation.
The existing scalar ECMAScript public ABI remains explicit and is not imposed on
Rust or core Wasm. Rust public named-type closure is retained so hiding imported
value helpers does not accidentally hide types used by a public signature.

## Readable outputs

JS and TS builds use locked Prettier 3.6.2 and Babel parser 7.28.0. Formatting is
accepted only when parsed syntax trees match after excluding parser metadata.
Formatting is not an optimization or a proof of generated-program equivalence to
source. Readable indentation and stable target names are retained; no minification
is used. Maps observe the final formatted AST, all captured source texts, UTF-16
columns, correct negative VLQ deltas and explicit generated-only boundaries.
Mapping granularity is declaration-level, not expression-level.

Actual JS identity output from the qualified artifact:

```javascript
export function idNat(x) {
  return x;
}
```

Actual TS identity output:

```typescript
export function idNat(x: bigint): bigint {
  while (true) {
    return x;
  }
}
```

The current TS printer retains a loop scaffold; removing it is a separate lowering
optimization, not silently claimed by formatting. `build --target ts` is the
qualified formatted artifact path. The `typescript` stdout convenience command
still uses the native TS printer directly, without the artifact formatter.

Rust is formatted with rustfmt and ships a sibling `.cargo` directory containing
Cargo.toml, Cargo.lock and src/lib.rs. The standalone `.rs` and crate source are
identical. Direct dependency versions are exact (`num-bigint=0.4.6`,
`num-traits=0.2.19`); each produced bundle retains its resolved transitive lock and
passes `cargo check --locked`. This does not assert future registry resolutions
will produce the same transitive lock without reusing that lockfile.

Actual Rust identity output:

```rust
pub fn idNat(x: PsNat) -> PsNat {
    (x).clone()
}
```

WIT is indented source. Its complete bounded ABI is compared structurally with the
observed component, not by searching for an export-name substring. WAT is generated
by printing the actual final binary with wasm-tools; core and component WAT both
passed binary roundtrip and runtime checks.

Actual WIT output:

```wit
package proofscript:psc1;

world app {
  export answer: func() -> bool;
}
```

## Important scalar correction

The historical WIT type table represented fixed-width integers and floats, but the
active typed-IR checker explicitly reports `scalar-capability-unqualified` for
those types. The first expanded runtime test exposed that false advertisement.
The repair does **not** remove the validator guard or activate new scalar features.
WIT selection now consults the same active capability policy.

The current component scalar API is **Bool only**. Bool values, parameters and
multiple-argument ordering execute in Wasmtime. All ten formerly advertised
integer/float source cases now have explicit negative tests requiring rejection
and absence of official artifact files. Nat/Int/String/aggregate component adapters
are still unsupported. See `profile.json` for the explicit active profile.

## Transaction contract

Each output owns a hidden store next to its requested filename:

```text
.module.js.psc1/
  generations/<content hash>/
    module.js
    module.d.ts
    module.js.map
    admissions.json
    psc1-input.json
    manifest.json
  current -> generations/<content hash>
module.js -> .module.js.psc1/current/module.js
module.d.ts -> .module.js.psc1/current/module.d.ts
module.js.map -> .module.js.psc1/current/module.js.map
module.js.bundle.json -> .module.js.psc1/current/manifest.json
```

Every bundle is fully prepared and checked before publication. Four injected
failure points and a real compiler replacement regression confirm that failure
before the commit point leaves the previous accepted generation intact. A first
failed build can leave managed dangling aliases or private stages, not a partially
accepted generation. Stale stages do not block subsequent builds.

The commit point is one atomic pointer replacement, **per target bundle**. Readers
requiring a consistent multi-file read should resolve the immutable generation once
and read within it; separate alias opens across a concurrent replacement can see
different complete generations. No global multi-target transaction or proven
power-failure durability is claimed. Linux is the qualified publication platform.
Old generations are retained; automatic collection is separate work.

Existing ordinary files and foreign symlinks are refused rather than overwritten.
Use new output locations when migrating legacy flat output. Give JS and TS separate
directories when they share a stem because both own a `.d.ts` companion path.

Manifests bind captured sources, admissions and artifact hashes. They are not
signed proof certificates authenticating arbitrary callers of the host I/O helper.
Normal trusted native emission reaches the helper through the checked session.

## Native/npm command identity and usage

Both `npm-cli/psc.js` and the root `packages/cli/bin/psc.mjs` launcher invoke the
same identity-checked native executable. No fallback to archived generated PSC0
compiler/kernel artifacts is permitted. The private stdlib source workspace has a
distinct npm identity, fixing the copied duplicate-workspace install failure.

From `psc1/`, with Node 22+, the pinned native compiler, Rust/cargo/rustfmt and the
qualified wasm-tools available:

```sh
npm --prefix "$PWD/host-tools" --workspaces=false ci --ignore-scripts
export PSC1_NATIVE="$PWD/.lake/build/bin/psc1"
export PSC1_HOST_TOOLS="$PWD/host-tools/artifacts.mjs"

node npm-cli/psc.js build example.lean --target js --out dist/js/example.js
node npm-cli/psc.js build example.lean --target ts --out dist/ts/example.ts
node npm-cli/psc.js build example.lean --target rust --out dist/rust/example.rs
node npm-cli/psc.js build example.lean --target wasm-core --out dist/wasm/example.wasm
node npm-cli/psc.js build boolean.lean --target wasm-component --export answer --out dist/component/answer.wasm
```

The core compiler and kernel remain Lean implementations. Babel/Prettier are
disclosed host formatting/observation tools; the Node helper also owns filesystem
publication and external target-tool invocation, not proof checking or elaboration.
Platform-native npm distribution and public package publication remain unqualified.
Historical release files are preserved as history, not relabeled current products.

## Audit disposition and honest remaining work

The scoped repair closes the demonstrated current-output defects in independent
admission, integrating the corrected kernel source, mandatory specialization
revalidation, entry export selection, implementation/declaration consistency,
captured source provenance, final-layout maps/VLQ, JS stack-safe printer selection,
partial publication, missing Rust build contract, WIT signature/capability checking,
native/npm command routing, and scoped CI coverage.

It does not claim every long-term architectural ambition is complete:

- Source modules are still linked into a whole-program backend unit. Correct export
  visibility is repaired, but full separate/incremental compilation is not added.
- Runtime prelude extraction/tree-shaking and artifact-size optimization remain.
- More structured target diagnostics are still possible; some target errors retain
  a phase-level refusal rather than a complete source-span diagnostic.
- Formal specialization/backend preservation, full kernel equivalence, broad
  language conformance and expression-level source maps remain separate claims.
- Native platform/npm distribution, optional scalar activation, owned-kernel default
  provider integration and full self-host qualification are not asserted here.

All new verification was GitHub/Linux cloud execution. No full compiler/kernel
self-generation, self-host census or fixed-point suite was run for this repair.
