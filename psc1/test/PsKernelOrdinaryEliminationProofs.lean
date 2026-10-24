import Ps.KernelCore.API.DagOrdinaryElimination
import Ps.KernelCore.Admission.Inductive.Common.Elimination

/- Native component equations for the private elimination policy.
   The membership correspondence lifts explicit pointwise comparison premises;
   it does not certify arbitrary arenas or cached hashes. Production callers
   supply the established canonical owner and already checked constructor types.
   Callback equations describe sequencing and owner transfer, not correctness
   of an arbitrary injected checker. The phase returns only Bool and publishes
   neither a checking owner nor an inductive/recursor admission result. -/

namespace PsKernelOrdinaryEliminationProofs

abbrev CheckCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
  Option (Except String (Prod PsKernelExprV2CheckState Nat))

abbrev DefEqCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
  Option (Except String (Prod PsKernelExprV2CheckState Bool))

variable (arena : PsKernelExprV2PagedArena)

theorem member_nil (needle : Nat) :
    psKernelExprV2OrdinaryEliminationMember arena needle List.nil = Except.ok false := by
  rfl

theorem member_cons_equation (needle value : Nat) (rest : List Nat) :
    psKernelExprV2OrdinaryEliminationMember arena needle (List.cons value rest) =
    (match psKernelExprV2PagedEqOnCanonical arena needle value with
    | Except.error error => Except.error error
    | Except.ok equal =>
        if equal then Except.ok true
        else psKernelExprV2OrdinaryEliminationMember arena needle rest) := by
  rfl

theorem all_members_nil (haystack : List Nat) :
    psKernelExprV2OrdinaryEliminationAllMembers arena List.nil haystack = Except.ok true := by
  rfl

theorem all_members_cons_equation (value : Nat) (rest haystack : List Nat) :
    psKernelExprV2OrdinaryEliminationAllMembers arena (List.cons value rest) haystack =
    (match psKernelExprV2OrdinaryEliminationMember arena value haystack with
    | Except.error error => Except.error error
    | Except.ok found =>
        if found then psKernelExprV2OrdinaryEliminationAllMembers arena rest haystack
        else Except.ok false) := by
  rfl

theorem member_lifts_pointwise_structural_equality
    (decode : Nat -> PsKernelExpr) (needle : Nat) (values : List Nat)
    (compared : ∀ value, value ∈ values ->
      psKernelExprV2PagedEqOnCanonical arena needle value =
        Except.ok (psKernelExprEq (decode needle) (decode value))) :
    psKernelExprV2OrdinaryEliminationMember arena needle values =
      Except.ok (psKernelSimpleExprMember (decode needle) (values.map decode)) := by
  revert compared
  induction values with
  | nil =>
      intro compared
      rfl
  | cons value rest ih =>
      intro compared
      have head := compared value (by simp)
      have tail : ∀ next, next ∈ rest ->
          psKernelExprV2PagedEqOnCanonical arena needle next =
            Except.ok (psKernelExprEq (decode needle) (decode next)) := by
        intro next present
        exact compared next (by simp [present])
      cases result : psKernelExprEq (decode needle) (decode value) <;>
        simp [member_cons_equation, head, result,
          psKernelSimpleExprMember, ih tail]

theorem all_members_lifts_pointwise_membership
    (decode : Nat -> PsKernelExpr) (values haystack : List Nat)
    (compared : ∀ value, value ∈ values ->
      psKernelExprV2OrdinaryEliminationMember arena value haystack =
        Except.ok (psKernelSimpleExprMember (decode value) (haystack.map decode))) :
    psKernelExprV2OrdinaryEliminationAllMembers arena values haystack =
      Except.ok (psKernelSimpleAllExprsMember (values.map decode) (haystack.map decode)) := by
  revert compared
  induction values with
  | nil =>
      intro compared
      rfl
  | cons value rest ih =>
      intro compared
      have head := compared value (by simp)
      have tail : ∀ next, next ∈ rest ->
          psKernelExprV2OrdinaryEliminationMember arena next haystack =
            Except.ok (psKernelSimpleExprMember (decode next) (haystack.map decode)) := by
        intro next present
        exact compared next (by simp [present])
      cases result : psKernelSimpleExprMember (decode value) (haystack.map decode) <;>
        simp [all_members_cons_equation, head, result,
          psKernelSimpleAllExprsMember, ih tail]

