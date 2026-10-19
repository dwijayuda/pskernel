# PSC0-SH/1: self-host authoring contract and capability plan

## Current strict SH/1 qualification

The declared bounded PSC0-SH/1 source, runtime and TypeScript target are qualified at [source `1fa5559a72b293defc56ef7e7020cf82d4b44b79`](https://github.com/dwijayuda/pskernel/commit/1fa5559a72b293defc56ef7e7020cf82d4b44b79). The evidence combines completed native/N1/C1 results from [cancelled run 38015134511](https://github.com/dwijayuda/pskernel/actions/runs/38015134511) and completed C2/C3 fixed-point products and conformance results from [run 38021634599](https://github.com/dwijayuda/pskernel/actions/runs/38021634599), which later failed in its evidence parser. [Evidence-only run 38027413274](https://github.com/dwijayuda/pskernel/actions/runs/38027413274) authenticated those archived bytes, used the reviewed corrected binder, produced the qualification records and obtained separate selected-provider acceptance of the recorded C2/C3 admission streams. The two earlier outcomes remain cancelled and failed. All original generation receipts retain source `1fa5559a72b293defc56ef7e7020cf82d4b44b79` and the original 48-file generation recipe; the corrected evidence producer at revision `719f5ec4225baf51d1969cc3b5e4cbc6959fad4a` has its own identity. [The release qualification record](strict/release-qualification.json) binds all three execution origins, archive and receipt hashes, source closure, generation recipe and toolchain, the narrow producer correction, reviewed source arguments, 33 correspondence dispositions and 27 stage dispositions.

Strict enforcement is qualified for the explicit `psCompilerSh1TypeScriptSources` entry and the recorded strict development/qualification lane. `psconfig.json` does not select strict SH/1: `selectedByPsconfig` remains false, and R remains the selected authoring seed. Authoritative compiler source remains `.lean`; current generated `.ps` uses only the `ps-0.9-r3` bounded subset. Current development uses TypeScript 7.0.2.

This disposition combines independently reviewed source and composition arguments with the exact implementation evidence. Conformance observations, typing, fixed-point equality and provider admission retain their separate meanings. The declared canonical-input, primitive, platform and successful-allocation premises remain in force; no machine-checked compiler-wide preservation theorem or unrestricted PSC1/Lean, Standard or PSCV support is asserted.

Earlier descriptions below of strict SH/1 as pending or unactivated refer to their recorded historical checkpoints. Their source identities and evidence remain unchanged; the linked release record defines the current disposition. This status foreword changes no normative requirement, enabled capability, source grammar or historical proof reference.

Initial F application: [`9ee0b1fd38dd1456a187d4675f9027440a989f2d`](https://github.com/dwijayuda/pskernel/commit/9ee0b1fd38dd1456a187d4675f9027440a989f2d). This is the initial attempt identity; any qualifying revision and its evidence are recorded separately below.

Status: the bounded varying-parameter recursion capability is **compiler-qualified** at the initially selected authoring seed A, `e91b9558d665879871b8bf0893915ae64b27c7fe`; its exact admissions passed the pinned provider. Foundation.List (B) is qualified. The three-helper migration H at `671685c3f0059574405a1e630dd965d421a26f05` passed compiler qualification and its exact-stream provider check on the first execution. The recursive generic-argument repair E at `cf8fbd784944a98b1e390b709685ca54c2511827` passed compiler qualification and its exact-stream provider check on the first execution. E's complete C2/C3 inventories have zero type-argument arity findings and 244 remaining call-expression typing obligations. The bounded M6 runtime IR typing checkpoint at `1b5fd12382c920944924c9d03e0851984293caa2` is compiler-qualified on TypeScript 5.8.3 and has separate exact-stream provider acceptance; the current TypeScript 7 checkpoint at `99786185f77edf952f11989d4c9bc44028f22f11` also passed compiler qualification and its independent provider check. Full strict PSC0-SH/1 remains pending its remaining runtime and semantic obligations. A retains its historical seed identity. The F source migration is compiler-qualified and independently provider-accepted at `fcd875c8f38db4b0524090bd10c7c2fd5024053d` in [F run 37947341800](https://github.com/dwijayuda/pskernel/actions/runs/37947341800), using qualified, cold-recovered, explicitly selected R. R2's new-only `ps-0.9-r3` grammar and parameter-projection repair passed compiler qualification and independent provider acceptance at `fe2560aba0f347b1caf8d000d371464642d44f23` in [run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635). Cold recovery is verified and [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) explicitly selects R; F has separately earned the bounded source/runtime and provider results recorded in [IMPLEMENTATION.md](IMPLEMENTATION.md#f-checkpoint-ordinary-worker-parameters). R2 evidence is separate from strict SH/1 activation and from the independently recorded F qualification. The words MUST and MUST NOT describe the complete contract, including obligations still pending. [IMPLEMENTATION.md](IMPLEMENTATION.md) defines the implemented checkpoint boundaries; [qualification-evidence.json](qualification-evidence.json) distinguishes compiler, provider and strict-runtime evidence.

Scope: the PSC0 compiler implementation and its portable dependencies. Executable target: the existing TypeScript-to-JavaScript bootstrap lane. Authoritative compiler source remains PSC1-compatible `.lean`, parsed by PSC0's own frontend. Current generated `.ps` uses the new-only `ps-0.9-r3` bounded self-host subset described in [PS_GRAMMAR_ADOPTION.md](PS_GRAMMAR_ADOPTION.md). Switching the current `.ps` grammar and switching compiler source authority are distinct checkpoints.

## 1. One language, explicit capabilities

PSC0-SH/1 is a versioned subset of PSC authoring constructs, not a new punctuation system. Its minimum useful delta is ordinary structural recursion with changing value parameters. It retains regular data, typed functions, local closures, immutable state and explicit errors that the current compiler already needs.

The profile has one mandatory core and a capability ledger. Extensions such as nested patterns or Except-only do are independently earned additions to the same frontend; they do not create per-package dialects or silently activate themselves. A seed advertises a capability only after generated-compiler replay covers it. Changes to enabled semantics require an explicit versioned contract and migration. The active bounded source grammar is `ps-0.9-r3` in new-only mode. Strict SH/1 remains unactivated; selecting this source grammar does not activate the complete strict contract.

Historical source and recovery recipes remain available only at their immutable revisions. The current `.ps` parser has one new-only edition and the active `.ps` fixtures and printer must migrate atomically; it must not retain a legacy grammar switch. The separately supported `.lean` frontend remains the compiler's source authority; R stays consumable by A and F requires the qualified selected R successor. The JSON proposal records historical support, current implementation and qualification status separately.

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

### Current authoring forms

Keep explicit types on match-valued local lets when no expected result type is available. “Inferred locals” means the existing supported inference cases, not a promise of full Lean inference.[AST], [LET], [MATCH]

F retains the existing callback and match-result boundaries while using R's repaired parameter projections at the three scoped cleanup sites:

| Situation | Supported source form | Current boundary |
| --- | --- | --- |
| Callback in authored compiler `.lean` | Bind a typed lambda to a local with an explicit function type, then pass the local by name. | The bounded `.lean` argument parser is a separate frontend; F does not extend it. |
| Callback in current `.ps` | Pass a grouped typed lambda, for example `use((fun (x : Nat) => x))`. | The new-only parser accepts this form; omitted lambda domains and general expected-type inference remain unsupported. R2's bounded grammar checkpoint is compiler-qualified; this does not add omitted-domain inference or grant F qualification. R's separate recovery and selection are recorded. |
| Match-valued let initializer | Give the local its result type before the initializer. | The current match elaborator needs an expected result type; general match-result inference is not installed. |
| Projection from an original record parameter in qualified F | Project the original parameter directly while retaining the supported root match. | Selected R supplies this capability. F removed only the three named aliases in `CompilerIr/Check.lean` and passed its separate source/runtime qualification. |

The historical selected-A/M6 restrictions come from the pinned parser, term elaborator and recursion normalizer.[M6PARSE], [M6TERM], [M6RECURSION] The current `.ps` parser changes only the explicitly documented syntax families; match-result inference and normalizer/source-seed constraints keep their own acceptance boundaries.

The pinned M6 source uses `let limits : PsIrCheckOptions := options;` before `limits.maxTypeSteps`, and two `let currentState : PsIrCheckState := state;` aliases before projections of changing state. These are historical examples: the ordinary initializer is rewritten to the hygienic parameter identity while the branch-local alias keeps its name. F removes those three aliases under the R seed prerequisite, retaining the structural-match branches and typing/resource behavior. The earlier restriction applied when changing-parameter normalization ran, not to every recursive function or field projection.[M6CHECK]

The current two-file parameter-projection checkpoint has separate acceptance requirements in [MIGRATION.md](MIGRATION.md#follow-on-repair--parameter-projections-in-recursion-normalization). It must preserve exact full-name priority and the existing first-segment projection path; only an absent first-segment base permits a longest proper multi-segment local prefix. Exact recursion-identity helpers must remain exact-only, and field-typing failure must not trigger another lookup. R2 has earned separate compiler qualification, provider acceptance and verified cold recovery; [selection commit e65606397fb679d7cb96f4f0e92700a6cf0944a6](https://github.com/dwijayuda/pskernel/commit/e65606397fb679d7cb96f4f0e92700a6cf0944a6) records its explicit selection. Its implementation must remain consumable by A; the F consumer source instead requires the qualified selected R successor. Direct projection acceptance by an unqualified candidate is insufficient to satisfy that prerequisite.

<a id="f-candidate-invariants"></a>

### Qualified F invariants

F is compiler-qualified and independently provider-accepted at `fcd875c8f38db4b0524090bd10c7c2fd5024053d`. The twelve worker
rewrites in [migration-backlog.json](migration-backlog.json) MUST preserve their
complete public curried types, parameter order, structural argument, distinct
zero-fuel policies, state-update order and first errors. The three alias removals
MUST preserve the existing root matches, explicit match-result types and resource
checks. No additional inference, recursion or grammar capability is claimed.

The F ABI gate MUST compare actual prepared Core types against independent
signatures and inspect ordered parameter/result types in the exact existing IR.
It MUST NOT use generated parameter display names or JavaScript underapplication
as the public calling contract. Its isolated signature/typed-partial module
provides elaboration evidence only; runtime partial-application and the 87-case
worker checks retain their separate evidence. Probe declarations MUST NOT enter
the authoritative compiler closure. One coherent exact-source qualification
MUST establish the required fixed-point, original-IR and provider results before
the candidate is called qualified.

Function values and returned functions remain supported language constructs.
F removes the twelve selected handwritten state encodings; it does not require
rewriting every function-valued declaration or activate unrestricted PSC1, strict
SH/1, full Standard or PSCV conformance.

## 2. Source and module rules

1. Top-level executable declarations MUST have explicit parameter and result types. Type parameters may remain implicit where existing PSC elaboration supports them. Implicit host-generated parameters, arbitrary notation and macro expansion are outside the contract.
2. Module identities and import ordering MUST be deterministic. The initial package allowlist remains the twelve compiler packages; adding a helper module inside one of them changes the new closure count, not the historical 55-module receipt.[CONTRACT]
3. The implementation MUST keep source-span/origin information through normalization for diagnostics and migration reporting.
4. The current `.ps` parser and printer MUST use the same new-only `ps-0.9-r3` bounded subset. Declarations and constructors use a non-explicit prefix followed by at most one nonempty typed comma group; typed lambdas retain native binder sequences. Commands, structure fields and local let sequences use newlines; record values and adjacent call arguments use commas. Legacy semicolon sequences and repeated explicit declaration groups MUST be refused. Annotated `const` and positive-arity `function` aliases are supported within this subset and canonicalize to `def`. The finite mapping and exclusions are normative for this implementation in [PS_GRAMMAR_ADOPTION.md](PS_GRAMMAR_ADOPTION.md).
5. New source conveniences MUST be implemented inside the portable compiler. An external JS rewrite or native-Lean-only preprocessing step cannot be the sole implementation of a self-host authoring feature.
6. Existing translator and compiler entry points MUST agree on whether input is ordinary authoring source or normalized source. A syntax-only parse/print round trip does not establish semantic normalization.
7. Adjacent calls, whitespace application and grouping MUST preserve application boundaries and argument order. `f a b` has one native argument group; `f(a) b` retains its inner call as the callee. `f()` MUST remain distinct from `f(())` in syntax and canonical output. The current elaborator MUST refuse explicit empty-call completion as `emptyCallUnsupported`, including beneath a later native application; it MUST NOT rewrite it to Unit or erase it.
8. Current source/parse/cache/generation provenance MUST include the grammar edition, new-only mode, enabled support scope and supplied reference digest together with the executing compiler identity. Historical seed products retain their producer's grammar identity. No parser acceptance, round trip or fixed point alone establishes full Standard/PSCV conformance or a Lean provider upgrade.

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

The historical `.ps` frontend lowered its custom do syntax to names `compilerBind` and `compilerPure`; that stdlib is outside the bootstrap closure.[DO], [STDLIB], [CONTRACT] The current new-only `.ps` subset explicitly refuses `do`. Existing modeled compilerBind/compilerPure behavior can be expressed as ordinary typed calls; the new grammar does not assign those helpers generic do semantics.

First reuse explicit Except matches and `psListMapExcept`; add a few ordinary helpers in the existing foundation package only when call sites justify them.

If adopting do, define an expected-type-directed Except-only capability with typed bind, ordinary let and final return. Its expansion MUST preserve the first error and avoid evaluating later callbacks after that error. Both native bootstrap and generated PSC paths must agree. Do not silently reinterpret explicit compilerBind/compilerPure calls or enable generic do from parser support alone.

For explicit state, document whether a function is `State -> Except Error (Value × State)` or `State -> (Except Error Value × State)`. These expose different state-on-error behavior.

## 6. Runtime IR validation

### Installed bounded API

M6 installs portable runtime typing for the existing `PsVerifiedIrModule`. The implementation and its qualification status are recorded in [RUNTIME_IR_PLAN.md](RUNTIME_IR_PLAN.md); the current-source compiler and provider results remain separate receipts in [qualification-evidence.json](qualification-evidence.json). The checker does not depend on a replacement IR or on a host implementation of expression inference.

The M6 TS5 baseline at `1b5fd12382c920944924c9d03e0851984293caa2` passed [run 37906602597](https://github.com/dwijayuda/pskernel/actions/runs/37906602597). Native checking accepted the complete 61-module compiler IR with zero findings. N1/C1/C2/C3 each passed 59 runtime observations, 36 negative IR cases and five carrier refusals, plus the resource, substitution and checked-entry cases. C2 and C3 accepted the complete current-source IR with zero findings and checked that same IR before emission; all four deterministic products agree. N1 TS/JS also agree with C2/C3. Exact counts, identities and the separate three-stream provider acceptance are retained in the [compiler/runtime receipt](runtime-ir-checker-qualification.json) and [provider receipt](runtime-ir-checker-provider.json). The provider ran after emission.

The current TS7 checkpoint at `99786185f77edf952f11989d4c9bc44028f22f11` separately passed [run 37910429506](https://github.com/dwijayuda/pskernel/actions/runs/37910429506), including full C2/C3 qualification and the independent provider check. Its current-source IR reports are accepted and complete with zero findings, with the same IR checked before emission. The [TS7 compiler/runtime receipt](typescript7-qualification.json) and [TS7 provider receipt](typescript7-provider.json) retain this profile's exact identities. That TS7 checkpoint's C2/C3 compiler JS hash is `37ab7de713295b7a2143f1df92b746f97e5a73a8177e906f406fde4a474c0161`; the TS5 baseline and R2 retain their own identities. Neither of those historical checkpoints activated strict SH/1 or replaced the then-selected authoring seed A.

`psCheckVerifiedIrModule` checks module names and signatures, nearest lexical bindings, named-type arity and type-parameter scope, and the runtime type of each supported expression. It checks declaration/lambda results and let initializers against their annotations; infers function-valued callees compositionally; checks generic/runtime call arity; and checks record/constructor fields, projections, and flat match coverage. The active intrinsic ledger gives operand and result types. Explicit `.unknown` is an error, including during equality; it is never a wildcard.[M6CHECK], [M6TYPES]

Caller and callee type scopes remain separate. Generic instantiation uses simultaneous substitution: selecting a replacement returns it unchanged, even when caller and callee reuse names such as T0 and T1. Function parameter grouping is exact: `Function([A], Function([B], R))` differs from `Function([A, B], R)`. A nongeneric global with zero runtime parameters has its declared result type as a value; that result may itself be a function. Generic schemes require direct explicit instantiation and do not become first-class polymorphic values.[M6CHECK], [M6TYPES]

`psTsEmitCheckedModule` requires an accepted, complete report and then passes the exact checked IR to the original emitter. `psCompilerCheckedTypeScriptFromPrepared` exposes that route from an admission-ready prepared module. These entry points are defined in `Ps.BackendTs.Checked`. The raw erasure and emission APIs still exist; a checked entry point does not globally activate strict profile enforcement.[M6CHECKED]

### Bounds and evidence meaning

Before synchronous lookup or binding scans, a portable preflight visits every model/list occurrence and bounds each individual string's UTF-8 size. Input preflight and expression dispatch each have their own `maxSteps` allowance; each type well-formedness, equality or substitution operation has a `maxTypeSteps` allowance. These are bounded-work scopes, not a single wall-clock, allocation or total-operation budget. Exhaustion rejects and marks traversal incomplete.[M6CHECK], [M6SIZE]

`maxFindings` limits retained diagnostic details without stopping the dispatcher. The total counts failed checking obligations; a type operation reports its first error rather than every malformed descendant. Host per-code counts describe all findings only when all details were retained. IR owner/path diagnostics are structural paths, not recovered source positions.[M6HOST]

The host validates its generated-value carriers and serializes the portable report. It permits the old diagnostic inventory only at an explicit immutable-recovery or selected-authoring-seed boundary. That legacy route always records `runtimeIrTypingAccepted: false`. Preserve E's complete historical C2/C3 inventories—zero type-argument arity findings and 244 unfinished expression-typing obligations—as evidence about those exact executions. They are neither 244 established runtime failures nor an M6 acceptance result.[M6HOST]

### Active scope and remaining strict obligations

The installed typing ledger admits Nat, Int, Bool, Char, String and Unit, plus the declared arity-one Array runtime type and its checked intrinsic signatures. The optional fixed-width, floating and word-sized variants remain in the IR model, but their use in a checked module is refused. External imports, empty inductive layouts and empty matches are also explicit refusals in this slice.[M6TYPES], [M6CHECK]

A successful report establishes this bounded runtime typing contract. The full strict profile still needs the applicable primitive laws, literal/canonical value rules, bounds and text-position validity, source/IR evaluation correspondence, and erasure/backend layout and semantic preservation. New scalar or import capabilities need their own target/ABI qualification before being enabled; unused optional extensions need not become prerequisites for the existing closed compiler lane. A post-erasure type check cannot recreate a deleted bounds proof.

M6's focused runtime fixtures also exposed and cover a bounded let-emission repair: an initializer that refers to the old same-named binding must be evaluated outside the new binding's scope, including suspended calls and captured closures. The generator path now preserves that scope, and the tail optimizer declines unsafe batching for this case. This targeted correction supplies evidence for the tested forms, not a general lowering-preservation proof.[M6EXPR], [M6MOD], [M6FIXTURES]

Kernel admission establishes Core typing relative to the admitted environment. Runtime IR checking establishes additional representational constraints on a particular module. Compiler qualification establishes the declared current-source generation and execution evidence. Semantic correspondence addresses preservation through lowering. These claims MUST remain distinguishable; none of the first three alone activates strict PSC0-SH/1 or changes the selected authoring-seed manifest.

## 7. Capability evidence and enforcement

Each capability has a stable identifier, current support status, proposed semantics, negative cases, test family and first qualifying seed. The capability JSON distinguishes the historical baseline, implemented/qualified evidence and planned fixture families. A planned fixture name alone does not grant support.

A future profile checker MUST parse source through the real frontend. Lexical host/API bans may remain an early filter, but a regular-expression list cannot establish support for typed recursion or runtime representation.

Replace function-specific marker gates only after a generated compiler passes the positive and negative capability fixtures that cover their purpose. Keep the historical gates for the historical reproduction lane.

Required accumulator fixtures include empty/single/multiple elements, two changing parameters, argument swapping, state before the major, fixed parameters in different positions, stable generic and erased proof parameters around runtime arguments, function-valued results, Nat fuel/state, and all refusal cases above. When extensions are enabled, add equation/match equivalence, nested defaults and expected-type lambda tests.

Where normalization is intended to preserve canonical admissions exactly, require equality. Where helper introduction or a deliberate normalization change alters declaration structure, require approved structural differences plus reference/runtime correspondence and new generation equality. Never require every legitimate migrated source file to emit the old seed's artifact bytes.

## 8. Qualification and versioning

A capability is **proposed** until implementation exists; **implemented** after focused checks; **generated-tested** only after the generated compiler consumes ordinary authoring examples; and **compiler-qualified** after the required current-source generation equality and capability/runtime tests.

Qualification has separate axes. A **compiler-qualified seed** can support controlled migration with its limited claims. **Strict SH/1 qualification** additionally requires all mandatory capabilities and the complete enabled runtime/semantic contract; the bounded M6 typing API alone does not complete that contract. **Kernel-checked qualification** requires actual selected-provider acceptance and is recorded independently. A compiler-only checkpoint does not imply either stricter claim.

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

[M6PARSE]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/packages/syntax/src/Ps/Syntax/ParseLean.lean
[M6TERM]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/packages/elab/src/Ps/Elab/Term.lean
[M6RECURSION]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/packages/elab/src/Ps/Elab/Recursion.lean
[M6CHECK]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/packages/compiler-ir/src/Ps/CompilerIr/Check.lean
[M6TYPES]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/packages/compiler-ir/src/Ps/CompilerIr/CheckTypes.lean
[M6SIZE]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/packages/compiler-ir/src/Ps/CompilerIr/CheckSize.lean
[M6CHECKED]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/packages/backend-ts/src/Ps/BackendTs/Checked.lean
[M6HOST]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/scripts/original-ir-inventory.mjs
[M6EXPR]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean
[M6MOD]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean
[M6FIXTURES]: https://github.com/dwijayuda/pskernel/blob/956e2c3345d8d634904ff812b31d3b84fc9c23d9/psc0/scripts/sh1-ir-checker-conformance.mjs
