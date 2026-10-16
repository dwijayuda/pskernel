import Ps.KernelCore.Core.FastExactAppEq

/-!
Source equality is proven by Lean's Decidable proof irrelevance for all
expressions. The large nested-shared-DAG case is therefore checked with
only the optimized decision procedure; invoking the old generated routine
on the 2^28 expanded tree would be a nonbenchmarking hang.
-/

def c0FastAppEqBool (a b : PsKernelExpr) : Bool :=
  match psKernelC0FastAppDecEq a b with
  | .isTrue _ => true
  | .isFalse _ => false

def main : IO Unit := do
  let base : PsKernelExpr := .fvar (.str .anonymous "x")
  let meta : PsKernelExpr := .mdata 8 (.sort .zero)
  let differing : PsKernelExpr := .mdata 9 (.sort .zero)
  let sample : List PsKernelExpr := [
    .bvar 0, .bvar 1, base,
    .app base (.lit (.nat 1)),
    .lam (.str .anonymous "a") (.sort .zero) (.bvar 0) .default,
    .forallE (.str .anonymous "b") meta differing .implicit,
    .letE (.str .anonymous "z") meta base (.app (.bvar 0) base) false,
    .app (.app base base) meta,
    .proj (.str .anonymous "S") 2 meta,
    meta, differing
  ]
  for a in sample do
    for b in sample do
      let proof : psKernelC0FastAppDecEq a b =
          (inferInstance : Decidable (a = b)) :=
        psKernelC0FastAppDecEq_source a b
      let expected : Bool := decide (a = b)
      if c0FastAppEqBool a b != expected then
        throw (IO.userError "fast exact app equality disagrees with source")
  let depth := 28
  let shared := (List.range depth).foldl
    (fun e (_ : Nat) => PsKernelExpr.app e e) base
  let left := PsKernelExpr.app shared (.lit (.nat 13))
  let different := PsKernelExpr.app shared (.lit (.nat 14))
  let same := PsKernelExpr.app shared (.lit (.nat 13))
  let t0 ← IO.monoNanosNow
  let equal := c0FastAppEqBool left same
  let notEqual := c0FastAppEqBool left different
  let t1 ← IO.monoNanosNow
  if !equal || notEqual then
    throw (IO.userError "large shared app equality/inequality is incorrect")
  let _allSource : psKernelC0FastAppDecEq left different =
      (inferInstance : Decidable (left = different)) :=
    psKernelC0FastAppDecEq_source left different
  IO.println s!"C0_FAST_APP_EQ source=Lean_proved depth={depth} same=pass distinct=pass elapsed_ms={(t1-t0)/1000000}"
