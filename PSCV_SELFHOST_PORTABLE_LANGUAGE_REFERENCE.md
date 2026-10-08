# PSCV Self-Host Portable Language Reference — Candidate Version 1.0

**Document kind:** standalone, proposed compiler-implementation *language profile reference*.  
**Proposed profile identifier:** `PSCV-selfhost-portable/2` (abbreviation: SHP2).  
**Language:** ProofScript `.ps`, within the approved `pscv-v1` grammar and semantic profile.  
**Created:** 2026-10-08. Repository: `dwijayuda/pskernel` on `main`.  
**Four first-class target backends:** TypeScript, direct JavaScript, direct WebAssembly, Rust.  
**Future targets considered but not required:** Python, PHP, Java, Go and other mainstream runtimes.  
**Normative upstream semantic pin:** Lean 4.35.0-rc3 at commit `470d5ce1400764999581fd26d5d72b00d990b0f4`.  
**Legacy bootstrap:** Lean 4.34.0 at commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`. These pins are not interchangeable.  
**Parent source authority:** [ProofScript PSCV Language Reference][PSC-LANG]; compiler architecture: [PSCV V5.1][PSC-V51]; companion research: [PSCV Self-Host Portable V3][PSC-RESEARCH].  
**Adoption status:** **PROPOSAL ONLY**; not an implemented compiler, a certified build, or a change to the approved `pscv-v1` normative language.

> **Authority rule:** This reference defines a *strict subset and implementation discipline*, not a competing ProofScript grammar. If its grammar examples or restrictions conflict with [PSC-LANG], the approved language prevails. Unadmitted Lean, TypeScript, JavaScript, Rust or Go source constructs MUST NOT silently gain acceptance through translator fallback, macros or runtime interpretation. Any genuine new language feature requires a new approved semantic-profile identity.

> **Verification rule:** source checking and executable emission are separate. A development compiler MAY analyze partially verified source and emit explicitly **development-unverified** artifacts. A build claiming `pscv-v1` verified-executable status MUST NOT emit until approved specification coverage, kernel-checked proofs, recursion/VC/effect closure, assumption audit and erasure/certification gates succeed. See [PSC-LANG] `[pscv.no-proof-no-build]`.

> **Release blocker inherited from PSCV:** the standard environment manifest `STD-ENV-PSCV-V1-L435RC3-RC1.json` is still marked SHA-256 **PENDING — release-blocking** in [PSC-LANG]. No hash or proven environment is invented here.

## 0. Purpose and conformance

This language reference defines what source features the eventual PSCV compiler implementation should use to keep the same `.ps` codebase readable, self-hostable, suitable for AI-assisted formal proofs, and semantically executable on TypeScript, JavaScript, WebAssembly and Rust.

**SHP2 source membership** is the intersection of (i) the existing `pscv-v1` language, (ii) a closed SHP2 feature admission policy, and (iii) an approved standard environment and dependency graph. The mathematical/kernel theory and existing PSCV runtime semantics are inherited unchanged. This is a source-capability profile, not a new type theory or a second specification of the four backends.

The approved PSCV full language can be **strictly larger** than the SHP2 compiler subset. For example, the full `pscv-v1` requires verified general `while` loops; SHP2 may deliberately omit them from *compiler implementation source* if finite iterators and well-founded worklists suffice. This omission cannot be cited as permission for the general PSCV compiler to reject a valid `pscv-v1` program.

### 0.1 Evidence/conformance levels

| Label | Exact interpretation |
|---|---|
| PARENT | a rule already defined in [PSC-LANG], not changed by SHP2 |
| SHP2-SOURCE | the restricted source is parsed/elaborated and its imported profile is accepted |
| SHP2-CORE | SHP2 source lowering generates terms independently checked against the pinned logical environment |
| SHP2-TARGET | all four backends implement the admitted value/effect semantics for a stated closed source subset |
| SHP2-SELFHOST | all four complete compiler executables independently recompile the *full same source closure* |
| SHP2-CERTIFIED | separate PSCV proof/spec/effect/erasure and applicable target-preservation assurance satisfied |
| SHP2-STANDALONE | an independently owned PSKernel/provider distribution is accounted for in addition to the compiler |

Do not conflate source acceptance, kernel checking, runtime IR validation, self-host fixed point, target compilation and certified correctness.

### 0.2 Feature categories

- **F0 required:** source construct or fixed library operation mandatory for the SHP2 compiler closure and all four target backends.
- **F1 registered:** accepted only when its deterministic instance/library/verification/target mapping has been added to the pinned SHP2 manifest.
- **FP proof/spec:** accepted only in proof/specification context, checked by the parent PSCV rules and erased when permitted.
- **FD deferred:** a full PSCV feature deliberately left out of the SHP2 compiler-source subset until a new SHP2 revision.
- **FX excluded:** unavailable in a closed portable compiler implementation; separately declared host/boundary capabilities may exist outside that closure.

### 0.3 Source feature inventory

| Feature family | Class | Normative restriction |
|---|---|---|
| modules/imports, namespaces, scopes, deterministic names | F0 | parent import, lookup and instance registry |
| total `def`, `const`, `function`, local `let` | F0 | typed/total, no unchecked executable opacity |
| dependent Pi, universes, `Prop`, `Type`, `Sort` | F0/FP | inherited type theory, no new core formers |
| `inductive`, indexed inductives, `structure`, record update | F0 | strict positivity, typed constructors/projections |
| exhaustive `match`, typed lambdas, closures | F0 | inherited pattern grammar, immutable captures |
| explicit/implicit/instance arguments, deterministic generics | F0 | frozen elaboration and specialization |
| `Option`/`Except`, `List`/`Array`/`ByteArray`/tuples | F0/F1 | exact library semantics and checked errors |
| `Nat`/`Int`/fixed-width ints, Bool, Char, String, Unit | F0 | exact target-independent values |
| `do`, `let ←`, `return` and explicit typed errors | F0 | approved registered monad/effect semantics |
| local `let mut`/assignment | F0 | locally scoped, no escaping mutable alias |
| finite `for`, `break`, `continue` | F0/F1 | certified iterator, invariant/exit VCs |
| structural and well-founded total recursion | F0 | kernel-accepted decreasing evidence |
| mutual total recursion, `where` helpers | F0 | joint well-founded or structural recursion |
| closed classes, instances, coercions | F1 | exact pinned deterministic Standard registry |
| pure/Reader/State/Except effects and finite-iterator WP | F1 | explicit success/error/state model |
| transparent `abbrev` and small combinator libraries | F1 | no hidden semantics beyond registered definitions |
| `theorem`, proof tactics, `verify` | FP | accepted proof terms, exact axiom closure |
| `given`/`requires`/`ensures`/`errors`, frames | FP | approved contracts and call-site obligations |
| `assert`, `ghost`, invariants, `decreasing_by` | FP | proof-only state, totality and ghost erasure |
| general `while`, `refine type` in implementation source | FD | full PSCV supports; not initially needed in SHP2 |
| general `deriving` and user syntax macros | FD/FX | not imported from unrestricted Lean by default |
| raw `partial`, `unsafe`, user `axiom` | FX | source/reachable dependency rejection |
| runtime-relevant `noncomputable`, arbitrary IO/FFI | FX | separate explicit host/boundary profile only |
| raw pointers, general aliased heap, dynamic reflection | FX | requires new independently specified semantic profile |
| unmodeled concurrency/shared mutable state | FX | no deterministic or closed effect model |
| JavaScript truthiness, TS `any`, Go `nil`, Rust `panic!` | FX | not ProofScript source semantics |

## 1. Primary-language reference research

### 1.1 Lean 4 — semantic baseline

The [Lean elaboration/compilation reference][R-LEAN-PIPE] separates parsing, macro elaboration, typed Core, trusted kernel checking and native compiler output. [Inductive types][R-LEAN-IND] cover algebraic data and checked recursor/induction principles. [Do-notation][R-LEAN-DO] includes mutable local variables, monad sequencing, early return and for loops through typeclasses such as ForIn. [Recursive definitions][R-LEAN-REC] distinguish kernel-checkable structural/well-founded recursion from kernel-opaque `partial` functions. [Strings][R-LEAN-STRING] have a UTF-8 logical model and byte positions.

**SHP2 decision:** adopt total functions, typed ADTs, dependent Core, local mutation lowered into pure/effect Core, deterministic elaboration, registered iterators and proof terms; reject unrestricted unsafe/partial/meta/IO source in the portable closed compiler. Lean's pinned syntax can host development, but an accepted Lean program is not automatically accepted PSCV.

### 1.2 TypeScript — type-level ergonomics, JavaScript runtime

The official [generics handbook][R-TS-GEN] describes reusable type parameters. [Narrowing][R-TS-NARROW] uses tagged discriminated unions and exhaustive switching. [Type erasure][R-TS-ERASE] explicitly distinguishes compile-time checking from actual JS execution. [Object types][R-TS-OBJ] use structural object shapes; [module documentation][R-TS-MODULE] distinguishes ESM/CommonJS emit and module resolution.

**SHP2 decision:** borrow ergonomic typed APIs and allow backend-generated tagged records/declarations. Do not import TS structural assignability, `any`, null/undefined coercion, JS runtime behavior or `tsc` success as a proof of PSCV correctness. Direct JS MUST be independent of `tsc`; emitted TS MAY require a pinned `tsc` and then runs with a JS runtime.

### 1.3 ECMAScript/JavaScript — runtime mismatch that must be modeled

The [ECMAScript 2026 specification][R-ECMA] specifies `Number` and `BigInt` separately, and defines `String` values as sequences of 16-bit code units (commonly UTF-16 text). Runtime objects/prototypes, implicit coercions, host exceptions and `undefined` are not valid implementations of ProofScript's dependent types, exact integer contracts or typed errors without an explicit semantic adapter.

**SHP2 decision:** use BigInt/exact integer libraries, UTF-8 byte buffers, tagged values and explicit exceptions only through checked runtime wrappers; never use host truthiness, floating Number for arbitrary Nat, Unicode code-unit offsets for source spans, or dynamic `eval` as a compiler fallback.

### 1.4 Rust — strongly typed IR, explicit failure and target ownership

The [Rust Reference][R-RUST-EXPR] defines evaluation order and place/value expressions; its [type system][R-RUST-TYPES] includes structs/enums, generics and trait types. [Ownership and borrowing][R-RUST-BORROW] enforces constraints on aliased mutable references. [Integer overflow][R-RUST-OVERFLOW] can panic under debug/overflow-checking settings; source semantics therefore cannot be inferred from arbitrary release settings.

**SHP2 decision:** borrow ADTs, typed error results, well-structured transformations and target-specific efficient ownership *under* the Rust backend. Do not force Rust borrow/lifetime/unsafe/panic/`usize`/drop semantics into portable ProofScript.

### 1.5 Go — readable iteration but not portable native map or string rules

The [Go language specification][R-GO-SPEC] documents type parameters, interfaces, statements and range iteration. Go map iteration order is unspecified; ranging a string decodes Unicode runes and invalid byte sequences are replaced. These are inappropriate definitions of source-order-sensitive ProofScript compilation and exact UTF-8 source bytes.

**SHP2 decision:** borrow clear loop and modular compiler source organization; use ordered explicit traversal over compiler maps, strict UTF-8 byte processing and typed failure rather than `panic`/`nil`. Go may be a future backend, but it will implement the same source-language value model rather than define one.

### 1.6 Other verified-compiler lessons

[CompCert][R-COMPCERT] motivates pass-specific semantic preservation rather than assuming source typechecking proves compiled executables. [CakeML][R-CAKEML] demonstrates verified compiler/bootstrapping methodology. [Dafny][R-DAFNY] and [Verus][R-VERUS] motivate explicit invariants, decreasing measures, proof/executable separation and controlled heap effects. These precedents do not prove the correctness of the future PSCV self-host compiler.

## 2. Lexical grammar: strict inherited PSCV parsing

**SHP2-GRAMMAR-1:** the authoritative syntax consists of the parent's `SourceFile` goal symbol, Chapter 5 scanner, Appendix A closed grammar (A.1–A.18), exact Chapter 20 approved tactics and pinned Appendix I Lean mapping locators. SHP2 adds only a *filter over parsed and elaborated parent constructs*, not its own competing tokenization.

For clarity, the following is an **admission predicate**, not a new parse grammar:

~~~text
AcceptSHP2(source, identity) :=
  ParentPSCVParse(SourceFile, source, frozenGrammar)
  AND ParentPSCVElaborate(source, frozenEnv)
  AND OnlySHP2AdmittedFeatures(source)
  AND ImportedLibraryAndProofClosureAllowed(identity)
  AND ExecutableDependencyEffectsAllowed(identity)
~~~

**SHP2-LEX-1:** source is normalized valid UTF-8 according to the parent. Source/diagnostic offsets are *byte offsets*. Unknown or invalid encodings fail explicitly; no silent JavaScript surrogate replacement or Go range replacement.

**SHP2-LEX-2:** only parent-approved identifiers, literals, comments and trivia are admitted. Block comments nest as specified. Unmatched strings, escaped characters or comments reject.

**SHP2-LAYOUT-1:** line endings, `CommandSep`, `DoSep`, `InstanceSep`, `WhereSep`, proof separators and `LayoutEdge` obey Appendix A. Semicolons and JavaScript ASI are not general alternatives. Braced definition bodies contain **one term**; `do { ... }` is the explicitly sequenced case.

**SHP2-CALL-1:** parenthesized `f(x, y)`, static field/method notation, optional trailing comma, qualified calls and gap/adjacency constraints follow the parent. `f()` is not `f(())`, because the latter supplies a Unit argument. Mandatory missing explicit args fail.

**SHP2-BINDER-1:** explicit binders `(x: A, y: B)`, implicit `{α: Type}`, strict implicit `{{α: Type}}` and instance `[C α]` retain parent rules. The self-host profile requires explicit public API types where necessary for deterministic proofs, but it cannot change meaning through TS/JS/Rust/Go inference.

**SHP2-OPERATORS-1:** grammar precedence, associativity, static member access, comma use and call spacing are exactly the parent's; no Rust `?` operator, Go `:=` short declaration semantics or TS `=>` arrow syntax is inherited.

### 2.1 Closed acceptance pseudogrammar

~~~ebnf
SHP2Source       ::= ParentSourceFile subjectTo SHP2ModulePolicy
SHP2Command      ::= ParentCommand subjectTo SHP2CommandPolicy
SHP2Declaration  ::= ParentDeclaration subjectTo SHP2DeclPolicy
SHP2Expr         ::= ParentPSTerm subjectTo SHP2ExprPolicy
SHP2Do           ::= ParentPSCVDoTerm subjectTo SHP2DoPolicy
SHP2Proof        ::= ParentProofTerm subjectTo SHP2ProofPolicy
~~~

The names above are *meta-notation*, not a second parser EBNF. Parent grammar remains the only precise token/syntax production authority. In particular `WhileElem` may be valid under `pscv-v1` but fails this initial compiler-source feature policy.

### 2.2 Parent grammar examples (informative, not independently compiled here)

~~~proofscript
function add(x: Nat, y: Nat): Nat := {
  x + y
}

function zero(): Nat := {
  0
}

function id {α: Type}(x: α): α := {
  x
}

function sameValue {α: Type}[BEq α](x: α, y: α): Bool := {
  x == y
}
~~~

The forms are drawn from [PSC-LANG] Chapters 8–10; this research did not run them through a complete SHP2 compiler.

## 3. Modules, names and import identity

**SHP2-MOD-1:** top-level `import`/`public import` must appear in the parent's import-header position. `namespace`, `section`, `open`, public/private declarations and local shadowing obey the pinned name lookup tiers [PSC-LANG] Chapter 7. No last-import-wins, JS property lookup, TS declaration merging or filesystem-order dependence.

**SHP2-MOD-2:** module identities are logical, not arbitrary file paths or runtime module objects. Every self-host closure must fix the source import graph, transitive environment/instance/coercion registry, published proof/standard-library identities and target capabilities.

**SHP2-MOD-3:** imports of unchecked host modules, axiom-bearing proof dependencies and nonportable intrinsics are not permitted in the *closed* compiler executable closure. An explicit `pscv-boundary-v1` tool/runtime adapter is separate and cannot manufacture a closed certificate.

**SHP2-NAME-1:** use normal parent lexical shadowing, namespace prefixes, `open` and qualified names; ambiguities reject. Compiler source SHOULD favor qualified names at public/critical type/proof boundaries to reduce accidental dependency changes.

**SHP2-CACHE-1:** caching and incremental elaboration have no authority: the exact semantic manifest, module identities, registry and source hashes must match for reuse.

## 4. Declarations and the data language

**SHP2-DEF-1:** executable `def`, `const` and `function` are total and have a typed body. A braced definition has exactly one `PSTerm`. The application must use registered effects and valid runtime primitives. Local `where` helpers are allowed only through the parent's bounded where grammar.

**SHP2-DATA-1:** positive `inductive` and indexed inductive families represent ASTs, Core, IR, token kinds and error variants. Pattern matching is exhaustive, single-scrutinee as constrained by the parent, with typed branch results and original alternative order.

**SHP2-DATA-2:** `structure` values, named record construction, projections and immutable updates use the typed parent grammar; they do not become dynamic JS objects/TS structural types. Representation choice is private to each target backend.

**SHP2-FUN-1:** functions may be polymorphic and dependent under the parent, and may be represented by immutable closures. In the initial executable subset, runtime closure captures may not expose mutable aliases; higher-rank or open-ended specialization cannot be silently degraded into dynamic runtime casts.

**SHP2-CLASS-1:** parent classes/instances and coercions are only accepted with a closed deterministic Standard registry; unbounded user typeclass metaprogramming is excluded from the initial source profile. Instantiation and instance priority must agree with the parent's `PS-UNIFY-v1` rules, not host Rust traits or TypeScript structure lookup.

**SHP2-OPAQUE-1:** transparent `abbrev` is permitted for fixed source aliases. `opaque` may describe approved proof/spec interfaces; an opaque executable root requires a separately checked implementation relation. User `axiom`, `partial` and `unsafe` are rejected under the parent verified source.

## 5. Type system and elaboration

**SHP2-TYPE-1:** inherit exactly `Prop`, `Type`/`Sort`, universes, dependent Pi/arrow, lambda, let, Eq, recursors, quotient and definitional/propositional equality from [PSC-LANG]. SHP2 adds **no kernel primitive**.

**SHP2-TYPE-2:** indexed data, `Subtype`/`Fin` and proof fields are available where admitted by the verified executable semantics. Proof/ghost material must not influence erased executable behavior.

**SHP2-ELAB-1:** implicit parameters, expected type propagation, instance ordering, coercions, integer literal defaulting and `PS-UNIFY-v1` follow the pinned Standard environment. JavaScript/TS `number` default, Rust `i32` inference and Go `int` defaults play no role.

**SHP2-ELAB-2:** a conditional must be the parent's `Bool` mode or `Prop + Decidable` mode. JS truthiness and TypeScript falsy narrowing are not accepted semantic substitutes; branch typing remains exact.

**SHP2-ELAB-3:** failed inference, ambiguous name, unsolved metavariable, unknown import or unsynthesized class instance is a typed source failure. A Lean frontend may *propose* checked Core but must satisfy independent source-fidelity/registry checks before claiming PSCV conformance.


## 6. Evaluation, recursion and algorithmic effects

### 6.1 Expression/evaluation meaning

**SHP2-EVAL-1:** evaluations and definitional equality obey the parent logical theory [PSC-LANG] Chapters 4 and 17. The compiler may optimize only under explicit observational equivalence. No backend chooses semantics by casting source terms to JS objects or native Rust/Go values.

**SHP2-EVAL-2:** value evaluation order, short-circuiting and match alternative order are fixed by the approved source semantics, not whichever host backend would find convenient. An emitter MUST preserve the observable order of approved effects, error selection and deterministic output bytes; it MAY reorder computations proven observationally independent.

**SHP2-BOOL-1:** only Boolean/decidable proposition conditionals admitted by `[elab.if]`. Reject numeric/string/object truthiness, JS optional chaining as logic, TS truthiness narrowing as dependent proof, and Go/Rust host implicit coercion.

**SHP2-ERROR-1:** expected failures have declared algebraic types (e.g., `Except Error A` or a checked, registered result type). A host `throw`, Go `panic`, Rust `panic!` or Wasm trap is **not** a source-level error branch unless the backend's contract explicitly models it and proves equivalent handling.

### 6.2 Structural recursion

**SHP2-REC-1:** the parent's strict-structural-subterm relation [PSC-LANG] `[recursion.structural]` is authoritative. Every recursive cycle has an approved totality argument; `n - 1` by itself is not a syntactic structural subterm.

**SHP2-REC-2:** a local `where` recursive helper obeys the same designated decreasing argument rule as a top-level function. Mutual recursion is accepted only when its joint recursive measure/elaboration closes under the parent grammar and kernel-checkable recursors.

### 6.3 Well-founded recursion and algorithmic resources

**SHP2-REC-3:** use parent `termination_by measure` and optional `decreasing_by proof` (see `[pscv.recursion.well-founded]`) for algorithms whose decreases are arithmetic/lexicographic rather than constructor-subterm relationships. Inferred termination may be used only when the kernel-checked decrease evidence and source-to-Core meaning can be exported and independently audited.

**SHP2-REC-4:** a function with fuel/budget is mathematically total only relative to the actual returned failure/success type. At exhaustion, return `resourceExceeded` or `unknown` in the declared error model; **never invent a valid AST, treat a valid theorem as invalid, or issue a checked proof from exhausted search**. Distinguish provable semantic falsehood from operational inability to decide.

**SHP2-REC-5:** deep recursive traversal is a portability concern even for mathematically total functions. Use a proven iterative worklist, trampoline or bounded recursion library where JS/Wasm stack behavior would otherwise diverge. Runtime out-of-memory/stack faults outside the modeled resource envelope are host assumptions, not proof of logical nontermination.

### 6.4 Why general `partial` is excluded

The official [Lean recursion reference][R-LEAN-REC] distinguishes kernel-safe termination from opaque `partial` and unsafe compiled implementations. These mechanisms are practical in Lean compiler internals, but they would prevent certifying the whole PSCV compiler's executable closure under `pscv-closed-v1`.

SHP2 therefore permits more ergonomic finite loops and worklist libraries **instead of** importing unrestricted general recursion. The profile does not require each compiler function to be implemented as a handwritten primitive fuel worker if a total library combinator proves the same operation.

## 7. Verified `do`, local mutation and finite loops

### 7.1 Context and effects

**SHP2-DO-1:** ordinary `do { ... }` follows the parent Appendix A `BasicDoTerm` or `PSCVDoTerm` grammar. In the compiler-source subset, the set of permitted effects must be a *frozen, registered* member of the parent `PSCV-VERIFY-v1` verified-effect families, initially:

- pure/identity computation;
- Reader-like readonly environment;
- State-like explicit abstract local/compiler state;
- typed Except-like errors;
- explicitly registered combinations with an exact state-on-error policy.

A `Monad` instance alone is not sufficient to prove any effect; WP laws and import assumptions are required.

**SHP2-DO-2:** source local `let mut` and assignment are allowed *only inside the admitted `do` and its lexical descendants*; assignment targets must be in-scope mutable locals and cannot cross abstract runtime ownership boundaries. No general heap references, shared aliasable mutable object graphs or global mutable bindings are introduced by this syntax.

### 7.2 Typed success and error policy

The **proposed default compiler-state/error library contract** is:

~~~text
CompilerM Error State A  :=  State -> Except Error (A, State)

successful run:
  run m state0 = Except.ok(result, state1)

failed run:
  run m state0 = Except.error(error)
  no successful state1 is published
~~~

This corresponds to a proposed `StateT State (Except Error)`-shaped abstract result, not the different `ExceptT Error (StateM State)`-shaped semantics where failure can still return state.

**SHP2-ERROR-2:** the choice is **not** a claim that parent PSCV has already standardized this exact combined-monad law. It must be registered in the approved Standard environment and supplied with a correctly checked WP and runtime correspondence *before being permitted as an S1 effect*. Until then, source may use separately verified primitive State and Except models, with no unapproved implicit stack composition.

An abstract failed state being discarded does not undo real network/file/FFI effects. Those belong to a separately modeled host capability, which cannot falsely acquire transactional semantics from a StateT API.

**SHP2-ERROR-3:** `ensures result => P` and `errors err => Q` apply to the correct success/error branches under parent `[pscv.effect.error-post]`; a missing `errors` clause must follow the active approved default rather than making all failures vacuously successful.

### 7.3 Local mutation desugaring

SHP2 local mutation is **operational sugar**, not an additional primitive kernel type former:

~~~text
let mut total := init
total := next(total, x)
return total

becomes a typed sequence of states:
  total_0 = init
  total_1 = next(total_0, x)
  normal_exit(total_1)
~~~

This is an explanatory SSA/state relation, **not** a complete executable semantics for `do`. A conforming implementation must preserve scope, evaluation order, type dependency, early exit, error propagation and proofs under the parent `PSCV-VERIFY-v1` lowering.

SHP2 source semantics cannot observe runtime object identity or raw mutable aliasing of a local. A target emitter may use JS/TS variables, Wasm locals or Rust mutable locals/owned buffers when that representation satisfies the abstract state relation.

### 7.4 Finite `for`

**SHP2-FOR-1:** an admitted `for pattern in collection` is total only when the collection has a **registered finite iterator contract**. The specified element order and cursor advancement must agree across four targets. The loop body and its observable state must be provable under the iterator's invariant/specification.

**SHP2-FOR-2:** for mutable state, an explicit invariant or a registered iterator/library theorem must provide initialization, preservation and exit obligations. `break` and `continue` must discharge their own frame/invariant/exit VCs, as required by [PSC-LANG] `[pscv.loop.for]`.

**SHP2-FOR-3:** an iterator that can grow indefinitely through its own loop mutations is not admitted as finite merely because its input initially had finite length. A decreasing well-founded measure is required over the actual admitted iteration semantics.

**SHP2-FOR-4:** source iteration over hash maps with unspecified order cannot determine canonical compiler outputs. Stable traversal through sorted keys or preserved declaration/source order is required.

### 7.5 General `while` remains a full PSCV feature, not initial SHP2

Parent `pscv-v1` explicitly specifies `while` and requires a loop `invariant` and `decreasing` clause (`[pscv.loop.while]` and `[pscv.grammar.loop-clauses]`). The SHP2 language profile excludes general `while` in its initial closed compiler executable subset as an extra source restriction. Use finite `for` or certified total worklists; include general `while` in SHP2 only through a new **versioned source feature revision**, not through a runtime fallback.

### 7.6 Authoritative PSCV source-shape illustration

The following is the *parent reference's* source shape; `prefixSum` stands for a declared proof/model value and makes the snippet illustrative rather than ready to compile:

~~~proofscript
do {
  let mut total := 0
  for x in xs
    invariant total = prefixSum
  {
    total := total + x
  }
  return total
}
~~~

This is **not** a general JavaScript/Go statement block. It is verified monadic local state with a finite iterator and proof obligations. The example is not evidence that the current PSC1 source compiler or experimental Lean frontend supports all these forms.

## 8. Specifications, contracts, theorem terms and ghost code

### 8.1 Approved specifications

**SHP2-CONTRACT-1:** [PSC-LANG] `[pscv.spec.coverage]` requires every exported executable declaration to be associated with an **approved** specification; a private helper may be transitively covered but remains subject to totality, effects and axiom closure. A theorem that proves `True` does not establish correctness when the approved requirement was stronger.

**SHP2-CONTRACT-2:** source `given`, `requires`, frame `reads`/`modifies`, `ensures` and `errors` must follow Appendix A.18's exact grammar and clause ordering. A source compiler must reject interleaved clause order even when a generated Lean program could still elaborate.

**SHP2-CONTRACT-3:** callee preconditions yield call-site VCs, checked callee postconditions may be used only with accepted proof/spec identity, and exceptional exits have independent obligations. Proof generation by automation/AI/tactics does not itself establish proof soundness.

### 8.2 Proof and ghost relevance

**SHP2-PROOF-1:** accepted proof terms/theorems use the parent `Prop` and pinned proof/tactic grammar. Lean automation such as `simp only`, `omega` and `grind` may be used only when admitted by the approved proof environment and with independently checked proof terms.

**SHP2-PROOF-2:** `assert P` creates a proof obligation; it does not become a required runtime `assert` or a TypeScript/Rust thrown exception merely to make testing easier. Optional runtime instrumentation cannot count as proof.

**SHP2-GHOST-1:** `ghost`/`ghost mut` state may guide specifications and invariants but cannot affect runtime-relevant return values, branch choice, errors, external calls or emitted bytes after erasure. A target that includes or branches on ghost state without an accepted noninterference relation MUST reject certified emission.

**SHP2-PROOF-3:** `noncomputable` may occur in approved proof/spec reasoning according to the parent, but cannot be reachable from executable runtime data. An unchecked user axiom, even through an imported module or a renamed declaration, is not permitted in a closed certificate.

### 8.3 Proof engineering for AI-assisted maintenance

AI-generated proofs and source edits are **untrusted proposals**. In particular they may not change the approved specification ID, widen allowed assumptions, weaken the postcondition, add `sorry` or use unchecked native proof shortcuts to obtain a pass.

Portable compiler modules SHOULD expose:
- explicit function signatures and typed errors;
- a one-paragraph semantic contract and approved spec ID;
- a named structural/well-founded recursion measure or certified iterator invariant;
- small lemmas about constructor cases, bounds, state transitions and preservation;
- precise source spans and dependency identities for all VCs;
- an explicit proof-only/executable relevance distinction;
- no hidden environmental instance or coercion drift;
- an independently checked proof/replay result distinct from test green and backend output.

An AI proof benchmark must measure **kernel-replayed success and the cost to preserve the same approved theorem**, not merely code length, natural-language explanation quality or model confidence. The exact benchmark protocol appears in the evaluation section later in this document.

## 9. Runtime values and target-neutral semantics

### 9.1 Logical meaning versus target representation

**SHP2-RT-1:** the meaning of each type and primitive is inherited from [PSC-LANG] Runtime Semantics and the exact pinned Standard environment. The profile may **restrict which runtime types compiler source uses** but must not silently redefine a type to match a target's convenient representation.

**SHP2-RT-2:** target-specific representation decisions belong *below* the validated RuntimeIR boundary. A JS tagged record, Rust enum, Wasm GC object or future Go struct may implement the same source `inductive`; the target representation is not a source type-theory axiom.

### 9.2 Integers, machine integers and floats

**SHP2-NUM-1:** `Nat` and `Int` are exact mathematical values under the approved parent, not JS `Number`, Rust fixed `i64` or Go platform `int`. Use a correct arbitrary-precision representation when needed (JS/TS BigInt or exact library; Wasm exact integer runtime; Rust big-int library or corresponding checked representation), preserving source arithmetic, comparisons, conversions and exceptional/error cases.

**SHP2-NUM-2:** fixed-width signed/unsigned types have explicit bit widths, wrap/overflow/conversion/shift/divide semantics as pinned by the parent. Do not inherit Rust compiler overflow-check settings, Go width of `int`, JS binary operators' implicit 32-bit coercion or Wasm i32/i64 truncation.

**SHP2-NUM-3:** `USize` and `ISize` (where admitted) require explicit target profile and checked sizing/casts; indices and declaration IDs cannot silently narrow from exact `Nat` to target-native size. If a target width is unsupported, emit a typed target error.

**SHP2-NUM-4:** Float/Float32 remain part of the general PSCV language where specified, but the initial *compiler implementation source* SHOULD avoid floating-point computation unless necessary and covered by exact NaN, infinity, signed-zero, rounding and serialization semantics. This is a use-site restriction, not a language feature removal.

### 9.3 Strings, Unicode, source bytes

**SHP2-UTF8-1:** compiler lexing/source spans/hash inputs operate on exact UTF-8 **bytes** and their specified decoding. No JS/TS UTF-16 length, Java UTF-16 code-unit index, Go decoded-rune byte replacement or PHP binary-string coercion may change source offsets.

**SHP2-UTF8-2:** invalid byte streams MUST follow approved rejection/diagnostic rules. If the runtime host originally presents text as a higher-level string, the ingestion adapter must explicitly define encoding and report its trust assumptions. No silent invalid Unicode replacement for source input.

**SHP2-UTF8-3:** `Char` values, string slicing, byte slicing, byte offsets, valid character boundaries and end-of-input checks use exact library contracts. The [Lean String reference][R-LEAN-STRING] demonstrates why byte positions matter, but any ProofScript-specific `String` operation still follows the parent registry.

**SHP2-UTF8-4:** source maps, diagnostics, identifiers and serialized artifacts use deterministic positions/escaping/line-ending normalization. Do not make output depend on locale or operating-system text encoding.

### 9.4 ADTs, records, closures and equality

**SHP2-ADT-1:** constructors are disjoint, well-typed variants; matches are exhaustive; field extraction and record update follow source declaration identity. JS object property identity and Go/Rust pointer identity are not source equality unless explicitly defined by a registered primitive contract.

**SHP2-ADT-2:** immutable closures capture source-level values. General observable mutable aliasing through an escaped capture is excluded in SHP2. Function specialization/lambda lifting may change runtime layout but not call behavior or closure environment semantics.

**SHP2-EQ-1:** define equality for each admitted type through the approved Core/registered typeclass laws. No JS `==`/`===`, PHP loose equality, Go interface equality or Rust pointer equality is substituted merely by emitter convenience.

### 9.5 Containers and deterministic output

**SHP2-ARRAY-1:** indexing and updates use explicit bounds evidence or typed optional/error results. No automatic out-of-range `undefined`, Rust panic, Go panic or Wasm trap as a *successful* typed PSCV value.

**SHP2-MAP-1:** hash maps can accelerate lookup but their iteration MUST NOT determine compiler output order unless an approved deterministic ordered-map/iteration contract explicitly specifies that order. Stable source-order lists or sorted keys are recommended for declarations and diagnostic output.

**SHP2-BUILDER-1:** string/byte builders MUST have append-order, canonical encoding, snapshot immutability and resource-failure laws. Their implementation may use target-specific buffers internally but must preserve the same value on all targets. Building an entire string by repeated naive concatenation is not required merely because it is easier to prove a primitive list algorithm.

### 9.6 Resource model

**SHP2-RESOURCE-1:** mathematical totality of a function does not guarantee finite stack, heap or execution time on all runtimes. Resource budgets, host limits and uncaught fatal runtime exits are separately declared in the target profile.

**SHP2-RESOURCE-2:** an exhausted parser/elaborator/checker must report failure/unknown with a typed reason when feasible, not fabricate a checked declaration or a semantically definitive false rejection. An unavoidable runtime OOM/trap is a declared external assumption rather than a verified source-level control path.

**SHP2-RESOURCE-3:** portability acceptance exercises deep ASTs, large Nat values, long Unicode inputs, repeated append, map collision/order, Wasm memory growth and actual source re-entry, not only small unit tests.

## 10. The standard self-host library contract

### 10.1 Owned and versioned library interface

The language profile MUST identify a **closed Standard environment** with exact type/instance/coercion/theorem identities. The table below specifies *capability families*, not claimed existing `import` names. Concrete module paths and hashes must be generated from the approved manifest rather than invented here.

| Family | Required operations | Core laws and proof obligations |
|---|---|---|
| `List` | constructor, recursion, length, map/fold | structural induction, ordered traversal |
| `Array` | empty, push, get, get?, set, size, fold | bounds, size, stable order, functional update |
| `ByteArray` | append, slice, push, read | byte exactness, bounds, EOF/progress |
| `String`/UTF-8 | decode/encode, next position, byte size | Unicode/byte-boundary correctness |
| `Option` | some/none, bind/map | exact branch semantics |
| `Except` | ok/error, bind/map | typed errors, no hidden host throw |
| `State` and `Reader` | read/write, run, local scope | declared state/environment effects |
| `State+Except` | combined monad, run, error policy | pinned WP, explicit transactional model |
| finite iterator | next, done, breaks/continues | decrease, invariant, ordered visit |
| deterministic map | lookup/insert/keys | equality/hash law, stable enumeration |
| name/path registry | lookup, intern, qualified path | deterministic identity and collision handling |
| text/byte builder | append, finish, freeze | observable immutability, amortized performance |
| compiler diagnostics | source position, error code, spans | typed failure, canonical ordering |
| target primitive/intrinsics | conversions, fixed-width ops, runtime calls | exact semantic correspondence per backend |

### 10.2 Library inclusion policy

**SHP2-LIB-1:** a source library operation is F1-admitted only if its exported signature, runtime/effect behavior, approved proof laws, transitive imports and TS/JS/Wasm/Rust lowering are all declared under the frozen feature manifest.

**SHP2-LIB-2:** typeclasses, `BEq`/`Ord`/`Hashable`, iterators and syntactic sugar must be restricted to registered, lawfully modeled operations. A method spelling `map` alone does not guarantee source method registration or target implementation.

**SHP2-LIB-3:** unsupported library versions MUST fail explicitly. No implicit reuse of a host JavaScript prototype, Go map, Rust standard-library method or tsc runtime helper may alter admitted source semantics.

### 10.3 External/compiler-host interface

The language used to implement the **pure compiler semantic core** may be fully closed and total; a useful command-line compiler necessarily interacts with host files, processes, environments and target toolchains.

**SHP2-HOST-1:** isolate IO, filesystem, process execution, Wasm host imports, native Rust FFI and toolchain invocation behind a typed provider/host boundary. Such wrappers have separately named assumptions and product/capability identities, not a `pscv-closed-v1` proof of the external world.

**SHP2-HOST-2:** the portable compiler source closure and the actual assembled runtime host closure must be separately enumerated. An external Lean parser/checker secretly called during a claimed *independent* self-host re-entry invalidates that claim.

**SHP2-HOST-3:** exact toolchain versions, runtime ABI, memory ownership, import/export signatures, target profiles and failure modes must be recorded. This applies equally to TypeScript compilation with `tsc` and native Rust source compilation with `rustc`.

