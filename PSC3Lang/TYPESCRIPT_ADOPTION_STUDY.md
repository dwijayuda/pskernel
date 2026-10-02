# TypeScript developer workflows and PSC3 adoption design

**Research-informed proposal · draft 0.2.** The matrix records documented capabilities and proposed PSC responses. It is not a measured ranking of TypeScript feature frequency or a claim of implemented PSC support.

## 1. The adoption hypothesis

Developers choose a language inside a workflow: model API data, call libraries, render UI, handle asynchronous state, debug failures and ship changes. TypeScript's official examples and ecosystem documentation demonstrate these tasks. The hypothesis for PSC3 is that coherent libraries, tooling and checkable guarantees can compensate for learning native Lean syntax. This hypothesis must be tested; familiar keywords alone would not establish it. [T01–T16, E01–E08](RESEARCH_SOURCES.md)

The core translation strategy is not structural-type imitation. Use native records, inductives, polymorphism, functions and monadic composition; generate boundary schemas and adapters where foreign APIs need structural shapes. Preserve a stable Lean meaning and make migrations explicit.

## 2. Classification

**Native** means a proposed supported Lean mechanism; **library** means ordinary Lean definitions; **tool** means editor/build/generator work; **extension** means an explicit optional source capability; **boundary** means a foreign runtime model. Priority P0 is needed for a credible first app release, P1 follows the first app, P2 is experimental or later. Priority is a design judgment, not usage statistics.

## 3. Feature-to-design matrix

