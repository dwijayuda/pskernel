import Lean
import Ps.KernelCore.API.Dag

/-!
Local ownership equations for the post-admission Quot bridge. These preserve
the four-name plan, exact type comparison, idempotent import and immutable
caller namespace. They neither authenticate arbitrary session records nor
prove complete kernel soundness. The actual Quot admission is unchanged.
-/
namespace PsKernelExprV2QuotOwnerProofs

theorem kind_reflexive (kind : PsKernelQuotKind) :
    psKernelExprV2QuotKindEq kind kind = true := by
  cases kind <;> rfl

theorem quotient_kind_matches_exact
    (kind : PsKernelQuotKind) (value : PsKernelQuotInfo) :
    psKernelExprV2DeclarationRefKindMatches (.quotDecl kind) (.quotInfo value) =
      psKernelExprV2QuotKindEq kind value.kind := by
  rfl

theorem quotient_kind_refuses_axiom
    (kind : PsKernelQuotKind) (value : PsKernelAxiomInfo) :
    psKernelExprV2DeclarationRefKindMatches (.quotDecl kind) (.axiomInfo value) =
      false := by
  rfl

theorem find_missing
    (environment : PsKernelEnvironment) (name : PsKernelName)
    (kind : PsKernelQuotKind)
    (missing : psKernelEnvironmentFind environment name = none) :
    psKernelDagGeneratedFindQuot environment name kind = none := by
  simp [psKernelDagGeneratedFindQuot, missing]

theorem find_wrong_kind
    (environment : PsKernelEnvironment) (name : PsKernelName)
    (kind : PsKernelQuotKind) (value : PsKernelQuotInfo)
    (found : psKernelEnvironmentFind environment name = some (.quotInfo value))
    (wrong : psKernelExprV2QuotKindEq value.kind kind = false) :
    psKernelDagGeneratedFindQuot environment name kind = none := by
  simp [psKernelDagGeneratedFindQuot, found, wrong]

theorem plan_uninitialized
    (environment : PsKernelEnvironment) (uninitialized : environment.quotInitialized = false) :
    psKernelDagGeneratedPlanQuot environment = none := by
  simp [psKernelDagGeneratedPlanQuot, uninitialized]

theorem plan_missing_first
    (environment : PsKernelEnvironment)
    (missing : psKernelDagGeneratedFindQuot environment psKernelQuotName .typeQ = none) :
    psKernelDagGeneratedPlanQuot environment = none := by
  simp [psKernelDagGeneratedPlanQuot, missing]

theorem plan_incomplete_last
    (environment : PsKernelEnvironment) (typeInfo ctorInfo liftInfo : PsKernelConstantInfo)
    (initialized : environment.quotInitialized = true)
    (foundType : psKernelDagGeneratedFindQuot environment psKernelQuotName .typeQ = some typeInfo)
    (foundCtor : psKernelDagGeneratedFindQuot environment psKernelQuotMkName .ctorQ = some ctorInfo)
    (foundLift : psKernelDagGeneratedFindQuot environment psKernelQuotLiftName .liftQ = some liftInfo)
    (missingInd : psKernelDagGeneratedFindQuot environment psKernelQuotIndName .indQ = none) :
    psKernelDagGeneratedPlanQuot environment = none := by
  simp [psKernelDagGeneratedPlanQuot, initialized, foundType, foundCtor, foundLift, missingInd]

theorem plan_complete
    (environment : PsKernelEnvironment) (typeInfo ctorInfo liftInfo indInfo : PsKernelConstantInfo)
    (initialized : environment.quotInitialized = true)
    (foundType : psKernelDagGeneratedFindQuot environment psKernelQuotName .typeQ = some typeInfo)
    (foundCtor : psKernelDagGeneratedFindQuot environment psKernelQuotMkName .ctorQ = some ctorInfo)
    (foundLift : psKernelDagGeneratedFindQuot environment psKernelQuotLiftName .liftQ = some liftInfo)
    (foundInd : psKernelDagGeneratedFindQuot environment psKernelQuotIndName .indQ = some indInfo) :
    psKernelDagGeneratedPlanQuot environment = some [typeInfo,ctorInfo,liftInfo,indInfo] := by
  simp [psKernelDagGeneratedPlanQuot, initialized, foundType, foundCtor, foundLift, foundInd]

theorem owner_missing
    (value : PsKernelQuotInfo) (state : PsKernelDagGeneratedState)
    (missing : psKernelExprV2DeclarationRefFind state.declarations value.base.name = none) :
    psKernelDagGeneratedQuotOwnerMatches value state = false := by
  simp [psKernelDagGeneratedQuotOwnerMatches, missing]

theorem owner_delta_refused
    (value : PsKernelQuotInfo) (state : PsKernelDagGeneratedState)
    (owner : PsKernelExprV2DeclarationRef) (body : Nat)
    (found : psKernelExprV2DeclarationRefFind state.declarations value.base.name = some owner)
    (delta : owner.deltaValue = some body) :
    psKernelDagGeneratedQuotOwnerMatches value state = false := by
  simp [psKernelDagGeneratedQuotOwnerMatches, found, delta]

