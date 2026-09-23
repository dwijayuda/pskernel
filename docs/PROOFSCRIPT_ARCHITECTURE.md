# ProofScript canonical architecture

Status: **normative anti-drift architecture**.

Reference research for this architecture follows `docs/STUDY_REFERENCE_POLICY.md`.

ProofScript is a small general-purpose language for the JavaScript ecosystem
with Lean-compatible dependent types, theorem proving, and formal
verification. Surface syntax may be smaller and more familiar than Lean, but
semantic acceptance must not bypass Lean-compatible elaboration and pskernel.

## Canonical pipeline

The semantic pipeline may accept more than one bounded source syntax, but source
selection must end before semantic acceptance.

```text
 .ps source          supported .lean source
     |                       |
     v                       v
ProofScript parser      Lean-subset parser
     |                       |
     +----------+------------+
                |
                v
      canonical surface module
                |
                v
          syntax / names
        |
        +---- pinned Lean 4.34 environment
        |     (pskernel-admitted Init.Prelude)
        v
 Lean-compatible elaboration
        |
        v
checked dependent core
        |
     +--+----------------+
     |                   |
 proofs / specs     executable terms
     |                   |
 pskernel           verified erasure
                         |
                         v
                    compiler IR
                     /       \
                    v         v
              TypeScript    Wasm lowering
                    |         |
                    v         v
             tsc -> JS      WasmIR
                              |
                              v
                         Binaryen -> .wasm
```

## Dual-source frontend contract

The first DS1 checkpoint now makes source-kind ownership explicit. Extension
recognition is independent of parser availability: `.ps` resolves to the
registered ProofScript frontend, while `.lean` resolves to the
`lean-subset` source kind but fails closed until the bounded Lean parser is
registered. Merely recognizing a file extension never grants semantic support.


ProofScript supports two intended authored source forms:

- `.ps`: the primary small ProofScript syntax;
- `.lean`: a documented Lean 4 subset whose constructs have an explicit
  ProofScript/checked-core meaning.

Both frontends lower into one canonical surface representation and then share
the same name resolution, Meta/Elab, pskernel admission, checked core, erasure,
compiler IR, TypeScript backend, and JavaScript emission. A supported `.lean`
file must never bypass the ProofScript semantic pipeline by becoming trusted
kernel data.

The supported conversion graph is:

```text
.ps   -> canonical surface -> checked core -> TypeScript -> JavaScript
.lean -> canonical surface -> checked core -> TypeScript -> JavaScript

.ps   -> canonical surface -> canonical Lean-subset source
.lean -> canonical surface -> canonical ProofScript source
```

Source-to-source conversion is semantic, not textual. The first implementation
may normalize formatting, binder spelling, parentheses, and supported syntactic
sugar, and may omit comments until a lossless concrete-syntax layer exists.
Round-trip acceptance is defined by pskernel-admitted declarations and
executable erasure/IR equivalence, not byte-identical source.

The Lean frontend is intentionally fail-closed. Arbitrary Lean syntax
extensions, macros, custom elaborators, commands, tactics, attributes, or
metaprogramming are not implicitly accepted. A construct enters the psc Lean
subset only when its parser ownership, canonical lowering, Lean-compatible
meaning, pskernel gate, source translation behavior, and tooling behavior are
specified.

Mixed-source projects use one source-kind-independent module graph. A `.ps`
module may import a supported `.lean` module and vice versa; imported
declarations enter the same checked environment. Resolution must reject
ambiguous duplicate module sources rather than silently choosing between
`.ps` and `.lean`.

Tooling follows the same rule. The language service records source kind and
dispatches parsing through a frontend registry, after which diagnostics,
kernel status, proof goals, navigation, completion, and hover use the shared
semantic services. The VS Code extension must recognize both source kinds
without unconditionally taking ownership of every `.lean` file from the
official Lean extension; Lean-subset support should be workspace/setting aware
or exposed through an explicit ProofScript Lean-subset language mode.

## Package ownership

- `@proofscript/syntax`: source grammar and source ownership only.
- `@proofscript/environment`: shared pinned Lean 4.34 environment replay used by compiler and tooling.
- `@proofscript/meta` / `@proofscript/elab`: untrusted Lean-compatible
  elaboration.
- `@proofscript/tactic`: untrusted ordered goal-state transitions. It owns no
  proof acceptance; Meta/elaboration adapters construct and assign proof terms.
- `@proofscript/checked-core`: stable boundary containing declarations
  re-admitted by pskernel.
- `lean-ts-kernel`: proof/type acceptance authority and TCB.
- `@proofscript/erasure`: removes type/proof-only content from checked core.
- `@proofscript/compiler-ir`: runtime-oriented executable representation.
- `@proofscript/backend-ts`: verified IR to TypeScript text.
- `@proofscript/wasm-ir`: ProofScript-owned typed WebAssembly-oriented IR.
- `@proofscript/wasm-lowering`: fail-closed verified IR to WasmIR representation lowering.
- `@proofscript/backend-wasm`: Binaryen-backed WasmIR validation/emission; outside the TCB.
- `@proofscript/compiler`: orchestration from checked core to TS/JS or supported Wasm.
- TypeScript Compiler API: TypeScript type-checking/emission to JavaScript,
  declarations, and source maps.

