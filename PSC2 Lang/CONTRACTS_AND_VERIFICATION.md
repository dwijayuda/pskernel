# PSC2 Contracts and Verification

Status: **draft verification profile extending PSC1**

PSC2 should make formal verification feel native to ordinary programming.
Contracts are therefore proposed as a standard PSC2 verification surface while
remaining outside the kernel TCB.

## 1. Lean 4.34 precedent

Lean 4.34 added experimental intrinsic verification syntax around ordinary
`def` and `do` programs. The relevant features include:

- `requires` clauses on definitions;
- `ensures` clauses on definitions;
- `assert` inside `do`;
- `invariant` on loops;
- `decreasing` clauses;
- verification-condition generation through `vcgen`/`Std.Do`;
- a `where finally | spec => ...` proof section for obligations automation does
  not close.

Lean 4.34 explicitly warns that this syntax is experimental. PSC2 should use the
same successful conceptual model while freezing only semantics that ProofScript
can specify, bootstrap, test and preserve across backends.

## 2. Goals

PSC2 contracts should be:

- easy for ordinary programmers to read;
- close enough to Lean 4.34 to support `.lean` migration;
- proposition-based rather than Bool-only runtime checks;
- compositional across pure and effectful code;
- usable with loops and mutable-looking `do` syntax;
- independent of the TS/Rust/Wasm backend;
- proof-producing / kernel-checkable;
- erasable after verification;
- extensible by specification libraries without trusting those libraries.

## 3. Function contracts

Draft `.ps` syntax:

```proofscript
function withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result = balance - amount :=
  balance - amount;
```

The supported `.lean` frontend should accept the corresponding Lean-compatible
contract syntax where its semantics are owned.

Multiple clauses may be permitted:

```proofscript
function clamp(x: Int, lo: Int, hi: Int): Int
  requires lo <= hi
  ensures r => lo <= r
  ensures r => r <= hi :=
  ...;
```

All clauses are logical specifications. They are not host-language assertions.

## 4. Meaning of `requires`

A precondition describes what callers must establish for verified use of the
specified operation.

Conceptually:

```text
requires P
```

contributes a proposition `P` to the function specification.

The implementation must distinguish:

1. the executable definition;
2. its verified specification;
3. proofs that the implementation satisfies the specification;
4. proofs/VCs that callers satisfy required preconditions.

No specification record or attribute may itself count as proof.

## 5. Meaning of `ensures`

A postcondition relates input/context and the successful result.

```proofscript
ensures r => Q r
```

provides a result binder and a proposition.

For stateful/effectful computations the contract may bind the logical state
shape required by the relevant verification model, analogous to Lean `Std.Do`.

Example conceptually:

```proofscript
def increment(): StateM Nat Unit
  requires s => s = 0
  ensures _ s => s = 1 := do {
  modify(fun n => n + 1);
}
```

The exact binder shape is driven by the verified effect specification, not by
backend runtime object layout.

## 6. Verified `assert`

PSC2 verification `assert` states a proposition at a program point:

```proofscript
do {
  ...
  assert index <= xs.size;
  ...
}
```

Semantics:

```text
assert P
  -> VC generator creates obligation P
  -> proof/automation constructs proof term
  -> kernel checks proof
  -> assertion has no required runtime effect in verified builds
```

PSC2 must also provide an ordinary runtime check API for debugging/application
logic, but it must be a different semantic concept.

A runtime check passing during execution is never formal proof.

## 7. Loop invariants

PSC2 loops may carry invariants:

```proofscript
do {
  let mut acc := 0;
  for x in xs
    invariant consumed remaining acc =>
      acc = consumed.sum
  {
    acc := acc + x;
  }
  return acc;
}
```

The VC generator should establish at least:

1. invariant initialization;
2. preservation by each iteration;
3. the exit fact required to prove the following program/postcondition;
4. any control-flow obligations introduced by break/continue/early return.

The invariant's logical iterator model must be target-neutral. TS iteration,
Rust iterators and Wasm lowering may differ internally.

## 8. Decreasing / termination evidence

Loops or recursive definitions whose termination is part of a verification
claim may carry a decreasing measure/relation.

PSC2 should reuse a common termination vocabulary where possible:

```text
recursive termination
loop termination
```

should both ultimately establish well-founded descent rather than use unrelated
trusted mechanisms.

## 9. Verification conditions

Contracts should elaborate into a verified-specification representation from
which an untrusted VC generator creates propositions.

```text
source program + contracts
          |
          v
   elaborated program/spec
          |
          v
       VC generator
          |
          v
    obligations : Prop
          |
     +----+------+----------------+
     |           |                |
     v           v                v
 manual proof   simp/etc      external solver
     |           |          + reconstruction
     +-----------+----------------+
                 |
                 v
             proof terms
                 |
                 v
              kernel
```

The VC generator is outside the TCB. A VC-generation bug can make verification
fail or generate the wrong candidate proof task, but cannot make an invalid
proof term pass the kernel.

## 10. Specification lemmas

Libraries should be able to register verified specifications for reusable
operations.

