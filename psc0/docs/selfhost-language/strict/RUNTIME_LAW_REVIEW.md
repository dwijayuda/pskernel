# Enabled runtime laws: source review and remaining proof obligations

## Status and decision

This is a source-level review of the 45 enabled primitive operations in the current PSC0 TypeScript lane. It supplies explicit conditional arguments, identifies two concrete expression-template defects, and records the exact reviewed correction. It does not report compiler execution, cloud qualification, a kernel theorem, or completed general source preservation. The authoritative operation meanings remain in `enabled-runtime-contract.json`; this document does not narrow or replace them. The existing correspondence explanation and ledger retain their separate authority. [P1] [P2] [P9]

The recommended next implementation is the two-operation correction below, together with the separate Nat-major and partial-application corrections and their shared raw-source regression. A broad runtime refactor, a new cache algorithm, additional source syntax, and additional primitive capabilities are unnecessary for these findings. Every other enabled intrinsic template retains its equality-corrected bytes. General correspondence work should then proceed through shared value/evaluation relations and a small number of family arguments, instead of treating another collection of passing examples as semantic discharge.

All of the following remain false:

- `strictSh1Qualified`
- `semanticContractQualified`
- `generalPreservationProven`
- `formalPreservationProven`
- `sourceProofProvenanceReconstructed`

No obligation ledger row is closed by this review. Kernel, provider, definitional equality, metatheory, runtime helpers, the UTF-8 cache algorithm, toolchain pins, source grammar and seed identities are unchanged.

## 1. Exact review boundary

