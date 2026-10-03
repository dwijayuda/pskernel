# r3 Stable PSC-Owned Contracts

Status: **accepted r3 semantic design; production implementation pending.**

## Decision

ProofScript r3 owns the semantics of requires, ensures, assert, invariant, and termination/specification metadata. Lean intrinsic verification may remain an oracle or implementation path, but it is not the definition of PSC contracts.

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

For Except E A, a contract should distinguish successful and failed outcomes.

Proposed source direction:

~~~proofscript
function parseUser(input: String): Except ParseError User
  ensures .ok user => User.valid(user)
  ensures .error err => ParseError.describes(input, err)
:=
  ...
~~~

The exact surface grammar remains subject to parser work. The semantic relation is stable: every permitted terminal outcome receives an explicit predicate.

## Caller obligations

A precondition is not runtime enforcement by itself.

Callers fall into four categories:

1. verified callers that prove the obligation;
2. dependent/proof-bearing APIs that receive evidence;
3. runtime boundary wrappers that validate a decidable condition;
4. explicitly trusted external callers.

Generated TypeScript declarations do not enforce ProofScript preconditions at runtime.

## Stateful and partial programs

Stateful specifications use explicit pre/post state relations. Partial functions can have partial-correctness and safety results without claiming termination. Long-running services may use trace/state invariants instead of total-return theorems.

The public assurance vocabulary must distinguish:

- partial correctness;
- termination;
- total correctness;
- trace safety.

## Loop invariants

Loop verification must cover initialization, preservation, normal exit, break, continue, early return, typed failure, and cancellation/effect exits when those constructs are present.

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

Freeze first:

- total pure functions;
- requires;
- one normalized result relation;
- final admitted theorem;
- assumption reporting.

Then extend to typed failure, loops/state, partial correctness, and application effects.

## Evidence status

Semantic architecture: **accepted for r3**.
Production contract elaborator: **not implemented**.
General VC correctness theorem: **not proved**.
AI policy enforcement: **not implemented**.
