import Ps.KernelCore.Admission.Declaration.Validation

/-!
These tests never trust node metadata as a proof judgment. The source theorems
in Validation.lean establish every-input equivalence and exact first offender.
Only after real native execution and whole-proof A/B can the guarded function
be considered for selected admission call sites.
-/

def c0LevelFlagOptionEq : Option PsKernelName → Option PsKernelName → Bool
  | none, none => true
  | some a, some b => psKernelNameEq a b
  | _, _ => false

def c0LevelFlagMakeShared : Nat → PsKernelExpr → PsKernelExpr
  | 0, leaf => leaf
  | n + 1, leaf =>
      let child := c0LevelFlagMakeShared n leaf
      .app child child

def main : IO Unit := do
  let a : PsKernelName := .str .anonymous "a"
  let b : PsKernelName := .str .anonymous "b"
  let bare : PsKernelExpr := .const a [.zero]
  let uA : PsKernelExpr := .sort (.param a)
  let uB : PsKernelExpr := .sort (.param b)
  let xs : List PsKernelExpr := [
    .bvar 0, .fvar a, .mvar b, .sort .zero,
    bare, uA, uB, .const a [.zero, .param b],
    .app bare bare, .app uA uB, .app uB uA,
    .lam a uA bare .explicit,
    .forallE a bare uB .default,
    .letE a bare uA bare false,
    .mdata 7 uB, .proj a 0 bare, .lit (.nat 9)]
  for expr in xs do
    let _witness : expr.psKernelC0LevelParamFlag =
        psKernelExprHasLevelParam expr :=
      psKernelC0LevelParamFlag_source expr
    for allowed in [[], [a], [a, b]] do
      let old := psKernelFindUndefExprLevelParam expr allowed
      let current := psKernelC0FindUndefWithNodeFlag expr allowed
      let _exact : current = old :=
        psKernelC0FindUndefWithNodeFlag_source expr allowed
      unless c0LevelFlagOptionEq current old do
        throw (IO.userError "computed param flag changed first-offender result")
  let pureDag := c0LevelFlagMakeShared 4000 bare
  let paramDag := c0LevelFlagMakeShared 4000 uA
  let _closedWitness : pureDag.psKernelC0LevelParamFlag =
      psKernelExprHasLevelParam pureDag :=
    psKernelC0LevelParamFlag_source pureDag
  let _openWitness : paramDag.psKernelC0LevelParamFlag =
      psKernelExprHasLevelParam paramDag :=
    psKernelC0LevelParamFlag_source paramDag
  let start ← IO.monoNanosNow
  if pureDag.psKernelC0LevelParamFlag then
    throw (IO.userError "false-positive param in closed deep DAG")
  if !paramDag.psKernelC0LevelParamFlag then
    throw (IO.userError "false-negative param in deep DAG")
  if (psKernelC0FindUndefWithNodeFlag pureDag []).isSome then
    throw (IO.userError "false undefined level in 4000-level closed DAG")
  let duration ← IO.monoNanosNow
  IO.println s!"C0_LEVEL_PARAM_NODE_FLAG source=all_inputs cases=17 allowed_lists=3 deep_shared_depth=4000 milliseconds={(duration-start)/1000000} first_offender=unchanged native_absence=fast no_admission=true"
