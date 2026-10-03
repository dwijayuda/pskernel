# The ProofScript Language Reference v0.9.0 r3

Status: **accepted r3 language/design baseline; documentation/specification scope; not an implementation release or proof of soundness.**
Grammar identity: `ps-0.9-r3`.
Semantic pin: Lean 4.34.0, commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b.

## 0. Completeness, inheritance, and authority

r3 is a **complete delta specification** over one immutable r2 baseline:

~~~text
baseline/ProofScript_Language_Reference_v0.9.0_r2.md
SHA-256 d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d
~~~

Everything in that r2 reference remains normative unless explicitly amended/overridden by r3.

The exact section-by-section authority map is `R3-R2-INHERITANCE-MATRIX.md`. The precedence rules are in `R3-AUTHORITY-AND-DELTA.md`.

This restores, without approximate re-transcription, all unchanged r2 rules for primitives, exact Nat/Int behavior, strings/bytes, modules/source identity, recursion/partiality/unsafe behavior, theorem/axiom policy, compiler phases, transactional admission, source maps, erasure, primitive matrices, preservation, artifact binding, resource limits, diagnostics and evidence manifests.

Normative r3 companions are:

~~~text
R3-GRAMMAR-AND-FEATURE-REGISTRY.md
FEATURE-REGISTRY-r3.json
PS-STANDARD-REGISTRY-r3.json
SEMANTIC-BUNDLE-v1.md
SEMANTIC-BUNDLE-v1.schema.json
INTERFACEIR-v1.md
INTERFACEIR-v1.schema.json
~~~

Design acceptance remains distinct from implementation/proof/testing evidence.

## 1. Design commitment

ProofScript remains a general-purpose programming and theorem-proving language whose logical meaning is defined through Lean-compatible elaboration and kernel admission.

r3 changes the application-facing surface and platform profile, not the logical foundation.

The design goal is:

> make ProofScript predictable and comfortable for TypeScript developers while preserving Lean semantics and ProofScript theorem-proving and verification strengths.

The base continues to reject JavaScript truthiness, implicit null/undefined, native any, prototype inheritance as object semantics, unchecked casts, and silent proof/runtime authority.

## 2. Source kinds

### .lean

Native Lean syntax only. ProofScript surface productions are not injected into the Lean parser.

### .ps

ProofScript surface plus inherited Lean categories according to the selected profile.

### Optional extension source

Any .psx or other dialect requires an explicit grammar/profile and does not automatically inherit base verification claims.

## 3. Source profiles

r3 defines two `.ps` profiles over the same logic.

### ps-standard

The exact Standard registry is `PS-STANDARD-REGISTRY-r3.json` with registry identity `ps-standard-0.9-r3`.

Its parser is a closed/versioned snapshot. Ordinary package imports do not mutate parser, notation, macro, tactic-elaborator or command/term elaborator tables.

The registry enumerates the accepted r3 surface features, native command heads, term families, tactic heads, allowed attributes, and forbidden dynamic syntax mechanisms.

### ps-lean-extensible

For theorem proving, custom notation/macros/tactics/elaborators, Lean compatibility, and metaprogramming.

Every extension identity/order/options set is part of the environment identity.

### Crossing profiles

A Standard package consumes an Extensible library's checked semantic exports through `PSC Semantic Bundle v1`.

A Standard-importable bundle must have no syntax/meta exports and must pass schema, dependency, payload-hash and genuine checker import/recheck validation.

The exact protocol is `SEMANTIC-BUNDLE-v1.md` / `SEMANTIC-BUNDLE-v1.schema.json`.

## 4. Definitions

def remains the general native declaration.

function is an alias for a parameterized native definition.

const is retained in r3 as a top-level/namespace parameterless native-definition alias. It is not local const, object freezing, or compile-time evaluation. The spelling remains eligible for reconsideration before stable/1.0 if usability evidence demonstrates harmful false familiarity.

No ProofScript-wide declaration semicolon is introduced.

## 5. Zero-argument function sugar and empty invocation

r3 permits:

~~~proofscript
function now(): Time :=
  ...
~~~

with canonical declaration meaning equivalent to:

