import Ps.KernelCore.API.DagMutualGenerated
import Lean

/- Local original-boundary/checked-owner syntax adapter equations. These
   component premises do not authenticate forged decoded tables, establish
   generated type correctness, or publish any mutual admission. -/
namespace PsKernelMutualGeneratedProofs

theorem empty_constructor_metadata_never_reads_input (input : PsKernelExprV2Decoded) :
    psKernelExprV2MutualDecodeConstructorDecls [] input = .ok [] := rfl

theorem constructor_metadata_head_error_precedes_tail
    (input : PsKernelExprV2Decoded) (first : PsKernelDagConstructor)
    (rest : List PsKernelDagConstructor) (error : String)
    (missing : psKernelExprV2DecodedRequire input first.type = .error error) :
    psKernelExprV2MutualDecodeConstructorDecls (first :: rest) input = .error error := by
  simp only [psKernelExprV2MutualDecodeConstructorDecls, missing]

theorem constructor_metadata_keeps_exact_original_root_and_order
    (input : PsKernelExprV2Decoded) (first : PsKernelDagConstructor)
    (rest : List PsKernelDagConstructor) (type : PsKernelExpr)
    (tail : List PsKernelSimpleConstructorDecl)
    (found : psKernelExprV2DecodedRequire input first.type = .ok type)
    (decoded : psKernelExprV2MutualDecodeConstructorDecls rest input = .ok tail) :
    psKernelExprV2MutualDecodeConstructorDecls (first :: rest) input =
      .ok (PsKernelSimpleConstructorDecl.mk first.name type :: tail) := by
  simp only [psKernelExprV2MutualDecodeConstructorDecls, found, decoded]

theorem type_original_input_error_precedes_constructors_and_opened_indices
    (input built : PsKernelExprV2Decoded) (header : PsKernelExprV2MutualTypeHeader)
    (error : String)
    (missing : psKernelExprV2DecodedRequire input header.declaration.type = .error error) :
    psKernelExprV2MutualDecodeTypeHeader input built header = .error error := by
  simp only [psKernelExprV2MutualDecodeTypeHeader, missing]

theorem recursive_field_error_precedes_arguments_and_indices
    (built : PsKernelExprV2Decoded) (field : PsKernelExprV2MutualRecursiveField)
    (error : String)
    (missing : psKernelExprV2OrdinaryDecodeBinder built field.field = .error error) :
    psKernelExprV2MutualDecodeRecursiveField built field = .error error := by
  simp only [psKernelExprV2MutualDecodeRecursiveField, missing]

theorem recursive_field_preserves_target_and_all_checked_binders
    (built : PsKernelExprV2Decoded) (value : PsKernelExprV2MutualRecursiveField)
    (field : PsKernelOpenBinder) (arguments : List PsKernelOpenBinder) (indices : List PsKernelExpr)
    (a : psKernelExprV2OrdinaryDecodeBinder built value.field = .ok field)
    (b : psKernelExprV2OrdinaryDecodeBinders value.arguments built = .ok arguments)
    (c : psKernelExprV2OrdinaryDecodeIds value.indices built = .ok indices) :
    psKernelExprV2MutualDecodeRecursiveField built value =
      .ok (PsKernelSimpleMutualRecursiveField.mk field arguments value.target indices) := by
  simp only [psKernelExprV2MutualDecodeRecursiveField, a, b, c]

theorem shape_original_input_error_precedes_opened_fields
    (input built : PsKernelExprV2Decoded) (shape : PsKernelExprV2MutualConstructorShape)
    (error : String) (missing : psKernelExprV2DecodedRequire input shape.ctor.type = .error error) :
    psKernelExprV2MutualDecodeConstructorShape input built shape = .error error := by
  simp only [psKernelExprV2MutualDecodeConstructorShape, missing]

theorem shape_preserves_owner_original_metadata_and_checked_opened_ids
    (input built : PsKernelExprV2Decoded) (shape : PsKernelExprV2MutualConstructorShape)
    (type : PsKernelExpr) (fields : List PsKernelOpenBinder)
    (recursiveFields : List PsKernelSimpleMutualRecursiveField) (indices : List PsKernelExpr)
    (a : psKernelExprV2DecodedRequire input shape.ctor.type = .ok type)
    (b : psKernelExprV2OrdinaryDecodeBinders shape.fields built = .ok fields)
    (c : psKernelExprV2MutualDecodeRecursiveFields shape.recursiveFields built = .ok recursiveFields)
    (d : psKernelExprV2OrdinaryDecodeIds shape.resultIndices built = .ok indices) :
    psKernelExprV2MutualDecodeConstructorShape input built shape =
      .ok (PsKernelSimpleMutualConstructorShape.mk shape.owner
        (PsKernelSimpleConstructorDecl.mk shape.ctor.name type) fields recursiveFields indices) := by
  simp only [psKernelExprV2MutualDecodeConstructorShape, a, b, c, d]

theorem data_parameter_error_precedes_type_and_constructor_metadata
    (input built : PsKernelExprV2Decoded) (header : PsKernelExprV2MutualHeaderAnalysis)
    (shapes : List PsKernelExprV2MutualConstructorShape) (error : String)
    (missing : psKernelExprV2OrdinaryDecodeBinders header.parameters.binders built = .error error) :
    psKernelExprV2MutualDecodeRecursorData input built header shapes = .error error := by
  simp only [psKernelExprV2MutualDecodeRecursorData, missing]

