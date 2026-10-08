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