~~~lean
def now (_ : Unit) : Time :=
  ...
~~~

However `f()` is more general than textual `f ()`: it is a **complete empty source-level invocation**.

The empty-call elaborator:
1. inserts implicit and instance arguments normally;
2. inserts omitted optional/default and automatic arguments;
3. if the next still-required explicit parameter is definitionally `Unit`, synthesizes exactly one `()`;
4. continues inserting trailing implicit/default/automatic arguments;
5. rejects if any required non-Unit explicit parameter remains;
6. never eta-abstracts a missing required parameter for an empty call.

Examples:

~~~proofscript
function now(): Time := ...
now()                         -- Unit sugar

function greet(name: String := "world"): String := ...
greet()                       -- uses default

function add(x: Nat): Nat := x + 1
add()                         -- reject

function staged(_: Unit, x: Nat): Nat := x
staged()                      -- reject
staged(())                    -- explicit Unit; ordinary partial-application rules may apply
~~~

`f(())` remains an ordinary nonempty call with an explicit Unit term.

## 6. Parenthesized calls

r3 deliberately breaks the r2 whitespace-sensitive D-CALL rule in .ps.

These have the same r3 meaning:

~~~proofscript
f(x)
f (x)
~~~

and:

~~~proofscript
f(x, y)
f (x, y)
~~~

Both multi-argument forms mean curried application.

One tuple argument requires explicit extra grouping:

~~~proofscript
f((x, y))
~~~

The call gap permits spaces/tabs and Lean comments containing no physical line terminator.

A physical line terminator between the completed callable head and `(` breaks r3 parenthesized-call ownership. A block comment containing a newline also breaks the gap.

Multiline argument lists remain valid after the opening parenthesis.

Thus `f (x)` is the same r3 call as `f(x)`, but:

~~~proofscript
f
(x)
~~~

is not one r3 parenthesized call.

The canonical formatter prints:

~~~proofscript
f(x)
f(x, y)
f((x, y))
~~~

This is an E-class surface exception because it intentionally reinterprets a valid Lean neighbor inside .ps.

Native .lean behavior is unchanged.

## 7. Call lowering

A parenthesized call produces one native application syntax object with ordered positional/named arguments so native elaboration retains implicit/default/named argument behavior and expected-type information.

Conceptually:

~~~text
Call(h, [])       -> native h ()
Call(h, [a])      -> native h a
Call(h, [a,b])    -> native h a b
Named(n,e)        -> native named argument (n := e)
~~~

A trailing comma remains allowed in a nonempty owned call or explicit parameter group. This convenience does **not** extend to structure/class field lists; field commas are separators only.

Nested application groups remain distinct.

Generalized field notation is delegated to compatible Lean elaboration; the frontend does not hard-code receiver position.

r3 does **not** make the dot whitespace-insensitive:

~~~proofscript
users.map(render)    -- field notation + r3 call
users .map(render)   -- not added by r3
~~~

Patterns remain native and do not acquire constructor-call syntax.

## 8. Structural braces

When an r3-owned construct uses braces, the braces and category-specific separators/markers determine the outer member sequence.

Indentation inside that owned outer sequence is formatting rather than a hidden second member-boundary mechanism.

Nested inherited syntax can still use its own native layout.

Canonical Standard presentation:

~~~proofscript
structure User where {
  name: String,
  active: Bool
}

class Sized(α: Type) where {
  size: α -> Nat
}

inductive State(α: Type) where {
  | idle
  | ready(value: α)
}

match value with {
  | .none => fallback
  | .some x => x
}
~~~

Outer sequence rules:

- structure/class fields: commas separate fields; a trailing field comma is not part of the accepted r3 form;
- inductive constructors: leading bar marker;
- match alternatives: leading bar marker;
- instance initializer fields: native semicolon separator in brace mode;
- local where declarations: native semicolon separator in brace mode;
- conditional branch: one term;
- native do/tactic constructs: retain their own native sequencing/combinators.

There is no universal JavaScript statement block and no ASI.

## 9. Native layout remains available

Inherited Lean layout remains valid where the selected profile allows it.

The Standard formatter chooses the structural r3 form for owned constructs and native layout for inherited categories.

