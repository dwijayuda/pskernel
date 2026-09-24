# ProofScript self-hosting foundation plan

Status: **highest-priority ProofScript execution plan**

This plan supersedes the previous package/infrastructure-first ordering for
ProofScript work on `main`. The objective is to finish one stable language and
runtime foundation that can express the ProofScript compiler itself, first in a
bounded Lean-compatible `.lean` subset and then in native `.ps`, without
rewriting compiler infrastructure again after self-hosting starts.

Kernel conformance work is intentionally separate. The TypeScript Lean 4.34
kernel remains an independent checker and continues on the dedicated
`kernel/lean434-study-hardening` branch. ProofScript foundation work must not
modify kernel semantics merely to unblock a compiler feature.

## Priority override

Until the self-hosting foundation gates in this document are closed:

1. **Stop unrelated ProofScript infrastructure expansion.**
2. Do not add new LSP/editor/package-manager/browser/build-system features
   unless they are required to implement, exercise, or diagnose the
   self-hosting foundation.
3. Do not broaden tactics, macros, Lean compatibility, npm interoperability, or
   additional backends merely because the feature exists in Lean or
   TypeScript.
4. Add a language/runtime feature only when it is required by an identified
   compiler module or by a prerequisite standard-library abstraction.
5. Keep one semantic path:
   source -> Meta/Elab -> pskernel -> checked core -> erasure -> verified IR
   -> TypeScript -> JavaScript.
6. No second software checker, alternate IR, or automatic fallback may be
   introduced.
7. Host integration may stay TypeScript when it is genuinely a Node/npm/VS
   Code/TypeScript-API capability rather than ProofScript semantics.

## Reference workload

The implementation workload is derived from the pinned Lean 4.34 sources under:

- `study/lean4-4.34.0/src/Lean/Parser/`
- `study/lean4-4.34.0/src/Lean/Elab/`
- `study/lean4-4.34.0/src/Lean/Meta/`
- `study/lean4-4.34.0/src/Lean/Compiler/`

Lean is the reference for semantics and for evidence about what facilities are
useful when implementing a serious dependently typed compiler. It is **not** a
requirement to accept or reproduce all Lean implementation conveniences.

The study inventory shows recurrent use of:

- functions, lambdas, higher-order functions and parametric polymorphism;
- structures, inductives, pattern matching and dependent function types;
- direct, mutual and partial recursion;
- `List`, `Array`, `Option`, maps/sets and persistent collections;
- `String`, `Char` and source positions;
- `StateT`, `ReaderT`, `ExceptT`, `OptionT`, `EStateM` and `do`;
- explicit environments, name tables and metavariable state;
- IO/host capabilities at the outer boundary;
- Lean-specific macros, quotations, attributes, environment extensions,
  `unsafe`, `implemented_by`, and other facilities that are not automatically
  required by ProofScript.

### Lean implementation-language coverage policy

The self-hosting foundation is no longer defined as the absolute smallest
feature set discovered one blocker at a time. Before SH7 freezes the bootstrap
subset, ProofScript must perform a systematic feature census of the Lean 4.34
implementation sources used as references, including at least:

- `study/lean4-4.34.0/src/Init/`;
- `study/lean4-4.34.0/src/Lean/Parser/`;
- `study/lean4-4.34.0/src/Lean/Meta/`;
- `study/lean4-4.34.0/src/Lean/Elab/`;
- `study/lean4-4.34.0/src/Lean/Compiler/`.

The census must cover both source-language constructs and recurring library /
effect abstractions. At minimum it must record use of declarations, recursion,
pattern forms, `do`, mutable-looking Lean syntax, loops, binders, universes,
classes/instances, collections, names, source positions, monad transformers,
comparison/hash abstractions, parser control and Meta-state operations.

Each discovered facility is classified into one of four buckets:

1. **REQUIRED** — needed by the ProofScript compiler or an unavoidable
   prerequisite abstraction. Implement before SH7 freezes.
2. **USEFUL/CHEAP** — broadly used by Lean to implement compiler code and
   feasible without a disproportionately large subsystem. Implement before SH7
   when doing so materially improves compiler authoring and reduces rewrite
   risk.
3. **DEFERRED/EXPENSIVE** — legitimate Lean functionality whose implementation
   would pull in a large metaprogramming/extensibility subsystem that the
   ProofScript compiler does not need. Record it and keep it fail-closed.
