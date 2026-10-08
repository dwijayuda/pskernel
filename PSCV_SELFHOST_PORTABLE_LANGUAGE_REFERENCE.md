# PSCV Self-Host Portable Language Reference — Candidate Version 1.0

**Document kind:** standalone, proposed compiler-implementation *language profile reference*; **V1.1 research-audited draft**.  
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

[CompCert][R-COMPCERT] motivates pass-specific semantic preservation rather than assuming source typechecking proves compiled executables. [CakeML][R-CAKEML] demonstrates verified compiler/bootstrapping methodology. [Dafny][R-DAFNY] and [Verus][R-VERUS] motivate explicit invariants, decreasing measures, proof/executable separation and controlled heap effects. Verus explicitly separates spec, proof and exec modes [R-VERUS-MODES], whereas SHP2 retains the parent PSCV relevance rules. Ullrich and de Moura's peer-reviewed do Unchained study [R-DO-PAPER] and its Lean proof supplement [R-DO-SUPP] give formally studied translations for local mutation, early return and iteration. These precedents motivate the profile, but do not prove SHP2 implementation correctness or AI proof speed.

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


## 11. Backend-specific semantic obligations

### 11.1 One frontend meaning, four independent target representations

**SHP2-BE-1:** TS/JS/Wasm/Rust backends do **not** own SHP2 language definitions. All four compile the same checked, target-neutral runtime meaning and MUST preserve semantic effects, result/error values, numeric/text precision, constructor identity, evaluation order, function calls and declared host capabilities.

The canonical compiler pipeline from [PSC-V51] remains:

~~~text
Source + frozen SemanticProfile
        -> parse / resolve / elaborate
        -> CheckedCore
        -> PSCV-certified-source policy gate (when requesting verified output)
        -> erasure
        -> RuntimeIR -> ValidatedRuntimeIR
        -> Specialization
        -> target-IR / target generation
        -> independently checked target product and evidence bundle
~~~

Where current implementation exposes legacy `PsVerifiedIr*` names, do not confuse raw `PsErasedIrModule` or `PsValidatedIrModule` with logically certified source. Target validation is necessary but not a kernel theorem about compiler correctness.

### 11.2 Detailed four-target mapping

| Source semantic property | TypeScript source | Direct JavaScript | Direct WebAssembly | Rust source |
|---|---|---|---|---|
| `Nat/Int` | bigint/exact library, checked wrapper declarations | BigInt/exact library | arbitrary-precision runtime and declared memory model | exact integer library or proved specialization |
| fixed-width ints | explicit widths/checked ops, typed declarations | explicit widths/checked ops | i32/i64 plus conversion rules | u8…u64/i8…i64 with explicit arithmetic policy |
| bytes/UTF-8 | Uint8Array/bytes and typed byte positions | Uint8Array/bytes | fixed byte representation, import/export ABI | byte buffers and validated UTF-8 |
| ADTs | discriminated typed union + runtime tag | checked tag/payload shapes | variant encoding with typed constructors | enums/structs |
| records | typed product/object records | defined product/object representation | layout/indirections chosen per ABI | structs/immutable transforms |
| immutable closures | type-erased JS closure/env mapping | closure/env mapping | closure conversion and call tables | closure env or specializing code |
| local mutable `do` | generated TS locals/effect model | generated JS locals/effect model | locals/state machine | local `mut` or abstract state transitions |
| `Except` and state | tagged result, no implicit host `throw` | tagged result, no implicit host `throw` | explicit discriminant/ABI status | `Result`-like representation, no unmodeled panic |
| arrays/maps | checked library with stable iteration | checked library with stable iteration | explicit allocation, bounds/GC/RC | checked collections, deterministic enumeration |
| generic functions | type annotations + explicit specialization | specialization or dynamic shape with validation | monomorphization or owned runtime dispatch | monomorphization/generic emission |
| callable compiler | pinned `tsc` then JS runtime | executable from direct JS backend only | validated binary and explicit host adapter | pinned `rustc`/linker and native CLI |
| verification | source proof checked by kernel, NOT tsc | source proof checked by kernel, NOT JS engine | source proof checked by kernel, NOT Wasm validator | source proof checked by kernel, NOT rustc |
| preservation | checked source->TS->JS relation | checked source->JsIR->JS relation | checked source->WasmIR->binary/ABI relation | checked source->Rust->toolchain relation |

**SHP2-BE-2:** a JavaScript or TypeScript target emitter MUST NOT use IEEE-754 `Number` as an implementation of arbitrary `Nat` or `Int`. `BigInt` is a representation option but does not automatically implement every pinned `Int` division/remainder or conversion rule without verification.

**SHP2-BE-3:** generated TS public signatures, declarations and source maps MUST derive from checked source/public API meaning, not infer a generic type by reverse engineering one specialized emitted function. Type erasure does not remove the need for runtime guards enforcing source value invariants.

**SHP2-BE-4:** Wasm emission must pin the core feature set, Wasm32/Wasm64 target if relevant, heap/GC or linear memory model, host imports/exports, allocator, signedness, trap handling, recursion and full compiler input/output API. Core Wasm validation is not source-to-Wasm semantic preservation.

**SHP2-BE-5:** Rust emission MUST pin the target triple, compiler version, dependent crate/runtime versions, signed/unsigned arithmetic, panic/abort and FFI assumptions. The emitter MAY use Rust's borrow checker and efficient ownership internally without introducing Rust source lifetimes into ProofScript.

**SHP2-BE-6:** if any backend lacks a representation or correspondence for a source value or intrinsic, it MUST fail the requested target emission with a precise unsupported-capability error. It MUST NOT substitute an unchecked foreign library, `undefined`, unchecked cast, arbitrary `panic!` or a nonterminating fallback.

### 11.3 Example of a source-level Nat contract and target implementations

The following is a source-level numerical example:

~~~proofscript
function twice(x: Nat): Nat := {
  x + x
}
~~~

Its abstract meaning is `twice : Nat -> Nat`, `twice(x) = x + x` with exact unbounded Nat arithmetic. **Illustrative** target approaches, not generated code or currently tested PSCV emitters:

~~~text
Lean semantic reference:
  def twice (x : Nat) : Nat := x + x

TS/JS:
  use bigint or exact integer library and a checked nonnegative Nat wrapper.
  bigint addition alone does not enforce Nat domain constraints.

Rust:
  use an owned or borrowed arbitrary-precision unsigned integer runtime
  (or a validated proof-bounded fixed-width specialization).

Wasm:
  use the registered arbitrary-precision integer representation;
  i64 alone cannot implement unbounded Nat.

Future Go:
  use an explicit checked Nat wrapper over math/big rather than host int.
