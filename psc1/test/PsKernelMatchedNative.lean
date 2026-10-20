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
  if op == "check_sort" then
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
  if op == "check_sort" then
    match psKernelSessionCheck 4096 session psSort with
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
  for op in ["check_sort", "beta_whnf", "defeq_positive"] do
    psc1MatchedMeasure env op "lean" 2400
    psc1MatchedMeasure env op "psc" 2400
    psc1MatchedMeasure env op "psc" 2400
    psc1MatchedMeasure env op "lean" 2400
  psc1MatchedDeepAll env
  IO.println "PSC1_MATCHED_KERNEL: COMPLETE"


/-
Depth-controlled closed zeta chains, built once before timing. Each let is
let x : Sort 1 := previous; x, so the expression checks with type Sort 1
and WHNF/DefEq recover Sort 0. The public APIs receive fresh checker state on
each operation; the same exact expression shapes are checked on both sides.
This measures checked computations, not elaboration or term construction.
-/
private def psMatchedSortOne : PsKernelExpr :=
  PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)

private def leanMatchedSortOne : Lean.Expr :=
  Lean.Expr.sort (Lean.Level.succ Lean.Level.zero)

private def psMatchedZeta (depth : Nat) : PsKernelExpr :=
  match depth with
  | 0 => psSort
  | Nat.succ remaining =>
      PsKernelExpr.letE PsKernelName.anonymous psMatchedSortOne
        (psMatchedZeta remaining) (PsKernelExpr.bvar 0) false

private def leanMatchedZeta (depth : Nat) : Lean.Expr :=
  match depth with
  | 0 => leanSort
  | Nat.succ remaining =>
      Lean.Expr.letE Lean.Name.anonymous leanMatchedSortOne
        (leanMatchedZeta remaining) (Lean.Expr.bvar 0) false

private def officialDeepOne (env : Lean.Environment)
    (op : String) (term : Lean.Expr) : IO Nat := do
  if op == "check_zeta" then
    match Lean.Kernel.check env {} term with
    | Except.ok value =>
        if Lean.Expr.equal value leanMatchedSortOne then return 1
        throw (IO.userError "OFFICIAL_DEEP_CHECK_WRONG_TYPE")
    | Except.error _ => throw (IO.userError "OFFICIAL_DEEP_CHECK_REJECTED")
  else if op == "whnf_zeta" then
    match Lean.Kernel.whnf env {} term with
    | Except.ok value =>
        if Lean.Expr.equal value leanSort then return 1
        throw (IO.userError "OFFICIAL_DEEP_WHNF_WRONG_RESULT")
    | Except.error _ => throw (IO.userError "OFFICIAL_DEEP_WHNF_REJECTED")
  else
    match Lean.Kernel.isDefEq env {} term leanSort with
    | Except.ok value =>
        if value then return 1
        throw (IO.userError "OFFICIAL_DEEP_DEFEQ_FALSE")
    | Except.error _ => throw (IO.userError "OFFICIAL_DEEP_DEFEQ_REJECTED")

private def independentDeepOne (op : String) (term : PsKernelExpr) : IO Nat := do
  if op == "check_zeta" then
    match psKernelSessionCheck 4096 session term with
    | Except.ok result =>
        if psKernelExprEq (Prod.fst result) psMatchedSortOne then return 1
        throw (IO.userError "PSC1_DEEP_CHECK_WRONG_TYPE")
    | Except.error _ => throw (IO.userError "PSC1_DEEP_CHECK_REJECTED")
  else if op == "whnf_zeta" then
    match psKernelSessionWhnf 4096 session term with
    | Except.ok result =>
        if psKernelExprEq (Prod.fst result) psSort then return 1
        throw (IO.userError "PSC1_DEEP_WHNF_WRONG_RESULT")
    | Except.error _ => throw (IO.userError "PSC1_DEEP_WHNF_REJECTED")
  else
    match psKernelSessionIsDefEq 4096 session term psSort with
    | Except.ok result =>
        if Prod.fst result then return 1
        throw (IO.userError "PSC1_DEEP_DEFEQ_FALSE")
    | Except.error _ => throw (IO.userError "PSC1_DEEP_DEFEQ_REJECTED")

private def psc1MatchedDeepMeasure
    (env : Lean.Environment) (op label : String) (depth calls : Nat)
    (psTerm : PsKernelExpr) (officialTerm : Lean.Expr) : IO Unit := do
  let mut passed := 0
  let before ← IO.monoMsNow
  for _ in [:calls] do
    let value ← if label == "lean" then
        officialDeepOne env op officialTerm
      else independentDeepOne op psTerm
    passed := passed + value
  let after ← IO.monoMsNow
  unless passed == calls do throw (IO.userError "MATCHED_DEEP_INCOMPLETE")
  IO.println s!"PSC1_MATCHED_DEEP operation={op} depth={depth} variant={label} calls={calls} ms={after-before} all_correct=true"

private def psc1MatchedDeepAll (env : Lean.Environment) : IO Unit := do
  for (depth, calls) in [(32, 100), (96, 50), (192, 20)] do
    let psTerm := psMatchedZeta depth
    let leanTerm := leanMatchedZeta depth
    for op in ["whnf_zeta", "defeq_zeta", "check_zeta"] do
      psc1MatchedDeepMeasure env op "lean" depth calls psTerm leanTerm
      psc1MatchedDeepMeasure env op "psc" depth calls psTerm leanTerm
      psc1MatchedDeepMeasure env op "psc" depth calls psTerm leanTerm
      psc1MatchedDeepMeasure env op "lean" depth calls psTerm leanTerm
  IO.println "PSC1_MATCHED_DEEP: COMPLETE"
