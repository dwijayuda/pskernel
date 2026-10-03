# r3 npm and TypeScript Declaration Interoperability

Status: **accepted r3 interop architecture; InterfaceIR schema/importer/exporter implementation pending.**

## Goal

Make npm interoperability routine without importing TypeScript structural unsoundness into native ProofScript.

## Pipeline

~~~text
npm package + package exports + d.ts + runtime profile
                  |
                  v
           untrusted TS reader
                  |
                  v
             InterfaceIR
          /        |        \
       raw        safe      spec
     foreign     adapter    model
          \        |        /
             PSC package
~~~

A d.ts declaration is not runtime validation and not proof that the package implementation behaves as declared.

## InterfaceIR v1 concepts

Record package name/version, exact package export condition, ESM/CJS mode, selected declaration-file identities, type declarations, functions, receiver identity, callbacks, Promise behavior, presence policies, errors/effects, and target profile.

Core type forms should include primitive values, literals, arrays, tuples, records, variants, functions, Promise, callbacks, handles, generics, and opaque foreign types.

## Three layers

Raw foreign layer is a faithful boundary model and may expose ForeignValue, foreign handles, missing/undefined/null distinctions, receiver-bound methods, and raw Promise values.

Safe layer validates/decodes into native nominal PSC values, converts numeric domains, classifies failures, adapts async behavior, and owns callback/resource lifetimes.

Specification layer optionally states logical models. A model theorem does not prove that the JS package implements the model unless that relationship is separately established.

## Dynamic values

TypeScript any and unknown become explicit foreign/dynamic values, never a native unchecked any.

Runtime refinement/decoding is required before such values become invariant-bearing PSC data.

## Presence

Preserve missing, undefined, null, and present-value states where the API can distinguish them.

Optional-property syntax in d.ts is not automatically identical to Option. The adapter records an explicit presence policy and whether information is lost.

## Objects

Readonly is a TypeScript static property, not proof of deep runtime immutability.

Plain data should normally be copied/decoded into owned nominal structures. Identity-bearing mutable objects such as DOM nodes become opaque handles with effectful methods.

## Numbers

JS number maps only through a selected checked numeric conversion. JS bigint to Nat still checks nonnegativity.

Do not use target arithmetic as the source definition of Nat/Int.

## Unions

Literal/discriminated unions can become finite PSC variants when runtime discrimination is defined.

Ambiguous structural unions require an explicit decoder or are unsupported.

## Promise

Raw Promise remains a foreign value. The adapter states already-started behavior, rejection classification, cancellation support, and late completion. It does not become native Lean Task by alias.

## Callbacks and receivers

Bindings state receiver/this requirements and callback retention/reentrancy/lifetime. A retained callback is not equivalent to an immediate pure higher-order call.

## Overloads

Support only when selection can be translated deterministically. Otherwise generate explicit wrapper names, require a manual adapter, or reject.

## Generics and advanced TS types

Simple parametric generics may map to PSC polymorphism.

Conditional, mapped, template-literal, keyof, and indexed-access types are importer problems. A bounded untrusted specialization phase may normalize supported cases into ordinary InterfaceIR. Unsupported cases reject rather than becoming any.

## Branded types

A TS brand can express static nominal intent but is not a runtime invariant. Import as a validated wrapper, opaque foreign brand, or explicit assumption.

## Iterables

Iterable can use a versioned iterator adapter. AsyncIterable maps to PSC Stream only when demand, cancellation, failure, completion, and cleanup are specified.

## Generated binding package

Suggested structure:

~~~text
raw.ps
safe.ps
schema.ps
specs.ps
interface-ir.json
binding-manifest.json
~~~

specs.ps is optional and must not contain fabricated proofs.

## Exporting PSC to npm

A PSC package can emit:

~~~text
index.js
index.d.ts
index.js.map
assurance.json
proof-bundle/
~~~

Proof-only parameters disappear from runtime signatures. Public APIs with refined domains use runtime-validating constructors/wrappers or a clearly restricted internal ABI.

## Required status vocabulary

Each imported symbol is one of:

- raw-unverified;
- runtime-validated;
- modeled-external;
- verified-adapter;
- trusted-assumption;
- unsupported.

## Diagnostics

- PS_DTS_UNSUPPORTED_TYPE_OPERATOR
- PS_DTS_AMBIGUOUS_OVERLOAD
- PS_DTS_EXPORT_CONDITION_MISMATCH
- PS_DTS_PRESENCE_POLICY_REQUIRED
- PS_DTS_RECEIVER_REQUIRED
- PS_DTS_RUNTIME_VALIDATION_REQUIRED
- PS_DTS_DYNAMIC_ESCAPE

## Prototype corpus

The importer prototype must eventually cover a pure utility package, JSON/schema package, Promise HTTP API, event/callback API, receiver/class API, React/UI declarations, and an intentionally unsupported advanced type case.

## Evidence status

Architecture: **accepted for r3**.
Serialized InterfaceIR schema: **pending**.
InterfaceIR importer: **not implemented; no prototype evidence claimed by this documentation baseline**.
Exporter: **pending**.
npm package workflow evidence: **not claimed by this documentation baseline**.
Runtime validation library: **pending**.
