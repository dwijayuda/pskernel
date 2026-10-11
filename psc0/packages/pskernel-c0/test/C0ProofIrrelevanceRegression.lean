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
