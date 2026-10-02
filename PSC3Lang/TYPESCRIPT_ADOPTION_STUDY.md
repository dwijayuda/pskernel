# TypeScript developer workflows and PSC3 adoption design

**Research-informed proposal · draft 0.3. Syntax and grammar authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** The matrix records documented capabilities and proposed responses, not population feature-frequency measurements or implemented PSC support.

## 1. Adoption hypothesis

Developers work with data, libraries, UI, async state, diagnostics and deployment. TypeScript/framework documentation demonstrates these tasks. PSC3 should combine the v0.7 TypeScript-friendly surface and Lean semantics with coherent libraries, tooling and checkable guarantees. Adoption is a hypothesis to test, not a result established by familiar keywords. [T01–T16,E01–E08](RESEARCH_SOURCES.md)

Use admitted v0.7 calls, aliases and braced forms plus inherited Lean records, inductives, polymorphism, functions and effects. Generate schemas/adapters for foreign structural APIs rather than copy structural subtyping into the logical foundation. The previous proposal that required stock-Lean-only `.ps` is withdrawn.

## 2. Classification

**Source** means an admitted v0.7 L/D/E mechanism. **Library**, **tool**, **extension** and **boundary** distinguish ordinary definitions, tooling, explicitly unregistered experimental grammar and foreign behavior. P0 is a first-app target, P1 follows and P2 is experimental/later. Priorities are design judgments, not usage statistics.

## 3. Feature-to-design matrix

| ID | Documented TypeScript/JS workflow | PSC3 response | Layer / priority | Test that matters |
|---|---|---|---|---|
| TS01 | Local inference [T01] | Expected-type/local inference; public signatures by convention. | Source/tool P0 | Inferred types remain inspectable after refactoring. |
| TS02 | Generic functions [T03,T05] | Dependent/universe-polymorphic functions with inherited implicit binders; v0.7 parameter decoration. | Source P0 | `map` inference without manual generic plumbing. |
| TS03 | Contextual callbacks [T03] | `fun` lambdas with contextual types inside native or D-CALL expressions. | Source/tool P0 | Callback inference; reject JS arrow syntax as base PSC. |
| TS04 | Object/interface DTOs [T04] | Nominal `structure ... where { ... }`; generated codecs and TS export interfaces. | Source/library P0 | Nested responses decoded, not merely cast. |
| TS05 | Optional properties [T04,T15] | `Option` fields; richer foreign-presence type when necessary; no native `field?: T` rule. | Library/boundary P0 | Missing, undefined and null not collapsed accidentally. |
| TS06 | Discriminated unions [T02] | `inductive ... where { ... }` and exhaustive `match ... with { ... }`. | Source P0 | New constructor forces relevant cases. |
| TS07 | Control-flow narrowing [T02] | Native patterns and dependent branch evidence where supported. | Source/tool P0 | Unchecked predicates cannot fabricate refined values. |
| TS08 | Destructuring [T03,T04] | Native patterns/projections and options records; D-CALL does not extend patterns. | Source P0 | Refutable patterns need an explicit failure context. |
| TS09 | Immutable object updates [T04] | Inherited `{ value with field := replacement }`. | Source P0 | Changed index cannot retain invalid dependent data. |
| TS10 | Defaults [T03] | Supported native default binders and visible inserted expressions. | Source P0 | Dependencies and evaluation order tested. |
| TS11 | Optional/rest arguments [T03] | Options records, Array/List arguments, foreign variadic adapters. | Library/boundary P0/P1 | Omission differs from undefined when required. |
| TS12 | Method-style APIs [T03,T04] | Generalized field notation and admitted adjacent calls such as `users.map(fun u => u.name)`. | Source/library P0 | Same resolved meaning after canonical lowering. |
| TS13 | Overloads [T03] | Named functions or inductive inputs; bounded foreign overload selection. | Boundary/tool P1 | Ambiguity is a diagnostic, not `any`. |
| TS14 | Generic constraints [T05] | Inherited typeclasses or explicit dictionaries. | Source P0 | Imported instance influence is explained. |
| TS15 | `keyof`/indexed access [T04,T09] | Finite schemas and generated accessors. | Library/tool P1 | Unknown keys rejected without dynamic proof data. |
| TS16 | Mapped utilities [T06,T09] | Generated patch/input/output structures. | Library/tool P1 | Optional/presence semantics preserved. |
| TS17 | Conditional types/`infer` [T07] | Bounded importer specialization; owned dependent functions. | Tool P1 | Unsupported type computation fails explicitly. |
| TS18 | Template-literal types [T08] | Typed routes/keys and parsers with round-trip specifications. | Library/tool P1 | Runtime strings validate before refinement. |
| TS19 | `satisfies` [T14] | Expected-type checks and explicit schema membership; no invented syntax. | Source/tool P1 | No new unchecked cast or structural assignability. |
| TS20 | `as`/non-null assertions [T01] | Decoding, evidence or explicit foreign assumptions. | Boundary P0 | Invalid shapes cannot enter verified DTOs. |
| TS21 | `unknown`/dynamic payload [T01] | Opaque JS value or data-only JSON, then codecs. | Boundary/library P0 | Dynamic values cannot inhabit arbitrary logical types. |
| TS22 | Async/Promises [E07,E12] | Proposed `Psc.Async` library and Promise adapter; no `async function` keyword in the base grammar. | Library/boundary P0 | Start/rejection/cancellation/cleanup traces. |
| TS23 | Error recovery [T03,E06] | Native `Except ε α` and effects, with separate unexpected foreign failures. | Source/library P0 | Non-Error throws and rejection reasons are covered. |
| TS24 | Collections [T01,T05] | Native data and law-governed collection APIs. | Library P0 | Bounds, ordering and iteration conformance. |
| TS25 | JSON/validation [E06] | Shared Codec/Schema definitions, not trust in casts. | Library/tool P0 | Malformed values report field paths. |
| TS26 | Typed endpoints [E08] | Shared input/output/error schemas generate client/server interfaces. | Library/tool P0 | Runtime validation; no inferred remote correctness. |
| TS27 | Query/cache state [E07] | Inductive state, request IDs and invalidation policy. | Library P0 | Stale responses do not overwrite newer state. |
| TS28 | React props/events [E01] | Ordinary view APIs and bounded adapters; `.psx` is optional. | Library/extension P0/P1 | Plain `.ps` and `.lean` can author components. |
| TS29 | JSX composition [T11] | Explicit experimental `.psx` dialect lowering to admitted library expressions. | Extension P1 | Reference/profile separation, expansion and diagnostics. |
| TS30 | Hooks/state/reducers [E01,E02] | Model/update/view libraries; generated wrapper obeys lifecycle rules. | Library/boundary P0 | Stable subscriptions and disposal. |
| TS31 | DOM handles [E13] | Opaque identity-bearing handles and effects. | Boundary P0 | Aliasing and listener lifetimes. |
| TS32 | Server/client boundaries [E04] | Entry capabilities and serialization-safe DTOs. | Tool/library P1 | Client graph excludes server secrets/capabilities. |
| TS33 | SSR/hydration [E03] | Defined view/state serialization and hydration adapters. | Library/tool P1 | Initial trees/key policies agree. |
| TS34 | ESM/package exports [T12,E09] | Native logical `import` graph mapped to target ESM exports, not ESM `.ps` grammar. | Tool P0 | Conditional resolution recorded per target. |
| TS35 | Dev server/HMR [E05] | Vite-compatible integration with reset/migration policy. | Tool P0 | Stale proofs and incompatible retained state invalidated. |
| TS36 | CSS/assets [E05] | Typed asset manifests and stylesheet adapters. | Tool P0 | Paths, hashing, loading and escaping. |
| TS37 | Classes/`this` [T03,T10] | Owned structures/functions; receiver-preserving foreign calls. | Source/boundary P0 | Detached calls do not lose required receivers. |
| TS38 | Decorators [T16] | Selected derives/registries and explicitly profiled extensions. | Extension P2 | No decorator execution becomes proof authority. |
| TS39 | Fast editor feedback | Shared incremental source/lowering/elaboration information. | Tool P0 | Edit latency and source-map fidelity measured. |
| TS40 | `number`/bigint [T01,E11] | Exact Nat/Int, explicit numeric types and checked conversions. | Source/boundary P0 | Ranges, NaN, signed zero and large integers. |
| TS41 | Async iteration/streams [E10,E12] | Library backpressure/cancellation contracts. | Library/boundary P1 | Demand bounds, late emissions and disposal. |
| TS42 | Package publishing [T12,E09] | ESM + `.d.ts` + maps + optional proof bundles. | Tool P0 | Clean TypeScript and PSC consumers. |

