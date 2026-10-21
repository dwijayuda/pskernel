import Ps.KernelCore.API.Dag

/- Local source obligations for the explicit generated-owner bridge.
   These prove namespace refusal and exact stage guard/order equations.
   They do not prove complete inductive admission, global iota equivalence,
   or soundness of arbitrary caller-forged internal owner records. -/

namespace PsKernelExprV2RecursorProofs

abbrev PublicWhnf := PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
  Option (Except String (Prod PsKernelExprV2WhnfState Nat))

theorem check_uses_input_namespace
    (input work : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (root : Nat) (error : String)
    (invalid : psKernelExprV2DecodedRequire input root = Except.error error) :
    psKernelDagRunCommandWithSource input execution params safety arena work
      (PsKernelDagCommand.check root) =
      Except.error (PsKernelError.rejectedInvalid error) := by
  simp [psKernelDagRunCommandWithSource, psKernelDagRequire, invalid]

theorem whnf_uses_input_namespace
    (input work : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (root : Nat) (error : String)
    (invalid : psKernelExprV2DecodedRequire input root = Except.error error) :
    psKernelDagRunCommandWithSource input execution params safety arena work
      (PsKernelDagCommand.whnf root) =
      Except.error (PsKernelError.rejectedInvalid error) := by
  simp [psKernelDagRunCommandWithSource, psKernelDagRequire, invalid]

theorem defeq_left_uses_input_namespace_first
    (input work : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (left right : Nat) (error : String)
    (invalid : psKernelExprV2DecodedRequire input left = Except.error error) :
    psKernelDagRunCommandWithSource input execution params safety arena work
      (PsKernelDagCommand.isDefEq left right) =
      Except.error (PsKernelError.rejectedInvalid error) := by
  simp [psKernelDagRunCommandWithSource, psKernelDagRequire, invalid]

theorem admission_uses_input_namespace
    (input work : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (request : PsKernelDagDeclarationRequest)
    (error : String)
    (invalid : psKernelDagDecodeDeclaration input request = Except.error error) :
    psKernelDagRunCommandWithSource input execution params safety arena work
      (PsKernelDagCommand.admit request) =
      Except.error (PsKernelError.rejectedInvalid error) := by
  simp [psKernelDagRunCommandWithSource, invalid]

theorem generated_finish_synchronizes_append
    (source : PsKernelExpr) (state : PsKernelDagGeneratedState)
    (arena : PsKernelExprV2PagedArena) (root : Nat)
    (atEnd : root = state.built.size)
    (oneNew : arena.size = Nat.succ state.built.size) :
    psKernelDagGeneratedFinish source state (Except.ok (Prod.mk arena root)) =
      Except.ok (Prod.mk
        (PsKernelDagGeneratedState.mk arena
          (psKernelExprV2DecodedPush state.built source) state.declarations) root) := by
  simp [psKernelDagGeneratedFinish, atEnd, oneNew]

theorem generated_finish_refuses_wrong_root
    (source : PsKernelExpr) (state : PsKernelDagGeneratedState)
    (arena : PsKernelExprV2PagedArena) (root : Nat)
    (wrong : Nat.beq root state.built.size = false) :
    psKernelDagGeneratedFinish source state (Except.ok (Prod.mk arena root)) =
      Except.error "PSKERNEL_V2_GENERATED_OWNER_MISMATCH" := by
  simp [psKernelDagGeneratedFinish, wrong]

theorem no_owner_from_empty_batch
    (recursor : PsKernelRecursorInfo) (rule : PsKernelRecursorRule) :
    psKernelExprV2RecursorRuleOwner [] recursor rule = none := rfl

theorem insufficient_fields_precede_owner
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel) (args fields : List Nat) (majorIndex : Nat)
    (rule : PsKernelRecursorRule)
    (short : psKernelNatGt rule.nFields (psKernelExprV2TransformNatLength fields) = true) :
    psKernelExprV2RecursorApplyRule state recursor levels args fields majorIndex rule =
      some (.ok (state,none)) := by
  simp [psKernelExprV2RecursorApplyRule, short]

theorem wrong_universe_arity_precedes_owner
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel) (args fields : List Nat) (majorIndex : Nat)
    (rule : PsKernelRecursorRule)
    (enough : psKernelNatGt rule.nFields (psKernelExprV2TransformNatLength fields) = false)
    (wrong : Nat.beq (psKernelLevelListLength levels)
      (psKernelNameListLength recursor.base.levelParams) = false) :
    psKernelExprV2RecursorApplyRule state recursor levels args fields majorIndex rule =
      some (.ok (state,none)) := by
  simp [psKernelExprV2RecursorApplyRule, enough, wrong]

theorem missing_owner_never_claims_reduction
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel) (args fields : List Nat) (majorIndex : Nat)
    (rule : PsKernelRecursorRule)
    (enough : psKernelNatGt rule.nFields (psKernelExprV2TransformNatLength fields) = false)
    (arity : Nat.beq (psKernelLevelListLength levels)
      (psKernelNameListLength recursor.base.levelParams) = true)
    (missing : psKernelExprV2RecursorRuleOwner state.declarations recursor rule = none) :
    psKernelExprV2RecursorApplyRule state recursor levels args fields majorIndex rule = none := by
  simp [psKernelExprV2RecursorApplyRule, enough, arity, missing]

theorem K_refuses_before_callbacks
    (whnf : PublicWhnf) (context : PsKernelCheckerContext)
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel) (args : List Nat) (majorIndex major : Nat)
    (isK : recursor.k = true) :
    psKernelExprV2TryReduceNonKRecursorWith whnf context state recursor
      levels args majorIndex major = none := by
  simp [psKernelExprV2TryReduceNonKRecursorWith, isK]

