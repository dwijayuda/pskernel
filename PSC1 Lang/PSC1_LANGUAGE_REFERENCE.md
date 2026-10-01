# ProofScript PSC1 Language Reference

Status: **comprehensive repository-derived PSC1 draft**

Baseline repository revision:
`165468c7f195c60906075e774543c1e65b3518f1` on `main`.

Semantic baseline: **Lean 4.34**, as pinned by the repository's study and
architecture policy.

Language-source baseline: **ProofScript v0.7 line with v0.6.1 as the compatible
compiler-ready baseline**. v0.8 is not normative for PSC1.

---

## 1. Purpose and scope

PSC1 is a small general-purpose programming and verification language profile.
It is intended to be sufficient to implement the ProofScript compiler itself,
while preserving a clear path to dependent types, theorem proving, formal
verification, JavaScript/npm integration, native Rust generation, and direct
WebAssembly generation.

PSC1 deliberately separates four questions:

1. **Surface syntax** — what source text is accepted?
2. **Logical semantics** — what does the program/proof mean?
3. **Executable semantics** — what observable computation does an executable
   term denote?
4. **Backend representation** — how does a target encode that computation?

The first three are language concerns. The fourth is not allowed to redefine
the first three.

PSC1 is not:

- full Lean syntax;
- TypeScript with a proof checker bolted on;
- JavaScript semantics with dependent types;
- a text-to-text preprocessor;
- a backend-specific IR language.

The fact that official Lean 4.34 accepts a construct does **not** automatically
make that construct part of PSC1.

---

## 2. Normative architecture

A runtime feature is complete only when its applicable path is executable:

```text
.ps or supported .lean
-> source-kind frontend
-> canonical source AST
-> Lean-compatible Meta / Elab
-> pskernel admission
-> CheckedCore
-> semantics-preserving erasure
-> target-neutral VerifiedIR
-> target backend
```

For the TypeScript backend the tail is:

```text
VerifiedIR -> backend-ts -> .ts -> pinned tsc -> .js + .d.ts + source map
```

Proof-only declarations stop at pskernel admission and do not need executable
runtime lowering.

### 2.1 Trust boundary

The default logical TCB is intentionally small.

The following are outside the logical TCB:

- lexer and parser;
- name resolver;
- Meta/elaborator implementation;
- tactics;
- erasure and optimizer;
- compiler backends;
- TypeScript compiler;
- Rust compiler;
- Wasm encoder/runtime;
- LSP/editor;
- package manager;
- host/FFI code.

They may construct or transport proof terms, but proof authority comes from
kernel declaration admission.

### 2.2 Claim discipline

PSC1 MUST NOT be described as fully Lean-equivalent merely because many Lean
programs pass or because pskernel has extensive compatibility evidence.
Semantic compatibility claims must state their exact supported scope and
evidence.

---

## 3. Language design laws

### 3.1 Lean-compatible logical meaning

Within the claimed PSC1 profile, the following retain Lean-compatible
foundational meaning:

- terms and types;
- universes;
- dependent function types;
- propositions and proof terms;
- inductive types, constructors, recursors, and eliminators;
- definitional equality;
- pattern-match semantics;
- positivity and recursion/termination acceptance;
- coercions and class/instance synthesis where supported;
- theorem/kernel acceptance.

PSC1 may offer friendlier syntax, but that syntax MUST lower to the same
semantic mechanisms rather than inventing a second checker.

### 3.2 One mechanism before sugar

PSC1 prefers:

- functions and lambdas for computation;
- structures and inductives for data;
- one ordinary `match` mechanism for elimination;
- structural recursion plus a controlled executable `partial def` boundary;
- `Option` for absence;
- a `Result`/`Except`-style ADT for recoverable errors;
- libraries for reusable traversal and algorithms;
- an explicit effect abstraction for state/context/errors;
- explicit host capabilities at boundaries.

New syntax is not justified merely because another mainstream language has it.

### 3.3 Fail closed

Unknown or unsupported forms MUST fail with a specific diagnostic before they
can be mistaken for checked semantics.

No backend MAY "support" a source construct that has not first been represented
and admitted by the source/semantic pipeline.

---

## 4. Source feature classes

PSC1 inherits the v0.7 vocabulary for classifying surface syntax.

| Class | Meaning |
| --- | --- |
| L | Lean-compatible form admitted by the bounded PSC1/Lean-subset profile. |
| D | Conservative ProofScript decoration with a clear discriminator and canonical Lean meaning. |
| E | Context-owned ProofScript spelling that intentionally differs from Lean source but lowers deterministically. |
| X | Semantic divergence forbidden in the portable verified core. |

