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
2. **USEFUL/CHEAP / OPTIONAL-PSC1** — broadly useful or convenient Lean
   implementation facilities that are feasible at reasonable cost. Keep them
   in the plan and implement them opportunistically, but they do **not** block
   SH7, PSC1, or the first self-hosting claim unless an actual compiler module
   or frozen acceptance fixture is changed to depend on them.
3. **DEFERRED/EXPENSIVE** — legitimate Lean functionality whose implementation
   would pull in a large metaprogramming/extensibility subsystem that the
   ProofScript compiler does not need. Record it and keep it fail-closed.
4. **HOST-BOUNDARY** — behavior that is genuinely supplied by Node/npm/the
   filesystem/TypeScript API rather than ProofScript semantics. Keep it behind
   typed adapters.

The default rule is therefore:

> Implement the smallest practical language that can express the ProofScript
> compiler and preserve the required ProofScript semantics. REQUIRED features
> close PSC1; USEFUL/CHEAP features remain available plan items but are
> optional/non-blocking until real compiler code demonstrates a requirement.

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

### PSC1 minimality / Go-like freeze policy

PSC1 follows a deliberately small-language policy: prefer one canonical
mechanism for each problem, and move reusable abstractions into ordinary
libraries instead of making them independent language requirements.

**PSC1 completion is defined only by the REQUIRED bootstrap capability set.**
An optional feature may be unfinished without preventing SH7 freeze, PSC1,
PSC2, or promotion of `.ps` as the compiler source of truth.

Already implemented features are **not removed** by this policy. Optionality
changes only milestone/blocking status. An already-supported feature remains
supported and must not be silently weakened.

The preferred canonical choices for the first bootstrap are:

- ordinary functions/lambdas for computation and higher-order behavior;
- structures and inductives for data;
- one ordinary `match` mechanism for elimination;
- structural recursion plus a controlled executable `partial def` boundary;
- `Option` for absence and `Result`/`Except`-style values for recoverable
  errors;
- one concrete `CompilerM`-style context/state/error abstraction for compiler
  effects;
- `List`, `Array`, ordered `Map` and ordered `Set` as the standard
  bootstrap collection families;
- libraries for traversal/combinators instead of adding parallel language
  mechanisms;
- thin host capabilities only at explicit boundaries.

The **minimal REQUIRED PSC1 language/capability set** is:

- definitions, functions, lambdas, application and `let`;
- ordinary `if` and basic single-scrutinee `match`;
- structures, inductives, constructors and projections;
- the primitive/runtime foundation actually needed by the compiler:
  `Nat`, `Int`, `Bool`, `Char`, `String`, `Unit`;
- `List`, `Option`, `Result`/`Except`, `Prod`, `Array`, ordered
  `Map`/`Set`, plus the bounded operations exercised by compiler code;
- dependent function types / `Prop` / kernel proof terms and the universe,
  implicit-argument, metavariable and definitional-equality machinery required
  to preserve ProofScript's dependent semantics;
- the bounded class/instance and `Decidable` machinery actually exercised by
  the frozen compiler/language subset;
- structural recursion and controlled executable `partial def`;
- a concrete reader/state/error compiler effect with `do`, `pure`, `bind`,
  error recovery and transactional rollback;
- imports/modules, qualified names, deterministic name resolution, compiler
  environments, AST/tokens/spans/diagnostics;
- the canonical JSON codec and versioned pskernel bridge;
- canonical `.lean <-> .ps` translation and equal checked-core/IR behavior;
- verified lowering through TypeScript to JavaScript.

The following remain in the plan but are **OPTIONAL/NON-BLOCKING for PSC1**
unless real compiler code proves otherwise:

- generic `ReaderT`, `StateT`, `ExceptT`, `OptionT`, generic `Monad`
  transformer stacks and automatic `MonadLift`;
- precise TypeScript HKT encodings;
- `Sum` when the compiler data model does not need it;
- list/array literal syntax, tuple destructuring sugar and generic `GetElem`;
- mutual inductive declarations;
- mutual/local recursion syntax when the same algorithm can use top-level
  helpers or one structural dispatcher;