For example, a list/map operation may carry a theorem describing its effect,
and VC generation can use that theorem instead of unfolding the implementation.

The registry must contain references to kernel-admitted declarations. A
`@[spec]`-like tag is an index, not trust.

## 11. Remaining obligations / spec proof sections

PSC2 may support a source form analogous to Lean 4.34's final specification
proof section:

```proofscript
where finally {
  spec := by {
    ...
  }
}
```

Exact syntax is open. The important behavior is that:

- automatic VC generation may leave named goals;
- ordinary theorem tactics/proof terms close them;
- all resulting proofs are kernel checked;
- the executable function body remains separate from proof-only discharge code.

## 12. Pure vs effectful contracts

### Pure function

```proofscript
function abs(x: Int): Nat
  ensures r => r >= 0 :=
  ...;
```

The postcondition is over input/result values.

### Stateful computation

```proofscript
def clear(): StateM Nat Unit
  ensures _ s => s = 0 := do {
  set(0);
}
```

The specification uses the logical state shape defined by the state effect.

### Exceptional computation

For `Result`/`Except`-style effects, PSC2 should support specifications that
separate successful and failure outcomes without pretending failures are host
exceptions.

The exact postcondition shape may use an ADT or effect-specific specification
abstraction.

## 13. Async contracts

If PSC2 Standard Platform introduces `Task A`, contracts apply to the logical
completion of the task, not directly to JS Promise implementation details.

```proofscript
async function loadUser(id: UserId): Task User
  requires valid(id)
  ensures user => user.id = id :=
  ...;
```

A TS backend may use Promise internally, but verification is against the
ProofScript Task semantics.

Cancellation/failure behavior must be explicitly represented in the Task
specification before postconditions can claim facts about it.

## 14. `old` and pre-state values

PSC2 should not immediately require a special `old(expr)` primitive.

Preferred first approach:

- explicit contract binders for initial logical state;
- ordinary immutable local/ghost values capturing pre-state facts;
- effect-specific specification shapes.

Only add `old(...)` as ergonomic syntax when its meaning across pure/stateful,
exceptional and asynchronous computations is unambiguous.

## 15. Ghost data

Proof-only values may be used to state or prove specifications.

Rules:

- ghost/proof-only data must be identified before executable IR;
- it must erase unless explicitly reified as runtime data;
- runtime behavior must not depend on erased ghost values;
- a backend must fail closed if erasure would change observable behavior.

A future `ghost` keyword is optional; the semantic distinction matters more
than the spelling.

## 16. Runtime contract checking

PSC2 MAY provide a diagnostic mode:

```text
psc run --contracts=runtime
```

or an equivalent project profile that evaluates executable approximations of
selected contracts.

This mode is for testing/debugging only.

It MUST NOT change the verification claim:

```text
runtime contract passed != theorem proved
```

Only kernel-admitted proof closes a formal contract.

## 17. External/FFI functions

An external function cannot automatically acquire a verified specification.

Possible statuses should be explicit:

```text
verified external spec
  proof connects model/spec to a trusted/verified adapter

assumed/trusted external spec
  expands the trusted boundary and is reported in artifacts

unverified external call
  cannot be used to establish stronger verified claims without an explicit
  assumption/model
```

The build manifest should expose these trust assumptions.

## 18. Contracts and multiple backends

A verified contract is established **before** target lowering.

```text
source + spec
   -> kernel-checked obligations
   -> CheckedCore
   -> erase proof/spec-only material
   -> VerifiedIR
   -> TS / Rust / Wasm
```

Backend correctness is a separate assurance question. The fact that a source
program is proved does not imply a buggy compiler/backend preserves its
behavior.

ProofScript should therefore maintain distinct claims:

1. source theorem/contract correctness;
2. erasure/compiler semantic preservation;
3. backend/runtime correctness.

## 19. Relationship to PSC1 contracts/proof concepts

PSC2 contracts reuse PSC1 mechanisms:

- `Prop` for specifications;
- theorem/proof terms for evidence;
- existing effect abstractions;
- kernel checking;
- proof erasure;
- CheckedCore/VerifiedIR separation.

They should therefore require **little or no new kernel semantics**.

The substantial new work belongs in:

- parser/source forms;
- specification representation;
- VC generation;
- specification registries;
- tactics/automation;
- tooling/diagnostics.

## 20. Minimum PSC2 verification acceptance gates

Before PSC2 can claim first-class contracts:

1. pure pre/postcondition example closes through the kernel;
2. caller precondition obligation is generated and checked;
3. stateful `requires`/`ensures` example is verified;
4. `assert` creates a proof obligation and erases from runtime;
5. `for` loop invariant initialization/preservation/exit are checked;
6. decreasing/termination example is checked;
7. an intentionally false contract fails closed;
8. an intentionally bad invariant fails closed;
9. TS/Rust/Wasm receive the same pre-backend VerifiedIR after proof erasure;
10. `.lean` and `.ps` contract examples produce equivalent checked
    specifications where both syntaxes are supported;
11. build artifacts list any trusted external assumptions;
12. runtime-checking mode, if present, is clearly separated from proof status.