~~~

The library implementations must agree on inputs including 0, values near 2^53, very large values, boundaries and conversion errors. A short numeric example is not evidence that the entire compiler self-hosts.

## 12. Future backend portability: Python, PHP, Java, Go

A new mainstream backend requires a **BackendDescriptor**, an exact runtime semantic correspondence, actual target compilation/execution and a conformance corpus. It is not permitted to reinterpret any F0/S1 feature by using the target language's default semantics.

| Potential target | Useful runtime feature | Nonportable defaults that need adapters |
|---|---|---|
| Python | arbitrary-precision ints, productive data/AST code | dynamic types, truthiness, exceptions, string scalar indexing, hash/equality |
| PHP | byte-oriented strings and easy distribution | int range, implicit coercions, dynamic arrays, error/exceptions |
| Java | JVM portability, enums/classes, `BigInteger` | UTF-16 strings, fixed-width primitive overflow, heap reference identity |
| Go | explicit byte slices, `math/big`, simple loops | platform `int`, map iteration unspecified, `rune` replacement on invalid UTF-8, panic/`nil` |
| Other (C#, Swift, Kotlin, C, etc.) | platform-specific performance/distribution | runtime memory, FFI, effects and numeric representation |

**SHP2-FUTURE-1:** the core source language's mathematical integers, Unicode/bytes, ADTs, immutable closures, typed errors and deterministic iteration must be implementable in every future backend through a runtime shim if necessary. This is a *language design constraint*, not a claim those backends already exist.

**SHP2-FUTURE-2:** portable first-class proof/effect semantics are source checked; no Python type annotations, TypeScript type erasure, Go interfaces, Rust traits or Java generics can serve as the proof kernel. A future target compiler is a separate operational dependency with its own TCB/evidence entry.

**SHP2-FUTURE-3:** source-language features whose only plausible implementation depends on JS object identity, Rust lifetimes, WASM GC object identity or Go pointer mutability SHOULD be excluded from initial SHP2, despite target-local optimizations possibly using those internals.

## 13. Compiler-only self-hosting and kernel independence

### 13.1 Source closure versus compiler runtime

The surveyed [current status][PSC-STATUS] records a **compiler-only 55-module bootstrap** with no kernel package in that generated source closure; checked compiler production is mediated by a host checked-session interface [PSC-HOST]. This is an important ownership distinction.

**SHP2-BOOT-1:** a compiler called `fully self-hosted` must have a complete, frozen, transparently recorded source and **operational dependency closure**. A compiler that internally invokes a prebuilt Lean frontend to parse/elaborate/check new source during re-entry does not count as an independent PSCV self-host compiler.

**SHP2-BOOT-2:** a full distributed PSCV toolchain MAY keep a separately installed checker/provider if the evidence reports this dependency accurately. **Compiler-only self-hosting** and **standalone PSCV with independently owned PSKernel** are different milestones; the latter requires separate kernel-source/binary/provider proof and bootstrap evidence.

**SHP2-BOOT-3:** preserved `PSC1-selfhost-stable/1` remains the seed and rollback until a new compiler reproduces the required semantics, complete source closure and target artifacts. Do not bulk rewrite the stable compiler first or rely on tests that patch one source syntax case at a time.

### 13.2 Mandatory 4×4 complete compiler re-entry

Let `C[t]` be the *running whole compiler executable* built from the same pinned canonical `.ps` source closure for target `t`. The following is **the acceptance matrix**, not present-day achieved status:

| Executing full compiler | Emit TS | Emit direct JS | Emit direct Wasm | Emit Rust |
|---|---|---|---|---|
| C[TypeScript] | MUST | MUST | MUST | MUST |
| C[JavaScript] | MUST | MUST | MUST | MUST |
| C[Wasm] | MUST | MUST | MUST | MUST |
| C[Rust] | MUST | MUST | MUST | MUST |

**SHP2-BOOT-4:** for each cell, actually run the compiler, ingest full source through the declared host adapter, parse/elaborate/check using the named kernel provider, erase/validate/specialize the program, generate and validate the selected backend artifact, and record exact source, environment, provider and toolchain identities. A target-specific closure may include a declared host shell and an independent provider, but not an undeclared compiler seed.

**SHP2-BOOT-5:** stage0/1/2/3 fixed-point evidence is a different axis from the four-target dimension. Compare byte identities only for the same target, pinned toolchain and identical serialization/environment; compare **semantic behavior and independently checked intermediate identities** across different targets. TS source, JS text, Rust source and Wasm binary cannot meaningfully have identical bytes.

### 13.3 Lean-first → PSCV-owned migration gates

| Stage | Goal | Portable language effect | Acceptance |
|---|---|---|---|
| M0 | freeze PSC1 stable seed | none | old profile/fixed-point evidence preserved |
| M1 | freeze SHP2 grammar subset + environment | closed syntax, exact feature list | source-rule-to-test matrix agreed |
| M2 | implement typed errors, ADTs and runtime primitives | F0 data semantics | differential proofs/tests of runtime values |
| M3 | implement `do`, local mutation, finite `for` | F0 effect+control semantics | VCs/typing/target runtime agreement |
| M4 | Lean-host source/Core bridge | two frontend comparison path | faithful pinned elaboration + checked proof terms |
| M5 | native PSCV frontend parity | no source rewrite for second compiler | checked Core semantics correspondence |
| M6 | four-backend whole compiler | no backend-sensitive source conditionals | runnable complete TS/JS/Wasm/Rust compiler |
| M7 | 16-path independent re-entry | same canonical source | all cells, staging and host/dependency evidence |
| M8 | verification and preservation evidence | approved contracts, proofs, erasure | `PSCV-CERT` and separate backend claims |
| M9 | standalone PSKernel distribution | independent checker closure | owned kernel/provider/runtime evidence |

The profile upgrade does not force a new compiler implementation into the existing main compiler branch. It should be executed on an isolated branch and integrated only after preserving old checkpoints and passing source/semantic closure gates.

## 14. Machine-checkable conformance and negative-test catalog

The following test IDs are **proposed normative acceptance IDs**, not currently implemented test files. Each family must include success and rejection cases, a recorded rule mapping, and a target-by-target semantic result.

### 14.1 Source and elaboration

| Test ID family | Positive requirement | Negative requirement |
|---|---|---|
| SHP2-LEX-001 | valid nested comments, Unicode, exact byte spans | invalid UTF-8, newline in invalid string, unclosed comment |
| SHP2-LAYOUT-002 | only allowed newline layout for do/where | illegal ASI/semicolon separator |
| SHP2-CALL-003 | adjacent parenthesized calls and optional trailing commas | wrong adjacency and `f()`/`f(())` confusion |
| SHP2-BIND-004 | explicit/implicit/strict/instance binders | unexpected default and missing explicit arguments |
| SHP2-MODULE-005 | header imports, namespace, private/public identity | import after declarations, ambiguous opened names |
| SHP2-ENV-006 | frozen instances, numerals, coercions | unregistered instance or changed priority/order |
| SHP2-MATCH-007 | exhaustive typed ADT matches | impossible constructor or missing branch |
| SHP2-STRUCT-008 | typed record construction and update | missing/duplicate/wrong-type field |
| SHP2-GENERIC-009 | supported type arguments and calls | unground or unspecializable generic value |
| SHP2-TYPE-010 | dependent binder, indexed inductive, proof fields | invalid universes/indices or proof-as-runtime branch |

### 14.2 Totality, state, proofs and erasure

| Test ID family | Positive requirement | Negative requirement |
|---|---|---|
| SHP2-REC-011 | strict structural recursion | same-size/non-subterm call accepted in error |
| SHP2-WF-012 | valid measure/decreasing proof | unproved decreasing or `partial` |
| SHP2-MUT-013 | scoped `let mut` and immutable observation | escaped mutable alias or invalid assignment target |
| SHP2-FOR-014 | finite iterator, invariant, correct break/continue | nonfinite cursor or bypassed exit VC |
| SHP2-RETURN-015 | early return obeys postcondition | forgotten postcondition on early branch |
| SHP2-STATE-016 | exact State+Except success/rollback model | error branch leaks state or unregistered WP |
| SHP2-ERROR-017 | typed success/error contracts | implicit host throw counted as accepted `Except` |
| SHP2-CONTRACT-018 | approved independent requires/ensures | false/missing/vacuous contract or dropped call precondition |
| SHP2-TRUST-019 | exact kernel-checked allowed proof closure | user axiom, imported axiom, proof hole or runtime noncomputable |
| SHP2-GHOST-020 | verified erase-only ghost behavior | ghost influences return/emitted bytes/side effects |
| SHP2-EXHAUST-021 | typed incomplete/resource error | budget exhaustion returns fabricated success or false checking conclusion |

### 14.3 Four-backend semantic and self-host matrix

| Test ID family | Target and behavior |
|---|---|
| SHP2-NAT-022 | huge Nat/Int, sign, 2^53 boundary, division/rem semantics across TS/JS/Wasm/Rust |
| SHP2-WIDTH-023 | all admitted UInt/Int widths, overflow, signedness, conversions, 32/64 target sizes |
| SHP2-UTF8-024 | invalid byte sequences, multibyte scalar offsets, deep slicing and source spans |
| SHP2-ARRAY-025 | bounds, append, immutability and empty/large arrays |
| SHP2-MAP-026 | collision/order, deterministic declaration serialization, repeated hashes |
| SHP2-CLOSURE-027 | closures, generic specialization, lifetime-safe target representations |
| SHP2-ABI-028 | actual Wasm engine, memory/GC/ref profile, signed imports/exports and host capabilities |
| SHP2-TS-029 | pinned tsc, typed public declarations and JS output behavior |
| SHP2-JS-030 | independent JsIR/direct JS output without mandatory tsc |
| SHP2-RUST-031 | pinned rustc/target triple and emitted native compiler behavior |
| SHP2-BOOT-032 | *every* cell in 4×4 compiler-to-target matrix, same canonical import closure |
| SHP2-PROVIDER-033 | actual checked-session and independently named kernel provider dependency |
| SHP2-PRESERVE-034 | each backend's preservation theorem/checker assumptions separated from typecheck |
| SHP2-AI-035 | held-out proof-maintenance experiment with kernel replay and no specification edits |

For each case record: exact source, expected semantic outcome, target, compiler/toolchain hashes, Standard environment digest, imported axiom/host assumptions, proof/VC status and actual observed execution. Reject ungrounded `pass` tags or a simulated/emulated target that was not really run.

## 15. Research-to-implementation proof obligations

The following relations are **verification targets**, not theorems already present in the repository.

### 15.1 Source elaboration fidelity

~~~text
AcceptedSHP2(S, Env)
AND ElaborateLean(S, Env) = C_Lean
AND LeanKernelChecks(C_Lean)
=> SourceSemantics(S, Env) ~ CoreSemantics(C_Lean, Env)
~~~

The implication requires a source-fidelity theorem or independent checker for the concrete lowering. A Lean source policy scanner, Lean type checker alone, or handwritten `.ps`→`.lean` printer is insufficient for proving the relation.

### 15.2 Two independent frontends

~~~text
LeanFrontend(S)    -> CheckedLeanCore
PSCVFrontend(S)    -> CheckedPscvCore

Required:
  Correspond(CheckedLeanCore, CheckedPscvCore, pinnedSemanticProfile)
  ∧ KnownAssumptions(LeanProvider, PSKernelProvider)
~~~

Double acceptance provides differential evidence; it is not automatically a proof of equivalence or of kernel soundness.

### 15.3 Core to runtime and targets

~~~text
CheckedCore(C)
∧ ApprovedSpec(C) ∧ AxiomAndEffectClosure(C)
∧ TotalityAndVCClosure(C) ∧ GhostErasureSafe(C)
∧ EraseAndValidate(C) = R
=> RuntimeCorrespondence(C, R)

ValidatedRuntimeIR(R) ∧ Compile(t, R) = Program_t
∧ TargetValid(t, Program_t)
∧ TargetCorrespondence(t, R, Program_t)
=> AllowedObservations(R) encompass Observations(Program_t)
~~~

CompCert's pass-preservation architecture [R-COMPCERT] provides a model for these distinct claims, but is not a theorem about PSCV.

### 15.4 Explicit weakest-precondition/state obligations

~~~text
For every admitted state/exception program:
  Correct initiation of local state;
  Registered effect transformer and proof of its laws;
  Every normal and error return establishes respective postcondition;
  Every early Return/Break/Continue exit satisfies frame and invariant;
  Every loop iteration maintains invariant and decreases required measure;
  All ghost data erased without observable effect;
  Every imported proof theorem kernel checked with approved assumptions.
~~~

Use module-local theorem/property IDs to prevent AI-generated speculative proof search from silently altering the statement being proved.

### 15.5 Compiler self-host is a separate theorem/evidence family

A stage1 compiler compiling itself into stage2, then stage2 into stage3, with canonical identity stability shows bootstrap reproducibility under fixed inputs; it **does not by itself imply source-to-target semantics preservation or program correctness**. Preserve the Claim Lattice from [PSC-V51].


## 16. AI-assisted proof ergonomics: executable evaluation protocol

The language is intentionally designed for AI proof engineering, but a source language is not made easier to prove merely by adding syntax or removing code lines. Formal Lean do-notation translation research [R-DO-PAPER][R-DO-SUPP] is evidence of a possible proof-friendly desugaring strategy, not evidence that PSCV's currently unimplemented source lowering is already verified. Verification effort includes the elaborated Core theorem, effect VCs, induction/termination obligations, library lemmas, imported axioms, and post-edit proof maintenance.

### 16.1 Profile-level proof simplifications

**SHP2-AI-1:** mutable local variables and finite iteration must desugar into small typed state/SSA obligations; aliasable heap effects are excluded. This follows the design principles of Lean `do` [R-LEAN-DO], plus contracts and invariant reasoning studied in [R-DAFNY] and [R-VERUS]. It is not a proof of SHP2's current implementation.

**SHP2-AI-2:** every compiler library operation used by multiple passes SHOULD expose a stable theorem API: bounds, construction, lookup/update, monotonicity, serialization, source-span preservation, input/output typing and failure behavior. AI proof attempts SHOULD depend on these lemmas rather than unfold the whole library implementation.

**SHP2-AI-3:** successful proof search MUST end in an accepted proof term under the pinned kernel and approved axiom closure; tactic success, SMT output, runtime tests, model agreement and AI confidence do not count.

**SHP2-AI-4:** approved specifications must have a separately reviewed stable identity. Proof-producing agents MAY refactor code or introduce lemmas; they MUST NOT weaken required postconditions, mark a helper as out-of-scope, introduce unchecked assumptions or change the acceptance policy merely to obtain green tests.

### 16.2 Controlled benchmark (not performed here)

Select a **24-task frozen corpus** covering: UTF-8 cursor bounds, parser progress/recovery, AST substitution, well-scopedness, instance resolution, unification occurs-check, reduction, total worklists, State+Except rollback, typed IR validation, specialization correspondence, JS/TS declaration identities, Wasm stack/ABI and deterministic Rust code generation.

Compare for the same approved property and same underlying algorithm where possible:

- **A:** current PSC1 explicit workers and boilerplate.
- **B:** SHP2 local `do`/mutation/finite iteration.
- **C:** SHP2 pure fold/structural-recursion implementation.

Use pinned Lean/PSKernel and library versions, equal tools/agent model/token/time budgets, multiple independent proof attempts for each task (five as a starting measurement design, not a requirement on the language's semantics). Hold the formal theorem statement and host runtime semantics constant; do not alter the requirement to favor a style.

Measure:
1. independently replayed proof completion and exact proved obligation count;
2. admitted axioms/spec-coverage and unsound/vacuous proposals rejected;
3. median and tail wall-clock and token/tool-call cost;
4. normalized VC size, number of state variables, imports and proof dependency depth;
5. repair effort when source is behavior-preservingly refactored;
6. compilation/runtime CPU, memory, generated size and deep-stack behavior;
7. number of manual supporting lemmas and timeouts.

**SHP2-AI-5:** if the measured pure style proves faster for a subsystem, use that style; SHP2 is a **capability subset**, not a demand that every compiler function be imperative. Honest proof-efficiency recommendations are conditional on controlled results and independent theorem replay.

## 16A. Pinned-source audit and semantic crosswalk (V1.1)

**Research purpose:** replace loosely inferred portability claims with verifiable language-reference correspondences. Pinned PSCV and upstream-source snapshots are normative or version-stable evidence; newer official manuals are informative unless the parent PSCV semantic profile explicitly adopts their rules. A working hyperlink is *not by itself* implementation evidence.

### 16A.1 Five-language and verified-compiler research matrix

| Topic | Primary authoritative reference | Explicit PSCV self-host source restriction | Falsifying conformance test |
|---|---|---|---|
| Lean inductives, recursors | [R-LEAN-IND] and [PSC-LANG] Ch. 4, 13, 16–18 | total ADTs/recursors without new logical primitive | reject negative or ill-typed inductive/recursive construction |
| Lean `do`, `ForIn`, local mutation | [R-LEAN-DO] and [R-DO-FORMAL] | finite `for` and `let mut` lower to checked typed state | compare normal, return, break, continue and error exits |
| Lean recursion, `partial` | [R-LEAN-REC] | no partial reachable runtime definition | reject failed decreasing proof and bogus fuel success |
| TypeScript generics | [R-TS-GEN] | bounded runtime specialization with exact source types | reject missing generic arguments/unsupported higher-rank closure |
| TypeScript narrowing | [R-TS-NARROW] | tagged unions implement, but do not define, inductive semantics | reject unregistered constructor/runtime tag |
| TypeScript type erasure | [R-TS-ERASE], [R-TS-BASIC] | typed TS output is not a runtime validator/kernel proof | incorrectly-tagged emitted JS value must fail explicitly |
| ECMAScript Number/BigInt | [R-ECMA-2026] | no narrowing unbounded `Nat` or `Int` to Number | compare 2^53±1 and huge signed/unsigned values |
| ECMAScript String | [R-ECMA-2026] | UTF-8 byte positions never JS 16-bit code-unit indices | non-BMP Unicode and malformed byte source spans |
| Rust expression order | [R-RUST-EXPR] | preserve source evaluation/error behavior | nested calls with distinct error traces |
| Rust integer overflow | [R-RUST-OVERFLOW] | pinned PSCV fixed-width semantics on all build modes | same source edge results with overflow checking on/off |
| Rust ownership and unsafe | [R-RUST-BORROW] | backend may use ownership; SHP2 has no aliased pointer API | escaped mutable reference/observable pointer identity rejects |
| Go maps | [R-GO-SPEC] | hash lookup never determines compiler artifact order | randomized insertion/collisions have same canonical bytes |
| Go UTF-8 range | [R-GO-SPEC] | no replacement-rune swallowing invalid source bytes | malformed byte sequence diagnosed without loss |
| CompCert front-end caveat | [R-COMPCERT-FRONTEND], [R-COMPCERT] | parser/desugaring requires independent evidence | checked target IR cannot mask wrong source parse |
| CakeML bootstrap | [R-CAKEML] | preserve frozen stage source and semantic identity | self-host compiler actually re-enters source, no Lean fallback |
| Dafny multi-target | [R-DAFNY] | each backend needs a runtime correspondence and admitted FFI model | target-dependent exception/string differences fail |
| Verus modes | [R-VERUS-MODES] | existing PSCV spec/proof/exec classification stays authoritative | ghost runtime branch fails certified erasure |

**Inference boundary:** these sources support *feasibility and risks of source features*; none supplies a theorem or controlled AI proof-efficiency study for SHP2. Do not treat published Lean `do` correctness as proof of PSCV's future translator.

### 16A.2 Actual compiler-code patterns and bootstrap boundaries

The [pinned Lean 4.35 LCNF compiler][R-LEAN-CORE] uses typed inductives/records, Reader/State compiler monads, local helpers, early return, finite loops, local mutation and also partial definitions. SHP2 adopts the first group with explicit proof obligations and excludes uncontrolled partial executable functions. The [pinned Rust MIR pass][R-RUST-MIR] and [Go compiler README][R-GO-COMPILER] provide evidence for multi-stage IRs and practical loops, not for copying their target language's native runtime semantics.

The surveyed [existing source profile][PSC-SEED] explicitly restricts mutual recursion, termination commands, tactics, mutable local bindings and loops; [source standard][PSC-SRC-STANDARD] calls these *bootstrap restrictions*, not the permanent programming language. [Current status][PSC-STATUS] records a 55-module **compiler-only** source closure excluding the kernel. Production checking goes through the [checked host service][PSC-HOST], not a standalone unchecked bootstrap driver facade. Source-profile migration cannot silently change the kernel/provider ownership boundary.

### 16A.3 Pinned rule-ID trace verified against the PSCV language reference

| SHP2 concern | Exact parent rule identity | Required interpretation |
|---|---|---|
| Whole-file parsing | `[grammar.source-file]`, `[grammar.closure]` | full SourceFile, EOF, no raw Lean fallback |
| Call-gap and empty calls | `[grammar.parenthesized-call-adjacency]` and Chapters 9–10 | `f()` is not `f(())`, parent static call rules |
| Total structural/mutual recursion | `[recursion.structural]`, `[recursion.mutual]` | strict subterm or pinned total joint check |
| Well-founded recursion | `[pscv.recursion.well-founded]` | kernel-accepted decrease proof |
| Local mutation and sequencing | `[pscv.do.verified]`, `[pscv.do.local-mutation]` | checked local effect state, no escaping aliases |
| Finite iteration | `[pscv.loop.for]` | verified iterator + loop VCs |
| Parent general while | `[pscv.loop.while]`, `[pscv.grammar.loop-clauses]` | parent admits while; SHP2 additionally excludes from source |
| Verified effects | `[pscv.effect.standard]`, `[pscv.effect.frame]` | approved pure/Reader/State/Except and frame rules |
| Errors and postconditions | `[pscv.effect.error-post]` | distinct success and error branches |
| Independent specification | `[pscv.spec.coverage]` | meaningful approved spec, not mere tautology |
| Verified emission | `[pscv.no-proof-no-build]` | unresolved source/assumption/erasure/proofs block certification |

All names in this table occur in the audited 4.35-rc3-pinned PSCV source. A *rule ID* names the intended source contract; it is not a theorem about the current compiler.

### 16A.4 Feature-maturity record (future manifest, not existing file)

~~~text
SHP2FeatureRecord = {
  id:                  stable feature ID
  parentRules:         exact PSCV rule IDs
  sourceProfile:       pinned source/env digest
  leanCoreRelation:    checked relation or open
  nativeCoreRelation:  checked relation or open
  totality:            structural/decrease/finite iterator evidence
  effectModel:         registered WP and State/Error semantics
  runtime:             abstract value model
  targets:             TS, JS, Wasm, Rust evidence each
  proofClosure:        assumptions, approved spec, ghosts, erasure
  operationalStatus:   not implemented / checked / measured / certified
}
~~~

This is a **requirements sketch**, not executable JSON or a claim that the registry exists. Evidence is per target; a backend that cannot implement a source feature must reject target emission rather than reinterpret source acceptance.

### 16A.5 State/error monad order is semantic, not a compiler convenience

The parent PSCV reference requires verified State, Reader and typed Except-like effects but does not automatically authorize every transformer composition. For a future library the following **proposed** types have different meanings:

~~~text
Transactional effect: State -> Except Error (Value,State)
  write(1); error(e)   => Error(e), no successful final state

State-retaining effect: State -> (Except Error Value,State)
  write(1); error(e)   => (Error(e),1), final state available
~~~

Choosing one type without an approved WP, frame theorem, imported law identity and four-target representation is unsound. A pure transformer is not a promise to undo real filesystem/network side effects. The initial SHP2 source may admit only registered single effects while a combined effect remains F1.

### 16A.6 Dependent proof indices vs runtime value representation

SHP2 inherits `Prop`, dependent Pi, indexed inductives, `Subtype` and `Fin`. Proof-only indices may be erased only when source semantics and backend erasure remain observationally equivalent. Runtime-relevant dependent indices/closures require a *separate* validated representation and specialization mechanism. The source checker must produce identical typing judgments across target choices; an unsupported target representation fails **after** source checking, not as a target-dependent type error.

A proof of array index in `Fin n` does not, without an additional backend preservation contract, prove that arbitrary Wasm linear memory access or JS buffer indexing is physically safe. Keep proof-theory evidence separate from runtime ABI and allocation assumptions.

### 16A.7 Source and certificate version locks

A conforming future release record MUST bind source and transitive import closure, approved spec identities, frozen grammar and environment digest, pinned Lean/PSKernel checker interface, deterministic classes/coercions, registered WPs, runtime primitive contracts, all four target backend descriptors, actual toolchain versions, proof/erasure/correspondence evidence, and exact host capability/ABI assumptions. The currently **PENDING** Standard environment digest remains an external release blocker. This document creates no imaginary digest or certificate.

## 16B. Implementation-independent semantic obligations and falsifiable conformance cases

This appendix defines **checks needed before a compiler implementation can claim conformance**, not new PSCV type theory or operational semantics. Only the approved parent source reference can own the exact interpretation of source constructs.

### 16B.1 Three-stage source language acceptance

~~~text
Γ; E ⊢ module : SHP2-source
 iff
   ParentPSCVParse(module, frozenGrammar) = syntaxTree
   AND ParentPSCVElaborate(E, syntaxTree) = typedCore
   AND FeatureFilter(syntaxTree, SHP2FeatureTable) = allowed
   AND ExactImportsAndRegistries(E, module)
   AND NoForbiddenExecutableDependency(typedCore)
~~~

1. **Syntax acceptance:** parse the exact inherited SourceFile and EOF, no arbitrary Lean/JS/TS/Rust fallback.
2. **Static semantics:** type, name, instance, coercion, totality, effect and source inference rules use the pinned standard environment and parent PSCV semantics.
3. **SHP2 compiler-source admission:** check extra restrictions on entire syntactic and imported executable dependency closure; the full parent may admit constructs that the source profile excludes.

Successful elaboration is not PSCV-CERT and does not prove target preservation. A target that cannot lower valid source fails **target emission**, not source typing.

### 16B.2 Distinct observable exits of verified do

~~~text
ControlOutcome A E :=
    Normal(A)
  | Return(A)
  | Break
  | Continue
  | Error(E)
~~~

This is checker pseudocode, not an added Core inductive. The concrete translation remains owned by `PSCV-VERIFY-v1` and registered effects. A portable implementation MUST preserve these branches:
- `Normal` satisfies its typed result and specified postcondition.
- `Return` exits the intended surrounding block early, satisfies its postcondition and suppresses subsequent effects.
- `Break` exits the current registered loop and discharges the break frame/exit obligation.
- `Continue` skips the remainder of the body while preserving the loop invariant and progressing the finite iterator.
- `Error` obeys the exact registered typed error and state rollback/retention model, never undefined/panic as success.
- `Ghost` changes cannot affect any runtime branch, error, externally modeled effect, source result or emitted bytes after erasure.

The falsifier is a small `do` program with a local mutable accumulator and a return, break, continue or error at the same reachable point; compare *both* return values and side-effect traces after all four target emissions. This prevents a target that "runs" but violates early-exit semantics from passing conformance.

### 16B.3 Source examples and negative cases

These examples are **illustrative parent grammar shapes**, not test executions. An admitted source example requires a real parser, elaborator, proof checker and target run before obtaining SHP2-TARGET evidence.

~~~proofscript
function identity {α: Type}(x: α): α := {
  x
}

function callNat(x: Nat): Nat := {
  identity(x)
}

function withLocals(): Nat := do {
  let mut n := 0
  n := n + 1
  return n
}
~~~

| Negative family | Failure ownership | Reason |
|---|---|---|
| Multiple semicolon-delimited terms in one function body | parent parser | braced definition body contains one term, not a JS block |
| `f(())` mistaken for `f()` | elaboration | Unit argument differs from empty argument/default completion |
| Numeric `if (123)` | elaboration | no JS truthiness |
| Import after non-import top-level command | parent import header rule | grammar does not allow delayed import |
| `partial def` in executable source | parent PSCV profile | verified compiler must be total |
| Semicolon-separated source do statements | parent PSCV grammar | defined newline sequencing required |
| Parent-valid general `while` | SHP2 filter | excluded from initial compiler source only |
| Runtime branch on ghost value | certification/erasure | no proof-ghost executable dependence |
| Imported user axiom/proof hole | proof/trust closure | no unchecked theorem authority |
| Arbitrarily large Nat mapped into JS Number | target emission/correspondence | source exactness must be preserved |
| Exhausted reduction reported as semantic inequality | checker operation | unknown/resource limit not false rejection |

Negative families above are not executable code fixtures; concrete conformance implementation MUST instantiate them with complete, fully parsed programs and stable expected diagnostic identifiers.

### 16B.4 Target-neutral runtime conformance vectors

| ID | Source observation and boundary case | Targets / relevant false acceptance |
|---|---|---|
| CV-NAT-01 | `Nat` above 2^53 and negative `Int` extremes | JS/TS Number truncation, Rust/Wasm width loss |
| CV-ARITH-02 | Nat/Int division, remainder, subtraction at boundaries | host-specific quotient/remainder and underflow |
| CV-WIDTH-03 | UInt/Int fixed widths, shifts, overflow, word-size narrowing | Rust debug/release difference, JS 32-bit implicit operators |
| CV-UTF8-04 | ASCII, multibyte, non-BMP, malformed source bytes | JS/Java UTF-16 indexing, Go replacement rune |
| CV-ADT-05 | nested inductive constructor and erased proof fields | forged variant, invalid tagged runtime value |
| CV-ARRAY-06 | index 0, length-1, length, huge index, empty array | silent undefined, trap/panic or negative index |
| CV-MAP-07 | same bindings, different hash seeds, collisions and insertion order | changed deterministic output hash |
| CV-CLOSURE-08 | generic specialization and nested immutable captures | invalid closure conversion or type erasure |
| CV-EFFECT-09 | State+Except failure after state change | transactional versus state-retaining mismatch |
| CV-FOR-10 | finite iterator, break, continue, return and error | wrong number/order of effects or exit |
| CV-DEEP-11 | deep AST/list and approved worklist | JS/Wasm stack assumptions |
| CV-SOURCE-12 | UTF-8 byte span and line-ending conversion | wrong source maps and diagnostics |
| CV-IR-13 | malformed unknown type/ref/constructor | unchecked target IR acceptance |
| CV-WASM-14 | control/operand stack, locals, ABI imports/exports, memory | Wasm validation alone confused with preservation |
| CV-BOOT-15 | entire emitted compiler re-enters its full source | hidden stage0/Lean fallback |

Expected values MUST come from the approved PSCV source semantics or independently checked reference, not solely from copying one target's output. Do not invent a signed division/remainder policy without mechanically extracting its pinned parent definition; the test must reflect the actual specification.

For successful pure operations, compare source values and canonical output artifacts; for typed failures, compare exact error categories and declared observations. External IO is compared only under a stated capability/host assumption. When unknown/resource exhaustion occurs, it may not be promoted to semantic success or a proof of falsehood.

### 16B.5 Per-feature implementation and certification gates

~~~text
F0-or-F1 feature promotion requires:
  [ ] exact parent grammar/rule IDs and source negative cases
  [ ] frozen environment/name/instance/coercion meaning and digest
  [ ] source typing, total recursion and local WP/VC evidence
  [ ] approved effect, error, frame, loop and ghost obligations where relevant
  [ ] checked Core and precise imported assumption closure
  [ ] Core erasure and target-neutral RuntimeIR correspondence
  [ ] TS source, pinned tsc and JS runtime execution
  [ ] independent direct JS source without mandatory tsc
  [ ] Wasm binary, actual engine, full ABI and host adapter
  [ ] Rust source, pinned rustc, and real native execution
  [ ] malformed/negative/resource and large-input target conformance
  [ ] entire canonical compiler import/dependency closure compatibility

Additional certified-release conditions:
  [ ] independent approved specification coverage
  [ ] kernel-accepted proof terms, no disallowed imported axioms
  [ ] totality, loop/early-exit/frame and effect closure
  [ ] ghost/proof erasure evidence
  [ ] target preservation or independently validated equivalence
  [ ] PSCV-CERT issuance only when all mandatory requirements are closed
~~~

Each unchecked box is an **implementation blocker**, not a documentation omission. The source profile may still be proposed while these boxes remain open. No compiler passes this gate by accepting only a small `Good.ps` demo.

### 16B.6 Compiler-only vs standalone-kernel self-host

The [surveyed status][PSC-STATUS] describes a 55-module compiler-only seed without the kernel in its generated closure. Therefore a future 16-path matrix has two explicit inventories:
1. compiler/runtime import closure, executable and host process/Wasm/Node/native adapters; and
2. checked-session provider/kernel identity, external logical assumptions and owned/non-owned status.

A compiler using a separately declared provider may qualify as **compiler-only self-hosted**, provided the source compiler can re-enter its own complete parser/elaborator/IR/backend pipeline without a hidden Lean/PSC1 compiler. A standalone PSCV+PSKernel distribution requires independent kernel-source, binary and provider/interface evidence. The two claims cannot be conflated.

### 16B.7 AI proof records and specification integrity

A proof/VC record MUST bind immutable approved specification identity, exact source/Core/import hashes, elaboration environment, termination/effect/ghost/frame obligations, proof-term replay outcome, allowed axioms, kernel checker identity and independently identified backend preservation assumptions. AI agents MAY propose code, lemmas and proof terms, but cannot change the approved specification or weaken source/certificate acceptance to obtain a green result.

## 17. Evaluation of the proposed language reference

### 17.1 Scope of the score

The numerical score below is an **expert engineering judgment about the projected design**, supported by primary-language rules and traceable source constraints—not a measured empirical result or a formal kernel theorem. It compares alternative source-language approaches using the *same weights* across all eleven user-requested criteria. Individual candidate values range from 0 (poor fit) to 5 (excellent fit); `Score = Σ weight × rating / 5` with max 100.

**Do not combine or directly compare this score** with the companion V3 research document's self-audited 97/100 **documentation-coverage** checklist. They answer different questions. A high design-preference rating does not mean implemented self-host/target proof closure.

### 17.2 Weighted eleven-criterion comparison

| Criterion | Weight | PSC1 | Lean full | Rust-style | Go-style | Proposed SHP2 |
|---|---:|---:|---:|---:|---:|---:|
| Soundness and source fidelity | 13 | 3.4 | 3.9 | 3.7 | 2.9 | 4.6 |
| Formal verification and AI proof efficiency | 18 | 3.0 | 3.4 | 3.3 | 2.3 | 4.3 |
| Malformed/adversarial-input robustness | 8 | 3.7 | 3.6 | 3.8 | 3.1 | 4.5 |
| Compatibility completeness | 8 | 1.8 | 4.9 | 4.2 | 3.8 | 4.7 |
| Architecture and semantic boundaries | 9 | 3.0 | 4.2 | 4.1 | 3.5 | 4.7 |
| Runtime/compiler performance | 8 | 2.0 | 4.2 | 4.5 | 4.4 | 4.2 |
| Four-backend portability | 10 | 4.0 | 1.6 | 2.4 | 3.4 | 4.5 |
| Longevity/versioning | 6 | 2.8 | 4.5 | 4.4 | 4.5 | 4.6 |
| Interoperability | 5 | 2.6 | 3.5 | 4.2 | 4.0 | 4.4 |
| Full self-host/bootstrap | 10 | 3.9 | 2.5 | 3.0 | 3.1 | 4.5 |
| Auditability and conformance evidence | 5 | 3.4 | 3.4 | 3.8 | 3.2 | 4.6 |
| **Weighted conditional design preference /100** | **100** | **62.2** | **70.8** | **73.0** | **65.8** | **89.9** |

### 17.3 Why SHP2 scores as it does

| Criterion | Source-backed design choice | Missing evidence / limitation |
|---|---|---|
| Soundness/fidelity | restrictive parent grammar and Core, source-to-Lean and Core-to-target proof relations | approved standard environment still lacks final digest; no completed lowering proofs |
| Formal/metatheoretic verification performance | total P0, typed local state, finite loops, explicit error/ghost frames, proof-local abstractions | AI proof-completion comparison and theorem libraries not measured |
| Robustness | typed rejection/exhaustion, transitive imported trust, negative source/IR/runtime corpus | malicious/malformed input campaigns not executed |
| Compatibility | entire reference based on `pscv-v1` syntax/theory; full language remains larger | some F1 library/WP identities and elaborator parity unfinished |
| Architecture | V5.1 semantic spine, separation of compiler and kernel provider, backend-neutral RuntimeIR | actual Lean-Core RuntimeIR adapter not implemented |
| Performance | byte builders, finite loops, deterministic maps, worklists | JS/Wasm/Rust/TS runtime benchmarks not run |
| Portability | target-neutral numeric/string/error/ADT semantics and 4-target mapping | big integers, Wasm ABI and runtime libraries not established everywhere |
| Longevity | one `.ps` source and pinned versioned source semantics | future PSCV/Lean versions require explicit compatibility work |
| Interoperability | declared host adapters, TS declarations and runtime interfaces | foreign toolchains, WIT/Component ABI evidence not closed |
| Self-host/bootstrap | 16-cell matrix, stage dimensions, frozen seed, independent checker ownership | 4 whole compiler re-entry executions not demonstrated |
| Auditability | rule IDs, complete acceptance/negative matrix, primary-source trace and unmixed assurance claims | implementation conformance and independent review pending |

The recommendation is to choose SHP2 as the **prospective long-term source language**, while keeping the **current PSC1 seed** intact. Do not declare the candidate feature profile operationally available until actual compiler and backend implementations meet the stated acceptance tests.

### 17.4 Independent evaluation distinctions

An independent reviewer should separately assess:

- **Reference clarity/completeness:** are grammar ownership, selection restrictions, static/operational rules, effects, runtime semantics, target mapping and examples internally consistent?
- **Language suitability:** are the chosen features practical without making VCs/alias reasoning disproportionately harder?
- **Actual proof efficiency:** controlled same-theorem AI-proof comparison, independent kernel replay, axiom/spec integrity.
- **Operational portability:** actual full-closure compiler tests under four distinct runtimes.
- **Assurance strength:** source meaning, PSKernel soundness, kernel provider identity, erasure and backend preservation.

These outcomes may differ. A clear reference can earn a high documentation score while the language implementation remains unproved or unavailable.

### 17.5 Known unresolved issues (do not silently assume)

- The parent `STD-ENV-PSCV-V1-L435RC3-RC1.json` SHA-256 is **PENDING/release-blocking**; no frozen final manifest has been verified in this research.
- There is no currently demonstrated complete SHP2 grammar/elaborator/code generator in PR #81 or in the existing PSC1 source compiler.
- The exact composition of verified State+Except effects and their registered WP must be resolved under `PSCV-VERIFY-v1` before admitting the combined effect.
- The full self-host compiler's runtime Nat/Int, UTF-8, deterministic map and finite iterator conformance need four-target independent execution.
- The semantics of all target host ABI, Wasm memory/GC and provider sessions need approved exact manifests and separate evidence.
- The full 16 producer-target re-entry matrix has not been observed.
- Target compiler semantic preservation and kernel metatheoretic assurance are separate unresolved efforts.
- AI formal proof performance and proof-maintenance benefit of SHP2 versus pure/PSC1 source are **not measured**.
- Illustrative source and target snippets are not machine-validated artifacts.
- Future Python/PHP/Java/Go backend feasibility is architectural design intent, not an implemented feature claim.

## 18. Recommendation, staged adoption, and end-state

**Recommendation:** **conditionally adopt the design** of `PSCV-selfhost-portable/2` as the desired compiler implementation-language profile, subject to feature conformance and benchmark results; retain `PSC1-selfhost-stable/1` as a preserved seed.

The most valuable implementation family is `do + locally scoped let mut + typed Except + finite for` **on top of a small total Core**. It provides the language features actual Lean/Rust/Go compiler developers use while leaving a more constrained semantic/proof boundary than unrestricted host language features.

The eventual *one-source, two-frontends* architecture is:

~~~text
                           SHP2 ProofScript (.ps) compiler source
                                         |
                       +-----------------+------------------+
                       |                                    |
                 Lean-hosted path                    Native PSCV path
                       |                                    |
             Lean source/Core checked            PSCV Core + PSKernel checked
                       |                                    |
             correspondence + evidence        correspondence + evidence
                       +-----------------+------------------+
                                         |
                            certified or explicit
                           DEVELOPMENT-UNVERIFIED
                                         |
                   target-neutral erasure / validated RuntimeIR
                                         |
                           specialization / target IR
                                         |
                      +---------+---------+---------+
                      |         |         |         |
                     TS      direct JS   Wasm      Rust
                                         |
                        full-closure compiler re-entry
                         (16 producer/target paths)
~~~

Development compiler pipelines may generate unverified artifacts before proofs are complete, but MUST NOT imply certification. Source, instance/environment, proof, RuntimeIR and target semantics are separate claims whose evidence cannot be substituted.

**Adoption order:** (1) freeze profile and Standard manifest, (2) implement exact ByteArray/Nat/Int/Array/Except/State libraries and semantics, (3) add F0 `do`/local mutation/finite loop lowering, (4) compare Lean-hosted and own PSCV elaboration, (5) integrate checked RuntimeIR and all four emitters, (6) port whole compiler source package-by-package, (7) run complete 16-cell self-host and host-provider closure tests, (8) measure AI proof performance, (9) finish certification and backend-preservation proof/evidence.

## 19. Primary sources and repository evidence

These are live public language-reference URLs or commit-pinned repository sources. A newer reference version does not silently change the normative 4.35.0-rc3 PSCV pin.

[PSC-LANG]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md
[PSC-V51]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md
[PSC-RESEARCH]: https://github.com/dwijayuda/pskernel/blob/47a0f60d6cc8d255d7eb3a24e01bbc4f427a2c9b/PSCV_SELFHOST_PORTABLE.md
[PSC-STATUS]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/STATUS.md
[PSC-HOST]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/scripts/compiler-checked-service.mjs
[PSC-IR]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/packages/compiler-ir/src/Ps/CompilerIr/Model.lean

[R-LEAN-PIPE]: https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/
[R-LEAN-IND]: https://lean-lang.org/doc/reference/latest/The-Type-System/Inductive-Types/
[R-LEAN-DO]: https://lean-lang.org/doc/reference/latest/Functors___-Monads-and--do--Notation/Syntax/
[R-LEAN-REC]: https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/
[R-LEAN-STRING]: https://lean-lang.org/doc/reference/latest/Basic-Types/Strings/
[R-LEAN-INST]: https://lean-lang.org/doc/reference/latest/Type-Classes/Instance-Synthesis/
[R-TS-GEN]: https://www.typescriptlang.org/docs/handbook/2/generics.html
[R-TS-NARROW]: https://www.typescriptlang.org/docs/handbook/2/narrowing
[R-TS-ERASE]: https://www.typescriptlang.org/docs/handbook/typescript-from-scratch.html
[R-TS-OBJ]: https://www.typescriptlang.org/docs/handbook/2/objects
[R-TS-MODULE]: https://www.typescriptlang.org/docs/handbook/modules/reference
[R-ECMA]: https://tc39.es/ecma262/2026/
[R-RUST-EXPR]: https://doc.rust-lang.org/reference/expressions.html
[R-RUST-TYPES]: https://doc.rust-lang.org/reference/types.html
[R-RUST-BORROW]: https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html
[R-RUST-OVERFLOW]: https://doc.rust-lang.org/reference/expressions/operator-expr.html
[R-GO-SPEC]: https://go.dev/ref/spec
[R-COMPCERT]: https://compcert.org/doc/
[R-CAKEML]: https://cakeml.org/index.html
[R-DAFNY]: https://dafny.org/latest/DafnyRef/DafnyRef.html
[R-VERUS]: https://verus-lang.github.io/verus/guide/
[R-LEAN-CORE]: https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF
[R-DO-FORMAL]: https://www.microsoft.com/en-us/research/publication/do-unchained-embracing-local-imperativity-in-a-purely-functional-language/
[R-TS-BASIC]: https://www.typescriptlang.org/docs/handbook/2/basic-types.html
[R-ECMA-2026]: https://tc39.es/ecma262/2026/multipage/ecmascript-data-types-and-values.html
[R-RUST-MIR]: https://github.com/rust-lang/rust/blob/36aeef32c6c012e1af17af53a820aac042846c43/compiler/rustc_mir_transform/src/inline.rs
[R-RUST-OVERFLOW]: https://doc.rust-lang.org/reference/expressions/operator-expr.html
[R-GO-COMPILER]: https://github.com/golang/go/blob/3b98eddbcd66230a78c4893f32099b5d3045a334/src/cmd/compile/README.md
[R-COMPCERT-FRONTEND]: https://compcert.org/man/manual003.html
[R-VERUS-MODES]: https://verus-lang.github.io/verus/guide/modes.html
[PSC-SEED]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/selfhost-profile.json
[PSC-SRC-STANDARD]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/docs/SELFHOST_SOURCE_STANDARD.md
[R-VERUS-MODES]: https://verus-lang.github.io/verus/guide/modes.html
[R-DO-PAPER]: https://www.microsoft.com/en-us/research/publication/do-unchained-embracing-local-imperativity-in-a-purely-functional-language/
[R-DO-SUPP]: https://zenodo.org/records/6684085

---

**End of PSCV Self-Host Portable Language Reference v1.0 candidate. Its acceptance requirements are proposals until explicitly adopted and implemented; no normative PSCV source rule or verification certificate is overridden.**