theorem owner_type_error_refused
    (value : PsKernelQuotInfo) (state : PsKernelDagGeneratedState)
    (owner : PsKernelExprV2DeclarationRef) (error : String)
    (found : psKernelExprV2DeclarationRefFind state.declarations value.base.name = some owner)
    (matchesLive : psKernelExprV2DeclarationRefMatches owner (.quotInfo value) = true)
    (delta : owner.deltaValue = none)
    (missingType : psKernelExprV2DecodedRequire state.built owner.type = .error error) :
    psKernelDagGeneratedQuotOwnerMatches value state = false := by
  simp [psKernelDagGeneratedQuotOwnerMatches, found, matchesLive, delta, missingType]

theorem owner_type_exact_comparison
    (value : PsKernelQuotInfo) (state : PsKernelDagGeneratedState)
    (owner : PsKernelExprV2DeclarationRef) (type : PsKernelExpr)
    (found : psKernelExprV2DeclarationRefFind state.declarations value.base.name = some owner)
    (matchesLive : psKernelExprV2DeclarationRefMatches owner (.quotInfo value) = true)
    (delta : owner.deltaValue = none)
    (decoded : psKernelExprV2DecodedRequire state.built owner.type = .ok type) :
    psKernelDagGeneratedQuotOwnerMatches value state =
      psKernelExprEqual type value.base.type := by
  simp [psKernelDagGeneratedQuotOwnerMatches, found, matchesLive, delta, decoded]

theorem install_missing_plan (state : PsKernelDagGeneratedState) :
    psKernelDagGeneratedInstallQuotPlan none state = .ok state := by
  rfl

theorem install_existing_plan
    (infos : List PsKernelConstantInfo) (state : PsKernelDagGeneratedState)
    (owned : psKernelDagGeneratedQuotOwnersComplete infos state = true) :
    psKernelDagGeneratedInstallQuotPlan (some infos) state = .ok state := by
  simp [psKernelDagGeneratedInstallQuotPlan, owned]

theorem install_incomplete_owners
    (infos : List PsKernelConstantInfo) (state : PsKernelDagGeneratedState)
    (unowned : psKernelDagGeneratedQuotOwnersComplete infos state = false) :
    psKernelDagGeneratedInstallQuotPlan (some infos) state =
      psKernelDagGeneratedInstallInfos infos state := by
  simp [psKernelDagGeneratedInstallQuotPlan, unowned]

theorem quotient_info_imports_only_header
    (value : PsKernelQuotInfo) (state : PsKernelDagGeneratedState) :
    psKernelDagGeneratedInstallInfo (.quotInfo value) state =
      psKernelDagGeneratedInstallHeader value.base (.quotDecl value.kind) state := by
  rfl

theorem quotient_command_uses_checked_plan
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState) :
    psKernelDagGeneratedAfterCommand (.admit .quot) environment state =
      psKernelDagGeneratedInstallQuotPlan (psKernelDagGeneratedPlanQuot environment) state := by
  rfl

theorem private_check_reference_stays_invalid
    (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (workArena : PsKernelExprV2PagedArena) (workBuilt : PsKernelExprV2Decoded)
    (root : Nat) (error : PsKernelError)
    (invalid : psKernelDagRequire input root = .error error) :
    psKernelDagRunCommandWithSource input execution levelParams safety workArena workBuilt
        (.check root) = .error error := by
  simp [psKernelDagRunCommandWithSource, invalid]

theorem private_whnf_reference_stays_invalid
    (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (workArena : PsKernelExprV2PagedArena) (workBuilt : PsKernelExprV2Decoded)
    (root : Nat) (error : PsKernelError)
    (invalid : psKernelDagRequire input root = .error error) :
    psKernelDagRunCommandWithSource input execution levelParams safety workArena workBuilt
        (.whnf root) = .error error := by
  simp [psKernelDagRunCommandWithSource, invalid]

theorem quotient_previous_command_uses_checked_plan
    (previous current : PsKernelEnvironment) (state : PsKernelDagGeneratedState) :
    psKernelDagGeneratedAfterCommandWithPrevious (.admit .quot) previous current state =
      psKernelDagGeneratedInstallQuotPlan (psKernelDagGeneratedPlanQuot current) state := by
  rfl

#print axioms kind_reflexive
#print axioms quotient_kind_matches_exact
#print axioms quotient_kind_refuses_axiom
#print axioms find_missing
#print axioms find_wrong_kind
#print axioms plan_uninitialized
#print axioms plan_missing_first
#print axioms plan_incomplete_last
#print axioms plan_complete
#print axioms owner_missing
#print axioms owner_delta_refused
#print axioms owner_type_error_refused
#print axioms owner_type_exact_comparison
#print axioms install_missing_plan
#print axioms install_existing_plan
#print axioms install_incomplete_owners
#print axioms quotient_info_imports_only_header
#print axioms quotient_command_uses_checked_plan
#print axioms quotient_previous_command_uses_checked_plan
#print axioms private_check_reference_stays_invalid
#print axioms private_whnf_reference_stays_invalid

end PsKernelExprV2QuotOwnerProofs