- multiple structural-recursion convenience and general well-founded
  termination elaboration;
- `let mut`, reassignment, `for`, `while`, `break` and `continue`
  when library folds/recursion are sufficient;
- rich/nested/multi-scrutinee pattern syntax, `if let`, let-patterns and
  do-patterns when explicit nested `match` is sufficient;
- method-style notation, structure-update sugar, named/default arguments,
  grouped binders, unnamed instance binders and structure field defaults;
- `abbrev`, source-level `opaque`, interpolation, `Inhabited`/`default`
  conveniences and `Id.run`;
- explicit user-written universe commands/syntax when inferred/bounded
  universes suffice;
- broad visibility/section/open-scoped conveniences beyond the module/name
  behavior actually required by the compiler.

A convenience may still land before PSC1 when it is local, obviously
desugaring-only, and reduces repeated compiler boilerplate. It simply does not
become a finish criterion.

When there are two plausible ways to solve the same bootstrap problem, prefer
the one that reuses an existing semantic mechanism. Add a new REQUIRED language
feature only after demonstrating that the compiler cannot be written
reasonably using the frozen core/library vocabulary.

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

### Staged source portability invariant

During the Lean bootstrap and SH8a compiler implementation, **`.lean` is the
only handwritten compiler source**. Do not create, update, or review paired
`.ps` implementation files by hand. The bootstrap source must still stay
inside the frozen PSC1-compatible Lean subset and must use the same canonical
AST, elaboration, checked-core, and compiler-IR semantics that the eventual
ProofScript source will use.

Dual-surface behavior may still be tested with in-memory/source fixtures where
the ProofScript frontend already exists. That tests the language design without
creating a second maintained compiler tree.

Canonical source translation becomes a required compiler capability **after the
Lean-authored compiler is complete enough to perform that translation itself**.
At that point generate the ProofScript tree from the authoritative Lean tree:

```text
compiler.lean
  -> completed compiler
  -> generated canonical compiler.ps
  -> parse / elaborate / check
  -> equal checked-core and compiler-IR fingerprints
  -> equivalent TypeScript / JavaScript
```

Only compiler-generated `.ps` is used for the initial parity campaign. Once
that generated tree is stable, the reverse `.ps -> .lean` direction and
canonical-idempotence gates are enabled. Unsupported constructs must continue
to fail closed rather than being silently erased or approximated.

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

## SH1 — executable text foundation — COMPLETED 2026-09-24

Lean-compatible executable text support is now sufficient for bootstrap compiler
work and remains on the single verified semantic lane.

Closed evidence:

- `Char` is a first-class verified runtime primitive through checked core,
  erasure, verified IR, TypeScript emission, CLI ABI, and explicit FFI;
- `Char.ofNat` and `Char.toNat` lower through checked Lean constants, with
  Unicode-scalar behavior covered by executable regressions;
- the exact Lean 4.34 text-foundation delta is pinned and reproducibly replayed
  over `Init.Prelude`, while remaining small enough for the normal compiler
  environment;
- `String.push`, `String.singleton`, `String.Internal.length`,
  `String.Internal.append`, `String.utf8ByteSize`,
  `String.Internal.next`, `String.Internal.get`,
  `String.Internal.atEnd`, and `String.Internal.extract` execute through
  checked core -> erasure -> verified IR -> TypeScript -> JavaScript;
- `String.Pos.Raw` retains its real Lean checked-core structure and erases to
  its exact runtime payload, the UTF-8 byte-offset `Nat`; constructor and
  `byteIdx` projection round-trip through the verified compiler;
- primitive `Char` and `String` Boolean equality are checked in Lean terms
  and normalized after checking to verified equality intrinsics;
- executable dual-source regressions cover code-point length and UTF-8
  next/get/extract/atEnd behavior on multi-byte Unicode;
- `stdlib/src/ProofScript/Text/Lexer.ps` now provides portable
  `SourceSpan`, ASCII digit/identifier/whitespace classification, raw-position
  helpers, slicing, and a nontrivial identifier scanner;
