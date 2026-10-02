# PSC3 Theorem Prover and Formal Verification

Status: **architecture and language-design draft**

The theorem prover is a defining property of ProofScript.

PSC3 should make theorem proving powerful enough for serious mathematics and verification while keeping ordinary programming approachable.

## 1. One logical foundation

PSC3 uses a dependent core in the Lean-compatible family selected by the kernel profile.

The logical foundation includes, as supported by the profile:
- universes;
- dependent functions;
- inductive families;
- equality;
- propositions/proofs;
- recursors/elimination;
- proof irrelevance;
- quotients/extensionality according to explicit profile;
- controlled axioms.

The kernel checks proof terms/declarations.

Parser, elaborator, tactics, automation and AI are outside proof authority.

## 2. Theorem programming

Native .ps should support structured proof forms familiar to Lean users:

~~~text
by
have
show
suffices
calc
rfl
rw
simp
simpa
cases
induction
by_cases
by_contra
subst
change
unfold
rcases-like destructuring
~~~

The exact standard vocabulary can evolve above the kernel.

A successful tactic produces/reconstructs ordinary evidence.

## 3. Simplifier

A mature simplifier is required for the standard theorem experience.

It should support:
- simp;
- simpa;
- simp only;
- simp at;
- local hypotheses;
- registered lemmas;
- congruence;
- simplification procedures;
- deterministic configuration.

The simplifier is untrusted.

Its output must remain kernel-checkable.

## 4. Automation

Standard packages may include:
- Presburger arithmetic;
- linear arithmetic;
- ring normalization;
- numeric normalization;
- rewriting/search;
- SAT/SMT integration;
- AI proof search.

External solvers need proof reconstruction or checked certificates before contributing to a strict verified claim.

An unsupported solver "valid" response is not proof.

## 5. Contracts as first-class specifications

Core surface:

~~~proofscript
function withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result = balance - amount
{
  balance - amount
}
~~~

Contracts are logical propositions tied to the program.

They must distinguish:
1. executable implementation;
2. specification;
3. theorem that implementation satisfies specification;
4. caller obligations;
5. optional runtime validation.

## 6. Binding the proof to the actual program

A critical PSC3 requirement:

> Verification success must establish the requested property of the actual accepted implementation, not merely prove whatever VCs an untrusted generator emitted.

For a pure function, the final admitted result should conceptually connect:

~~~text
implementation f
precondition P
postcondition Q
proof: forall x, P(x) -> Q(x, f(x))
~~~

For effectful/partial programs, use the corresponding program semantics/judgment.

This prevents a buggy VC generator from creating an unrelated trivially true obligation and calling the program verified.

## 7. requires

requires describes caller obligations.

Multiple clauses normally conjoin.

A precondition is not a license for the compiler/AI to strengthen the domain silently.

Changes to an approved precondition are specification changes.

## 8. ensures

ensures describes result/effect outcomes.

Error-producing functions must state whether the condition applies to:
- success only;
- error only;
- both through a result relation.

Do not silently assume successful completion.

## 9. assert

Verified assert creates a proposition obligation.

It may erase after proof.

Runtime debugging assertion is a different operation.

## 10. Loop invariants

Verified loops generate obligations for:
- initialization;
- preservation;
- exit;
- break/continue paths;
- early return paths;
- state/effect transitions.

The invariant is a logical assertion, not a target-language Boolean check.

## 11. Termination

decreasing/termination evidence should reuse well-founded logic.

Termination claims are separate from partial correctness.

Tools report:
- partial correctness proved;
- termination proved;
- total correctness;

separately.

## 12. Partial and long-running applications

Full applications include servers and event loops.

PSC3 therefore needs useful reasoning about computations that are not total functions returning a value.

Research direction:
- operational/coinductive trace semantics;
- Hoare-style safety/partial correctness;
- effect-specific specifications;
- state-machine invariants.

The initial PSC3 release may expose only a bounded verified profile for partial/effectful programs.

