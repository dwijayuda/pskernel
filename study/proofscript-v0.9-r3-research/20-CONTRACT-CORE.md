# r3 Normative Contract Core

Status: **normative semantic core for `ps-0.9-r3`**

Contract semantic version:

~~~text
psc-contract-core-v1
~~~

## 1. Scope

r3 deliberately narrows the **stable source contract core** to semantics that can be stated precisely now.

Normative source clauses in the base r3 contract core:

~~~text
requires
ensures
~~~

for total functions/definitions whose logical implementation is an ordinary admitted declaration.

The following words/concepts remain reserved or library/program-logic work until a later profile defines complete syntax/semantics:

~~~text
assert
invariant
decreasing
old
modifies/writes clause syntax
async contract sugar
loop-specific contract sugar
~~~

The absence of stable sugar does not prevent ordinary theorem proofs about those concepts.

## 2. Pure total contract semantics

For:

~~~proofscript
function f(x: A): B
  requires Pre(x)
  ensures result => Post(x, result)
:=
  implementation
~~~

the required final logical evidence is equivalent to:

~~~text
forall x,
  Pre(x) ->
  Post(x, f(x))
~~~

where `f` is the actual accepted implementation declaration under the exact selected environment.

Multiple `requires` clauses conjoin in source order.

Multiple ordinary result `ensures` clauses conjoin in source order.

A contract with no `requires` has precondition `True`.

A contract with no `ensures` makes no additional postcondition claim and MUST NOT be reported as functionally verified merely because the implementation is typed/admitted.

## 3. Exact contract identity

A normalized `ContractSpec` contains:

~~~text
implementationIdentity
sourceContractIdentity
requiresPredicate
ensuresRelation
terminationClass
effectFrame
readFrame
writeFrame
semanticDependencyClosure
axiomPolicy
programLogicVersion
environmentIdentity
~~~

Changing any semantic field changes the specification identity.

The identity includes referenced predicate/type/theorem definitions, not only the clause text.

## 4. Implementation binding

Contract evidence is valid only for the exact implementation identity it names.

A VC generator may create proof obligations, helper lemmas, solver queries, or certificates.

The accepted endpoint must establish the normalized contract theorem for the actual declaration.

A proof of:

~~~text
True
~~~

or of a similar but different implementation does not authorize the contract.

## 5. Caller obligations

For a verified call to `f(args)`, the caller must establish the normalized `requires` predicate unless the API uses a separate runtime-validating wrapper.

A precondition is not a JavaScript runtime check.

Public FFI/npm wrappers for untrusted callers must either:

- validate a decidable runtime condition and return an explicit failure; or
- document the boundary as restricted/trusted.

A `.d.ts` signature does not discharge a ProofScript precondition.

## 6. Result relation

`ensures result => P` binds `result` to the ordinary logical result of the function.

For sum/error result types such as `Except E A`, r3 core can express outcome-sensitive properties using an ordinary match inside the single result relation:

~~~proofscript
function parse(input: String): Except ParseError User
  ensures result =>
    match result with {
      | .ok user => User.valid(user)
      | .error err => ParseError.describes(input, err)
    }
:=
  ...
~~~

Dedicated `ensures .ok ...` / `ensures .error ...` sugar is **not** normative in core v1.

This keeps the stable grammar small while preserving full logical expressiveness.

## 7. Termination class

Core-v1 source contracts apply to total logical functions unless a named program-logic profile states otherwise.

The evidence report distinguishes:

~~~text
partial-correctness
termination
total-correctness
trace-safety
~~~

A proof of a postcondition conditioned on termination is not a termination proof.

## 8. Frame and effect semantics

Even though core-v1 does not add `reads`, `writes`, or `uses` keywords, the normalized contract carries frame/effect fields.

### 8.1 Effect frame

`effectFrame` is a finite normalized set of capability-operation identities that the implementation may emit in the selected program-logic trace.

For a pure total function:

~~~text
effectFrame = {}
~~~

For an `App Caps E A` computation, the type-level capability set is an upper bound:

~~~text
effectFrame ⊆ Caps
~~~

A contract may narrow that frame but may not silently expand the capabilities allowed by the type/profile.

### 8.2 Read frame

`readFrame` identifies abstract mutable regions/foreign resources whose state may influence the result/trace.

Pure immutable values are not heap regions merely because they are represented as objects on a target runtime.

