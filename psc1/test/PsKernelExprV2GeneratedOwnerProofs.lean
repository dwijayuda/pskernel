import Ps.KernelCore.API.DagGenerated

/- Local equations for the post-admission generated-owner transaction.
   These establish complete-plan refusal, exact metadata guard ordering,
   current-state threading and exact owner publication.
   They do not establish complete inductive admission or global soundness,
   and they do not authorize importing caller-supplied recursor metadata. -/

namespace PsKernelExprV2GeneratedOwnerProofs

theorem missing_plan_preserves_entire_state
    (state : PsKernelDagGeneratedState) :
    psKernelDagGeneratedInstallPlan Option.none state = Except.ok state := rfl

theorem header_import_error_is_preserved
    (base : PsKernelConstantBase) (kind : PsKernelExprV2DeclarationRefKind)
    (state : PsKernelDagGeneratedState) (error : String)
    (failed : psKernelDagGeneratedImport base.type state = Except.error error) :
    psKernelDagGeneratedInstallHeader base kind state = Except.error error := by
  simp [psKernelDagGeneratedInstallHeader, failed]

theorem header_publishes_exact_imported_owner
    (base : PsKernelConstantBase) (kind : PsKernelExprV2DeclarationRefKind)
    (state next : PsKernelDagGeneratedState) (typeId : Nat)
    (imported : psKernelDagGeneratedImport base.type state =
      Except.ok (Prod.mk next typeId)) :
    psKernelDagGeneratedInstallHeader base kind state =
      Except.ok (PsKernelDagGeneratedState.mk next.arena next.built
        (List.cons
          (PsKernelExprV2DeclarationRef.mk base.name base.levelParams typeId
            Option.none kind)
          next.declarations)) := by
  simp [psKernelDagGeneratedInstallHeader, imported]

theorem first_import_error_prevents_tail_publication
    (first : PsKernelConstantInfo) (rest : List PsKernelConstantInfo)
    (state : PsKernelDagGeneratedState) (error : String)
    (failed : psKernelDagGeneratedInstallInfo first state = Except.error error) :
    psKernelDagGeneratedInstallInfos (List.cons first rest) state =
      Except.error error := by
  simp [psKernelDagGeneratedInstallInfos, failed]

theorem next_import_receives_complete_returned_state
    (first : PsKernelConstantInfo) (rest : List PsKernelConstantInfo)
    (state next : PsKernelDagGeneratedState)
    (installed : psKernelDagGeneratedInstallInfo first state = Except.ok next) :
    psKernelDagGeneratedInstallInfos (List.cons first rest) state =
      psKernelDagGeneratedInstallInfos rest next := by
  simp [psKernelDagGeneratedInstallInfos, installed]

theorem missing_live_recursor_declines
    (environment : PsKernelEnvironment) (name : PsKernelName)
    (numParams : Nat) (all : List PsKernelName)
    (missing : psKernelEnvironmentFind environment name = Option.none) :
    psKernelDagGeneratedFindRecursor environment name numParams all = Option.none := by
  simp [psKernelDagGeneratedFindRecursor, missing]

theorem parameter_mismatch_declines_before_group_test
    (environment : PsKernelEnvironment) (name : PsKernelName)
    (numParams : Nat) (all : List PsKernelName) (recursor : PsKernelRecursorInfo)
    (found : psKernelEnvironmentFind environment name =
      Option.some (PsKernelConstantInfo.recInfo recursor))
    (sameName : psKernelNameEq recursor.base.name name = true)
    (wrongParams : Nat.beq recursor.numParams numParams = false) :
    psKernelDagGeneratedFindRecursor environment name numParams all = Option.none := by
  simp [psKernelDagGeneratedFindRecursor, found, sameName, wrongParams]

theorem group_mismatch_declines
    (environment : PsKernelEnvironment) (name : PsKernelName)
    (numParams : Nat) (all : List PsKernelName) (recursor : PsKernelRecursorInfo)
    (found : psKernelEnvironmentFind environment name =
      Option.some (PsKernelConstantInfo.recInfo recursor))
    (sameName : psKernelNameEq recursor.base.name name = true)
    (sameParams : Nat.beq recursor.numParams numParams = true)
    (wrongGroup : psKernelNameListsEq recursor.all all = false) :
    psKernelDagGeneratedFindRecursor environment name numParams all = Option.none := by
  simp [psKernelDagGeneratedFindRecursor, found, sameName, sameParams, wrongGroup]

theorem mutual_missing_tail_discards_ready_prefix
    (first : PsKernelDagInductive) (rest : List PsKernelDagInductive)
    (environment : PsKernelEnvironment) (numParams : Nat) (all : List PsKernelName)
    (recursor : PsKernelRecursorInfo)
    (found : psKernelDagGeneratedFindRecursor environment
      (psKernelSimpleRecName first.name) numParams all = Option.some recursor)
    (missing : psKernelDagGeneratedPlanRecursors rest environment numParams all =
      Option.none) :
    psKernelDagGeneratedPlanRecursors (List.cons first rest)
      environment numParams all = Option.none := by
  simp [psKernelDagGeneratedPlanRecursors, found, missing]