4. **HOST-BOUNDARY** — behavior that is genuinely supplied by Node/npm/the
   filesystem/TypeScript API rather than ProofScript semantics. Keep it behind
   typed adapters.

The default rule is therefore:

> Implement the practical Lean implementation-language subset: all broadly
> useful Lean constructs exercised by Lean's own implementation that are
> feasible at reasonable cost, plus every feature required by the ProofScript
> compiler. Do not require a concrete blocker for every USEFUL/CHEAP feature.

This broadening applies to ordinary implementation-language facilities, not to
the whole Lean metaprogramming platform. In particular, arbitrary user syntax,
macros/quotations, custom parser categories, custom elaborators, environment
extensions, broad attribute registration, compile-time interpreter machinery,
`implemented_by`, and unrestricted unsafe escape hatches remain deferred
unless a later compiler module demonstrates a hard requirement.

The preferred implementation strategy remains: desugar convenient source
constructs into the small Lean-compatible checked core rather than enlarging
pskernel. `for`, `while`, mutable-looking locals and similar features must
not introduce JavaScript-specific semantic authority.

## Foundation completion rule

A runtime language feature is complete only when it executes through:

```text
.ps or supported .lean
-> canonical source AST
-> Lean-compatible Meta/Elab
-> pskernel admission
-> CheckedCoreModule
-> erasure
-> verified compiler IR
-> TypeScript
-> tsc
-> JavaScript
```

A parser-only or backend-only implementation does not close a foundation gate.

## SH0 — remove the legacy semantic lane — COMPLETED 2026-09-24

This gate is promoted ahead of all new foundation work.

Completed:

- `psc check/build/run` use the checked-core path unconditionally;
- the legacy `@proofscript/language` software checker was deleted;
- legacy software-HIR lowering was deleted from compiler IR;
- legacy software TypeScript emitters were deleted;
- unverified CLI result/report paths were removed;
- source parsing/printing remains in the shared source frontends;
- the architecture gate rejects the retired package/files if they reappear.

Exit condition is met:

> There is exactly one ProofScript semantic compiler path on `main`.

## SH1 — executable text foundation — IN PROGRESS

Finish Lean-compatible executable support for:

- `Char`;
- `String` traversal and character access;
- length/position operations;
- slicing/substrings;
- comparison;
- concatenation and an efficient builder strategy;
- character classification needed by a lexer;
- source-position/span data.

Completed 2026-09-24:

- `Char` is a first-class verified runtime primitive through checked core,
  erasure, verified IR, TypeScript emission, CLI ABI, and explicit FFI;
- the real Lean 4.34 `Char.ofNat` constant lowers to a verified intrinsic;
- emitted JavaScript preserves Lean's Unicode-scalar rule, including NUL for
  surrogate/out-of-range inputs;
- executable regressions cover ASCII, non-BMP Unicode, and invalid scalar
  behavior;
- a dedicated Lean 4.34 text-foundation export recipe now roots only the
  compiler-required Char/String/String.Pos.Raw operations instead of adopting
  a broad Std environment.

Current gate:

- generate
  `oracle/fixtures/lean434-proofscript-text-foundation.ndjson` with exact
  Lean 4.34.0 using `scripts/generate-text-foundation-fixture.sh`;
- replay it with `npm run oracle:text-foundation`;
- only then add erasure/backend intrinsics for `Char.toNat`, character
  classification, `String.length`, `String.append`, traversal, and raw
  string positions.

The raw text-foundation dependency closure is an **assurance input**, not the
normal compiler hot-path environment. Replaying the 17+ MiB closure in every
`psc` process exceeded the ordinary Node heap during CLI tests, so the normal
provider continues to use the pinned `Init.Prelude` base unless an explicit
`PROOFSCRIPT_LEAN_FOUNDATION` path is supplied.

After exact replay is green, derive a compact, versioned pskernel-certified
foundation interface/base for the selected roots and fingerprint it to the
exact Lean 4.34 assurance closure. The compact artifact must preserve the
kernel-facing types/metadata needed by elaboration and the SH6b bridge without
making the raw dependency closure a startup dependency. No synthetic
standard-library axioms are permitted to bypass the exact-replay gate.

