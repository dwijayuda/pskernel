# Standard library, modules and package design

**Proposed library architecture. Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** Names below are proposed namespaces, not published or implemented package claims. Libraries may use v0.7 `.ps` or supported native `.lean`; canonical semantics, not source-byte identity, connects them.

## 1. Layering

| Layer | Proposed contents | Dependency rule |
|---|---|---|
| Native base | Pinned Init and selected Std declarations. | Exact source/elaboration/logical closure. |
| `Psc.Data` | Text, bytes, collections, schemas, codecs, routes. | Pure ordinary definitions where possible. |
| `Psc.Spec` | Laws, contracts, invariants and proof helpers. | Registry membership has no proof authority. |
| `Psc.Effect` | Capabilities and error/resource conventions. | No hidden IO in pure-looking APIs. |
| `Psc.Async` | Descriptions, scopes and cancellation. | Not a redefinition of native Lean Task. |
| `Psc.Web` | HTTP, endpoints, URLs, forms and routing. | Host effects behind typed interfaces. |
| `Psc.UI` | Views, model/update/subscriptions. | Ordinary v0.7/native API; optional syntax separately profiled. |
| Adapters | Browser, Node, React, storage/native/Wasm. | Exact runtime identities, permissions and evidence. |
| Development tooling | Build, LSP, tests, docs, bindings, migration. | No logical authority; execution security is separate. |

Applications need not import the whole prover and theorem libraries need not import browser runtimes. Separate source/elaboration from executable dependencies. Proof-only library content may erase only through justified erasure.

## 2. API and source style

Use `def` or the v0.7 `function`/`const` aliases with their restrictions. Function bodies use `:= ...;` in decorated expression declarations; lambdas use `fun`; records use `where` bodies and `:=` field assignment. Prefer native `Except ε α` for standard error APIs. The reference's illustrative user-defined `Result α ε` retains success-first order and is not silently interchangeable with Except.

Design predictable argument order, options records and native receiver positions. Method notation and D-CALL offer familiar use without changing resolution. Named/default arguments use supported inherited forms. Do not add colon-named calls, optional-property markers, error-propagation punctuation or universal resource blocks by library convention.

Share concepts across the platform: one coherent Codec family can serve endpoints, storage and initial UI state. Nominal identifiers stay distinct unless explicitly aliased; equal-shaped data is not automatically one logical type.

## 3. Schemas and codecs

A Codec provides encode/decode with typed errors; laws can establish properties such as `decode(encode(x)) = Except.ok(x)` under a defined wire model. The corresponding Lean term is `decode (encode x) = Except.ok x`. Lossy projections or normalizations need different laws.

Schema descriptions may generate v0.7 `.ps`, canonical/native Lean, TS interfaces, runtime validation, endpoints and docs. Generated evidence binds to the exact schema and resulting declarations; origin is not proof.

Start with scalars, tagged unions, products/records, explicit presence policies, lists/arrays and reviewed recursive forms. Functions, handles, arbitrary dependent values and proofs are not generically serializable. Define unknown-field, missing/null and evolution behavior; do not use runtime memory layout as wire format.

## 4. Modules and package manifests

Source uses inherited logical imports/namespaces/sections, not ESM-like replacements. A package manifest maps modules to one selected source snapshot and records PSC edition, v0.7 reference version, canonical Lean pin, extension environment, dependencies and target entries. `.ps` goes through structural lowering; `.lean` goes directly to its native frontend. Reject stale/ambiguous siblings and undeclared dependencies.

v0.7 §27 recommends npm/package.json as the JS package substrate. PSC-specific semantic/module/evidence metadata may augment it; this grammar repair does not introduce a replacement package manager or a new manifest DSL.

Entry capabilities separate browser/client from server/storage dependencies. This guards module inclusion, not arbitrary information flow. Initialization and visibility modes need exact inherited conformance; explicit startup is the initial recommendation. Parser/tactic registration belongs to elaboration dependencies, not accidental app runtime effects.

## 5. Version axes

Separate platform edition, source-reference/feature-registry version, extension grammar, logical profile, axiom policy, Core bundle, Runtime IR, InterfaceIR, runtime ABI, library API and artifact format. A formatter update cannot silently change call ownership or turn into a logical-profile update.

Library compatibility covers documented API/behavior; proof-script repair is separately reported. Semantic or assumption changes require review. Go's compatibility policy is an engineering reference, not a solution to proof compatibility. [G03](RESEARCH_SOURCES.md#engineering-and-design-method)

## 6. Distribution and reproducibility

JS packages may contain ESM, `.d.ts`, maps, runtime identities and proof bundles. TS source remains useful; native routes may expose `.rs`/crate metadata or selected built artifacts. These target artifacts do not become the source grammar authority.

Do not run arbitrary installation tools without declared permissions. Locks and hashes identify bytes, not behavior. Reports record exact statements, assumptions, dependencies and preservation. Downloaded acceptance flags cannot construct CheckedModule; consumers may request independent replay.

## 7. Foreign-package catalog

Catalog exact package/export versions, operations, conversions, callbacks/resources, initialization effects and clean-consumer tests. Unsupported libraries may use explicitly reviewed adapters without automatic verification. Dynamic values remain opaque until appropriately validated.

## 8. Implementation order

Close primitive/data APIs needed by compiler and app corpus; then schemas/codecs, HTTP and async/resource basics, one UI adapter and tooling. Add storage/streams/frameworks from concrete requirements.

Every library needs examples with declared source language and v0.7 lowering where relevant, behavior/law documentation and negative cases. A name and `.d.ts` declaration are not an implementation plan.
