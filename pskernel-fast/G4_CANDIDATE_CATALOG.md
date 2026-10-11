# G4.1 — Untrusted candidate-declaration catalog

This independent module supports **strict candidate preflight**, not kernel proof checking.

Authoritative Lean 4.35 semantic references:
- [type_checker.cpp::infer_constant](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.cpp): known names, exact universe-argument arity, restrictions on referenced unsafe/partial declarations according to caller's safety policy.
- [declaration.h](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/declaration.h): kinds of constant declarations and proof/value/safety fields.

## Intent

\`CandidateCatalog\` is a persistent map keyed by lawful structural \`KName\` equality. A \`CandidateRecord\` contains a proposed type and optional untrusted value, its own universe parameters, safety mode and declaration kind. Registration refuses duplicate names/parameters, ill-scoped types and values, free/metavariables, wrong level-argument arity, non-existent or forward references, and forbidden safe/partial/unsafe dependencies. The dependency graph only looks backward into the previous immutable snapshot.

**Importantly, a successfully registered candidate is NOT a checked Lean constant, theorem or axiom.** Registration does not infer a type, check a proof, validate positivity, compare dependent types, construct an inductive recursor, establish a model interpretation, or atomically *admit* logical declarations. Do not rebrand the candidate map as a kernel environment or allow it to drive proof acceptance.

The first bounded tests also check that registering or failing to register a candidate cannot mutate the previous map, and that the caller's safety mode follows the currently observed Lean rule that safe cannot reference partial/unsafe, partial cannot reference unsafe, and unsafe is permitted to reference both. The rule mapping must be reevaluated as more declaration kinds are implemented.

No existing PSKernel code or metatheory is imported. The module uses the independently developed G3 \`KExpr\` and G4.0 symbolic levels; a \`CandidateCatalog\` can never be used as an implicit checked declaration environment.

## Next formal/implementation obligations

1. Prove \`register\` success preserves name freshness, non-duplicate universe parameters and exact catalog lookup identities, subject to its stated structural preflight conditions.
2. Maintain a **distinct, sealed checked environment**. The only promotion from an untrusted \`CandidateRecord\` must be a fully verified dependent type inference/DefEq/admission transaction.
3. Make an explicit immutable environment-generation identity and a consistent positive cache/refinement rule before any checked type cache is used.
4. Add a strict resource/size policy for untrusted huge candidate arrays/names; termination of structurally recursive Lean functions is not a host-level memory bound.
5. Integrate actual official Lean 4.35 valid/invalid declaration exports, preserving normal vs verified modeled-axiom policies.

**Stage status:** implementation is a candidate until the exact 4.35 cloud workflow and tests pass. No proven kernel soundness, no admission, and no whole-kernel performance claim.
