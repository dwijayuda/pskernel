# PSCV0 v7: directJS, WIT/WAT/Wasm, and readable output

Current implementation audit, 13 October 2026: C0–C4b are qualified for the
selected native runtime; directWasm is implemented, despite proposal-era wording
below. C5 has bounded historical printer assets but full native reconstruction
is missing. [Current audit](PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md) integrates retention into M2–M4 and final
C5 correspondence into M5/E; no replacement backend sequence is introduced.

Architecture proposal, revision 2 · 12 October 2026 · Research baseline: native profile 31; C0–C4b implementation update: profile 35 (see §16 and PSCV0_NATIVE_CODEGEN.md)

## 1. Decision and completed milestone

Keep the existing portable semantic compiler, authored and executed natively in Lean. Add direct JavaScript through a shared ECMAScript lowering layer with TypeScript. Add direct WebAssembly through a typed Wasm lowering layer, Canonical ABI adapters, and a component writer. Generate WIT from a checked public interface schema and WAT from the same module/component structure used by the binary writer. Retain Rust's ownership/layout work. Generate readable Lean and ProofScript from retained pre-erasure information.

The main refinement to the previous proposal is that the requested .wit/.wat/.wasm bundle should describe and implement a real component interface. Placing WIT next to an unrelated core module is insufficient. Core Wasm remains available as an explicit target and development milestone. Internal Wasm GC data and external linear-memory ABI conversion have separate responsibilities.

