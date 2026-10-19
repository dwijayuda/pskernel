# PSC1 Practical Core — v7.2 subset

Status: adopted implementation target; initial source inventory, not completed conformance.
Updated 2026-10-20. Scope: the retained PSC1 subset plus exactly the fourteen
approved feature families below. All other unimplemented v7.2 features are deferred.

## 1. Authority, provenance, and the separate toolchain migration

This standalone PSC1 selection adopts PSCV0 Language Reference v7.2, revision
2026-10-16, from upstream commit
`33676076bcda7b0de5ec1f9803f49b8b1d28a058`, path
`psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md`, Git blob
`694115223777599ba28ee175e14bb642b7b6aa4b`.
The upstream document and all historical PSC1 qualification records remain unchanged.

- Normative semantic target: Lean **4.35.0**, commit
  `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
- Last qualified PSC1 implementation at adoption: Lean **4.34.0**,
  implementation `f933691a1d6fa578c59623636afbb02119909837`,
  Linux [run 39332460452](https://github.com/dwijayuda/pskernel/actions/runs/39332460452).
- Repaired continuation parent: `a2778be648850a1f6a2381e28babcd4a6e783e31`;
  PR #162 remains a separate repair PR.
- A 4.34.0 build is a transitional checkpoint. Editing version strings does not
  qualify a 4.35.0 migration. Compiler, independent provider, native launcher,
  environment and provenance identities must agree, and the focused repaired
  suite must execute on the new pin before the migration is marked qualified.

[Exact governing reference](https://github.com/dwijayuda/pskernel/blob/33676076bcda7b0de5ec1f9803f49b8b1d28a058/psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md)
and [pinned Lean source](https://github.com/leanprover/lean4/tree/eb6cafb7290e8bd5f2937522d8d804f58f02bafc)
provide normative detail. This file defines PSC1's bounded selection; references to
Standard features elsewhere are not permission to enable them.

## 2. Capability and evidence vocabulary

The machine-readable status is `docs/PSC1_PRACTICAL_CORE_STATUS.json`.
A feature has separate specified, parsed, elaborated, independently checked, and
named-target execution states. A selected feature can be specified while missing
implementation. A fixture present in source is not an executed test.

The current admission authority is the **independent official Lean kernel**.
The corrected owned PSKernel-Core is integrated source with separate native
regressions. It is not the current direct provider. Neither fact proves semantic
preservation of generated JS, TS, Rust or Wasm.

Public DirectJS/TS signatures retain the admitted scalar boundary. Aggregate data
can be internal where the checked target supports it. Rust retains its checked
generic IR. Component Wasm remains **Bool-only at its public boundary**.
Core Wasm and component Wasm keep their existing ABI/memory policies. New source
syntax cannot bypass target capability validation.

## 3. Retained PSC1 forms and surface alignment

The repaired input pipeline captures source/import bytes and syntax once, resolves
a dependency-ordered closure, elaborates the bounded common AST, independently
admits that exact Core graph, erases it, and validates the typed IR and target plan.
Retained functionality includes named definitions/theorems, explicit and supported
implicit binders, lambdas/Pi, literals, immutable lets, Bool conditionals, bounded
inductive/structure construction and matching, structural recursion, named
collection operations, imports, and existing checked primitive operations.
Exact limitations remain those enforced by the current source and target checks.

`.lean` uses native Lean spelling for this implemented subset. Its extension does
not enable arbitrary Lean commands. `.ps` follows the actual v7.2 surface selection:
comma-grouped adjacent calls `f(a, b)`, native curried application where selected,
and a diagnostic for a gap before parenthesized call arguments. Do not infer a
blanket prohibition of all spaced application from older project notes.

The v7.2 `function f()` form inserts exactly one required Unit argument.
A one-required-Unit function can be invoked by `f()` or `f(())`; extra required
arguments are not invented. Empty calls are not yet implemented in the initial
PSC1 inventory. One-term braced bodies, declaration spelling and nullary alignment
must be qualified as surface changes, not described as already complete.

No compatibility mode for obsolete language references is introduced. Existing
forms are retained only where compatible with the governing selection; concrete
alignment gaps remain visible in the status record.

## 4. Fixed operators and ordinary inference (P0/P1)

### 4.1 Selected operator table

| Spelling | Associativity / binding | Selected domains and meaning |
| --- | --- | --- |
| `+`, binary `-` | left, 65 | Nat/Int exact addition/subtraction; Nat subtraction saturates |
| `*`, `/`, `%` | left, 70 | Nat exact multiplication/division/modulus; Int multiplication; Int division/modulus deferred until individually admitted |
| unary `-` | prefix, 75 | Int negation |
| `=` | nonassociative, 50 | propositional Eq over admitted operands |
| `==`, `!=` | nonassociative, 50 | typed Boolean equality/inequality for each explicitly qualified scalar domain |
| `<`, `<=`, `≤`, `>`, `>=`, `≥` | nonassociative, 50 | Nat/Int propositions with a checked decision path where used as a condition |
| `&&` | left, 35 | Bool short-circuit conjunction |
| `||` | left, 30 | Bool short-circuit disjunction |
| prefix `!` | operand binding 40 | Bool negation |
| `×` | right, 35 | product type, supporting the approved tuple family |
| `→`, `->` | right, 25 | retained function/Pi type syntax |

This bounded table selects from v7.2 section 8. Other notation, shifts, power and
extensible operators are deferred unless already part of the repaired subset.
Calls/projections bind more tightly. Unparenthesized comparison chains reject.
`a == b` has type Bool; `a = b` and `a < b` have type Prop.
The compiler must not relabel `Nat.blt` as a proposition. Bool conditions use the
existing typed branch path; proposition conditions require their actual checked
decision evidence. No JS truthiness or dynamic numeric coercion is admitted.

Arithmetic lowers through existing typed operations and checked IR intrinsics.
Nat/Int remain unbounded values across qualified targets. Division/modulo-zero and
negative Int cases must follow the selected pinned Lean definitions. Boolean
combinations evaluate the left operand once and evaluate the right only when
required; generated target evaluation must preserve that order.

Positive sketches: `a + b * 2`, `(a + b) * 2`, `a == b && flag`.
Negative sketches: `1 + true`, `a < b < c`, using `a = b` as Bool.
The status matrix records which domains and operators actually execute.

### 4.2 Local inference and call inference

`let x := 10` infers Nat under ordinary unconstrained literal rules.
An explicit `let x : Int := 10` keeps Int. Omitted local types are solved from
actual constraints; annotations remain usable.

Call-site implicit type arguments are inferred from supplied arguments and the
expected result. Context must reach arguments early enough that a literal is not
prematurely fixed to Nat in `id(1)` expected to return Int. Dependent result
constraints must use fresh scoped metavariables, the existing unifier and its
occurs/scope checks; no unrelated coercion/default mechanism is introduced.

Positive: polymorphic identity from a Nat argument; the same identity expected as
Int; a nullary constructor inferred from an annotated result; explicit annotations.
Negative: unsolved type parameters, incompatible argument/result types, escaping
locals, or an unconstrained empty collection. No any/unknown, unchecked cast, or
arbitrary solution of an unresolved type is permitted. Final declaration closure
must contain no holes or unresolved expression/universe metavariables.

## 5. One typed procedural family (P0)

The approved family comprises do, local computations and monadic binds, local
mutation, return, for, while, and partial runtime recursion. Shared lowering must
preserve their interactions. Internal control tags and joins are permitted;
additional public control constructs are not.

### 5.1 Do, binds and return

PS spelling is `do { ... }` with newline-separated items, including
`let x := value`, `let x ← action`, `pure(value)`, and `return value`.
Native Lean uses its selected layout spelling. Literal semicolons are not general
PS statement separators. A block has a concrete effect/result type; supported
Id/typed-error/state machinery must be independently admitted with its closure.

Each statement is typed and sequenced in source order. A bind evaluates its action
once, then scopes the result over the following sequence. Local let values and
effect actions are distinct. Expected result information flows to branch results.

Early return follows the exact selected Lean 4.35.0 do elaboration: its target is
the enclosing procedural computation, with nested do, lambda, loop and handler
boundaries established by that elaborator's return context. Implementations must
qualify each boundary against the pinned oracle before claiming it. A lambda has
its own computation; a return cannot accidentally leave an enclosing caller.
Loops/handlers propagate the selected return outcome without interpreting it as a
typed error or ordinary loop value. These are acceptance obligations, not a claim
that PSC1 already implements early exit.

Positive sketches: bind then return; typed local computations; early return in an
if nested inside a loop; a nested lambda returning without exiting its caller.
Negative: bind in a non-computation, inconsistent branch result types, escaping
branch binder, return outside an admitted procedural computation.

### 5.2 Lexical mutation

PS/native selected spelling: `let mut x [: T] := value`, then `x := next`.
The initializer determines one fixed local type. Assignment checks against that
type and updates the selected lexical binding only. Branch/loop joins carry the
updated value; a local introduced in a branch does not leak. Captured values obey
Lean value/scoping semantics. No global mutable cell or shared mutable alias is
created as an implementation shortcut.

Lower through typed values, checked state/continuation operations and joins.
An array update uses persistent value semantics or justified exclusive reuse:
updating one binding cannot mutate an aliased earlier value.
Positive: a Nat accumulator updated through nested loops.
Negative: assign Bool to a Nat local; assign to an immutable/unknown local; leak a
loop-local variable; observe accidental host-array alias mutation.

### 5.3 For and finite ranges

PS: `for x in collection { ... }`; native: `for x in collection do ...`.
Admitted iterables are List, Array and finite ranges. Native range notation is
selected only after its exact pinned grammar is checked. Bounds are lower
inclusive and upper exclusive; the bounded first form uses unit positive step.
Iteration is left-to-right, zero times for an empty collection/range. The iterable
is evaluated once before iteration. Nested scopes and loop-carried locals retain
their types. Returns/effects propagate according to the shared do lowering.

Lower through checked finite recursors/folds and internal control outcomes, not a
hidden execution limit. Arbitrary iterators, break and continue are deferred.
Positive: empty/singleton lists, nested arrays, equal range bounds.
Negative: noniterable values, escaped iterator binder and type-changing mutation.

### 5.4 While

PS: `while (condition) { ... }`; native selected layout uses `while ... do ...`.
The condition is re-evaluated before every iteration. False initially means no
body execution. State updates feed the next condition. An unrestricted loop can
diverge and must use a separately classified ordinary partial/effectful runtime
path. A total logical definition requires an actual admitted total lowering;
termination failure never silently changes a definition to partial.

No compiler/kernel fuel is runtime semantics. No implicit iteration cap pretends
to implement while. Divergence observation uses an external process timeout only.
Verified total or divergent behavior requires the exact evidence demanded by v7.2;
unsupported proof modes must report unavailable, not success.

## 6. Partial definitions and assurance (P0)

Selected syntax is `partial def` with the corresponding admitted PS declaration
surface. Useful terminating and deliberately nonterminating bodies are required
for completion; parsing followed by universal rejection is only partial support.

The logical declaration is opaque and must satisfy pinned Lean's genuine-function
and codomain inhabitation/nonemptiness rules. Its runtime body is separately typed
in a recursive environment and linked to the exact admitted declaration and source
snapshot. Its recursive equation is not a kernel axiom. Logical reduction must not
execute the body or use a fabricated runtime default.

- Ordinary checked execution: an explicitly selected checked artifact with exact
  source/runtime identity, typed executable closure, and disclosed partial/effect
  dependencies. This is not behavior certification.
- Verified execution: all requested body-refinement, dependency, termination or
  divergence, effects, erasure and target obligations must be discharged. An
  unavailable proof path refuses the requested artifact before publication.
  Failed verification cannot downgrade to ordinary output.

At adoption the CLI has a checked-direct identity and no working end-to-end
verified mode. That identity must not be retroactively described as verification.
Minimal explicit assurance selection/metadata will be added before enabling
ordinary partial/effect bodies. Source axioms, holes, unresolved metas, new
assumption allowlists, unsafe escapes and unchecked casts remain rejected across
the full transitive closure, including generated helpers.

Required positive cases: ordinary terminating partial calls and deep recursion.
Required negative cases: missing inhabitant, nonfunction partial value, proof by
unfolding a partial body, imported unapproved assumption, unavailable verified
request, and divergent execution stopped only by an external test timeout.
A timeout reports an observation, not a mathematical proof of divergence.

## 7. Products, arrays and basic namespaces (P1)

### 7.1 Tuple expressions and patterns

`(a, b)` and larger tuples lower to right-associated Prod values.
`(a)` is grouping, `()` is Unit, `f(a, b)` supplies two call arguments, and
`f((a, b))` supplies one product. PS permits a trailing comma only with at least
two tuple elements. `(a,)` rejects. Type spelling is `A × B` or the admitted
named Prod application. Expected product field types guide literal inference.

Destructuring `let (x, y) := value` evaluates value once and binds the statically
checked product components in the following scope. Nested patterns check shape.
Use existing product constructor/recursor/projection semantics; internal tuples do
not become public exports.
Positive: nested tuples, annotated Int fields, tuple argument versus argument list.
Negative: wrong tuple arity/shape, one-element tuple, escaping pattern binder.

### 7.2 Arrays and safe indexing

Array syntax is `#[a, b]`; `[a, b]` is List, never a JS-style array alias.
Elements share one inferred or annotated type and evaluate in order. Typed empty
arrays are accepted; an unresolved empty-array element type rejects.
Length is Nat. Initial construction lowers through existing checked Array
empty/push/size primitives, with exact source-to-runtime closure retained.

