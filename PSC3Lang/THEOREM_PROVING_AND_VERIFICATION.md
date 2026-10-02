# Theorem proving, contracts and verification

**Proposed assurance model.** Mathematical expressiveness and application verification share a foundation, but no compiler/kernel theorem is established by this document.

## 1. A real theorem prover

Retain dependent functions, universes, inductive families, equality, ordinary proof terms, classical/noncomputable mathematics under an explicit policy, and a serious tactic/simplifier layer. The theorem prover is not reduced to an automated contract syntax.

The initial teaching path can be simple definitions, propositions and equality before advanced universes and automation. The full logical model remains the selected Lean theory; teaching must not invent a simpler incompatible type system. [L09](RESEARCH_SOURCES.md#lean-and-logical-foundations)

Prioritize `have`, `show`, `calc`, rewriting, simplification, cases and induction, with inspectable goals and replayable evidence. Larger arithmetic/search procedures belong in proof-producing libraries/plugins. A large tactic engine need not enlarge the checker, although it increases elaboration and maintenance cost.

## 2. Final theorem, not just successful obligations

For a pure total implementation f, a representative contract theorem is:

```text
for all x, Pre(x) implies Post(x, f(x))
```

For state/effects, use the appropriate program relation over initial/final states and observable outcomes. The theorem must identify the actual f and fixed specification definitions. An untrusted verification-condition generator that emits `True` must not be able to obtain the requested program theorem merely by proving that unrelated proposition.

The policy fixes the specification's semantic dependency closure, not just the source text of its final line. Modifying a predicate definition to always return True is a requirement change. Independent proof validation must match expected statements and referenced definitions. [L08](RESEARCH_SOURCES.md#lean-and-logical-foundations)

## 3. Native contract baseline

Plain definition-plus-theorem is the stable conceptual baseline. The pinned intrinsic mechanism is experimental and is adopted only as that named capability. The inspected parser has one optional precondition and one optional postcondition clause; the inspected test generates a separate `.spec` theorem and distinguishes proof assertions from runtime assertions. [L03–L04](RESEARCH_SOURCES.md#lean-and-logical-foundations)

Do not rebrand experimental syntax as a frozen PSC innovation. A specification library may hide some implementation churn behind ordinary definitions. It must still keep the theorem about the actual computation visible.

## 4. Callers and gradual adoption

An ordinary program can be type-checked and executed without a full functional-correctness proof. An explicitly verified caller must discharge the preconditions needed in its own correctness argument. A proof-bearing dependent API can require evidence directly. These are explicit choices, not modes that secretly change function meaning.

External callers use validated boundary wrappers where the guarantee requires constrained inputs. Generated `.d.ts` and Rust interfaces communicate types, but arbitrary foreign values must not bypass the logical input relation.

Do not force effectful applications into an unsafe source suffix. A typed IO program may have useful local/state/trace proofs without total termination or a verified world model.

## 5. Outcome and resource precision

A contract about successful results alone may permit an implementation that always fails. A sorting property that only requires sorted output may permit an always-empty result. Contradictory preconditions may make obligations vacuous. Use specification-quality tooling and deliberate bad implementations to expose these weaknesses.

Such checks are diagnostics and evidence, not proof that the full human requirement has been captured. The finite experiments demonstrate small examples of weak specifications; they do not solve requirement validation generally.

For async programs distinguish successful completion, typed failure, cancellation, divergence and resource outcomes. A timeout does not establish absence of a remote side effect. For partial definitions, a theorem about the opaque logical constant is not automatically about its compiled body. [L05](RESEARCH_SOURCES.md#lean-and-logical-foundations)

## 6. Assumptions and policies

Keep these categories separate:

| Category | Treatment |
|---|---|
| Selected foundational axioms | Exact reviewed declarations; report transitive theorem dependence. |
| Explicit user/model hypotheses | Visible in theorem type or assumption policy. |
| External implementation assumptions | Runtime/model layer; do not silently become proof axioms. |
| Incomplete proofs | Usable editor state, not admitted strict release evidence. |
| Native/solver proof shortcuts | Independent certificate/reconstruction or a separately named larger trust profile. |
| Compiler/backend assumptions | Separate preservation/build-trust accounting. |

A constructive restriction and a classical mathematics profile may share the same checker rules with different permitted assumptions. Do not ban all classical mathematics to advertise safety; do not permit arbitrary axioms while advertising unconditional proof.

## 7. Proof-carrying packages and changes

A package may contain source declarations, specification identities, proof terms/certificates, logical assumptions, dependency snapshots and target-preservation evidence. The consumer can replay relevant proofs without trusting the author's automation.

A package hash or signature authenticates identity/provenance, not mathematical correctness. The exact checked artifact and referenced definitions must be bound. On reimport, a Boolean accepted flag is not a substitute for the required checking operation.

Proof scripts and proof terms have different stability requirements. Tactic upgrades may break script reconstruction even when a theorem remains meaningful. Pin the elaboration environment, retain useful explicit evidence and support proof-repair diagnostics.

## 8. Application verification opportunities

Good early targets include codec round trips and rejection properties; route parsing/printing; invariant-preserving reducers; permission-decision functions under explicit input assumptions; bounded allocation/accounting models; and pure algorithms shared between browser and server.

A proved authorization decision over validated claims does not verify the identity provider, token parser or transport automatically. A proved transaction state machine does not establish the database's isolation behavior. A proved view model does not verify CSS layout. The report must expose these boundaries rather than undermine useful local proofs with a misleading whole-app claim.

## 9. What the checker must establish

The independent kernel's own desired theorem is that successful admission preserves well-formedness/derivability under its declared rules and assumptions. Its implementation needs evidence for binding, universes, conversion, primitives, inductives, quotients and transactional environment updates. Tests and agreement with Lean are important, but not that theorem.

The existing owned-kernel design explicitly recognizes these obligations. Reuse its canonical bundle/checked-module seam instead of inventing another shortcut checker for UI or contracts. [R06](RESEARCH_SOURCES.md#repository-baselines)

## 10. Release assurance vocabulary

Use explicit fields such as source accepted, logical admission, contract evidence, termination evidence, source correspondence, erasure evidence, target preservation, runtime assumptions and observed tests. Do not collapse them into a single green badge.

The requested claim determines the needed evidence. If preservation is not established, say that the source theorem is checked and executable correctness retains the reported compiler/runtime assumptions. If a solver fails to find a proof, report incomplete search rather than a fabricated counterexample.
