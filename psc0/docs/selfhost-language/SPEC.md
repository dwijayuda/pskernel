# PSC0-SH/1: self-host authoring contract and capability plan

Status: the bounded varying-parameter recursion capability is **compiler-qualified** at the selected authoring seed A, `e91b9558d665879871b8bf0893915ae64b27c7fe`; its exact admissions passed the pinned provider. Foundation.List (B) is qualified. The three-helper migration H at `671685c3f0059574405a1e630dd965d421a26f05` passed compiler qualification and its exact-stream provider check on the first execution. The recursive generic-argument repair E at `cf8fbd784944a98b1e390b709685ca54c2511827` passed compiler qualification and its exact-stream provider check on the first execution. E's complete C2/C3 inventories have zero type-argument arity findings and 244 remaining call-expression typing obligations. The full strict PSC0-SH/1 profile remains pending runtime enforcement (M6), and psconfig retains the existing PSC1 bootstrap lane. The words MUST and MUST NOT describe the complete contract, including obligations still pending. [IMPLEMENTATION.md](IMPLEMENTATION.md) defines the implemented checkpoint boundaries; [qualification-evidence.json](qualification-evidence.json) distinguishes compiler, provider and strict-runtime evidence.

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

Keep explicit types on match-valued local lets when no expected result type is available. “Inferred locals” means the existing supported inference cases, not a promise of full Lean inference.[AST], [LET], [MATCH]

## 2. Source and module rules

1. Top-level executable declarations MUST have explicit parameter and result types. Type parameters may remain implicit where existing PSC elaboration supports them. Implicit host-generated parameters, arbitrary notation and macro expansion are outside the contract.
2. Module identities and import ordering MUST be deterministic. The initial package allowlist remains the twelve compiler packages; adding a helper module inside one of them changes the new closure count, not the historical 55-module receipt.[CONTRACT]
3. The implementation MUST keep source-span/origin information through normalization for diagnostics and migration reporting.
4. The generated `.ps` printer MUST emit the old parser's supported syntax unless a separate parser/printer capability is deliberately promoted. In particular, do not substitute the later `function` syntax.[PP], [PARSECALL]
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

The original TS mapping uses bigint for Nat/Int, boolean for Bool, string for Char/String, and undefined for Unit. It supports parametric records/data/functions. It does not thereby support first-class polymorphic values, polymorphic recursion, arbitrary dependent runtime types or unresolved types treated as dynamic Any.[TYPE], [IR]

The contract does not change existing numeric or text semantics during a source refactor. Add boundary fixtures for zero divisors, large integers, non-ASCII scalars and byte positions before treating another target as conformant.[EXPR]

### Arrays and additional primitives

Arrays already have IR/emission support, but current TS push/set copy arrays. Keep existing use compatible; prefer total `getD`/`setIfInBounds` helpers for new source. Do not describe them as mutable constant-time vectors.[EXPR]

Unchecked indexing requires its pre-erasure proof/provenance or a separately established bounds contract. A post-erasure type/arity checker cannot recreate a deleted bounds proof.

Fixed-width integers and floating operations are separate optional scalar capabilities. USize/ISize require an explicit target width, and merely printing their type as bigint is insufficient. The current IR does not even contain a float-literal constructor, so an arithmetic enum is not a complete source language.[IR], [TYPE] None is a prerequisite for accumulator ergonomics.

The portable closure MUST remain closed over a declared runtime primitive/prelude set. Adding a new source convenience SHOULD NOT introduce a runtime primitive.

## 4. Principal transformation: ordinary accumulator recursion

### Desired authoring form

The following authoring form is exercised by the qualified generated-compiler corpus. Its supported boundaries are the explicit typed/generalization conditions below.

```lean
def reverseInto {alpha : Type}
    (items : List alpha)
    (out : List alpha) : List alpha :=
  match items with
  | List.nil => out
  | List.cons item tail =>
      reverseInto tail (List.cons item out)
```

The historical grammar can express this form, but its stable recursive-call validator rejects the changing explicit accumulator. The enhanced ordinary declaration path now applies typed normalization on that precise refusal, while the explicit stable path retains the historical behavior. Existing worker-shaped source remains accepted.[TERM], [LIST]

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

This is an explanatory encoding. The minimum implementation emits a hygienic internal worker in this canonical shape and preserves the original public interface with a wrapper where needed. The public declaration name, type, implicit binder kinds and parameter order MUST remain unchanged; a source function taking state before its major must not silently acquire a different calling convention. Worker names MUST be deterministic and collision-free.