theorem nested_wrong_constructor_family_declines_before_tail
    (name family : PsKernelName) (rest levelParams : List PsKernelName)
    (environment : PsKernelEnvironment) (numParams : Nat)
    (ctor : PsKernelConstructorInfo)
    (found : psKernelEnvironmentFind environment name =
      Option.some (PsKernelConstantInfo.ctorInfo ctor))
    (sameName : psKernelNameEq ctor.base.name name = true)
    (wrongFamily : psKernelNameEq ctor.induct family = false) :
    psKernelDagGeneratedPlanNestedConstructors (List.cons name rest)
      environment family levelParams numParams = Option.none := by
  simp [psKernelDagGeneratedPlanNestedConstructors, found, sameName, wrongFamily]

theorem nested_missing_family_discards_ready_prefix
    (first : PsKernelDagInductive) (rest : List PsKernelDagInductive)
    (environment : PsKernelEnvironment) (levelParams all : List PsKernelName)
    (numParams numNested : Nat) (members : List PsKernelConstantInfo)
    (found : psKernelDagGeneratedPlanNestedFamily first environment
      levelParams numParams all numNested = Option.some members)
    (missing : psKernelDagGeneratedPlanNestedFamilies rest environment
      levelParams numParams all numNested = Option.none) :
    psKernelDagGeneratedPlanNestedFamilies (List.cons first rest)
      environment levelParams numParams all numNested = Option.none := by
  simp [psKernelDagGeneratedPlanNestedFamilies, found, missing]

theorem zero_auxiliary_count_requires_no_lookup
    (environment : PsKernelEnvironment) (mainRec : PsKernelName)
    (index numParams : Nat) (all : List PsKernelName) :
    psKernelDagGeneratedPlanNestedAux 0 environment mainRec index numParams all =
      Option.some List.nil := rfl

theorem missing_later_auxiliary_discards_ready_prefix
    (remaining : Nat) (environment : PsKernelEnvironment) (mainRec : PsKernelName)
    (index numParams : Nat) (all : List PsKernelName) (recursor : PsKernelRecursorInfo)
    (found : psKernelDagGeneratedFindRecursor environment
      (psKernelNameAppendIndexAfter mainRec index) numParams all = Option.some recursor)
    (missing : psKernelDagGeneratedPlanNestedAux remaining environment mainRec
      (Nat.succ index) numParams all = Option.none) :
    psKernelDagGeneratedPlanNestedAux (Nat.succ remaining) environment
      mainRec index numParams all = Option.none := by
  simp [psKernelDagGeneratedPlanNestedAux, found, missing]

theorem missing_mutual_plan_publishes_no_owner
    (group : PsKernelDagInductiveGroup) (environment : PsKernelEnvironment)
    (state : PsKernelDagGeneratedState)
    (missing : psKernelDagGeneratedPlanMutual group environment = Option.none) :
    psKernelDagGeneratedAfterCommand
      (PsKernelDagCommand.admit (PsKernelDagDeclarationRequest.mutualInductive group))
      environment state = Except.ok state := by
  simp [psKernelDagGeneratedAfterCommand, missing, psKernelDagGeneratedInstallPlan]

theorem missing_nested_plan_publishes_no_owner
    (group : PsKernelDagInductiveGroup) (environment : PsKernelEnvironment)
    (state : PsKernelDagGeneratedState)
    (missing : psKernelDagGeneratedPlanNested group environment = Option.none) :
    psKernelDagGeneratedAfterCommand
      (PsKernelDagCommand.admit (PsKernelDagDeclarationRequest.nestedInductive group))
      environment state = Except.ok state := by
  simp [psKernelDagGeneratedAfterCommand, missing, psKernelDagGeneratedInstallPlan]

theorem ordinary_eligible_path_keeps_exact_live_recursor
    (levelParams : List PsKernelName) (numParams : Nat)
    (value : PsKernelDagInductive) (isUnsafe : Bool)
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (recursor : PsKernelRecursorInfo)
    (found : psKernelEnvironmentFind environment (psKernelSimpleRecName value.name) =
      Option.some (PsKernelConstantInfo.recInfo recursor))
    (sameName : psKernelNameEq recursor.base.name (psKernelSimpleRecName value.name) = true)
    (sameParams : Nat.beq recursor.numParams numParams = true)
    (sameGroup : psKernelNameListsEq recursor.all (List.cons value.name List.nil) = true) :
    psKernelDagGeneratedAfterCommand
      (PsKernelDagCommand.admit
        (PsKernelDagDeclarationRequest.ordinaryInductive
          levelParams numParams value isUnsafe))
      environment state = psKernelDagGeneratedInstallRecursor recursor state := by
  simp [psKernelDagGeneratedAfterCommand, psKernelDagGeneratedFindRecursor,
    found, sameName, sameParams, sameGroup]

#print axioms missing_plan_preserves_entire_state
#print axioms header_import_error_is_preserved
#print axioms header_publishes_exact_imported_owner
#print axioms first_import_error_prevents_tail_publication
#print axioms next_import_receives_complete_returned_state
#print axioms missing_live_recursor_declines
#print axioms parameter_mismatch_declines_before_group_test
#print axioms group_mismatch_declines
#print axioms mutual_missing_tail_discards_ready_prefix
#print axioms nested_wrong_constructor_family_declines_before_tail
#print axioms nested_missing_family_discards_ready_prefix
#print axioms zero_auxiliary_count_requires_no_lookup
#print axioms missing_later_auxiliary_discards_ready_prefix
#print axioms missing_mutual_plan_publishes_no_owner
#print axioms missing_nested_plan_publishes_no_owner
#print axioms ordinary_eligible_path_keeps_exact_live_recursor

end PsKernelExprV2GeneratedOwnerProofs
