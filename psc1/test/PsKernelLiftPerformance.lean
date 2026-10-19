import Ps.KernelCore.SelfHost

/-
Matched native C0 lifting benchmark. Compare exactly the old fuel-based
lifting with direct structural lifting; before measuring, assert identical
source trees and changed flags. Timings are informational.
-/
private def liftSpine (depth : Nat) : PsKernelExpr :=
  match depth with
  | Nat.zero => PsKernelExpr.bvar 2
  | Nat.succ n =>
      PsKernelExpr.app (liftSpine n) (PsKernelExpr.bvar 0)

private def liftOld (term : PsKernelExpr) : Prod PsKernelExpr Bool :=
  psKernelExprLiftLooseBVarsChangedWithFuel
    (Nat.succ (psKernelExprNodeCount term)) term 0 3

private def liftNew (term : PsKernelExpr) : Prod PsKernelExpr Bool :=
  psKernelExprLiftLooseBVarsChanged term 0 3

private def liftLoop (optimized : Bool)
    (times : Nat) (term : PsKernelExpr) : IO Nat := do
  let mut checksum := 0
  for _ in [:times] do
    let result := if optimized then liftNew term else liftOld term
    checksum := checksum + psKernelExprNodeCount (Prod.fst result)
  pure checksum

private def liftBenchCase (depth times : Nat) : IO Unit := do
  let term := liftSpine depth
  let expected := liftOld term
  let actual := liftNew term
  unless psKernelExprEq (Prod.fst expected) (Prod.fst actual) &&
      Prod.snd expected == Prod.snd actual do
    throw (IO.userError "PSC1_C0_LIFT_PARITY_FAILED")
  let oldStart ← IO.monoMsNow
  let oldSum ← liftLoop false times term
  let oldEnd ← IO.monoMsNow
  let newStart ← IO.monoMsNow
  let newSum ← liftLoop true times term
  let newEnd ← IO.monoMsNow
  unless oldSum == newSum do
    throw (IO.userError "PSC1_C0_LIFT_CHECKSUM_FAILED")
  IO.println s!"PSC1_C0_LIFT_BENCH depth={depth} calls={times} prior_ms={oldEnd-oldStart} c0_ms={newEnd-newStart} checksum={newSum}"

def main : IO Unit := do
  liftBenchCase 12 25000
  liftBenchCase 32 25000
  IO.println "PSC1_C0_LIFT_BENCH: COMPLETE"
