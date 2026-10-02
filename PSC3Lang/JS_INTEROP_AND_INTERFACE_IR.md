# JS ecosystem interoperability and InterfaceIR

**Architecture proposal, not implemented npm compatibility. Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** Source `.ps` follows the registered grammar; generated TS/JS and interface metadata have their own explicitly labelled formats. Target ESM does not introduce ESM-style source imports into v0.7.

## 1. Boundary values

1. **Owned data:** validated/copied values with ordinary PSC semantics, such as DTOs.
2. **Foreign references:** opaque mutable, identity-bearing handles, such as DOM nodes or streams.
3. **Foreign operations:** typed effectful calls with receiver, error, lifetime and scheduling contracts.

A structural TS object type is not automatically an immutable Lean structure. TS interface compatibility does not prove runtime immutability or domain invariants. [T04,T10](RESEARCH_SOURCES.md#typescript-language-and-tooling)

## 2. InterfaceIR

InterfaceIR is a versioned foreign-interface description distinct from dependent Core and Runtime IR. It may generate v0.7 `.ps` declarations, their canonical/native Lean counterparts, adapters, validation code, `.d.ts` exports and assumption reports. Generated `.ps` uses `:=`, `fun`, admitted calls/data forms and inherited commands; it is not a renamed `.d.ts` or stock-Lean-only alias.

Each operation records exact package/export/version and resolution conditions; wire types; value/reference distinction; receiver and argument order; omission/overload policy; synchronization and start behavior; expected/unexpected errors; callback multiplicity, reentrancy and lifetime; disposal/cancellation/aliasing; runtime capabilities; and optional specification evidence.

InterfaceIR can be ordinary Lean-defined data. A signature is an interface claim, not a proof of foreign behavior. Hashes bind identity, not semantics. A future `extern` spelling or the repository's separate FFI extension must be explicitly profiled rather than silently added to v0.7 grammar.

## 3. Bounded `.d.ts` importer

The first subset should cover concrete primitives, arrays/tuples, explicit tagged unions, DTOs, callbacks, resolved generics, bounded overloads and Promise operations with adapters. Utility/conditional/mapped/template types may be specialized by an importer when the result is materialized and checked against the supported interface contract. [T03–T09](RESEARCH_SOURCES.md#typescript-language-and-tooling)

Unsupported recursive type computation, merging/augmentation, overload ambiguity, unmodeled `this`, export conditions and dynamic behavior produce diagnostics, not an unrestricted `any` equivalent.

Output is explicit ordinary source plus InterfaceIR. Domain validation does not establish arbitrary API behavior. Handwritten adapters remain available and labelled. No all-npm or declaration-accuracy claim is made. Supported packages record exact versions and tested operations. Loading source is not permission to execute installation/build scripts.

## 4. Absence and property access

JS distinguishes missing, present undefined, null and value. These matter to patches and serialization. [T15,E11](RESEARCH_SOURCES.md)

Conceptual boundary model, **type-design notation rather than PSC source grammar**:

```text
FieldPresence A = missing | present (JsNullable A)
JsNullable A    = undefined | null | value A
```

Implementation uses ordinary v0.7 inductives or their native Lean equivalents. An application may deliberately collapse states to Option, but that lossy conversion is not a general inverse. No optional-field `?` or `?.`/`??` syntax is admitted by this data model.

Arbitrary objects may have getters, proxies or mutable reads. Choose a controlled data-only copy/rejection policy or effectful foreign reads. `hasOwn` plus access is not a security proof. Define unknown fields, duplicate keys, prototype-related keys and schema evolution explicitly; do not merge untrusted objects indiscriminately.

## 5. Numbers, text and collections

Explicit conversions connect JS number/bigint to PSC values. Nat needs finite/integral/range checks for numbers and nonnegativity for bigints. Exact large JSON integers need a specified string/tagged format where appropriate.

Preserve or reject NaN, infinity and signed zero per interface. Lossless foreign text may require a JsString representation including lone surrogates, followed by checked conversion to native text. [E11,L11–L13](RESEARCH_SOURCES.md)

Maps, sets, dates, regexes, buffers and typed arrays need named adapters. Specify copy/share/detach policies. Shared mutable data requires a snapshot or state relation before reasoning as pure data.

## 6. Calls, callbacks and receivers

A foreign method retains its required receiver; detached functions are bound or rejected. Subscriptions expose scoped disposal where needed. Specify synchronous/asynchronous, one-shot/repeated and reentrant behavior, including after disposal. Marshal inputs before creating typed messages.

A useful runtime pattern is foreign event → decoded message → serialized update → effect descriptions. That does not imply all APIs are pure functions. Source calls use v0.7 D-CALL or supported native application; target `.call`/receiver mechanics remain implementation details with explicit correctness obligations.

## 7. Promises and errors

An existing Promise can already be executing. Distinguish attachment from starting a foreign operation inside `Psc.Async`. Abort requests do not guarantee rollback. Settlement, timeout and cancellation races follow the named library model. [E10,E12](RESEARCH_SOURCES.md#application-and-javascript-platform)

Expected failures become typed Except/Async errors. Arbitrary thrown/rejected values need a separate foreign-failure channel. Domain tags do not exhaust every host failure. No new `async`/`await` source grammar or Promise-as-Lean-effect equivalence follows from this adapter.

## 8. Exporting libraries

Generate ESM and `.d.ts` from an owned export schema. Erased proof arguments are not runtime arguments. Expose proof-indexed internals through validating wrappers or an explicitly restricted ABI.

TS interfaces describe the callable boundary, not every logical guarantee. Proof bundles bind specifications, encoding, assumptions and preservation coverage. Editing generated code invalidates identity; keeping its filename does not retain proof. Opaque identity operations remain distinct from ordinary DTO equality.

## 9. Modules and deployment

Use inherited logical `import` commands in `.ps`/`.lean`; map them to locked target package entries. ESM is the recommended JS output route. Node/browser/bundler conditions, export maps and entry choices are recorded. CJS and startup side effects are separately supported capabilities. [T12,E09](RESEARCH_SOURCES.md)

Bundlers, minifiers, tree shaking, workers and framework transforms occur after semantic output and require appropriate tests/validation. A Vite development success does not prove production preservation.

## 10. Initial adapter targets

Prioritize Fetch, URL/text/bytes, selected DOM events, timers/cancellation, bounded Node file/process APIs, ESM calls and a bounded React wrapper. Add streams, storage and SSR through concrete apps. Each catalog entry needs source examples classified by language/profile, negative boundary tests, capability reports and exact dependencies.

React client support does not imply Next.js Server Components. Framework server/client transforms and serialization need their own integration. [E01–E05,E10,E13](RESEARCH_SOURCES.md)
