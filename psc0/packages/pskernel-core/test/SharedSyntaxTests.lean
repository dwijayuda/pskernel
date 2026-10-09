import Ps.KernelCore.Core.Substitution.Abstract

private instance : BEq PsKernelExpr := ⟨fun a b => decide (a = b)⟩

private def ensure (b : Bool) (message : String) : IO Unit :=
  if b then pure () else throw (IO.userError message)

private def dag (depth : Nat) (leaf : PsKernelExpr) : PsKernelExpr :=
  match depth with
  | 0 => leaf
  | n + 1 => let child := dag n leaf; .app child child

private def examples : List PsKernelExpr :=
  let n := PsKernelName.str .anonymous "x"
  let p := PsKernelName.str .anonymous "u"
  let shared := dag 5 (.app (.bvar 1) (.fvar n))
  [ .bvar 0, .bvar 3, .fvar n, .mvar n, .sort (.param p),
    .const n [.param p], .lit (.nat 42), .lit (.str "λ"),
    shared, .app shared (.lam n (.sort .zero) shared .default),
    .forallE n shared shared .implicit, .letE n shared shared shared false,
    .mdata 99 shared, .proj n 0 shared ]

def main : IO Unit := do
  let n := PsKernelName.str .anonymous "x"
  let p := PsKernelName.str .anonymous "u"
  let subst := [PsKernelExpr.fvar n, PsKernelExpr.bvar 4]
  for e in examples do
    for d in [0, 1, 2, 5] do
      ensure (psKernelExprHasLooseAtShared e d ==
        PsKernelSharing.fold PsKernelSharing.looseAlgebra e d) "loose-variable fold"
      ensure (psKernelExprInstantiateAtChangedShared e 1 subst d ==
        PsKernelSharing.fold (PsKernelSharing.instantiateAlgebra 1 subst) e d) "substitution cursor"
      ensure (psKernelExprLiftLooseBVarsChangedShared e d 3 ==
        PsKernelSharing.fold (PsKernelSharing.liftAlgebra 3) e d) "lifting cursor"
      ensure (psKernelExprAbstractFVarsAtChangedShared e [n, n] d ==
        PsKernelSharing.fold (PsKernelSharing.abstractAlgebra [n, n]) e d) "abstraction cursor"
    ensure (psKernelExprInstantiateLevelParamsShared e [p] [.zero] ==
      PsKernelSharing.fold (PsKernelSharing.levelAlgebra [p] [.zero]) e 0) "level substitution"
  for e in examples do
    for f in examples do
      ensure (psKernelExprEq e f == PsKernelSharing.eqSpec (e, f) 0) "exact syntactic equality"
  let collisionEntry : PsKernelSharing.Entry PsKernelExpr Bool
      (PsKernelSharing.fold PsKernelSharing.looseAlgebra) :=
    ⟨.bvar 0, 0, true, rfl⟩
  let collisionMemo : PsKernelSharing.Memo PsKernelExpr Bool
      (PsKernelSharing.fold PsKernelSharing.looseAlgebra) :=
    ({} : PsKernelSharing.Memo PsKernelExpr Bool
      (PsKernelSharing.fold PsKernelSharing.looseAlgebra)).insert (0, 0) collisionEntry
  let missNode := PsKernelSharing.value
    (PsKernelSharing.probe (0, 0) (.sort .zero) 0 collisionMemo (fun _ =>
      Squash.mk (⟨false, rfl⟩, collisionMemo)))
  ensure (!missNode) "hash collision must validate the node"
  let missCursor := PsKernelSharing.value
    (PsKernelSharing.probe (0, 0) (.bvar 0) 1 collisionMemo (fun _ =>
      Squash.mk (⟨false, rfl⟩, collisionMemo)))
  ensure (!missCursor) "hash collision must validate the cursor"
  let depth := 32
  let closed := dag depth (.sort .zero)
  ensure (psKernelExprNodeCount closed == 2 ^ (depth + 1) - 1) "shared node count"
  ensure (!psKernelExprHasLooseBVar closed) "shared closed-variable query"
  ensure (!psKernelExprHasFVar closed) "shared free-variable query"
  let openDag := dag depth (.bvar 1)
  let result := psKernelExprInstantiateAt openDag 0 subst 0
  ensure (psKernelExprNodeCount result == 2 ^ (depth + 1) - 1) "shared substitution result"
  ensure (psKernelExprHasLooseAt result 4) "shared substitution leaf"
  let abstracted := psKernelExprAbstractFVars (dag depth (.fvar n)) [n]
  ensure (psKernelExprHasLooseBVar abstracted) "shared abstraction result"
  let lifted := psKernelExprLift openDag 3
  ensure (psKernelExprHasLooseAt lifted 4) "shared lifting result"
  let levelResult := psKernelExprInstantiateLevelParams (dag depth (.sort (.param p))) [p] [.zero]
  ensure (psKernelExprNodeCount levelResult == 2 ^ (depth + 1) - 1) "shared universe result"
  ensure (psKernelExprEq closed closed) "shared reflexivity"
  ensure (psKernelExprEq closed levelResult) "independently rebuilt shared equality"
  ensure (psKernelExprEq closed (psKernelExprInstantiateLevelParams closed [] [.zero]))
    "empty universe substitution with arbitrary values"
  let preparedClosed := PsKernelSharing.prepareReplacement closed
  for amount in [0, 1, 7, 100] do
    ensure (psKernelExprEq (preparedClosed.liftAt amount) closed) "prepared closed argument"
  let preparedOpen := PsKernelSharing.prepareSubst [PsKernelExpr.bvar 2, .fvar n]
  ensure (PsKernelSharing.preparedLookup preparedOpen 0 5 == some (.bvar 7))
    "prepared open argument still lifts"
  ensure (PsKernelSharing.preparedLookup preparedOpen 2 5 == none)
    "prepared substitution preserves missing entries"
  let underBinder := PsKernelExpr.lam n (.sort .zero) (dag depth (.bvar 1)) .default
  let substituted := psKernelExprInstantiate1 underBinder closed
  let expected := PsKernelExpr.lam n (.sort .zero) (dag depth closed) .default
  ensure (psKernelExprEq substituted expected) "closed argument shared beneath binder"
  IO.println "PSKERNEL_SHARED_SYNTAX: PASS cursors=4 variants=14 DAG-depth=32"
