# Fully modular executable compiler plan

Decision date: 2026-10-28 (Asia/Jakarta).
Status: **planned; not implemented or qualified by this document**.

Keep `proofscript` as the installation umbrella and `psc` as its thin CLI command.
Gradually make executable packages follow their existing source responsibilities.
Defer further development and expansion of the experimental modular pilot.

This is the current production-modularity plan. The
[development roadmap](../PSC1_DEVELOPMENT_ROADMAP.md) remains the authoritative
overall remaining-work queue. Earlier [distribution research](modular-compiler-distribution.md)
and [pilot/provenance documentation](transform-provenance.md) remain historical
references and evidence, not prerequisites or production release contracts.

## 1. What is preserved and what changes

The qualified .13 distribution remains the usable reference until its replacement
passes the applicable production gates. PR #198 HEAD
ee9220e20e6b9fa202693c8226815a780cc5bbc0 preserves automatic installation of 20 core
packages, the checked API, thin command launcher, optional providers and the
qualified bundled compiler. Its exact scope is in the
[umbrella receipt](../PSC1_NPM_UMBRELLA_QUALIFICATION_2026-10-27.json).

That distribution has npm package interfaces; most compiler execution still takes
place in whole-compiler JS/TS bundles. Installing a package is not evidence that
its source has an independently executing implementation.

The target is ordinary ESM modules with actual generated bodies and real imports.
A package may contain several files. A type-only module need not invent executable
functions. Small public barrels and compatibility wrappers are acceptable when
they lead to the actual owned implementation; facades over a hidden full compiler
do not satisfy executable modularity.

Retain existing package names and `psc1/packages/` directories. Do not add one npm
package per Lean file, invent new package families, duplicate the compiler, or
bulk-translate/rewrite .lean sources. Use the same frontend, elaborator, Core,
erasure, IR validation, transforms and JS/TS emitters.

## 2. User experience

The intended registry experience stays:

```sh
npm install proofscript
npx --no-install psc --help
```

Global CLI installation remains supported. Before authorized registry publication,
deliver an offline-installable root tarball and ZIP with the exact matching core
dependencies. One root installation must be sufficient; users should not manually
install a pile of internal packages to obtain normal checking and compilation.

Preserve public checked entry points such as:

```js
import {compile} from 'proofscript';
import {compile as compileJs} from 'proofscript/backend-js';
```

Do not rely on npm hoisting. Document stable root subpaths and direct package APIs.
Python/PHP remain explicit optional packages. Missing optional engines, SDKs or
ABIs must refuse rather than silently substitute a tool or download one.

## 3. Target responsibility boundaries

| Existing package | Intended responsibility |
| --- | --- |
| proofscript | Installation umbrella, stable checked API/subpaths, command registration and compatible cohort selection. |
| @proofscript/cli | Arguments, help, project/file capture, diagnostics presentation, watch coordination and calls into the checked host API. |
| @proofscript/compiler | Compiler pipeline orchestration and checked host integration; compose the lower packages through explicit interfaces. |
| @proofscript/syntax | Shared .lean/.ps lexical, parser and syntax operations. |
| @proofscript/core | Core representations and their actual supported operations. |
| @proofscript/environment, meta, elab | Their existing environment, inference and elaboration responsibilities. |
| @proofscript/erasure | Existing Core-to-runtime erasure. |
| @proofscript/compiler-ir | IR representations, validation and shared transforms. |
| @proofscript/backend-common | Lower-level backend contracts and shared emission support. |
| @proofscript/backend-js, backend-ts, backend-rust, backend-wasm | Actual source-owned target implementations, not complete compiler copies. |
| @proofscript/foundation | Existing portable helpers and a suitable leaf home for shared generated runtime support, subject to dependency verification. |
| @proofscript/bridge | Existing serialization, canonical admission/transport data and lower-level boundary contracts. |
| @proofscript/bootstrap | Bootstrap/reproduction tooling using the same compiler source; no second compiler implementation. |
| @proofscript/stdlib | Existing language library sources and generated artifacts where they are actually supported. |
| @proofscript/pskernel-lean-wasm, pskernel-lean | Genuine independent checkers behind the existing host boundary. |
| @proofscript/backend-python, backend-php | Optional emit-only providers under the existing contracts. |

PSKernel-Core research retains its independent scope and status. Installing its
package must not select it as an officially qualified replacement checker.

The command may be only a few lines delegating to @proofscript/cli. A short
launcher alone does not establish compiler modularity: parser, elaborator,
transforms and emitters must actually execute through their generated modules.

## 4. Dependency direction and source cleanup

This is a target dependency direction, not a claim about today's manifests:

```text
proofscript -> cli -> compiler orchestration
                        -> syntax / environment / meta / elab / core
                        -> erasure / compiler-ir
                        -> backend implementations

backend implementations -> compiler-ir / backend-common / foundation
shared lower-level packages -> lower-level packages only
checked host -> independent kernel provider
```