| Artifact | Immutable Git blob or native revision | Role |
| --- | --- | --- |
| Enabled runtime contract | `8c893f0ecbc37855d02a006bb2774de4b0ebde2b` | Six primitive carriers, Array, 45 laws and 186 finite cases |
| Correspondence explanation | `74289d66a4366eaed59d679721272c1c29b89ea9` | General obligation interpretation |
| Correspondence ledger | `eedc40474f88183243b40d3ab6e4f9ea9090507e` | All 33 general rows remain open |
| Equality-corrected BackendTs/Expr | `9628e3c9def09c487abb5b8859a79c7be735acf9` | Exact base for this next correction |
| Next BackendTs/Expr candidate | `dfd58154826c892d18b97b84303abbce6a622d7b` | Only stringAtEnd and arrayEmptyWithCapacity change |
| BackendTs/Module | `fa6491f4861ddc59caba51c03a29790fc6e8653b` | Actual UTF-8 and generator helpers |
| BackendTs/Type | `8c9dcf6b0168dcb1edc49d87130fbee09a47cd79` | Actual carrier printing |
| Installed source prelude | `d862ba8c806595fbf11237724089bd2282af9866` | Source capability boundary |
| Separate Nat-major prerequisite | `3153b38e9a85e00932cac7cad59440dede218899` | Separate Erasure/Expr change; not included in the two-operation diff |
| Combined Nat-major and partial-application candidate | `3e11222a620cd044c9a5d48243c9b33421b5d5dc` | Eager capture of supplied computations, with proof-erased runtime annotations |
| Combined regression gate | `df55eb56e9ce5c7f26a134b48de5114feeaaaad6` | Eleven definitions and one structure, 24 native values and 21 diagnostic host probes |
| Native Lean | `4.34.0`, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b` | Pinned native definitions and runtime |
| JavaScript lane | Node `22.23.3`, TypeScript `7.0.2` | Explicit trusted compiler/runtime boundary |

The candidate expression file SHA-256 is `6412739b8ff585f8dda07109ad986802e1006d78e35bdb1051497ad452410095`. The equality-corrected base SHA-256 is `ad3315ec4e54cf7a1cb80b100202000f34e7f69cef2d7b99fb73b459bcb96766`. A second reviewer reconstructed the candidate from exactly the two guarded case replacements and reversed it to the base. That review covers source structure; qualification still belongs to the root-owned exact-source run. [P3] [P4]

The combined gate's Nat/runtime predecessor `4651b0a8c9a32bd4129a641e3dfd9e64c23a3a8f` independently reverses through seven edit regions to `8838155fb80ef28f7bf5c3916c207c6c94451634`. The reviewed partial-application extension preserves the predecessor's 18 value rows and 11 diagnostic rows as exact prefixes; its additional changes are limited to the bounded raw fixture, native wrapper, diagnostic dispatch and corresponding counts. Its raw Lean and current new-only `ps-0.9-r3` PS fixtures, native reference wrapper, fixed value rows and host trace rows have independently reconstructed hashes. Its existing 186 cases, 45-operation inventory, eight bounds refusals, nine prior operand observations, five malformed-carrier cases, two text-position families and six raw-source equality declarations are preserved. [P5]

A subsequent complete fixture grammar audit found that its first expanded PS conditional used Lean's if/then/else spelling. The installed parser and printer require `if (condition) { thenBranch } else { elseBranch }`. The reviewed gate corrects that single PS line and its raw-PS digest; production code, raw Lean, native reference, pure observations, diagnostic traces and all counts remain unchanged. The audit checked all twelve declarations against the actual lexer, common name/pattern rules, declaration binders, arrow/application rules, braced matches and structure, eight newline-separated typed lets, and the corrected conditional. This is static source review, not a parser or compiler execution. [P11] [P12] [P13] [P14]

## 2. Relations and assumptions needed by every law

A useful runtime relation is indexed by the source/IR type. Nat and Int remain different relations even though both use primitive `bigint`. Char and String remain different relations even though both use primitive JavaScript strings. A JavaScript type annotation alone does not enforce these distinctions. [P1] [P6]

| Type | Related JavaScript value |
| --- | --- |
| Nat | A nonnegative primitive bigint denoting the same natural number |
| Int | A primitive bigint denoting the same mathematical integer |
| Bool | Exactly the corresponding primitive true or false |
| Char | The canonical UTF-16 encoding of exactly one Unicode scalar, including NUL when applicable |
| String | The canonical, well-formed UTF-16 encoding of the same finite scalar sequence; no normalization |
| Unit | undefined |
| Array A | An ordinary dense array of the same finite length, with corresponding elements related at A |
| Function | A source-owned function related through the same captured environment, parameter group and application relation |

For arrays, density means that every index below length has its own element. An element whose value is undefined is still present and can represent Unit. Bounds membership must therefore be determined by length and density, never by whether reading an element returns undefined.

The proofs also require the declared ownership and resource boundary:

1. Built-in BigInt, String, Array, iteration, reflection and generator behavior is the pinned ordinary behavior. Foreign proxies, accessors, overwritten prototypes, custom array iterators and externally mutated compiler/runtime objects are not silently admitted.
2. Inputs and results must be representable in the pinned host, and the execution under comparison must complete its required allocations. Native and JavaScript heap usage, allocation timing, wall-clock cost, stack limits and maximum physical sizes are not equated. Ignoring an Array capacity hint preserves the specified array value; it does not simulate the native allocator.
3. Array.get and Array.set are related to source operations only on their proof-required domain `i < size`. The explicit JavaScript bounds faults are useful defensive behavior outside that domain. They do not recover an erased proof or prove that a source computation possessed one.
4. A relation for map/fold callbacks must be established for source-owned functions. Calling diagnostic foreign functions in a gate is not an extension of the strict language with effects or FFI.
5. BigInt arithmetic/decimal conversion, native arithmetic, TypeScript translation and V8 execution remain explicit trusted implementation assumptions until separately verified. Reproducible hashes delimit this boundary; they do not prove it correct.

These are the contract's intended domains, not new exceptions introduced to make failing examples pass. The ledger separately requires a complete source/Core/IR relation and reconciliation of all mandatory language coverage. [P1] [P2]

## 3. All 45 local value laws

The table describes the argument to instantiate under those relations. “Conditional callback induction” explicitly depends on an application lemma; it is not an unconditional result about arbitrary JavaScript callbacks. Numeric and Boolean cases use the exact templates in the candidate, pinned native Prelude/Int definitions and native arithmetic implementations. [P3] [N1] [N2] [N3] [N4]

### 3.1 Nat: nine operations

| Operation | Local argument |
| --- | --- |
| natAdd | Nonnegative bigint addition denotes natural addition; the result remains nonnegative. |
| natSub | Split on a >= b. The first branch computes a-b; the second is zero. This is truncated natural subtraction. |
| natMul | Multiplication of nonnegative bigints denotes the natural product. |
| natDiv | Split on b=0. That branch returns zero before division. Otherwise truncation toward zero equals floor because both operands are nonnegative. |
| natMod | Split on b=0. That branch returns a. Otherwise the nonnegative remainder is a-floor(a/b)*b. |
| natEq | Primitive bigint equality agrees with equality of the represented naturals. |
| natNe | Primitive bigint inequality is the complement of the preceding equality relation. |
| natLe | Bigint non-strict order agrees with natural order on nonnegative inputs. |
| natLt | Bigint strict order agrees with natural order on nonnegative inputs. |

The guards in natSub/div/mod bind both source expressions as IIFE call arguments. Repeated uses of their local parameters do not repeat the source computations. The equality correction widens TypeScript literal types with erased assertions; it neither converts values nor adds a second evaluation. Division by zero never reaches JavaScript's throwing bigint division operator.

### 3.2 Int: ten operations

| Operation | Local argument |
| --- | --- |
| intOfNat | The same nonnegative bigint denotes the corresponding nonnegative integer. |
| intRepr | Decimal bigint conversion yields canonical signed decimal text: zero has no minus sign, positive values use decimal digits, and negative values prefix the positive magnitude with minus. |
| intNegSucc | For natural n, -(n+1) is exactly the integer represented by the negative-successor constructor. |
| intNeg | Integer negation agrees for the nonnegative and negative-successor constructor cases. |
| intAdd | Integer addition on the represented mathematical integers. |
| intSub | Integer subtraction on the represented mathematical integers. |
| intMul | Integer multiplication on the represented mathematical integers. |
| intEq | Bigint equality agrees with equality of the represented integers. |
| intLe | Bigint non-strict order agrees with integer order. |
| intLt | Bigint strict order agrees with integer order. |

The native Int representation has nonnegative and negative-successor cases. Reducing each arithmetic definition by those constructors supplies the mathematical side of these arguments. For repr, its native two-constructor definition produces decimal magnitude text with the appropriate sign. The correctness of the underlying native/JavaScript decimal conversion is a named trusted premise, not something established by a few large-number examples. [N2] [N3]

### 3.3 Bool: five operations

| Operation | Local argument |
| --- | --- |
| boolNot | The two input cases give the opposite Boolean. |
| boolAnd | False on the left returns false without demanding the right; true on the left returns the right Boolean. |
| boolOr | True on the left returns true without demanding the right; false on the left returns the right Boolean. |
| boolEq | Exhaust the four Boolean pairs and compare equality. |
| boolNe | Exhaust the four Boolean pairs and compare inequality. |

Exhaustive reasoning over the two-element Boolean carrier is a general value proof because there are no other related Boolean values. It must not be confused with finite testing of arbitrary program contexts. Demand additionally needs the expression rule: JavaScript &&/|| evaluate the left once and evaluate the right only in the selected case. Pinned Lean exposes internal macro-inlined conditional implementations for and/or; their selected-branch behavior explains the intended source demand. The source-to-intrinsic identity and lowering path must still be covered by the erasure obligations. [N1] [P2]

### 3.4 Char: two operations

| Operation | Local argument |
| --- | --- |
| charOfNat | Split the nonnegative input into Unicode scalar ranges and their complement. Valid inputs are at most 0x10ffff and convert exactly through Number; invalid scalars produce NUL. |
| charToNat | Decoding the first code point of a one-scalar canonical string yields that scalar's numeric value. The empty-string fallback is unreachable for related Char values. |

The scalar interval excludes surrogate code points. Thus String.fromCodePoint receives a valid scalar only after a bigint range decision, with no loss from Number conversion. A negative foreign bigint is outside the Nat relation; extending the guard for that foreign input is a different capability decision. [N5] [P3]

### 3.5 String: ten operations

Let U be UTF-16 code-unit length, let B be the sum of Unicode scalar UTF-8 widths, and let b_j and u_j be the UTF-8 byte and UTF-16 offsets of scalar j.

| Operation | Local argument |
| --- | --- |
| stringPush | Canonical UTF-16 concatenation appends exactly the supplied scalar to the scalar sequence. |
| stringSingleton | The one-scalar Char representation already is the corresponding singleton String representation. |
| stringLength | Array.from on a well-formed string enumerates Unicode scalars; its length therefore is the scalar count, not U or a grapheme count. |
| stringAppend | Concatenation preserves the two scalar sequences in order and remains well formed. |
| stringUtf8ByteSize | The UTF-8 helper sums the exact width of each scalar, yielding B. |
| stringNext | At a scalar start below B, return p plus that scalar's UTF-8 width; at an interior continuation byte, end or beyond end, return p+1. |
| stringGet | At a scalar start below B, decode the scalar at its related UTF-16 offset; otherwise return A. |
| stringAtEnd | Compare the original position p with B. The corrected template first evaluates text then position. |
| stringExtract | If b>=e or b is not a scalar start before end, return empty. Otherwise accumulate scalars until a matching stop boundary, or until end when no such boundary is encountered. |
| stringEq | Canonical UTF-16 encoding is injective on scalar sequences, so exact JavaScript string equality agrees with source sequence equality. |

No normalization, locale comparison or grapheme segmentation is involved. Combining sequences that render similarly can remain different strings.

The next/get/extract laws intentionally include non-boundary raw byte offsets. The pinned native C++ implementations establish the exact fallback: invalid get returns A, invalid next advances one, invalid extraction start is empty, and an extraction stop inside a multibyte scalar behaves as end of string. An arbitrary-precision position larger than every representable string stays out of bounds; converting it prematurely to Number would be wrong. The current helpers compare the bigint bound first. These pinned behaviors must be re-reviewed if the native version changes. [N6] [N4] [P3] [P7]

### 3.6 Array: nine operations

Let xs have length n and related elements. Number conversion of an index is exact after establishing `0 <= i < n`, because an ordinary JavaScript array length is bounded by its representable array range.

| Operation | Local argument |
| --- | --- |
| arrayEmptyWithCapacity | Evaluate the capacity expression once and return a fresh dense empty array, conditional on the resource boundary. The hint is not part of the array's observed value. |
| arraySize | BigInt(xs.length) denotes the exact natural length. |
| arrayPush | Copy the dense sequence and append the related new element; the input array's values are unchanged. |
| arrayGet | On the proof domain i<n, the indexed element is related. The bounds guard protects the implementation outside that domain. |
| arrayGetD | Split on i<n. Select the existing element or the supplied related fallback. The fallback expression is still evaluated as an ordinary argument. |
| arraySet | On i<n, copy and replace exactly position i; length and all other related elements are preserved. |
| arraySetIfInBounds | If i>=n, preserve the original array values. Otherwise the same pointwise copy/replace argument applies. |
| arrayMap | Conditional callback induction: after k positions, the output prefix contains exactly the k related callback results in source order. |
| arrayFoldl | Conditional callback induction over [start,min(stop,n)): the accumulator equals the source fold of the processed prefix; an empty range returns the initial accumulator without a callback. |

Pinned Array.map uses the Id instance of mapM. Its reference loop advances from zero to size and appends each result. The optimized native implementation reuses storage under native ownership rules, while JavaScript creates another array. That storage difference is unobservable under the immutable value relation. The JavaScript adapter calls the callback with exactly one element, so the built-in JavaScript Array.map's additional callback parameters do not leak into the source callback. [N7]

Pinned Array.foldl uses the Id instance of foldlM. Its reference definition clamps stop to size and consumes a decreasing count while incrementing the current index. The emitted loop uses the same end and current-index conditions. For start>=end, both return the initial value immediately; for start<end, the index is in bounds and exact as Number on every iteration. Array.setIfInBounds splits on the same source bound. [N7] [N8]

These are general induction arguments over arbitrary finite related arrays. Their callback premise is substantial: preservation for the captured environment, parameter group, callback result and any permitted error comes from EV-04/EV-05/TS-04. This review does not discharge those rows by assuming that a few host callbacks worked.

## 4. UTF-8 helper and cache invariants

The actual helper stores a view with the original primitive string, its bigint byte size and a Uint32Array of byte-position information. It initially fills the array with zeros. At each scalar start b_j it stores u_j+1; it also stores U+1 at B. Consequently, positions below B are zero exactly at continuation bytes, and nonzero entries recover their precise UTF-16 scalar start by subtracting one. The +1 representation distinguishes offset zero from absence. [P7]

The construction invariant is simple: before scalar j, the running byte and code-unit counters equal b_j and u_j. The width function and canonical iteration update them to the next scalar's offsets. Induction over the scalar sequence proves the position table and B. This supports get/next without relying on a finite list of Unicode examples.

A suspected Uint32 overflow is not a defect in this pinned lane. The Node 22.23.3 V8 header (Git blob `eb0a791cf73946c0955f6ccadbb36f0c4999cbab`) bounds String length by (1<<28)-16 on a 32-bit pointer configuration and (1<<29)-24 otherwise. Thus U+1 fits in Uint32. Every scalar has UTF-8 width at most three times its UTF-16 width, so B<=3U. B and the positions-array length also remain exact Number integers below 2^31 in the larger bound. Allocation of that potentially large table is still a resource premise; this argument does not promise that every maximum-sized string can allocate its view. [V1]

The two-entry cache only returns a prior view when its stored primitive text equals the requested text. Primitive strings are immutable and equality means identical scalar content under the relation, so a cache hit returns a view satisfying the same invariant. Replacing either cache entry changes time and memory retention, not the related result. No cache mutation is observable through a source value. There is no reason to change the cache algorithm to address the two identified template defects.

For extraction, an independent loop invariant is sufficient. Before its start flag becomes true, the byte counter is the prefix byte sum and output is empty. The flag can become true only at an exact scalar start b. Thereafter output consists of exactly the scalars traversed from b; an exact match with e stops before the next scalar. If e is a continuation byte or exceeds B, no loop boundary matches it and the output continues to end. If b is invalid, the flag never becomes true. This gives the native pinned cases by exhaustion over the start/stop classifications. [P3] [N4]

## 5. Operand placement and the two confirmed defects

All 45 enabled templates were inspected for source-operand occurrence, runtime order, omitted/repeated demand, and placement of source expressions inside newly generated function bodies. Each source operand has one printed occurrence. Bool.and and Bool.or intentionally condition demand of their second operand; all other operations demand their operands in declared source order in the corrected candidate. [P3] [P4]

Internal parameter reuse does not imply repeated source evaluation. Arithmetic and array IIFEs receive the original expressions as outer call arguments. Their bodies refer to fresh local parameters. Array.map/foldl callback bodies likewise operate on already captured function/array values; they do not inject an unevaluated source expression inside a new non-generator closure.

One timing qualification matters: arrayPush emits the equivalent of `[...array, value]`. Dense array copying occurs between evaluating the array expression and evaluating the appended-value expression. The two source expressions still run once and in the same order. Ordinary copying has no language-visible effect for canonical immutable arrays when required allocation succeeds. This is not a claim that every helper action occurs after every operand, and it is not a correspondence claim for foreign iterators, mutable inputs or allocation faults.

### RT-ORDER-01: stringAtEnd reverses its arguments

Before the correction, the emitted shape is:

```ts
POSITION >= __ps$utf8(TEXT).size
```

JavaScript evaluates POSITION before TEXT. The declared intrinsic order is text, then position. A pure final Boolean can be right while the operational order is wrong. A host diagnostic in which each operand records its call order, or each can throw a distinct object, distinguishes the two templates immediately.

The correction is:

```ts
((text: string, position: bigint) =>
  position >= __ps$utf8(text).size)(TEXT, POSITION)
