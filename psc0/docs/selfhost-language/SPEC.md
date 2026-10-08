# PSC0-SH/1: proposed self-host authoring contract

Status: **proposed, not implemented or selected by psconfig**. The words MUST and MUST NOT below describe acceptance requirements for a future implementation. They are not claims about the current compiler.

Scope: the PSC0 compiler implementation and its portable dependencies. Initial executable target: existing TypeScript-to-JavaScript bootstrap lane. Initial authoritative source: PSC1-compatible `.lean`, parsed by PSC0's own frontend. Existing generated `.ps` remains the canonical exchange form.

## 1. One language, explicit capabilities

PSC0-SH/1 is a versioned subset of PSC authoring constructs, not a new punctuation system. Its minimum useful delta is ordinary structural recursion with changing value parameters. It retains regular data, typed functions, local closures, immutable state and explicit errors that the current compiler already needs.

The profile has one mandatory core and a capability ledger. Extensions such as nested patterns or Except-only do are independently earned additions to the same frontend; they do not create per-package dialects or silently activate themselves. A seed advertises a capability only after generated-compiler replay covers it. Breaking semantics require a new major language contract and migration.

The historical source compatibility lane remains available during transition. A new authoring restriction must not be applied retrospectively to the old seed/prelude without inventory and an explicit migration. The JSON proposal records current support and proposed support separately.

### Minimum contract versus follow-on work

| Capability | Minimum SH/1 | Subsequent, separately gated work |
| --- | --- | --- |
| Typed declarations and regular data | Existing def/structure/inductive forms, explicit signatures | No source class/instance/deriving promise |
| Function values | Existing typed lambdas, captured values, partial applications, function results | Omitted lambda types from expected domains |
| Control | Let, Bool if, flat constructor matches | Nested patterns and common recursive equation forms |
| Recursion | Direct structural descent with supported changing parameters | Harmless body wrappers/aliases and richer equation normalization |
| Error/state | Except, Option, immutable records, pure helpers | Expected-type-directed Except-only do |
| Runtime | Existing scalar/regular generic representations with explicit checks | Separately specified optional scalar/target extensions |
| Host | No portable host IO or foreign implementation APIs | Host adapters remain outside the compiler language |

Keep explicit types on match-valued local lets when no expected result type is available. “Inferred locals” means the existing supported inference cases, not a promise of full Lean inference.[AST][TERM]

## 2. Source and module rules

1. Top-level executable declarations MUST have explicit parameter and result types. Type parameters may remain implicit where existing PSC elaboration supports them. Implicit host-generated parameters, arbitrary notation and macro expansion are outside the contract.
2. Module identities and import ordering MUST be deterministic. The initial package allowlist remains the twelve compiler packages; adding a helper module inside one of them changes the new closure count, not the historical 55-module receipt.[CONTRACT]
3. The implementation MUST keep source-span/origin information through normalization for diagnostics and migration reporting.
4. The generated `.ps` printer MUST emit the old parser's supported syntax unless a separate parser/printer capability is deliberately promoted. In particular, do not substitute the later `function` syntax.[PP][PARSECALL]
5. New source conveniences MUST be implemented inside the portable compiler. An external JS rewrite or native-Lean-only preprocessing step cannot be the sole implementation of a self-host authoring feature.
6. Existing translator and compiler entry points MUST agree on whether input is ordinary authoring source or normalized source. A syntax-only parse/print round trip does not establish semantic normalization.

The current architecture deliberately keeps handwritten `.lean` authoritative until source and semantic parity justify a change. SH/1 follows that rule; moving authority to `.ps` is optional later work.[A]

## 3. Runtime language

### Required value model

