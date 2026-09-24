import Ps.Core.Equality
import Ps.Core.Subst
import Ps.Core.LevelSubst
import Ps.Environment.Basic
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

def psWhnfWithFuel
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext) : Nat -> PsExpr -> PsExpr
  | 0, expr => psWhnfCore metaContext localContext expr
  | fuel + 1, expr =>
      let core := psWhnfCoreWithFuel metaContext localContext fuel expr
      match core with
      | .constE name levels =>
          match psEnvironmentFind environment name with
          | none => core
          | some declaration =>
              match psDeclarationValue declaration with
              | none => core
              | some value =>
                  let parameters := psDeclarationLevelParams declaration
                  if parameters.length == levels.length then
                    psWhnfWithFuel
                      environment
                      metaContext
                      localContext
                      fuel
                      (psExprInstantiateLevelParams parameters levels value)
                  else
                    core
      | .app fn arg =>
          let reducedFn :=
            psWhnfWithFuel environment metaContext localContext fuel fn
          if psExprAlphaEq reducedFn fn then
            core
          else
            psWhnfWithFuel
              environment
              metaContext
              localContext
              fuel
              (PsExpr.app reducedFn arg)
      | _ => core

def psWhnf
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (expr : PsExpr) : PsExpr :=
  psWhnfWithFuel environment metaContext localContext 256 expr

def psDefEqReadOnlyWithEnv
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (left : PsExpr)
    (right : PsExpr) : Bool :=
  let leftValue := psWhnf environment metaContext localContext left
  let rightValue := psWhnf environment metaContext localContext right
  psExprAlphaEq leftValue rightValue