## Non-negotiable invariants

1. The kernel never imports an outer ProofScript package.
2. Checked core cannot be created by trusting parser/compiler metadata; its
   declarations are replayed through pskernel.
3. Erasure consumes checked core, never raw syntax or the legacy software HIR.
4. The verified compiler consumes checked core/verified IR, never source AST.
5. TypeScript/JavaScript and WebAssembly output have no authority over proof acceptance.
6. Erased proof/type values may not survive in executable code. If they do,
   compilation fails closed.
7. Unsupported elaboration/erasure never falls back automatically to the
   legacy software checker.
8. ProofScript conveniences may change syntax, not Lean-compatible meaning
   where dependent types, propositions, inductives, recursion, typeclasses,
   or theorem checking are involved.


## WebAssembly backend checkpoint

WebAssembly is an alternate execution backend after the same pskernel-admitted
checked core and verified erasure used by TypeScript. It is not a second
semantic pipeline:

```text
checked core
    -> verified erasure
    -> verified compiler IR
       |                 |
       v                 v
 TypeScript backend   wasm-lowering
       |                 |
       v                 v
 JavaScript            WasmIR
                         |
                         v
                  Binaryen -> .wasm
```

The W1 executable subset covers Bool/Unit control values and direct first-order
functions. W2 now also carries fixed-width UInt8/16/32/64 values through the
verified runtime IR and Wasm scalar ABI; fixed-width arithmetic/comparisons are
still a separate milestone. Runtime Nat/Int are rejected until an
arbitrary-precision ABI exists; they must never be silently narrowed to i64.
String, external imports, structures, ADTs, generic runtime values, and closures
also fail closed until their representations are specified.

The checked-core/verified-IR external import surface remains an explicit runtime
trust boundary. W1 rejects non-empty verified IR imports with
`PS_WASM_UNSUPPORTED_EXTERNAL_IMPORTS` until a WebAssembly FFI ABI is defined;
it does not reinterpret Lean declaration safety or FFI trust to make emission
succeed.

Binaryen is untrusted compiler infrastructure. Its validator establishes
WebAssembly validity, not equivalence to ProofScript semantics. The
ProofScript-owned WasmIR boundary exists so later differential,
translation-validation, and formal-refinement work can target a stable,
versioned representation.

## Transitional legacy software path

The existing `@proofscript/language` software checker and
`software.ts` compiler-IR lane remain temporarily because they cover more
ordinary programming constructs than the verified-core lane today.

They are **not** the target architecture and must not gain new foundational
semantics that compete with Meta/Elab/pskernel.

Migration policy:

1. add/repair the construct in Lean-compatible syntax/meta/elab;
2. obtain a pskernel-admitted checked-core declaration;
3. implement semantics-preserving erasure/lowering;
4. move backend/runtime coverage to verified IR;
5. only then retire the corresponding legacy software path.

## Current executable proof of architecture

The current vertical regression includes:

```proofscript
function identity {α : Type}(x : α) : α := x;
```

It is:

1. parsed as ProofScript;
2. dependently elaborated;
3. re-admitted into `@proofscript/checked-core` by pskernel;
4. erased so `α` is absent at runtime;
5. lowered to verified compiler IR;
6. emitted as TypeScript equivalent to
   `identity<T0>(x: T0): T0`;
7. compiled by TypeScript to JavaScript `identity(x)`;
8. emitted to `.d.ts` with the generic type preserved.

This is the reference direction for all future language/compiler work.

A dedicated composition regression also locks that the same checked path can
nest ordinary functional constructs rather than supporting them only in
isolation: an outer `let` binds a lambda whose body is a checked Bool `if`,
and the let body performs a verified ADT `match` whose branches call that
local function. The expected verified-IR shape is asserted directly as
`let -> lambda(if) -> match` before TypeScript emission.


## Verified Nat programming checkpoint

The canonical path now also covers composing ordinary checked functions:

```proofscript
function add(x : Nat, y : Nat) : Nat := x + y;

function twice(x : Nat) : Nat :=
  add(x, x);
```

For the current bounded notation milestone, `+`, `-`, `*`, `/`, and `%`
are accepted only at `Nat`. Elaboration produces the real Lean constants
`Nat.add`, `Nat.sub`, `Nat.mul`, `Nat.div`, and `Nat.mod`; erasure then
maps those checked applications to explicit verified-IR intrinsics. Runtime
division/modulo preserve Lean's total Nat semantics: division by zero yields
`0`, while modulo by zero returns the dividend.