| Category | Contract |
| --- | --- |
| Nat | Arbitrary precision natural values; preserve existing arithmetic, saturating subtraction, division/modulo conventions |
| Int | Arbitrary precision signed values; require only the operations implemented by the original intrinsic set |
| Bool | Two values, explicit equality/negation, short-circuit control preserved |
| Char and String | Unicode scalar characters; immutable strings; distinguish character counts from UTF-8 byte positions |
| Unit | A single value; representation is backend-specific |
| Data | Regular non-indexed algebraic data types and immutable structures with closed runtime layouts |
| Collections/results | Existing List, Option, Except and Prod prelude types and shared helpers |
| Functions | Monomorphic runtime function values, captures and returned functions; top-level rank-1 generic definitions |
| Proofs/types | Existing admitted compile-time proof/type erasure; no runtime type reflection or dependent layout promise |

The original TS mapping uses bigint for Nat/Int, boolean for Bool, string for Char/String, and undefined for Unit. It supports parametric records/data/functions. It does not thereby support first-class polymorphic values, polymorphic recursion, arbitrary dependent runtime types or unresolved types treated as dynamic Any.[TYPE][IR]

The contract does not change existing numeric or text semantics during a source refactor. Add boundary fixtures for zero divisors, large integers, non-ASCII scalars and byte positions before treating another target as conformant.[EXPR]

### Arrays and additional primitives

Arrays already have IR/emission support, but current TS push/set copy arrays. Keep existing use compatible; prefer total `getD`/`setIfInBounds` helpers for new source. Do not describe them as mutable constant-time vectors.[EXPR]

Unchecked indexing requires its pre-erasure proof/provenance or a separately established bounds contract. A post-erasure type/arity checker cannot recreate a deleted bounds proof.

Fixed-width integers and floating operations are separate optional scalar capabilities. USize/ISize require an explicit target width, and merely printing their type as bigint is insufficient. The current IR does not even contain a float-literal constructor, so an arithmetic enum is not a complete source language.[IR][TYPE] None is a prerequisite for accumulator ergonomics.

The portable closure MUST remain closed over a declared runtime primitive/prelude set. Adding a new source convenience SHOULD NOT introduce a runtime primitive.

## 4. Principal transformation: ordinary accumulator recursion

### Desired authoring form

The following is an illustrative proposed SH/1 example. It is not asserted to compile with the current PSC0 generated compiler.

```lean
def reverseInto {alpha : Type}
    (items : List alpha)
    (out : List alpha) : List alpha :=
  match items with
  | List.nil => out
  | List.cons item tail =>
      reverseInto tail (List.cons item out)
```

The current grammar can express this form, but the recursive-call validator rejects the changing explicit accumulator. Existing code manually uses a function-valued worker instead.[TERM][LIST]

The normalized form is schematically:

```lean
def reverseWorker {alpha : Type}
    (items : List alpha) : List alpha -> List alpha :=
  match items with
  | List.nil => fun (out : List alpha) => out
  | List.cons item tail =>
      let next : List alpha -> List alpha := reverseWorker tail;
      fun (out : List alpha) => next (List.cons item out)
```

This is an explanatory encoding. The compiler may keep the public declaration and use an internal typed recursion plan instead of exposing a new helper name. Emitted helper names, when needed, MUST be deterministic and hygienic.

### Required algorithm

For a function whose inputs consist of fixed parameters, one structural major, and varying ordinary value parameters:

1. Resolve binder identities and the declaration's actual self references. A same-spelled shadowed local is not a recursive call.
2. Select one unambiguous structural major. The initial implementation accepts supported ordinary non-indexed inductives and Nat successor/predecessor matching. Ambiguous cases require a diagnostic, not arbitrary selection.
3. Track constructor-child provenance from matches on that major. A same-typed field from an unrelated value is not evidence of decrease.
4. Analyze recursive calls and classify fixed versus varying parameters. Fixed arguments MUST preserve their resolved identities.
5. Check binder-type dependencies before reordering or generalizing anything. Initially varying parameter types and the result MUST be independent of the major and unsupported changing indices. Varying parameters may depend on stable type parameters. Either compute a valid dependency closure or reject a more dependent case.
6. Generalize the varying parameter telescope into the recursion result: for state types S1, S2 and result R, the motive returns `S1 -> S2 -> R`. The hypothesis for a smaller child has that function type.
7. Introduce typed state lambdas in each branch. Replace a direct recursive call with the appropriate child's hypothesis applied to the new varying arguments, preserving simultaneous argument values and evaluation order.
8. Feed the normalized declaration through the existing elaboration/admission/erasure route. Preserve existing structural validation for the normalized form.
9. Verify deterministic output, source correspondence, and execution. A well-typed result alone does not prove that the transformation preserved what the source computes.