The formatter cannot change AST ownership by inserting/removing punctuation heuristically.

## 10. Lambdas, patterns and equality

r3 retains:

~~~proofscript
fun x => ...
match x with ...
:=
=
==
Prop
Type
theorem
by
where
~~~

where those spellings communicate important Lean concepts.

r3 does not add TypeScript arrow lambdas.

Definitional equality, propositional equality, and Boolean comparison remain distinct.

## 11. Stable PSC-owned contracts

The normative base-r3 contract surface is deliberately narrow:

~~~text
requires P
ensures result => Q
~~~

for **total pure functions**.

For preconditions `P₁..Pₙ` and postconditions `Q₁..Qₘ`, the final accepted evidence establishes the conjunction of postconditions for the **actual admitted implementation** under the conjunction of preconditions.

Zero `requires` means `True`. Zero `ensures` means no contract theorem is requested.

### Frame/effect semantics

Every contract has a semantic `FrameSpec` containing read capabilities/locations, write/modified locations, and foreign effects. A total pure r3 contract has an empty frame.

Future stateful/application contract profiles must make their frame/effect relation explicit; a postcondition about the returned value never grants arbitrary unrelated mutation.

### Higher-order contracts

r3 accepts the ordinary logical model:

~~~text
CallableSpec args result
callRequires(f, args) : Prop
callEnsures(f, args, result) : Prop
~~~

These are ordinary definitions/predicates, not kernel primitives. Higher-order verification must prove the connection between a function value and these predicates.

### Staged contract features

Surface `assert`, loop `invariant`, state `modifies`, old-state notation, async trace clauses and termination-specific convenience syntax are **not part of the frozen base-r3 contract grammar**. They require later versioned program-logic profiles.

Lean intrinsic verification may remain an oracle/implementation path but is not the semantic definition of PSC contracts.

Specification identity includes implementation identity, normalized contract AST, frame/effect data, referenced predicates/types, imports, program-logic version, environment and axiom policy.

## 12. Assurance states

Tools distinguish parsing, elaboration, kernel admission, contract proof, termination proof, erasure preservation, target preservation, runtime validation, tests, and external assumptions.

Malformed, unsupported, incompatible, failed, exhausted, cancelled, and internal-error states do not become accepted output.

## 13. Application model

The accepted r3 Standard application semantics is conceptually:

~~~text
App (caps : CapabilitySet) (err : Type) (result : Type)

Exit err result
  | success result
  | failure err
  | cancelled CancelReason

Fiber err result
RuntimeFault
Resource caps err value
Stream caps err item
~~~

### Cold App / started Fiber

`App` is **cold**. Constructing, copying or reusing an App value does not start external work.

Work starts only through explicit execution/start operations such as `run` or `fork`.

`Fiber` denotes started work. `join` observes terminal `Exit`; `cancel` requests cancellation and is not itself terminal completion.

### Structured concurrency

A lexical task scope owns child fibers unless detach explicitly transfers ownership. Scope completion requests cancellation of unfinished children, waits for terminal outcome/cleanup under the semantic resource policy, and does not silently leak children.

### Typed failure and RuntimeFault

`failure err` is ordinary recoverable application failure.

Unexpected host/runtime faults are represented separately as `RuntimeFault` and are not caught by ordinary typed-error handlers unless an explicit adapter translates them.

### Resource cleanup

After successful acquisition, release is attempted exactly once on success, typed failure and cancellation.

Once release starts, ordinary cooperative cancellation is **shielded** until release terminates. Body failure plus cleanup failure must preserve both causes rather than silently discard one.

### Capabilities

Capabilities are visible in `App caps err result` through a canonical type-level `CapabilitySet`. Package/runtime manifests aggregate reachable capability requirements.

### Native IO/Task

Lean `IO`/`Task` remain the low-level native substrate.

Portable `ps-standard` application APIs expose App/Fiber/Resource/Stream. Direct native IO/Task is reserved for explicitly nonportable/native-adapter modules (or the Extensible profile) and carries explicit capability/assumption metadata.

JavaScript Promise and WASI 0.3 `async func`/`future<T>`/`stream<T>` are target adapters, not the source definition of PSC async.

