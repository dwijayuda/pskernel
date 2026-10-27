import Lean
import Ps.KernelCore.API.DagNestedRestoration

namespace PsKernelNestedRestorationProofs
/- Private syntax/owner protocols only. Independent restored validation remains
   mandatory; no theorem here establishes global source correspondence. -/
theorem no_rename_retains_original_name (name : PsKernelName) :
    psKernelExprV2NestedRestoredOriginName name [] = name := rfl

theorem matching_rename_selects_actual_transformed_origin (oldName name : PsKernelName)
    (rest : List (Prod PsKernelName PsKernelName)) (same : psKernelNameEq name name = true) :
    psKernelExprV2NestedRestoredOriginName name ((oldName,name)::rest) = oldName := by
  simp only [psKernelExprV2NestedRestoredOriginName,same];rfl

theorem empty_rule_list_preserves_exact_owner (owner : PsKernelDagGeneratedState)
    (origins : List PsKernelExprV2RecursorRuleRef) :
    psKernelExprV2NestedRestoreRules [] origins owner = .ok (owner,[]) := rfl

theorem empty_prefix_preserves_exact_owner (base : PsKernelEnvironment)
    (origins : List PsKernelExprV2DeclarationRef) (renames : List (Prod PsKernelName PsKernelName))
    (owner : PsKernelDagGeneratedState) :
    psKernelExprV2NestedRestorePrefix [] base origins renames owner = .ok owner := rfl

theorem retained_base_constant_never_reimports_its_type
    (info : PsKernelConstantInfo) (rest : List PsKernelConstantInfo) (base : PsKernelEnvironment)
    (origins : List PsKernelExprV2DeclarationRef) (renames : List (Prod PsKernelName PsKernelName))
    (owner : PsKernelDagGeneratedState)
    (present : psKernelEnvironmentContains base (psKernelConstantInfoName info) = true) :
    psKernelExprV2NestedRestorePrefix (info::rest) base origins renames owner =
      psKernelExprV2NestedRestorePrefix rest base origins renames owner := by
  simp only [psKernelExprV2NestedRestorePrefix,present];rfl

theorem existing_origin_uses_exact_id_preserving_overlay
    (type : PsKernelExpr) (origin : PsKernelExprV2DeclarationRef) (owner : PsKernelDagGeneratedState) :
    psKernelExprV2NestedRestoreType type (some origin) owner =
      psKernelExprV2NestedOverlay type origin.type owner := rfl

theorem missing_origin_uses_existing_generated_syntax_importer
    (type : PsKernelExpr) (owner : PsKernelDagGeneratedState) :
    psKernelExprV2NestedRestoreType type none owner = psKernelDagGeneratedImport type owner := rfl

theorem failed_restoration_returns_no_private_owner
    (base : PsKernelEnvironment) (originalOwner : PsKernelDagGeneratedState)
    (checked : PsKernelExprV2NestedCheckedTransformed) (error : String)
    (failed : psKernelExprV2NestedRestoreEnvironment base checked = .error error) :
    psKernelExprV2NestedRestore base originalOwner checked = .error error := by
  simp only [psKernelExprV2NestedRestore,failed]

end PsKernelNestedRestorationProofs
#print axioms PsKernelNestedRestorationProofs.no_rename_retains_original_name
#print axioms PsKernelNestedRestorationProofs.matching_rename_selects_actual_transformed_origin
#print axioms PsKernelNestedRestorationProofs.empty_rule_list_preserves_exact_owner
#print axioms PsKernelNestedRestorationProofs.empty_prefix_preserves_exact_owner
#print axioms PsKernelNestedRestorationProofs.retained_base_constant_never_reimports_its_type
#print axioms PsKernelNestedRestorationProofs.existing_origin_uses_exact_id_preserving_overlay
#print axioms PsKernelNestedRestorationProofs.missing_origin_uses_existing_generated_syntax_importer
#print axioms PsKernelNestedRestorationProofs.failed_restoration_returns_no_private_owner