It must not pretend total-function logic automatically proves properties of arbitrary long-running IO.

## 13. Stateful specifications

A state effect can expose:

~~~text
Pre  : State -> Prop
Post : Result -> State -> Prop
~~~

or a more general relation.

Specifications use logical state, not backend object layout.

## 14. Async specifications

Task contracts must account for:
- successful completion;
- typed failure;
- cancellation;
- timeout/race outcomes;
- spawned child tasks;
- externally observable effects.

Until Task semantics are frozen, async verification claims should be scoped conservatively.

## 15. Ghost data

Ghost/proof-only state can express specifications and facilitate proofs.

Rules:
- identified before executable lowering;
- runtime computation cannot depend on erased ghost values;
- erasure fails closed if relevance is uncertain.

## 16. Specification registries

Libraries can register admitted theorems describing operations.

For example:

~~~proofscript
@[spec]
theorem mapSpec(...) : ...
~~~

The registry is an index.

Truth comes from the referenced admitted theorem.

## 17. Assumptions and axioms

Every non-foundational assumption relevant to a claim is reportable.

Strict profile should reject/flag:
- arbitrary undeclared axioms;
- sorry-like placeholders;
- unchecked native evaluation as proof;
- trusted external theorem results.

A research profile may allow explicit axioms while preserving complete provenance.

## 18. Classical/noncomputable mathematics

The theorem environment supports explicit classical reasoning and noncomputable definitions when the selected logical profile does.

Noncomputable theorem definitions are legitimate mathematical objects.

They cannot silently become executable application code.

## 19. Proof stability

PSC3 should distinguish:
- theorem statement/meaning;
- checked proof term;
- proof script;
- tactic implementation.

A tactic update may require script repair without changing theorem truth.

Build artifacts should preserve enough identity/provenance to replay important evidence.

## 20. AI proof generation

AI may:
- propose proof scripts;
- synthesize invariants;
- generate lemma candidates;
- suggest stronger useful specs;
- search for counterexamples;
- repair implementation/proof code.

AI cannot:
- grant kernel acceptance;
- silently weaken an approved specification;
- introduce hidden assumptions;
- convert a runtime test into proof.

## 21. Specification protection for AI workflows

An approved spec bundle should identify:
- contract text/AST;
- referenced predicate definitions;
- relevant data definitions;
- dependency closure;
- axiom policy;
- semantic profile.

Changing any of these may change meaning even when the contract text stays identical.

Hashes identify exact artifacts; they do not prove semantic equivalence between old and new specs.

## 22. Counterexamples

Where a decidable/bounded model finder finds a counterexample, tooling should present it clearly.

A solver model is only a confirmed program counterexample when its relation to the PSC semantics has been validated.

Timeout/unknown are not failures of the theorem.

## 23. Verification levels

Suggested user-facing statuses:

~~~text
Typed
KernelChecked
ContractVerified
TerminationVerified
SafetyVerified(profile)
CompilerPreserved(target/profile)
ExternallyAssumed(...)
~~~

A single green "verified" badge is too coarse for a serious platform.

## 24. Proof artifacts

A release artifact may include:
- canonical declaration bundle;
- proof dependency graph;
- assumptions;
- specification identity;
- kernel/profile identity;
- optional compact proof/certificate data;
- compiler-preservation evidence identity.

The exact binary format is a separate versioned contract.

## 25. Relationship to Lean

Supported .lean theorem source retains official Lean syntax.

Native .ps provides its own regular proof/program surface.

Both target compatible canonical proof semantics for the claimed overlap.

Lean-compatible libraries may be reused by:
- source compatibility;
- checked declaration import;
- PSC-native wrapper/port.

## 26. Soundness over convenience

Any feature that would make proof acceptance depend on:
- JavaScript execution;
- Rust execution;
- a bundler;
- an AI model;
- an SMT Boolean;
- runtime test success;

must either reconstruct/check evidence or explicitly expand the trust profile.

Convenience never silently changes the meaning of proof.