The first implementation belongs in a small typed planning/normalization module under `elab`, integrated from Declaration/Context/Term. It MUST itself be written in the old accepted subset so the old seed can build it. Direct recursor construction can replace the normalization later if evidence and performance justify it.

### Required refusals

| Source situation | Required result in the first slice |
| --- | --- |
| Recursive call passes the original major unchanged | Reject as nondecreasing |
| Major is computed by an arbitrary transformation of a child | Reject unless a specific provenance rule is implemented |
| Nat decrease is expressed as arbitrary subtraction | Require successor-pattern provenance in the minimum contract |
| Parameter/result type depends on a changing major/index | Reject unsupported dependent generalization |
| Recursive argument comes from matching an unrelated value | Reject as unrelated to the chosen major |
| Self reference escapes as an unsaturated function value | Reject unsupported recursive escape |
| Fixed parameter unexpectedly changes | Reclassify only when the typed generalization rules permit it; otherwise reject |
| Resource budget is exhausted | Report resource exhaustion distinctly from invalid recursion |

Ordinary nonrecursive higher-order functions remain supported. The special self-recursive escape restriction does not ban all callbacks or returned functions.

Do not “fix” the current implementation by deleting `structuralRecursionInvariantArgument`. Its successful path currently returns a hypothesis variable without applying changing state; relaxing only the check could silently change semantics.[TERM]

## 5. Planned authoring extensions

### A. Body wrappers and recursive equations

The present recognizer requires a root match. Equation parsing can produce a lambda-wrapped body that the recognizer does not see.[DECL][EQUATION]

Route explicit matches and supported equation clauses through the same typed recursion plan. Admit a leading local let or alias only when scope, dependencies, evaluation and structural provenance are preserved. Do not float an arbitrary computation across a match just because it is syntactically a let.

A type ascription must constrain the original expression. It must not disappear before its type has been checked. Aliases of the major or its child require tracked identity/provenance, not name-based substitution.

### B. Nested constructor patterns

Keep the existing flat core match representation. Introduce an authoring-only recursive pattern representation or equivalent parser staging, then lower to a factored decision tree.

Two source clauses beginning with the same outer constructor need one outer branch with an inner decision, not duplicate outer branches. Preserve first applicable clause order, wildcard behavior, binder scope, exhaustiveness and recursion provenance.

The bounded extension excludes guards, inaccessible patterns, arbitrary indexed refinement and dependent pattern matching. Initially keep explicit nested matches fully supported; the extension improves notation.

### C. Expected-type lambdas

Permit `fun x => body` only when an expected function type determines x's domain. Otherwise require an annotation. Keep explicit public signatures and diagnostic locations.

Do not promise that a generic callee's callback domain is always known before later arguments are elaborated. A first fixture should pass the lambda to an explicitly typed local function variable; improve application constraint ordering only with separate tests. The typed form remains a reliable fallback.

### D. Explicit errors first; Except-only do later

Current PSC do syntax lowers to names `compilerBind` and `compilerPure`; it is not general Monad or Except do. The associated stdlib is outside the bootstrap closure.[DO][STDLIB][CONTRACT]

First reuse explicit Except matches and `psListMapExcept`; add a few ordinary helpers in the existing foundation package only when call sites justify them.

If adopting do, define an expected-type-directed Except-only capability with typed bind, ordinary let and final return. Its expansion MUST preserve the first error and avoid evaluating later callbacks after that error. Both native bootstrap and generated PSC paths must agree. Do not silently reinterpret existing compilerBind syntax.

For explicit state, document whether a function is `State -> Except Error (Value × State)` or `State -> (Except Error Value × State)`. These expose different state-on-error behavior.

## 6. Runtime IR validation