```

Both original expressions are outer call arguments, evaluated text then position exactly once before UTF-8 helper work. Their scope is outside the IIFE's parameter bindings, so those bindings cannot capture source references. The helper is unchanged.

This is a demonstrated emitted-order discrepancy. The diagnostic foreign faults are not represented as proof-valid strict source programs; they are probes of the emitted operational mechanism.

### RT-GEN-01: arrayEmptyWithCapacity creates an invalid yield context

Before the correction, the emitted shape is:

```ts
(() => { void (CAPACITY); return []; })()
```

An ordinary source call in CAPACITY is printed using generator delegation, such as `yield* __ps$invoke(...)`. Injecting that expression into this new non-generator arrow creates a syntactically invalid TypeScript context. Literal-capacity examples cannot reveal the problem.

The correction is:

```ts
((capacity: bigint) => { void capacity; return []; })(CAPACITY)
```

The source expression stays in the surrounding generator, is evaluated once as a call argument, and the arrow body only consumes its parameter and returns the fresh empty array. Ordinary function-valued capacity callbacks already belong to the source language; no new effect or FFI feature is required to reach the old defect.

Both changes were independently source-reviewed as exact two-case replacements. Runtime helper bodies, cache state and all other 43 enabled cases are byte-identical to the equality-corrected base. [P3] [P4]

## 6. Regression scope and what its evidence can establish

The combined next-slice gate has five Nat-major definitions, two source definitions for stringAtEnd and array capacity, and four definitions plus one structure for partial applications. It compiles equivalent raw Lean and new-only PS through compileStrictSources, checks byte-identical TypeScript/admissions, and performs one additional tiny TypeScript 7 compile of their shared output for each compiler generation. The raw modules are compiled separately from other generated fixtures, avoiding private runtime-helper collisions. [P5]

A single additional native Lean execution calculates 24 pure values from the exact eleven raw Lean definitions and one structure, and its retained receipt is reused by N1/C1/C2/C3. Twenty-one host probes separately inspect once-only evaluation, call order, first-fault identity and unselected-branch non-demand. Fourteen probes use callbacks alone; seven additionally use a noncanonical host accessor to distinguish computed-callee demand. The String/Array share remains seven pure values and five host probes. Array capacity values are bounded by 17.

The added partial-application cases inspect a computed function field and two computed supplied arguments, repeated use, an unused saved closure, nested incomplete groups, and erased type/proof arguments. Pure-value cases use plain immutable host records with mathematically related fields; they do not establish full generated-brand carrier conformance. Accessor and callback traces are separate host diagnostics outside admitted source effects. The implementation's runtime annotation removes proof binders in the same way as erasure, and direct generic callees retain their type arguments at the call. These source-inspected cases support the bounded correction; they do not close the general closure, call-group or source-erasure obligations. [P10]

The native wrapper preserves its complete native receipt. A separate ordered observation object supports reproducible hashing without pretending that Lean JSON object key order must match JavaScript's insertion order. The original native rows are still compared in full against independently fixed results. The gate's source inputs, raw receipts, shared TypeScript, emitted JavaScript, admissions and native reference must be bound to the actual compiler/source products by the evidence binder.

The existing 186 observations remain valuable coverage and the new fixture targets the demonstrated lowering classes. Even a completely passing run establishes those observations and exact-source reproducibility only. It does not turn 24 or 186 examples into a theorem for arbitrary programs, nor prove source proof provenance.

The Nat-major and partial-application candidates retain their own separate identities and erasure review. This document neither modifies them nor treats the intrinsic-template arguments as proofs of Nat matching, fresh-name generation, branch substitution, general closure capture or application grouping.

## 7. Generator runtime argument and its limits

The runtime registers public functions with generator implementations. A call yields a request containing a function and argument group. The runner either pushes the registered implementation on its pending generator stack or invokes the represented unregistered value. A completed frame pops and supplies its return value to the waiting frame. Source lambdas register through the same wrapping mechanism. [P7]

A suitable simulation invariant relates each pending generator to the continuation of its source/IR call, with the waiting frames ordered from caller to callee. For a registered request, a push corresponds to entering the related callee with its argument group. A completed generator corresponds to returning the related result to the caller. Direct synchronous calls from map/fold adapters must be included in this relation because a public callback wrapper can start another runner.

This is a useful proof outline, not completed TS-04 discharge. It still needs a precise environment/capture relation, the general expression rules, call-group preservation, all recognized optimizer paths, and the conservative module-initialization argument. General source errors and resource failures must not be conflated.

The present IR has no source try/catch/finally rule to simulate. A JavaScript exception from a generator or represented host call escapes the current runner. The runner does not resume parent generators with throw. That observation is compatible with aborting evaluation in the stated no-handler domain; it is not a correctness claim for arbitrary foreign generators with cleanup handlers.

The explicit stack removes some ordinary JavaScript recursive-call pressure. It does not establish an unlimited total stack/resource bound for all callback nesting, all host functions or all supported compilation work.

## 8. Counterexamples outside the stated domain

These examples explain why the relation must remain explicit. They are not additional production fixes proposed by this review.

| Foreign input or condition | Why the unrestricted claim fails |
| --- | --- |
| Negative bigint supplied to charOfNat | It can reach String.fromCodePoint with an invalid negative number; negative values are not Nat. |
| Negative bigint supplied to arrayGetD/setIfInBounds | Their Nat-domain guards are not a general validation scheme for foreign signed indices. |
| Sparse array | JavaScript map can skip holes; a source Array is a dense sequence. |
| Mutated array iterator, proxy or getter | Copying/indexing can acquire effects absent from the immutable ordinary-array relation. |
| Ill-formed UTF-16 String or multi-scalar Char | Canonical scalar iteration/encoding lemmas no longer apply. |
| Array.get/set without a valid source bound | Defensive JavaScript refusal does not supply the erased source proof. |
| Huge native capacity/allocation failure | Value correspondence does not imply equal native and JavaScript allocation behavior. |
| Arbitrary effectful or throwing callback | A diagnostic observation is not an admitted source-effect semantics or a closure proof. |
| Host implementation replacement or TypeScript/V8 defect | The explicit trusted toolchain premise fails. |

Conversely, very large nonnegative Nat positions and arithmetic operands are inside the numeric relation when representable. The implementation must keep their bigint semantics. It must not introduce a safe-integer cut-off merely to simplify a host assertion.

The source-name catalogue also must not be mistaken for an installed source API. Some contract rows have no direct source name and arise through supported condition erasure. The current prelude does not install every name mentioned by the wider mapping catalogue; source capability admission and reserved primitive identity have separate obligations. This review does not invent authoring syntax for missing operations. [P1] [P8] [P2]

## 9. Which general obligations can advance

| Existing obligation | What this review contributes | What remains before discharge |
| --- | --- | --- |
| EV-03, enabled intrinsic evaluation | All 45 pointwise law arguments; Unicode/cache invariants; Array induction hypotheses; exact operand/context inventory; two concrete corrections | Install the shared value/evaluation relation and trusted premises, integrate callback/error/proof-domain arguments, independently review the complete rule, and qualify the corrected implementation |
| EV-01, literals | Carrier distinctions and relevant canonicality assumptions | Complete literal printing/escaping proof over all permitted input text and integer forms |
| EV-04 / EV-05, closures and calls | Required callback relation and the actual argument/demand shape | General capture, parameter-group, invocation and result/error simulation |
| TS-03, general templates | Intrinsic case and its evaluation-context corrections | All eleven expression forms, with child induction hypotheses, scope and error correspondence |
| TS-04, generator declarations/closures | Pending-stack simulation outline and callback re-entry limitation | Complete continuation/environment proof and registration/call-group coverage |
| TS-09, TypeScript/JavaScript boundary | Named versioned trust assumptions and representability limits | Explicit qualification of that boundary; source preservation cannot be inferred from product hashes |
| N-01..N-04 and ER-01..ER-09 | Concrete dependencies and the separate Nat candidate identity | Normalization, binding/layout, source origins, proof independence and erasure arguments remain separate |
| Other TS/EV rows and required language coverage | No waiver | Their existing obligations, including optimizer and mandatory empty-data reconciliation, remain open |

For first-order operation results, algebra, finite case splits and finite-sequence induction are adequate proof methods. They quantify over arbitrary related values and do not require exhaustively testing large domains. There are 43 first-order laws and two higher-order conditional laws, map and foldl. No single family argument supplies missing closure, source-origin or layout correctness automatically.

At the present review boundary, no whole one of the 33 ledger rows is declared discharged. The local arguments provide material for EV-03, but independently completing that row is a distinct review action against a precise operational relation. Completing EV-03 alone would still leave source normalization/erasure and the other required rows open. The current false assurance fields are therefore appropriate.

## 10. Efficient continuation

1. Integrate the reviewed Nat, partial-application, two-template, source-origin and ingress-snapshot changes as one coherent next semantic slice, with the combined small fixture and exact evidence binding. Retain the prior equality-only qualification separately. Run the required cloud gate once for that exact source; broaden it only if a concrete remaining failure or required gate warrants it.
2. Define a shared type-indexed value/environment relation and a small operational semantics for the existing eleven original-IR expression forms. State canonical values, source-owned callbacks, proof-required domains and resource assumptions once.
3. Turn the arguments here into separately reviewable family lemmas: arithmetic/Bool, Unicode encoding and cache, first-order Array, and conditional map/fold. Keep the 45-row catalogue as the completeness inventory.
4. Connect those family lemmas to EV-03 and the general expression/call/generator rules. Reuse the same callback/environment lemma for both Array operations and ordinary source calls.
5. Continue normalization/erasure and required-language reconciliation using the real retained origin objects. Promote strict status only after every mandatory ledger obligation is actually resolved and tied to one immutable qualifying source.

This sequence targets demonstrated defects and reusable proof obligations. It does not require a migration of every source file, a second source-language version, TypeScript 5, a new kernel/provider path, or a broad runtime rewrite.

## Primary source references

PSC0 references use immutable Git blob endpoints so that unattached candidates cannot be confused with a moving branch. Native source links use the exact reviewed Lean commit or Node tag. Subsequent qualification status must come from actual root-owned receipts.

[P1]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/8c893f0ecbc37855d02a006bb2774de4b0ebde2b
[P2]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/eedc40474f88183243b40d3ab6e4f9ea9090507e
[P3]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/dfd58154826c892d18b97b84303abbce6a622d7b
[P4]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/9628e3c9def09c487abb5b8859a79c7be735acf9
[P5]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/df55eb56e9ce5c7f26a134b48de5114feeaaaad6
[P6]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/8c9dcf6b0168dcb1edc49d87130fbee09a47cd79
[P7]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/fa6491f4861ddc59caba51c03a29790fc6e8653b
[P8]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/d862ba8c806595fbf11237724089bd2282af9866
[P9]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/74289d66a4366eaed59d679721272c1c29b89ea9
[P10]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/3e11222a620cd044c9a5d48243c9b33421b5d5dc
[P11]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/e91415c66fec9115a281c93c9459189bb919f121
[P12]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/4ab23fcc1ae2ef70bd90a997319e421f5744a723
[P13]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/45d4cb9ee3d20345ad51ff2e15a7cb4f78fe579b
[P14]: https://api.github.com/repos/dwijayuda/pskernel/git/blobs/335a78cad3eda53c9dd8687064002c9313901964
[N1]: https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Prelude.lean
[N2]: https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/Int/Basic.lean
[N3]: https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/Int/Repr.lean
[N4]: https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/runtime/object.cpp
[N5]: https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/Char/Basic.lean
[N6]: https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/String/Basic.lean
[N7]: https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/Array/Basic.lean
[N8]: https://github.com/leanprover/lean4/blob/293d5d0c0c3f3dded4688b3ccd6a33939ac5102b/src/Init/Data/Array/Set.lean
[V1]: https://api.github.com/repos/nodejs/node/git/blobs/eb0a791cf73946c0955f6ccadbb36f0c4999cbab