Exit test: a nontrivial lexer utility can be authored in supported `.lean`
and `.ps` and run through verified JavaScript emission.

## SH2 — compiler collections

Provide verified, generic:

- `Array α`;
- `Map K V`;
- `Set α`;
- `Prod α β` / tuple support and the ordinary `fst` / `snd` operations;
- `Sum α β` when the compiler data model benefits from it;
- the already-landed Option/Result/List APIs needed by compiler code.

The first Array profile needs at least empty, size, get/get?, push, set, map,
fold, monadic map/fold variants used by compiler code, any/all and find?.

The bootstrap Map/Set semantics must not silently inherit JavaScript identity
semantics. Prefer a persistent ordered implementation requiring an explicit
Lean-compatible ordering abstraction. Provide the bootstrap comparison
foundation needed for compiler keys, including `BEq`/equality and `Ord`
coverage for at least the primitive/name forms actually used by the compiler.
`Hashable`/hash maps may remain deferred until profiling or a concrete module
requires them.

Map/Set may initially use a persistent tree implementation in ProofScript; a
faster runtime representation may be added later without changing their
semantic API.

Exit test: AST/name-table transformations use no TypeScript collection
semantics, tuple-returning compiler utilities are ordinary ProofScript values,
and map/set key behavior is deterministic and specified.

## SH3 — controlled effects, transactional state and bootstrap Meta support

Implement the compiler-oriented effect foundation:

- `Except` / error propagation;
- `State` / `StateT`;
- `Reader` / `ReaderT`;
- usable Lean-compatible `do` notation;
- bind/pure sequencing;
- Lean-compatible `return` inside `do`;
- `throw` / `tryCatch` and bounded `failure` / `orElse` behavior;
- cheap control-flow combinators such as `when` / `unless`;
- `OptionT` or additional transformers when the census or a compiler module
  requires them.

The first bootstrap profile should also provide the monad-lifting operations
actually needed by the selected Reader/State/Except stack. Do not reproduce
Lean's full transformer/typeclass hierarchy unless the compiler workload
requires it.

Add the small proof-aware control-flow forms that compiler code uses to carry
branch facts without invoking a tactic engine:

- dependent/proof-binding conditionals such as `if h : P then ... else ...`
  and the anonymous-proof form `if _ : P then ... else ...`;
- ordinary proof-valued local bindings such as `have h : P := proof`;
- `show T from e` or an equivalent cheap expected-type annotation form when
  it materially simplifies compiler/proof code.

These are term-elaboration features, not tactic automation. Branch hypotheses
and `have` values must elaborate to ordinary proof terms that pskernel checks.

Also provide transactional state operations required by parsers and
elaboration:

- checkpoint/save;
- rollback/restore;
- commit;
- isolated trial/alternative execution;
- deterministic error recovery.

A failed parser, coercion, unification or instance-search alternative must not
leak assignments/state into the next candidate.

Before SH7, move the bootstrap-critical subset of Meta/Elab support into this
foundation instead of leaving all of it as post-foundation language work. This
includes, to the extent exercised by the compiler source:

- implicit argument insertion and expected-type propagation;
- universe metavariables/constraints required by bootstrap declarations;
- postponed constraints;
- bounded higher-order pattern unification;
- transparency-sensitive reduction where needed by elaboration;
- Lean-compatible coercion insertion for the supported subset;
- instance synthesis with priorities and recursion control;
- imported instance indexes;
- `outParam` / `semiOutParam` only if the bootstrap libraries actually
  require them.

Do not add arbitrary JavaScript statement semantics merely to mimic TypeScript
mutation. These facilities remain ordinary ProofScript/Lean-compatible effect
and Meta abstractions outside the kernel TCB.

Exit test: parser state, a small name-resolution pass, and a candidate-based
Meta/unification probe can all be authored in supported `.lean` and `.ps`,
including rollback after a deliberately failing candidate, with no host-language
mutation semantics or leaked metavariable assignments.

## SH4 — recursion, iteration and executable control closure

Finish the executable recursion forms needed by compiler algorithms:

- mutual recursive definitions;
- mutual inductive declarations where compiler data requires them;
- recursive local `where` / `let rec` groups;
- multiple structural recursive parameters where Lean semantics justify them;
- bounded well-founded recursion when structural recursion is insufficient and
  the Lean semantics are owned;
