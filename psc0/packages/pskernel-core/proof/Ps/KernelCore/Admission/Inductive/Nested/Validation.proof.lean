import Ps.KernelCore.Admission.Inductive.Nested.Validation

theorem psKernelSimpleNestedRuleListLength_eq_length
    (rules : List PsKernelRecursorRule) :
    psKernelSimpleNestedRuleListLength rules =
      List.length rules := by
  induction rules with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelSimpleNestedRuleListLength, ih]

theorem psKernelSimpleNestedCompareValidatedRuleTypesWithFuel_zero_empty
    (fuel : Nat)
    (transformed finalEnvironment : PsKernelEnvironment)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (oldLevelParams newLevelParams : List PsKernelName) :
    psKernelSimpleNestedCompareValidatedRuleTypesWithFuel
        0 fuel transformed finalEnvironment safety
        maxRecDepth maxNatSize families renames canonicalParams
        numParams oldLevelParams newLevelParams List.nil List.nil =
      Except.ok Unit.unit := by
  rfl
