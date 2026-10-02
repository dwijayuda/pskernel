# Research sources and evidence register

**V0.7 syntax repair · 3 October 2026.** The controlling repository references below were reviewed for this correction. Existing external references are retained as draft-0.2 research records, not claimed newly revalidated. Design recommendations are not empirical results; live manuals do not override pinned source grammar.

## Controlling ProofScript v0.7 syntax and grammar

- **V07 — Main reference.** [ProofScript Language Reference v0.7.0](../study/proofscript-language-reference-v0.7.0/ProofScript_Language_Reference_v0.7.0_authoritative_draft.md). Pinned repository snapshot `65369c75c7b63124f1ba7f2289e573181db281f0`, blob `8b4097363c5ade7d594b66706b94dff62400ff53`. Controls syntax, L/D/E/X classes, ownership and canonical lowering. §§0–7 define the model; §§8–10 declarations/binders/calls; §§12–18 data/pattern/proof/effect categories; §§21–23 resolution/commands/extensions; §27 source/package profiles; §§28–33 evidence and corpus. The reference reports S1 specification, not completed production or parser/lowering proof.
- **V07-A — Surface registry.** [Appendix A](../study/proofscript-language-reference-v0.7.0/appendices/A-complete-feature-registry.md), blob `5c577000709646b37017b692c21ae66f1c6ebf84`. Enumerates admitted features, alias restrictions and future-registration obligations.
- **V07-M — Machine registry.** [feature-registry.json](../study/proofscript-language-reference-v0.7.0/conformance/feature-registry.json). Implementation-facing reference identity; no claim that its complete suite was run here.
- **V07-C — Conformance corpus.** [Conformance README](../study/proofscript-language-reference-v0.7.0/conformance/README.md). Positive/negative/lowering cases and limitations. These are future execution inputs, not tests passed by this repair.
- **Local authority map.** [SYNTAX_AND_GRAMMAR_V07.md](SYNTAX_AND_GRAMMAR_V07.md) maps these rules to every PSC3 document. The v0.7 canonical baseline is Lean 4.34.0 at `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`; older PSC3 prose or live later manuals cannot silently replace it.

## Repository baselines