theorem constructor_skips_major_callback
    (whnf : PublicWhnf) (context : PsKernelCheckerContext)
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel) (args : List Nat) (majorIndex major : Nat)
    (notK : recursor.k = false)
    (isConstructorResult : psKernelExprV2RecursorIsConstructorApp context state.arena major = .ok true) :
    psKernelExprV2TryReduceNonKRecursorWith whnf context state recursor levels args majorIndex major =
      psKernelExprV2RecursorSelectRule state recursor levels args majorIndex major := by
  simp [psKernelExprV2TryReduceNonKRecursorWith, notK, isConstructorResult]

theorem nonconstructor_callback_error_precedes_normalization
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (recursor : PsKernelRecursorInfo) (levels : List PsKernelLevel)
    (args : List Nat) (majorIndex major : Nat) (error : String)
    (notK : recursor.k = false)
    (notConstructor : psKernelExprV2RecursorIsConstructorApp context state.arena major = .ok false) :
    psKernelExprV2TryReduceNonKRecursorWith
      (fun _ _ _ => some (.error error)) context state recursor levels args majorIndex major =
      some (.error error) := by
  simp [psKernelExprV2TryReduceNonKRecursorWith, notK, notConstructor]

theorem recursor_zero_before_syntax
    (localValue : PsKernelName -> Option Nat) (context : PsKernelCheckerContext)
    (state : PsKernelExprV2WhnfState) (root : Nat) (cheapProj : Bool) :
    psKernelExprV2TryReduceRecursorWithLocalValuesFuel 0 localValue context state root cheapProj =
      some (.error "kernel recursor budget exhausted") := rfl

#print axioms check_uses_input_namespace
#print axioms whnf_uses_input_namespace
#print axioms defeq_left_uses_input_namespace_first
#print axioms admission_uses_input_namespace
#print axioms generated_finish_synchronizes_append
#print axioms generated_finish_refuses_wrong_root
#print axioms no_owner_from_empty_batch
#print axioms insufficient_fields_precede_owner
#print axioms wrong_universe_arity_precedes_owner
#print axioms missing_owner_never_claims_reduction
#print axioms K_refuses_before_callbacks
#print axioms constructor_skips_major_callback
#print axioms nonconstructor_callback_error_precedes_normalization
#print axioms recursor_zero_before_syntax

end PsKernelExprV2RecursorProofs