The bounded primitive equality surface follows Lean's existing `==`/`!=`
meaning rather than redefining it as propositional equality. Nat operands use
`Nat.beq`; Bool operands use `Bool.beq`; both produce `Bool`. Inequality is
`Bool.not` of the corresponding checked equality, matching Lean 4.34's
`bne` definition. Generic `BEq` synthesis is intentionally not claimed.

The same verified Bool lane now covers `!x`, `x && y`, and `x || y` through
the actual Lean constants `Bool.not`, `Bool.and`, and `Bool.or`. Any
supported expression already checked to have type `Bool` may be used as an
`if` condition. The frontend reflects that Bool to the proposition
`Eq Bool condition true` with `Bool.decEq`; proposition-native Nat ordering
conditions continue through `LE.le`/`LT.lt` with their Nat instances and
checked deciders. Only after pskernel admission does erasure lower these
checked forms to boolean verified-IR conditions.

This is intentionally narrower than pretending to have Lean's general
`HAdd`/typeclass notation or generic `BEq` synthesis already. General
overloaded notation must wait for the real typeclass-synthesis layer.


Verified runtime intrinsics have one shared compiler-IR contract for operation
identity and arity. Validation consumes that contract, and backend-ts emits the
operation union exhaustively. There is no catch-all emission fallback: adding a
new verified intrinsic without defining its backend semantics is a TypeScript
compile-time error rather than silently changing meaning.


## Verified execution checkpoint

The CLI runtime path now consumes the semantic types retained in verified IR.
For primitive entrypoints, the complete developer flow is executable:

```proofscript
function main(x : Nat) : Nat :=
  x + x;
```

```text
psc run --verified -- 21
source
-> shared Lean 4.34 Init.Prelude environment
-> elaboration
-> pskernel checked core
-> verified erasure/IR
-> TypeScript
-> tsc JavaScript
-> verified runtime ABI (Nat)
-> main(21n)
-> 42
```

The verified CLI ABI supports primitive `Nat`, `Int`, `Bool`, `String`,
and `Unit` values plus kernel-derived structure/ADT types whose runtime fields
are representable by the verified IR. Structured values cross the CLI boundary
as strict JSON: nested Nat/Int values are decimal strings, structures are exact
field objects, and ADTs use `{"$ctor":"constructor", ...fields}`. ADT inputs
are reconstructed through the generated constructor exports so verified match
tags are genuine; results are encoded from the runtime representation back to
the same JSON-safe shape.

This boundary is untrusted input handling, not proof evidence. The accepted
shape is derived from pskernel-admitted verified IR. Function-typed values,
unknown types, unresolved type parameters, malformed constructors/fields, and
unsupported dependent runtime shapes remain fail-closed.


## Verified structure checkpoint

The preferred pipeline now also covers simple nominal structures:

```proofscript
structure User where { age : Nat; }

function make(age : Nat) : User :=
  { age := age : User };

function get(user : User) : Nat :=
  user.age;
```

The structure is first admitted as a pskernel inductive. Checked-core structure
metadata is accepted only after validation against the generated constructor.
Erasure then lowers constructor applications to branded runtime records and
kernel projections to field access. TypeScript receives a readonly nominally
branded interface.

Dependent/existential structures such as `{ T : Type; value : T }` remain
fail-closed in verified compilation until their runtime existential packaging
semantics are designed; they are not flattened into unsound structural types.


## Verified ADT constructor checkpoint

The preferred pipeline now covers simple unparameterized, non-recursive
algebraic data types and constructor values:

```proofscript
inductive MaybeNat where {
  | none;
  | some(value : Nat);
}

const noneValue : MaybeNat := MaybeNat.none;
const oneValue : MaybeNat := MaybeNat.some(1);
```

The inductive and constructors are admitted by pskernel first. Erasure derives
runtime constructor shape from pskernel `ConstructorInfo`, then verified IR
represents the ADT as a nominal tagged union. TypeScript emits an internal
unique-symbol tag plus a constructor object; JavaScript therefore preserves
constructor identity without trusting source-only ADT metadata.

Parameterized, indexed, recursive inductives and pattern matching remain
separate milestones and fail closed until their Lean-compatible core semantics
are implemented.


## Local class-instance checkpoint

ProofScript class declarations now follow Lean's kernel boundary:

```proofscript
class Boxed(α : Type) where {
  value : α;
}

function reuse {α : Type}[inst : Boxed(α)](x : α) : α :=
  x;

function caller {α : Type}[inst : Boxed(α)](x : α) : α :=
  reuse(x);
```

`Boxed` is admitted by pskernel as the same single-constructor inductive shape
used for structures. "Class" is elaborator metadata only; it does not extend
the kernel's type theory.

The first instance-synthesis slice began local-only. The current bounded
layer searches local `instImplicit` binders first and then registered global
instance definitions. When the requested class target still contains
metavariables, synthesis is postponed until later explicit arguments/result
constraints have had a chance to solve them; only then is the instance goal
retried. This prevents declaration order from prematurely fixing an otherwise
unresolved type parameter.

