# Full application platform

**Proposed architecture and release requirements; APIs/packages are not implemented by this document.** Full application authorship is a first-class goal, not a permanent restriction to extracted pure libraries.

## 1. Meaning of a full ProofScript application

Within a supported deployment profile, application logic, UI definitions, routing, endpoint schemas, service orchestration, tests and selected proofs can be authored in `.ps` or native `.lean`. Optional `.psx` improves view syntax but is not required. Foreign framework/runtime adapters may exist inside the platform distribution; the user should not need to hand-write glue for every normal operation.

Full source authorship does not mean the browser, database, operating system or imported npm packages are rewritten in ProofScript. Nor does it mean the whole deployed app is formally verified. Those are separate claims with explicit assumptions.

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

The same domain model can be used by browser and service code. Module capabilities restrict which entry points can include which dependencies. Source sharing is not permission to put secrets or filesystem operations in client bundles.

Use a minimal number of integrated concepts: ordinary records and inductives; Codec/Schema for untrusted data; Endpoint for request/response/error contracts; Model/Msg/update/view for the native UI layer; and Async/Resource for effects. These are library families with explicit semantics, not independent mini-languages.

## 3. Proposed platform inventory

| Area | First credible app profile | Follow-on work |
|---|---|---|
| Data | Text/bytes, arrays/maps, JSON codecs, typed validation errors. | Schema evolution, binary formats, streaming codecs. |
| HTTP | Fetch-style client and selected server adapter; typed endpoints. | Streaming, WebSocket, advanced middleware. |
| UI | Typed components, event decoding, forms, list keys, state updates, subscriptions. | Advanced composition and multiple renderer adapters. |
| Routing | Parsed route values, URL encode/decode, parameters and navigation effects. | Nested layouts, streaming loaders and richer server routing. |
| Async | Scoped tasks, failure/cancellation policy, request identity. | Bounded parallelism, backpressure and advanced scheduling. |
| Persistence | One explicit driver/transaction adapter with tested CRUD. | Migration tooling, broader drivers and transaction proof models. |
| Development | Format/check/build/test, watch mode, source maps, error overlay, CSS/assets. | Profiling, advanced HMR state migration, distributed builds. |
| Distribution | ESM + types; clean Node/browser consumption; selected server deployment. | SSR/hydration, edge-specific capabilities and native packaging. |
| Assurance | Checked domain contracts and exact assumption reports. | Wider stateful/async specifications and compiler preservation. |

Do not postpone every application feature until all theorem automation is complete. Conversely, do not call a compiler application-ready because a single expression evaluates.

## 4. Cohesive reference app: Inventory Board

The design corpus should build a small inventory application with a browser view, typed API, persistence and a verified domain transition.

### Shared source

`Domain.Item` defines nominal IDs, item fields and invariants. `Domain.Adjustment` is an inductive request with explicit error cases. `Api.Inventory` declares request, response and error codecs plus endpoint metadata. The same definitions generate a PSC client, a TS interface and runtime validation on the server.

Proof candidates establish properties of the actual in-memory transition: stock remains within the chosen domain; rejected requests leave the model unchanged; successful adjustments follow the contract. The theorem does not automatically prove that a database transaction under concurrent requests preserves those properties.

### Browser source

`Client.Model` stores items, form state, query status and a request generation ID. `Client.Update` transforms messages into a new model and effect descriptions. `Client.View` uses ordinary typed view constructors; `Client.View.psx` may be an alternative example but must not duplicate a maintained semantic implementation.

Form inputs are text until decoded. Loading, success, failure and stale responses have explicit constructors. The latest request ID policy prevents an old response from overwriting a newer result. Cancellation requests do not imply the server rolled back a write.

### Server source

`Server.Main` assembles the router, configuration and capabilities. `Server.Inventory` validates requests, checks authorization through a declared provider, executes a transaction operation and encodes responses. Secrets are supplied at the server boundary. The example must not implement home-grown password cryptography or label an auth adapter proved merely because its signature is typed.

`Server.Store` describes isolation/conflict/retry behavior and identifies the driver/version used. Verified state-transition reasoning is explicitly conditional on the storage model until that adapter relationship is established.

### Release output

A browser bundle, service package, typed client package, source maps and assurance manifest. Tests cover bad requests, stale results, cancelled navigation, transaction conflicts, denied access, startup failure and a deliberate false domain contract.

Every application-owned module is ordinary `.ps`/`.lean`, with optional markup only for the view. That is the target full-app acceptance demonstration—not a claim that it runs today.

## 5. Native UI versus React interoperation

The recommended native authoring model uses explicit state/messages and pure view construction. This makes state transitions testable and gives proofs an identifiable subject. It does not require users to learn a full functional UI theory before writing a button; project templates and ordinary helper APIs should hide routine boilerplate without hiding meaning.

A bounded React adapter can render or embed these components in existing TS apps. Imported React components use reviewed props/events interfaces. React hook and lifecycle behavior remains an adapter obligation; native PSC code must not pretend a hook call is an arbitrary pure function. [E01–E02](RESEARCH_SOURCES.md#application-and-javascript-platform)

Do not build an entirely new DOM engine, React implementation and server framework simultaneously for the first release. Prove the native API useful with one supported renderer, then add alternatives against the same documented view/event contract.

## 6. SSR, hydration and framework boundaries

SSR needs deterministic initial rendering, a specified state serialization format, stable keys, explicit client-only capabilities and an initialization protocol. React's hydration documentation requires server/client content correspondence; this is a concrete adapter test, not something guaranteed by typing a view. [E03](RESEARCH_SOURCES.md#application-and-javascript-platform)

Next.js Server Components introduce framework compilation and serialization constraints. They require a dedicated integration profile; producing ESM or React elements is not sufficient evidence of support. Mark unsupported framework transforms rather than generating misleading directives. [E04](RESEARCH_SOURCES.md#application-and-javascript-platform)

SSR/hydration is P1, but the plain browser/service app is P0. Pure server rendering can be used first without promising incremental hydration semantics.

## 7. Builds, assets and development latency

Provide a Vite plugin or compatible integration for the selected profile, source maps back to original `.ps`/`.lean`/`.psx`, CSS/assets, dependency invalidation and a useful overlay. Vite's own documentation separates TS transformation from full type checking; similarly, development output must visibly distinguish provisional compilation from verified release. [E05](RESEARCH_SOURCES.md#application-and-javascript-platform)

HMR is an explicit development mode. Preserve state only when its version/schema compatibility is justified; otherwise reset. A code or spec change invalidates affected proof evidence. Do not present stale green proof badges while executing newer code.

Measure cold startup, warm edits, rebuild size, diagnostic latency, browser startup, memory and clean production builds. Set budgets from measured baselines rather than inventing favorable numbers in the spec.

## 8. Adoption stages

Support three paths: consume one PSC package from TS; replace one feature including its UI/API modules; author a complete app from the supported template. Each path must have maintained examples and an escape boundary that is explicit rather than infecting all domain types.

The ecosystem strategy is to become preferable for concrete work because of maintainability and guarantees. Market-share dominance is not a technical acceptance test and is not predicted by this design.