- **R01 — PSC2 reference.** [Pinned file](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/PSC2%20Lang/PSC2_LANGUAGE_REFERENCE.md). Draft features and history; blob `836529be4d44c24ac177fc82bd870c75eebc06e3`. Historical context, not authority over v0.7 syntax.
- **R02 — PSC1 grammar.** [Pinned file](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/PSC1%20Lang/SYNTAX_AND_GRAMMAR.md). Adjacent-call/tuple distinctions also required by v0.7, not removed in this corrected design.
- **R03 — PSC1 runtime/effects.** [Pinned file](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/PSC1%20Lang/SEMANTICS_RUNTIME_AND_EFFECTS.md). Semantic layering and open scalar matrix; no implication that every implementation shares every gap.
- **R04 — PSC2 contracts/research.** [Contracts](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/PSC2%20Lang/CONTRACTS_AND_VERIFICATION.md), [feature matrix](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/PSC2%20Lang/FEATURE_RESEARCH_MATRIX.md). Plans, not implemented capability or population statistics.
- **R05 — Minimal bootstrap snapshot.** [Architecture](https://github.com/dwijayuda/pskernel/blob/90d02086146fce06df6d0a720e50f340adcbf52a/psc15selfhost/ARCHITECTURE.md), [status](https://github.com/dwijayuda/pskernel/blob/90d02086146fce06df6d0a720e50f340adcbf52a/psc15selfhost/STATUS.md). Admission-ready versus real checking; not all-branch current evidence.
- **R06 — Owned-kernel design.** [Pinned architecture](https://github.com/dwijayuda/pskernel/blob/78a6a3d4759b16230a44fcb57cd76a7fac426b5a/psc15selfhost/packages/pskernel-core/ARCHITECTURE.md). Independent checking, exact identities, assumptions and build trust; design is not implementation.
- **R07 — Repair starting point.** `docs/psc3-language-design-20261003` at `b07a5ae10535ebfc93350fe049b931876fd6d4f1`: 21 existing design files. The byte-identical `.ps`/`.lean` rule in that draft is intentionally corrected, not treated as a v0.7 feature.

## TypeScript language and tooling

- **T01 — [Everyday Types](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html).** Primitive/object/function/union concepts, inference and assertions; task evidence, not usage frequency.
- **T02 — [Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html).** Guards/unions/exhaustiveness as migration motivations.
- **T03 — [More on Functions](https://www.typescriptlang.org/docs/handbook/2/functions.html).** Callbacks, generics, optional/rest parameters and overloads; no authority over PSC grammar.
- **T04 — [Object Types](https://www.typescriptlang.org/docs/handbook/2/objects.html).** Structural/optional/readonly data, not runtime immutability proof.
- **T05 — [Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html).** Polymorphic APIs and constraints.
- **T06 — [Mapped Types](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html).** Schema-generation motivation rather than copied foundational subtyping.
- **T07 — [Conditional Types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html).** Importer specialization and limits.
- **T08 — [Template Literal Types](https://www.typescriptlang.org/docs/handbook/2/template-literal-types.html).** Typed string families and parsing needs.
- **T09 — [Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html).** Input/patch/output transformations.
- **T10 — [Type Compatibility](https://www.typescriptlang.org/docs/handbook/type-compatibility.html).** Structural compatibility/tradeoffs, not the PSC logical foundation.
- **T11 — [JSX](https://www.typescriptlang.org/docs/handbook/jsx.html).** Typed UI motivation, not arbitrary TSX or v0.7 syntax acceptance.
- **T12 — [Modules Reference](https://www.typescriptlang.org/docs/handbook/modules/reference.html).** Target/dependency resolution, not ESM source syntax for `.ps`.
- **T13 — [erasableSyntaxOnly](https://www.typescriptlang.org/tsconfig/erasableSyntaxOnly.html).** Target TS discipline, not preservation proof.
- **T14 — [TypeScript 4.9: satisfies](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html).** Historical type-checking feature, not a current-version pin or new PSC operator.
- **T15 — [exactOptionalPropertyTypes](https://www.typescriptlang.org/tsconfig/exactOptionalPropertyTypes.html).** Optional-property distinction; runtime omission remains a boundary model.
- **T16 — [Decorators](https://www.typescriptlang.org/docs/handbook/decorators.html).** Legacy/new-mode distinction requires exact transform profiles; no native PSC decorator semantics adopted.

## Application and JavaScript platform

- **E01 — [React TypeScript](https://react.dev/learn/typescript).** Props/events/children/state workflows, not population statistics.
- **E02 — [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks).** Adapter lifecycle/call constraints.
- **E03 — [hydrateRoot](https://react.dev/reference/react-dom/client/hydrateRoot).** SSR/client correspondence, not a verified PSC renderer.
- **E04 — [Next.js server/client components](https://nextjs.org/docs/app/getting-started/server-and-client-components).** Framework-specific transforms/serialization.
- **E05 — [Vite Features](https://vite.dev/guide/features).** TS transformation, HMR, CSS/assets; tooling requirements, not semantic proof.
- **E06 — [Zod Basics](https://zod.dev/basics).** Runtime validation and typed errors, distinct from theorem evidence.
- **E07 — [TanStack Query TypeScript](https://tanstack.com/query/latest/docs/framework/react/typescript).** Async state/error inference.
- **E08 — [tRPC inference](https://trpc.io/docs/client/react/infer-types).** Shared endpoint type derivation.
- **E09 — [Node packages](https://nodejs.org/api/packages.html).** ESM/CJS/exports/conditions as target profile inputs.
- **E10 — [Fetch Standard](https://fetch.spec.whatwg.org/).** Requests/responses/abort context; not proof of network behavior.
- **E11 — [ECMAScript values](https://tc39.es/ecma262/multipage/ecmascript-data-types-and-values.html).** Number, BigInt, text, null/undefined and object distinctions. Live reference; not implicit future-feature inclusion.
- **E12 — [ECMAScript Promise objects](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-promise-objects).** Foreign execution/settlement semantics, not the definition of Psc.Async.
- **E13 — [Web IDL](https://webidl.spec.whatwg.org/).** Browser conversion/interface context; adapters need their own coverage.

## Lean and logical foundations

**Version limitation:** V07 selects 4.34.0. L01–L04 are retained from the earlier 4.34.1 upgrade study; they are not current v0.7 grammar authority or newly executed evidence.

- **L01 — [Lean 4.34.1 notes](https://lean-lang.org/doc/reference/latest/releases/v4.34.1/).** Earlier patch/runtime-fix research; upgrade candidate only.
- **L02 — [4.34.1 tag](https://api.github.com/repos/leanprover/lean4/git/ref/tags/v4.34.1).** Earlier reported resolution `5045d0056413266e57c625dcd7c365b10e377c52`; existing pins unchanged.
- **L03 — [4.34.1 declaration parser](https://github.com/leanprover/lean4/blob/5045d0056413266e57c625dcd7c365b10e377c52/src/Lean/Parser/Command.lean).** Prior observation of optional contract clauses; recheck selected baseline before a conformance claim.
- **L04 — [4.34.1 intrinsic tests](https://github.com/leanprover/lean4/blob/5045d0056413266e57c625dcd7c365b10e377c52/tests/elab/intrinsicVerification.lean).** Prior read of imports/options/specification/assert behavior, not local execution.
- **L05 — [Recursive Definitions](https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/).** Live partiality/termination explanation; exact-pin behavior is separately gated.
- **L06 — [IO](https://lean-lang.org/doc/reference/latest/IO/).** Logical/runtime effect distinction, not new Async semantics.
- **L07 — [Instance Synthesis](https://lean-lang.org/doc/reference/latest/Type-Classes/Instance-Synthesis/).** Resolution concepts; selected canonical environment governs actual claims.
- **L08 — [Validating a Lean Proof](https://lean-lang.org/doc/reference/latest/ValidatingProofs/).** Statement/definition identity and independent checking.
- **L09 — [Type System](https://lean-lang.org/doc/reference/latest/The-Type-System/).** Conceptual dependent-type/proof model, not PSC implementation proof.
- **L10 — [Notations and Macros](https://lean-lang.org/doc/reference/latest/Notations-and-Macros/).** Extension/hygiene mechanisms, not stock-syntax acceptance of every proposed extension.
- **L11 — [Natural Numbers](https://lean-lang.org/doc/reference/latest/Basic-Types/Natural-Numbers/).** Primitive concepts requiring pin-specific bindings.
- **L12 — [Strings](https://lean-lang.org/doc/reference/latest/Basic-Types/Strings/).** Native positions/text context, not JS code-unit identity.
- **L13 — [Integers](https://lean-lang.org/doc/reference/latest/Basic-Types/Integers/).** Operation/sign/zero distinctions; names do not prove host equivalence.

## Engineering and design method

- **G01 — [Go at Google](https://go.dev/talks/2012/splash.article).** Software-engineering discipline, not a grammar template.
- **G02 — [Go FAQ](https://go.dev/doc/faq).** Clarity and tradeoffs.
- **G03 — [Go 1 compatibility](https://go.dev/doc/go1compat).** Continuity and explicit exceptions; PSC proof/source policy needs its own design.
- **G04 — [Go proposal process](https://go.dev/s/proposal-process).** Recorded discussion and design review.
- **M01 — [PLIERS](https://arxiv.org/abs/1912.04719).** User-centered language-design method, not a conducted PSC study.

## Compilation and targets

- **C01 — [CompCert](https://compcert.org/man/manual001.html).** Scoped behavioral preservation; no automatic theorem transfer to PSC.
- **C02 — [Rust operators](https://doc.rust-lang.org/reference/expressions/operator-expr.html).** Arithmetic/cast/overflow concerns for faithful target generation.
- **C03 — [Rust wasm32-unknown-unknown](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html).** Target restrictions, distinct from an owned PSC Wasm implementation.
- **C04 — [Wasm overview](https://webassembly.github.io/spec/core/intro/overview.html).** Decoding/validation/execution, not source-contract preservation.

## Evidence limitations

External docs motivate capabilities and tasks, not representative usage frequency. Framework integrations need exact pins and actual tests. Live pages can be newer than v0.7's Lean baseline. Historical branch snapshots are not an all-branch audit.

The earlier local experiments are recorded in `EXPERIMENTS.md` and are not rerun by this repair. No parser acceptance, kernel theorem, full dependency closure, participant result or new implementation is fabricated. This register identifies sources; release evidence still requires the corresponding conformance and checking work.
