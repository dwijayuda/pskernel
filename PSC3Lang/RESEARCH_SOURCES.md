# Research sources and evidence register

**Accessed/reviewed for this design on 3 October 2026.** Primary documents support factual observations; proposed PSC choices are design judgments. Live manuals are not frozen compatibility contracts. Exact upstream source is used for the selected Lean parser/tag facts. No population-level TypeScript feature statistics are asserted.

## Repository baselines

- **R01 — PSC2 reference.** [Pinned file](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/PSC2%20Lang/PSC2_LANGUAGE_REFERENCE.md). Main snapshot; draft feature surface, source forms, `.psx` history and open freeze obligations. Blob `836529be4d44c24ac177fc82bd870c75eebc06e3`.
- **R02 — PSC1 grammar.** [Pinned file](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/PSC1%20Lang/SYNTAX_AND_GRAMMAR.md). Inherited adjacent-call and tuple distinction; migration must preserve old interpretation.
- **R03 — PSC1 runtime/effects.** [Pinned file](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/PSC1%20Lang/SEMANTICS_RUNTIME_AND_EFFECTS.md). Semantic layering and unresolved scalar operation matrix; do not attribute all gaps to PSC2 alone.
- **R04 — PSC2 verification and feature research.** [Contracts](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/PSC2%20Lang/CONTRACTS_AND_VERIFICATION.md), [feature matrix](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/PSC2%20Lang/FEATURE_RESEARCH_MATRIX.md). Prior plans, not implemented capability evidence or representative usage statistics.
- **R05 — Minimal self-host architecture snapshot.** [Architecture](https://github.com/dwijayuda/pskernel/blob/90d02086146fce06df6d0a720e50f340adcbf52a/psc15selfhost/ARCHITECTURE.md), [status](https://github.com/dwijayuda/pskernel/blob/90d02086146fce06df6d0a720e50f340adcbf52a/psc15selfhost/STATUS.md). A previously reviewed workstream snapshot distinguishing admission-ready preparation from true checking; not all-branch current completion evidence.
- **R06 — Owned-kernel architecture snapshot.** [Pinned architecture](https://github.com/dwijayuda/pskernel/blob/78a6a3d4759b16230a44fcb57cd76a7fac426b5a/psc15selfhost/packages/pskernel-core/ARCHITECTURE.md). Independent checking, exact identity, assumptions, private checked artifacts and checker-build trust; design status must not be mistaken for implementation.

## TypeScript language and tooling

- **T01 — [Everyday Types](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html).** Primitive/object/function/union vocabulary, inference and assertions. Used to identify tasks and migration concepts, not frequency.
- **T02 — [Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html).** Guards, discriminated unions and exhaustive handling; informs native pattern/refinement UX.
- **T03 — [More on Functions](https://www.typescriptlang.org/docs/handbook/2/functions.html).** Callbacks, generic functions, optional/rest parameters and overloads; informs typed API ergonomics.
- **T04 — [Object Types](https://www.typescriptlang.org/docs/handbook/2/objects.html).** Structural data, optional/readonly fields and object composition; not a proof of runtime immutability.
- **T05 — [Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html).** Polymorphic APIs and constraints; informs inference and dictionary design.
- **T06 — [Mapped Types](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html).** Type-derived shapes; motivates schema-derived interfaces rather than core TS subtyping.
- **T07 — [Conditional Types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html).** Type-level branching/inference; motivates explicit importer limits.
- **T08 — [Template Literal Types](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html).** Typed string families; motivates route/key libraries with runtime parsing.
- **T09 — [Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html).** API transformations such as partial/selected records; informs schema projections.
- **T10 — [Type Compatibility](https://www.typescriptlang.org/docs/handbook/type-compatibility.html).** Structural compatibility and deliberate soundness tradeoffs; not a model to copy into the logical core.
- **T11 — [JSX](https://www.typescriptlang.org/docs/handbook/jsx.html).** Typed UI expressions and component checking; motivates an optional explicit UI source layer, not arbitrary TSX compatibility.
- **T12 — [Modules Reference](https://www.typescriptlang.org/docs/handbook/modules/reference.html).** Module and resolution behavior; supports deployment-specific import identities.
- **T13 — [erasableSyntaxOnly](https://www.typescriptlang.org/tsconfig/erasableSyntaxOnly.html).** Restricted emitted-TS discipline. The compiler option is not a preservation theorem.
- **T14 — [TypeScript 4.9 release notes: satisfies](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html).** Constraint checking without the same inference change as a blanket annotation; a historical feature source, not a current-version pin.
- **T15 — [exactOptionalPropertyTypes](https://www.typescriptlang.org/tsconfig/exactOptionalPropertyTypes.html).** Optional-property checking distinction; foreign omission semantics still need runtime modelling.
- **T16 — [Decorators](https://www.typescriptlang.org/docs/handbook/decorators.html).** The page explicitly distinguishes its legacy experimental model from newer support. Framework decorator modes require exact version/transform profiles; this draft adopts none by default.

## Application and JavaScript platform

- **E01 — [React: Using TypeScript](https://react.dev/learn/typescript).** Concrete props, events, children and state/reducer typing examples. Framework practice evidence, not population statistics.
- **E02 — [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks).** Lifecycle/call-placement constraints for a React adapter; an arbitrary function translation is insufficient.
- **E03 — [hydrateRoot](https://react.dev/reference/react-dom/client/hydrateRoot).** Hydration correspondence requirements and diagnostics. Does not verify a PSC view or renderer.
- **E04 — [Next.js server and client components](https://nextjs.org/docs/app/getting-started/server-and-client-components).** Framework-specific boundaries and serialization; ordinary ESM output is not automatically this integration.
- **E05 — [Vite Features](https://vite.dev/guide/features).** TS transformation, HMR, CSS/assets and development workflow. Useful integration requirements, not compiler-proof evidence.
- **E06 — [Zod Basics](https://zod.dev/basics).** Runtime schema parsing and typed error handling. Motivates Codec ergonomics without equating runtime tests and theorem proofs.
- **E07 — [TanStack Query TypeScript](https://tanstack.com/query/latest/docs/framework/react/typescript).** Inference for async data/error state and narrowing. Motivates explicit query-state libraries.
- **E08 — [tRPC type inference helpers](https://trpc.io/docs/client/react/infer-types).** Shared endpoint input/output inference. Motivates one schema source for clients and services.
- **E09 — [Node packages](https://nodejs.org/api/packages.html).** ESM/CJS, package exports/imports and resolution conditions; must be bound by deployment profile.
- **E10 — [Fetch Standard](https://fetch.spec.whatwg.org/).** Web request/response and abort-related integration context. A typed wrapper does not verify the network or server.
- **E11 — [ECMAScript data types and values](https://tc39.es/ecma262/multipage/ecmascript-data-types-and-values.html).** Numbers, BigInt, strings, null/undefined and object distinctions. Live specification; no future feature is implicitly included in the generated subset.
- **E12 — [ECMAScript control abstraction objects](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-promise-objects).** Promise execution/settlement and asynchronous interfaces. Not the definition of proposed Psc.Async.
- **E13 — [Web IDL](https://webidl.spec.whatwg.org/).** Browser interface/type conversion context. Generated DOM adapters need their own bounded support and runtime tests.

## Lean and logical foundations

- **L01 — [Lean v4.34.1 release notes](https://lean-lang.org/doc/reference/latest/releases/v4.34.1/).** Dated September 24, 2026; recommends the patch for runtime fixes. Used to motivate a proposed reference update, not to claim PSC compatibility.
- **L02 — [Pinned tag resolution](https://api.github.com/repos/leanprover/lean4/git/ref/tags/v4.34.1).** Resolved to `5045d0056413266e57c625dcd7c365b10e377c52` during this review.
- **L03 — [Pinned declaration parser](https://github.com/leanprover/lean4/blob/5045d0056413266e57c625dcd7c365b10e377c52/src/Lean/Parser/Command.lean).** Inspected contract rule with one optional requires and one optional ensures clause.
- **L04 — [Pinned intrinsic verification tests](https://github.com/leanprover/lean4/blob/5045d0056413266e57c625dcd7c365b10e377c52/tests/elab/intrinsicVerification.lean).** Inspected imports/options, generated specification checks, invariants and assert/assert! distinction. Read, not locally executed.
- **L05 — [Recursive Definitions](https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/).** Total recursion, partial definitions and runtime/logical separation. Live explanatory source; proposed-pin cases need exact conformance tests.
- **L06 — [IO](https://lean-lang.org/doc/reference/latest/IO/).** Logical and executable views of effects and sequencing. Does not specify the new portable Async library.
- **L07 — [Instance Synthesis](https://lean-lang.org/doc/reference/latest/Type-Classes/Instance-Synthesis/).** Native search behavior, priority/order and inference context; restrictions must not change selected meanings.
- **L08 — [Validating a Lean Proof](https://lean-lang.org/doc/reference/latest/ValidatingProofs/).** Statement/definition identity and independent checking boundaries.
- **L09 — [The Type System](https://lean-lang.org/doc/reference/latest/The-Type-System/).** Dependent terms, proof evidence and conversion; a conceptual reference, not PSC's implementation proof.
- **L10 — [Notations and Macros](https://lean-lang.org/doc/reference/latest/Notations-and-Macros/).** Imported syntax, hygiene and expansion facilities; optional extensions are not stock syntax.
- **L11 — [Natural Numbers](https://lean-lang.org/doc/reference/latest/Basic-Types/Natural-Numbers/).** Native exact-number operations, including natural subtraction; primitive bindings still need pin-specific evidence.
- **L12 — [Strings](https://lean-lang.org/doc/reference/latest/Basic-Types/Strings/).** Native string/position API context, not interchangeable with JS code-unit operations.
- **L13 — [Integers](https://lean-lang.org/doc/reference/latest/Basic-Types/Integers/).** Native integer operation variants and sign/zero conventions; do not infer host equivalence from names.

## Engineering and design method

- **G01 — [Go at Google: Language Design in the Service of Software Engineering](https://go.dev/talks/2012/splash.article).** Original engineering motivations; use the discipline rather than copying Go's type system.
- **G02 — [Go FAQ](https://go.dev/doc/faq).** Design tradeoffs, clarity and orthogonality context.
- **G03 — [Go 1 compatibility](https://go.dev/doc/go1compat).** Explicit compatibility commitment and exceptions; informs a separate PSC edition/API/proof policy.
- **G04 — [Go proposal process](https://go.dev/s/proposal-process).** Significant changes receive recorded discussion/design review.
- **M01 — [PLIERS: A Process that Integrates User-Centered Methods into Programming Language Design](https://arxiv.org/abs/1912.04719).** Research process for language design with user-centered methods. No PSC study results are implied.

## Compilation and targets

- **C01 — [CompCert compiler overview and correctness](https://compcert.org/man/manual001.html).** Scoped behavioral preservation and trust boundaries. Results do not automatically transfer to PSC.
- **C02 — [Rust operator expressions](https://doc.rust-lang.org/reference/expressions/operator-expr.html).** Arithmetic/cast behavior and overflow concerns for faithful lowering.
- **C03 — [Rust wasm32-unknown-unknown target](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html).** Supported compilation route and platform limitations, distinct from a PSC direct-Wasm implementation.
- **C04 — [WebAssembly overview](https://webassembly.github.io/spec/core/intro/overview.html).** Decoding, validation and execution layers; validation is not source-contract preservation.

## Evidence-use limitations

Official docs demonstrate capabilities and intended semantics, not how often all TypeScript developers use them. Framework choices are illustrative and need exact dependency pins before an integration claim. Live manuals may change or contain newer material than the selected Lean pin. Selected source files and prior workstream snapshots are not an all-branch audit.

The only executed local experiments are documented in EXPERIMENTS.md. No external benchmark, participant result, complete library closure or new theorem is fabricated. The source register is a research aid, not a substitute for release conformance and independent evidence checking.