- Lean-faithful executable `partial def` for algorithms whose termination is
  intentionally outside proof computation.

Implement the practical Lean iteration conveniences identified by the census
when they can be desugared without enlarging the trusted core:

- `let mut`;
- reassignment of such locals inside the bounded control-flow model;
- `for`;
- `while`;
- `break` / `continue` where needed by the supported loop model.

Back `for` with a deliberately small Lean-compatible iteration abstraction
instead of hard-coding Array-only loop semantics. The bootstrap profile should
cover the concrete containers used by compiler code, expected to include at
least List, Array, ordered Map/Set entries and simple Nat ranges. A bounded
`ForIn`-style library interface is preferred; the full Lean iterator
hierarchy is not required.

These are Lean-style source conveniences, not JavaScript mutation semantics.

Also provide an explicit runtime-only failure/assertion vocabulary for compiler
invariants, expected to cover the useful roles of Lean's `guard`, `assert!`,
`panic!`, and `unreachable!` without necessarily copying their exact APIs.
These operations may abort/fail executable code, but they must never manufacture
proof terms, discharge propositions, or add trusted definitional authority.
Prefer typed `Except`/failure where recovery is expected and reserve
panic/unreachable forms for internal impossible-state assertions.

Structural recursion remains preferred. The exact `partial` trust boundary
must be executable and mechanically enforced: partial code may execute, but it
must not gain trusted definitional/proof authority that Lean 4.34 would deny.
Dependencies from trusted proof/type computation into partial implementation
behavior must remain fail-closed according to the pinned Lean model.

Because the TypeScript/JavaScript backend is the bootstrap execution target,
compiler-critical tail recursion/iteration must also have a stack-safety
strategy. Prefer tail-recursion-to-loop lowering and verified/library iterators;
use trampolining only when a concrete algorithm requires it.

Exit test: mutually recursive expression/type parsing, a fixed-point-style
compiler utility, and a large compiler-style traversal run through the verified
backend without host mutation shortcuts or JavaScript stack overflow in the
covered profile.

## SH4.5 — pattern-language closure

The current flat single-scrutinee constructor-pattern subset is not sufficient
for natural compiler implementation. Before SH7 freezes, add the bounded
Lean-compatible pattern forms actually needed by parser/Meta/compiler code:

- nested constructor patterns;
- tuple / `Prod` patterns;
- multi-scrutinee `match`;
- wildcard and literal patterns at nested positions;
- `if let`;
- ordinary `let` pattern destructuring;
- pattern binds in `do` where required by the selected effect subset;
- deterministic failure/exhaustiveness behavior for the supported forms.

Prefer desugaring richer source patterns into ordinary checked eliminators and
lets. Do not implement Lean's complete dependent pattern compiler merely for
surface parity. Indexed/dependent pattern features remain workload-driven and
must fail closed until their elaboration semantics are owned.

Exit test: a parser/AST transformation module can destructure nested compiler
data, use multi-scrutinee matches and `if let`/let-patterns, and execute through
the checked-core JavaScript path with no TypeScript-side pattern semantics.

## SH5 — names, modules, environments and bootstrap data model

Provide stable ProofScript-authored models for:

- qualified names;
- module/import identities and deterministic module ordering;
- namespaces and qualified lookup;
- the minimal public/private visibility model needed by the compiler;
- source positions/spans;
- tokens;
- syntax/AST nodes used by the bounded compiler;
- diagnostics and fresh identifiers;
- explicit environments and compiler state.

Also finish the cheap implementation-language ergonomics that Lean compiler
source relies on heavily and that materially reduce bootstrap rewrite risk:

- field/projection notation;
- bounded method-style notation when it deterministically resolves to an
  ordinary declaration application;
- structure update syntax such as `{ s with field := value }`;
- named arguments;
- default arguments where the census shows repeated compiler use;
- `abbrev` when it can be supported without introducing a second semantic
  mechanism.

These conveniences must elaborate/desugar into the same ordinary core terms;
they do not receive independent runtime semantics.

The name-resolution gate must specify and test at least local shadowing,
namespace lookup, fully-qualified lookup, imported declarations, private-name
handling, constructor resolution, projection/method resolution, instance-index
lookup, and deterministic ambiguity rejection.

