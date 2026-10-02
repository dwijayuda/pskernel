# Theorem proving, contracts and verification

**Proposed assurance model. Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** Mathematical and application reasoning share a foundation, but no compiler/kernel theorem is established by this document.

## 1. A real theorem prover

Retain dependent functions, universes, inductive families, equality, ordinary proof terms, explicit classical/noncomputable policies and substantial tactics/simplification. The prover is not reduced to automated contract syntax.

Teach simple definitions/equalities before advanced concepts without inventing a simpler incompatible logic. V0.7 retains `theorem`, `Prop`, `fun`, `by`, `have`, `show`, `calc` and inherited tactic categories. Registered term/header decoration does not globally rewrite tactic punctuation. [Reference §§16–19](../study/proofscript-language-reference-v0.7.0/ProofScript_Language_Reference_v0.7.0_authoritative_draft.md)

```proofscript
theorem selfEq {α : Type}(x : α) : x = x := by {
  rfl
}
```

This reference-style example is a documentation candidate, not a new proof execution. Rewriting, simplification, cases and induction should have inspectable goals and replayable evidence. Large search procedures remain proof-producing libraries/plugins, not checker authority.

## 2. Final theorem, not unrelated obligations

For total pure implementation f, the desired form is conceptually:

```text
for every x: Pre(x) implies Post(x, f(x))
```

This is explanatory logic notation, not replacement source grammar. Effectful claims use the appropriate program relation. The final theorem must identify actual f and fixed predicates. Proving an unrelated True emitted by a buggy VC generator is insufficient.

Protect semantic specification dependencies, not only final-line text. Modifying a predicate to True changes requirements. Validation must match statements and referenced definitions. [L08](RESEARCH_SOURCES.md#lean-and-logical-foundations)

## 3. Contract source baseline

Plain v0.7 definitions plus ordinary theorems are the baseline. `function` and `const` remain aliases to definitions, not aliases to theorem or opaque declarations. Proof-producing contracts must ultimately establish a theorem about that actual definition.

Upstream intrinsic syntax is a separately gated inherited capability, not newly registered PSC grammar. Prior 4.34.1 parser/test observations [L03–L04](RESEARCH_SOURCES.md#lean-and-logical-foundations) are upgrade research; recheck the exact v0.7/4.34.0 pin/import/option requirements before acceptance. Do not infer repeated clauses, final-proof-section syntax, brace rules or automatic proof arguments from examples in another version.

Specification libraries can stabilize APIs without hiding the resulting theorem. They cannot extend source grammar merely by being mentioned in the platform plan.

## 4. Callers and adoption

Ordinary typed programs need not have complete functional-correctness proofs. Verified callers discharge the obligations needed by their claims; dependent APIs may explicitly require proofs. These choices cannot silently change function meaning.

Foreign callers need validating wrappers when required by input relations. `.d.ts`/Rust types do not enforce all logical invariants. Inherited IO/effectful programs can be ordinary `.ps` or `.lean`; lack of a totality theorem does not force a different file suffix. `.psx` is an explicit source/extension boundary, not the name for every unproved program.

## 5. Outcomes and resources

Success-only conditions can admit always-failing implementations; sorted-output-only contracts can admit empty output; contradictory preconditions can be vacuous. Use deliberate mutants and specification-quality diagnostics without claiming complete human-intent validation.

For async/partial code distinguish success, failure, cancellation, divergence and resources. Timeouts do not erase remote effects. Logical opacity of partial definitions does not prove their executable bodies. Named program models and bridge evidence are required.

## 6. Assumptions

| Category | Treatment |
|---|---|
| Foundational axioms | Exact reviewed declarations and transitive dependence. |
| User/model hypotheses | Visible theorem assumptions or explicit policy. |
| External behavior | Runtime/model boundary, not hidden proof axioms. |
| Incomplete proofs | Editor state, not strict release evidence. |
| Native/solver shortcuts | Checked reconstruction/certificates or named larger trust profile. |
| Compiler/backend assumptions | Separate preservation/build-trust accounting. |

Classical and constructive policies may share checker rules while differing in assumptions. Do not ban useful mathematics to advertise safety or allow arbitrary axioms while promising unconditional proof.

## 7. Proof packages and changes

Packages bind source-reference/registry version, original declarations, canonical lowering, specifications, proofs, assumptions, dependencies and target evidence. Consumers can replay evidence without trusting authoring automation.

Hashes/signatures authenticate identity, not truth. An accepted Boolean is not a checking operation. Tactic scripts and proof terms have different stability: pin environments and support explicit evidence/reconstruction and repair.

The v0.7 S1–S5 source/lowering evidence ladder is separate from program contract proofs, kernel compatibility and backend preservation. This documentation correction claims none of those promotions.

## 8. Application opportunities

Early targets include codec laws, routes, invariant-preserving reducers, permission decisions with explicit inputs, bounded resource models and shared pure algorithms.

A permission theorem does not verify the identity provider or transport. A transaction state machine does not prove database isolation. A view model does not verify CSS/browser behavior. Preserve useful scoped proofs without misleading whole-app claims.

## 9. Checker obligations

The desired independent-kernel theorem relates successful admission to derivability/well-formedness under its rules and assumptions. Binding, universes, conversion, primitives, inductives, quotients and transactional updates need evidence. Tests/Lean agreement are useful but not that theorem.

Reuse the owned-kernel bundle/CheckedModule seam rather than inventing a UI/contract bypass. [R06](RESEARCH_SOURCES.md#repository-baselines) A correct checker still needs source-to-statement correspondence through the actual v0.7 lowerer.

## 10. Assurance vocabulary

Report source conformance, logical admission, contract/termination evidence, canonical source correspondence, erasure, target preservation, runtime assumptions and observed tests separately. Do not collapse them into one badge.

Missing preservation leaves executable compiler/runtime assumptions explicit. Unsuccessful proof search is not a fabricated counterexample. No new theorem or parser result is claimed by this repair.