The minimum selected safe indexing surface is `xs[i]?`, returning Option of the
element type for a Nat index. At or past length it returns none. Proof-bearing
`xs[i]` and `xs[i]'h` require actual checked validity evidence; until that path
exists, they reject explicitly rather than becoming getD, optional or panic
access. `xs[i]!` is not selected for this Practical Core increment.
Named existing getD/setIfInBounds operations retain their explicit default/bounds
behavior. New indexing/assignment support must preserve array value semantics.

Positive: typed empty and nonempty arrays, ordered iteration, zero/last/past-end
optional lookup, aliased values preserved after an update.
Negative: mixed element types, negative/non-Nat index, unresolved empty type,
unsupported proof-bearing/panic form without its required semantics.

### 7.3 Namespaces

Both inputs select `namespace N ... end N`, including nested scopes.
Namespace identity qualifies declarations; it is separate from the source module
that owns/exported them. Locals shadow names normally. Current then enclosing
namespace lookup and exact qualified lookup are deterministic; true ambiguity and
duplicate fully qualified declarations reject. End names must match the opened
scope, and unterminated scopes reject.

Core symbol identity and collision-aware target names remain authoritative.
Imported namespace helpers stay private under entry-module export policy.
No unrestricted open/section/macros or package-system overhaul is included.
Positive: nested namespace sibling call; imported qualified reference; local shadow.
Negative: duplicate qualified definition; wrong end; unresolved/ambiguous name.