Research baseline: Component Model repository commit 6c48079bbc808bb3bdeb9554f338ab3a5b187388 (7 October 2026), with only a selected synchronous, memory32, UTF-8 subset. Its binary format remains pre-standard; gated features are not implicitly admitted. This plan does not rely on proposed GC Canonical ABI extensions. [Pinned component binary design](https://github.com/WebAssembly/component-model/blob/6c48079bbc808bb3bdeb9554f338ab3a5b187388/design/mvp/Binary.md), [GC ABI proposal](https://github.com/WebAssembly/component-model/issues/525).

This extends the previous codegen architecture rather than replacing the frontend, canonical Core, erasure, or checked runtime IR. This document preserves the researched design. C0–C2 were subsequently implemented and qualified; directWasm and source reconstruction remain proposed. Full v7 remains incomplete.

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
            └─ Wasm representation / closures → typed core module
                    + checked public API → WIT + Canonical ABI adapters
                    → component plan → binary .wasm + readable .wat
                    → optional standalone .core.wasm / .core.wat
```

Provenance accompanies transformations as metadata. Source reconstruction cannot recover proofs or dependent types from erased runtime IR.

Suggested ownership, introduced only when the corresponding milestone needs it:

| Module family | Responsibility |
|---|---|
| Codegen.Bundle | Target-neutral file bundle, text/binary payloads, roles, dependency manifest |
| Codegen.Origin / Names / Doc | Source identities, target spelling, layout and render events |
| Interop.Api / Codegen.Capabilities | Checked logical public API, export selection and target representability |
| Interop.Wit / BackendWasm.CanonicalAbi | WIT schema/printing and the corresponding memory/call/lifetime ABI plan |
| BackendEcma | Shared JS/TS expression, statement, function, module and runtime plan |
| BackendJs / BackendTs | Small dialect printers and target entry points |
| BackendWasm.Core / Component | Representation, closures, structured instructions, component wiring, validation, binary and WAT |
| SourcePresentation | Retained source structure, controlled Core reification, Lean/PS printing |
| Host | Kernel service, file IO, CLI, diagnostics and external validation tools |

The logical public API schema connects checked declarations to their erased runtime implementations. Target ABI plans then choose JS objects, Rust values, or WIT value/resource encodings. Do not force all targets through WIT's restrictions, derive WIT from JavaScript spelling, or reconstruct public types from arbitrary binary instructions. Verify every exported wrapper against its actual runtime declaration.

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

A JavaScript ABI view of the checked public API drives wrappers and declarations. A .d.ts describes actual JavaScript values and calling conventions. It cannot restore erased theorems or imply a dependent guarantee that JavaScript does not enforce. Follow the runtime module's export structure. [TypeScript declaration guidance](https://www.typescriptlang.org/docs/handbook/declaration-files/templates/module-d-ts.html).

| Runtime category | Proposed JS/declaration surface |
|---|---|
| Nat / Int | bigint; Nat ingress validates nonnegativity |
| Bool / String / Char | boolean / string / string; Char ingress validates one admitted scalar |
| Unit and retained proof slots | undefined according to the actual call ABI |
| Data / classes | Named records or tagged unions; computational dictionary fields remain |
| Function values | Actual callable shape with represented generic parameters only |
| Persistent arrays | Readonly public view, with defensive conversion/ownership at foreign ingress |
| Unsupported machine/effect forms | Capability refusal until explicitly qualified |

Erased parameters do not become fake runtime arguments. The safe foreign interface refuses uncheckable proof preconditions. Where an executable check is defined, an adapter can validate the precondition before calling the internal erased function. An explicitly selected trusted interface may expose additional operations, but its assumption ledger must say so; .d.ts or WIT types alone cannot authorize fabricated proofs. Readonly TypeScript types alone do not protect against mutable JS aliases; constructors and public conversion routines must establish the runtime invariants.

Keep Nat saturation, division-by-zero behavior, signed arithmetic, Unicode scalar/UTF-8 operations and array persistence in a versioned runtime semantic contract. Raw JavaScript operators are used only when their semantics match. BigInt provides arbitrary-size integers, but this does not equate all of its operations to Lean's. [ECMAScript BigInt specification](https://tc39.es/ecma262/multipage/ecmascript-data-types-and-values.html#sec-ecmascript-language-types-bigint-type).

## 7. Real source maps

Current .origins.json files contain generated UTF-8 byte intervals associated with declarations. They are useful, but are not debugger source maps.

Add FileId, source spans, OriginId, and per-occurrence IDs at the syntax boundary. Transformations carry origin relations; generated helpers record their reason and originating construct. Do not key provenance solely by structurally equal Core terms, which may occur at different source locations. Keep metadata outside kernel expression equality and proof authority.

Extend render events to track generated line, UTF-16 column and UTF-8 byte offset. Preserve lexer byte positions and convert original coordinates through a source-file line index. Map meaningful expression/control boundaries, not only whole declarations. Synthetic code is left unmapped or deliberately anchored to its source construct; it must not pretend to be an unrelated token.

Pin the published ECMA-426 December 2024 baseline and document any later draft features selected. JS generated columns use UTF-16 code units; Wasm mappings use binary byte offsets on one generated line. Implement bounded Base64-VLQ deltas, deterministic source/name tables and correct line reset rules. Add sourceMappingURL links. [Published ECMA-426](https://ecma-international.org/wp-content/uploads/ECMA-426_1st_edition_december_2024.pdf), [working draft](https://tc39.es/ecma426/).

Generate mappings after final layout. External formatting or optimization must preserve/compose maps or invalidate them explicitly. Relative source paths are the default; embedding sourcesContent is an option. Runtime helper maps identify runtime sources, not user source. Declaration maps are optional and separate from the required JS map.

For Wasm, attach origin marks to instructions and resolve final offsets during encoding. Supply core name metadata and optional core .wasm.map/sourceMappingURL custom sections. Embedded core-module offsets and outer component offsets are distinct: retain module identity and the embedding relation in the manifest, and qualify debugger conventions before advertising component maps. Do not apply an arbitrary outer-file offset to a core map. Source maps and readable WAT aid inspection but do not promise identical debugger support across engines. WIT and WAT also receive generated-text origin ranges; those are not advertised as a standardized WIT debugger-map format.

## 8. WebAssembly alternatives and recommendation

| Approach | Strength | Cost / limitation | Decision |
|---|---|---|---|
| Emit Rust, then rustc to Wasm | Reuses part of Rust codegen/runtime | External toolchain, extra compilation, Rust ABI/layout dependence; not direct emission | Retain only as a possible comparison |
| Direct linear-memory Wasm | Broad baseline engines, explicit layout | Allocator, ownership/RC or tracing, root/call conventions, teardown and alias discipline become compiler responsibilities | Defer unless compatibility requirements demand it |
| Direct Wasm GC plus Canonical ABI adapter | Typed structs/arrays and managed references fit data and closures; public components remain interoperable | Requires GC-capable engines and a small linear-memory marshalling allocator | Recommended internal runtime and component boundary |
| Wasm importing JS for all runtime primitives | Small initial runtime | Loses standalone behavior and makes crossings part of basic arithmetic | Not the portable default |

Wasm GC is an architectural size/maintenance recommendation, not a measured speed claim. V8's porting guidance supports using engine-managed data for managed languages; Hoot demonstrates a self-contained language-owned Wasm toolchain. Neither proves PSCV0 performance or qualifies this compiler. [V8 design discussion](https://v8.dev/blog/wasm-gc-porting), [Hoot project](https://spritely.institute/hoot/).

Pin an explicit GC/function-reference feature subset, not “latest Wasm.” The inspected core specification is labeled WebAssembly 3.0, 2026-10-09; the associated JS document is an editor's draft. Freeze the exact referenced revision and engine versions at implementation. Wasmtime lists GC and function references as Tier 1, with a Winch qualification exception. Qualify the core runtime in pinned Wasmtime Cranelift and Node/V8. Qualify components separately in a pinned component-capable Wasmtime host. Core-engine compatibility does not establish component-loader compatibility; do not claim all browsers or embedded engines. [Core types](https://webassembly.github.io/spec/core/syntax/types.html), [Wasmtime feature matrix](https://docs.wasmtime.dev/stability-wasm-proposals.html).

## 9. DirectWasm representation and runtime

Use checked runtime IR → representation/closure plan → typed structured core Wasm module → binary writer. Add the component layer over this same module and a checked ABI plan. Print readable core/component WAT from the respective structures. Neither WAT nor WIT reparsing is a mandatory compilation stage. Use structured blocks, loops and typed branches, with local assignment to preserve source evaluation order.

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

## 10. WIT: a deliberate public contract

WIT describes component interfaces/worlds, not executable behavior. Its named data definitions are not user-generic, and value-type definitions cannot be recursive. Resources express owned/borrowed handles. Therefore, a fully capable internal language does not imply that every source type can cross a WIT boundary unchanged. [WIT overview](https://component-model.bytecodealliance.org/design/wit.html), [pinned WIT specification](https://github.com/WebAssembly/component-model/blob/6c48079bbc808bb3bdeb9554f338ab3a5b187388/design/mvp/WIT.md).

Introduce an explicit export-root manifest for foreign APIs, without adding new v7 grammar. Preserve the source module's own visibility rules. Each selected export must have a representable signature and implementation; reject unsupported selected exports rather than silently dropping them. Concrete specialization applies only to selected foreign signatures, with a bounded budget and stable names.

| PSCV0 category | Proposed WIT contract and policy |
|---|---|
| Bool, Unicode Char/String | bool, char, string; choose UTF-8 canonical encoding |
| Qualified fixed-width scalars | Corresponding signed/unsigned/float types only when semantics are qualified |
| Nat | A named natural record containing little-endian list<u32> limbs; arbitrary precision within resource limits |
| Int | Sign plus natural magnitude; normalize negative zero |
| Nonrecursive records / inductives | Named records / variants after concrete type substitution and proof-field erasure |
| Option / Except / product / arrays | option / result / tuple / list with explicit element conversion |
| Source List | Finite list conversion where semantics match; sharing is not part of the public value contract |
| General recursive data | Explicit opaque resource API or user-selected finite view; no recursive WIT type |
| Generic public functions | Concrete export instantiations; no invented WIT type variables |
| Closures / dictionaries | Internal by default; explicit resource methods or selected concrete operations at the boundary |
| Dependent invariants / proofs | Checked external validation where defined; otherwise refuse safe foreign export |
| USize/ISize, effects, imported callbacks | Explicit target policy and assurance classification before support |

For natural limbs, accept all finite input lists and normalize redundant leading zero limbs. Emit canonical zero as an empty list. This avoids a hidden invariant that WIT cannot express. Integer input normalizes negative zero. The public limb format is independent of internal bigint storage, so a later small-integer fast path does not change the interface.

Illustrative WIT presentation, not generated or qualified output:

```wit
package pscv0:example@0.1.0;

interface arithmetic {
    /// Little-endian base-2^32 limbs; zero is an empty list.
    record natural {
        limbs: list<u32>,
    }

    add: func(left: natural, right: natural) -> natural;
}

world example {
    export arithmetic;
}
```

Preserve meaningful source names using deterministic kebab-case allocation, keyword escaping and a reverse identity map. Group types and operations by source API, not by codegen pass. Public WIT names are versioned ABI identities: a rename, type change or ownership change requires explicit compatibility review. The private helper naming policy must not rename public interfaces.

Avoid opaque resources for every small value: records/lists are easy to consume and inspect. Use resources for recursive, identity-bearing or deliberately persistent objects where behavior matters more than copying representation. Persistent resources may expose an explicit clone/share operation returning a new owned handle to the same immutable value. This is an API operation, not implicit copying of an owned handle.

## 11. Canonical ABI and GC runtime integration

A component embeds core modules and uses canonical lift/lower adapters for its public functions. The selected ABI uses linear memory, flattening and memory/reallocation/post-return options. GC-native canonical conversion is a separate proposal, so it is not a foundation for this compiler. [Component explainer](https://github.com/WebAssembly/component-model/blob/6c48079bbc808bb3bdeb9554f338ab3a5b187388/design/mvp/Explainer.md), [Canonical ABI](https://github.com/WebAssembly/component-model/blob/6c48079bbc808bb3bdeb9554f338ab3a5b187388/design/mvp/CanonicalABI.md), [GC ABI proposal](https://github.com/WebAssembly/component-model/issues/525).

Recommended split: language values live in the GC heap; public strings, lists and structured values cross a dedicated memory32 ABI area. Generated adapters convert between them. The ABI buffer is not a second general-purpose language heap.

One CanonicalAbiPlan computes layouts, alignment, checked size arithmetic, scalar flattening, indirect arguments/results, string encoding, cleanup actions and resource operations. Both the core adapter functions and component wiring consume that plan. Follow the pinned rules for the chosen lift/lower direction; a generic “all results use a pointer” shortcut would be wrong.

Implement a small reusable allocator with the required realloc behavior and explicit allocation ownership. Input conversion may release transferred buffers once copied according to the ABI. Exported results remain live until post-return cleanup. Nested aggregate cleanup follows the plan. Do not reset an arena at ordinary function return while a caller still needs the result; do not retain every call's buffers for the instance lifetime. Reentry, imports and callbacks require a defined call/lifetime protocol before they are admitted.

GC-managed resources need a component-owned root table: the resource representation identifies a live GC object, and its destructor releases that root. Keep runtime canonical handles distinct from guest representation IDs and from internal pointers. Do not retain a borrowed handle beyond its allowed call. Make cross-instance identity, ownership transfer, drops and stale-reference behavior explicit. Shared immutable payloads may survive while another owned root remains.

Bounds, alignment, UTF-8/scalar validity, variant discriminants and numeric narrowing are ABI correctness obligations. Treat malformed boundary data and resource exhaustion according to the selected contract; do not silently turn every trap into a source Except result. Domain errors remain typed result values where the source API specifies them.

The first component profile is synchronous and pure, with no implicit WASI imports. Source effects and foreign callbacks require modelled imports and assurance classification. Async components, threads, memory64 and GC-native Canonical ABI can be added as versioned capabilities later, without changing source/Core semantics.

The principal extra cost compared with the earlier core-only plan is real: a component encoder, ABI adapters, marshalling allocator and resource lifecycle. GC still avoids a custom collector for the language heap, but does not eliminate boundary allocation or copying.

## 12. Exact artifacts, WAT readability, and hosts

| Target/profile | Required outputs | Meaning |
|---|---|---|
| directJS | module.js, module.d.ts, module.js.map; reachable runtime companions | Native Lean emits JavaScript directly |
| directWasm component | module.wit, module.wat, module.wasm; manifest | WIT and component binary describe the same selected world; WAT is its readable text form |
| Explicit core-Wasm target | module.core.wat, module.core.wasm; manifest and optional JS adapter | Standalone core module; no claim of component interoperability |
| TypeScript / Rust | module.ts / module.rs and required runtime files | Existing peers, with shared readable presentation infrastructure |
| Lean / ProofScript | module.lean / module.ps and provenance | Selected checked source reconstruction before erasure |

The requested directWasm bundle is complete only at the component milestone. A scalar core prototype is an intermediate result, not a substitute. The manifest identifies core versus component kind; do not infer it from the .wasm extension.

Use a small ComponentPlan with explicit type/index spaces, embedded core modules, instances, aliases, canonical operations, imports and exports. Its binary encoder and WAT printer share those identities. Generate WIT and component type declarations from one interface schema, then independently compare the emitted binary's extracted interface with that schema.

Emit structured component WAT with readable embedded core modules, not a giant escaped module-byte blob. Use source-derived function/local/type/field labels, meaningful branch labels, multi-line instruction blocks and named ABI helpers. Preserve every instruction and constant: readable WAT must remain complete and assemblable. Example of the intended core presentation:

```wat
(module
  (func $both (export "both")
    (param $left i32)
    (param $right i32)
    (result i32)
    local.get $left
    local.get $right
    i32.and
  )
)
```

This illustrative helper assumes normalized Boolean operands; the actual public adapter establishes that condition. WAT is a faithful low-level view, not an attempt to recreate high-level source semantics. Source references connect it to readable Lean/PS and the original input.

Allocate separate core and component indices from stable IDs; debug labels never drive linking. Emit only reachable runtime/ABI helpers. A size pass or buffered sections resolve lengths and offsets without repeated global byte insertion. Standard name metadata and the origin manifest preserve names through independent binary inspection. Embedded-module provenance remains separate from outer component offsets.

Implement both encoders in portable .lean. No rustc, clang, LLVM, WAT assembler, WIT parser, jco or wasm-tools subprocess is required for production emission. Those tools may serve as independent development validators.

Use Wasmtime's component host for component qualification. Use Node/V8 and Wasmtime for the extracted standalone core profile. Browser/Node component consumption needs a separately qualified adapter/tooling route; it is not implied by WebAssembly.instantiate support for core modules. jco demonstrates such a transpilation route and is useful as a reference, not a mandatory compiler dependency. [Wasmtime support matrix](https://docs.wasmtime.dev/stability-wasm-proposals.html), [jco transpilation](https://bytecodealliance.github.io/jco/transpiling.html).

An optional generated browser adapter should consume the same ABI plan and the standalone core artifact. It exposes async instantiation followed by sync pure calls, and may present Nat/Int as JS bigint. It must implement the planned marshalling/cleanup rather than rely on GC objects behaving like JS records. Arbitrary component loading is not a new compiler responsibility.

## 13. Readable output across all seven text formats

Readable output is the default presentation mode. Preserve user declaration, binder and field names; use descriptive generated helpers; render structured multi-line bodies; respect operator precedence; emit shared helpers once; separate runtime support from user modules. Keep stable declaration ordering subject to dependency constraints, source-linked synthetic declarations, and anchored comments where they survive transformations.

WIT should show only the selected public contract, organized into meaningful interfaces and worlds. WAT should show named modules/components, complete structured instructions and clearly separated ABI helpers. Use the same symbol/provenance service, with grammar-specific escaping and naming; no one printer attempts to make all languages look identical.

TS/JS should show normal functions, loops, matches-as-control and small named helpers. Rust keeps its correct Rc, closure, borrow and clone decisions, displayed plainly rather than hidden by new abstractions. Parenthesis reduction and naming cleanup follow the structured plan, never text replacement.

For Lean/PS, retain a presentation model before preparation destroys useful source structure. It contains resolved declarations, binder groups, universes, visibility, source constructs and checked elaboration results. Prefer original high-level constructs when they still denote the checked result. Reify Core only for generated or transformed portions.

Reconstruction must account for implicit arguments, hygiene, dependent motives, proof terms, private helpers and qualified names. A generated proof may be large; organize it into named helpers rather than inserting sorry, opaque holes or unsupported tactics. Do not advertise arbitrary Lean-source decompilation.

Validate selected generated Lean with pinned official Lean and selected generated PS with the portable frontend, comparing canonical declarations/definitional meaning under an explicit name/environment correspondence. Exact text equality is not semantic equality; successful re-elaboration alone is not a proof that two different implementations are equivalent. Unsupported reconstruction receives a clear boundary diagnostic.

Source-output qualification is separate from translating the compiler itself. Keep native .lean authoritative until sufficient language support exists. Final readable compiler .ps migration and fixed-point/self-host qualification remain later, explicitly scheduled work.

## 14. Small validation surface, meaningful acceptance

Reuse the existing composite and 142 runtime observations. Add targets to that same observation matrix rather than duplicating language tests. Keep all current refusal outcomes and kernel/IR gates.

| Boundary | Focused validation |
|---|---|
| Shared ECMAScript migration | Existing TS build/runtime; direct JS agrees with the same observations |
| Declarations | One strict consumer exercises exported generics, data, callbacks and erased call conventions; selected type errors remain errors |
| Source maps | Independent decoder; mapped token checks after supplementary Unicode, line breaks, nested scopes and generated helpers |
| Wasm encoding | Independent wasm-tools validation; inspect readable WAT; execute the same applicable observations |
| Core Wasm parity | All 142 current observations in pinned Node/V8 and Wasmtime, plus compact persistence/large-integer boundaries |
| Component / WIT | Independent WIT parse, component validation, extracted-world equivalence, and all observations through component wrappers in pinned Wasmtime |
| WAT correspondence | Independently reassemble core/component WAT and compare decoded semantic structure, allowing only specified debug-metadata differences |
| ABI lifecycle | Compact repeated-call allocation, aggregate/Unicode conversion, output cleanup and owned/borrowed resource checks where those capabilities are exposed |
| Source reconstruction | Selected Lean/PS round trips, official checking, correspondence checks, no added proof assumptions |
| Trust boundary | Native prelude signature/model audit and explicit primitive/assumption closure |

wasm-tools supplies an independent WIT parser, component/core validator, WAT assembler and interface extraction route in CI; it is not required by the Lean production emitter. A custom-world component requires a small embedding harness rather than assuming the WASI CLI run command can invoke arbitrary exports. Reuse observation definitions and assert wrapper results, not just extracted type names. [wasm-tools](https://github.com/bytecodealliance/wasm-tools).

Validation cannot replace a preservation proof. Record exact source, toolchain, target features and runtime dependencies for each qualification. Avoid enormous golden outputs and a second self-host test loop. Performance checks should separate native compile time, output size, engine startup, execution and allocation, using a small representative workload only when that performance decision is being made.

## 15. Implementation sequence after this report

The names below extend the earlier A/B milestones; they do not restart the architecture.

| Milestone | Concrete result and exit condition |
|---|---|
| C0 — contracts and provenance | Bundle model, stable identities, real spans, checked public API/capabilities, export selection and WIT representability, primitive ledger and native signature/model audit. Current TS/Rust behavior retained. |
| C1 — shared ECMAScript | Structured expressions/control/runtime replace active string paths; TS still passes the existing matrix. Remove replaced emitters after their callers migrate. |
| C2 — directJS | Real .js, .d.ts and .js.map bundle, optional separate runtime, independent declaration/map checks and all 142 runtime observations. No TS compiler in emission. |
| C3 — directWasm foundation | Typed core module, direct binary/readable WAT, capability diagnostics and a bounded scalar profile. Prove one small GC-containing module can be embedded/lifted by the pinned component toolchain before scaling the runtime. |
| C4 — current-language core parity | GC data/closures, generic conventions, full current bigint/string/array semantics; all 142 observations in two pinned core engines. |
| C4b — WIT/component completion | WIT printer, Canonical ABI plan/adapters, component binary/WAT, allocator/lifetime/resource rules. Extracted world matches the declared contract; all observations pass through component exports. This completes the requested .wit/.wat/.wasm bundle for the qualified public profile. |
| C5 — readable source reconstruction | Complete selected Lean/PS presentation and checked correspondence; no compiler migration or self-hosting yet. |
| D — measured performance | Reachability, bounded specialization, allocation/call improvements and remaining Rust destruction work, each justified by measurements. |

C0 precedes both source maps and new backends. C1 precedes C2. C3/C4/C4b must use C0 contracts, not invent another public ABI. C4b makes components part of the requested work; it supersedes the previous proposal's deferral of components. C5 uses the same origin/name infrastructure but branches before erasure. Complete each acceptance boundary before adding broad optimization.

The most substantial costs are C4/C4b: arbitrary precision, generic closures, persistent data, Canonical ABI marshalling and component/resource lifetimes. A binary encoder alone is a small part of a capable backend. DirectJS should be delivered first because it reuses the existing runtime model and immediately completes structured TS expression output.

## 16. Risks and limits to keep visible

GC engine support is a deliberate portability constraint. If a concrete deployment requires MVP-only or embedded Wasm, reevaluate the representation decision before C3; do not silently maintain two runtimes.

WIT cannot express arbitrary dependent, generic or recursive source types. Explicit concrete exports and resource/view adapters keep this foreign-interface limitation from contaminating internal language capability. Component binary/tooling revisions must be pinned; experimental features do not become defaults through an upstream update.

No performance winner has been measured. GC, boxed polymorphism, adapters, bigint arithmetic and array copying have different costs. Preserve a simple correct baseline, profile, then specialize at explicit boundaries.

Real maps require early source retention; comments cannot be recovered after discarding them. Source reconstruction requires richer information than executable emission. Treat these as information-flow requirements, not printer polish.

General modules/libraries, broader inference/recursion/control/effects, selected proof automation and VC generation still remain in the v7 roadmap. New backends do not make those features complete.

Implementation update (12 October 2026): the user subsequently authorized C0–C2.
The native implementation now has artifact/API contracts, reviewed primitive
signatures, shared ECMAScript lowering and direct .js/.d.ts/.js.map output.
Source-map precision is explicitly owning-declaration spans; generated members
retain parent attribution, and runtime helpers stay unmapped. See
PSCV0_NATIVE_CODEGEN.md and AI_WORK_STATE.md for implementation and qualification.
The user subsequently authorized C3 through C4b and selected option A:
GC for language values, linear memory only at explicit Canonical ABI boundaries.
C3/C4/C4b are now qualified for current-runtime parity and the synchronous pure
public profile. The .wit/.wat/.wasm component bundle includes real aggregate
marshalling, an exported interface instance and post-return cleanup. No resources,
callbacks or effect imports are exposed; recursive/dependent/proof-bearing
foreign construction requires explicit view/resource/validating APIs.
See PSCV0_NATIVE_WASM.md and AI_WORK_STATE.md for exact evidence and boundaries.
C5, full v7, compiler-source migration and self-hosting remain separate.