- that lexer module is continuously gated through canonical
  `.ps -> .lean -> .ps` translation with equal checked-core and compiler-IR
  fingerprints and equal TypeScript/JavaScript/declaration output;
- full `npm test` and `anti-drift` are green at the SH1 closeout head.

The compact pinned Lean delta remains part of SH1 assurance and must continue
to regenerate from exact Lean 4.34. No synthetic standard-library axioms may
replace that evidence.

Exit condition is met:

> A nontrivial lexer utility is authored in ProofScript, translated to the
> supported Lean subset, admitted by pskernel, and emitted through verified
> JavaScript with dual-source semantic parity.

## SH2 — compiler collections — IN PROGRESS

Required PSC1 collection/data foundation:

- `Array α`;
- ordered `Map K V`;
- ordered `Set α`;
- `Prod α β` and the ordinary `fst` / `snd` operations;
- a self-hostable canonical JSON value/codec library used by SH6b;
- the already-landed Option/Result/List APIs needed by compiler code.

`Sum α β` remains planned but is OPTIONAL/NON-BLOCKING when the compiler data
model can use an ordinary purpose-specific inductive instead.

The JSON foundation must provide the bounded functionality needed by the
pskernel protocol without depending on host-side object semantics:

- JSON value representation;
- deterministic parser with structured errors;
- canonical encoder;
- object lookup/building using the owned Map/association semantics;
- exact string escaping/unescaping and integer handling required by the bridge;
- schema-level codecs for versioned compiler/kernel payloads.

JSON is a library/data-format requirement, not a new trusted language primitive.

The first Array profile needs at least empty, size, get/get?, push, set, map,
fold, monadic map/fold variants used by compiler code, any/all and find?.

Optional cheap literal/constructor conveniences may be added when they
materially reduce noise in compiler data code and desugar directly to the same
library constructors in both source frontends:

- list literals such as `[]` and `[a, b, c]`;
- array literals such as `#[]` and `#[a, b, c]`;
- tuple/Prod literal and destructuring syntax when not already covered by SH4.5.

These are USEFUL/CHEAP source forms, not new runtime primitives and not PSC1
finish criteria. If implemented, they must round-trip `.lean <-> .ps` and
lower to ordinary checked constructors.

Prefer safe collection APIs such as `get?` in bootstrap code. A generalized
Lean `GetElem`/proof-producing indexing framework is not an SH7 prerequisite;
add only a bounded indexing notation if it can be implemented as cheap sugar
over already-owned safe APIs without importing tactic-based bounds solving.

The bootstrap Map/Set semantics must not silently inherit JavaScript identity
semantics. Prefer a persistent ordered implementation requiring an explicit
Lean-compatible ordering abstraction. Provide the bootstrap comparison
foundation needed for compiler keys, including `BEq`/equality and `Ord`
coverage for at least the primitive/name forms actually used by the compiler.
Make the corresponding `Ordering` data/API explicit in the bootstrap library
so map/set comparison is ordinary portable ProofScript/Lean code rather than a
host-language callback convention.
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

- `Except`-style error propagation;
- state semantics equivalent to the subset needed from `State` / `StateT`;
- read-only context semantics equivalent to the subset needed from `Reader` /
  `ReaderT`;
- usable Lean-compatible `do` notation;
- bind/pure sequencing;
- Lean-compatible `return` inside `do`;
- `throw` / `tryCatch` and bounded `failure` / `orElse` behavior;
- cheap control-flow combinators such as `when` / `unless`;
- additional transformer-style behavior only when the census or a compiler
  module demonstrates that the concrete bootstrap effect API is insufficient.

For PSC1, **the semantics are required; a generic higher-kinded transformer
hierarchy is not**. A concrete compiler effect can be used as the bootstrap
representation, conceptually:

```text
CompilerM α :=
  CompilerContext ->
  CompilerState ->
  Result CompilerError (α × CompilerState)
```

or an equivalent checked representation with the same reader/state/error
behavior. The source API should still expose the familiar operations needed by
compiler code (`read`, `withReader`, `get`, `set`, `modify`, `throw`,
`tryCatch`, `failure`, `orElse`, checkpoint/restore, `pure`, `bind`) so
switching to generic transformers later does not require rewriting compiler
algorithms.