The resulting checked core contains the ordinary dictionary argument, so
verified erasure/backend compilation needs no typeclass-specific escape hatch.
Priorities, parameterized-instance application, recursive/table-based search,
`outParam`/`semiOutParam`, ambiguity diagnostics, and imported Lean instance
indexes remain future Meta milestones.


## Global instance checkpoint

The bounded typeclass layer now also supports definition-like global
instances:

```proofscript
class Boxed(α : Type) where {
  value : α;
}

instance boxedNat : Boxed(Nat) :=
  { value := 7 : Boxed(Nat) };

function get {α : Type}[inst : Boxed(α)](x : α) : α :=
  inst.value;

function read(x : Nat) : Nat :=
  get(x);
```

The instance is first elaborated and admitted as an ordinary pskernel
definition. Checked-core records only validated instance-registry metadata
whose final result head is a previously admitted class. Later application
elaboration may select that constant as an instance candidate. The resulting
core term contains the ordinary dictionary argument, and verified erasure
therefore lowers `read` to an ordinary runtime call equivalent to
`get(boxedNat, x)`.

Instance lookup remains intentionally smaller than Lean 4.34 `SynthInstance`:
it is non-recursive and has no priorities, parameterized-instance application,
out-parameters, ambiguity diagnostics, or imported/prelude instance index.
A regression with competing `Boxed(Nat)` and `Boxed(Boxed(Nat))` instances
locks the rule that an unresolved `Boxed(?α)` goal is postponed until a later
explicit argument fixes `?α`.

The theorem-prover slice also includes bounded single-premise `apply`.
`by apply f; next` requires the elaborated candidate to expose one explicit
Pi/function premise. The continuation constructs that premise proof; applying
it to the candidate must then be definitionally equal to the original goal.
The produced term is an ordinary application rechecked by pskernel. Candidates
requiring multiple generated goals or unresolved implicit-instance search fail
closed until the tactic state supports those cases.

## Dependent theorem/result surface checkpoint

Declaration header elaboration now distinguishes a **type-position term** from
the final requirement that a declaration type inhabit a sort. Nested named
applications are elaborated with the same application/implicit-argument logic
used elsewhere, so Lean-compatible propositions such as
`Eq (Nat.succ a) a` can be stated without treating `Nat.succ a` as though it
were itself a type.

This does not make arbitrary runtime expressions valid types. After dependent
arguments are elaborated, the complete parameter/result/annotation term is
still checked by pskernel to inhabit a `Sort`.

ProofScript source should use Lean-compatible `Eq a b` when spelling the
constant directly; the carrier type is implicit. Native infix propositional
`=` remains the preferred eventual surface and is still pending in the v0.6.1
header grammar.

## Propositional equality surface checkpoint

The verified v0.6.1 header grammar now owns native non-associative
propositional `=` in type/proposition position. It is not a separate
ProofScript equality relation: the elaborator constructs the real polymorphic
Lean `Eq` application and lets the shared Meta/application layer infer the
implicit carrier type.

Precedence is intentionally Lean-like for the supported slice:

```text
application  >  =  >  ->
```

Thus `Nat.succ(a) = a -> P` parses as
`(Nat.succ(a) = a) -> P`. Chained equality requires parentheses.

Boolean `==` remains a distinct runtime/BEq operation. No backend or parser
shortcut equates `=` with `==`.

## Theorem-position Nat term checkpoint

The dependent header surface now reuses the ordinary Nat notation semantics for
numeric literals and `+ - * / %`. Parsing uses the same operator precedence
table as ordinary expressions, while header elaboration delegates Nat operation
construction/checking to the same Nat notation module.

This is deliberately not a generic operator overloading system. The supported
header arithmetic is the existing verified Nat subset only. Lean-style
typeclass-driven arithmetic notation remains fail-closed until the shared Meta
layer owns it.

To keep that sharing maintainable, notation elaboration is split into focused
modules:

```text
v061-notation-support
     ├── v061-nat-notation-elab
     ├── v061-bool-notation-elab
     └── v061-notation-elab       (small dispatcher/reflection)
```

The split restores the repository source-shape invariant without exemptions and
keeps theorem-header and executable Nat arithmetic on one semantic path.

## Nat relation theorem-surface checkpoint

The theorem/result grammar now admits the verified Nat relation subset
`< <= > >=`. These are propositions, not Boolean comparisons. The elaborator
reuses the same `LE.le` / `LT.lt` construction and Nat instances used by
ordinary relation expressions. Reverse spellings `>` and `>=` preserve the
existing operand-swap semantics.

Decidability remains separate: theorem statements do not require
`Nat.decLt`/`Nat.decLe`; executable conditional elaboration adds those
deciders only when execution needs them.

This keeps the distinction intact:

```text
x <= y      : Prop
x == y      : Bool
x = y       : Prop
```

No theorem-only comparison relation has been introduced.

## Bool-valued theorem-term checkpoint

