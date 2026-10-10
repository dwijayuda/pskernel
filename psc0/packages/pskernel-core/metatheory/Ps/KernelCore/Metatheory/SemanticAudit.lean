import Lean
import Ps.KernelCore.Metatheory.SemanticSortInference
import Ps.KernelCore.Metatheory.SemanticSetDomain

/-!
Machine-checked dependency audit for the new semantic foundation.
The allowlist is only the standard host foundation; sorryAx and every custom
axiom are rejected. Local domain and callback premises are separately exposed
in theorem statements and documented in RESEARCH_AND_MIGRATION.md.
-/

open Lean Elab Command in
run_cmd do
  let targets : Array Name := #[
    ``PsKernelSemantics.Interpretation.equal_symm,
    ``PsKernelSemantics.Interpretation.equal_trans,
    ``PsKernelSemantics.Interpretation.convert,
    ``PsKernelSemantics.Interpretation.proof_irrelevance,
    ``PsKernelSemantics.Interpretation.no_empty_inhabitant,
    ``PsKernelSemantics.Interpretation.not_equal_of_undefined,
    ``PsKernelSemantics.PropositionDomain.domain,
    ``PsKernelSemantics.PropositionDomain.pi_isProp,
    ``PsKernelSemantics.PropositionDomain.pi_intro,
    ``PsKernelSemantics.PropositionDomain.pi_elim,
    ``PsKernelSemantics.PropositionDomain.no_proof_of_all_props,
    ``PsKernelSemantics.PropositionDomain.sortValue_isType,
    ``PsKernelSemantics.PropositionDomain.sortValue_mem_succ,
    ``PsKernelSemantics.PropositionDomain.sortValue_not_mem_self,
    ``PsKernelSemantics.PropositionDomain.witness_propCompatible,
    ``PsKernelSemantics.PropositionDomain.witness_sort_hasType,
    ``PsKernelSemantics.PropositionDomain.witness_no_type_in_type,
    ``PsKernelSemantics.PropositionDomain.witness_proposition,
    ``PsKernelSemantics.PropositionDomain.witness_inhabited,
    ``PsKernelSemantics.PropositionDomain.witness_proof_irrelevance,
    ``PsKernelSemantics.PropositionDomain.witness_empty,
    ``PsKernelSemantics.PropositionDomain.witness_not_universal,
    ``PsKernelSemantics.PropositionDomain.undefined_not_equal,
    ``PsKernelSemantics.normalizesToZero_eval,
    ``PsKernelSemantics.checkedInference_implies_inferOnly,
    ``PsKernelSemantics.propCompatible_of_sort_valuation,
    ``PsKernelSemantics.classifier_true_sound,
    ``PsKernelSemantics.proofIrrelevance_calls_sound,
    ``PsKernelSemantics.PropositionDomain.forged_classifier_succeeds,
    ``PsKernelSemantics.PropositionDomain.proof_is_not_proposition,
    ``PsKernelSemantics.PropositionDomain.operational_success_is_insufficient,
    ``PsKernelSemantics.PropositionDomain.forgedInfer_not_sound,
    ``PsKernelSemantics.inferCore_sort_result,
    ``PsKernelSemantics.inferCore_sort_sound,
    ``PsKernelSemantics.sort_inference_has_concrete_model,
    ``PsKernelSemantics.SetModel.domain,
    ``PsKernelSemantics.SetModel.sort_isType,
    ``PsKernelSemantics.SetModel.sort_not_self,
    ``PsKernelSemantics.SetModel.pi_mem_sort,
    ``PsKernelSemantics.SetModel.application_mem,
    ``PsKernelSemantics.SetModel.beta,
    ``PsKernelSemantics.SetModel.eta,
    ``PsKernelSemantics.SetModel.empty_type_uninhabited,
    ``PsKernelSemantics.SetModel.no_proof_of_all_props
  ]
  let allowed : Array Name := #[``propext, ``Classical.choice, ``Quot.sound]
  for target in targets do
    let used ← Lean.collectAxioms target
    for dependency in used do
      unless allowed.contains dependency do
        throwError "Unapproved axiom {dependency} in semantic declaration {target}"
  logInfo m!"PSKERNEL_SEMANTIC_AXIOMS: PASS declarations={targets.size}; local hypotheses remain explicit"
