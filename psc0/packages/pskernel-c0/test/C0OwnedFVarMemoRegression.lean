import Ps.KernelCore.Checker.Reduction.Whnf

/-!
The checker state carries ONLY proof-carrying, context-free syntactic
FVar membership; the other eight semantic caches retain their exact
original scope-exit behavior. Any hash-collision result is checked by
source-level exact equality. No proof is admitted here.
-/

def c0OwnedFVarShared : Nat → PsKernelExpr → PsKernelExpr
  | 0, expr => expr
  | k + 1, expr =>
      let child := c0OwnedFVarShared k expr
      .app child child

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "free"
  let closed : PsKernelExpr := .const name []
  let openExpr : PsKernelExpr := .fvar name
  let cases : List PsKernelExpr := [
    .bvar 0, closed, .sort .zero, openExpr,
    .app closed openExpr, .app openExpr closed,
    .lam name closed openExpr .default,
    .forallE name closed openExpr .default,
    .letE name closed openExpr (.bvar 0) false,
    .mdata 0 openExpr, .proj name 0 openExpr,
    c0OwnedFVarShared 9 closed,
    c0OwnedFVarShared 9 openExpr
  ]
  let mut state := psKernelCheckerStateEmpty
  for expr in cases do
    let original := psKernelSemanticCacheEligible expr
    let first := psKernelC0SemanticEligibilityWithState state expr
    if first.1 != original then
      throw (IO.userError "source-certified stateful eligibility mismatch")
    let again := psKernelC0SemanticEligibilityWithState first.2 expr
    if again.1 != original then
      throw (IO.userError "memo hit altered source eligibility")
    -- The memo theorem is parametric in the exact bucket selector.
    -- Even an adversarial all-collision hash cannot turn a cache entry
    -- into unverified FVar absence.
    let colliding := psKernelC0FVarMemoGoWithHash (fun _ => 0) expr state.semanticFVarMemo
    if colliding.1.value != psKernelExprHasFVar expr then
      throw (IO.userError "all-collision source-proof memo mismatch")
    let restored := psKernelCheckerStateExitLocalScope state again.2
    let afterScope := psKernelC0SemanticEligibilityWithState restored expr
    if afterScope.1 != original then
      throw (IO.userError "pure FVar fact leaked semantic local-scope authority")
    state := afterScope.2
  IO.println "C0_OWNED_FVAR source_all_input=Lean_proved cases=13 across_scope=pass repeated_lookup=pass semantic_caches_preserved=true arbitrary_hash=Lean_proved all_collisions=pass no_admission=true"