### Required algorithm

For a function whose inputs consist of fixed parameters, one structural major, and varying ordinary value parameters:

1. Preserve the original public declaration name, type, implicit binder kinds and parameter order. Plan a wrapper when the internal worker's parameter order differs.
2. Resolve binder identities and the declaration's actual self references. A same-spelled shadowed local is not a recursive call.
3. Select one unambiguous structural major. Initially accept supported ordinary non-indexed inductives and Nat successor/predecessor matching. Ambiguous cases require a diagnostic, not arbitrary selection.
4. Track constructor-child provenance from matches on that major. A same-typed field from an unrelated value is not evidence of decrease.
5. Analyze recursive calls and classify fixed versus varying parameters. Fixed arguments MUST preserve their resolved identities.
6. Check every binder dependency before moving parameters. No retained runtime binder type, generalized state type or runtime result type may depend on the major or a moved varying value binder. Stable type/fixed parameters may be dependencies only where the existing runtime contract supports them. Reject any case that requires a dependent telescope in this first slice.
7. Generalize the varying parameter telescope into the recursion result: for state types S1, S2 and result R, the motive returns `S1 -> S2 -> R`. The hypothesis for a smaller child has that function type.
8. Introduce typed state lambdas in each branch. Replace a direct recursive call with the appropriate child's hypothesis applied to the new varying arguments, preserving simultaneous argument values and evaluation order.
9. Emit the canonical worker with only fixed parameters and the major in its outer recursion-parameter set; keep generalized state in the motive/hypothesis function telescope. Emit the public wrapper without changing its external binder order.
10. Feed this form through existing elaboration, admission and erasure. Verify deterministic output, source correspondence and execution. A well-typed result alone does not prove that the transformation preserved what the source computes.

**Erasure boundary:** existing erasure records outer runtime parameters, changes one major argument when reconstructing recursion, and finishes the application using the hypothesis domain. Generalized state MUST NOT remain in the list it treats as fixed outer arguments, or a future normalizer could reinsert stale state or duplicate arguments.[EOPEN], [EREC] This is an implementation obligation, not an observed current bug. Recursive-call reconstruction MUST also retain the current declaration's ordered generic arguments while preserving the empty list for monomorphic declarations. E supplies that bounded repair and its generated-compiler evidence; declaration generics remain distinct from ambient expression-local type binders.

The initial implementation is in a small typed planning/normalization module under `elab`, integrated from Declaration/Context/Term. That first source checkpoint remains written in the old accepted subset so the historical seed can build it. Later source families use the independently qualified A authoring seed. A later direct-recursor alternative may avoid wrappers only with an explicit fixed/major/generalized parameter map consumed correctly by erasure after type/proof erasure and eta expansion; that larger change needs its own conformance evidence.

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

The present recognizer requires a root match. Equation parsing can produce a lambda-wrapped body that the recognizer does not see.[DECL], [EQUATION]

Route explicit matches and supported equation clauses through the same typed recursion plan. Initially admit a leading local let only with a nonrecursive RHS and no unsupported dependent-result or major/branch evaluation dependency; aliases require tracked provenance. Preserve scope and demand behavior. Do not float an arbitrary computation across a match just because it is syntactically a let.

A type ascription must constrain the original expression. It must not disappear before its type has been checked. Aliases of the major or its child require tracked identity/provenance, not name-based substitution.

### B. Nested constructor patterns

Keep the existing flat core match representation. Introduce an authoring-only recursive pattern representation or equivalent parser staging, then lower to a factored decision tree.

Two source clauses beginning with the same outer constructor need one outer branch with an inner decision, not duplicate outer branches. Preserve first applicable clause order, wildcard behavior, binder scope, exhaustiveness and recursion provenance.

The bounded extension excludes guards, inaccessible patterns, arbitrary indexed refinement and dependent pattern matching. Initially keep explicit nested matches fully supported; the extension improves notation.

### C. Expected-type lambdas

Permit `fun x => body` only when an expected function type determines x's domain. Otherwise require an annotation. Keep explicit public signatures and diagnostic locations.

Do not promise that a generic callee's callback domain is always known before later arguments are elaborated. A first fixture should pass the lambda to an explicitly typed local function variable; improve application constraint ordering only with separate tests. The typed form remains a reliable fallback.

### D. Explicit errors first; Except-only do later