Unlike the broader v0.7 reference-Lean profile, PSC1 does **not** treat all
remaining Lean syntax as automatically inherited L-class syntax. L-class
support is bounded by the frozen profile and executable gates.

### 4.1 Core owned D/E surface

PSC1 preserves these v0.7/v0.6.1 forms:

- `D-CALL` — adjacent call syntax `f(x, y)`;
- `D-EXPLICIT-PARAMS` — comma-separated explicit declaration parameters;
- `D-DECL-SEMI` — semicolon termination in registered ProofScript
  declaration contexts;
- `D-CONST-ALIAS`;
- `D-FUNCTION-ALIAS`;
- `E-IF-BRACE`;
- `E-STRUCT-BODY`;
- `E-CLASS-BODY`;
- `E-INDUCTIVE-BODY`;
- `E-MATCH-BODY`;
- `E-WHERE-BODY`.

The repository also has a post-v0.7 host-boundary extension,
`D-EXTERN-FFI`, described later. It is not retroactively presented as a
v0.7 reference feature.

---

## 5. Lexical rules and punctuation

PSC1 keeps Lean-oriented punctuation where it communicates semantics.

- `:=` is definition/binding/update syntax in the contexts that define it.
- `=` is propositional equality.
- `==` is Boolean equality through the supported Lean-compatible equality
  machinery.
- `->` denotes function/dependent-function arrows in the supported source
  profile.
- Braces are category-specific; they do not create a universal JavaScript
  statement block.
- Semicolons are category-specific; they are not globally erased.
- Comments and whitespace matter to D-CALL ownership.

The implementation MUST NOT perform global textual rewrites such as replacing
all parentheses with spaces, stripping all semicolons, or treating all brace
pairs as blocks.

---

## 6. Declarations

### 6.1 `def`

`def` is the canonical general definition mechanism.

```proofscript
def answer: Nat := 42;

def add(x: Nat, y: Nat): Nat :=
  x + y;
```

Canonical Lean:

```lean
def answer : Nat := 42

def add (x : Nat) (y : Nat) : Nat :=
  x + y
```

### 6.2 `const`

`const` is a **parameterless `def` alias**.

```proofscript
const answer: Nat := 42;

const increment: Nat -> Nat :=
  fun x => x + 1;
```

A `const` MAY have a function type. It MUST NOT have declaration parameters.

Rejected:

```proofscript
const add(x: Nat, y: Nat): Nat := x + y;
```

`const` does not introduce JavaScript binding/object-immutability semantics.

### 6.3 `function`

`function` is a **parameterized `def` alias** and requires at least one
explicit declaration parameter group.

```proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y;

function identity {α: Type}(x: α): α :=
  x;
```

Rejected:

```proofscript
function answer: Nat := 42;
```

`function` does not introduce hoisting, prototypes, `this`, JavaScript
statement bodies, or unrestricted early `return`.

### 6.4 Alias identity

`def`, valid `const`, and valid `function` declarations share one semantic
declaration kind.

Canonical Lean translation emits `def`.

Canonical ProofScript translation MAY normalize aliases to `def`; semantic
round-trip correctness is based on checked-core and executable-IR identity, not
lexical preservation of the alias.

### 6.5 Theorems

A theorem is a logical declaration whose type is a proposition and whose body
constructs a proof term.

```proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  rfl
}
```

The exact set of accepted tactic syntax is a separate bounded frontend
capability. Tactics never become kernel authorities.

### 6.6 Other Lean declaration conveniences

The v0.7 study reference discusses Lean forms such as `abbrev`, `opaque`,
and `example`. PSC1 does not require those source conveniences for the first
freeze unless the frozen compiler actually adopts them.

They must therefore be treated as optional/source-profile capabilities, not as
implied support merely because Lean has them.

---

## 7. Binders, polymorphism, and dependent functions

PSC1 retains Lean binder meaning.

```proofscript
(x: A)        -- explicit
{α: Type}     -- implicit
{{α: Type}}   -- strict implicit, when supported by the frozen subset
[C α]          -- instance implicit
```

Registered declaration/header contexts may group complete explicit binders:

```proofscript
function get(n: Nat, i: Fin n): Fin n :=
  i;
```

Binder order is semantically significant and MUST be preserved.

PSC1 does not replace Lean implicit/dependent binders with TypeScript generic
angle-bracket syntax.

### 7.1 Function types

Ordinary function type:

```proofscript
Nat -> Nat
```

Dependent function type:

```proofscript
(x: Nat) -> Fin x -> Nat
```

The dependent arrow denotes ordinary dependent Pi semantics; it is not a
ProofScript-specific runtime feature.