variable
  (check whnf : CheckCallback) (defeq : DefEqCallback)
  (fuel : Nat) (context : PsKernelExprV2CheckContext)
  (state : PsKernelExprV2CheckState)
  (userName : PsKernelName) (domain body : Nat)
  (binderInfo : PsKernelBinderInfo) (revNonProp : List Nat)

theorem after_sort_annotation_error_precedes_allocation
    (sorted : Prod PsKernelExprV2CheckState PsKernelLevel) (message : String)
    (annotated : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      (Prod.fst sorted).whnf.arena domain = Except.error message) :
    psKernelExprV2OrdinaryEliminationAfterSort
      context sorted userName domain body binderInfo revNonProp = Except.error message := by
  simp only [psKernelExprV2OrdinaryEliminationAfterSort, annotated]

theorem after_sort_keeps_owner_actual_fvar_and_original_body
    (sorted : Prod PsKernelExprV2CheckState PsKernelLevel)
    (localDomain : Nat) (fresh : PsKernelName) (next : PsKernelExprV2CheckState)
    (varArena bodyArena : PsKernelExprV2PagedArena) (varId bodyId : Nat)
    (annotated : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      (Prod.fst sorted).whnf.arena domain = Except.ok localDomain)
    (freshened : psKernelExprV2CheckStateFreshName (Prod.fst sorted) userName =
      Prod.mk fresh next)
    (allocated : psKernelExprV2PagedMkFVar next.whnf.arena fresh =
      Except.ok (Prod.mk varArena varId))
    (instantiated : psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons varId List.nil))
      varArena body 0 = Except.ok (Prod.mk bodyArena bodyId)) :
    psKernelExprV2OrdinaryEliminationAfterSort
      context sorted userName domain body binderInfo revNonProp =
    Except.ok
      (PsKernelExprV2OrdinaryEliminationStep.mk
        (psKernelExprV2CheckContextWithLocal context fresh userName localDomain binderInfo)
        (psKernelExprV2CheckStateWithArena next bodyArena) bodyId
        (if psKernelLevelNormalizesToZero (Prod.snd sorted) then revNonProp
         else List.cons varId revNonProp)) := by
  simp only [psKernelExprV2OrdinaryEliminationAfterSort,
    annotated, freshened, allocated, instantiated]

theorem step_check_decline_precedes_sort
    (checked : check fuel context state domain = Option.none) :
    psKernelExprV2OrdinaryEliminationStepWith
      check whnf fuel context state userName domain body binderInfo revNonProp = Option.none := by
  simp only [psKernelExprV2OrdinaryEliminationStepWith, checked]

theorem step_check_error_precedes_sort
    (message : String)
    (checked : check fuel context state domain = Option.some (Except.error message)) :
    psKernelExprV2OrdinaryEliminationStepWith
      check whnf fuel context state userName domain body binderInfo revNonProp =
    Option.some (Except.error message) := by
  simp only [psKernelExprV2OrdinaryEliminationStepWith, checked]