No lower package may depend on the umbrella or CLI. Backends must not import the
compiler orchestrator merely to obtain error types, transport records or emission
helpers. Dependencies declared in package.json must match the real interfaces and
generated import graph; include runtime, type-only and peer edges in the audit.

Existing source boundaries need a small, deliberate cleanup before they can be
treated as package boundaries. For example, backend service modules currently use
helpers from Compiler.Service. Having compiler orchestration import those backends
would create a package return edge if the current files were packaged unchanged.

Move only the shared lower-level contracts into the appropriate existing bridge
or backend-common owner. Preserve bodies and logical names first, then update
imports and qualify the new source identity. Keep frontend orchestration in the
compiler package. Make each move independently reviewable.

Do not hide a cycle with undeclared imports, an upward filesystem search, optional
peer back-edges, or a process-global compiler singleton. Explicit host-owned tool
providers remain possible under a documented resource contract, but must not be
used to disguise missing ordinary package dependencies.

The .13 lower-package ./compiler aliases and checked backend facades require an
explicit compatibility review: importing checked orchestration from a lower package
can reintroduce cycles. Keep checked convenience wrappers at the umbrella/host
layer. Version and document any direct low-level API transition; do not silently
change a checked API into an unchecked emitter.

## 5. Generate modules from compiler data

Build a deterministic production module/link plan from captured declaration
origins and actual references after the existing transforms. Source imports alone
are navigation data, not the final executable dependency graph.

Assign every surviving value exactly once, including specializations and workers.
Carry explicit parent ownership through transforms rather than decoding generated
names. Recheck original and transformed IR. Keep generated helper names internal
unless an intentional public API requires them.

Emit actual source-owned function bodies and imports using the existing structured
JS/TS emitters. Multiple files within a package are normal. For example, the target
layout may have:

```text
packages/elab/
  src/Ps/Elab/...
  dist/js/Ps/Elab/...
  dist/ts/Ps/Elab/...
  package.json
  README.md
```

This is illustrative; exact file extensions and exported subpaths follow the
validated build and existing Node ESM conventions.

Build the complete checked source closure when whole-program specialization needs
it, then place the resulting bodies by verified ownership. Physical package
separation does not imply that every source file can already be compiled alone.
Derive rebuild/caching dependencies from actual inputs and generated references;
do not promise arbitrary incremental compilation before it is tested.

Use one shared runtime and nominal/tag registry per selected JS/TS execution graph.
JS and TS runtime representations can differ; mixing incompatible graph variants
must refuse. Shared runtime support may live in a leaf submodule of an existing
package; it need not create another npm name. Verify that the chosen owner remains
a leaf rather than forcing a new dependency cycle.

Handle type-only/erased sources honestly. Handle recursive declaration groups and
initialization order explicitly: preserve a necessary group in one generated unit,
or correct the source/package boundary. Do not duplicate definitions, invent empty
runtime implementations, or merge most of the compiler into one file and call
that source-responsible packaging.

Emit accurate declarations and readable generated TS. Generated TS source maps may
map emitted JS back to generated TS. Original Lean/PS locations require actual
captured provenance; do not fabricate source maps.

## 6. Integrity, checking and resources

Retain official Lean 4.35.0 admission, commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/transformed IR validation,
source/logical-body pairing, semantic fuel, memory/stack/lifetime policies, negative
tests and explicit ABI refusals. The default kernel remains genuine official C++
compiled with Emscripten to linear-memory Wasm; compiler Wasm retains its own GC
architecture. Do not rewrite a kernel for packaging.

Use a versioned production artifact manifest that binds the exact source closure,
module paths/bytes, dependency edges, package versions, engine/runtime cohort,
entry points and resource hashes. Validate the complete graph before import or
publication. User source, project configuration and package metadata cannot choose
a checker, arbitrary executable, SDK or publication capability.

Define finite aggregate bounds and exact failure behavior before adding the new
production format. Retain existing 240-second compiler/tool requests and 120-second
checking policies; do not quietly multiply resource allowances by the number of
files. Any separately bounded build stage needs an explicit total budget and
evidence. Existing pilot limits remain unchanged and are not the release
architecture for a complete compiler.

Publish a complete coherent graph as one immutable generation. Pre-commit failure
retains the previous generation; post-commit durability uncertainty must be reported
truthfully. A flat-file publication result does not qualify nested graph publication
or another platform. State the trusted-bootstrap/stable-files assumptions; package
exports and hash inventories are not a sandbox or a semantic-preservation proof.

## 7. Migration queue and exit criteria

Do not resume pilot expansion as a dependency for these stages.