## 14. npm and .d.ts

The normative boundary format is `InterfaceIR v1`:

~~~text
INTERFACEIR-v1.md
INTERFACEIR-v1.schema.json
schemaVersion = proofscript-interface-ir-1.0.0
~~~

Its resolution identity binds TypeScript version/module-resolution mode, custom and ordered effective conditions, package name/version, package.json SHA-256, export subpath, selected runtime entry/format, selected type entry, declaration-file hashes and target runtime/platform.

Bindings separate raw foreign shape, safe runtime adapter/codec, and optional logical specification/model.

Every imported construct is classified as native, specialized, runtime-adapter, opaque-handle, import-normalization, or unsupported.

Unsupported TypeScript machinery fails closed rather than becoming native `any`.

Presence can distinguish missing, undefined, null and value. Identity-bearing objects become foreign handles. Promise/callback/receiver/resource behavior is explicit.

A `.d.ts` file is not runtime validation or proof.

## 15. Targets and preservation

The architectural pipeline remains:

~~~text
.ps
 -> surface AST
 -> canonical Lean-compatible syntax
 -> elaboration
 -> kernel admission
 -> checked declarations
 -> justified erasure/RuntimeIR
 -> target lowering
 -> JS/Wasm/optional artifacts
~~~

Owning a backend does not prove it. Using an external compiler does not invalidate a source theorem. Every relevant transformation has a theorem, validator, test status, or explicit assumption.

## 16. Planned first formal evidence

The r3 design is now specification-complete enough to define its first proof targets, but it deliberately does not claim those proofs have been completed.

The proposed first frontend theorem should formalize a small parenthesized-call model and establish ownership/lowering properties before relating that model to the production parser.

The proposed first backend theorem should formalize a very small pure RuntimeIR fragment, a target AST/semantics, and a value-preservation relation, followed later by an exact serializer/artifact connection.

See 11-FORMAL-OVERLAY-PROOF.md and 12-BACKEND-PRESERVATION-SLICE.md.

These are proof plans, not completed production proofs.

## 17. Migration from r2

Migration parses r2 first.

The major breaking rule is:

~~~text
r2 native f (x, y)  -> r3 f((x, y))
~~~

when the r2 AST establishes tuple intent.

A nonempty r2 D-CALL remains an r3 call.

An empty r2 D-CALL `f()` meant explicit Unit application, so the mechanical semantics-preserving migration is:

~~~text
r2 f()  -> r3 f(())
~~~

The new r3 `f()` empty-invocation/default semantics is not retroactively assigned to r2 source.

Structural braces receive the category separator required by r3.

r2 intrinsic contracts are not silently relabelled stable PSC contracts.

Profile selection is explicit.

## 18. Pre-stable usability evidence

The r3 design is accepted now. Stable/1.0 surface freeze remains contingent on the human study in `13-USABILITY-STUDY.md`, especially for high-risk false-familiarity decisions.

High-risk questions include call whitespace, tuple grouping, braces/layout, const, zero-argument Unit sugar, Option versus undefined/null, typed errors, and contract meaning.

Current participant count is zero; no superiority claim is made.

## 19. Full-application gate

ProofScript should not claim r3 full-app readiness until the CLI, HTTP service, browser UI, and published npm library reference applications build and execute through supported PSC toolchains, with the verified state-machine application demonstrating a useful admitted contract.

Those applications are not yet completed on this documentation branch. No end-to-end r3 application evidence is claimed here.

## 20. Status and remaining evidence work

The r3 **specification-completion pass is complete** for the ten identified design gaps.

The language remains a documentation/specification baseline, not an implementation release.

Remaining work is evidence/implementation rather than an unresolved base-language design dependency:
- production parser/lowerer and Standard registry implementation;
- contract checker/VC implementation;
- App/Fiber/Resource/Stream library/runtime implementation;
- InterfaceIR importer/exporter;
- real reference applications;
- formal overlay/refinement/preservation proofs;
- JS/Wasm preservation;
- TypeScript/Lean human usability study before stable/1.0 freeze.

Any new syntax or semantic change discovered during implementation/evidence work requires an explicit r3 amendment or later revision; it is not silently inferred.
