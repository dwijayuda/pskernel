import Lean
import Ps.KernelCore.SelfHost

/-
Matched preallocated-expression hot-path experiment for Lean 4.35.0.
Only source-runtime operations are measured; no admissions or checker rules change.
-/

private def psHotApp (depth : Nat) : PsKernelExpr :=
  match depth with
  | Nat.zero => PsKernelExpr.bvar 0
  | Nat.succ remaining =>
      PsKernelExpr.app (psHotApp remaining) (PsKernelExpr.bvar 1)

private def leanHotApp (depth : Nat) : Lean.Expr :=
  match depth with
  | Nat.zero => Lean.Expr.bvar 0
  | Nat.succ remaining =>
      Lean.Expr.app (leanHotApp remaining) (Lean.Expr.bvar 1)

private def bench (name : String) (depth calls : Nat)
    (run : Nat → Nat) : IO Unit := do
  let mut checksum := 0
  let start ← IO.monoMsNow
  for i in [:calls] do
    checksum := checksum + run i
  let stop ← IO.monoMsNow
  IO.println s!"PSC1_HOTPATH_NATIVE operation={name} depth={depth} calls={calls} ms={stop-start} checksum={checksum}"

private def runDepth (depth : Nat) : IO Unit := do
  let ps := psHotApp depth
  let psClone := psHotApp depth
  let official := leanHotApp depth
  let officialClone := leanHotApp depth
  unless psKernelExprHasLooseBVar ps && official.hasLooseBVars do
    throw (IO.userError "HOTPATH_BVAR_CLOSURE_MISMATCH")
  unless !psKernelExprHasFVar ps && !official.hasFVar do
    throw (IO.userError "HOTPATH_FVAR_CLOSURE_MISMATCH")
  unless psKernelExprEq ps psClone && Lean.Expr.equal official officialClone do
    throw (IO.userError "HOTPATH_EXPR_EQ_MISMATCH")
  let calls := 12000
  bench "psc_hash" depth calls (fun _ => psKernelExprHash ps)
  bench "lean_hash" depth calls (fun _ => official.hash.toNat)
  bench "psc_has_fvar" depth calls (fun _ => if psKernelExprHasFVar ps then 1 else 0)
  bench "lean_has_fvar" depth calls (fun _ => if official.hasFVar then 1 else 0)
  bench "psc_has_bvar" depth calls (fun _ => if psKernelExprHasLooseBVar ps then 1 else 0)
  bench "lean_has_bvar" depth calls (fun _ => if official.hasLooseBVars then 1 else 0)
  bench "psc_equal" depth calls (fun _ => if psKernelExprEq ps psClone then 1 else 0)
  bench "lean_equal" depth calls (fun _ => if Lean.Expr.equal official officialClone then 1 else 0)

def main : IO Unit := do
  runDepth 32
  runDepth 128
  runDepth 512
  IO.println "PSC1_HOTPATH_NATIVE: COMPLETE"
