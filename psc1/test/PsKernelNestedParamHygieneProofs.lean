import Lean
import Ps.KernelCore.Admission.Inductive.Nested.Rebase

namespace PsKernelNestedParamHygieneProofs
private theorem branches_false (a b : Bool) (h : (if a then true else b) = false) :
    a = false ∧ b = false := by cases a <;> simp_all

theorem capture_worker_false_for_every_closed_input (type : PsKernelExpr) :
    ∀ count, psKernelExprHasFVar type = false →
      psKernelSimpleNestedCtorParamCaptureWorker type count = false := by
  induction type with
  | bvar _ => intro count closed; rfl
  | mvar _ => intro count closed; rfl
  | sort _ => intro count closed; rfl
  | const _ _ => intro count closed; rfl
  | lit _ => intro count closed; rfl
  | fvar _ => intro count closed; simp only [psKernelExprHasFVar] at closed; cases closed
  | app fn arg ihFn ihArg =>
      intro count closed
      have h := branches_false (psKernelExprHasFVar fn) (psKernelExprHasFVar arg) closed
      simp only [psKernelSimpleNestedCtorParamCaptureWorker,ihFn count h.1,ihArg count h.2] <;> rfl
  | lam name domain body info ihDomain ihBody =>
      intro count closed
      have h := branches_false (psKernelExprHasFVar domain) (psKernelExprHasFVar body) closed
      simp only [psKernelSimpleNestedCtorParamCaptureWorker,ihDomain count h.1,ihBody count h.2] <;> rfl
  | forallE name domain body info ihDomain ihBody =>
      intro count closed
      have h := branches_false (psKernelExprHasFVar domain) (psKernelExprHasFVar body) closed
      simp only [psKernelSimpleNestedCtorParamCaptureWorker,ihDomain count h.1,ihBody count h.2] <;> rfl
  | letE name domain value body nondep ihDomain ihValue ihBody =>
      intro count closed
      have h := branches_false (psKernelExprHasFVar domain)
        (if psKernelExprHasFVar value then true else psKernelExprHasFVar body) closed
      have h2 := branches_false (psKernelExprHasFVar value) (psKernelExprHasFVar body) h.2
      simp only [psKernelSimpleNestedCtorParamCaptureWorker,ihDomain count h.1,
        ihValue count h2.1,ihBody count h2.2] <;> rfl
  | mdata tag body ih => intro count closed; exact ih count closed
  | proj name index body ih => intro count closed; exact ih count closed

theorem capture_guard_false_for_every_closed_input
    (type : PsKernelExpr) (count : Nat) (closed : psKernelExprHasFVar type = false) :
    psKernelSimpleNestedCtorParamCapture type count = false := by
  cases count with
  | zero => rfl
  | succ n => exact capture_worker_false_for_every_closed_input type (n+1) closed

theorem finish_keeps_original_shape_error_first
    (type : PsKernelExpr) (count : Nat) (error : String) :
    psKernelSimpleNestedFinishConstructorParams type count (.error error) = .error error := rfl

theorem finish_keeps_entire_success_when_no_capture
    (type : PsKernelExpr) (count : Nat) (opened : PsKernelSimpleNestedOpenParamsResult)
    (safe : psKernelSimpleNestedCtorParamCapture type count = false) :
    psKernelSimpleNestedFinishConstructorParams type count (.ok opened) = .ok opened := by
  simp only [psKernelSimpleNestedFinishConstructorParams,safe]

theorem opening_keeps_original_shape_and_budget_error
    (type : PsKernelExpr) (count : Nat) (error : String)
    (original : psKernelSimpleNestedOpenConstructorParamsWithFuel (count+1) type count 0 [] = .error error) :
    psKernelSimpleNestedOpenConstructorParams type count = .error error := by
  simp only [psKernelSimpleNestedOpenConstructorParams,original,
    psKernelSimpleNestedFinishConstructorParams]

