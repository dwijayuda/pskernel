import Lean
import Ps.KernelCore.API.DagOrdinaryConstructorParams

/-
Universal state, fuel and short-circuit equations for the private constructor
parameter worker. Dependency premises describe the observed lookup, callback
and transformation results; no premise assumes the result of this worker.
These equations do not assert full admission equivalence or establish the
canonical-arena invariant. The module belongs only to the native proof suite.
-/
namespace PsKernelOrdinaryConstructorParamsProofs

abbrev DefEqCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Bool))

variable (defeq : DefEqCallback) (fuel : Nat)
variable (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
variable (parameters rest : List PsKernelExprV2OrdinaryOpenBinder)
variable (parameter : PsKernelExprV2OrdinaryOpenBinder) (type : Nat)

theorem worker_zero_precedes_parameters_lookup_and_callbacks :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker 0
        defeq context state parameters type =
      Option.some
        (Except.error "simple inductive constructor parameter budget exhausted") := by
  rfl

theorem successor_empty_keeps_complete_owner_without_lookup :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state List.nil type =
      Option.some (Except.ok (Prod.mk state type)) := by
  rfl

theorem lookup_error_precedes_defeq
    (error : String)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.error error) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state (List.cons parameter rest) type =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found]

theorem syntactic_nonforall_precedes_defeq
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (notForall : ∀ userName domain body binderInfo,
      entry.node ≠ PsKernelExprV2Node.forallE userName domain body binderInfo) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state (List.cons parameter rest) type =
      Option.some
        (Except.error "simple inductive constructor has fewer parameters than the datatype") := by
  cases node : entry.node <;>
    first
    | exact False.elim (notForall _ _ _ _ node)
    | simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node]

variable (entry : PsKernelExprV2Entry)
variable (userName : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo)

theorem forall_uses_predecessor_fuel_and_constructor_domain_left
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state (List.cons parameter rest) type =
      match defeq fuel context state domain parameter.type with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok equal =>
              if Prod.snd equal then
                let next := Prod.fst equal;
                match psKernelExprV2PagedMkFVar next.whnf.arena parameter.internalName with
                | Except.error error => Option.some (Except.error error)
                | Except.ok fvarBuilt =>
                    match psKernelExprV2TransformOnCanonical
                        (PsKernelExprV2Transform.instantiate 0
                          (List.cons (Prod.snd fvarBuilt) List.nil))
                        (Prod.fst fvarBuilt) body 0 with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok instantiated =>
                        psKernelExprV2OrdinaryOpenConstructorParamsWorker fuel defeq context
                          (psKernelExprV2CheckStateWithArena next (Prod.fst instantiated))
                          rest (Prod.snd instantiated)
              else
                Option.some
                  (Except.error
                    "simple inductive constructor parameter does not match the datatype parameter") := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node] <;> rfl

theorem defeq_decline_precedes_fvar_and_instantiation
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (compared : defeq fuel context state domain parameter.type = Option.none) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state (List.cons parameter rest) type = Option.none := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node, compared]

theorem defeq_error_precedes_fvar_and_instantiation
    (error : String)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (compared : defeq fuel context state domain parameter.type =
      Option.some (Except.error error)) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state (List.cons parameter rest) type =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node, compared]

theorem defeq_false_precedes_fvar_and_instantiation
    (next : PsKernelExprV2CheckState)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (compared : defeq fuel context state domain parameter.type =
      Option.some (Except.ok (Prod.mk next false))) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state (List.cons parameter rest) type =
      Option.some
        (Except.error
          "simple inductive constructor parameter does not match the datatype parameter") := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node, compared] <;> rfl

theorem fvar_error_uses_returned_owner_and_existing_parameter_name
    (next : PsKernelExprV2CheckState) (error : String)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (compared : defeq fuel context state domain parameter.type =
      Option.some (Except.ok (Prod.mk next true)))
    (built : psKernelExprV2PagedMkFVar next.whnf.arena parameter.internalName =
      Except.error error) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state (List.cons parameter rest) type =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node, compared,
    built] <;> rfl

theorem instantiation_error_precedes_recursive_continuation
    (next : PsKernelExprV2CheckState) (builtArena : PsKernelExprV2PagedArena)
    (fvarId : Nat) (error : String)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (compared : defeq fuel context state domain parameter.type =
      Option.some (Except.ok (Prod.mk next true)))
    (built : psKernelExprV2PagedMkFVar next.whnf.arena parameter.internalName =
      Except.ok (Prod.mk builtArena fvarId))
    (instantiated : psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons fvarId List.nil))
      builtArena body 0 = Except.error error) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state (List.cons parameter rest) type =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node, compared,
    built, instantiated] <;> rfl

theorem success_keeps_context_and_complete_returned_owner
    (next : PsKernelExprV2CheckState)
    (builtArena openedArena : PsKernelExprV2PagedArena) (fvarId openedBody : Nat)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (compared : defeq fuel context state domain parameter.type =
      Option.some (Except.ok (Prod.mk next true)))
    (built : psKernelExprV2PagedMkFVar next.whnf.arena parameter.internalName =
      Except.ok (Prod.mk builtArena fvarId))
    (instantiated : psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons fvarId List.nil))
      builtArena body 0 = Except.ok (Prod.mk openedArena openedBody)) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state (List.cons parameter rest) type =
      psKernelExprV2OrdinaryOpenConstructorParamsWorker fuel defeq context
        (psKernelExprV2CheckStateWithArena next openedArena) rest openedBody := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node, compared,
    built, instantiated] <;> rfl

