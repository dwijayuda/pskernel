# Standard library, modules and package design

**Proposed library architecture.** Names below are design namespaces, not claims that packages have been published or implemented.

## 1. Layering

| Layer | Proposed contents | Dependency rule |
|---|---|---|
| Native base | Pinned Init and selected Std declarations. | Exact source/elaboration/logical closure recorded. |
| `Psc.Data` | Text/bytes, collections, schema, codecs, typed routes. | Pure ordinary definitions wherever possible. |
| `Psc.Spec` | Laws, contracts, invariant libraries and proof conveniences. | No runtime behavior merely from registration metadata. |
| `Psc.Effect` | Explicit capability descriptions and error/resource conventions. | No hidden host IO in pure-looking APIs. |
| `Psc.Async` | Portable task descriptions, scope and cancellation model. | Not a replacement definition of native Lean Task. |
| `Psc.Web` | HTTP, endpoint schemas, URL/form parsing and routing. | Host effects behind typed interfaces. |
| `Psc.UI` | View/component/model/update/subscription APIs. | Plain Lean source; optional syntax in a separate package. |
| Adapter packages | Browser, Node, React, selected storage/native/Wasm interfaces. | Exact runtime identity, permissions and assurance status. |
| Development tooling | Build, LSP, test, docs, bindings and migration. | Outside logical authority; secure execution separately controlled. |

Do not force every application to import the prover or every theorem library to import the browser runtime. Separate source/elaboration and executable dependency closures. A proof term can depend on a theorem library while its executable artifact erases that content, provided erasure is justified.

## 2. API style

Use ordinary Lean functions and types. Prefer a canonical error convention `Except ε α`, predictable argument order and options records for evolving configuration. Design receiver positions to support native field notation where appropriate. Offer explicit alternatives when inference is ambiguous.

Choose a small number of concepts shared across platform libraries. For example, the same Codec family should serve JSON endpoints, storage DTOs and initial UI state serialization, rather than introducing incompatible validation DSLs for each subsystem.

Nominal domain identifiers remain distinct structures unless the programmer deliberately chooses an alias. Convenience does not justify turning all equal-shaped records into the same logical type.

## 3. Schema and codec family

A proposed Codec for a supported type provides encode and decode functions with typed errors. A law package can establish properties such as `decode (encode x) = .ok x` under the stated wire model. Not every schema or type can satisfy every law; lossy projections and normalization require different named properties.

A Schema description can drive generated Lean definitions, TS interfaces, runtime validation, endpoint descriptions and documentation. Generation itself has no proof authority. Bind generated code and law evidence to the exact schema/version.

Support a deliberately bounded schema language first: scalar values, finite tagged unions, products/records, options with explicit presence policy, arrays/lists and reviewed recursive forms. Functions, live handles, arbitrary dependent values and proofs are not generic serializable data.

Derived patch/input/output DTOs are ordinary generated types. Specify how missing and null differ, whether unknown fields are rejected and how version evolution is handled. Do not infer backend wire layout from a record's runtime memory representation.

## 4. Modules and package manifests

Use native logical module paths. A manifest maps paths to one chosen source snapshot and records edition, Lean pin, allowed source/extension environment, dependencies and target entry points. Reject ambiguous sibling `.ps`/`.lean` files and undeclared transitive imports.

An application package should expose explicit entry-point capabilities, such as browser/client or server/store, so a client build cannot accidentally close over process/environment secrets through a shared import. This is a module/capability check, not a universal information-flow proof.

Native initialization and old/new Lean module modes need exact conformance rules. Until they are covered, recommend explicit application startup. Approved parser/tactic registration initialization is a separate elaboration dependency, not a runtime app effect.

## 5. Versioning dimensions

Keep independent identifiers for source edition, extension grammar, logical profile, axiom policy, Core bundle format, Runtime IR, InterfaceIR, runtime ABI, library API and artifact format. A formatter update is not automatically a logical-profile update; a new primitive reduction rule is not merely a package patch.

Compatible library updates should preserve public types and documented behavior. Proof scripts may require repair even when program APIs remain compatible; report that dimension separately. Semantic migrations and assumption changes need explicit review.

The Go compatibility policy is an engineering reference for taking continuity seriously, not a template that automatically solves proof-script compatibility. [G03](RESEARCH_SOURCES.md#engineering-and-design-method)

## 6. Distribution and reproducibility

The recommended JS package includes executable ESM, `.d.ts`, source maps, runtime dependency identities and optional proof bundles. TS source artifacts can remain available for integration. Native consumers may receive generated `.rs`/crate metadata or built artifacts under their selected route.

Package outputs should not require downloading arbitrary tools at install time without consent. Build scripts and generators are an explicit capability. Dependency locks and hashes identify exact bytes; they do not validate package behavior or substitute for proof checking.

Proof metadata records accepted statements, assumptions, dependency closure, code artifact identities and preservation coverage. Unchecked downloaded reports cannot construct a trusted CheckedModule. Consumer policy may request independent replay.

## 7. External-package catalog

Maintain tested adapter entries rather than claim generic npm compatibility. Each entry specifies package/export versions, supported operations, boundary conversions, callback/resource semantics, startup effects and clean-consumer tests.

For a unsupported library, offer an explicit hand-written adapter route without claiming its behavior verified. A dynamic opaque value can be useful in a host-only region, but cannot be coerced into arbitrary proof-bearing domain types.

## 8. Implementation order

First close primitive/data APIs used by the compiler and the reference app. Then ship schemas/codecs, HTTP and async/resource basics, one UI adapter and development tooling. Expand storage, streams and advanced framework integration from actual app requirements.

Every library family needs readable examples, behavior/law documentation and negative cases. A function name and a `.d.ts` declaration are not an implementation plan.