Keep Lean's generic `ReaderT`, `StateT`, `ExceptT`, `OptionT`,
`MonadLift` and ordinary `Monad` concepts in the language model; do not
delete or redefine them merely because TypeScript lacks native higher-kinded
types. Their **generic executable backend support is non-blocking for PSC1**.
`OptionT` and automatic `MonadLift` remain optional conveniences unless
real compiler code needs them.

Do not reproduce Lean's full transformer/typeclass/law hierarchy merely for
bootstrap ergonomics.

Keep the following proof-aware control-flow forms in the plan as
OPTIONAL/NON-BLOCKING conveniences unless the frozen compiler/language subset
actually uses them:

- dependent/proof-binding conditionals such as `if h : P then ... else ...`
  and the anonymous-proof form `if _ : P then ... else ...`;
- ordinary proof-valued local bindings such as `have h : P := proof`;
- `show T from e` or an equivalent cheap expected-type annotation form.

When these forms are supported, the implementation must own the **bounded
Decidable closure** needed to make them real Lean-compatible terms rather than
syntax-only conveniences:

- synthesize a known `Decidable P` through the same bounded instance-search
  mechanism used elsewhere in elaboration;
- elaborate ordinary proposition-valued `if` through Lean-compatible `ite`;
- elaborate proof-binding/dependent branches through Lean-compatible `dite`
  when the branch result depends on the branch proof;
- introduce the positive/negative branch proof only in the corresponding local
  context;
- roll back Meta assignments and instance-search state when Decidable synthesis
  or a candidate branch elaboration fails;
- fail closed when the required Decidable instance cannot be synthesized.

This does **not** require ProofScript to implement the whole Lean Decidable
ecosystem or automation for proving propositions. It owns only the bounded
instance-driven semantics exercised by bootstrap code.

These are term-elaboration features, not tactic automation. Branch hypotheses
and `have` values must elaborate to ordinary proof terms that pskernel checks.

### SH3-HKT — cheap higher-kinded erasure experiment, non-blocking for PSC1

Before deciding whether the bootstrap compiler should directly use generic
Lean-style transformer definitions, add one deliberately small executable gate
for higher-kinded type parameters such as:

```lean
m : Type -> Type
```

The experiment must preserve the source/kernel semantics while keeping the
TypeScript backend simple:

1. recognize binders whose **type inhabits a Sort** as type-level binders even
   when that binder type is itself a function kind such as `Type -> Type`;
2. erase those higher-kinded binders from JavaScript runtime arguments;
3. permit runtime types headed by an erased type constructor, such as `m α`,
   to use a conservative verified-IR/TypeScript representation when no precise
   TypeScript type exists;
4. recursively erase type/proof binders inside runtime function types, so
   operations such as polymorphic `pure` and `bind` become ordinary runtime
   functions;
5. compile a tiny generic `Monad` plus `ReaderT`/`StateT`/`ExceptT`
   exercise through checked core -> erasure -> verified IR -> TypeScript ->
   JavaScript;
6. run the same gate from canonical `.lean` and `.ps` and require equal
   checked-core/IR fingerprints and equivalent JavaScript behavior.

The initial TypeScript representation may use `unknown` (or a dedicated
opaque-runtime type) at HKT-dependent annotation positions **after pskernel
checking**. This is a loss of host type precision, not a loss of ProofScript
soundness; TypeScript remains an untrusted backend.

Do **not** implement a TypeScript HKT encoding, URI-to-kind registry, higher-kinded
generic framework, or similar host-type machinery before PSC1. If this bounded
erasure experiment stays local and green, generic `ReaderT`/`StateT`/
`ExceptT` may be used by bootstrap code. If it expands into a large backend
project, use the concrete `CompilerM` profile and defer precise generic HKT
emission until after PSC2.

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

Also add a **SELFHOST-EFFECT** dual-source regression. It must implement a
compiler-like context/state/error computation with `pure`, `bind`, read,
get/modify, failure, recovery and rollback, compile to JavaScript, and
demonstrate that PSC1 does not require higher-kinded type applications to
survive into verified IR. When SH3-HKT is green, run the same behavioral
fixture through the generic transformer spelling as an additional equivalence
test, not as a prerequisite for the concrete lane.