Freeze the canonical source-position representation before parser/LSP work
spreads. Prefer UTF-8 byte offsets for compiler/source-map identity, with
explicit conversion at JavaScript UTF-16 and LSP line/column boundaries.

Avoid Lean implementation-only mechanisms such as environment extensions when
ordinary explicit data structures are sufficient. Do not pull in sections,
open-scoped machinery or generalized environment extensions unless the feature
census shows that the ProofScript compiler itself needs them.

## SH6 — host capability and independent-kernel boundary

Keep host-specific effects thin and explicit.

### SH6a — ordinary host capabilities

The bootstrap compiler may call typed host capabilities for:

- file reads/writes;
- path operations;
- process arguments;
- npm/Node resolution where required;
- TypeScript Compiler API invocation.

These adapters may remain TypeScript. They are runtime assumptions, never
proof evidence, and must not own language semantics.

### SH6b — versioned pskernel bridge

Before SH7 freezes, define and executable-gate the interface between the
self-hosted compiler and the independent TypeScript pskernel.

The self-hosted Meta/Elab layer must not depend directly on arbitrary mutable
TypeScript class internals. Prefer versioned, ProofScript-owned canonical data /
codec representations for the kernel-facing subset, including at least:

- `Name`;
- universe `Level`;
- kernel `Expr`;
- declaration and inductive-declaration payloads;
- environment/constant metadata required by elaboration;
- checked-module/admission identities.

Provide the smallest explicit bridge operations needed by the self-hosted
compiler, expected to include:

- load/open the pinned base environment;
- deterministic constant lookup;
- ground expression type checking/inference where the compiler deliberately
  delegates to the independent checker;
- ground definitional-equality queries where needed;
- definition/theorem admission;
- inductive admission and retrieval of generated constructor/recursor metadata;
- replay/validation of checked-core module admissions.

Meta unification, candidate search, coercion policy, instance synthesis and
source elaboration remain self-hosted compiler semantics. The bridge must not
silently turn pskernel into a hidden second elaborator.

The bridge protocol/version must be fingerprinted or otherwise compatibility
checked so PSC1 cannot accidentally run against an incompatible kernel API.

#### Initial SH6b transport

Do not block SH6b on a generalized structured FFI. The current checked-core FFI
is intentionally first-order and primitive-valued, so the first bridge should
use a versioned canonical text transport that fits that boundary.

Preferred initial shape:

```text
ProofScript compiler
    |
    | canonical request JSON : String
    v
single narrow pskernel bridge extern
    |
    | canonical response JSON : String
    v
ProofScript compiler
```

A minimal API may therefore begin as an operation equivalent to
`kernelRequest : String -> String`, with a schema-discriminated request/response
protocol. The schema must:

- carry an explicit protocol version and pskernel/foundation fingerprint;
- define canonical encodings for Name, Level, Expr, declarations, inductives,
  errors and checked metadata;
- reject unknown versions, unknown variants, malformed payloads and incomplete
  metadata deterministically;
- preserve integer/string/universe/name information exactly rather than relying
  on JavaScript object identity;
- keep each semantic operation explicit in the request tag (lookup, infer/check,
  defeq, definition/theorem admission, inductive admission, checked replay);
- return structured diagnostics rather than depending on thrown host exceptions
  for ordinary kernel rejection.

Once self-hosting is stable, a typed/binary/structured ABI may replace this
transport for performance, but it must preserve the same versioned semantic
contract. The JSON/String bridge is a bootstrap transport, not a new semantic
authority.

Exit test: a compiler module authored in supported `.lean` and `.ps` can
encode a canonical request, cross the primitive String bridge, decode the
versioned response, perform lookup/check/admission, obtain the resulting checked
metadata, and continue verified compilation without importing pskernel's
TypeScript implementation classes directly.

## SH7 — census, prove compiler readiness, then freeze the Lean bootstrap subset

Before writing the real compiler, complete the Lean implementation-language
feature census and freeze the exact `.lean` subset accepted for bootstrap
source.

The census artifact must record, for every relevant Lean construct or recurring
abstraction:

- representative source locations in the pinned Lean 4.34 tree;
- whether the ProofScript compiler is expected to use it;
- current ProofScript implementation status;
- REQUIRED / USEFUL-CHEAP / DEFERRED-EXPENSIVE / HOST-BOUNDARY classification;
- the owning SH milestone and executable acceptance gate.