theorem every_closed_input_keeps_exact_original_open_result
    (type : PsKernelExpr) (count : Nat) (closed : psKernelExprHasFVar type = false) :
    psKernelSimpleNestedOpenConstructorParams type count =
      psKernelSimpleNestedOpenConstructorParamsWithFuel (count+1) type count 0 [] := by
  have guard := capture_guard_false_for_every_closed_input type count closed
  cases h : psKernelSimpleNestedOpenConstructorParamsWithFuel (count+1) type count 0 [] <;>
    simp only [psKernelSimpleNestedOpenConstructorParams,h,
      psKernelSimpleNestedFinishConstructorParams,guard]

theorem zero_parameter_input_keeps_exact_original_result (type : PsKernelExpr) :
    psKernelSimpleNestedOpenConstructorParams type 0 =
      psKernelSimpleNestedOpenConstructorParamsWithFuel 1 type 0 0 [] := by
  cases h : psKernelSimpleNestedOpenConstructorParamsWithFuel 1 type 0 0 [] <;>
    simp only [psKernelSimpleNestedOpenConstructorParams,h,
      psKernelSimpleNestedFinishConstructorParams,psKernelSimpleNestedCtorParamCapture]

theorem successful_open_cannot_close_a_colliding_input_variable
    (type : PsKernelExpr) (count : Nat) (opened : PsKernelSimpleNestedOpenParamsResult)
    (original : psKernelSimpleNestedOpenConstructorParamsWithFuel (count+1) type count 0 [] = .ok opened)
    (capture : psKernelSimpleNestedCtorParamCapture type count = true) :
    psKernelSimpleNestedOpenConstructorParams type count = .error "declaration has free variables" := by
  simp only [psKernelSimpleNestedOpenConstructorParams,original,
    psKernelSimpleNestedFinishConstructorParams,capture]

theorem other_free_variable_namespaces_do_not_change_the_guard
    (parent : PsKernelName) (index count : Nat)
    (other : psKernelNameEq parent (psKernelSimpleInternalName "nestedCtorParam") = false) :
    psKernelSimpleNestedCtorParamCaptureWorker (.fvar (.num parent index)) count = false := by
  simp only [psKernelSimpleNestedCtorParamCaptureWorker,other]

theorem only_introduced_parameter_indices_are_capturable
    (parent : PsKernelName) (index count : Nat)
    (outside : Nat.ble (Nat.succ index) count = false) :
    psKernelSimpleNestedCtorParamCaptureWorker (.fvar (.num parent index)) count = false := by
  cases h : psKernelNameEq parent (psKernelSimpleInternalName "nestedCtorParam") <;>
    simp only [psKernelSimpleNestedCtorParamCaptureWorker,h,outside] <;> rfl

end PsKernelNestedParamHygieneProofs
#print axioms PsKernelNestedParamHygieneProofs.capture_worker_false_for_every_closed_input
#print axioms PsKernelNestedParamHygieneProofs.capture_guard_false_for_every_closed_input
#print axioms PsKernelNestedParamHygieneProofs.finish_keeps_original_shape_error_first
#print axioms PsKernelNestedParamHygieneProofs.finish_keeps_entire_success_when_no_capture
#print axioms PsKernelNestedParamHygieneProofs.opening_keeps_original_shape_and_budget_error
#print axioms PsKernelNestedParamHygieneProofs.every_closed_input_keeps_exact_original_open_result
#print axioms PsKernelNestedParamHygieneProofs.zero_parameter_input_keeps_exact_original_result
#print axioms PsKernelNestedParamHygieneProofs.successful_open_cannot_close_a_colliding_input_variable
#print axioms PsKernelNestedParamHygieneProofs.other_free_variable_namespaces_do_not_change_the_guard
#print axioms PsKernelNestedParamHygieneProofs.only_introduced_parameter_indices_are_capturable