### 7.2 Lambdas

Anonymous functions use `fun`:

```proofscript
fun x => x + 1
fun (x: Nat) => x + 1
```

TypeScript/JavaScript arrow-lambda spelling is not part of the PSC1 normative
surface.

---

## 8. Function application

PSC1 supports ordinary admitted Lean-style application and the D-CALL
decoration.

```proofscript
add(1, 2)
normalize(transform(x))
f()
f((x, y))
```

Canonical Lean:

```lean
add 1 2
normalize (transform x)
f ()
f (x, y)
```

Multiple D-CALL arguments are curried application, not an n-ary primitive:

```text
f(x, y)  ==  (f x) y
```

Tuple distinction:

```proofscript
f(x, y)     -- two curried arguments
f((x, y))   -- one tuple argument
f (x, y)    -- protected Lean-style neighbor: one tuple argument
```

Adjacency is part of the syntax ownership rule:

```text
f(x)         D-CALL
f (x)        not D-CALL
f/*c*/(x)    not D-CALL
```

Whitespace/comment-separated forms are not silently rewritten into D-CALL.

---

## 9. Expressions and operator foundation

The currently shared ProofScript expression precedence table for the supported
Nat/Bool binary surface is, from weaker to stronger binding:

| Level | Operators |
| ---: | --- |
| 1 | `||` |
| 2 | `&&` |
| 3 | `==`, `!=` |
| 4 | `<`, `<=`, `>`, `>=` |
| 5 | `+`, `-` |
| 6 | `*`, `/`, `%` |

Applications bind tighter than these binary operators.

Native propositional `=` is parsed separately as a non-associative proposition
operator. In the supported theorem/type grammar, the current relationship is:

```text
application
  > arithmetic / relation / Bool binary terms
  > propositional =
  > function/dependent arrow
```

Canonical Lean printing MUST insert parentheses when ProofScript and Lean
precedence numbers differ, so AST meaning is preserved.

The current operator surface is not a promise of a generic user-defined
operator-overloading system. Each executable/operator family still requires
Lean-compatible elaboration and checked semantics.

---

## 10. Conditionals

PSC1 admits ordinary supported Lean conditionals:

```proofscript
if c then t else e
```

and the braced ProofScript form:

```proofscript
if (c) {
  t
} else {
  e
}
```

The braced form lowers to the ordinary conditional semantics.

Each braced branch is one expression. The braces do not create JavaScript
statement-block semantics.

Rejected as a generic statement block:

```proofscript
if (c) {
  x;
  y;
} else {
  z
}
```

Sequencing belongs to an explicit effect/sequencing construct such as `do`.

---

## 11. Structures

PSC1 structures are nominal Lean-compatible data declarations, not JavaScript
objects.

```proofscript
structure Point where {
  x: Float;
  y: Float;
}
```

Canonical Lean:

```lean
structure Point where
  x : Float
  y : Float
```

Constructor generation, projections, parameter dependence, and logical
admission follow the checked semantics.

Record values use the supported record syntax:

```proofscript
const origin: Point := { x := 0, y := 0 };
```

Structure-update convenience is optional/non-blocking for the first PSC1 freeze
unless adopted by frozen compiler source.

---

## 12. Classes and instances

PSC1 classes are typeclasses, not object-oriented classes.

A class declaration is a logical structure-like declaration participating in
bounded class/instance synthesis.

```proofscript
class Sized(α: Type) where {
  size: α -> Nat;
}
```

The frozen PSC1 compiler must support only the class/instance/`Decidable`
machinery it actually needs. Broad Lean typeclass-system convenience is not
implicitly required.

PSC1 does not introduce JavaScript/C++-style constructors, inheritance,
prototype chains, `static`, or `this` as class semantics.

---

## 13. Inductive types

PSC1 supports inductive data with Lean-compatible constructor and recursor
meaning.

```proofscript
inductive Result(α: Type, ε: Type) where {
  | ok(value: α);
  | error(error: ε);
}
```

Canonical Lean:

```lean
inductive Result (α : Type) (ε : Type) where
  | ok (value : α)
  | error (error : ε)
```

Positivity, universe validity, constructor types, generated recursors, and
elimination validity remain checked semantic obligations.

Mutual inductive declaration syntax is optional/non-blocking for the first PSC1
freeze unless real compiler source adopts it.

---

## 14. Pattern matching

PSC1 requires ordinary basic single-scrutinee match.

```proofscript
function getOrElse(value: Option Nat, fallback: Nat): Nat :=
  match value with {
    | .none => fallback;
    | .some x => x;
  };
```