theorem step_sort_decline_uses_complete_checked_owner
    (next : PsKernelExprV2CheckState) (type : Nat)
    (checked : check fuel context state domain = Option.some (Except.ok (Prod.mk next type)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context next type = Option.none) :
    psKernelExprV2OrdinaryEliminationStepWith
      check whnf fuel context state userName domain body binderInfo revNonProp = Option.none := by
  simp only [psKernelExprV2OrdinaryEliminationStepWith, checked, sorted]

theorem step_sort_error_uses_complete_checked_owner
    (next : PsKernelExprV2CheckState) (type : Nat) (message : String)
    (checked : check fuel context state domain = Option.some (Except.ok (Prod.mk next type)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context next type = Option.some (Except.error message)) :
    psKernelExprV2OrdinaryEliminationStepWith
      check whnf fuel context state userName domain body binderInfo revNonProp =
    Option.some (Except.error message) := by
  simp only [psKernelExprV2OrdinaryEliminationStepWith, checked, sorted]

theorem step_success_passes_sorted_owner_and_original_domain
    (next : PsKernelExprV2CheckState) (type : Nat)
    (sortedOwner : Prod PsKernelExprV2CheckState PsKernelLevel)
    (checked : check fuel context state domain = Option.some (Except.ok (Prod.mk next type)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context next type = Option.some (Except.ok sortedOwner)) :
    psKernelExprV2OrdinaryEliminationStepWith
      check whnf fuel context state userName domain body binderInfo revNonProp =
    Option.some (psKernelExprV2OrdinaryEliminationAfterSort
      context sortedOwner userName domain body binderInfo revNonProp) := by
  simp only [psKernelExprV2OrdinaryEliminationStepWith, checked, sorted]

theorem worker_zero_precedes_every_callback (type : Nat) :
    psKernelExprV2OrdinaryCtorAllowsLargeElimWorker 0
      check whnf context state type revNonProp =
    Option.some (Except.error "simple inductive elimination budget exhausted") := by
  rfl

theorem worker_whnf_decline_uses_predecessor (type : Nat)
    (reduced : whnf fuel context state type = Option.none) :
    psKernelExprV2OrdinaryCtorAllowsLargeElimWorker (Nat.succ fuel)
      check whnf context state type revNonProp = Option.none := by
  simp only [psKernelExprV2OrdinaryCtorAllowsLargeElimWorker, reduced]

theorem worker_whnf_error_precedes_lookup (type : Nat) (message : String)
    (reduced : whnf fuel context state type = Option.some (Except.error message)) :
    psKernelExprV2OrdinaryCtorAllowsLargeElimWorker (Nat.succ fuel)
      check whnf context state type revNonProp = Option.some (Except.error message) := by
  simp only [psKernelExprV2OrdinaryCtorAllowsLargeElimWorker, reduced]

theorem worker_lookup_error_uses_returned_arena
    (type root : Nat) (next : PsKernelExprV2CheckState) (message : String)
    (reduced : whnf fuel context state type = Option.some (Except.ok (Prod.mk next root)))
    (found : psKernelExprV2PagedRequire next.whnf.arena root = Except.error message) :
    psKernelExprV2OrdinaryCtorAllowsLargeElimWorker (Nat.succ fuel)
      check whnf context state type revNonProp = Option.some (Except.error message) := by
  simp only [psKernelExprV2OrdinaryCtorAllowsLargeElimWorker, reduced, found]

theorem worker_forall_composes_predecessor_step_and_complete_owner
    (type root : Nat) (next : PsKernelExprV2CheckState) (entry : PsKernelExprV2Entry)
    (reduced : whnf fuel context state type = Option.some (Except.ok (Prod.mk next root)))
    (found : psKernelExprV2PagedRequire next.whnf.arena root = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo) :
    psKernelExprV2OrdinaryCtorAllowsLargeElimWorker (Nat.succ fuel)
      check whnf context state type revNonProp =
    (match psKernelExprV2OrdinaryEliminationStepWith
        check whnf fuel context next userName domain body binderInfo revNonProp with
    | Option.none => Option.none
    | Option.some attempted =>
        match attempted with
        | Except.error error => Option.some (Except.error error)
        | Except.ok step =>
            psKernelExprV2OrdinaryCtorAllowsLargeElimWorker fuel
              check whnf step.context step.state step.body step.revNonProp) := by
  cases stepped : psKernelExprV2OrdinaryEliminationStepWith
      check whnf fuel context next userName domain body binderInfo revNonProp with
  | none =>
      simp only [psKernelExprV2OrdinaryCtorAllowsLargeElimWorker,
        reduced, found, node, stepped]
  | some attempted =>
      cases attempted with
      | error error =>
          simp only [psKernelExprV2OrdinaryCtorAllowsLargeElimWorker,
            reduced, found, node, stepped]
      | ok step =>
          simp only [psKernelExprV2OrdinaryCtorAllowsLargeElimWorker,
            reduced, found, node, stepped]

theorem worker_terminal_membership_uses_reduced_owner_and_all_arguments
    (type root : Nat) (next : PsKernelExprV2CheckState) (entry : PsKernelExprV2Entry)
    (head : Nat) (arguments : List Nat)
    (reduced : whnf fuel context state type = Option.some (Except.ok (Prod.mk next root)))
    (found : psKernelExprV2PagedRequire next.whnf.arena root = Except.ok entry)
    (notForall : ∀ name dom cod info,
      entry.node ≠ PsKernelExprV2Node.forallE name dom cod info)
    (spine : psKernelExprV2TransformAppSpineOnCanonical next.whnf.arena root =
      Except.ok (Prod.mk head arguments)) :
    psKernelExprV2OrdinaryCtorAllowsLargeElimWorker (Nat.succ fuel)
      check whnf context state type revNonProp =
    Option.some (psKernelExprV2OrdinaryEliminationAllMembers
      next.whnf.arena revNonProp arguments) := by
  cases node : entry.node <;>
    first
    | exact False.elim (notForall _ _ _ _ node)
    | simp only [psKernelExprV2OrdinaryCtorAllowsLargeElimWorker,
        reduced, found, node, spine]

variable (parameters : List PsKernelExprV2OrdinaryOpenBinder) (type : Nat)

theorem parameter_decline_precedes_telescope_whnf
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq fuel context state parameters type = Option.none) :
    psKernelExprV2OrdinaryCtorAllowsLargeElimWith
      check whnf defeq fuel context state parameters type = Option.none := by
  simp only [psKernelExprV2OrdinaryCtorAllowsLargeElimWith, opened]

theorem parameter_error_precedes_telescope_whnf
    (message : String)
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq fuel context state parameters type = Option.some (Except.error message)) :
    psKernelExprV2OrdinaryCtorAllowsLargeElimWith
      check whnf defeq fuel context state parameters type =
    Option.some (Except.error message) := by
  simp only [psKernelExprV2OrdinaryCtorAllowsLargeElimWith, opened]

theorem parameter_success_preserves_owner_and_adds_one_worker_step
    (next : PsKernelExprV2CheckState) (bodyId : Nat)
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq fuel context state parameters type = Option.some (Except.ok (Prod.mk next bodyId))) :
    psKernelExprV2OrdinaryCtorAllowsLargeElimWith
      check whnf defeq fuel context state parameters type =
    psKernelExprV2OrdinaryCtorAllowsLargeElimWorker (Nat.succ fuel)
      check whnf context next bodyId List.nil := by
  simp only [psKernelExprV2OrdinaryCtorAllowsLargeElimWith, opened]

