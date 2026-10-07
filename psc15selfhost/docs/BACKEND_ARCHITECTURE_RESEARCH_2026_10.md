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