theorem data_success_retains_all_component_order_and_values
    (input built : PsKernelExprV2Decoded) (header : PsKernelExprV2MutualHeaderAnalysis)
    (shapes : List PsKernelExprV2MutualConstructorShape)
    (parameters : List PsKernelOpenBinder) (types : List PsKernelSimpleMutualTypeShape)
    (constructors : List PsKernelSimpleMutualConstructorShape)
    (a : psKernelExprV2OrdinaryDecodeBinders header.parameters.binders built = .ok parameters)
    (b : psKernelExprV2MutualDecodeTypeHeaders header.types input built = .ok types)
    (c : psKernelExprV2MutualDecodeConstructorShapes shapes input built = .ok constructors) :
    psKernelExprV2MutualDecodeRecursorData input built header shapes =
      .ok (PsKernelExprV2MutualRecursorData.mk parameters types constructors) := by
  simp only [psKernelExprV2MutualDecodeRecursorData, a, b, c]

theorem type_names_are_exact_original_family_order (types : List PsKernelSimpleMutualTypeShape) :
    psKernelExprV2MutualLegacyTypeNames types =
      psKernelSimpleMutualNames (types.map (fun shape => shape.decl)) := by
  induction types with
  | nil => rfl
  | cons first rest ih =>
      simp only [psKernelExprV2MutualLegacyTypeNames, List.map, psKernelSimpleMutualNames]
      exact congrArg (List.cons first.decl.name) ih

theorem expected_rule_motive_error_precedes_closing
    (plan : PsKernelExprV2MutualRecursorPlan) (owner : Nat)
    (shape : PsKernelSimpleMutualConstructorShape) (error : String)
    (failed : psKernelSimpleMutualMotiveApp plan.motives owner shape.resultIndices
      (psKernelSimpleMutualCtorApp plan.levels plan.data.parameters shape) = .error error) :
    psKernelExprV2MutualExpectedRuleType plan owner shape = .error error := by
  simp only [psKernelExprV2MutualExpectedRuleType, failed]

theorem expected_rule_closes_exact_original_rule_binders_and_fields
    (plan : PsKernelExprV2MutualRecursorPlan) (owner : Nat)
    (shape : PsKernelSimpleMutualConstructorShape) (result : PsKernelExpr)
    (found : psKernelSimpleMutualMotiveApp plan.motives owner shape.resultIndices
      (psKernelSimpleMutualCtorApp plan.levels plan.data.parameters shape) = .ok result) :
    psKernelExprV2MutualExpectedRuleType plan owner shape =
      .ok (psKernelCloseOpenBinders (psKernelOpenBinderListAppend plan.ruleBinders shape.fields) result) := by
  simp only [psKernelExprV2MutualExpectedRuleType, found]

theorem expected_rule_error_precedes_generated_syntax_import
    (plan : PsKernelExprV2MutualRecursorPlan) (owner : Nat)
    (shape : PsKernelSimpleMutualConstructorShape) (state : PsKernelExprV2CheckState)
    (built : PsKernelExprV2Decoded) (error : String)
    (failed : psKernelExprV2MutualExpectedRuleType plan owner shape = .error error) :
    psKernelExprV2MutualPrepareExpectedRuleType plan owner shape state built = .error error := by
  simp only [psKernelExprV2MutualPrepareExpectedRuleType, failed]

theorem expected_rule_success_imports_only_expected_generated_syntax
    (plan : PsKernelExprV2MutualRecursorPlan) (owner : Nat)
    (shape : PsKernelSimpleMutualConstructorShape) (state : PsKernelExprV2CheckState)
    (built : PsKernelExprV2Decoded) (type : PsKernelExpr)
    (found : psKernelExprV2MutualExpectedRuleType plan owner shape = .ok type) :
    psKernelExprV2MutualPrepareExpectedRuleType plan owner shape state built =
      psKernelExprV2OrdinaryImportGenerated type state built := by
  simp only [psKernelExprV2MutualPrepareExpectedRuleType, found]

#print axioms empty_constructor_metadata_never_reads_input
#print axioms constructor_metadata_head_error_precedes_tail
#print axioms constructor_metadata_keeps_exact_original_root_and_order
#print axioms type_original_input_error_precedes_constructors_and_opened_indices
#print axioms recursive_field_error_precedes_arguments_and_indices
#print axioms recursive_field_preserves_target_and_all_checked_binders
#print axioms shape_original_input_error_precedes_opened_fields
#print axioms shape_preserves_owner_original_metadata_and_checked_opened_ids
#print axioms data_parameter_error_precedes_type_and_constructor_metadata
#print axioms data_success_retains_all_component_order_and_values
#print axioms type_names_are_exact_original_family_order
#print axioms expected_rule_motive_error_precedes_closing
#print axioms expected_rule_closes_exact_original_rule_binders_and_fields
#print axioms expected_rule_error_precedes_generated_syntax_import
#print axioms expected_rule_success_imports_only_expected_generated_syntax
end PsKernelMutualGeneratedProofs
