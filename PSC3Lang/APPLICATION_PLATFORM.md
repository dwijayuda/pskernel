# Full application platform

**Proposed architecture and release requirements; no APIs/packages are implemented here. Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** Full application authorship remains a first-class goal, not a permanent restriction to extracted pure libraries.

## 1. Full ProofScript applications

Within a supported deployment profile, application logic, UI, routing, schemas, orchestration, tests and selected proofs can be authored in v0.7 `.ps` or supported native `.lean`. `.ps` declarations/calls are canonically lowered; they are not merely renamed Lean files. Optional `.psx` views require an explicit extension dialect and are not needed for ordinary APIs.

Platform/runtime adapters may be foreign implementations inside the distribution; users should not need handwritten glue for every normal operation. Full source authorship does not mean rewriting browsers, databases or npm packages, nor does it mean the whole app is formally verified.

## 2. Application layers

```text
Pages / CLI / service entry points
               |
Typed components, endpoints and application state
               |
Domain models, schemas, reducers and specifications
               |
Psc.Async / resource / capability libraries
               |
Declared JS/native/Wasm adapters
```

Shared models can serve browser and service code while module capabilities restrict dependencies. Sharing source is not permission to include secrets or filesystem operations in clients.

Use a few integrated concepts: records/inductives; Codec/Schema; Endpoint; Model/Msg/update/view; Async/Resource. These are ordinary library families, not independent source languages. V0.7 `function ... := ...;`, `fun`, adjacent calls and registered data/match forms can express their APIs. Proposed async, resource or component conveniences do not add new base keywords.

## 3. Platform inventory

| Area | First credible app profile | Follow-on work |
|---|---|---|
| Data | Text/bytes, collections, JSON codecs, typed errors. | Schema evolution and streaming/binary formats. |
| HTTP | Client and one server adapter, typed endpoints. | Streaming, WebSockets, advanced middleware. |
| UI | Typed views/events/forms/keys/state/subscriptions. | More composition and renderer adapters. |
| Routing | Parsed routes, encode/decode, navigation effects. | Nested layouts and server routing. |
| Async | Scoped work, failure/cancellation, request identity. | Bounded parallelism and backpressure. |
| Persistence | One driver/transaction adapter and tested CRUD. | Migrations, drivers and transaction proof models. |
| Development | Format/check/build/test/watch, maps, overlay, CSS/assets. | Profiling, HMR migration and distributed builds. |
| Distribution | ESM + types, clean browser/Node consumers, selected server target. | SSR/hydration, edge and native packaging. |
| Assurance | Checked domain contracts and exact assumptions. | Wider effectful proofs and compiler preservation. |

Do not delay all application work until all theorem automation exists. Do not call a compiler app-ready because one expression executes.

## 4. Reference app: Inventory Board

Build a small browser/service/persistence app with a verified domain transition.

### Shared source

`Domain.Item` defines nominal IDs, fields and invariants. `Domain.Adjustment` is an inductive request with explicit errors. `Api.Inventory` supplies request/response/error codecs and endpoint metadata. Shared definitions generate PSC clients, TS interfaces and runtime validation through explicit source/target formats.

Theorems concern the actual in-memory transition: stock stays in its domain; rejection preserves the model; success obeys the contract. They do not automatically establish concurrency properties of a database transaction.

### Browser source

`Client.Model` stores data, form/query states and a request generation ID. `Client.Update` maps messages to model/effect descriptions. `Client.View` uses ordinary v0.7 view calls or native `.lean` equivalents. An optional `.psx` example must expand to the same library meaning, not create a second maintained semantic implementation.

Form values remain text until decoded. Explicit loading/success/failure states and request IDs govern stale results. Cancellation does not imply remote writes were rolled back.

### Server source

`Server.Main` assembles router, configuration and capabilities. `Server.Inventory` validates, invokes an explicit authorization provider, executes a transaction and encodes outcomes. Secrets enter at the server boundary. Do not implement home-grown password cryptography or label typed authentication adapters proved.

`Server.Store` states isolation/conflict/retry behavior and identifies the driver. Domain reasoning remains conditional on the storage model until the implementation relation is established.

### Source grammar

Use inherited `import Inventory.Domain.Item`-style logical imports, v0.7 declarations/patterns and library combinators. Server async orchestration is not an implicit `export async function ... { ... }` grammar. ESM exports and deployment entry points are generated metadata/artifacts. `.lean` authors use native forms for the same APIs.

### Release output

Produce browser/service/client packages, source maps and an assurance manifest. Test malformed requests, stale responses, cancelled navigation, conflicts, denied access, startup failure and a false domain contract. Every app-owned module can be `.ps` or `.lean`; markup is an explicit optional boundary. This is an acceptance target, not a running app claim.

## 5. UI and React

The recommended library model has state, messages, update and pure view values, giving tests/proofs an identifiable subject. Templates/helpers can reduce boilerplate without hiding meaning.

A bounded React adapter renders/embeds components in existing TS apps, with reviewed props/events and lifecycle behavior. Hooks are not arbitrary pure functions. [E01–E02](RESEARCH_SOURCES.md#application-and-javascript-platform)

Do not build a DOM engine, React replacement and server framework at once. Validate one renderer before adding alternatives under the same interface contract. Components are ordinary functions unless an explicitly registered extension says otherwise.

## 6. SSR/hydration and framework boundaries

SSR needs deterministic initial rendering, serialization, stable keys, client capability boundaries and initialization. Hydration correspondence is an adapter test, not a consequence of view typing. [E03](RESEARCH_SOURCES.md#application-and-javascript-platform)

Next.js Server Components require dedicated compilation/serialization integration. ESM or React elements alone are insufficient. Reject unsupported transforms rather than emit misleading directives. [E04](RESEARCH_SOURCES.md#application-and-javascript-platform)

The plain browser/service app is P0; SSR/hydration is P1. Initial server rendering need not claim incremental hydration support.

## 7. Builds, assets and latency

Use Vite-compatible integration, original-source maps through v0.7 lowering or `.psx` expansion, CSS/assets, dependency invalidation and useful overlays. Development transformation and full checking are distinct evidence states. [E05](RESEARCH_SOURCES.md#application-and-javascript-platform)

HMR retains state only under a justified compatibility policy; otherwise reset. Changes invalidate related proofs. Measure startup, edits, rebuilds, diagnostics, browser cost, memory and clean production builds rather than inventing favorable budgets.

## 8. Adoption

Support consuming a PSC package, replacing one complete feature and authoring a whole supported app. Maintain examples for each with explicit foreign boundaries.

The strategy is concrete maintainability and guarantees, not a predicted market-share outcome. This syntax correction preserves the full-app goals while restoring one declared source grammar.