theorem success_preserves_every_semantic_field_and_freshness
    (next : PsKernelExprV2CheckState)
    (builtArena openedArena : PsKernelExprV2PagedArena) (fvarId openedBody : Nat)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (compared : defeq fuel context state domain parameter.type =
      Option.some (Except.ok (Prod.mk next true)))
    (built : psKernelExprV2PagedMkFVar next.whnf.arena parameter.internalName =
      Except.ok (Prod.mk builtArena fvarId))
    (instantiated : psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons fvarId List.nil))
      builtArena body 0 = Except.ok (Prod.mk openedArena openedBody)) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state (List.cons parameter rest) type =
      psKernelExprV2OrdinaryOpenConstructorParamsWorker fuel defeq context
        (PsKernelExprV2CheckState.mk
          (PsKernelExprV2WhnfState.mk openedArena next.whnf.coreCache
            next.whnf.publicCache next.whnf.declarations)
          next.nextFresh next.checkedInfer next.success next.inferOnly next.unfold next.failure)
        rest openedBody := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node, compared,
    built, instantiated, psKernelExprV2CheckStateWithArena,
    psKernelExprV2CheckStateWithWhnf, psKernelExprV2WhnfStateWithArena] <;> rfl

theorem one_unit_successful_step_still_reaches_zero_before_empty_tail
    (next : PsKernelExprV2CheckState)
    (builtArena openedArena : PsKernelExprV2PagedArena) (fvarId openedBody : Nat)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (compared : defeq 0 context state domain parameter.type =
      Option.some (Except.ok (Prod.mk next true)))
    (built : psKernelExprV2PagedMkFVar next.whnf.arena parameter.internalName =
      Except.ok (Prod.mk builtArena fvarId))
    (instantiated : psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons fvarId List.nil))
      builtArena body 0 = Except.ok (Prod.mk openedArena openedBody)) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ 0)
        defeq context state (List.cons parameter List.nil) type =
      Option.some
        (Except.error "simple inductive constructor parameter budget exhausted") := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node, compared,
    built, instantiated] <;> rfl

theorem two_or_more_units_finish_one_parameter_with_returned_owner
    (next : PsKernelExprV2CheckState)
    (builtArena openedArena : PsKernelExprV2PagedArena) (fvarId openedBody : Nat)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (compared : defeq (Nat.succ fuel) context state domain parameter.type =
      Option.some (Except.ok (Prod.mk next true)))
    (built : psKernelExprV2PagedMkFVar next.whnf.arena parameter.internalName =
      Except.ok (Prod.mk builtArena fvarId))
    (instantiated : psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons fvarId List.nil))
      builtArena body 0 = Except.ok (Prod.mk openedArena openedBody)) :
    psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ (Nat.succ fuel))
        defeq context state (List.cons parameter List.nil) type =
      Option.some (Except.ok
        (Prod.mk (psKernelExprV2CheckStateWithArena next openedArena) openedBody)) := by
  simp only [psKernelExprV2OrdinaryOpenConstructorParamsWorker, found, node, compared,
    built, instantiated] <;> rfl

theorem wrapper_adds_one_before_empty_or_callbacks :
    psKernelExprV2OrdinaryOpenConstructorParamsWith
        defeq fuel context state parameters type =
      psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
        defeq context state parameters type := by
  rfl

theorem wrapper_zero_empty_is_identity :
    psKernelExprV2OrdinaryOpenConstructorParamsWith
        defeq 0 context state List.nil type =
      Option.some (Except.ok (Prod.mk state type)) := by
  rfl

theorem with_fuel_uses_full_owner_defeq_without_fallback :
    psKernelExprV2OrdinaryOpenConstructorParamsWithFuel
        fuel context state parameters type =
      psKernelExprV2OrdinaryOpenConstructorParamsWith
        psKernelExprV2TryDefEqStateWithFuel fuel context state parameters type := by
  rfl

#print axioms worker_zero_precedes_parameters_lookup_and_callbacks
#print axioms successor_empty_keeps_complete_owner_without_lookup
#print axioms lookup_error_precedes_defeq
#print axioms syntactic_nonforall_precedes_defeq
#print axioms forall_uses_predecessor_fuel_and_constructor_domain_left
#print axioms defeq_decline_precedes_fvar_and_instantiation
#print axioms defeq_error_precedes_fvar_and_instantiation
#print axioms defeq_false_precedes_fvar_and_instantiation
#print axioms fvar_error_uses_returned_owner_and_existing_parameter_name
#print axioms instantiation_error_precedes_recursive_continuation
#print axioms success_keeps_context_and_complete_returned_owner
#print axioms success_preserves_every_semantic_field_and_freshness
#print axioms one_unit_successful_step_still_reaches_zero_before_empty_tail
#print axioms two_or_more_units_finish_one_parameter_with_returned_owner
#print axioms wrapper_adds_one_before_empty_or_callbacks
#print axioms wrapper_zero_empty_is_identity
#print axioms with_fuel_uses_full_owner_defeq_without_fallback

end PsKernelOrdinaryConstructorParamsProofs
