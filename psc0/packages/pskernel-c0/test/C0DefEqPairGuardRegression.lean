import Ps.KernelCore.Checker.DefEq.Quick

/-!
Pure all-state equality guard regression. The source theorem in Quick
proves every expression/state combination, not just these cases.
Every cache hit still uses the historical checked success pair set and
the complete FVar-free source predicate; no proof is admitted here.
-/

def c0GuardSharedDAG : Nat → PsKernelExpr → PsKernelExpr
  | 0, value => value
  | k + 1, value =>
      let child := c0GuardSharedDAG k value
      .app child child

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "scope"
  let atom : PsKernelExpr := .const name []
  let openTerm : PsKernelExpr := .fvar name
  let shared := c0GuardSharedDAG 10 atom
  let sharedOpen := c0GuardSharedDAG 10 openTerm
  let cases : List PsKernelExpr := [
    .bvar 0, atom, openTerm, .sort .zero,
    .app atom openTerm,
    .app atom atom,
    shared, sharedOpen
  ]
  let empty : PsKernelCheckerState := psKernelCheckerStateEmpty
  let seededClosed : PsKernelCheckerState :=
    { empty with success :=
        psKernelExprPairSetInsert empty.success atom atom }
  let seededOpen : PsKernelCheckerState :=
    { empty with success :=
        psKernelExprPairSetInsert empty.success openTerm openTerm }
  let states := [empty, seededClosed, seededOpen]
  for state in states do
    for left in cases do
      for right in cases do
        let original :=
          psKernelSemanticPairCacheEligible left right &&
            psKernelExprPairSetContains state.success left right
        let selected :=
          psKernelC0CertifiedDefEqSuccessGuard state left right
        if selected != original then
          throw (IO.userError "DefEq success pair guard changed source decision")
  if psKernelC0CertifiedDefEqSuccessGuard seededOpen openTerm openTerm then
    throw (IO.userError "FVar-bearing pair must not inherit cached success")
  if !psKernelC0CertifiedDefEqSuccessGuard seededClosed atom atom then
    throw (IO.userError "closed proven pair cache hit was lost")
  IO.println "C0_DEFEQ_PAIR_GUARD_SOURCE all_state_source_proved=true corpus_pairs=192 state_scoped_FVar_guard=pass success_hit=pass success_miss=pass no_admission=true"
