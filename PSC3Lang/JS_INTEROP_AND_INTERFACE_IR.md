# JS ecosystem interoperability and InterfaceIR

**Architecture proposal, not implemented npm compatibility.** The objective is that supported applications need no hand-written JS glue, while every imported behavior retains an honest boundary.

## 1. Three different kinds of boundary value

1. **Owned data:** a validated/copied value with ordinary PSC semantics. JSON DTOs usually belong here.
2. **Foreign references:** opaque handles to mutable, identity-bearing objects. DOM nodes, streams and framework instances usually belong here.
3. **Foreign operations:** typed effectful calls with receiver, error, lifetime and scheduling contracts.

Do not treat every structural TS object type as an immutable Lean structure. TypeScript's compatibility design and object examples are not proofs of runtime immutability or nominal domain invariants. [T04,T10](RESEARCH_SOURCES.md#typescript-language-and-tooling)

## 2. InterfaceIR proposal

InterfaceIR is a versioned description of foreign interfaces, distinct from both dependent Core and executable Runtime IR. It can generate Lean declarations, adapters, validation code, `.d.ts` exports and human-readable assumption reports.

Each operation records:

- exact package/export path, dependency version and target-resolution conditions;
- wire types and value/reference distinction;
- receiver binding and argument order;
- optionality/omission and overload policy;
- synchronous/asynchronous behavior and start semantics;
- expected error channel plus unexpected foreign failures;
- callback argument/result schema, call multiplicity, reentrancy and lifetime;
- resource ownership/disposal, cancellation and aliasing rules;
- relevant runtime capability and purity assumptions;
- optional specification theorem/model and its evidence status.

The IR can be ordinary Lean-defined data. A signature is an interface claim, not evidence that its JS implementation obeys it. Package hashes bind identity; they do not prove the package's behavior.

## 3. Bounded `.d.ts` importer

