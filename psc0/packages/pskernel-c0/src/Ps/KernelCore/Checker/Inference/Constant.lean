import Ps.KernelCore.Checker.Inference.Helpers

/-!
Lean 4.35-compatible cold constant inference decision, mechanically
extracted from C0's original Checker/Inference/Core.lean.

This function is called after the *same* source cache-miss, fuel and
recursion checks. Keep exact ordering of environment lookup, level arity,
unsafe/partial authorization, declared universe parameters, type
instantiation, and checked/infer-only cache updates. Source checking and
the proof-qualified cold constant caller share this one algorithm;
the independently rebuilt original kernel remains a separate conformance
oracle. Do not add axioms, source inference callbacks or unchecked
approval to this pure decision.
-/

/-- Execute the complete cold constant typing rule in a pre-entered
    source checking context. A returned type is still only a source
    inference result, not a declaration-admission proof. -/
def psKernelInferConstantHead
    (nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (inferOnly : Bool) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  let expr : PsKernelExpr := .const name levels
  match psKernelEnvironmentFind
      nextContext.environment name with
  | Option.none =>
      Except.error "unknown constant"
  | Option.some info =>
      let params :=
        psKernelConstantInfoLevelParams info
      if Nat.beq
          (psKernelNameListLength params)
          (psKernelLevelListLength levels) then
        -- Preserve the original safety precedence and
        -- only validate declared level parameters AFTER
        -- a fully checked use has passed safety checks.
        -- Lean 4.35::infer_constant checks levels only
        -- on the checked path, never infer-only.
        if !inferOnly &&
            psKernelConstantInfoIsUnsafe info &&
            !psKernelDefinitionSafetyIsUnsafe
              nextContext.safety then
          Except.error
            "safe declaration uses unsafe constant"
        else if !inferOnly &&
            !psKernelConstantInfoIsUnsafe info &&
            psKernelConstantInfoIsPartial info &&
            psKernelDefinitionSafetyIsSafe
              nextContext.safety then
          Except.error
            "safe declaration uses partial constant"
        else if !inferOnly &&
            (psKernelFindUndefInLevels
              levels nextContext.levelParams).isSome then
          Except.error
            "invalid reference to undefined universe level parameter"
        else
          let result :=
            psKernelExprInstantiateLevelParams
              (psKernelConstantInfoType info)
              params levels
          Except.ok
            (Prod.mk result
              (psKernelCacheInferResult
                state inferOnly expr result))
      else
        Except.error
          "incorrect number of universe levels"