## SH4 — recursion, iteration and executable control closure

Required PSC1 recursion/control closure:

- structural recursion sufficient for compiler data traversals;
- Lean-faithful executable `partial def` for algorithms whose termination is
  intentionally outside proof computation.

Keep the following planned but OPTIONAL/NON-BLOCKING unless a real compiler
module demonstrates that the simpler core is unreasonable:

- mutual recursive definitions;
- mutual inductive declarations;
- recursive local `where` / `let rec` groups;
- multiple structural-recursion conveniences;
- bounded/general well-founded recursion elaboration;
- `let mut` and reassignment;
- `for` and `while`;
- `break` / `continue`.

Prefer ordinary structural recursion, top-level helper functions and library
fold/traversal operations before promoting another control form to REQUIRED.

If `for` is implemented before PSC1, back it with a deliberately small
Lean-compatible iteration abstraction instead of hard-coding Array-only loop
semantics. A bounded `ForIn`-style library interface may cover only the
containers actually used. Neither `for` nor a generic iterator hierarchy is
required to finish PSC1.

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

PSC1 exit test: a structurally recursive parser/compiler traversal, one
controlled `partial def` utility, and a large compiler-style traversal run
through the verified backend without host mutation shortcuts or JavaScript
stack overflow in the covered profile. Mutual/local recursion and loop syntax
receive separate optional gates when implemented.

## SH4.5 — pattern-language closure

PSC1 requires one ordinary, deterministic single-scrutinee `match` path over
the constructors/literals needed by compiler data. Richer pattern syntax remains
planned but OPTIONAL/NON-BLOCKING:

- nested constructor patterns;
- tuple / `Prod` patterns;
- multi-scrutinee `match`;
- wildcard and literal patterns at nested positions beyond the required basic
  matcher;
- `if let`;
- ordinary `let` pattern destructuring;
- pattern binds in `do`.

Compiler code may express the same logic using explicit nested `match`
expressions until these conveniences land. When implemented, richer patterns
must desugar into ordinary checked eliminators and lets. Do not implement Lean's
complete dependent pattern compiler merely for surface parity. Indexed/dependent
pattern features remain workload-driven and must fail closed until their
elaboration semantics are owned.

PSC1 exit test: a parser/AST transformation module can express its logic using
the required ordinary single-scrutinee `match` path and execute through the
checked-core JavaScript path with no TypeScript-side pattern semantics. Richer
nested/multi-scrutinee/`if let`/let-pattern syntax receives optional
round-trip and execution gates when implemented.

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

Keep the following cheap implementation-language ergonomics in the plan, but
treat them as OPTIONAL/NON-BLOCKING for PSC1 unless compiler code actually
depends on them:

- field/projection notation;
- bounded method-style notation when it deterministically resolves to an
  ordinary declaration application;
- structure update syntax such as `{ s with field := value }`;
- named arguments;
- default arguments where the census shows repeated compiler use;
- grouped binders such as `(x y : T)` and `{α β : Type}`;
- unnamed instance binders such as `[Monad m]`, represented internally with
  deterministic generated names when a name is required;
- structure field defaults such as `field : T := default` and the bounded
  empty/default structure construction they justify;
- `abbrev` when it can be supported without introducing a second semantic
  mechanism;
- `opaque` when it can reuse pskernel's existing opacity semantics without a
  second elaboration path;
- simple string interpolation such as `s!"...{x}..."` when it can desugar to
  owned String append/builder operations plus bounded `ToString` support;
- `default` / `Inhabited` for compiler-state records when it can be provided
  as ordinary typeclass/library functionality;
- `Id.run` or an equivalent zero-cost identity runner when it makes
  mutation-looking pure blocks (`let mut`, loops) substantially clearer.

These are USEFUL/CHEAP conveniences, not PSC1 finish criteria. Already-landed
support remains supported. New support should be added only when cheap or
actually used, and must not introduce macro or runtime machinery beyond the
ordinary desugared terms.

