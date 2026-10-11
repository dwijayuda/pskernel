# PSCV0 v7: direct JavaScript, direct WebAssembly, and readable output

Architecture proposal · 12 October 2026 · Implementation stopped at native profile 31

## 1. Decision and completed milestone

Keep the existing portable semantic compiler, authored and executed natively in Lean. Add direct JavaScript through a shared ECMAScript lowering layer with TypeScript. Add direct WebAssembly through a separate typed Wasm lowering layer and binary writer. Retain Rust's target-specific ownership/layout work. Generate readable Lean and ProofScript from retained pre-erasure information.

This extends the previous codegen architecture rather than replacing the frontend, canonical Core, erasure, or checked runtime IR. New backends are **proposed, not implemented**. Full v7 remains incomplete.

The requested stopping milestone is complete: registered class output parameters, output-only universes, output-insensitive cycle detection, and shared dependency-ordered dictionary solving. The worklist replaces duplicated fixed-order solvers; candidate selection precedes output reconciliation. Scope and priority invariants remain intact.

[Qualified source 9c08a9a](https://github.com/dwijayuda/pskernel/commit/9c08a9a019b2afc2dc7eda15a0c6699832f2c688), [Linux run 38185022674](https://github.com/dwijayuda/pskernel/actions/runs/38185022674), job 114605381212, profile pscv0-v7-native-bounded/31:

| Evidence | Result |
|---|---|
| Native Lean | 4.35.0-rc4, pinned c29b6dda4f7c20e3eeaa717c4e565663c5cfa364 |
| Official kernel | 473 composite declarations admitted relative to the reconstructed portable prelude |
| Compact semantic validation | Four accepted programs; 92 phase-specific refusals |
| Existing checks | 28 parser cases plus focused IR/naming/origin/scope checks |
| Runtime comparison | 142 shared observations pass in strict TypeScript-to-JavaScript and Rust |
| Portable boundary | 121 portable / 127 native closure modules; pskernel-core excluded |
| Observed timing | Rebuild 59,973 ms; warm build 502 ms; application parse/elaborate/prepare/kernel/erase/IR-and-emit 48/64/79/53/71/22 ms |

These timings describe one cloud run, not a benchmark or a performance guarantee. No compiler-source migration or self-hosting was performed. The current JavaScript evidence uses TypeScript compilation; it does not qualify the proposed directJS backend.

## 2. Source audit and architectural gaps

The canonical [v7 language reference](https://github.com/dwijayuda/pskernel/blob/9c08a9a019b2afc2dc7eda15a0c6699832f2c688/psc0/PSCV0_LANGUAGE_REFERENCE.md) remains the language contract. Backend additions do not broaden source acceptance or relax verified-executable requirements.

The inspected path is source parsing and shared elaboration → prepared canonical Core → official checking → typed erasure → complete IR validation → selected backend. The host retains the exact prepared graph across checking and emission. The IR continuation requires both acceptance and complete traversal; a diagnostic report is not a reusable admission token.

| Current subsystem | Useful asset | General capability still needed |
|---|---|---|
| Codegen.Doc and Names | Compositional layout, readable semantic names, UTF-8 generated ranges | Stable symbol/occurrence identities, lexical naming, original source provenance |
| BackendTs.Readable | Structured declarations and runtime behavior | Expression/control/runtime strings must become structured ECMAScript nodes |
| BackendRust | Structured emission, recursive layout, lexical captures, liveness, persistent arrays | Keep these target decisions; improve presentation through shared provenance |
| Codegen.Artifact / native CLI | Portable emission record and host-owned file IO | Multiple text/binary files, dependencies, role-specific metadata |
| CompilerIr | Typed runtime operations and complete admission gate | Target capabilities, export ABI, explicit primitive semantic contracts |
| Syntax/source printers | Existing Lean/PS presentation assets | Complete selected-source coverage and checked reconstruction before erasure |

The central gap is structured information surviving to the right boundary. Adding more string rewrites would multiply the problem across JS, declarations, maps, and source reconstruction.

Audit locators: [native host](https://github.com/dwijayuda/pskernel/blob/9c08a9a019b2afc2dc7eda15a0c6699832f2c688/psc0/host/src/Ps/Host/NativeV7.lean), [TS readable emitter](https://github.com/dwijayuda/pskernel/blob/9c08a9a019b2afc2dc7eda15a0c6699832f2c688/psc0/packages/backend-ts/src/Ps/BackendTs/Readable.lean), [artifact model](https://github.com/dwijayuda/pskernel/blob/9c08a9a019b2afc2dc7eda15a0c6699832f2c688/psc0/packages/codegen/src/Ps/Codegen/Artifact.lean), [document printer](https://github.com/dwijayuda/pskernel/blob/9c08a9a019b2afc2dc7eda15a0c6699832f2c688/psc0/packages/codegen/src/Ps/Codegen/Doc.lean).

## 3. Verification boundary: a necessary correction

The official provider creates an empty Lean environment and replays the portable prelude. Definitions and inductives undergo kernel checking; portable axiom declarations become assumptions. It does **not** automatically compare every primitive signature with the imported native standard library. Earlier wording claiming such comparison was too strong. [Provider implementation](https://github.com/dwijayuda/pskernel/blob/9c08a9a019b2afc2dc7eda15a0c6699832f2c688/psc0/packages/pskernel-lean/provider/PsKernelLean/Prelude.lean).

The current conditional primitive signatures were studied against pinned RC4, but official admission alone does not establish their fidelity or the correctness of their runtime implementations. This includes the selected Decidable/ite/dite boundary. The distinction applies to existing primitives as well as recent additions.

Before qualifying additional backends, add one compact native prelude audit and a primitive/assumption ledger. Classify each entry as a checked definition, native-matched signature, explicitly modeled representation, or trusted runtime primitive. Compare types modulo binder names and declared universe correspondence; record intentional representation adaptations separately. Audit bodies/equations where reduction matters. A type match alone is insufficient for computational fidelity.

Keep four claims separate: source/Core checking; primitive and erasure assumptions; IR/target well-formedness; observed runtime agreement. None alone proves backend semantic preservation. The canonical distinction between ordinary checked output and verified executable output remains intact. This is an assurance prerequisite, not a request to redesign the kernel.

## 4. Pipeline and dependency ownership

```text
PS source (selected Lean adapter when qualified)
  → syntax + scopes + source provenance
  → shared elaboration
  → prepared Core → official Lean check
       ├─ retained source presentation → readable Lean / ProofScript
       └─ typed erasure → checked runtime IR
            ├─ ECMAScript plan → TypeScript
            │                  → JavaScript + declarations + source maps
            ├─ Rust layout / ownership → Rust
            └─ Wasm representation / closures → typed Wasm module
                                                   → binary + readable WAT
```

Provenance accompanies transformations as metadata. Source reconstruction cannot recover proofs or dependent types from erased runtime IR.

Suggested ownership, introduced only when the corresponding milestone needs it:

| Module family | Responsibility |
|---|---|
| Codegen.Bundle | Target-neutral file bundle, text/binary payloads, roles, dependency manifest |
| Codegen.Origin / Names / Doc | Source identities, target spelling, layout and render events |
| Codegen.ExportAbi / Capabilities | Public runtime surface and target support checks |
| BackendEcma | Shared JS/TS expression, statement, function, module and runtime plan |
| BackendJs / BackendTs | Small dialect printers and target entry points |
| BackendWasm | Representation, closure conversion, structured instructions, validation, binary and WAT |
| SourcePresentation | Retained source structure, controlled Core reification, Lean/PS printing |
| Host | Kernel service, file IO, CLI, diagnostics and external validation tools |

Share dependency SCCs and capture analysis only where their semantics are actually common. Rust ownership, Wasm storage and JavaScript call machinery remain separate. A universal low-level IR or a large plugin framework is unnecessary.

Portable modules must not import Lean's elaborator, a JS parser, LLVM, Rust tooling, or Wasm engines. Native host adapters may use official Lean and external qualification tools. This preserves the eventual portable compiler closure without beginning self-hosting now.

## 5. Artifact bundles, identity, and capabilities

Replace the single source-plus-runtime field with an ordered bundle of files. Each file has a relative path, role, media kind, text or bytes, optional provenance, and dependencies. The manifest records compiler/source identity, target profile, ABI version, required features, runtime dependency versions, and qualification status.

The host validates duplicate names and escaping paths before writing. Generate all requested targets successfully before publishing the bundle. Stage a versioned output directory and switch its entry reference where supported; do not claim arbitrary multi-file writes are atomic. Keep the existing CLI as a thin adapter during migration, then retire obsolete fields once both current targets use bundles.

Names are views of stable semantic identities. Use declaration identity plus lexical binder identity; generated spelling is never the identity. Allocate within actual target scopes, reserve runtime/import names, resolve collisions deterministically, and retain source/output mappings. Stable noncolliding names should survive unrelated edits. Namespace flattening must remain reversible through the manifest.

Capability checks run after common IR admission and before file publication. Distinguish an IR enum constructor from an implemented target feature. Record primitive support, effects/imports, machine word width, export shapes, and Wasm feature requirements. Unsupported cases receive explicit diagnostics rather than placeholder behavior.

## 6. Direct JavaScript and declarations

**Recommendation:** one structured ECMAScript plan, two printers. Lower the checked runtime IR once into expressions, statements, blocks, normal/generator functions, exports, and imports. Attach optional type nodes. The TS printer renders annotations; the JS printer omits them structurally. Move runtime helpers into the same representation or a small explicit portable runtime module.

Do not remove TypeScript syntax with regular expressions. Do not require tsc, Babel, esbuild, a Rust subprocess, or an external JS compiler to emit JavaScript. TypeScript remains a development validator and differential reference.

Initially preserve the existing generator trampoline and tail-loop behavior. Their evaluation order, lazy branches, and retained proof-argument Unit slots are semantic obligations. Improve helper names and layout first; remove wrappers only when an explicit call/effect analysis justifies it. Keep direct calls direct where the existing contract allows.

The initial target is ESM with an ES2020-or-later feature baseline for BigInt. Emit module.js, module.d.ts, module.js.map, and reachable runtime support with matching map/declaration files when imported by the module. Use explicit .js import specifiers. Document the required ESM package context; .js does not itself guarantee Node treats a file as ESM. Package creation is optional and must not overwrite a user's package metadata. [TypeScript module reference](https://www.typescriptlang.org/docs/handbook/modules/reference.html).

A single export ABI description drives wrappers and declarations. A .d.ts describes actual JavaScript values and calling conventions. It cannot restore erased theorems or imply a dependent guarantee that JavaScript does not enforce. Follow the runtime module's export structure. [TypeScript declaration guidance](https://www.typescriptlang.org/docs/handbook/declaration-files/templates/module-d-ts.html).

| Runtime category | Proposed JS/declaration surface |
|---|---|
| Nat / Int | bigint; Nat ingress validates nonnegativity |
| Bool / String / Char | boolean / string / string; Char ingress validates one admitted scalar |
| Unit and retained proof slots | undefined according to the actual call ABI |
| Data / classes | Named records or tagged unions; computational dictionary fields remain |
| Function values | Actual callable shape with represented generic parameters only |
| Persistent arrays | Readonly public view, with defensive conversion/ownership at foreign ingress |
| Unsupported machine/effect forms | Capability refusal until explicitly qualified |

Erased parameters do not become fake runtime arguments. Proof-erased APIs cannot promise a caller's proof precondition: mark them as an external trust boundary or generate checked wrappers only where an executable check is defined. Readonly TypeScript types alone do not protect against mutable JS aliases; constructors and public conversion routines must establish the runtime invariants.

Keep Nat saturation, division-by-zero behavior, signed arithmetic, Unicode scalar/UTF-8 operations and array persistence in a versioned runtime semantic contract. Raw JavaScript operators are used only when their semantics match. BigInt provides arbitrary-size integers, but this does not equate all of its operations to Lean's. [ECMAScript BigInt specification](https://tc39.es/ecma262/multipage/ecmascript-data-types-and-values.html#sec-ecmascript-language-types-bigint-type).

## 7. Real source maps

Current .origins.json files contain generated UTF-8 byte intervals associated with declarations. They are useful, but are not debugger source maps.

Add FileId, source spans, OriginId, and per-occurrence IDs at the syntax boundary. Transformations carry origin relations; generated helpers record their reason and originating construct. Do not key provenance solely by structurally equal Core terms, which may occur at different source locations. Keep metadata outside kernel expression equality and proof authority.

Extend render events to track generated line, UTF-16 column and UTF-8 byte offset. Preserve lexer byte positions and convert original coordinates through a source-file line index. Map meaningful expression/control boundaries, not only whole declarations. Synthetic code is left unmapped or deliberately anchored to its source construct; it must not pretend to be an unrelated token.

Pin the published ECMA-426 December 2024 baseline and document any later draft features selected. JS generated columns use UTF-16 code units; Wasm mappings use binary byte offsets on one generated line. Implement bounded Base64-VLQ deltas, deterministic source/name tables and correct line reset rules. Add sourceMappingURL links. [Published ECMA-426](https://ecma-international.org/wp-content/uploads/ECMA-426_1st_edition_december_2024.pdf), [working draft](https://tc39.es/ecma426/).

Generate mappings after final layout. External formatting or optimization must preserve/compose maps or invalidate them explicitly. Relative source paths are the default; embedding sourcesContent is an option. Runtime helper maps identify runtime sources, not user source. Declaration maps are optional and separate from the required JS map.

For Wasm, attach origin marks to instructions and resolve final offsets during encoding. Supply a name section and optional .wasm.map/sourceMappingURL custom section. Source maps and readable WAT aid inspection but do not promise identical debugger support across engines.

## 8. WebAssembly alternatives and recommendation

| Approach | Strength | Cost / limitation | Decision |
|---|---|---|---|
| Emit Rust, then rustc to Wasm | Reuses part of Rust codegen/runtime | External toolchain, extra compilation, Rust ABI/layout dependence; not direct emission | Retain only as a possible comparison |
| Direct linear-memory Wasm | Broad baseline engines, explicit layout | Allocator, ownership/RC or tracing, root/call conventions, teardown and alias discipline become compiler responsibilities | Defer unless compatibility requirements demand it |
| Direct Wasm GC | Typed structs/arrays and managed references fit data and closures; less memory-management code | Requires GC-capable engines; public ABI still needs adaptation | Recommended first directWasm profile |
| Wasm importing JS for all runtime primitives | Small initial runtime | Loses standalone behavior and makes crossings part of basic arithmetic | Not the portable default |

Wasm GC is an architectural size/maintenance recommendation, not a measured speed claim. V8's porting guidance supports using engine-managed data for managed languages; Hoot demonstrates a self-contained language-owned Wasm toolchain. Neither proves PSCV0 performance or qualifies this compiler. [V8 design discussion](https://v8.dev/blog/wasm-gc-porting), [Hoot project](https://spritely.institute/hoot/).

Pin an explicit GC/function-reference feature subset, not “latest Wasm.” The inspected core specification is labeled WebAssembly 3.0, 2026-10-09; the associated JS document is an editor's draft. Freeze the exact referenced revision and engine versions at implementation. Wasmtime lists GC and function references as Tier 1, with a Winch qualification exception. Start with a pinned Wasmtime Cranelift build and pinned Node/V8; do not claim all browsers or embedded engines. [Core types](https://webassembly.github.io/spec/core/syntax/types.html), [Wasmtime feature matrix](https://docs.wasmtime.dev/stability-wasm-proposals.html).

## 9. DirectWasm representation and runtime

Use checked runtime IR → representation/closure plan → typed structured Wasm module → binary writer. Print readable WAT from the same module. WAT assembly is not a mandatory compilation stage. Use structured blocks, loops and typed branches, with local assignment to preserve source evaluation order.

| Category | Initial representation decision |
|---|---|
| Bool, Char, supported fixed-width values | Typed scalar locals; validate narrowing and signedness |
| Nat / Int | Wasm-owned canonical sign/limb arithmetic over GC arrays; never substitute i64 for arbitrary precision |
| Strings | Owned UTF-8 data and scalar-aware helpers; preserve byte/scalar distinction |
| Nonrecursive and recursive data | Typed constructor records, explicit tags where needed, recursive type groups derived from dependency SCCs |
| Function values | Code reference plus captured environment; lifted entries take an explicit environment |
| Polymorphic runtime values | Uniform boxed representation at generic boundaries; typed concrete paths and bounded specialization |
| Persistent arrays | Correct immutable copy baseline; block/tree representation or reuse only after an explicit design and measurement |
| Proofs / Decidable | Existing erasure contract; retained call slots and Boolean decision representation remain uniform |

A generic value family can use eqref with explicit scalar/function boxes; function references themselves are not interchangeable with eqref. Define one checked boxing/unboxing convention, and normalize generic function signatures at their boundaries. Preserve declared type relationships and validate casts against the representation plan. Avoid unlimited monomorphization or inference based on generated names.

Begin bigint algorithms with canonical zero/sign/limb invariants and straightforward add/subtract/multiply/divide. A small-integer fast path can follow profiling. Keep division-by-zero and Nat subtraction policies identical across targets. Initial strings and bigint operations run inside Wasm without mandatory JavaScript semantic imports.

GC does not prove uniqueness. Never mutate a persistent array merely because it is GC-managed. Compiler-proven unshared construction may use private mutable buffers; exported or aliased values require immutable behavior. Copying is a correctness baseline, not the final high-performance array claim.

Lower known tail recursion to loops. General calls initially use the engine stack; tail-call instructions can be an explicitly qualified feature later. Resource exhaustion, deep non-tail recursion and allocation behavior remain measured limits. Correct successful results do not imply unbounded stack safety.

Use append-oriented buffers or a size pass for binary sections and LEB lengths. Assign indices deterministically, resolve relocations once, then finalize maps; avoid repeatedly inserting into a growing byte stream. Emit only reachable declarations and runtime helpers. The binary layout follows the pinned core format. [Wasm binary modules](https://webassembly.github.io/spec/core/binary/modules.html).

## 10. Wasm host ABI and packaging

Separate internal GC layout from exported host representation. Wasm i64 crosses the JS API as a 64-bit BigInt value; it is not PSCV0 Nat/Int. GC records are exposed as opaque host objects rather than ordinary JS records. Explicit conversion is required. [Wasm JS interface, work in progress](https://webassembly.github.io/spec/js-api/).

Propose two surfaces: a versioned core ABI with scalar operations and typed opaque values, plus an optional generated JS adapter with a friendly .d.ts. The adapter exposes an asynchronous instantiate operation followed by synchronous pure calls. It may marshal bigint limbs, UTF-8 bytes, arrays and records using generated constructors/accessors. A bounded scratch memory can support bulk transfer without becoming the language heap.

Opaque values belong to an instance; reject cross-instance mixing. Provide conversion, ownership/lifetime and error rules. Do not expose unstable internal field offsets or rely on JS object identity as language equality. Avoid permanent integer-handle tables where ordinary GC references suffice; if a host requires handles, make release and resource limits explicit.

An initial scalar-only backend is an honest intermediate capability, not completion. Generic public exports, callbacks, higher-order foreign values and effects must be implemented by a defined adapter or explicitly refused. Internal closures and dictionaries remain required for current-language parity. The pure core has no default WASI dependency. Components, foreign IO and asynchronous effects are future adapters under their own contracts.

## 11. Readable TypeScript, Rust, Lean, and ProofScript

Readable output is the default presentation mode. Preserve user declaration, binder and field names; use descriptive generated helpers; render structured multi-line bodies; respect operator precedence; emit shared helpers once; separate runtime support from user modules. Keep stable declaration ordering subject to dependency constraints, source-linked synthetic declarations, and anchored comments where they survive transformations.

TS/JS should show normal functions, loops, matches-as-control and small named helpers. Rust keeps its correct Rc, closure, borrow and clone decisions, displayed plainly rather than hidden by new abstractions. Parenthesis reduction and naming cleanup follow the structured plan, never text replacement.

For Lean/PS, retain a presentation model before preparation destroys useful source structure. It contains resolved declarations, binder groups, universes, visibility, source constructs and checked elaboration results. Prefer original high-level constructs when they still denote the checked result. Reify Core only for generated or transformed portions.

Reconstruction must account for implicit arguments, hygiene, dependent motives, proof terms, private helpers and qualified names. A generated proof may be large; organize it into named helpers rather than inserting sorry, opaque holes or unsupported tactics. Do not advertise arbitrary Lean-source decompilation.

Validate selected generated Lean with pinned official Lean and selected generated PS with the portable frontend, comparing canonical declarations/definitional meaning under an explicit name/environment correspondence. Exact text equality is not semantic equality; successful re-elaboration alone is not a proof that two different implementations are equivalent. Unsupported reconstruction receives a clear boundary diagnostic.

Source-output qualification is separate from translating the compiler itself. Keep native .lean authoritative until sufficient language support exists. Final readable compiler .ps migration and fixed-point/self-host qualification remain later, explicitly scheduled work.

## 12. Small validation surface, meaningful acceptance

Reuse the existing composite and 142 runtime observations. Add targets to that same observation matrix rather than duplicating language tests. Keep all current refusal outcomes and kernel/IR gates.

| Boundary | Focused validation |
|---|---|
| Shared ECMAScript migration | Existing TS build/runtime; direct JS agrees with the same observations |
| Declarations | One strict consumer exercises exported generics, data, callbacks and erased call conventions; selected type errors remain errors |
| Source maps | Independent decoder; mapped token checks after supplementary Unicode, line breaks, nested scopes and generated helpers |
| Wasm encoding | Independent wasm-tools validation; inspect readable WAT; execute the same applicable observations |
| Wasm parity milestone | All 142 current observations in both pinned engines, plus compact ABI/persistence/large-integer boundaries |
| Source reconstruction | Selected Lean/PS round trips, official checking, correspondence checks, no added proof assumptions |
| Trust boundary | Native prelude signature/model audit and explicit primitive/assumption closure |

wasm-tools provides independent validation and inspection in CI; it is not required by the Lean production emitter. [wasm-tools](https://github.com/bytecodealliance/wasm-tools).

Validation cannot replace a preservation proof. Record exact source, toolchain, target features and runtime dependencies for each qualification. Avoid enormous golden outputs and a second self-host test loop. Performance checks should separate native compile time, output size, engine startup, execution and allocation, using a small representative workload only when that performance decision is being made.

## 13. Implementation sequence after this report

The names below extend the earlier A/B milestones; they do not restart the architecture.

| Milestone | Concrete result and exit condition |
|---|---|
| C0 — contracts and provenance | Bundle model, stable identities, real spans, export ABI/capabilities, primitive ledger and native signature/model audit. Current TS/Rust behavior retained. |
| C1 — shared ECMAScript | Structured expressions/control/runtime replace active string paths; TS still passes the existing matrix. Remove replaced emitters after their callers migrate. |
| C2 — directJS | Real .js, .d.ts and .js.map bundle, optional separate runtime, independent declaration/map checks and all 142 runtime observations. No TS compiler in emission. |
| C3 — directWasm foundation | Typed module, direct binary/WAT, capability diagnostics and a deliberately bounded scalar profile validated independently. |
| C4 — current-language Wasm parity | GC data/closures, generic conventions, full current bigint/string/array semantics and host adapter; all 142 observations in two pinned engines. |
| C5 — readable source reconstruction | Complete selected Lean/PS presentation and checked correspondence; no compiler migration or self-hosting yet. |
| D — measured performance | Reachability, bounded specialization, allocation/call improvements and remaining Rust destruction work, each justified by measurements. |

C0 precedes both source maps and new backends. C1 precedes C2. C3/C4 must use C0 contracts, not invent another public ABI. C5 uses the same origin/name infrastructure but branches before erasure. Complete each acceptance boundary before adding broad optimization.

The most substantial cost is C4: arbitrary precision, generic closures, persistent data and host conversion. A binary encoder alone is a small part of a capable backend. DirectJS should be delivered first because it reuses the existing runtime model and immediately completes structured TS expression output.

## 14. Risks and limits to keep visible

GC engine support is a deliberate portability constraint. If a concrete deployment requires MVP-only or embedded Wasm, reevaluate the representation decision before C3; do not silently maintain two runtimes.

No performance winner has been measured. GC, boxed polymorphism, adapters, bigint arithmetic and array copying have different costs. Preserve a simple correct baseline, profile, then specialize at explicit boundaries.

Real maps require early source retention; comments cannot be recovered after discarding them. Source reconstruction requires richer information than executable emission. Treat these as information-flow requirements, not printer polish.

General modules/libraries, broader inference/recursion/control/effects, selected proof automation and VC generation still remain in the v7 roadmap. New backends do not make those features complete.

Implementation remains stopped at the qualified class-output milestone. The next proposed action is C0, followed by C1/C2; directWasm follows the same checked pipeline. No directJS/directWasm code, compiler-source .ps migration, self-hosting, merge or release is part of this report.
