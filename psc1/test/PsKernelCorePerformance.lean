import Ps.KernelCore.SelfHost

/-
Matched native C0 beta planner comparison.  This is informational,
not a proof of whole-kernel performance.  Both candidate paths run on the
same GitHub Actions Linux worker and same runtime term workload; each case
first proves identical source result with the structural expression predicate.
-/
private def psKernelPerfOld (fn : PsKernelExpr)
    (args : List PsKernelExpr) : PsKernelExpr :=
  let counted := psKernelWhnfCountLambdas fn args.length
  match Prod.fst counted with
  | PsKernelExpr.lam _ _ body _ =>
      psKernelExprApplyArgsCheap
        (psKernelExprInstantiateRev body (args.take (Prod.snd counted)))
        (args.drop (Prod.snd counted))
  | _ =>
      psKernelExprApplyArgsCheap fn args

private def psKernelPerfC0 (fn : PsKernelExpr)
    (args : List PsKernelExpr) : PsKernelExpr :=
  match psKernelC0BetaSpinePlan fn args with
  | Option.none => psKernelExprApplyArgsCheap fn args
  | Option.some plan => psKernelC0BetaSpineApply plan

private def psKernelPerfNestedLambdas
    (depth : Nat) (body : PsKernelExpr) : PsKernelExpr :=
  match depth with
  | Nat.zero => body
  | Nat.succ n =>
      psKernelPerfNestedLambdas n
        (PsKernelExpr.lam PsKernelName.anonymous
          (PsKernelExpr.sort PsKernelLevel.zero) body
          PsKernelBinderInfo.default)

private def psKernelPerfLoop (optimized : Bool)
    (iterations : Nat) (fn : PsKernelExpr)
    (rest : List PsKernelExpr) : IO Nat := do
  let mut check := 0
  for i in [:iterations] do
    let args := PsKernelExpr.bvar i :: rest
    let expr :=
      if optimized then psKernelPerfC0 fn args
      else psKernelPerfOld fn args
    check := check + psKernelExprNodeCount expr
  pure check

private def psKernelPerfCase
    (depth iterations : Nat) : IO Unit := do
  let fn := psKernelPerfNestedLambdas depth (PsKernelExpr.bvar (depth - 1))
  let args := List.replicate (depth - 1) (PsKernelExpr.sort PsKernelLevel.zero)
  let probeArgs := PsKernelExpr.bvar 7 :: args
  unless psKernelExprEq
      (psKernelPerfOld fn probeArgs) (psKernelPerfC0 fn probeArgs) do
    throw (IO.userError "PSC1_C0_BETA_PERF_PARITY_FAILURE")
  let baselineStart ← IO.monoMsNow
  let oldSum ← psKernelPerfLoop false iterations fn args
  let baselineEnd ← IO.monoMsNow
  let improvedStart ← IO.monoMsNow
  let newSum ← psKernelPerfLoop true iterations fn args
  let improvedEnd ← IO.monoMsNow
  unless oldSum == newSum do
    throw (IO.userError "PSC1_C0_BETA_PERF_CHECKSUM_MISMATCH")
  let oldMs := baselineEnd - baselineStart
  let newMs := improvedEnd - improvedStart
  IO.println s!"PSC1_C0_BETA_BENCH depth={depth} calls={iterations} old_ms={oldMs} c0_ms={newMs} checksum={oldSum}"

def main : IO Unit := do
  psKernelPerfCase 24 120000
  psKernelPerfCase 96 120000
  IO.println "PSC1_C0_BETA_BENCH: COMPLETE (matched native comparison)"