The frozen subset should include the practical implementation-language
facilities selected by the census, including all compiler-required constructs
and broadly useful low/medium-cost Lean conveniences that materially reduce
self-host rewrite risk. It must intentionally omit expensive, unnecessary Lean
implementation machinery such as arbitrary user syntax, macro/quotation
systems, custom elaborators, generalized environment extensions, broad
attribute registration and unsafe casts.

Gate every supported bootstrap construct through the same `.lean` and `.ps`
frontends and checked-core path.

Before freezing, add one multi-module **SELFHOST-FEATURE** fixture/skeleton that
uses the foundation together rather than as isolated unit features. It must
exercise at least:

- nontrivial `String`/`Char` lexer-style traversal and source positions;
- Array plus ordered Map/Set and compiler-oriented traversal combinators such as
  `mapM` / indexed monadic traversal / folds;
- qualified `Name`, namespaces/imports and explicit environment updates;
- structures, structure updates, field/method notation and named arguments;
- dependent/proof-binding `if h : P`, proof-valued `have`, and the selected
  expected-type/show form;
- generic/dependent ADTs and the SH4.5 pattern subset, including nested and
  multi-scrutinee patterns plus `if let`/let-patterns;
- `Prod`/tuple-returning and tuple-destructuring utilities;
- structural, mutual and local recursion plus a controlled `partial` case;
- `do`, Reader/State/Except, `return`, failure/alternative handling and
  transactional rollback;
- practical iteration syntax and the bounded iteration abstraction selected by
  the census;
- runtime-only guard/assert/panic/unreachable behavior with a regression proving
  it cannot be used as proof evidence;
- higher-order/generic traversals;
- implicit arguments, instance synthesis and postponed Meta constraints used by
  the bootstrap subset;
- diagnostics/fresh IDs;
- multi-module compilation;
- the versioned SH6b pskernel bridge, using the canonical String/JSON bootstrap
  transport, for lookup, a ground kernel query and declaration/inductive
  admission.

The fixture must execute end-to-end:

```text
supported .lean and .ps
-> canonical source AST
-> Lean-compatible Meta/Elab
-> pskernel admission
-> checked core
-> erasure
-> verified compiler IR
-> TypeScript
-> tsc
-> JavaScript
```

Freeze only after this gate passes. Do not start SH8 merely because every
feature has an isolated parser or elaborator test.

Exit conditions:

> A complete ProofScript compiler implementation can be expressed naturally in
> the frozen supported Lean subset without adding another semantic pipeline.

> The SELFHOST-FEATURE fixture demonstrates that the selected features compose
> across multiple modules through the real verified JavaScript path.

## SH8a — implement the core compiler in .lean

Implement compiler-owned semantics in bounded Lean source, in approximately
this dependency order:

1. Name / SourcePos / Span / diagnostics;
2. canonical AST/data model;
3. pskernel bridge data/codec client;
4. verified compiler IR model;
5. pretty printer and TypeScript source builder;
6. erasure/lowering;
7. TypeScript emitter;
8. lexer;
9. parser;
10. environment/name resolution;
11. Meta;
12. term/declaration elaboration;
13. compiler orchestration.

SH8a is the first self-hosting target. It does **not** require moving every
existing theorem tactic into the self-hosted compiler before PSC1 can exist.
The bootstrap compiler source itself should avoid depending on tactic features
that have not yet moved.

Do not add broad proof automation merely to make the bootstrap compiler pleasant
to write. Prefer ordinary terms, `have`, proof-binding conditionals, safe APIs
such as optional/bounds-checked collection access, structural recursion, and the
controlled `partial` boundary. In particular, tactics comparable to `omega`,
`aesop`, `grind`, `linarith`, `ring`, broad `solve_by_elim`, or a full
simp engine are not SH8a prerequisites.

The TypeScript pskernel remains the independent admission authority. Node,
filesystem, TypeScript-API and similar host adapters remain outside the
self-hosted semantic compiler.

## SH8b — self-host the supported theorem/tactic frontend

After the SH8a compiler can bootstrap, move the currently supported
ProofScript theorem/tactic elaboration onto the self-hosted Meta/Elab
infrastructure, preserving the existing rule that tactics construct ordinary
kernel proof terms and pskernel remains final authority.