| Stage | Coherent work | Exit evidence |
| --- | --- | --- |
| M0: architecture and contract | Record the full source/package/API graph and source identity; specify the production manifest, bounds, public compatibility and finite CI acceptance. | Reviewed ownership/API inventory; every package edge explained; no unsupported qualification claim. |
| M1: lower-level ownership | Compile a real production dependency slice into its existing owners; move only misplaced shared contracts needed to keep direction acyclic. | Actual bodies/imports/declarations; independent admission and strict IR; exact reference comparison; negative/cohort/runtime-identity tests. A slice is not a complete compiler. |
| M2: complete compiler graph | Extend the same mechanism to the complete chosen compiler source closure, including all synthetic values, types, recursion and initialization rules. | Actual whole-compiler capture/transform/emission; every surviving value owned once; dependency/byte inventories; JS/TS type and loader checks. |
| M3: checked compiler execution | Execute that complete graph as the compiler for real .lean/.ps programs and retained language/application corpora. | Independent checking, strict IR, representative seven-backend parity/refusals and comparisons with the qualified bundled reference. |
| M4: toolchain integration | Wire the thin psc CLI and root umbrella to the qualified graph with optional providers and source packages. | Root-only offline local/global install; check/build/watch; usable outputs; complete dependency resolution; no unnecessary full compiler copies or installation hooks. |
| M5: reproduction and release qualification | Reproduce the packages and qualify the finalized modular compiler generations. | Deterministic complete graph/cohort, exact source/admission/IR identities, genuine separate JS/TS G1/G2/G3 and fixed-point evidence when claiming self-hosted release qualification; applicable platform/publication gates. |

A checked developer preview can report the exact M2/M3/M4 scope it passes, but may
not call itself a fully qualified modular self-hosted release. Keep the bundled
reference usable until the replacement meets its stated promotion criteria.

G1/G2/G3 receipts for the frozen bundled compiler stay attached to their original
source/executable identities. Do not inherit them after a source move or module
layout change. Preserve separate correctness and original 240-second performance
profiles. Do not make expensive unchanged self-host runs a prerequisite for
ordinary documentation, language or backend development.

## 8. Finite production acceptance

Before production promotion, CI must demonstrate all applicable items:

1. Every advertised export and required dependency resolves after fresh root-only
   installation, including global CLI use; optional Python/PHP remain absent.
2. Every executable component contains its actual generated owned bodies. There
   is no hidden whole-compiler fallback in normal modular mode.
3. All original/specialized/worker values have unique ownership; nominal identity,
   closures, trampolines, recursion and initializer order remain correct.
4. Both source grammars execute through the complete JS and TS compiler graphs.
   Supported Node/Bun consumers and accurate NodeNext/bundler declarations pass.
5. Existing Practical Core criteria, independent kernel positives/negatives,
   strict IR, seven-backend mappings, resource limits and unsupported-ABI refusals
   remain covered at the appropriate scope.
6. CLI check/build/watch and representative CLI, JSON/file, multi-module and
   compiler-like applications behave consistently with the reference.
7. Missing, extra, altered, incompatible, duplicate or wrongly owned modules;
   wrong engine cohorts; unsafe paths/symlinks; and initialization hazards refuse
   before unchecked graph execution or publication.
8. Complete graph publication has tested pre/post-commit outcomes. Other-platform
   durability is separately qualified rather than inferred from Linux.
9. Exact tarball/graph reproduction, source mappings and notices are retained.
   Measure startup, real compilation time, peak memory and installed size; file
   splitting alone is not evidence of a performance improvement.
10. A release claiming modular self-hosting has genuine generation/fixed-point
    evidence for that complete graph. A source count, manifest, component example
    or successful npm install cannot substitute for it.

Independent human comprehension remains the user-arranged maintainer trial, not a
CI result.

## 9. Deferred and preserved work

The qualified v1/v2 pilot is retained as reference/regression evidence. Its
experimental npm names, fixture-size limits and profile versions are not adopted
as the production package architecture. Existing tests are not disabled or deleted.

PR #203 and branches feat/psc1-real-modular-compiler-20261028 and
feat/psc1-real-modular-build-20261028 retain the stopped prototype. The latter
checkpoint is 10b1dea50217036171654b46076183b7257d13f0. Do not promote it, resume its
experimental pipeline, or infer a complete modular release from intermediate
emission. Inspect it later only for reusable, reviewed mechanisms.

Rust/Wasm execution engines may continue shipping linked native/Wasm artifacts
with readable source modules and provenance. Dynamic native/Wasm code splitting
is not required for JS/TS package modularity. Preserve all existing backend
functionality and explicit platform restrictions. Python/PHP remain optional.

Owned sources/packages remain Apache-2.0; retain qualified-input and upstream
notices. No merge, npm publication or replacement of qualified .13 artifacts is
authorized by this planning document.