| ID | Documented TypeScript/JS workflow | PSC3 response | Layer / priority | Test that matters |
|---|---|---|---|---|
| TS01 | Inference for local values [T01] | Native expected-type/local inference; explicit public signatures by convention. | Native/tool P0 | Inferred type remains inspectable after refactoring. |
| TS02 | Generic functions [T03,T05] | Universe-polymorphic/dependent functions with implicit type arguments. | Native P0 | `map`/callback inference without manual generic plumbing. |
| TS03 | Contextually typed callbacks [T03] | Lean lambdas plus contextual expected types and code actions. | Native/tool P0 | Collection and event callbacks infer usable argument types. |
| TS04 | Object/interface DTOs [T04] | Nominal structures; generated codecs and TS structural interfaces at exports. | Native/library P0 | Nested API response decoded, not merely cast. |
| TS05 | Optional properties [T04,T15] | `Option` for intentional two-state application data; richer foreign presence type when required. | Library/boundary P0 | Missing, undefined and null not collapsed accidentally. |
| TS06 | Discriminated unions [T02] | Inductives and exhaustive `match`. | Native P0 | New constructor forces all relevant branches to be handled. |
| TS07 | Control-flow narrowing [T02] | Pattern refinement; dependent branch evidence where supported. | Native/tool P0 | No unchecked user predicate can fabricate a refined value. |
| TS08 | Destructuring [T03,T04] | Native patterns and projections; named options records. | Native P0 | Refutable patterns require a failure path. |
| TS09 | Immutable object updates [T04] | Native structure update with dependent fields checked. | Native P0 | Changing a length cannot retain invalid indexed data. |
| TS10 | Default parameters [T03] | Pinned native default binders; show inserted defaults. | Native P0 | Default dependency and evaluation tests. |
| TS11 | Optional/rest arguments [T03] | Options structures and Array/List arguments; explicit foreign variadic adapters. | Library/boundary P0/P1 | Omission differs from passing undefined when API requires it. |
| TS12 | Method-style APIs [T03,T04] | Native generalized field notation; library receiver positions designed for it. | Native/library P0 | Resolve the same method as the pinned Lean environment. |
| TS13 | Overloads [T03] | Named functions or inductive input; importer selects bounded disjoint foreign overloads. | Boundary/tool P1 | Ambiguous overload generates a diagnostic, not `any`. |
| TS14 | Generic constraints [T05] | Native typeclasses or explicit dictionaries; exact instance semantics. | Native P0 | Imported instance influence is explained. |
| TS15 | `keyof`/indexed access [T04,T09] | Finite schema descriptors and generated field lenses/accessors. | Library/tool P1 | Unknown keys rejected; no arbitrary dynamic property as proof data. |
| TS16 | Mapped utility types [T06,T09] | Schema projections for patch/input/output DTOs; ordinary generated types. | Library/tool P1 | Projection preserves optional/presence semantics. |
| TS17 | Conditional types and `infer` [T07] | Bounded import-time specialization; native dependent functions for owned code. | Tool P1 | Unsupported type computation stops import with explanation. |
| TS18 | Template-literal types [T08] | Typed route/key constructors and parsers with round-trip specs. | Library/tool P1 | Runtime string must validate before gaining a route type. |
| TS19 | `satisfies` [T14] | Expected-type checking, explicit schema membership checks, retained elaborated type display. | Native/tool P1 | Do not imply TS structural assignability or a new cast. |
| TS20 | `as`/non-null assertions [T01] | No unchecked analogue in the strict fragment; provide decoding, proof or explicit foreign assumption. | Boundary P0 | Invalid asserted shape cannot enter a verified DTO. |
| TS21 | `unknown`/dynamic payload [T01] | Opaque `Psc.Js.Value` or data-only JSON value, followed by codecs. | Boundary/library P0 | Dynamic values cannot be pattern-matched as arbitrary Lean types. |
| TS22 | Async functions/Promises [E07,E12] | New `Psc.Async` library and explicit Promise adapter; native Lean Task unchanged. | Library/boundary P0 | Start order, rejection, cancellation and cleanup traces. |
| TS23 | Error recovery [T03,E06] | `Except ε α` and standard typed effects; preserve unexpected foreign failure separately. | Native/library P0 | Rejected promise or thrown non-Error value is accounted for. |
| TS24 | Arrays/maps/sets [T01,T05] | Native data and stable collection APIs with lawful equality requirements. | Library P0 | Bounds, ordering and iteration conformance. |
| TS25 | JSON parsing and validation [E06] | Shared schema/Codec definitions, not trust in `JSON.parse` types. | Library/tool P0 | Decode malformed input; report field paths. |
| TS26 | Typed endpoints [E08] | One input/output/error schema generates client and server interfaces. | Library/tool P0 | Runtime route validates; static agreement is not remote correctness. |
| TS27 | Query/cache state [E07] | Inductive idle/loading/success/failure states, request IDs and explicit invalidation policy. | Library P0 | Stale response cannot overwrite newer state. |
| TS28 | React props/children/events [E01] | Typed view/component API; bounded React adapter; optional `.psx`. | Library/extension P0/P1 | Component can be authored without markup or raw TS glue. |
| TS29 | JSX composition [T11] | Explicit UI quotation extension lowering to ordinary constructors. | Extension P1 | Expansion parity and useful original-source diagnostics. |
| TS30 | Hooks/state/reducers [E01,E02] | Native model/update/view design; generated React wrapper obeys lifecycle constraints. | Library/boundary P0 | Stable subscriptions, no state updates after disposal. |
| TS31 | DOM handles [E13] | Opaque handles and effectful operations, not structurally assignable pure records. | Boundary P0 | Identity, ownership and listener lifetime tests. |
| TS32 | Server/client boundaries [E04] | Explicit entry capabilities and serialization-safe shared DTOs. | Tool/library P1 | Client bundle cannot depend transitively on server secrets/capabilities. |
| TS33 | SSR/hydration [E03] | Deterministic view/state serialization with explicit hydration adapter. | Library/tool P1 | Initial server/client trees and key policies match. |
| TS34 | ESM/package exports [T12,E09] | Explicit logical module graph mapped to pinned ESM package interfaces. | Tool P0 | Conditional export resolution recorded per deployment. |
| TS35 | Development server/HMR [E05] | Vite integration or compatible plugin contract; state migration/reset protocol. | Tool P0 | Stale proofs and incompatible preserved state invalidated. |
| TS36 | CSS/assets [E05] | Typed asset manifest and stylesheet/module adapters. | Tool P0 | Content hashes, paths, production loading and escaping tested. |
| TS37 | Classes/`this` [T03,T10] | Structures/functions for owned data; receiver-preserving foreign handle methods. | Native/boundary P0 | Detached call does not lose foreign receiver accidentally. |
| TS38 | Decorator/procedural ecosystems [T16] | Selected derive/registry plugins; framework-specific transforms explicitly profiled. | Extension P2 | No arbitrary decorator execution treated as proof authority. |
| TS39 | Fast editor feedback | Shared incremental parser/elaborator, diagnostics, rename and code actions. | Tool P0 | Measure p50/p95 edit latency on representative projects. |
| TS40 | JS `number` and bigint [T01,E11] | Explicit numeric types and checked boundary conversions; exact Nat/Int. | Native/boundary P0 | Large integers, NaN, signed zero and range errors. |
| TS41 | Promise/async iteration and streams [E10,E12] | Stream library with backpressure and cancellation contract. | Library/boundary P1 | Bounded demand, late emissions and disposal. |
| TS42 | Publishing reusable packages [T12,E09] | ESM + `.d.ts` + source maps + optional proof bundle and metadata. | Tool P0 | Clean TS consumer and clean PSC consumer installation. |

