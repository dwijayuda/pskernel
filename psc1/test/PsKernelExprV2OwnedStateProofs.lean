import Ps.KernelCore.Checker.ExprV2.CheckCallbacks
import Ps.KernelCore.Checker.ExprV2.Check
import Ps.KernelCore.Checker.ExprV2.Knot

/- Local carrier identities. These prove compatibility-boundary state and
   failure preservation and primary entry guards; they are not a whole-kernel
   equivalence or soundness theorem. -/
namespace PsKernelExprV2OwnedStateProofs

theorem lift_success_preserves_six_outer_fields
    (owner : PsKernelExprV2CheckState) (next : PsKernelExprV2WhnfState) (root : Nat) :
    psKernelExprV2LiftWhnfAttempt owner
        (Option.some (Except.ok (Prod.mk next root))) =
      Option.some (Except.ok (Prod.mk
        (PsKernelExprV2CheckState.mk next owner.nextFresh owner.checkedInfer
          owner.success owner.inferOnly owner.unfold owner.failure) root)) := by
  rfl

theorem optional_lift_success_preserves_six_outer_fields
    (owner : PsKernelExprV2CheckState) (next : PsKernelExprV2WhnfState) (root : Option Nat) :
    psKernelExprV2LiftOptionalWhnfAttempt owner
        (Option.some (Except.ok (Prod.mk next root))) =
      Option.some (Except.ok (Prod.mk
        (PsKernelExprV2CheckState.mk next owner.nextFresh owner.checkedInfer
          owner.success owner.inferOnly owner.unfold owner.failure) root)) := by
  rfl

theorem lower_lift_identity
    (owner : PsKernelExprV2CheckState)
    (attempt : Option (Except String (Prod PsKernelExprV2WhnfState Nat))) :
    psKernelExprV2LowerWhnfAttempt (psKernelExprV2LiftWhnfAttempt owner attempt) = attempt := by
  cases attempt with
  | none => rfl
  | some attempted =>
      cases attempted with
      | error error => rfl
      | ok value => cases value; rfl

theorem optional_lower_lift_identity
    (owner : PsKernelExprV2CheckState)
    (attempt : Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat)))) :
    psKernelExprV2LowerOptionalWhnfAttempt
        (psKernelExprV2LiftOptionalWhnfAttempt owner attempt) = attempt := by
  cases attempt with
  | none => rfl
  | some attempted =>
      cases attempted with
      | error error => rfl
      | ok value => cases value; rfl

theorem lift_decline_and_error_preserved
    (owner : PsKernelExprV2CheckState) (error : String) :
    psKernelExprV2LiftWhnfAttempt owner Option.none = Option.none ∧
    psKernelExprV2LiftWhnfAttempt owner (Option.some (Except.error error)) =
      Option.some (Except.error error) ∧
    psKernelExprV2LiftOptionalWhnfAttempt owner Option.none = Option.none ∧
    psKernelExprV2LiftOptionalWhnfAttempt owner (Option.some (Except.error error)) =
      Option.some (Except.error error) := by
  exact ⟨rfl,rfl,rfl,rfl⟩

theorem owned_core_zero_precedes_callbacks_and_syntax
    (cheapRec cheapProj : Bool)
    (localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (reducer : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) (root : Nat) :
    psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel 0 cheapRec cheapProj
        localValue publicWhnf reducer context state root =
      Option.some (Except.error "kernel reduction budget exhausted") := by
  rfl

theorem owned_public_zero_precedes_callbacks_and_syntax
    (reducer : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))))
    (localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) (root : Nat) :
    psKernelExprV2TryWhnfOwnedWithReducerFuel 0 reducer localValue context state root =
      Option.some (Except.error "kernel reduction budget exhausted") := by
  rfl

theorem owned_recursor_zero_precedes_callbacks_and_syntax
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (cheapRec cheapProj : Bool) :
    psKernelExprV2TryReduceRecursorOwnedWithFuel 0 defeq localValue
        context state root cheapRec cheapProj =
      Option.some (Except.error "kernel recursor budget exhausted") := by
  rfl

theorem owned_inference_zero_precedes_callbacks_and_cache
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (inferOnly : Bool) :
    psKernelExprV2TryInferCoreOwnedWithFuel 0 whnf defeq context state root inferOnly =
      Option.some (Except.error "kernel inference budget exhausted") := by
  rfl

theorem owned_defeq_zero_precedes_syntax_and_cache
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) (left right : Nat) :
    psKernelExprV2TryDefEqStateWithFuel 0 context state left right =
      Option.some (Except.error "kernel definitional equality budget exhausted") := by
  rfl

end PsKernelExprV2OwnedStateProofs

#print axioms PsKernelExprV2OwnedStateProofs.lift_success_preserves_six_outer_fields
#print axioms PsKernelExprV2OwnedStateProofs.optional_lift_success_preserves_six_outer_fields
#print axioms PsKernelExprV2OwnedStateProofs.lower_lift_identity
#print axioms PsKernelExprV2OwnedStateProofs.optional_lower_lift_identity
#print axioms PsKernelExprV2OwnedStateProofs.lift_decline_and_error_preserved
#print axioms PsKernelExprV2OwnedStateProofs.owned_core_zero_precedes_callbacks_and_syntax
#print axioms PsKernelExprV2OwnedStateProofs.owned_public_zero_precedes_callbacks_and_syntax
#print axioms PsKernelExprV2OwnedStateProofs.owned_recursor_zero_precedes_callbacks_and_syntax
#print axioms PsKernelExprV2OwnedStateProofs.owned_inference_zero_precedes_callbacks_and_cache
#print axioms PsKernelExprV2OwnedStateProofs.owned_defeq_zero_precedes_syntax_and_cache