## 8. Typed errors and bounded IO (P1)

### 8.1 Typed errors

Selected PS forms are `throw error` and
`try { ... } catch error => { ... }` inside typed do, with native Lean spelling in
.lean. The admitted computation determines the error type. Except-based handling
has no ambient target exception semantics. Only errors in the selected typed error
channel are handled; target traps, assertions, exhausted compiler resources and
external execution timeouts are not ordinary caught values.

The state/error ordering is explicit per admitted effect instance. Existing
CompilerM is a pure library whose catch restarts from the original state; this
does not specify all future state/error combinations. Any admitted combination
must document and test whether preceding state changes survive an error.
Return propagation through try/loops must use its own control outcome.
Finally and additional handlers are deferred.

Positive: typed throw caught by a matching handler; uncaught error propagation;
state/error ordering; return in a handler.
Negative: error of wrong type; handler without the required effect; swallowing a
target trap or verification refusal as an ordinary source error.

### 8.2 Small typed host IO

Select console line input/output and bounded UTF-8 text-file read/write through
explicit host capabilities. The concrete small API is to be qualified before it
is advertised in the matrix; no ambient IO is enabled at adoption.
The adapter contract must state EOF, newline, path resolution/capability roots,
text/size limits and each translated host error. Deterministic temporary fixtures
exercise sequencing, permitted reads/writes and denied/failed operations.