## 4. Concrete adoption choices

### Data first, not type-level metaprogramming first

The proposal deliberately implements the *task* behind advanced TypeScript types before copying each type operator. A route schema can generate endpoint types, codecs and proof statements without adding a TS conditional-type evaluator to the PSC kernel. Type-level computations in a foreign declaration may still require bounded specialization in the importer.

Schemas are ordinary data with a specified interpretation. Generated code is not trusted merely because it came from a schema. Require codec laws and test malformed inputs. A data-only decoder must not execute arbitrary getters or prototype behavior while pretending it only inspected a mathematical record; the foreign boundary profile decides whether to copy, reject or deliberately evaluate such objects.

### Familiar APIs, honest syntax

Teach `users.map (fun u => u.name)`, options records, `match`, `do` and `Except` using the actual native forms. Do not teach PSC2 comma-call sugar and silently rewrite it in the new edition. Offer compiler-assisted migration examples and a TS-to-PSC glossary.

For a proposed API such as `client.getUser id`, the primary value is the inferred response and error type, decoded input/output and useful diagnostic. A TypeScript-like spelling alone cannot supply those properties.

### Structural convenience belongs at the edge

Nominal domain structures prevent accidental mixing of unrelated logical data. Typed foreign views may expose a structural JS API, but they remain effectful/opaque when mutation or accessors are involved. A copied DTO is a new owned value; it is not an identity-preserving reference to the original object.

## 5. What not to promise

No automatic conversion of an arbitrary TypeScript project, no all-npm compatibility, no universal elimination of runtime validators, no free conversion of Promises into native Lean Task, and no inference that a well-typed foreign implementation satisfies its declared behavior.

The gap between a verified pure function and a complete browser/server app is real. P0 includes the platform work needed to cross that gap, while P1/P2 are separately gated rather than hidden in a core-language freeze.

## 6. Adoption experiments to run

Compare TypeScript and PSC3 implementations of: a typed form and decoder; a cancellable search UI with stale-result prevention; a server endpoint with structured errors; a reusable package; a refactoring that changes a discriminated union; and a contract added to a state transition.

Record setup time, comprehension mistakes, annotations, callback/type debugging effort, unsupported interop, proof effort, source-map fidelity, build latency and change repair. Separate costs of learning new syntax from library/API defects. No such participant study was run in this pass.

Success means a developer can replace an entire small app module without writing more glue than business logic, and can add guarantees without duplicating the program. It does not mean winning a feature-count table.
