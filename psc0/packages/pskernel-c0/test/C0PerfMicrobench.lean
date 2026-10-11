import Ps.KernelCore.Core.Substitution.Instantiate
import Ps.KernelCore.Core.LocalContext

/-
Native Lean C0 performance microbenchmarks. No self-hosting or proof work.
Inputs vary across iterations to limit loop-invariant computation elimination.
All times are single-run runner observations, not kernel throughput claims.
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
  let first := c0BenchApps 512 (PsKernelExpr.bvar 0) arg
  let second := c0BenchApps 512 (PsKernelExpr.bvar 1) arg
  let iterations := 30000

  let mut legacyHits : Nat := 0
  let startedOld ← IO.monoMsNow
  for k in [:iterations] do
    let other := if k % 2 == 0 then first else second
    if psKernelExprEqLegacy first other then
      legacyHits := legacyHits + 1
  let finishedOld ← IO.monoMsNow
  let mut fastHits : Nat := 0
  let startedNew ← IO.monoMsNow
  for k in [:iterations] do
    let other := if k % 2 == 0 then first else second
    if psKernelExprEq first other then
      fastHits := fastHits + 1
  let finishedNew ← IO.monoMsNow
  if !(Nat.beq legacyHits fastHits) then
    throw (IO.userError "equality comparison results diverged")
  IO.println s!"C0_BENCH paired_equality legacy_ms={finishedOld - startedOld} paired_ms={finishedNew - startedNew} hits={fastHits} iterations={iterations}"

  let mut oldChanged : Nat := 0
  let oldStart ← IO.monoMsNow
  for k in [:iterations] do
    let result :=
      psKernelExprLiftLooseBVarsChangedWithFuel
        (Nat.succ (psKernelExprNodeCount first)) first (k % 3) (k % 4)
    if Prod.snd result then oldChanged := oldChanged + 1
  let oldEnd ← IO.monoMsNow
  let mut newChanged : Nat := 0
  let newStart ← IO.monoMsNow
  for k in [:iterations] do
    let result := psKernelExprLiftLooseBVarsChanged first (k % 3) (k % 4)
    if Prod.snd result then newChanged := newChanged + 1
  let newEnd ← IO.monoMsNow
  if !(Nat.beq oldChanged newChanged) then
    throw (IO.userError "lifting results diverged")
  IO.println s!"C0_BENCH lifting legacy_ms={oldEnd - oldStart} direct_ms={newEnd - newStart} changed={newChanged} iterations={iterations}"

  let mut genericApps : Nat := 0
  let subsStart ← IO.monoMsNow
  for k in [:iterations] do
    let result :=
      psKernelExprInstantiateAt first 0 [PsKernelExpr.bvar (k % 4)] 0
    match result with
    | PsKernelExpr.app _ _ => genericApps := genericApps + 1
    | _ => throw (IO.userError "generic substitution changed form")
  let subsEnd ← IO.monoMsNow
  let mut specializedApps : Nat := 0
  let c0Start ← IO.monoMsNow
  for k in [:iterations] do
    let result := psKernelExprInstantiate1 first (PsKernelExpr.bvar (k % 4))
    match result with
    | PsKernelExpr.app _ _ => specializedApps := specializedApps + 1
    | _ => throw (IO.userError "single substitution changed form")
  let c0End ← IO.monoMsNow
  if !(Nat.beq genericApps specializedApps) then
    throw (IO.userError "substitution counts diverged")
  IO.println s!"C0_BENCH instantiate1 generic_ms={subsEnd - subsStart} specialized_ms={c0End - c0Start} apps={specializedApps} iterations={iterations}"

  let sort0 := PsKernelExpr.sort PsKernelLevel.zero
  let mut locals := psKernelLocalContextEmpty
  for k in [:512] do
    let name := PsKernelName.num PsKernelName.anonymous k
    locals := psKernelLocalContextAddLocal locals name name
      sort0 PsKernelBinderInfo.default
  let queries := 20000
  let mut legacyLookupHits : Nat := 0
  let lookupStart ← IO.monoMsNow
  for k in [:queries] do
    let name := PsKernelName.num PsKernelName.anonymous (k % 16)
    match psKernelLocalContextFindIn name locals.decls with
    | Option.some _ => legacyLookupHits := legacyLookupHits + 1
    | Option.none => throw (IO.userError "linear local lookup missing")
  let lookupEnd ← IO.monoMsNow
  let mut indexedLookupHits : Nat := 0
  let indexedStart ← IO.monoMsNow
  for k in [:queries] do
    let name := PsKernelName.num PsKernelName.anonymous (k % 16)
    match psKernelLocalContextFind locals name with
    | Option.some _ => indexedLookupHits := indexedLookupHits + 1
    | Option.none => throw (IO.userError "indexed local lookup missing")
  let indexedEnd ← IO.monoMsNow
  if !(Nat.beq legacyLookupHits indexedLookupHits) then
    throw (IO.userError "local lookup counts diverged")
  IO.println s!"C0_BENCH locals linear_ms={lookupEnd - lookupStart} indexed_ms={indexedEnd - indexedStart} entries=512 queries={queries}"

