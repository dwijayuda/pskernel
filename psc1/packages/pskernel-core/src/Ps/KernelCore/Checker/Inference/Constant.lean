import Ps.KernelCore.Checker.Context

/-
Shared constant-reference validation. Lookup, level arity and unsafe/partial
checks retain the original order. inferOnly skips exactly the original safety
checks; complete checking passes false. Returning live ConstantInfo does not
admit a declaration or authorize a cached type.
-/
def psKernelCheckConstantReference
    (context : PsKernelCheckerContext)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (inferOnly : Bool) :
    Except String PsKernelConstantInfo :=
  match psKernelEnvironmentFind context.environment name with
  | Option.none => Except.error "unknown constant"
  | Option.some info =>
      let params := psKernelConstantInfoLevelParams info;
      if Nat.beq
          (psKernelNameListLength params) (psKernelLevelListLength levels) then
        if inferOnly then
          Except.ok info
        else if psKernelConstantInfoIsUnsafe info then
          if psKernelDefinitionSafetyIsUnsafe context.safety then
            Except.ok info
          else
            Except.error "safe declaration uses unsafe constant"
        else if psKernelConstantInfoIsPartial info then
          if psKernelDefinitionSafetyIsSafe context.safety then
            Except.error "safe declaration uses partial constant"
          else
            Except.ok info
        else
          Except.ok info
      else
        Except.error "incorrect number of universe levels"

def psKernelInferConstantType
    (context : PsKernelCheckerContext)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (inferOnly : Bool) :
    Except String PsKernelExpr :=
  match psKernelCheckConstantReference context name levels inferOnly with
  | Except.error error => Except.error error
  | Except.ok info =>
      Except.ok
        (psKernelExprInstantiateLevelParams (psKernelConstantInfoType info)
          (psKernelConstantInfoLevelParams info) levels)