Keep a bounded explicit universe surface in the census as OPTIONAL/NON-BLOCKING
source syntax, promoting only the pieces that compiler/library definitions
actually require:

- `universe u v`;
- `Type u` / `Sort u`;
- explicit constant levels such as `Foo.{u}`;
- the small level-expression subset actually exercised by bootstrap code.

Do not implement Lean's complete universe command/scoping convenience layer
merely for syntax parity. If the first compiler can remain in the ordinary
`Type` profile, explicit universe syntax may stay USEFUL/CHEAP rather than a
PSC1 blocker, but any universe syntax that is accepted must round-trip through
both `.lean` and `.ps` and elaborate to the same level expressions.

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

Host capability bindings used by the self-hosted compiler must be
**source-neutral**. Do not make the portable compiler depend on a `.ps`-only
`extern` declaration whose npm/runtime metadata is lost by `.ps -> .lean`
translation. Prefer a versioned capability manifest/adapter registration outside
the translated semantic source, from which both frontends receive the same
logical declarations. If source-level extern syntax is later admitted to the
bootstrap corpus, its binding metadata must survive both translation directions
through a source-neutral sidecar/artifact; silent metadata loss is forbidden.

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
authority. Its JSON parser, encoder and schema codecs must themselves be
expressible in the frozen dual-source subset so the bridge client can live in
both `.lean` and `.ps`.

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

The frozen PSC1 subset contains **only the REQUIRED capability set** from the
PSC1 minimality policy plus any optional facility that real compiler source has
actually adopted by freeze time. Merely being USEFUL/CHEAP, present in Lean, or
already listed in an SH milestone does not make a feature a freeze requirement.

Optional features stay documented and may already be implemented; they are not
removed. Their incomplete status cannot block SH7/PSC1 unless a required
compiler module depends on them. Expensive, unnecessary Lean implementation
machinery such as arbitrary user syntax, macro/quotation systems, custom
elaborators, generalized environment extensions, broad attribute registration
and unsafe casts remains outside the frozen subset by default.

Gate every supported bootstrap construct through the same `.lean` and `.ps`
frontends and checked-core path.

Maintain a **dual-source feature matrix** for the frozen subset. Each selected
feature must be green for:

1. `.lean` parse -> shared AST -> canonical `.lean`;
2. `.ps` parse -> shared AST -> canonical `.ps`;
3. `.lean -> .ps` translation -> reparse;
4. `.ps -> .lean` translation -> reparse;
5. elaboration/checking from both source kinds;
6. equal checked-core fingerprints;
7. equal compiler-IR fingerprints;
8. TypeScript emission from both source kinds;
9. JavaScript execution from both source kinds.

This matrix is a release gate, not documentation-only bookkeeping.

Before freezing, add one multi-module **SELFHOST-FEATURE** fixture/skeleton that
proves the minimal REQUIRED foundation composes rather than testing every
planned convenience. It must exercise at least:

- nontrivial `String`/`Char` lexer-style traversal and source positions;
- `List`, `Array`, ordered `Map`/`Set` and only the traversal
  combinators actually needed by the fixture/compiler;
- canonical JSON parse/encode plus at least one SH6b request/response codec;
- qualified `Name`, imports/modules and explicit environment updates;
- structures, inductives, constructors, projections and ordinary `match`;
- `Prod`/tuple-returning utilities without requiring tuple-destructuring
  syntax;
- structural recursion plus one controlled `partial` case;
- `do` with the concrete Reader/State/Except semantics, `return`,
  failure/alternative handling and transactional rollback;
- higher-order/generic traversal where the compiler truly needs it;
- implicit arguments, the bounded class/instance/`Decidable`/Meta behavior
  actually required by the frozen language subset;
- diagnostics/fresh IDs assembled from portable String operations;
- multi-module compilation;
- the versioned SH6b pskernel bridge, using the canonical String/JSON bootstrap
  transport, for lookup, a ground kernel query and declaration/inductive
  admission.

