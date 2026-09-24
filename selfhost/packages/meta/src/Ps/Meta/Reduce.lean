import Ps.Core.Equality
import Ps.Core.Subst
import Ps.Environment.LocalContext
import Ps.Meta.Context

def psWhnfCoreWithFuel
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext) : Nat -> PsExpr -> PsExpr
  | 0, expr => psMetaInstantiate metaContext expr
  | fuel + 1, expr =>
      let instantiated := psMetaInstantiate metaContext expr
      match instantiated with
      | .fvar id =>
          match psLocalFindById localContext id with
          | some (.letDecl _ _ _ value) =>
              psWhnfCoreWithFuel metaContext localContext fuel value
          | _ => instantiated
      | .letE _ _ value body =>
          psWhnfCoreWithFuel
            metaContext
            localContext
            fuel
            (psExprInstantiate1 body value)
      | .app fn arg =>
          let reducedFn := psWhnfCoreWithFuel metaContext localContext fuel fn
          match reducedFn with
          | .lam _ _ body _ =>
              psWhnfCoreWithFuel
                metaContext
                localContext
                fuel
                (psExprInstantiate1 body arg)
          | _ => PsExpr.app reducedFn arg
      | _ => instantiated

def psWhnfCore
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (expr : PsExpr) : PsExpr :=
  psWhnfCoreWithFuel metaContext localContext 256 expr

def psDefEqReadOnly
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (left : PsExpr)
    (right : PsExpr) : Bool :=
  let leftValue := psWhnfCore metaContext localContext left
  let rightValue := psWhnfCore metaContext localContext right
  psExprAlphaEq leftValue rightValue
