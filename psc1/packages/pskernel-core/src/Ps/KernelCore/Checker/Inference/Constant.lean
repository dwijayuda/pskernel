import Ps.KernelCore.Checker.Context

/-
Shared constant-inference rule for recursive and DAG input. Lookup, level
arity and unsafe/partial checks retain the original order. inferOnly skips
the same safety checks as the existing kernel; public checking passes false.
This helper does not perform declaration admission or trust a cached type.
-/
def psKernelInferConstantType
    (context : PsKernelCheckerContext)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (inferOnly : Bool) :
    Except String PsKernelExpr :=
  match psKernelEnvironmentFind context.environment name with
  | Option.none => Except.error "unknown constant"
  | Option.some info =>
      let params := psKernelConstantInfoLevelParams info;
      if Nat.beq
          (psKernelNameListLength params) (psKernelLevelListLength levels) then
        if inferOnly then
          Except.ok
            (psKernelExprInstantiateLevelParams
              (psKernelConstantInfoType info) params levels)
        else if psKernelConstantInfoIsUnsafe info then
          if psKernelDefinitionSafetyIsUnsafe context.safety then
            Except.ok
              (psKernelExprInstantiateLevelParams
                (psKernelConstantInfoType info) params levels)
          else
            Except.error "safe declaration uses unsafe constant"
        else if psKernelConstantInfoIsPartial info then
          if psKernelDefinitionSafetyIsSafe context.safety then
            Except.error "safe declaration uses partial constant"
          else
            Except.ok
              (psKernelExprInstantiateLevelParams
                (psKernelConstantInfoType info) params levels)
        else
          Except.ok
            (psKernelExprInstantiateLevelParams
              (psKernelConstantInfoType info) params levels)
      else
        Except.error "incorrect number of universe levels"