The theorem/result surface now admits the already-verified Bool term subset:
Bool literals, unary `!`, `&&`, `||`, and bounded primitive `==`/`!=`
for Nat and Bool. These constructs reuse the same term constructors and kernel
checks as executable expressions.

This does **not** turn Bool into Prop. For example:

```text
x == y             : Bool
(x == y) = true    : Prop
x = y              : Prop
```

The final declaration header remains required to inhabit a `Sort`, so a bare
Bool-valued expression is rejected as a theorem result.

Canonical Lean lowering also accounts for a source-precedence difference.
ProofScript keeps its existing expression precedence where `==` binds tighter
than the outer propositional `=`. Lean 4.34 declares both `=` and `==` at
precedence 50, so lowering inserts parentheses such as:

```text
x == y = true
  -> (x == y) = true
```

The type/proposition parser and Lean lowering are now separate modules, keeping
parser growth below the repository source-shape ceiling.

## Explicit dependent Pi checkpoint

The verified type/proposition surface now supports the reference-backed form:

```text
(x : T) -> U
```

The binder is elaborated as an ordinary Lean-style dependent function:
`T` is checked as a type, a fresh local `x : T` is introduced while
elaborating `U`, and the resulting codomain is abstracted into kernel
`forallE`.

This is not a second function-type representation. Non-dependent `A -> B`
continues to use the same kernel constructor with an anonymous binder.

The first accepted source slice is explicit/default binding only. Implicit
`{x : T}`, strict implicit `{{x : T}}`, and instance `[x : T]` Pi syntax
remain unsupported until a concrete ProofScript library requires them.

## Bounded exact-search checkpoint

ProofScript now has a first deterministic `exact?` slice. It is an untrusted
search procedure, not a proof authority.

Candidate order is deterministic:

1. local hypotheses, newest first;
2. already-admitted environment constants, newest first.

The environment phase considers only declarations with zero universe
parameters and stops after 4096 candidates. A candidate is only accepted when
its already-checkable type is definitionally equal to the goal. The selected
term is then submitted through the ordinary `exact` transition and pskernel
checker.

This intentionally omits Lean's broader library-search machinery:
discrimination-tree indexing, symmetry search, `Iff.mp`/`Iff.mpr`
variants, applying lemmas with premises, `solveByElim` subgoal discharge,
polymorphic level instantiation, `using`, configuration, `+all`, and
`+grind`.

A failed candidate probe is side-effect-free. Once a candidate matches, any
failure during actual assignment or parent-proof reconstruction propagates;
the search loop does not swallow it.

## Canonical ProofScript printer checkpoint

The DS1 frontend abstraction now includes both parsing and canonical printing:

```text
.ps text
  -> proofscript frontend.parse
  -> canonical V061 surface module
  -> proofscript frontend.print
  -> canonical .ps text
```

The printer is an untrusted source canonicalizer. It does not elaborate,
type-check, admit declarations, erase proofs, or influence pskernel.

Canonicalization is intentionally stronger than formatting preservation:
declaration semicolons, grouped explicit parameters, D-call/type-call spelling,
braced E-forms, and the currently implemented flat tactic sequence are
normalized. Comments and original whitespace are not preserved at this stage.

The executable syntax gate is canonical idempotence:

```text
print(parse(print(parse(source)))) == print(parse(source))
```

for representative declarations and expressions across the complete current
parser AST.

Canonical Lean lowering remains a target printer, not a registered Lean source
frontend. A `lean-subset` frontend will be registered only when DS2 can parse
the emitted supported Lean subset back into the same canonical surface module.

## Translation-target dispatch checkpoint

DS1 now separates **input frontend selection** from **output language
selection**.

```text
input filename
   -> SourceFrontendRegistry
   -> canonical V061 surface module
   -> TranslationTargetPrinterRegistry
        ├── ps   -> canonical ProofScript
        └── lean -> canonical supported Lean
```

The target registry uses user-facing translation targets `ps|lean`; it is not
keyed by source frontend ownership. This matters because canonical Lean output
already exists while Lean input parsing does not.

`psc emit-lean` is the first CLI integration of this split. It selects the
source frontend from the input path, parses once into the canonical surface,
then independently requests the Lean target printer. A `.lean` input still
fails with `PS_FRONTEND_UNAVAILABLE` until DS2 registers a bounded Lean
parser.

This completes DS1 without changing elaboration, checked-core semantics, proof
authority, erasure, or backend behavior.

## DS2.1 Lean value frontend checkpoint

The syntax package now contains a **separate** bounded Lean-subset frontend for
canonical value declarations. It is not implemented by feeding Lean text to the
ProofScript declaration parser.

Current accepted DS2.1 source shapes include:

```text
def name (x : T) ... : R := term
theorem name (x : T) ... : P := by ...
```

with the already-owned dependent type/proposition syntax, named whitespace
application, literals/operators, `fun`, `let`, Lean `if ... then ... else`,
synthetic holes, and the current tactic subset.

