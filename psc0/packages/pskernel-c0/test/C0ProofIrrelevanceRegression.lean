import Ps.KernelCore.Checker.Session

/- Native checker regression only. No bootstrap or self-host tests.
   The old metatheory equated arbitrary terms, while the executable
   conversion checker must reject distinct universe sorts. -/

def main : IO Unit := do
  let session :=
    psKernelMkCheckerSession
      psKernelEnvironmentEmpty
      []
      PsKernelDefinitionSafety.safe
      4096
      psKernelLeanNatMaxSizeDefault
  let sort0 := PsKernelExpr.sort PsKernelLevel.zero
  let sort1 := PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)
  match psKernelSessionIsDefEq 4096 session sort0 sort1 with
  | Except.error message =>
      throw (IO.userError ("unexpected sort comparison error: " ++ message))
  | Except.ok result =>
      if Prod.fst result then
        throw (IO.userError "unsound: Sort 0 equated with Sort 1")
      else
        IO.println "C0_PROOF_AUDIT sort0_sort1_distinct=pass"
  match psKernelSessionCheck 4096 session (PsKernelExpr.bvar 0) with
  | Except.error _ =>
      IO.println "C0_PROOF_AUDIT unbound_bvar_rejected=pass"
  | Except.ok _ =>
      throw (IO.userError "unsound: unbound de Bruijn variable was checked")

  -- The performance refactor must retain the historical lambda-consumption
  -- semantics, including nonzero already-consumed argument prefixes.
  let info := PsKernelBinderInfo.default
  let base := PsKernelExpr.bvar 0
  let f1 := PsKernelExpr.lam PsKernelName.anonymous sort0 base info
  let f2 := PsKernelExpr.lam PsKernelName.anonymous sort0 f1 info
  let args := [sort0, sort1, sort0]
  for fn in [base, f1, f2] do
    for count in [0, 1, 2, 3, 4] do
      let old :=
        psKernelExprConsumeLambdaSpineWithFuel
          (Nat.succ (psKernelExprNodeCount fn))
          fn args count
      let next := psKernelExprConsumeLambdaSpine fn args count
      if !(psKernelExprEq (Prod.fst old) (Prod.fst next) &&
            Nat.beq (Prod.snd old) (Prod.snd next)) then
        throw (IO.userError "beta-spine linear optimization changed behavior")
  IO.println "C0_PERF_REGRESSION beta_spine_semantics=pass"