IO stays outside kernel reduction, type inference and proof evaluation. Thin
JS/TS/Rust/Wasm host adapters implement one disclosed typed contract; they do not
contain a second compiler. Missing host binding or unsupported target must refuse
before publication. No network, shell, subprocess, dynamic evaluation, general FFI,
pointers or arbitrary host API is admitted. Component aggregate/IO ABI is not
implied by source-level IO.

## 9. Initial source inventory and execution contract

| Approved family | Baseline state | Exact primary PSC1 evidence |
| --- | --- | --- |
| Basic infix operators | Missing precedence/operator elaboration; named primitives exist | syntax/ParseLean.lean, syntax/ParseProofScript.lean; environment/Prelude.lean; erasure/Expr.lean |
| Local inference | Implemented for lets; focused target qualification pending | elab/Term.lean: psElabLet; test/BootstrapTests.lean: psTestDualSourceInferredLet |
| Proper do | Partial legacy native CompilerM sugar; PS rejects | syntax/ParseLean.lean: psParseLeanDoWithFuel; ParseCommon.lean: psSyntaxCompilerPure/Bind; ParseProofScript.lean |
| For | Missing | syntax/Ast.lean and both parsers |
| While | Missing | syntax/Ast.lean and both parsers |
| Mutation/assignment | Missing | syntax/Ast.lean and both parsers |
| Return | Partial terminal native do sugar only | syntax/ParseLean.lean: psParseLeanDoWithFuel |
| Partial def | Parsed/elaborated; blocked before direct admission | core/Declaration.lean; bridge/CheckedAdmissions.lean: psEncodeCheckedAdmissionsLoop |
| Tuples/patterns | Product machinery exists; tuple syntax missing | environment/SelfHostProd.lean; both parsers |
| Arrays/indexing | Typed named primitives exist; literals/indexing missing | environment/Prelude.lean; erasure/Expr.lean |
| Typed errors | Pure Result/Except/CompilerM library; selected syntax missing | stdlib/ProofScript/Data/Result.lean; Compiler/Effect.lean |
| Call inference | Partial; expected result applied after arguments | elab/Term.lean: psElabApplyArgsWithFuelWorker, psElabFinishApplication |
| Namespaces | Dotted references only; scopes missing | environment/Resolve.lean; elab/Context.lean; both parsers |
| Typed IO | Missing source/runtime host contract | host/DirectBackend.lean; compiler-ir/Model.lean |

Package shorthand above means `packages/<package>/src/Ps/<Module>/...`.
The JSON matrix contains full paths. The baseline repair CI is historical evidence
only; each changed implementation needs its own exact commit and cloud run.

All qualification uses focused GitHub Linux jobs: existing scoped native/kernel
regressions and real source-to-Node/isolated-TS/Cargo/Wasm execution as applicable.
Test interactions and negative publication preservation. No full compiler/kernel
self-host generation, source-wide self-host census or bootstrap fixed-point tests.
No package publication, release, merge, force push, kernel fuel increase or
unapproved assumption is authorized by this reference.