The parser lowers directly to the same v0.6.1 AST used by ProofScript. No proof,
type, erasure, or runtime semantics are source-kind specific after that point.

The `lean-subset` frontend remains **unregistered by default**. This is an
intentional phase boundary: parser existence in DS2 must not silently turn into
CLI acceptance from DS3.

Unsupported Lean commands/terms produce `PS_LEAN_SUBSET_*` diagnostics rather
than falling through to the ProofScript parser or approximating full Lean.

## DS2.2 Lean declaration frontend checkpoint

The bounded Lean-subset frontend now reads the canonical declaration families
that the current ProofScript Lean target already emits:

```text
structure
class
instance
inductive
```

and canonical structure/instance record values. These inputs produce the same
existing v0.6.1 AST nodes as ProofScript input; there is no Lean-specific
elaboration or proof path after parsing.

Lean field layout required one explicit parsing boundary. Canonical
structure/class fields are line-separated, while the shared type grammar uses
whitespace for application. The type parser therefore exposes an opt-in
`stopAtLineBreak` mode used by the Lean declaration frontend only. Default
ProofScript parsing behavior is unchanged.

The accepted declaration subset is intentionally narrower than full Lean 4.34:
class/inductive binder shapes are limited to forms that can also be printed
back into the current ProofScript grammar, explicit constructor result types are
rejected, and namespaces/attributes/deriving/extends/custom commands remain
outside the subset.

The default source frontend registry still does not register `lean-subset`.
Canonical `match` and `where` forms emitted by ProofScript remain the final
DS2 parser gaps before DS3 can expose `.lean` through normal CLI source
selection.

## DS2 emitted-subset closure

The bounded Lean frontend now parses every source form currently emitted by the
canonical Lean target printer for the supported v0.6.1 surface. This includes
declarations, records, match expressions, where declarations, and the landed
tactic subset.

The DS2 closure gate is source-semantic, not textual preservation:

```text
ProofScript source
  -> canonical V061 AST
  -> canonical Lean
  -> Lean-subset parser
  -> canonical V061 AST
  -> canonical Lean / canonical ProofScript
```

The canonical outputs must be stable/equivalent for the supported subset.
Comments, original formatting, and unsupported Lean extensions are not part of
the contract.

Even after DS2 closure, `lean-subset` remains absent from the default frontend
registry. Enabling `.lean` for normal `psc check/build/run` is a separate DS3
product decision and must still route into the identical elaboration, pskernel,
checked-core, erasure, and backend pipeline.

## DS3.1 dual-source compiler input checkpoint

Normal source selection now recognizes both `.ps` and the documented bounded `.lean` subset through the same `SourceFrontendRegistry`.

The boundary is intentionally narrow:

```text
filename extension
  -> source frontend
  -> shared V061 surface AST
  -> existing semantic pipeline selection
```

The source kind does not select a type system, proof checker, erasure strategy, or backend. In verified mode both source forms pass through the identical Meta/Elab, pskernel, checked-core, erasure, IR, and TypeScript/JavaScript path.

Build manifests/reports expose `sourceKind`, and output stems strip the actual input extension. Canonical translation command UX and canonical-source hashes remain DS3 follow-up work.

## DS3.2 canonical source translation checkpoint

`psc translate <file> --to ps|lean` now exposes the already-separated source frontend and translation target registries as a direct user workflow.

```text
input path
  -> source frontend selected by extension
  -> canonical V061 surface module
  -> requested target printer (ps | lean)
  -> canonical source text
```

The command is intentionally not a proof/check command. `--verified`, JSON reporting, and runtime passthrough are rejected rather than implying that translation changes semantic trust.

`emit-lean` remains as a convenience alias-style workflow for canonical Lean output. The remaining DS3 product gate is manifest canonical-source hashing.

## DS3/DS4 dual-source identity and semantic-equivalence checkpoint

Source kind now ends at the shared surface boundary. The CLI computes a
source-kind-neutral `canonicalSourceHash` by printing that shared surface in
canonical ProofScript form and hashing the UTF-8 bytes with SHA-256.

```text
.ps ----\
        -> shared surface -> canonical ProofScript -> SHA-256
.lean --/
```

This identity is reported by check/build manifests and is equal for canonical
supported sources with the same shared surface meaning.

DS4 adds a stronger executable equivalence gate. For a representative supported
corpus, ProofScript, canonical Lean, and Lean->ProofScript round-trip sources
must produce identical pskernel checked-core admissions and identical verified
compiler IR. Because backend input is identical, the gate also requires
identical TypeScript, JavaScript, and declaration output.

Unsupported Lean remains fail-closed before checked core. The equivalence gate
therefore proves two bounded frontends converge; it does not broaden the
documented Lean subset.

## DS5 mixed-source verified-project checkpoint

The first mixed-source module implementation keeps source ownership outside the
TCB:

```text
entry .ps/.lean
  -> parse import headers
  -> logical module resolver
  -> deterministic project DAG
  -> per-module shared frontend parse
  -> dependency-only pskernel environment
  -> module checked-core admissions
  -> deterministic combined checked core
  -> erasure -> verified IR -> TypeScript -> JavaScript
```

