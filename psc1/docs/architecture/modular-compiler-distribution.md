# Genuine modular generated compiler distribution

Decision, 2026-10-27: target real generated JS/TS modules grouped by source
responsibility for the final npm compiler distribution. Keep the current qualified
bundled executors as the release reference until the modular artifact graph has
its own genuine installed and self-host qualification. The bounded compiler-component pilot is now implemented and passes its dedicated
Linux gate at8473b22e2840f32543543f89ad238b3907b4e93c /40465513856.
[Current pilot guide](../guides/modular-pilot.md) gives exact scope, APIs, invariants,
resource limits and remaining work. Full compiler-family packaging and modular
self-host promotion remain future work. Broader source/integrated-gate validation
for this change is pending.

## Evidence behind the decision

The user-provided PSC0 archive has SHA256
946117f4416110aef3b1c0433f508f8bd37af169bba686847fdecc7139f8cd0e,
53,181,440 bytes. Inspection read its root and core/elab/compiler manifests,
the core/elab/erasure dist/index.mjs files, and member listings only; nothing from
the archive was installed or executed.

Its inspected core/elab/erasure runtime entries each export everything from
@proofscript/compiler. Their metadata declares shared-psc0-js-facade and
verifiedIndependentPackageCompilation:false. Core even depends on compiler,
which is a facade dependency rather than the desired semantic dependency direction.
The inspected package exports/main point at dist/index.js while their listed
facades are dist/index.mjs. A new installed gate must check every declared entry
exists. The archive is a useful layout example; its metadata does not establish
independent modular compilation. Its Lean4.34/default generated-core checking
choices are historical data. PSC1 retains official independent Lean4.35 admission.