Recommended first importable subset: concrete primitives, arrays/tuples, explicitly discriminated unions, DTO object shapes, literal tags, callbacks, resolved generics, bounded overloads and Promise-returning operations with an adapter model. Utility/conditional/mapped/template types may be specialized by an untrusted importer when their result is materialized and independently checked against the supported interface contract. [T03–T09](RESEARCH_SOURCES.md#typescript-language-and-tooling)

Unsupported recursive type computation, declaration merging, arbitrary augmentation, impossible overload discrimination, unmodeled `this`, conditional exports or unsafe dynamic behavior MUST produce diagnostics. They must not lower to an unrestricted `any` equivalent.

Importer output is reviewed/generated ordinary source plus InterfaceIR. Runtime decoding protects value domains; it does not prove arbitrary API behavior. Hand-authored interface adapters remain possible for unsupported packages and are explicitly labelled.

There is no claim that all of npm can be imported, nor that a declaration file is accurate or current. The supported-package catalog records exact versions and tested use cases. Installation/build scripts receive explicit permissions; source loading is not permission to run arbitrary code.

## 4. Absence and property access

JS distinguishes an absent property, a present property containing undefined, null, and a present value. TypeScript has configuration-sensitive optional-property checking. These distinctions matter to patch APIs and serialization. [T15,E11](RESEARCH_SOURCES.md)

Use a boundary representation conceptually equivalent to:

```text
FieldPresence A = missing | present (JsNullable A)
JsNullable A    = undefined | null | value A
```

These are ordinary proposed inductives, not new core rules. A specific application codec may deliberately map several cases into Option, but that lossy policy is explicit and cannot serve as a general inverse conversion.

A decoder of arbitrary JS objects may encounter accessors, proxies or mutation during reads. Offer a data-only profile accepting/copied from a controlled source and a foreign-object profile whose reads are effects. `hasOwn` plus property access is not a complete security proof; the local experiment only demonstrates the presence distinction on ordinary literals.

Reject or explicitly define unknown fields, duplicate JSON keys, prototype-related keys and schema version changes. Do not globally merge untrusted objects into configuration/prototypes.

## 5. Numbers, text and collections

Use explicit adapters for JS number, bigint and PSC numeric types. Converting a number to Nat requires the selected finite/integral/range checks; a returned bigint still requires nonnegativity. JSON numeric precision is a wire-design issue: use a specified string or tagged encoding for exact large integers when needed.

Preserve or reject NaN, infinities and signed zero according to the particular interface. Do not erase these distinctions for convenience. JavaScript strings use UTF-16 code units, while native Lean operations have their own index contracts; provide an explicit `JsString` boundary representation for lossless interoperation, including lone surrogates, and checked conversion to ordinary text. [E11,L11–L13](RESEARCH_SOURCES.md)

Maps/sets, dates, regular expressions, typed arrays and buffers are not automatically plain JSON. Supply named adapters. Byte views require explicit copying/sharing/detachment policy. Shared mutable buffers cannot be handed to a pure theorem model without a snapshot or appropriate state relation.

## 6. Calls, callbacks and receivers

A foreign method call retains the receiver. An extracted function that requires `this` must be bound explicitly or rejected. Registering a callback returns a scoped subscription/handle when the API requires disposal.

The callback contract states whether invocation is synchronous, asynchronous, one-shot or repeated; whether reentrancy is permitted; and what happens after disposal. Marshal input before constructing a typed message. Keep callback code from directly mutating logically immutable values through hidden aliases.

A proposed app-runtime pattern is `foreign event → decoded message → serialized update step → effect descriptions`. This reduces accidental reentrancy in owned application state but does not claim that every external API can be reduced to a pure function.

## 7. Promise and error adaptation

An existing Promise may already be executing. Distinguish attaching to it from starting a foreign operation inside a `Psc.Async` scope. Cancellation can request AbortSignal behavior when supported; it cannot promise reversal of a network side effect. Promise settlement, timeout and cancellation races require the explicit library policy. [E10,E12](RESEARCH_SOURCES.md#application-and-javascript-platform)

Expected failures become typed `Except`/Async errors. Unexpected thrown values and rejected reasons need a separate, explicit foreign-failure representation: JS can throw values that are not instances of Error. Do not assume exhaustive application error tags cover every external failure.

## 8. Exporting PSC libraries

Generate ESM and corresponding `.d.ts` interfaces from an owned export schema. Erased proof arguments do not appear as runtime arguments. A proof-indexed internal function is exported via either a validating wrapper or a clearly restricted internal ABI.

Generated TS interfaces describe the callable boundary, not all logical guarantees. A companion proof bundle identifies specifications, input encoding, runtime assumptions and preservation coverage. A downstream handwritten change to generated code invalidates its artifact identity; it does not keep the proof by keeping the filename.

Expose foreign identity only through opaque API operations. A verified DTO is not automatically interchangeable with a live framework object of the same shape.

## 9. Modules and deployment

ESM is the first recommended JS module route. Record Node/browser/bundler conditions, export maps, extension rules and chosen package entry points. CJS interoperation and side-effecting package initialization are separate catalogued capabilities. Node and TS module documentation show why resolution cannot be left implicit in a cross-toolchain assurance claim. [T12,E09](RESEARCH_SOURCES.md)

Bundlers, minifiers, tree shaking, worker packaging and framework compilation occur after semantic output and require separate testing or validation for any end-to-end guarantee. A Vite development success is not evidence that a production bundle preserves source behavior.

## 10. First supported adapter targets

Prioritize Web Fetch, URL/text/bytes, selected DOM events, timers/cancellation, a small Node file/process profile, ESM library calls, and a bounded React wrapper. Then add streams, database drivers and SSR integrations. Each catalog entry requires a clean example, negative boundary tests, capability report and exact version profile.

Do not promise Next.js Server Components merely because React client rendering works. Framework-specific server/client transforms and serialization have their own required integration. [E01–E05,E10,E13](RESEARCH_SOURCES.md)
