# The ProofScript Language Reference v0.9.0 r3 Candidate

Status: research candidate; not a released compiler or replacement for v0.9-r2.
Grammar identity: ps-0.9-r3-research.
Semantic pin: Lean 4.34.0, commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b.

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

r3 defines two .ps profiles over the same logic.

### ps-standard

For applications, packages, AI-generated code, stable formatting/LSP, and reproducible builds.

It has a closed/versioned syntax environment and does not import arbitrary parser/macro/elaborator mutation from ordinary dependencies.

### ps-lean-extensible

For theorem proving, custom notation/macros/tactics/elaborators, Lean compatibility, and metaprogramming.

Every extension identity/order/options set is part of the environment identity.

A Standard package can consume semantic/runtime exports from an Extensible package without importing its syntax/meta exports.

## 4. Definitions

def remains the general native declaration.

function is an alias for a parameterized native definition.

const is provisionally retained as a top-level/namespace parameterless native-definition alias. It is not local const, object freezing, or compile-time evaluation. This decision is gated on human usability results before 1.0.

No ProofScript-wide declaration semicolon is introduced.

## 5. Zero-argument function sugar

r3 permits:

~~~proofscript
function now(): Time :=
  ...
~~~

with canonical meaning equivalent to:

~~~lean
def now (_ : Unit) : Time :=
  ...
~~~

The invocation:

~~~proofscript
now()
~~~

remains a Unit application.

This is surface sugar, not a zero-arity core function concept.

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

The call parser may admit ordinary whitespace/comments and a legal expression-continuation newline between a completed callable head and its opening parenthesis.

It must not delete trivia and reparse text blindly. The active enclosing grammar category controls whether a newline can continue the expression.

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

Nested application groups remain distinct.

Generalized field notation is delegated to compatible Lean elaboration; the frontend does not hard-code receiver position.

Patterns remain native and do not acquire constructor-call syntax.

## 8. Structural braces

When an r3-owned construct uses braces, the braces and category-specific separators/markers determine the outer member sequence.

Indentation inside that owned outer sequence is formatting rather than a hidden second member-boundary mechanism.

Nested inherited syntax can still use its own native layout.

Canonical Standard presentation:

~~~proofscript
structure User where {
  name: String,
  active: Bool,
}

class Sized(α: Type) where {
  size: α -> Nat,
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

- structure/class fields: comma separator, optional trailing comma;
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

The candidate does not add TypeScript arrow lambdas.

Definitional equality, propositional equality, and Boolean comparison remain distinct.

## 11. Stable PSC-owned contracts

requires, ensures, assert, invariant, and termination/specification metadata have PSC-owned semantics.

For a total pure function:

~~~proofscript
function withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result = balance - amount
:=
  balance - amount
~~~

the accepted evidence must establish the approved property of the actual implementation declaration.

The stable semantic layer is expressed through ordinary checkable theorems/program logic.

Lean intrinsic verification may be an oracle or implementation path but is not the sole semantic definition.

Specification identity includes referenced predicates/types, imports, program-logic version, environment, and axiom policy.

## 12. Assurance states

Tools distinguish parsing, elaboration, kernel admission, contract proof, termination proof, erasure preservation, target preservation, runtime validation, tests, and external assumptions.

Malformed, unsupported, incompatible, failed, exhausted, cancelled, and internal-error states do not become accepted output.

## 13. Application model

r3 standardizes an application-library model around the concepts:

~~~text
App error result
Exit error result
Fiber error result
Resource error value
Stream error item
Capability capabilityId
~~~

These are ordinary library/runtime concepts, not new kernel primitives.

Execution distinguishes success, typed failure, cancellation, and unexpected runtime failure.

Capabilities are explicit.

Resource cleanup is deterministic and not defined by garbage collection.

Child fibers are structured/scoped by default; detach is explicit.

Promise, AbortController, AsyncIterable, WASI future/stream, and other target mechanisms are adapters rather than source semantics.

Convenience async/resource syntax is deferred until the library model and usability evidence justify it.

## 14. npm and .d.ts

A versioned InterfaceIR sits between TypeScript declaration interpretation and native PSC APIs.

Bindings separate:

1. raw foreign interface;
2. safe runtime adapter/codec;
3. optional logical specification/model.

Unsupported TypeScript machinery fails closed rather than becoming any.

Presence can distinguish missing, undefined, null, and value.

Identity-bearing objects become foreign handles.

Promise/callback/receiver/resource semantics are explicit.

Generated PSC npm packages may contain ESM JS, .d.ts, source maps, validators, assurance metadata, and proof bundles.

A .d.ts file is not runtime validation or proof.

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

r3 deliberately does not claim a production proof in this documentation-only workstream.

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

Existing r2 D-CALL remains an r3 call.

Structural braces receive the category separator required by r3.

r2 intrinsic contracts are not silently relabelled stable PSC contracts.

Profile selection is explicit.

## 18. Usability gate

The syntax is not frozen until the human study in 13-USABILITY-STUDY.md is run.

High-risk questions include call whitespace, tuple grouping, braces/layout, const, zero-argument Unit sugar, Option versus undefined/null, typed errors, and contract meaning.

Current participant count is zero; no superiority claim is made.

## 19. Full-application gate

ProofScript should not claim r3 full-app readiness until the CLI, HTTP service, browser UI, and published npm library reference applications build and execute through supported PSC toolchains, with the verified state-machine application demonstrating a useful admitted contract.

Those applications are not yet completed on this research branch. However, bounded layer evidence exists: a hand-authored npm ESM + d.ts package passes pack/install/strict-TypeScript-consumer/runtime tests; a restricted InterfaceIR shape prototype passes its fixture and rejects a conditional-type example; and a small Resource/race trace model passes its Node tests. None is PSC-generated end-to-end application evidence.

## 20. Open status

This candidate is a coherent integration of the research decisions, not a language release.

Remaining blockers include production parser/lowerer implementation, Standard profile closure, contract implementation, App runtime, InterfaceIR importer/exporter, real reference applications, production-refinement proofs, real JS/Wasm preservation, and human usability results.