Current PSC1 already owns cohesive source packages. Its
[compiler API](https://github.com/dwijayuda/pskernel/blob/91c5d898adea8e8d184b7927adf2ed988af8c2d8/psc1/packages/compiler/src/Ps/Compiler/Api.lean#L1)
composes syntax, checked-admissions encoding, environment, elaboration and erasure.
The current
[validated IR module](https://github.com/dwijayuda/pskernel/blob/91c5d898adea8e8d184b7927adf2ed988af8c2d8/psc1/packages/compiler-ir/src/Ps/CompilerIr/Model.lean#L242)
holds flat imports/structures/inductives/declarations. Existing imports are
external imports; they are not a validated generated module-ownership graph.
The
[JS stack-safe printer](https://github.com/dwijayuda/pskernel/blob/91c5d898adea8e8d184b7927adf2ed988af8c2d8/psc1/packages/backend-js/src/Ps/BackendJs/Print.lean#L2174)
and
[TS module emitter](https://github.com/dwijayuda/pskernel/blob/91c5d898adea8e8d184b7927adf2ed988af8c2d8/psc1/packages/backend-ts/src/Ps/BackendTs/Module.lean#L1154)
return one source module in the preserved bundled path. The additive Modules.lean
emitters now implement the bounded DAG pilot; general multi-file execution requires compiler-owned
partition/link output plus host graph validation/publication, not renamed folders.

## Recommended package shape

proofscript stays the convenient install/CLI/checked API. Cohesive source families
can become matching @proofscript/foundation, core, syntax, environment, meta,
elab, erasure, compiler-ir, compiler, backend-common and JS/TS/Rust/Wasm backend
packages where the measured runtime dependency graph supports those boundaries.
Use one exact release cohort initially; do not promise that incompatible Core,
elaborator and erasure versions can be mixed.

Each package contains its own real emitted modules, matching type declarations,
owned .lean/.ps sources and source maps/provenance, plus a small explicit entry.
For example, @proofscript/core/dist/js/Ps/Core/Expr.mjs owns Core Expr runtime
declarations; it does not re-export an entire compiler. JS/TS engine variants
must keep a consistent runtime/ABI cohort. Node/Bun should execute ordinary ESM;
readable generated TS and .d.mts declarations can accompany the emitted .mjs.
Do not require users to execute TypeScript or install a compiler SDK for the
default compiler. Keep internal file exports finite; package exports are API
organization, not an independent security boundary.

One npm package per source family, with multiple files inside, is preferable to
one npm package per Lean file. Source-level imports, runtime references and any
strongly connected declaration groups must be measured before final boundaries
are frozen. If a strongly connected runtime group crosses proposed package
boundaries, coalesce the generated unit or correct the boundary with evidence;
do not silently duplicate definitions or shared runtime state.

Rust should distribute readable generated crate/modules and an efficient compiled
native executable. Wasm should distribute source/name/provenance maps alongside
its qualified compiler GC artifact. Dynamic native/GC-Wasm splitting adds ABI,
linking and lifetime obligations and is not necessary merely to make source
readable. Their npm wrappers/providers stay separate optional execution packages.
Python/PHP remain optional. Kernel-Wasm stays genuine official C++/Emscripten
linear memory and does not become a compiler WasmGC module.

## Required compiler and host work

1. Derive a deterministic module/link plan from actual checked declaration
   origins and global runtime references after shared transforms. Retain whole
   original/transformed strict IR checking. Assign every surviving runtime
   declaration exactly once, including synthetic members with explicit owners.
   Detect unknown owners, duplicates, cycles/initialization hazards and name/path
   collisions. Source import graphs alone are navigation, not this proof.
2. Render JS/TS through the existing source-owned emitters and shared symbol
   plan. Add explicit import/export edges and matching declaration files.
   Preserve initializer order, closure behavior, mutual recursion, generated
   trampolines and one shared runtime/implementation registry per selected graph.
   A collection of facades or an unverified text splitter is not completion.
3. Introduce an explicit versioned multi-artifact service/manifest alongside
   existing strict single-file protocols. Hash every canonical relative path,
   byte sequence, dependency edge, package version, source closure and ABI/runtime
   cohort. Preserve aggregate response/input/fuel bounds; do not evade a current
   bound by applying it independently to arbitrarily many output files.
4. Validate the complete import/resource graph before executing or publishing
   it. Refuse escapes, missing/extra/changed files, symlinks, unknown imports,
   wrong cohorts and source/body mismatches. Package/module data cannot select
   a checker, SDK, arbitrary host module or publication capability.
5. Extend checked consumers, immutable-store inventory, staging/fsync and
   readPublication to complete bounded directory graphs. Publish one whole
   generation atomically; preserve rollback-before-commit and explicit
   committed-durability-uncertain behavior. Current flat-file publication is
   not automatically qualification for nested modules or another OS.
6. Exact source-preserving assembly should produce separate module tarballs
   plus an offline-installable umbrella ZIP with matching receipts. Optional
   bundles remain optional. No merge or registry publication without authorization.

## Finite acceptance before promotion

- A two-module producer/consumer pilot exercises exported values/types,
  constructor identity, higher-order calls and recursion in both grammars.
  Real package entries resolve under Node and Bun; declarations strict-check
  with actual NodeNext and bundler consumers. No core-to-compiler facade cycle.
- The modular self-host compiler actually compiles source through its separated
  modules. Compare real language/application/refusal corpora and all seven
  backend mappings with the preserved bundled reference. Kernel admission,
  strict IR and source/body identities remain mandatory.
- Tampered/missing/extra/duplicate modules, wrong package versions/runtime
  registries, cycles/TDZ hazards, paths/case collisions and interrupted publication
  fail closed and retain the previous complete generation.
- Cold/warm startup, wall time, peak memory and installed/tarball size are
  measured on real compiler workloads. Modularity alone proves no speed/size win.
- Final promotion requires genuine G1/G2/G3 execution and deterministic fixed
  points for the canonical complete module graph, with exact source identities.
  Old single-file fixed points remain historical evidence for their own files.
- Human comprehension remains a separate arranged maintainer trial. Source maps,
  package names, CI and generated declarations do not establish that result.

## References and remaining boundary

[Node package exports](https://nodejs.org/api/packages.html#package-entry-points)
support finite public interfaces but are not strong encapsulation.
[TypeScript module resolution](https://www.typescriptlang.org/docs/handbook/modules/reference)
and [compiler options](https://www.typescriptlang.org/docs/handbook/modules/guides/choosing-compiler-options)
require runtime and declaration entry points to agree.
[Rust crates/modules](https://doc.rust-lang.org/reference/crates-and-source-files.html)
support modular source within a compiled crate.

Implementation priority: integrate and qualify the bounded pilot alongside all
existing source regressions, then carry synthetic ownership and a measured complete
compiler graph into the next explicit profile. This document changes neither
current compiler semantics nor the frozen Practical Core language scope. There
is no claim of independently compiled complete PSC1 pass packages or modular
self-hosted compiler generations yet.

## License for the final cohort

All ProofScript-owned module packages and generated compiler components use
Apache-2.0 with LICENSE/NOTICE in each package. Dependencies retain their own
attribution. [Project licensing](../reference/licensing.md). The supplied archive
was inspected as data and remains unchanged.
