# r3 Stable PSC-Owned Contracts

Status: **accepted r3 semantic design; production implementation pending.**

## Decision

ProofScript r3 owns the stable contract semantics, but the **normative r3 surface core is deliberately narrow**.

The frozen r3 contract surface contains:
- `requires P`;
- `ensures result => Q`;
- total pure functions.

Stateful/loop/async contract clauses such as surface `assert`, `invariant`, `modifies`, `decreasing`, old-state syntax, and async trace clauses are reserved for later profile revisions until their program logic is specified.

Lean intrinsic verification may remain an oracle or implementation path, but it is not the definition of PSC contracts.

The kernel still checks ordinary evidence; r3 adds no trusted contract primitive.

## Pure total functions

For:

~~~proofscript
function withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result = balance - amount
:=
  balance - amount
~~~

the final accepted claim must be equivalent to:

~~~text
forall balance amount,
  amount <= balance ->
  withdraw balance amount = balance - amount
~~~

and it must refer to the actual accepted implementation declaration.

A VC generator that proves an unrelated True proposition cannot authorize the implementation.

## Normative pure contract semantics

For a declaration with preconditions `P₁ ... Pₙ` and postconditions `Q₁ ... Qₘ`, r3 normalizes:

~~~text
Pre x := P₁ x ∧ ... ∧ Pₙ x
Post x result := Q₁ x result ∧ ... ∧ Qₘ x result

ContractTheorem :=
  ∀ x, Pre x → Post x (implementation x)
~~~

with the corresponding dependent/multi-parameter generalization.

Zero `requires` means `True`. Zero `ensures` means the declaration has no contract theorem request.

The theorem identity binds to the exact admitted implementation and normalized specification dependency closure.

## Normalized contract model

A normalized contract contains:

- exact implementation identity;
- specification identity;
- precondition;
- outcome relation;
- optional state relation;
- optional termination obligation;
- semantic dependency closure;
- axiom policy;
- proof/evidence status.

Multiple preconditions conjoin. Result conditions are normalized by outcome rather than silently assuming success.

## Typed outcomes

For `Except E A` and other sum/result types, the stable r3 surface does **not** add separate success/error clause syntax.

Outcome-sensitive properties use the ordinary result binder plus native matching:

~~~proofscript
function parseUser(input: String): Except ParseError User
  ensures result =>
    match result with {
      | .ok user => User.valid(user)
      | .error err => ParseError.describes(input, err)
    }
:=
  ...
~~~

This keeps the stable contract grammar to `requires` and `ensures result => ...` while retaining full logical expressiveness.

A future convenience spelling such as separate `.ok`/`.error` postconditions requires an explicitly versioned contract-syntax revision.

## Caller obligations

A precondition is not runtime enforcement by itself.

Callers fall into four categories:

1. verified callers that prove the obligation;
2. dependent/proof-bearing APIs that receive evidence;
3. runtime boundary wrappers that validate a decidable condition;
4. explicitly trusted external callers.

Generated TypeScript declarations do not enforce ProofScript preconditions at runtime.

## Frame and effect semantics

Every contract has a semantic frame, even when the pure r3 surface does not spell it explicitly.

~~~text
FrameSpec {
  effectFrame
  readFrame
  writeFrame
}
~~~

For a total pure function, all three frames are empty.

`effectFrame` is a finite normalized set of permitted capability-operation identities.

`readFrame` identifies abstract mutable regions/foreign resources whose state may influence the result or trace.

`writeFrame` identifies abstract mutable regions/foreign resources the computation may modify.

For future stateful/application contracts, a postcondition about the returned value is not permission to mutate unrelated state.

The application type `App caps err result` provides an upper bound on permitted capability classes; a contract may narrow that effect frame but may not silently expand it.

Frame identities belong to the versioned program-logic model rather than raw target pointers. Frame/effect information is part of specification identity and evidence invalidation.

## Higher-order callable contracts

ProofScript is higher-order, so r3 freezes an ordinary logical model for function values without adding kernel primitives.

Conceptually:

~~~text
CallableSpec args result := {
  requires : args -> Prop
  ensures  : args -> result -> Prop
}

callRequires(f, args) : Prop
callEnsures(f, args, outcome) : Prop
callEffects(f, args) : EffectFrame
callReads(f, args) : ReadFrame
callWrites(f, args) : WriteFrame
~~~

A function value carrying/associated with a `CallableSpec` may be used by a higher-order theorem only through ordinary proved relationships connecting that value to `callRequires`, `callEnsures`, and any effect/read/write frame guarantees it relies on.

This model is analogous in purpose to higher-order pre/postcondition predicates in verification systems, but PSC defines its own predicates and proof obligations.

The r3 surface does not yet add special callable-contract syntax; ordinary theorem/library APIs expose these predicates first.

## Stateful and partial programs

Stateful specifications use explicit pre/post state relations. Partial functions can have partial-correctness and safety results without claiming termination. Long-running services may use trace/state invariants instead of total-return theorems.

The public assurance vocabulary must distinguish:

- partial correctness;
- termination;
- total correctness;
- trace safety.

## Stateful/loop/async contracts are staged

The semantics below are requirements for a future extension, not accepted r3 base-surface productions.

A future loop contract must cover initialization, preservation, normal exit, break, continue, early return, typed failure, and cancellation/effect exits when those constructs are present.

A future stateful contract must include an explicit frame/effect relation.

A future async contract must range over explicit outcomes/traces from the accepted application semantic model rather than pretending an async computation is a total pure return value.

## Ghost and erased values

Ghost values are explicitly classified. Runtime behavior must not depend on evidence that is erased. Failure to establish relevance/irrelevance rejects the executable claim.

## Specification identity

An approved specification includes:

- normalized contract AST;
- referenced predicates and types;
- imported theorem dependencies;
- selected program-logic version;
- semantic pin and profile;
- axiom policy.

Protecting only the textual ensures clause is insufficient if an agent can redefine its predicates.

## AI policy

Recommended repository policy:

~~~text
implementation: writable
proof scripts: writable
contracts: review-required
contract semantic dependencies: review-required
axiom policy: locked
foreign trust declarations: review-required
verification toolchain: locked
~~~

This is build/repository policy, not kernel authority.

## VC generation

VC generation is untrusted proof construction.

~~~text
checked implementation
      +
normalized specification
      |
      v
untrusted VC generator / automation / SMT
      |
      v
proof term or checked certificate
      |
      v
ordinary admitted theorem
      |
      v
ContractEvidence(implementationId, specificationId)
~~~

Solver valid/unsat output is not strict-profile proof authority without reconstruction, a checked certificate, or an explicitly larger trust profile.

## Lean intrinsic compatibility

If the pinned intrinsic system overlaps:

- PSC may lower compatible contracts to it;
- generated specification theorems can be candidate evidence;
- experimental status remains visible;
- unsupported PSC features use the PSC path or reject.

PSC contract meaning does not change with upstream experimental implementation details.

## First implementation slice

The first implementation slice is exactly the frozen normative core:
- total pure functions;
- `requires`;
- `ensures result => ...`;
- empty pure frame;
- final admitted contract theorem;
- assumption reporting.

Higher-order `CallableSpec` is a library/logical interface that can be implemented alongside the pure core without adding syntax.

Typed-error outcome sugar, mutable-state frames, loops/invariants, termination clauses and async traces require later explicitly versioned contract profiles.

## Evidence status

Normative pure contract core, outcome-through-match rule, frame semantics, and higher-order callable model: **accepted for r3**.
Production contract elaborator: **not implemented**.
General VC correctness theorem: **not proved**.
AI policy enforcement: **not implemented**.