Patterns retain the bounded Lean-compatible pattern vocabulary.

Constructor patterns are not rewritten into TypeScript call syntax merely for
surface consistency.

Richer nested patterns, multi-scrutinee pattern sugar, `if let`, let-patterns,
and do-patterns are optional/non-blocking unless compiler evidence promotes
them.

---

## 15. Local definitions and `where`

The owned braced `where` form is preserved:

```proofscript
def f(x: Nat): Nat :=
  helper(x)
where {
  helper(y: Nat): Nat := y + 1;
}
```

Canonical Lean uses Lean local-declaration structure without the ProofScript
braced body.

Local/mutual recursion syntax is not automatically REQUIRED. The first freeze
may use top-level helpers or a single structural dispatcher when that expresses
the compiler naturally.

---

## 16. Core scalar vocabulary

The PSC1 scalar/type foundation is:

```text
Nat Int
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
Float Float32
Bool Char String Unit
```

These are language-level semantic types, not backend aliases.

### 16.1 `Nat` and `Int`

`Nat` and `Int` retain exact mathematical integer semantics. They MUST NOT
silently become bounded JavaScript numbers, Rust machine integers, or Wasm
integers.

A backend MAY use a narrower representation only when a semantics-preserving
optimization establishes the required range.

### 16.2 Fixed-width unsigned and signed integers

`UInt8/16/32/64` and `Int8/16/32/64` have their declared machine widths.
Their operations/conversions must follow the single frozen PSC1 scalar
contract.

Width is semantic; backend overflow configuration is not.

### 16.3 `USize` and `ISize`

`USize` and `ISize` are target-word-sized types. A target profile may use a
32-bit or 64-bit word size. Cross-target behavior must be explicit where width
is observable.

### 16.4 `Float` and `Float32`

`Float` and `Float32` preserve the pinned semantics selected by PSC1/Lean
for supported operations. Deterministic/verified profiles MUST NOT silently
enable fast-math reassociation or another target optimization that changes
observable semantics.

### 16.5 `Bool`, `Char`, `String`, `Unit`

These preserve their Lean-compatible semantic roles. Backends may choose
efficient encodings but may not expose target object identity or representation
as the source semantics.

### 16.6 Open scalar freeze obligation

The type list above is frozen, but the full operation/conversion matrix is not
yet closed on the baseline revision.

Before PSC1 SH7 freeze, the repository must normatively decide and gate every
accepted case for:

- fixed-width addition/subtraction/multiplication overflow;
- division/remainder, including zero divisor and signed rules;
- shifts/rotates and bitwise operations;
- widening and narrowing conversions;
- signed/unsigned conversion;
- `Nat`/`Int` to/from machine integers;
- integer/floating conversions;
- `Float32`/`Float` conversions;
- NaN, signed zero, and floating comparison;
- floating bit conversions where exposed;
- `USize`/`ISize` target-width behavior.

Until that matrix is frozen, an implementation MUST NOT define the language by
whatever its backend happens to do.

---

## 17. Required data and collection capabilities

The self-hosting profile requires the usable capabilities of:

- `List`;
- `Option`;
- `Prod`;
- `Array`;
- ordered map;
- ordered set;
- a typed `Result`/`Except`-style error value.

The exact library namespace/name used during bootstrap may be library-owned.
For example, repository standard-library work may temporarily use explicit
ProofScript-owned names while executable metadata for canonical Prelude types
is being established.

Only the operations exercised by the frozen compiler are REQUIRED for PSC1
closure. A large standard library is not a language prerequisite.

---

## 18. Recursion and termination

PSC1 requires:

- ordinary structural recursion sufficient for compiler algorithms;
- direct recursive ADTs;
- a controlled executable `partial def` boundary for cases that cannot be
  expressed conveniently under the first structural subset.

Logical termination and proof acceptance remain Lean-compatible concerns.

A `partial def` executable capability MUST NOT become a way to manufacture
proofs or weaken kernel admission.

General well-founded recursion, multiple recursion conveniences, mutual/local
recursion syntax, or advanced termination elaboration are optional until actual
compiler code requires them.

---

## 19. Propositions and proofs

`Prop` is the proposition universe. A theorem statement is a type in `Prop`;
a proof is a term inhabiting that type.

PSC1 does not add a second Boolean proposition logic.

Examples:

```proofscript
theorem selfEq {α: Type}(x: α): x = x := by {
  rfl
}
```

`=` denotes proposition equality. `==` remains Bool-valued equality for
supported `BEq`-style behavior. A Boolean equality result does not silently
become a proposition; a statement such as `(x == y) = true` remains a
proposition when that is what is intended.