## 4. Concrete adoption choices

### Data first, not imported type-level machinery first

Implement the tasks behind advanced TS types before copying operators. A schema can generate endpoints, codecs and proof statements without adding conditional-type evaluation to the kernel. Foreign type computations may require bounded import-time specialization.

Schemas have specified interpretations. Generated code is not trusted by origin. Require codec laws and malformed-input tests. A data decoder must not secretly execute arbitrary getters or prototype behavior as though inspecting immutable logical data; choose copying, rejection or explicit effectful reads.

### Familiar APIs, accurate v0.7 syntax

Teach both surfaces explicitly:

```proofscript
function names(users : List User) : List String :=
  users.map(fun u => u.name);
```

Canonical/native Lean:

```lean
def names (users : List User) : List String :=
  users.map (fun u => u.name)
```

The decorated surface is not a stock-Lean file alias. Preserve call adjacency and tuple distinctions. Retain `:=`, `fun`, `where`, `with` and native patterns; do not replace them with bare block bodies, JS lambdas, optional chaining or invented named-argument syntax.

For a proposed `client.getUser(id)` API, inferred response/error types, decoding and diagnostics matter alongside admitted familiar spelling. The API remains a proposal until its implementation/profile is tested.

### Structural convenience at the edge

Nominal domain records keep unrelated logical types distinct. Foreign structural views remain opaque/effectful where identity or mutation exists. Copied DTOs are owned snapshots, not identity-preserving handles.

## 5. Limits

No automatic migration of arbitrary TypeScript projects, all-npm support, elimination of runtime validation, free Promise/Lean Task equivalence, or inference that a typed foreign implementation satisfies its behavior.

P0 includes actual application/platform work, not only source syntax. `.psx`, later grammar changes and unsupported upstream features stay separately identified rather than entering v0.7 by example.

## 6. Adoption experiments

Compare typed forms/decoders, cancellable search UI, server endpoints, package exports, union changes and added contracts across TypeScript, v0.7 `.ps` and supported native `.lean`. Where studied, add an explicit `.psx` condition rather than confounding base syntax and markup.

Record setup, comprehension, annotations, callback debugging, unsupported interop, proof effort, source maps, latency and change repair. Distinguish learning costs from library defects. No participant study was run in this repair.

Success means replacing a useful module without more glue than business logic and adding guarantees without duplicating the program—not winning a feature-count table.
