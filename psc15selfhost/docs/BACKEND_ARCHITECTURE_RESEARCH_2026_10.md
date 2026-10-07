# Backend architecture research — 2026-10-07

Scope: compiler implementation only on `pscv/v3-execution`. Kernel implementation, provider internals and kernel proofs belong to the separate kernel workstream. Implementation availability is distinct from preservation evidence, promotion and final V3 acceptance.

## Existing architecture and invariant

Production authority begins with a live CheckedCore/CertifiedSource session. Erasure produces strictly validated target-neutral IR; specialization produces a distinct capability. Direct JS and Wasm lower once, validate and retain the exact target IR, then print/encode that same value. Target representation choices stay inside the backend. Host archives and EvidenceEnvelope retain exact identities and explicit assumptions.

## Reference designs

The current TypeScript source was studied at commit [d61a7d2](https://github.com/microsoft/TypeScript/tree/d61a7d235906e78be9b111de0ba060e28e67ecfa). Its native implementation separates transformation, emission and buffered text writing. The [text writer](https://github.com/microsoft/TypeScript/blob/d61a7d235906e78be9b111de0ba060e28e67ecfa/tsc/internal/printer/textwriter.go) uses a builder and keeps source-map column accounting separate from storage position. Its [scanner](https://github.com/microsoft/TypeScript/blob/d61a7d235906e78be9b111de0ba060e28e67ecfa/tsc/internal/scanner/scanner.go) uses source byte positions and decodes Unicode at the cursor. These are design references, not dependencies or a reason to replace PSC1 portability with Go APIs.

The [WebAssembly Core 3.0 validation algorithm](https://webassembly.github.io/spec/core/appendix/algorithm.html), dated 2026-10-03, tracks operand types, control frames, unreachable-stack behavior and local initialization. PSCV's current WasmIR structural checks do not implement all those obligations. Engine validation is useful evidence but neither a proof of lowering preservation nor a replacement for an explicit target profile.

## Selected text writer design

Repeated immutable concatenation of a declaration with the entire remaining module copies increasingly large suffixes. Introduce a portable binary carry forest of immutable string chunks. Higher occupied levels contain older chunks; a carry combines older before newer. Finalization visits older levels first. Structural recursion and typed worker continuations follow PSC1-portable-selfhost/1.

A common forward declaration worker accepts the ordinary or stack-safe declaration printer. It returns the first error without visiting later declarations and finishes accumulated text once. Empty fragments still participate in separator placement. No output syntax or target IR changes are intended.

This design bounds a fragment's merge participation by the number of carry levels. It is an algorithmic design argument, not a checked complexity theorem or a measured whole-compiler speedup. Focused cloud tests compare joins against Lean's independent intercalation, exercise carry boundaries and Unicode, and lock declaration/diagnostic order.

## Wasm representation implementation

At 59ef0e0, cloud generation 2 spends most observed time in source parsing. The runtime stores scalar arrays while portable cursor positions count UTF-8 bytes; cursor operations repeatedly scan prefixes. The selected next representation is immutable UTF-8 byte storage with cached scalar length and bounded decoding at the requested byte position. Packed GC arrays are internal construction storage.

Preserve invalid-position behavior, large Nat offsets before narrowing, Unicode scalar validity and overflow outcomes. Host source marshalling must finish a private scalar builder into copied immutable string storage so later builder mutation cannot alter compiler input. Literal construction, append, extract and every direct representation consumer must move together.

## Remaining implementation and assurance

Complete the Wasm runtime representation, then full profile-aware target typing and explicit target ABI adapters. Keep the Component Model/Canonical ABI distinct from core Wasm and private bootstrap marshalling. Continue archive replay, comparator and FactoryBench integration from the machine-readable ledger. Expensive global proofs and campaigns remain deferred; no global erasure/specialization/backend theorem, direct-JS promotion, B9/B10 or final acceptance is asserted here.

## Transferred implementation checkpoint

The selected UTF-8 representation and private builder/finish ABI are now implemented together. The byte array is not exported; finishing copies scalar-builder contents, so subsequent host writes cannot alter a source string. The scalar count is established by constructors rather than accepted as host metadata. Literal emission keeps bounded byte chunks. Cursor defaults remain get='A' and next=position+1 for invalid positions; extract requires a valid start and retains suffix behavior for a nonboundary end.

Alternatives rejected: a global cursor cache introduces ownership/eviction concerns; a per-string offset table adds storage and lookup costs; a new scanner primitive enlarges the portable primitive surface. The chosen representation matches existing UTF-8 cursor semantics. Remaining concatenation, Nat and persistent-collection costs require independent diagnosis after cloud measurement.

The focused Wasm fixture executes emitted bytes and uses an independent JavaScript Unicode/UTF-8 reference for offsets and extraction, including oversized Nat inputs and builder aliasing. Earlier local observations are not transferred as cloud success. Cloud portable round-trip and whole-compiler integration remain required; structural WasmIR validation still does not establish full Wasm typing or source preservation.

## Target typing design

The represented Wasm profile now has two validation layers: structural context checks and an independent operand/control interpreter. The public entry point composes them before encoding the retained target IR. Instructions consume and produce types rather than runtime values. Control frames preserve the outer operand sequence and local-initialization baseline; branches cannot consume outer operands, and unreachability does not excuse concrete type mismatches.

The encoder uses non-null concrete GC references and nullable abstract funcref. Consequently, GC locals require definite initialization and GC arrays cannot default-initialize non-defaultable elements. Structure inheritance follows declared earlier non-final parents and immutable field-prefix covariance. Packed loads, mutable stores/copies, declared function references, call signatures and final results have separate rules.

The profile deliberately uses exact named function-reference identity and exact tail-result sequences. It does not claim arbitrary recursive-type equivalence or completeness for all Core Wasm. No new target representation is introduced. Typed validation, translation preservation, binary encoding correctness and external engine acceptance remain distinct claims. See contracts/target/WASM_IR_VALIDATION_V1.json for scope and pending assurance.


## Own data properties across the JavaScript paths

ECMAScript's [object initializer evaluation](https://tc39.es/ecma262/multipage/ecmascript-language-expressions.html#sec-object-initializer-runtime-semantics-propertydefinitionevaluation) treats a non-computed "__proto__" key as a prototype setter even when quoted. A scalar value creates no field; an object value changes the prototype. Neither behavior represents a ProofScript field.

Both direct-JS printer modes now emit all source data fields with computed string keys. The TypeScript emitter uses the same rule for records, constructor payload fields and constructor-table entries, including nullary constructors. This preserves left-to-right value evaluation and ordinary own-property descriptors without filtering valid names, changing object prototypes or adding runtime helpers. Compiler-owned tag/brand keys retain their existing layouts.

The shared validated fixture is emitted through ordinary JS, stack-safe JS and TS-to-tsc. Runtime checks assert independently expected own properties, prototype identity, record projection, constructor matching and single ordered callback evaluation. Backend agreement alone is insufficient because both emitters previously shared the same semantic error. Source preservation remains unproved.

Canonical target archive decoding separately rejects noncanonical numeric text and negative Nat indices while preserving arbitrary precision decimal strings. Decoding establishes schema/encoding validity; it does not imply target typing, source authority or semantic equivalence.


## Component Model boundary and synchronous Canonical ABI planning

Research pin: [Component Model Canonical ABI a25fc0b](https://github.com/WebAssembly/component-model/blob/a25fc0b372dd21f07f0242c46e98bd0f1ea0c0e1/design/mvp/CanonicalABI.md). This is a Component Model design revision, separate from the Core Wasm specification and the compiler's private GC bootstrap ABI.

A pure InterfaceIR planner now computes memory32/memory64 sizes, alignments, record offsets, variant discriminants/payload placement and synchronous lift/lower core signatures. It retains exact flat arities and at most 17 flat slots: this suffices to apply the pinned 16-parameter and one-result thresholds without constructing huge flat lists. Overflowing types are rejected using the required memory64 element-size bound, even when selected memory uses 32-bit pointers. Shared named layouts are resolved once in dependency order.

Imported functions use canon-lower conventions; exported functions use canon-lift conventions. An indirect result becomes an extra pointer parameter on lower, but a pointer result on lift. Owned and borrowed resources produce handle-table obligations, not raw integer authority. The existing policy still rejects borrowed returns/nested borrows; the new profile also rejects async/future/stream planning.

The planner provides data for later adapters. It does not perform memory reads/writes, allocation, string transcoding, post-return cleanup, resource-table operations or component binary generation. Those operations must follow the selected value and ownership contract; reusing the internal GC representation as a Canonical ABI representation would be unsound.

Foreign structural validation and Canonical ABI planning now share cached dependency/depth analysis. Each accepted definition body has a summarized maximum type depth, and named uses account for that depth without unfolding shared bodies. The same graph orders layout computation. This preserves valid acyclic depth thresholds and rejects unsupported borrow/async forms, missing names and cycles. Bounded topological passes and list lookup avoid exponential expansion, but do not establish a global resource theorem or constant/linear-time complexity. Multiple-error inputs may select a different first diagnostic.


## Canonical memory value runtime

The first actual-memory layer is `scripts/canonical-memory.mjs`, under `psc-canonical-memory-sync-utf8/1`. It pins exact InterfaceIR bytes, derives bounded named layouts, checks the memory64 size limit and operates on caller-selected Wasm memory. Synchronous memory32/memory64 scalar, record, tuple, enum/variant, option/result, list and UTF-8 values are supported. Its independent layout summaries are compared with the portable planner, including offsets, flat prefixes and pointer-width differences.

The pinned reference requires nonzero Boolean bytes to lift as true, integer loads/stores to use little-endian signedness, Unicode scalar validation, strict UTF-8, aligned/bounded ranges and dynamic list/string size checks. The runtime preserves a leading U+FEFF instead of treating it as a transport BOM and writes deterministic canonical NaN bits. It refreshes memory views after allocator calls, because growth can detach the previous buffer.

Before stores, a bounded snapshot validates input shapes and own data properties; invalid input does not call realloc or write memory. Allocator failures after this point can leave writes and allocations. Realloc is an explicit trusted capability required to provide owned, disjoint regions, with its returned range checked again after possible memory growth. Shared memory, resource handles, borrowed values and asynchronous values fail closed. Proxy behavior and host allocator effects are not a sandbox boundary.

This layer does not bind foreign functions, flatten core call values, execute canon-lift/canon-lower state transitions, perform post-return cleanup or emit components. Those operations remain separate implementation obligations; no layout or memory round trip establishes global adapter preservation.


## Core-value conversion and indirect transport

`psc-canonical-core-values-sync-utf8/1` adds direct and indirect value transport on top of the same memory codec. Core i32/i64 arrays use the signed JavaScript WebAssembly representation at the public boundary and unsigned bits internally, as in the pinned reference. Variant payloads are joined by bit reinterpretation and zero-extension, not numeric float/integer conversion. Narrow integer lifts discard unused high bits; unselected payload slots are consumed without reading their pointed-to data.

The caller explicitly selects the synchronous 16-parameter or one-result threshold. Larger values are transported through aligned memory: lowering either allocates and returns a pointer or uses a supplied result out-pointer and returns no core values. Direct values reject an unused out-pointer. Memory32/memory64 string and list paths share the existing range/UTF-8/budget implementation.

Further source review of canonopt validation identified that the pinned memory64 realloc signature uses four address-width parameters, including alignment. The runtime now passes four BigInts and a focused fixture calls an actual four-i64 Wasm function. The earlier host-only allocator fixture shared the incorrect Number-alignment assumption; passing those tests did not establish ABI correctness. Function binding, post-return and instance state are still distinct, unimplemented obligations.


## Core binary signatures before binding

A Canonical ABI wrapper must check the callee's actual signature before calling it. Core 3.0 places function signatures in the type section and associates imported/defined function indices with those types; GC recursive groups contribute multiple type indices. The new `psc-wasm-core-signatures/1` boundary pins bytes, compiles them without instantiation, and reads bounded signature/index metadata from those same bytes. Numeric signature requirements reject reference/vector boundaries, while GC types may remain internal. Exported memory address widths are explicit. See [Core types](https://webassembly.github.io/spec/core/binary/types.html) and [Core modules](https://webassembly.github.io/spec/core/binary/modules.html), revision displayed as WebAssembly 3.0 (2026-10-03).

The engine supplies full binary/instruction validation; the metadata reader is not an independent instruction validator or behavioral proof. Compilation does not run a start function, imports or guest code. Callers must still bind the inspected module instance and manage Canonical call/resource lifecycle. Byte and metadata limits do not prove a global engine compilation cost bound.

Wasm names are length-delimited UTF-8, not text documents with an optional byte-order mark. Reviewing this boundary found that the older literal validator and failure diagnostics stripped an initial BOM through TextDecoder's default. Both now preserve it. A literal module exporting U+FEFF followed by `answer` must never validate against an expectation for plain `answer`. The literal expectation decoder also rejects trailing line terminators in numeric text, matching the exact canonical-number rule used elsewhere.


## Pure planning before closed-core export binding

Canonical value/type planning is now separate from attaching memory and realloc. Pure plans expose immutable lift/lower numeric signatures for selected functions; the runtime holds the underlying type layouts privately. The portable planner independently emits signatures for the same fixture functions and both pointer widths. This avoids instantiating a module merely to discover whether a function is compatible.

`psc-canonical-closed-exports-sync-utf8/1` binds an explicitly selected exported InterfaceIR surface to a pinned core module with no imports or start function. It checks capabilities and every selected export/memory/realloc/post-return signature before instantiating that exact compiled module. Numeric-only bindings need no unused memory or allocator. Calls share the existing argument/result conversion, including indirect 17-argument and one-result thresholds.

Results are lifted and copied before selected post-return code can overwrite/free their memory. A trap during lowering, the callee, lifting or post-return poisons the adapter, so later calls reject. Arity errors before lowering do not enter the lifecycle. This is an explicit closed synchronous profile: it does not implement general component imports, callbacks/reentry, resource ownership, asynchronous tasks or cancellation. Caller execution policy still owns compilation, instantiation and guest cost containment, and the module's behavioral/allocator contract remains an assumption.

The profile is a runtime adapter boundary, not a claim that PSC's current private GC exports are Canonical ABI exports. Compiler lowering, component binary generation and production artifact/EvidenceEnvelope integration must explicitly select and bind this contract before those targets can be promoted.

### Compiler-selected scalar Wasm exports (2026-10-08)

The closed Canonical ABI host binder now has a portable compiler producer.
`Ps.BackendWasm.CanonicalExports` derives InterfaceIR from actual freshly
validated post-specialization declarations, checks the lowered functions
against the independent Canonical ABI planner, validates the resulting
WasmIR, and encodes that same module. An explicit source/foreign-name
selection controls the entire visible export surface. Internal string/GC
helpers remain private and can still serve the selected functions.

The source machine-word profile determines `usize/isize` as u32/s32 or
u64/s64. This scalar-only interface needs no memory; it does not couple source
word size to Canonical ABI address width. Fixed-width integers and floats,
Bool and Char retain their declared scalar semantics. Unit results already
lower to zero core results. Unit parameters, generic or GC boundary values,
and more than sixteen parameters reject until actual conversion wrappers
exist. Parameter names become deterministic positional labels, since source
identifier syntax is not the WIT naming grammar.

The binding artifact records source names and exported aliases. It does not
mint source authority or prove preservation. Production checked-driver,
PassExecution/EvidenceEnvelope, archive and independent replay integration
must bind the selection, actual IR, interface and exact binary before this
profile can be promoted. See
`contracts/interface/WASM_CANONICAL_SCALAR_EXPORTS_V1.json`.

### Canonical scalar evidence boundaries (2026-10-08)

The independent host projection consumes exact SpecializedIR and explicit
selection artifacts. It reconstructs the portable producer's InterfaceIR and
binding bytes, rejecting mismatched aliases, primitive signatures, word
profiles, generic boundaries and duplicate source names. This projection
checks the full IR encoding schema but deliberately does not claim strict
body/type/scope validation; optional existing IR replay owns that relation.

A separate relation checks engine-valid closed binaries without instantiating
them. It requires the entire selected export surface, Canonical numeric
signatures, and, when the actual WasmIR snapshot is supplied, exact export
routing through source function names and encoded function indices. It does
not inspect function behavior. The portable producer retains its actual
validated target module so a driver can snapshot the same value it encoded.

Observed build graphs bind selection, interface, binding, target IR, binary
and validation artifacts; offline archive verification recomputes both
relations. The static host TrustManifest explicitly includes the added
projection/codec/signature-inspection dependencies. Production checked-driver
selection routing and output/EvidenceEnvelope publication remain separate
implementation work. No serialized adapter data creates source authority.

## Public API and origin design, 2026-10-08

TypeScript research was refreshed against exact main commit
`91521cf2299d54a40d46fcf500130d273ddfc947`. Its current compiler sources
are in `tsc/internal`. Relevant primary implementation references:

- [Declaration transformer](https://github.com/microsoft/TypeScript/blob/91521cf2299d54a40d46fcf500130d273ddfc947/tsc/internal/transformers/declarations/transform.go):
  `ensureType`, `ensureTypeParams`, `ensureParameter`, and
  `transformFunctionDeclaration` retain the semantic signature and remove
  implementation bodies. Type serialization consults the checked resolver.
- [Symbol accessibility tracker](https://github.com/microsoft/TypeScript/blob/91521cf2299d54a40d46fcf500130d273ddfc947/tsc/internal/transformers/declarations/tracker.go):
  exported signatures require name visibility/import closure, not only printing
  whatever names occurred in an implementation.
- [Source-map generator](https://github.com/microsoft/TypeScript/blob/91521cf2299d54a40d46fcf500130d273ddfc947/tsc/internal/sourcemap/generator.go):
  generated positions, source positions, optional names and pending mappings
  are separate writer state.

PSC design conclusions: portable PublicApiIR retains exact source Core types,
universe parameters and binder visibility before erasure. It omits definition
bodies and target layouts. The current language has no public/private modifier,
so version 1 explicitly includes all prepared declarations and generated members.
A declaration adapter must select an export surface, resolve accessible names,
and check runtime representation. Unsupported signatures must reject explicitly;
TypeScript's permissive fallback types are not a correctness argument for PSC.

The actual direct-JS path specializes and removes generic roots while preserving
only requested closed instances. Therefore a generic declaration projected from
Core cannot yet promise a JavaScript export with the same name. The existing
closed specialization path remains intact; open generic exports require a
deliberate ABI/lowering strategy and correspondence validation. The new source API
product is independently available through a live checked service even when a
target cannot lower that API. This separation is useful for tools, but confers no
runtime compatibility or behavioral reuse claim.

The [ECMA-426 draft](https://tc39.es/ecma426/) inspected is dated 2026-09-11.
JavaScript columns count UTF-16 code units; Wasm positions use byte indices.
Version 3 mapping segments and their state resets must follow that distinction.
Generated helpers need explicit unmapped segments. Proposed scopes/ranges are
not silently assumed part of the selected mapping contract.

Origins must come from actual parser/elaborator events and pass correspondence.
Current source preparation removes imports and trims text; a map to original
files requires an exact preparation map. Core currently discards syntax spans.
The next OriginGraph work must carry a separate stable origin table through
preparation and transformation, with preserve/merge/synthesize/drop reasons,
and pass exact generated text positions from the writer. Searching source text
after code generation cannot recover those relations reliably.

All new products remain descriptive artifacts. Checked-session association,
source-to-admissions normalization, public projection fidelity, runtime export
correspondence and global preservation are distinct obligations.

## Origin preparation boundary

The existing bounded reader preserves BOM and rejects malformed UTF-8. Preparation
now retains exact byte intervals for the text it already produced, including
import removal, newline normalization and trimming. Separate intervals preserve
gaps rather than claiming that a declaration crossing removed text came from one
contiguous source range. Empty/import-only files remain in the provenance inventory
without consuming a prepared-source index.

This edge is host metadata and does not alter source admissions or kernel logic.
The full next edge should observe each actual `psElabDeclarationBatch` event,
associate resulting declarations with the parsed declaration span, and thread a
separate origin side table through preparation. A shared elaboration fold should
serve ordinary and origin-aware preparation so event capture cannot drift into a
second frontend. Declaration-level origins must be labeled as such until finer
expression mappings are emitted. Core and target transformations must explicitly
record preservation, merging, synthesis or loss; the preparation map alone cannot
supply generated-code positions.


## Observed declaration and instance correspondence

Declaration origins now come from the single actual elaboration fold. Generated
members share their originating declaration batch span. The shared erasure fold
records each source declaration's actual runtime name, proof omission, or absence
of a RuntimeIR declaration. Host maps bind the exact ordered PublicApiIR and
RuntimeIR inventories; they do not independently prove proof classification,
type/body erasure or constructor layout correspondence.

Specialization metadata now retains the witnesses established by the existing
bounded correspondence checker, including source definitions, concrete type
arguments and actual specialized names. Every target definition must have an
owner. The metadata uses target module order and is independent of producer name
mangling. Archive replay reruns the relation against exact subject identities;
serialized witnesses are never a substitute for that check.

This provides the declaration-level links needed for origin composition and
public export selection. The next target edge must capture positions in the
actual writer. Generic public exports still require a deliberate representation
strategy; the closed specialization contract is unchanged.


## Generated-position writer contract

The stack-safe JS printer now observes its actual emitted declaration chunks
through the shared printing fold. Byte offsets and zero-based UTF-16 columns
are distinct; the internal cursor handles CRLF across chunks and counts CR,
LF, line separator and paragraph separator according to
[ECMAScript line terminators](https://tc39.es/ecma262/2026/multipage/ecmascript-language-lexical-grammar.html#sec-line-terminators).
Exposed chunk boundaries cannot split CRLF. The
[ECMA-426 position model](https://tc39.es/ecma426/#sec-terms-and-definitions)
requires UTF-16 JS columns; parser scalar columns must not be copied into maps.

The metadata records chunk boundaries, not expression positions or source
attribution. Shared runtime helpers outside the chunks remain unmapped. The
next map emitter must compose exact source/preparation, erasure and
specialization identities, retain explicit unmapped segments, and keep coarse
declaration mapping separate from future precise expression events.

TypeScript's pinned
[type eraser](https://github.com/microsoft/TypeScript/blob/91521cf2299d54a40d46fcf500130d273ddfc947/tsc/internal/transformers/tstransforms/typeeraser.go)
removes type parameters/arguments while preserving runtime bodies and retains
original-node/location metadata for partially emitted expressions. It is a
useful design reference for future JS representation sharing, but is not proof
that PSC dependent types, erasure classifications or runtime layouts can be
discarded without their own validation policy.

## Exact declaration lineage

The direct-JS path now composes source declaration batches through the actual erasure name table, independent specialization-instance witnesses and actual printer chunks. The composition reconstructs every parent and binds the identical PublicApiIR, byte-preserving validation boundary and complete target declaration/parameter inventory. It deliberately checks no expression-lowering or erasure semantic theorem. No emitted-name parsing or source-name flattening is needed. Live builds retain a separately identified debug artifact; archive replay uses caller-pinned parents and bounded fixed-depth artifact resolution.

ECMA-426 emission remains the next consumer. Coarse declaration anchors must end at the first generated line boundary (or chunk end), with explicit unmapped segments for synthetic code because source-map lookup can carry prior positions across lines. Source preparation and parser coordinates remain distinct from generated ECMAScript coordinates. Direct declarations and generic export semantics remain separate PublicApiIR work.