---

## 20. Meta/elaboration foundation

PSC1's self-host compiler needs a bounded but real dependent elaboration
foundation, including where used by frozen source:

- expected-type propagation;
- implicit-argument insertion;
- metavariables and assignments;
- unification sufficient for the profile;
- universe metavariables/constraints sufficient for admitted declarations;
- definitional-equality queries;
- bounded class/instance synthesis;
- `Decidable` synthesis where required;
- environments, local contexts, names, and source diagnostics;
- construction of ordinary kernel terms/declarations for pskernel admission.

No syntax-specific shortcut may bypass these semantics merely to make a backend
test pass.

---

## 21. Tactics

Tactics are proof-term construction tools outside the TCB.

The repository's current bounded theorem-prover surface includes or is
actively gated around:

- `exact`;
- `assumption`;
- `intro`;
- bounded `apply`;
- bounded `refine` with controlled synthetic holes;
- `constructor`;
- bounded `cases`;
- bounded `induction`;
- Eq-oriented `rfl`;
- bounded Eq `rw`;
- bounded explicit `simp only`;
- bounded `exact?` search.

This tactic surface is **not** a claim of full Lean tactic compatibility.
Unsupported elaboration/search cases fail closed.

Large automation such as full `simp`, `omega`, `aesop`, `grind`,
`linarith`, `ring`, or `native_decide` is not a prerequisite for the first
core self-host.

The first PSC1 compiler source should avoid depending on proof automation that
has not moved into the self-hosted frontend.

---

## 22. Effects and `do`

Ordinary portable PSC1 functions are referentially transparent with respect to
portable language semantics.

Compiler implementation requires an explicit reader/state/error effect
capability, conceptually a concrete `CompilerM`-style abstraction with:

- context/reader access;
- state;
- typed failure;
- `pure`;
- `bind`;
- `do` sequencing;
- recovery/alternative handling;
- transactional rollback where specified.

Effect sequencing is determined by PSC1 effect semantics, not by JavaScript
evaluation order, Rust statement order, or Wasm instruction order.

`return` is not a universal imperative early-return statement. Where admitted
in `do`, it has the effect notation's semantics.

Generic transformer stacks such as `ReaderT`, `StateT`, `ExceptT`,
`OptionT`, and automatic `MonadLift` are useful but optional/non-blocking
unless the frozen compiler actually uses them.

---

## 23. Mutation-looking syntax and loops

PSC1 does not require mutable-looking locals, reassignment, `for`, `while`,
`break`, or `continue` for its first freeze when the same compiler can be
written naturally with recursion, folds, and the explicit state effect.

If such constructs are admitted, they MUST desugar into the existing semantic
mechanisms rather than import JavaScript or Rust mutation semantics.

Already-supported optional forms must not be silently broken merely because
they are not freeze blockers.

---

## 24. Modules, imports, and names

PSC1 requires deterministic modules/imports and qualified names.

The bounded shared import header is:

```proofscript
import Foo.Bar
```

The project graph is source-kind independent. A logical module can be supplied
by a supported `.ps` or bounded `.lean` source file.

A logical module name MUST resolve deterministically. If both source kinds, or
multiple configured source roots, produce ambiguous candidates and project
configuration does not disambiguate them, compilation fails.

Importing a `.lean` file does not grant full Lean language access. The
`.lean` frontend remains the bounded PSC1 Lean subset.

Broad namespace/section/open-scoped convenience is not a PSC1 completion
requirement unless frozen compiler source adopts it.

---

## 25. Dual-source `.ps` and bounded `.lean`

PSC1 supports a semantic interoperability goal between canonical ProofScript
and a documented bounded Lean source profile.

Source conversion is canonicalization, not lexical preservation.

Initially allowed to change:

- formatting;
- whitespace;
- parentheses;
- supported binder spelling;
- declaration alias spelling;
- other documented sugar.

Not promised:

- comment preservation;
- byte-identical source;
- arbitrary macro spelling;
- unsupported notation.

Required semantic relationship:

```text
.ps
 -> shared AST
 -> checked core
 -> VerifiedIR

supported .lean
 -> shared AST
 -> checked core
 -> VerifiedIR
```

Equivalent programs must converge before semantic acceptance.

The source kind may affect parsing, printing, diagnostics, and reporting. It
MUST NOT create a second checker or backend semantics.

Unsupported Lean constructs fail closed rather than being approximated.

During the current self-host transition, handwritten compiler source remains
`.lean` until the compiler can generate its own canonical `.ps` source. The
initial `.ps` compiler tree is generated, compared for checked-core/IR
identity, and only then promoted to maintained source.

