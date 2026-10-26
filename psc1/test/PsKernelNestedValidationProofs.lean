import Lean
import Ps.KernelCore.API.DagNestedValidation

namespace PsKernelNestedValidationProofs
/- Callback and ownership protocols, not a global soundness theorem. -/
variable (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
  Option (Except String (Prod PsKernelExprV2CheckState Nat)))

theorem empty_rule_list_retains_complete_checking_state
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) :
    psKernelExprV2NestedValidateRulesWith check [] fuel context state = some (.ok state) := rfl

theorem rule_decline_never_restarts_or_validates_tail
    (rule : PsKernelExprV2RecursorRuleRef) (rest : List PsKernelExprV2RecursorRuleRef)
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (declined : check fuel context state rule.rhs = none) :
    psKernelExprV2NestedValidateRulesWith check (rule::rest) fuel context state = none := by
  simp only [psKernelExprV2NestedValidateRulesWith,declined]

theorem rule_hard_error_keeps_exact_error_and_no_owner
    (rule : PsKernelExprV2RecursorRuleRef) (rest : List PsKernelExprV2RecursorRuleRef)
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (error : String) (failed : check fuel context state rule.rhs = some (.error error)) :
    psKernelExprV2NestedValidateRulesWith check (rule::rest) fuel context state = some (.error error) := by
  simp only [psKernelExprV2NestedValidateRulesWith,failed]

theorem rule_success_passes_the_complete_returned_owner_to_next_rule
    (rule : PsKernelExprV2RecursorRuleRef) (rest : List PsKernelExprV2RecursorRuleRef)
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (state next : PsKernelExprV2CheckState)
    (type : Nat) (checked : check fuel context state rule.rhs = some (.ok (next,type))) :
    psKernelExprV2NestedValidateRulesWith check (rule::rest) fuel context state =
      psKernelExprV2NestedValidateRulesWith check rest fuel context next := by
  simp only [psKernelExprV2NestedValidateRulesWith,checked]

theorem empty_template_list_retains_entire_owner
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (owner : PsKernelDagGeneratedState) :
    psKernelExprV2NestedValidateTemplatesWith check whnf [] fuel context owner = some (.ok owner) := rfl

theorem empty_constructor_list_retains_entire_owner
    (fuel : Nat) (environment : PsKernelEnvironment) (context : PsKernelExprV2CheckContext)
    (owner : PsKernelDagGeneratedState) :
    psKernelExprV2NestedValidateConstructorsWith check whnf [] fuel environment context owner = some (.ok owner) := rfl

theorem type_decline_never_restarts_or_checks_sort_or_rules
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (owner : PsKernelDagGeneratedState)
    (root : Nat) (sortRequired : Bool) (rules : List PsKernelExprV2RecursorRuleRef)
    (declined : check fuel context (psKernelExprV2OrdinaryFreshState owner) root = none) :
    psKernelExprV2NestedValidateTypeWith check whnf fuel context owner root sortRequired rules = none := by
  simp only [psKernelExprV2NestedValidateTypeWith,declined]

theorem type_hard_error_precedes_sort_and_rule_callbacks
    (fuel : Nat) (context : PsKernelExprV2CheckContext) (owner : PsKernelDagGeneratedState)
    (root : Nat) (sortRequired : Bool) (rules : List PsKernelExprV2RecursorRuleRef) (error : String)
    (failed : check fuel context (psKernelExprV2OrdinaryFreshState owner) root = some (.error error)) :
    psKernelExprV2NestedValidateTypeWith check whnf fuel context owner root sortRequired rules = some (.error error) := by
  simp only [psKernelExprV2NestedValidateTypeWith,failed]

end PsKernelNestedValidationProofs
#print axioms PsKernelNestedValidationProofs.empty_rule_list_retains_complete_checking_state
#print axioms PsKernelNestedValidationProofs.rule_decline_never_restarts_or_validates_tail
#print axioms PsKernelNestedValidationProofs.rule_hard_error_keeps_exact_error_and_no_owner
#print axioms PsKernelNestedValidationProofs.rule_success_passes_the_complete_returned_owner_to_next_rule
#print axioms PsKernelNestedValidationProofs.empty_template_list_retains_entire_owner
#print axioms PsKernelNestedValidationProofs.empty_constructor_list_retains_entire_owner
#print axioms PsKernelNestedValidationProofs.type_decline_never_restarts_or_checks_sort_or_rules
#print axioms PsKernelNestedValidationProofs.type_hard_error_precedes_sort_and_rule_callbacks