variable (resultLevel : PsKernelLevel)

theorem policy_nonprop_shortcut
    (ctors : List PsKernelDagConstructor)
    (nonzero : psKernelLevelIsNotZero resultLevel = true) :
    psKernelExprV2OrdinaryElimOnlyAtZeroWith
      check whnf defeq fuel context state parameters resultLevel ctors =
    Option.some (Except.ok false) := by
  simp [psKernelExprV2OrdinaryElimOnlyAtZeroWith, nonzero]

theorem policy_empty_shortcut :
    psKernelExprV2OrdinaryElimOnlyAtZeroWith
      check whnf defeq fuel context state parameters resultLevel List.nil =
    Option.some (Except.ok false) := by
  cases nonzero : psKernelLevelIsNotZero resultLevel <;>
    simp [psKernelExprV2OrdinaryElimOnlyAtZeroWith, nonzero]

theorem policy_multiple_shortcut
    (first second : PsKernelDagConstructor) (rest : List PsKernelDagConstructor)
    (notNonzero : psKernelLevelIsNotZero resultLevel = false) :
    psKernelExprV2OrdinaryElimOnlyAtZeroWith
      check whnf defeq fuel context state parameters resultLevel
      (List.cons first (List.cons second rest)) =
    Option.some (Except.ok true) := by
  simp [psKernelExprV2OrdinaryElimOnlyAtZeroWith, notNonzero]