---

## 26. Canonical source translation

The intended transition requires:

```text
compiler.lean
 -> completed compiler
 -> canonical compiler.ps
 -> parse / elaborate / pskernel
 -> equal checked-core fingerprints
 -> equal VerifiedIR fingerprints
 -> equivalent generated target behavior
```

After `.ps` becomes authoritative, canonical Lean remains a generated or
translated representation where the source feature can be represented
faithfully.

Translation MUST reject a feature rather than silently drop semantic metadata.

---

## 27. Host capabilities and FFI

Host facilities are not proof evidence.

A host operation may appear as an ordinary pure function only if its capability
contract explicitly classifies it as a trusted deterministic/pure runtime
assumption compatible with that signature.

Operations that observe or mutate the external world — filesystem, process,
network, clock, randomness, mutable host state, and similar APIs — must cross an
explicit effect/capability boundary.

Host exceptions/rejections used for recoverable failure must be translated at
the adapter boundary into the declared PSC1 error/effect channel unless the
capability is explicitly defined as an unrecoverable abort.

### 27.1 Current named-ESM extension

The repository currently supports a deliberately bounded post-v0.7 source
extension of the form:

```proofscript
extern function hostInc(x: Nat): Nat
  from "host-lib"
  import inc;
```

This is a runtime assumption with explicit binding metadata.

Current policy keeps this boundary narrow:

- first-order named ESM binding;
- runtime dependency explicitly allowlisted by exact package root/version;
- supported public package subpaths may be used under that root;
- proof-valued or polymorphic external signatures are rejected by the first
  profile;
- JavaScript execution is never proof evidence;
- unsupported default/namespace/CommonJS/dynamic-import forms remain
  fail-closed.

A module containing this extension cannot always be translated losslessly to
ordinary Lean source because the npm binding metadata has no equivalent
logical Lean source spelling. Translation must therefore fail rather than drop
the metadata.

A target-specific external capability also narrows backend portability unless
that capability has an explicit equivalent contract on other targets.

---

## 28. Portable value identity

Portable PSC1 values are semantic values, not host objects or addresses.

Structures, inductives, arrays, strings, closures, and other managed values
must not expose:

- JavaScript object identity;
- Rust storage address/layout;
- Wasm reference identity or linear-memory addresses;

as their ordinary source-language identity.

Equality and ordering come from declared PSC1 semantics/typeclasses.

A future explicit reference-identity capability would be a separate effectful
feature, not an accidental consequence of a backend representation.

---

## 29. Target-neutral compilation

All execution backends consume the same post-erasure semantic IR.

```text
                    CheckedCore
                        |
                     Erasure
                        |
                   VerifiedIR
                 /     |      \
                /      |       \
              TS      Rust     Wasm
```

VerifiedIR MAY contain:

- PSC primitive semantic types;
- functions, lambdas, calls, and lexical bindings;
- structures and inductives;
- constructors, projections, and matches;
- semantic intrinsics;
- target-neutral capability identities;
- target-neutral optimization facts justified by PSC semantics.

VerifiedIR MUST NOT contain:

- JavaScript `number`/`bigint`, Node/npm layout decisions;
- Rust `u32`/`Vec`, ownership, borrowing, lifetimes, traits, Cargo/ABI
  decisions;
- Wasm `i32/i64/f32/f64`, opcodes, memories, tables, GC layouts, WIT/WASI, or
  binary sections;
- target-specific calling convention, allocation, or object layout.

Each backend may introduce a private target IR **after** VerifiedIR.

---

## 30. Backend profiles

### 30.1 TypeScript/JavaScript

The TypeScript backend emits TypeScript. It does not maintain a second
Lean-authored direct JavaScript emitter.

```text
VerifiedIR -> TypeScript -> pinned tsc -> JavaScript
```

The pinned TypeScript compiler is an implementation checker/tool, not a proof
authority.

### 30.2 Rust

The planned Rust backend consumes the same VerifiedIR. Rust ownership,
borrowing, lifetimes, traits, and `unsafe` are target implementation concerns
and MUST NOT flow backward into PSC1 semantics.

Generated ordinary application/compiler code should prefer safe Rust. Any
unavoidable unsafe runtime/FFI implementation belongs behind an explicit small
audited boundary.

### 30.3 WebAssembly

The direct Wasm backend likewise consumes the same VerifiedIR and lowers to a
Wasm-specific target IR before encoding.

Wasm GC, typed function references, packed storage, SIMD, memory64, WASI/WIT,
and component mechanisms are target choices only.

A deterministic assurance profile must not silently use relaxed or
semantics-changing floating-point transformations.

---