Current PSC0 erasure returns the original raw `PsVerifiedIrModule`; TS accepts its `.unknown` type. Add a small validator for this actual model rather than copying later wrapper APIs wholesale.[API][IR][TYPE]

The checker MUST cover:

- Declared names and lexical variable scope, including legal shadowing represented by distinct identities.
- Named type arity, scoped type parameters and runtime type closure.
- Runtime function argument/result types and arity after existing application normalization.
- Record/constructor field layouts and projection types.
- Exhaustive, nonduplicate flat matches.
- Intrinsic signatures and the selected primitive ledger.
- Import/call closure and unresolved runtime `.unknown`.

Run it in report mode on the entire existing closure first. Distinguish deliberate erasure, supported parametric types and actual unknown runtime types. Enforce it on new SH/1 source only after the migration has accounted for historical cases. A wrapper name is optional; actual checks and evidence are required.

Kernel admission establishes core typing relative to its environment. The IR check establishes additional representational constraints. Semantic correspondence/runtime tests address lowering correctness. These claims MUST remain distinguishable.

## 7. Capability evidence and enforcement

Each capability has a stable identifier, current support status, proposed semantics, negative cases, test family and first qualifying seed. The proposal JSON records these fields without pretending that a test suite already exists.

A future profile checker MUST parse source through the real frontend. Lexical host/API bans may remain an early filter, but a regular-expression list cannot establish support for typed recursion or runtime representation.

Replace function-specific marker gates only after a generated compiler passes the positive and negative capability fixtures that cover their purpose. Keep the historical gates for the historical reproduction lane.

Required accumulator fixtures include empty/single/multiple elements, two changing parameters, argument swapping, fixed parameters in different positions, function-valued results, Nat fuel/state, and all refusal cases above. When extensions are enabled, add equation/match equivalence, nested defaults and expected-type lambda tests.

Where normalization is intended to preserve canonical admissions exactly, require equality. Where helper introduction or a deliberate normalization change alters declaration structure, require approved structural differences plus reference/runtime correspondence and new generation equality. Never require every legitimate migrated source file to emit the old seed's artifact bytes.

## 8. Qualification and versioning

A capability is **proposed** until implementation exists; **implemented** after focused checks; **generated-tested** only after the generated compiler consumes ordinary authoring examples; and **seed-qualified** only after the required current-source generations and provider claims have been recorded.

The seed manifest MUST include the language/capability set, normalizer version, exact executing compiler, source closure, prelude/runtime, target/toolchain, provider identity and evidence level. Do not let a profile string grant a stronger claim than the evidence.

Authoring readability and runtime efficiency are separate acceptance dimensions. Existing TS eta, count-loop and tail-loop optimizations must continue to work; generic functions may still use the generator path. Measure allocations and runtime before extending optimization. SH/1 does not assert a speedup merely because it emits cleaner source.[MOD]

[A]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/ARCHITECTURE.md
[AST]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/syntax/src/Ps/Syntax/Ast.lean
[PP]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/syntax/src/Ps/Syntax/ParseProofScript.lean#L1229-L1302
[DECL]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/elab/src/Ps/Elab/Declaration.lean#L56-L102
[TERM]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/elab/src/Ps/Elab/Term.lean#L2706-L2824
[CONTRACT]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/bootstrap-closure-contract.mjs
[LIST]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/foundation/src/Ps/Foundation/List.lean
[API]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/compiler/src/Ps/Compiler/Api.lean
[IR]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/compiler-ir/src/Ps/CompilerIr/Model.lean
[TYPE]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-ts/src/Ps/BackendTs/Type.lean
[EXPR]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean
[MOD]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean
[PARSECALL]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/syntax/src/Ps/Syntax/ParseProofScript.lean#L122-L175
[EQUATION]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/syntax/src/Ps/Syntax/ParseLean.lean#L2488-L2523
[DO]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/syntax/src/Ps/Syntax/ParseCommon.lean#L69-L95
[STDLIB]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/stdlib/ProofScript/Compiler/Effect.lean