SH8b should cover the tactic subset that ProofScript claims at that point; it
does not require full Lean tactic parity. Tactic self-hosting must not block the
first PSC0 -> PSC1 -> PSC2 core-compiler bootstrap.

After PSC2 core stability, prioritize **Meta capability before tactic-name
breadth**. The preferred order is:

1. general term holes and stronger implicit/instance handling in
   `apply`/`refine`;
2. dependent/indexed-context support for `cases` and `induction`;
3. small proof-structuring operations such as `change`, `subst`,
   `generalize`, `by_cases`, `by_contra`/ex-falso and
   `unfold`/`dsimp`;
4. `simpa` and a larger deterministic simplifier once the supporting
   Meta/indexing semantics are owned;
5. large automation only when it serves a concrete ProofScript verification
   workload.

Do not implement `omega`, `aesop`, `grind`, `linarith`, `ring`,
`native_decide`, or full Lean `simp` solely for self-hosting. They remain
post-bootstrap features unless an independently justified language goal
requires them.

## SH9 — bootstrap in JavaScript

Let PSC0 denote the current TypeScript implementation.

Required bootstrap:

```text
compiler.lean --PSC0--> compiler.ts --tsc--> PSC1.js
compiler.lean --PSC1--> compiler.ts --tsc--> PSC2.js
```

Require equality of checked-core/IR fingerprints and normalized generated
TypeScript. With a pinned toolchain, byte-stable JavaScript is preferred when
practical.

Do not claim self-hosting merely because PSC1 executes. The first core
self-hosting claim requires PSC2 stability for SH8a; full current-language
self-hosting additionally requires the applicable SH8b tactic/frontend gate.

## SH10 — move the compiler to .ps

Use the dual-source frontend/translation machinery to convert the frozen
bootstrap implementation to canonical ProofScript, then maintain/refactor the
compiler primarily in `.ps`.

The target condition is:

```text
compiler.ps --PSC1--> PSC2
compiler.ps --PSC2--> PSC3
```

with the same semantic/bootstrap equivalence gates.

## SH11 — verified self-hosting

After ordinary self-hosting is stable, add proofs/specifications for
semantics-preserving compiler transformations where they provide real
assurance.

This milestone must not block SH1-SH10.

## Deferred until the foundation closes

Unless demanded by an SH gate, defer:

- new backends beyond the current TypeScript/JavaScript path;
- broad React/Next.js integration;
- new browser/LSP/editor features;
- extra package-manager features;
- full Lean syntax/macros/metaprogramming;
- large proof automation such as `omega`, `aesop`, `grind`, `linarith`,
  `ring`, `native_decide`, or full Lean `simp` before SH8a/PSC2 stability;
- generalized dependent-pattern compilation beyond the bootstrap need;
- full Lean iterator hierarchy;
- broad HashMap/Hashable adoption before correctness-oriented ordered
  collections prove insufficient;
- full well-founded termination elaboration unless a compiler module requires
  it;
- tactic breadth unrelated to the currently supported ProofScript theorem
  frontend;
- broad npm binding generation;
- kernel rewrite in ProofScript.

## Branch policy

- `main`: ProofScript self-hosting foundation and non-kernel changes needed
  for SH0-SH11.
- `kernel/lean434-study-hardening`: independent TypeScript kernel assurance
  and Lean 4.34 conformance work.
- Kernel changes merge to `main` only when they are independently justified by
  kernel compatibility, never solely to make a ProofScript compiler test pass.

## Anti-drift decision test

Before accepting any ProofScript infrastructure task, ask:

1. Which SH milestone or Lean feature-census bucket justifies it?
2. Is it REQUIRED by a compiler module, or is it a broadly useful
   USEFUL/CHEAP Lean implementation-language feature that reduces self-host
   rewrite risk?
3. Can the need be satisfied as a ProofScript library instead of a language
   primitive?
4. Can host-specific behavior remain a thin TypeScript adapter?
5. Does the change preserve the single checked-core semantic path?
6. Would implementing it require importing a disproportionately large Lean
   metaprogramming subsystem that the compiler does not actually need?

If the feature is neither REQUIRED nor justified as USEFUL/CHEAP by the census,
defer it. Expensive extensibility machinery remains deferred until a concrete
compiler requirement changes its classification.