## 31. Portable package rule

A pure ProofScript library that uses only portable PSC APIs should be
backend-polymorphic:

```text
library.ps
 -> CheckedCore
 -> Erasure
 -> VerifiedIR
    +-> backend-ts   -> JS/npm
    +-> backend-rust -> native/Cargo artifact
    +-> backend-wasm -> .wasm/component-oriented artifact
```

A package that imports npm-only, OS-only, WASI-only, native-only, or another
target-specific capability must declare the resulting narrower target set.

Target dependencies never contaminate the semantic meaning of shared
VerifiedIR.

---

## 32. Required vs optional PSC1 capabilities

### 32.1 REQUIRED for the first freeze

- functions/lambdas/application/`let`;
- `def`, `const`, `function`;
- ordinary `if`;
- basic single-scrutinee `match`;
- structures, inductives, constructors, projections;
- complete frozen scalar type vocabulary;
- required collection/data families and compiler-used operations;
- dependent function types, `Prop`, proof terms;
- required universe/implicit/metavariable/defeq machinery;
- bounded required class/instance/`Decidable`;
- structural recursion;
- controlled executable `partial def`;
- concrete compiler reader/state/error effects with rollback;
- modules/imports/names/resolution;
- tokens/spans/diagnostics;
- JSON codec and versioned pskernel bridge;
- canonical dual-source translation/equivalence;
- target-neutral verified lowering.

### 32.2 OPTIONAL/NON-BLOCKING unless adopted by frozen compiler source

- generic monad-transformer stacks and automatic `MonadLift`;
- TypeScript-style HKT encodings;
- `Sum` when not needed by compiler data;
- list/array literal syntax;
- tuple destructuring sugar;
- generic `GetElem`;
- mutual inductives;
- mutual/local recursion syntax;
- general well-founded termination elaboration;
- `let mut`, reassignment, loops, `break`, `continue`;
- rich/nested/multi-scrutinee patterns;
- `if let`, let-patterns, do-patterns;
- method-style notation;
- structure-update sugar;
- named/default arguments;
- grouped-binder conveniences beyond required headers;
- unnamed instance binders;
- structure field defaults;
- `abbrev`, source-level `opaque`;
- interpolation;
- `Inhabited`/`default` conveniences;
- `Id.run`;
- explicit user universe commands/syntax when inference suffices;
- broad visibility/section/open-scoped convenience.

An optional feature that already works remains supported; this classification
only says it does not determine whether PSC1 is frozen.

### 32.3 DEFERRED by default

Unless concrete compiler evidence changes the classification:

- arbitrary user syntax extension;
- macros/quotations;
- custom parser categories;
- custom elaborators;
- generalized environment extensions;
- broad attribute-registration machinery;
- compile-time interpreter machinery;
- `implemented_by`-style implementation substitution;
- unrestricted unsafe casts/escape hatches.

### 32.4 HOST-BOUNDARY

Examples include:

- filesystem;
- process execution;
- TypeScript compiler API;
- Node/npm resolution;
- clocks/randomness/network;
- platform-specific native or Wasm facilities.

These require typed adapters/capability contracts and do not become core
semantics.

---

## 33. Rejected semantic-divergence families

The portable verified core rejects or refuses to assign special proof meaning
to:

- JavaScript truthiness;
- TypeScript `any` or `unknown` as a proof escape;
- implicit `null`/`undefined` option semantics;
- prototype inheritance;
- JavaScript class semantics;
- unrestricted imperative `return`;
- host `throw`/`catch` as a silent replacement for typed effects;
- Promise semantics as a silent replacement for PSC effects;
- TypeScript `<T>` as a replacement for dependent/implicit binders;
- function hoisting;
- `this` binding.

These are X-class semantic divergences, not merely syntax features waiting to
be implemented.

---

## 34. Diagnostics and source fidelity

A source-language implementation should preserve enough source information for:

- correct diagnostic locations;
- source maps;
- formatter round-trip within the canonical subset;
- hover/navigation binding identity;
- canonical Lean traceability where supported.

Errors should point to original `.ps` or bounded `.lean` locations whenever
possible.

Generated target source is not the canonical place to report a source semantic
error.

---

## 35. Version axes

A serious PSC1 artifact/release should distinguish at least:

- ProofScript language/spec revision;
- compiler revision;
- module artifact format version;
- pskernel API/version;
- Lean semantic baseline and commit;
- implementation profile;
- scalar/runtime profile revision;
- source feature registry revision;
- axiom/trust policy;
- backend/runtime profile.

A single package semver must not be interpreted as proving all of these axes
identical or equivalent.

---

## 36. Conformance principle