Maintain a separate **SELFHOST-OPTIONAL** matrix for conveniences that happen to
be implemented before PSC1 (for example literals, richer patterns, mutation
syntax, HKT transformers, `if h : P`, interpolation or method notation).
Those gates protect existing support but their absence/failure-to-implement does
not block PSC1 unless a REQUIRED compiler module adopts the feature.

The fixture must execute all four portability/build directions end-to-end:

```text
SELFHOST-FEATURE.lean -> canonical .ps   -> reparse/check
SELFHOST-FEATURE.ps   -> canonical .lean -> reparse/check

SELFHOST-FEATURE.lean
-> canonical source AST
-> Lean-compatible Meta/Elab
-> pskernel admission
-> checked core
-> erasure
-> verified compiler IR
-> TypeScript
-> tsc
-> JavaScript

SELFHOST-FEATURE.ps
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

The two build paths must produce the same checked-core/IR fingerprints and
semantically equivalent generated TypeScript/JavaScript. Translation
round-trips must also be canonical-idempotent:

```text
.lean -> .ps -> .lean -> canonical stability
.ps   -> .lean -> .ps -> canonical stability
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

Every SH8a compiler module is authored and reviewed only in `.lean`. It must
pass the official Lean 4.34 build, the portable source-profile audit, and the
owned ProofScript semantic path for every feature that path already supports.
Do **not** hand-author or manually synchronize `module.ps` siblings during
SH8a.

The compiler architecture, AST, names, elaboration, checked-core contracts and
IR must nevertheless stay source-neutral. When SH8a has produced a complete
enough compiler to translate its own frozen Lean subset, run the first
compiler-produced source transition over the whole compiler tree:

```text
module.lean -> completed compiler -> generated canonical module.ps
```

Then gate the generated ProofScript corpus against the Lean corpus for
parse/elaboration behavior, checked-core and compiler-IR fingerprints, and
TypeScript/JavaScript behavior. This makes `.ps` a compiler output before it
ever becomes a maintained source.

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

## SH10 — make .ps the authoritative compiler source

SH10 starts from the compiler-generated canonical `.ps` tree produced from
the completed Lean-authored compiler. First close the full parity campaign and
reverse-translation/idempotence gates; then promote the green ProofScript form
to the primary maintained source and keep canonical Lean as a supported
generated/translated representation.

The target condition is:

```text
compiler.ps   --PSC1--> PSC2
compiler.ps   --PSC2--> PSC3
compiler.ps   --translate--> compiler.lean
compiler.lean --translate--> compiler.ps
```

with the same checked-core/IR/TS/JS equivalence gates. Neither direction may
silently drop a language feature, proof term, module/import relation, universe
annotation, or host-capability association.

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
- precise TypeScript higher-kinded-type encodings or a generic HKT host
  framework; bootstrap may erase HKT-dependent host annotations conservatively;
- generic transformer-stack convenience beyond the bounded SH3-HKT probe,
  including `OptionT`, broad `MonadLift` derivation, `MonadControl`,
  `StateRefT`, `EStateM` and transformer-law hierarchies, unless a real
  compiler module requires them;
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
2. Is it REQUIRED by a compiler module? If it is merely USEFUL/CHEAP, can it
   remain optional without delaying self-hosting?
3. Can the need be satisfied as a ProofScript library instead of a language
   primitive?
4. Can host-specific behavior remain a thin TypeScript adapter?
5. Does the change preserve the single checked-core semantic path?
6. Would implementing it require importing a disproportionately large Lean
   metaprogramming subsystem that the compiler does not actually need?
7. If the feature exists mainly to mirror Lean's generic implementation style,
   can PSC1 use the same semantics through a simpler concrete representation
   while keeping the source/kernel model compatible with a later generic form?

If the feature is not REQUIRED, it does not block PSC1. Keep useful features in
the plan, land them opportunistically when local/desugaring-based, and preserve
already-landed support, but continue toward SELFHOST-FEATURE instead of waiting
for optional completeness. Promote an optional item to REQUIRED only when a
real compiler module or frozen semantic obligation cannot reasonably avoid it.
Expensive extensibility machinery remains deferred until a concrete compiler
requirement changes its classification.