theorem policy_singleton_composition_preserves_decline_error_and_negation
    (ctor : PsKernelDagConstructor)
    (notNonzero : psKernelLevelIsNotZero resultLevel = false) :
    psKernelExprV2OrdinaryElimOnlyAtZeroWith
      check whnf defeq fuel context state parameters resultLevel (List.cons ctor List.nil) =
    (match psKernelExprV2OrdinaryCtorAllowsLargeElimWith
        check whnf defeq fuel context state parameters ctor.type with
    | Option.none => Option.none
    | Option.some attempted =>
        match attempted with
        | Except.error error => Option.some (Except.error error)
        | Except.ok canLarge =>
            if canLarge then Option.some (Except.ok false)
            else Option.some (Except.ok true)) := by
  cases analyzed : psKernelExprV2OrdinaryCtorAllowsLargeElimWith
      check whnf defeq fuel context state parameters ctor.type with
  | none =>
      simp [psKernelExprV2OrdinaryElimOnlyAtZeroWith, notNonzero, analyzed]
  | some attempted =>
      cases attempted with
      | error error =>
          simp [psKernelExprV2OrdinaryElimOnlyAtZeroWith, notNonzero, analyzed]
      | ok canLarge =>
          cases canLarge <;>
            simp [psKernelExprV2OrdinaryElimOnlyAtZeroWith, notNonzero, analyzed]

end PsKernelOrdinaryEliminationProofs

#print axioms PsKernelOrdinaryEliminationProofs.member_nil
#print axioms PsKernelOrdinaryEliminationProofs.member_cons_equation
#print axioms PsKernelOrdinaryEliminationProofs.all_members_nil
#print axioms PsKernelOrdinaryEliminationProofs.all_members_cons_equation
#print axioms PsKernelOrdinaryEliminationProofs.member_lifts_pointwise_structural_equality
#print axioms PsKernelOrdinaryEliminationProofs.all_members_lifts_pointwise_membership
#print axioms PsKernelOrdinaryEliminationProofs.after_sort_annotation_error_precedes_allocation
#print axioms PsKernelOrdinaryEliminationProofs.after_sort_keeps_owner_actual_fvar_and_original_body
#print axioms PsKernelOrdinaryEliminationProofs.step_check_decline_precedes_sort
#print axioms PsKernelOrdinaryEliminationProofs.step_check_error_precedes_sort
#print axioms PsKernelOrdinaryEliminationProofs.step_sort_decline_uses_complete_checked_owner
#print axioms PsKernelOrdinaryEliminationProofs.step_sort_error_uses_complete_checked_owner
#print axioms PsKernelOrdinaryEliminationProofs.step_success_passes_sorted_owner_and_original_domain
#print axioms PsKernelOrdinaryEliminationProofs.worker_zero_precedes_every_callback
#print axioms PsKernelOrdinaryEliminationProofs.worker_whnf_decline_uses_predecessor
#print axioms PsKernelOrdinaryEliminationProofs.worker_whnf_error_precedes_lookup
#print axioms PsKernelOrdinaryEliminationProofs.worker_lookup_error_uses_returned_arena
#print axioms PsKernelOrdinaryEliminationProofs.worker_forall_composes_predecessor_step_and_complete_owner
#print axioms PsKernelOrdinaryEliminationProofs.worker_terminal_membership_uses_reduced_owner_and_all_arguments
#print axioms PsKernelOrdinaryEliminationProofs.parameter_decline_precedes_telescope_whnf
#print axioms PsKernelOrdinaryEliminationProofs.parameter_error_precedes_telescope_whnf
#print axioms PsKernelOrdinaryEliminationProofs.parameter_success_preserves_owner_and_adds_one_worker_step
#print axioms PsKernelOrdinaryEliminationProofs.policy_nonprop_shortcut
#print axioms PsKernelOrdinaryEliminationProofs.policy_empty_shortcut
#print axioms PsKernelOrdinaryEliminationProofs.policy_multiple_shortcut
#print axioms PsKernelOrdinaryEliminationProofs.policy_singleton_composition_preserves_decline_error_and_negation