A PSC1 implementation is not conforming merely because representative examples
parse.

For each claimed executable feature the repository should have evidence across
the applicable chain:

1. source parsing/AST ownership;
2. canonical source/Lean translation where defined;
3. Lean-compatible elaboration;
4. pskernel declaration admission;
5. checked-core identity;
6. erasure;
7. VerifiedIR identity;
8. backend emission;
9. runtime behavior.

Proof-only features require proof-term construction plus kernel admission, not a
runtime backend.

Unsupported cases require negative tests.

---

## 37. First PSC1 self-host freeze gate

Before the SH7 language subset can be declared frozen, each selected REQUIRED
feature must be green through:

1. bounded `.lean` parse -> shared AST -> canonical `.lean`;
2. owned elaboration/checking path;
3. stable checked-core fingerprint;
4. stable compiler-IR/VerifiedIR fingerprint;
5. TypeScript emission;
6. JavaScript execution where executable.

In addition, the freeze requires:

- declaration-alias semantic identity/rejection gates;
- the normative scalar operation/conversion matrix;
- explicit host capability purity/effect classification;
- no backend-object identity in portable values;
- a composed multi-module SELFHOST-FEATURE program exercising the required
  foundation through the real path.

Passing isolated parser tests is insufficient.

---

## 38. Self-host transition

The intended compiler bootstrap sequence is:

```text
current TypeScript compiler/oracle (PSC0)
  |
compiler.lean --PSC0--> compiler.ts --tsc--> first generated JS compiler
  |
compiler.lean --generated compiler--> next compiler
  |
fixed-point comparisons
  |
generate canonical compiler.ps
  |
prove semantic/fingerprint parity
  |
promote compiler.ps to authoritative maintained source
```

The self-host claim is a reproducibility/semantic-generation claim. It is not
by itself a proof that compiler lowering is correct.

Compiler-correctness proofs are a later assurance layer.

---

## 39. Compatibility and evolution rule

A new PSC1 language feature should not land informally.

It should define:

1. a stable feature identity/classification;
2. exact source grammar;
3. semantic meaning/canonical Lean lowering where applicable;
4. compatibility cost;
5. AST representation;
6. positive and negative parser tests;
7. elaboration/type behavior;
8. checked-core behavior;
9. erasure/IR behavior if executable;
10. backend/runtime tests if executable;
11. trust and assurance claim ceiling;
12. whether it is REQUIRED, OPTIONAL, DEFERRED, or HOST-BOUNDARY.

A feature becomes REQUIRED only from a concrete compiler requirement or frozen
semantic obligation, not from language-fashion parity.

---

## 40. Normative open items on the baseline revision

The following should be treated as explicit open work rather than filled in by
assumption:

1. complete executable scalar operation/conversion matrix;
2. final SH7 census and freeze of the exact compiler-used Lean subset;
3. completion of the self-host source-closure gate across required modules;
4. full generated `.lean -> .ps -> .lean` parity campaign after the compiler
   can translate itself;
5. stronger formal semantic-preservation evidence for erasure and backend
   transformations;
6. later Rust/Wasm cross-host fixed points.

These open items do not invalidate the language architecture. They define the
remaining evidence needed before stronger freeze/self-host/verification claims.

---

## 41. Source documents consolidated by this reference

This reference was derived from the repository's active evidence, especially:

- `docs/STUDY_REFERENCE_POLICY.md`;
- `docs/PROOFSCRIPT_ARCHITECTURE.md`;
- `docs/plans/00_MASTER_PLAN.md`;
- `docs/plans/02_FRONTEND_AND_THEOREM_PROVER.md`;
- `docs/plans/03_COMPILER_RUNTIME_BACKENDS.md`;
- `docs/plans/05_LANGUAGE_COMPLETION.md`;
- `docs/plans/06_DUAL_SOURCE_LEAN_INTEROP.md`;
- `docs/plans/07_SELF_HOSTING_FOUNDATION.md`;
- `docs/selfhost/PSC1_LEAN_BOOTSTRAP.md`;
- `selfhost/SELFHOSTING.md`;
- `selfhost/ARCHITECTURE_MAP.md`;
- `selfhost/packages/compiler-ir/CONTRACT.md`;
- `study/proofscript-language-reference-v0.7.0/`;
- `study/proofscript-language-reference-v0.6.1/`;
- pinned `study/lean4-4.34.0/` source and the bundled Lean language reference;
- current syntax/elaboration/compiler package implementation and tests.

Where older study prose conflicts with an intentional newer repository decision,
the newer repository decision controls PSC1 scope and the conflict should remain
visible rather than silently rewritten.