Current PSC do syntax lowers to names `compilerBind` and `compilerPure`; it is not general Monad or Except do. The associated stdlib is outside the bootstrap closure.[DO], [STDLIB], [CONTRACT]

First reuse explicit Except matches and `psListMapExcept`; add a few ordinary helpers in the existing foundation package only when call sites justify them.

If adopting do, define an expected-type-directed Except-only capability with typed bind, ordinary let and final return. Its expansion MUST preserve the first error and avoid evaluating later callbacks after that error. Both native bootstrap and generated PSC paths must agree. Do not silently reinterpret existing compilerBind syntax.

For explicit state, document whether a function is `State -> Except Error (Value × State)` or `State -> (Except Error Value × State)`. These expose different state-on-error behavior.

## 6. Runtime IR validation

Current PSC0 erasure returns the original raw `PsVerifiedIrModule`; TS accepts its `.unknown` type. The installed inventory is diagnostic. The generic-erasure repair E removes all 19 historical type-argument arity findings from its complete C2/C3 inventories, while 244 call-expression typing obligations remain. This repairs missing recursive-call generic arguments; it does not supply the full runtime checker.

Implement the checker for this actual model rather than copying later wrapper APIs wholesale. [RUNTIME_IR_PLAN.md](RUNTIME_IR_PLAN.md) gives the next coherent implementation and its acceptance boundaries, including function-valued globals, compositional expression types, simultaneous scoped substitution and explicit exhaustion.[API], [IR], [TYPE]

The checker MUST cover:

- Declared names and lexical variable scope, including legal shadowing represented by distinct identities.
- Named type arity, scoped type parameters and runtime type closure.
- Runtime function argument/result types and arity after existing application normalization.
- Record/constructor field layouts and projection types.
- Exhaustive, nonduplicate flat matches.
- Intrinsic signatures and the selected primitive ledger.
- Literal/result-type consistency and the selected scalar capability's range, signedness, canonicalization and target-width invariants.
- Import/call closure and unresolved runtime `.unknown`.

Continue report mode on the entire existing closure while the portable checker is implemented. Distinguish deliberate erasure, supported parametric types and actual unknown runtime types. Enforce it on new SH/1 source only after the migration has accounted for historical cases. A wrapper name is optional; actual checks and evidence are required.

Kernel admission establishes core typing relative to its environment. The IR check establishes additional representational constraints. Semantic correspondence/runtime tests address lowering correctness. These claims MUST remain distinguishable.

## 7. Capability evidence and enforcement

Each capability has a stable identifier, current support status, proposed semantics, negative cases, test family and first qualifying seed. The capability JSON distinguishes the historical baseline, implemented/qualified evidence and planned fixture families. A planned fixture name alone does not grant support.

A future profile checker MUST parse source through the real frontend. Lexical host/API bans may remain an early filter, but a regular-expression list cannot establish support for typed recursion or runtime representation.

Replace function-specific marker gates only after a generated compiler passes the positive and negative capability fixtures that cover their purpose. Keep the historical gates for the historical reproduction lane.

Required accumulator fixtures include empty/single/multiple elements, two changing parameters, argument swapping, state before the major, fixed parameters in different positions, stable generic and erased proof parameters around runtime arguments, function-valued results, Nat fuel/state, and all refusal cases above. When extensions are enabled, add equation/match equivalence, nested defaults and expected-type lambda tests.

Where normalization is intended to preserve canonical admissions exactly, require equality. Where helper introduction or a deliberate normalization change alters declaration structure, require approved structural differences plus reference/runtime correspondence and new generation equality. Never require every legitimate migrated source file to emit the old seed's artifact bytes.

## 8. Qualification and versioning

A capability is **proposed** until implementation exists; **implemented** after focused checks; **generated-tested** only after the generated compiler consumes ordinary authoring examples; and **compiler-qualified** after the required current-source generation equality and capability/runtime tests.

Qualification has separate axes. A **compiler-qualified seed** can support controlled migration with its limited claims. **Strict SH/1 qualification** additionally requires all mandatory capabilities and runtime IR enforcement (M6). **Kernel-checked qualification** requires actual selected-provider acceptance and is recorded independently. A compiler-only checkpoint does not imply either stricter claim.

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
[LET]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/elab/src/Ps/Elab/Term.lean#L862-L907
[MATCH]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/elab/src/Ps/Elab/Term.lean#L1919-L1938
[EOPEN]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/erasure/src/Ps/Erasure/Definition.lean#L224-L249
[EREC]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/erasure/src/Ps/Erasure/Expr.lean#L987-L1063
