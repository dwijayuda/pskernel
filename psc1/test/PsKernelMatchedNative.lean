import Lean
import Ps.KernelCore.SelfHost

/-
Lean 4.35.0 official kernel vs PSC1 independent checker cold-operation
comparison on equivalent closed expressions. This is not a Lean Arena,
full-library, or same-resource-policy benchmark.
-/

private def psSort : PsKernelExpr := PsKernelExpr.sort PsKernelLevel.zero
private def psBeta : PsKernelExpr :=
  PsKernelExpr.app
    (PsKernelExpr.lam PsKernelName.anonymous psSort
      (PsKernelExpr.bvar 0) PsKernelBinderInfo.default)
    psSort

private def leanSort : Lean.Expr := Lean.Expr.sort Lean.Level.zero
private def leanBeta : Lean.Expr :=
  Lean.Expr.app
    (Lean.Expr.lam Lean.Name.anonymous leanSort
      (Lean.Expr.bvar 0) Lean.BinderInfo.default)
    leanSort

private def session : PsKernelCheckerSession :=
  psKernelMkCheckerSession
    psKernelEnvironmentEmpty List.nil PsKernelDefinitionSafety.safe
    4096 psKernelLeanNatMaxSizeDefault

private def officialOne (env : Lean.Environment) (op : String) : IO Nat := do
  if op == "infer_sort" then
    match Lean.Kernel.check env {} leanSort with
    | Except.ok result =>
        if Lean.Expr.equal result (Lean.Expr.sort (Lean.Level.succ Lean.Level.zero)) then
          return 1
        else throw (IO.userError "OFFICIAL_KERNEL_SORT_TYPE_MISMATCH")
    | Except.error _ => throw (IO.userError "OFFICIAL_KERNEL_INFER_REJECTED")
  else if op == "beta_whnf" then
    match Lean.Kernel.whnf env {} leanBeta with
    | Except.ok result =>
        if Lean.Expr.equal result leanSort then
          return 1
        else throw (IO.userError "OFFICIAL_KERNEL_BETA_MISMATCH")
    | Except.error _ => throw (IO.userError "OFFICIAL_KERNEL_WHNF_REJECTED")
  else
    match Lean.Kernel.isDefEq env {} leanBeta leanSort with
    | Except.ok value =>
        if value then return 1
        else throw (IO.userError "OFFICIAL_KERNEL_DEFEQ_FALSE")
    | Except.error _ => throw (IO.userError "OFFICIAL_KERNEL_DEFEQ_REJECTED")

private def independentOne (op : String) : IO Nat := do
  if op == "infer_sort" then
    match psKernelSessionInfer 4096 session psSort with
    | Except.ok result =>
        if psKernelExprEq (Prod.fst result)
          (PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)) then
          return 1
        else throw (IO.userError "PSC1_KERNEL_SORT_TYPE_MISMATCH")
    | Except.error _ => throw (IO.userError "PSC1_KERNEL_INFER_REJECTED")
  else if op == "beta_whnf" then
    match psKernelSessionWhnf 4096 session psBeta with
    | Except.ok result =>
        if psKernelExprEq (Prod.fst result) psSort then return 1
        else throw (IO.userError "PSC1_KERNEL_BETA_MISMATCH")
    | Except.error _ => throw (IO.userError "PSC1_KERNEL_WHNF_REJECTED")
  else
    match psKernelSessionIsDefEq 4096 session psBeta psSort with
    | Except.ok result =>
        if Prod.fst result then return 1
        else throw (IO.userError "PSC1_KERNEL_DEFEQ_FALSE")
    | Except.error _ => throw (IO.userError "PSC1_KERNEL_DEFEQ_REJECTED")

private def psc1MatchedMeasure (env : Lean.Environment) (op label : String) (calls : Nat) : IO Unit := do
  let mut passed := 0
  let before ← IO.monoMsNow
  for _ in [:calls] do
    let value ← if label == "lean" then officialOne env op else independentOne op
    passed := passed + value
  let after ← IO.monoMsNow
  unless passed == calls do throw (IO.userError "MATCHED_KERNEL_INCOMPLETE")
  IO.println s!"PSC1_MATCHED_KERNEL operation={op} variant={label} calls={calls} ms={after-before} all_correct=true"

def main : IO Unit := do
  let env ← Lean.mkEmptyEnvironment
  for op in ["infer_sort", "beta_whnf", "defeq_positive"] do
    psc1MatchedMeasure env op "lean" 2400
    psc1MatchedMeasure env op "psc" 2400
    psc1MatchedMeasure env op "psc" 2400
    psc1MatchedMeasure env op "lean" 2400
  IO.println "PSC1_MATCHED_KERNEL: COMPLETE"