### 8.3 Write frame

`writeFrame` identifies abstract mutable regions/foreign resources that the computation may modify.

An implementation that writes outside its allowed frame violates the contract even if its final return value satisfies the postcondition.

This prevents a function from being called "correct" while mutating unrelated state.

### 8.4 Frame identities

Frame identities belong to the program-logic/platform model, not raw target pointers.

Examples may include:

~~~text
State.inventory
FileHandle#logical-id
Database.transaction-region
DomHandle#logical-id
~~~

The exact region algebra is versioned by the selected program-logic profile.

## 9. Relationship to capabilities

Capability permission and frame permission are separate:

- a capability says which class of operation can be invoked;
- a frame says which modeled region/resource can be read/written;
- a postcondition says which logical relation must hold.

Example:

~~~text
Capability: FileSystem.write
Write frame: File("/config/app.json")
Postcondition: encoded bytes correspond to approved Config value
~~~

Having the filesystem capability alone does not permit arbitrary writes under that contract.

## 10. Higher-order callable contracts

ProofScript is higher-order, so a function value needs a specification interface.

Core v1 defines a logical `CallableSpec` relation conceptually:

~~~text
callRequires(f, args) : Prop
callEnsures(f, args, outcome) : Prop
callEffects(f, args) : EffectFrame
callReads(f, args) : ReadFrame
callWrites(f, args) : WriteFrame
~~~

For a named function with a declared contract, the compiler/specification layer establishes ordinary checked lemmas connecting the declaration to these generic relations.

A higher-order function may require properties of its callable argument, for example conceptually:

~~~text
requires callRequires(callback, (x,))
requires forall result,
  callEnsures(callback, (x,), result) -> ResultProperty(result)
~~~

The exact user-facing convenience syntax for higher-order contract constraints can remain ordinary theorem predicates in r3; no extra arrow-contract language is introduced.

This design follows the general higher-order-contract need without making an external verifier's built-ins part of PSC's kernel.

## 11. Function values without declared contracts

A function value lacking stronger specification metadata has only what can be established from its ordinary logical type/definition/environment.

The system MUST NOT invent `callEnsures` from a name/comment/test.

## 12. Effectful/application contracts

`App` contracts use the application semantics in `21-APPLICATION-SEMANTICS.md`.

Their normalized specification can relate:

~~~text
initial modeled state
input
Exit E A
final modeled state
observable trace
effect/read/write frames
~~~

r3 core does not yet add dedicated surface sugar beyond ordinary predicates/theorems for these fields.

A later syntax revision may add concise clauses without changing `psc-contract-core-v1`.

## 13. VC generation and solvers

VC generation is untrusted proof construction.

Strict evidence requires one of:

- an ordinary proof term checked by the selected kernel;
- a checked certificate with an established sound validator;
- a proved reflective decision procedure;
- an explicitly named weaker trust profile.

Solver `valid`/`unsat`/timeout output is not strict proof authority by itself.

## 14. Assumption policy

Contract evidence reports transitive logical assumptions.

Unresolved holes, `sorry`, fabricated native-result axioms, or policy-disallowed assumptions reject a strict contract proof.

External service/model assumptions are recorded separately from logical axioms.

## 15. Specification well-formedness

A `requires` or `ensures` expression must itself elaborate/type-check in its declared scope independently of whether the implementation body later verifies.

A malformed/vacuous specification is not repaired by changing the implementation.

Tooling SHOULD warn about obviously impossible/vacuous conditions, but such warnings are specification-quality evidence rather than kernel soundness.

## 16. Contract mutation policy

Changing:

- a clause;
- a predicate it references;
- a frame/effect definition;
- an axiom policy;
- a program-logic version

is a specification change, not an implementation repair.

This distinction is especially important for AI-generated code.

## 17. Lean intrinsic compatibility

Pinned Lean intrinsic verification may serve as:

- an oracle for overlapping examples;
- a proof/VC-generation implementation path;
- an explicit compatibility profile.

It does not define `psc-contract-core-v1`.

If intrinsic behavior changes upstream, PSC contract meaning remains unchanged until the PSC contract version changes.

## 18. Normative versus future syntax

Normative r3 source contract syntax:

~~~text
requires <Prop-term>
ensures <result-binder> => <Prop-term>
~~~

All other contract conveniences remain future/profile-specific unless another accepted r3 document explicitly adds them.
