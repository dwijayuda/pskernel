import Lean
import Ps.KernelCore.Metatheory.SemanticSortInference
import Ps.KernelCore.Metatheory.SemanticContext
import Ps.KernelCore.Metatheory.SemanticErasure
import Ps.KernelCore.Metatheory.SemanticModelAdequacy
import Ps.KernelCore.Metatheory.SemanticDeclarative
import Ps.KernelCore.Metatheory.SemanticConcrete
import Ps.KernelCore.Metatheory.SemanticExtension
import Ps.KernelCore.Metatheory.SemanticStructuralEquality
import Ps.KernelCore.Metatheory.SemanticAbstraction
import Ps.KernelCore.Metatheory.SemanticScope
import Ps.KernelCore.Metatheory.SemanticLevelConstructors
import Ps.KernelCore.Metatheory.SemanticUniverseSubstitution

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
    ``PsKernelSemantics.SetModel.no_proof_of_all_props,
    ``PsKernelSemantics.SetModel.interp_liftN,
    ``PsKernelSemantics.SetModel.interp_inst,
    ``PsKernelSemantics.SetModel.interp_inst_zero,
    ``PsKernelSemantics.SetModel.interp_scoped,
    ``PsKernelSemantics.SetModel.interp_closed,
    ``PsKernelSemantics.SetModel.models_sort,
    ``PsKernelSemantics.SetModel.models_forall,
    ``PsKernelSemantics.SetModel.models_lam,
    ``PsKernelSemantics.SetModel.models_app,
    ``PsKernelSemantics.SetModel.models_let,
    ``PsKernelSemantics.SetModel.models_convert,
    ``PsKernelSemantics.SetModel.models_proof_irrelevance,
    ``PsKernelSemantics.SetModel.models_beta,
    ``PsKernelSemantics.SetModel.models_zeta,
    ``PsKernelSemantics.SetModel.models_eta,
    ``PsKernelSemantics.SetModel.models_weaken,
    ``PsKernelSemantics.SetModel.empty_context_satisfiable,
    ``PsKernelSemantics.SetModel.no_closed_empty_type,
    ``PsKernelSemantics.SetModel.no_closed_allProps,
    ``PsKernelSemantics.AnnotatedExpr.erase_liftN,
    ``PsKernelSemantics.AnnotatedExpr.scoped_iff_noLoose,
    ``PsKernelSemantics.AnnotatedExpr.inst_scoped,
    ``PsKernelSemantics.AnnotatedExpr.erase_inst,
    ``PsKernelSemantics.AnnotatedExpr.erase_instantiate1,
    ``PsKernelSemantics.SetModel.instantiate1_has_reading,
    ``PsKernelSemantics.SetModel.propIdentity_scoped,
    ``PsKernelSemantics.SetModel.propIdentity_type,
    ``PsKernelSemantics.SetModel.propIdentityType_sort,
    ``PsKernelSemantics.SetModel.erasure_is_not_semantic_coherence,
    ``PsKernelSemantics.SetModel.models_variable_zero,
    ``PsKernelSemantics.SetModel.models_substitution,
    ``PsKernelSemantics.Declarative.sound,
    ``PsKernelSemantics.Declarative.identity_derives,
    ``PsKernelSemantics.Declarative.no_allProps,
    ``PsKernelSemantics.Declarative.no_empty,
    ``PsKernelSemantics.SetModel.sort_inference_has_set_model,
    ``PsKernelSemantics.SetModel.zeta_has_set_model,
    ``PsKernelSemantics.SetModel.substitution_has_typed_set_model,
    ``PsKernelSemantics.SetModel.beta_has_set_model,
    ``PsKernelSemantics.SetModel.interp_extendConstant,
    ``PsKernelSemantics.SetModel.satisfies_extendConstant,
    ``PsKernelSemantics.SetModel.modelsType_extendConstant,
    ``PsKernelSemantics.SetModel.newConstant_modelsType,
    ``PsKernelSemantics.SetModel.exprEq_preserves_interp,
    ``PsKernelSemantics.AnnotatedExpr.erase_close,
    ``PsKernelSemantics.AnnotatedExpr.erase_abstractFVar,
    ``PsKernelSemantics.SetModel.interp_withFree_fresh,
    ``PsKernelSemantics.SetModel.interp_close,
    ``PsKernelSemantics.SetModel.open_fresh_has_reading,
    ``PsKernelSemantics.SetModel.abstractFVar_has_reading,
    ``PsKernelSemantics.SetModel.abstractFVar_closed_input,
    ``PsKernelSemantics.AnnotatedExpr.scoped_mono,
    ``PsKernelSemantics.AnnotatedExpr.scoped_liftN,
    ``PsKernelSemantics.AnnotatedExpr.scoped_inst,
    ``PsKernelSemantics.AnnotatedExpr.scoped_close,
    ``PsKernelSemantics.AnnotatedExpr.namesBelow_fresh,
    ``PsKernelSemantics.AnnotatedExpr.allocator_fresh,
    ``PsKernelSemantics.AnnotatedExpr.opened_has_no_loose,
    ``PsKernelSemantics.AnnotatedExpr.closed_has_one_binder,
    ``PsKernelSemantics.SetModel.membership_is_not_annotation_coherence,
    ``PsKernelSemantics.isZero_eval,
    ``PsKernelSemantics.isNotZero_eval,
    ``PsKernelSemantics.toOffset_eval,
    ``PsKernelSemantics.addOffset_eval,
    ``PsKernelSemantics.explicit_eval,
    ``PsKernelSemantics.mkMax_eval,
    ``PsKernelSemantics.mkIMax_eval,
    ``PsKernelSemantics.instantiateParams_eval,
    ``PsKernelSemantics.AnnotatedExpr.erase_instLevels,
    ``PsKernelSemantics.SetModel.interp_instLevels,
    ``PsKernelSemantics.SetModel.satisfies_instLevels,
    ``PsKernelSemantics.SetModel.modelsType_instLevels,
    ``PsKernelSemantics.SetModel.instantiateLevelParams_has_reading
  ]
  let allowed : Array Name := #[``propext, ``Classical.choice, ``Quot.sound]
  for target in targets do
    let used ← Lean.collectAxioms target
    for dependency in used do
      unless allowed.contains dependency do
        throwError "Unapproved axiom {dependency} in semantic declaration {target}"
  logInfo m!"PSKERNEL_SEMANTIC_AXIOMS: PASS declarations={targets.size}; local hypotheses remain explicit"