A module is elaborated against the transitive closure of the modules it
actually imports, not against a global mutable environment containing unrelated
siblings. Dependency visibility is therefore explicit in the project graph.

For the bounded MVP, logical `Foo.Bar` resolves relative to the entry
directory to exactly one of `Foo/Bar.ps` or `Foo/Bar.lean`. Ambiguous dual
sources, missing modules, and cycles fail before semantic compilation.

The bundled checked core is created by replaying every local admission in
topological order through pskernel. The source language of a module never
changes the proof/type authority.

Current limitation: same-file elaboration keeps untrusted metadata indexes for
structures, classes, and global instances. Those indexes are not yet
reconstructed from imported checked-core admissions, so DS5 does not yet claim
cross-module record/projection or typeclass-synthesis parity. Ordinary imported
definitions/theorems are the supported semantic slice.

The legacy software checker does not gain an import implementation. Imports
require the verified project pipeline and otherwise fail closed.

## DS5 imported semantic metadata checkpoint

A mixed-source project module is elaborated against two products of its
transitive dependency closure:

1. the pskernel-replayed dependency environment; and
2. the validated checked-core metadata for structures, classes, and instances.

The second product is an **elaboration seed**, not proof authority. Structure
and class descriptors have already been checked against pskernel-generated
constructors by checked core, and instance declarations have already passed
checked-core class-target validation.

Imported global instances are presented newest-admission-first, matching the
existing same-file rule where each newly declared instance is prepended to the
candidate list.

This closes the semantic difference between same-file and imported usage for
the current structure/class/global-instance subset while keeping module-local
admissions separate for future artifact caching.

## DS5 checked-module cache and integrity checkpoint

The mixed-project pipeline now has an untrusted in-process module cache. A cache
entry contains only the module's previously pskernel-admitted **local
admissions**. Cache hits do not return a trusted environment: after resolving
all modules, the complete ordered admission stream is replayed through checked
core and pskernel as before.

Module cache/integrity keys are SHA-256 hashes over canonical JSON containing:

- cache schema;
- pinned Lean/kernel compatibility descriptor;
- logical module name;
- source-kind-neutral canonical source hash;
- sorted direct dependency module/integrity pairs.

Because each dependency integrity already includes its own dependencies,
invalidation is transitive. Project integrity hashes the entry module plus the
deterministic topo-ordered module/integrity list.

This checkpoint intentionally does **not** emit persistent `.psmodule`
artifacts. The current module artifact v1 payload is Lean4Export 3.1.0 NDJSON,
and ProofScript has no serializer from checked-core admissions back into that
transport. Inventing one ad hoc would violate the artifact trust model. A
persistent cache must first land a real replayable payload codec or a formally
versioned new artifact payload.

## DS5 configured source-root checkpoint

Logical module resolution now accepts project-relative `sourceRoots` in
`psconfig.json`.

Rules:

- empty/unset `sourceRoots` preserves the previous behavior: imports resolve
  below the entry file's directory;
- configured roots are resolved relative to `psconfig.json`;
- every logical module path is searched under every configured root for both
  `.ps` and `.lean`;
- exactly one candidate is required;
- more than one candidate is an ambiguity error, even when candidates live in
  different roots or use different source kinds;
- no root has implicit priority.

This keeps resolution deterministic and makes mixed-source projects portable
without coupling source-kind choice to import precedence.

## DS6 source-kind-aware editor checkpoint

Editor parsing now follows the same frontend boundary as the compiler.

```text
LSP document
    |
    +-- sourceKind=proofscript --> ProofScript frontend --+
    |                                                    |
    +-- sourceKind=lean-subset --> Lean subset frontend -+
                                                         |
                                                         v
                                                   shared V061 AST
                                                         |
                                                         v
                                              shared elab -> pskernel
```

The LSP source-kind mapping is transport metadata only; it does not create a
second checker. Document edits preserve their initially selected source kind.

VS Code deliberately avoids an unconditional `.lean` extension association.
It exposes a `proofscript-lean` manual mode and an opt-in
`proofscript.leanSubset.enable` provider path. The extension may attach
ProofScript features to an existing Lean-owned document only when explicitly
enabled in the ProofScript workspace.

This checkpoint remains document-local. DS5 project/import semantics must be
composed into the language service before cross-file/cross-language navigation
can claim semantic project awareness.

## JavaScript/npm FFI foundation

The verified compiler IR now has an explicit external-import surface:

```text
checked executable meaning
        |
        v
 verified IR
   imports: [
     { localName, source, importedName, type }
   ]
        |
        v
 TypeScript named ESM import
```

This layer is intentionally **runtime-only metadata**. An IR import does not
create a pskernel theorem, definition, or proof witness. The TypeScript backend
may emit it only because an earlier trusted semantic boundary has supplied a
typed runtime dependency contract.

