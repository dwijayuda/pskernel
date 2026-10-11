import Ps.KernelCore.Core.Substitution.Instantiate

/-
Native Lean-only performance measurements. No PSC0 bootstrap or self hosting.
The baseline functions are preserved in C0 as behavioral/performance oracles.
Single runner timings should not be interpreted as stable speedup factors.
-/

def c0BenchApps (count : Nat)
    (current : PsKernelExpr)
    (arg : PsKernelExpr) : PsKernelExpr :=
  match count with
  | 0 => current
  | Nat.succ rest =>
      c0BenchApps rest (PsKernelExpr.app current arg) arg

def main : IO Unit := do
  let arg := PsKernelExpr.bvar 2
  let first := c0BenchApps 256 (PsKernelExpr.bvar 0) arg
  let second := c0BenchApps 256 (PsKernelExpr.bvar 1) arg
  let iterations := 700
  let startedOld ← IO.monoMsNow
  for _ in [:iterations] do
    if psKernelExprEqLegacy first second then
      throw (IO.userError "legacy expression equality unexpectedly true")
  let finishedOld ← IO.monoMsNow
  let startedNew ← IO.monoMsNow
  for _ in [:iterations] do
    if psKernelExprEq first second then
      throw (IO.userError "C0 expression equality unexpectedly true")
  let finishedNew ← IO.monoMsNow
  IO.println s!"C0_BENCH paired_equality legacy_ms={finishedOld - startedOld} paired_ms={finishedNew - startedNew} iterations={iterations}"

  let oldStart ← IO.monoMsNow
  for _ in [:iterations] do
    let result :=
      psKernelExprLiftLooseBVarsChangedWithFuel
        (Nat.succ (psKernelExprNodeCount first)) first 0 1
    if !(Prod.snd result) then
      throw (IO.userError "legacy lift unexpectedly unchanged")
  let oldEnd ← IO.monoMsNow
  let newStart ← IO.monoMsNow
  for _ in [:iterations] do
    let result := psKernelExprLiftLooseBVarsChanged first 0 1
    if !(Prod.snd result) then
      throw (IO.userError "new lift unexpectedly unchanged")
  let newEnd ← IO.monoMsNow
  IO.println s!"C0_BENCH lifting legacy_ms={oldEnd - oldStart} direct_ms={newEnd - newStart} iterations={iterations}"

  let subsStart ← IO.monoMsNow
  for _ in [:iterations] do
    let result := psKernelExprInstantiateAt first 0 [arg] 0
    match result with
    | PsKernelExpr.app _ _ => pure ()
    | _ => throw (IO.userError "generic substitution changed form")
  let subsEnd ← IO.monoMsNow
  let c0Start ← IO.monoMsNow
  for _ in [:iterations] do
    let result := psKernelExprInstantiate1 first arg
    match result with
    | PsKernelExpr.app _ _ => pure ()
    | _ => throw (IO.userError "single substitution changed form")
  let c0End ← IO.monoMsNow
  IO.println s!"C0_BENCH instantiate1 generic_ms={subsEnd - subsStart} specialized_ms={c0End - c0Start} iterations={iterations}"