The next frontend/checked-core FFI checkpoint must preserve three distinct
facts:

1. the source signature that ProofScript typechecks against;
2. the runtime binding (npm/ESM source + exported symbol);
3. the trust/assumption status exposed to users and assurance tooling.

JavaScript execution must never be used to discharge a theorem. If an external signature is represented in the kernel environment to typecheck
executable uses, its separate checked-core runtime-external metadata must be
reported as an assumption and proof-producing result types must fail closed in
the first FFI profile.

The initial backend form is named ESM import only. Default imports, namespace
imports, CommonJS, dynamic import, side-effect imports, and package-resolution
policy remain later explicit extensions.

## Replayable runtime-external admission checkpoint

The FFI boundary now exists above verified IR as a checked-core admission:

```text
external signature
   -> typed pskernel axiom
   +  { source, importedName } runtime binding
   -> checked-admission codec v2
   -> proofscript-module@2 payload 1.1.0
   -> replay through pskernel
   -> erasure
   -> typed verified IR ESM import
```

The runtime binding and the logical constant are deliberately distinct. The
kernel admits only the declared type of the external as an opaque axiom; it
never executes JavaScript to validate or discharge a proof. The first profile
requires at least one explicit argument and primitive runtime argument/result
types, so proof-valued and polymorphic extern signatures fail before admission.

This permits verified code to call an opaque external function while proofs can
use only its declared type, never facts learned from host execution. Assurance
tooling must still report the external assumption separately from ordinary
definitions/theorems and from other project axioms.

Nominal, higher-order, proof-valued, polymorphic, or unknown external runtime
types remain fail-closed until their ABI and assurance story are specified.

Checked-admission persistence is versioned compatibly: codec v1 / payload
1.0.0 remains readable; new external admissions require codec v2 / payload
1.1.0. Artifact verification enforces that coupling.

## Explicit source FFI and assurance checkpoint

The first source-level JavaScript/npm FFI declaration is now an intentional
post-v0.7 repository extension:

```proofscript
extern function hostInc(x : Nat) : Nat
  from "host-lib"
  import inc;
```

It records four separate facts: the ProofScript-local name, the checked logical
signature, the ESM package/module source, and the named runtime export.

The frontend does not trust this declaration directly. Its signature is
elaborated through the ordinary declaration-header path, represented as a
non-`unsafe` opaque axiom, paired with explicit runtime-binding metadata, and
validated by the existing checked-core external invariant before admission.
That invariant remains stricter than the source grammar: the first profile
requires one or more explicit primitive runtime arguments and a primitive
runtime result, rejecting proof-valued, polymorphic, nominal, and higher-order
extern signatures.

The two output views are deliberately different:

- internal logical Lean lowering may render the signature as an `axiom`, so
  verified checking/building can expose the logical assumption;
- canonical ProofScript printing preserves the full ESM binding;
- source translation to canonical Lean rejects extern-bearing modules because
  a Lean source file cannot preserve the runtime binding metadata.

Verified CLI reports now include a separate assurance record with:

- pskernel-checked definition count;
- pskernel-checked theorem count;
- runtime-external assumption count;
- each external's local name, module source, imported symbol, and logical
  signature;
- `proofEvidence=false` for every runtime external.

Thus `proofStatus: kernel-verified` continues to describe the proof checking
performed on internal theorems; it is not a claim that JavaScript/npm runtime
bindings were proven correct. The next FFI checkpoint is deterministic package
dependency policy and a real resolvable runtime-binding test.

## Exact runtime dependency policy checkpoint

Project-level FFI resolution is now explicit in `psconfig.json`:

```json
{
  "runtimeDependencies": {
    "host-lib": "1.0.0"
  }
}
```

This first profile accepts npm package **roots** with exact versions only.
Verified `check` requires every admitted external source to be present in that
map. Verified `build` and `run` additionally require
`node_modules/<package>/package.json` to report the same package name and
exact version before generated TypeScript is compiled.

Runtime dependency identity is deliberately separate from semantic project
identity:

```text
projectIntegrity
  = source/dependency/kernel semantic identity

runtimeDependencyPolicy.integrity
  = exact direct host-package policy identity
```

Changing a host package version therefore changes the build/assurance policy
fingerprint without pretending theorem meaning changed or that pskernel proved
the package implementation.

Verified build now compiles its in-memory TypeScript under the absolute
`dist/<entry>.ts` path. TypeScript module resolution therefore starts from the
same project/output tree that the emitted JavaScript will execute from. A
no-network regression installs a temporary ESM package with matching `.d.ts`,
executes a ProofScript `String -> String` external through Node, and verifies
the host result while retaining `proofEvidence=false` in assurance.

Still unsupported in this checkpoint:

- semver ranges;
- package subpath imports;
- `node:` builtins;
- default/namespace/CommonJS/dynamic imports;
- package installation;
- transitive lockfile integrity claims.

Those require separate project/runtime policy decisions and do not expand the
kernel trust boundary.
