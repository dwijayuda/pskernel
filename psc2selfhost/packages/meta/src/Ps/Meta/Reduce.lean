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

def psDefEqReadOnlyWithEnvFuel
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext) :
    Nat -> PsExpr -> PsExpr -> Bool
  | 0, left, right =>
      psExprAlphaEq
        (psWhnf environment metaContext localContext left)
        (psWhnf environment metaContext localContext right)
  | remaining + 1, left, right =>
      let leftValue :=
        psWhnf environment metaContext localContext left
      let rightValue :=
        psWhnf environment metaContext localContext right
      if psExprAlphaEq leftValue rightValue then
        true
      else
        match leftValue, rightValue with
        | .app leftFn leftArg, .app rightFn rightArg =>
            psDefEqReadOnlyWithEnvFuel
                environment
                metaContext
                localContext
                remaining
                leftFn
                rightFn
              && psDefEqReadOnlyWithEnvFuel
                environment
                metaContext
                localContext
                remaining
                leftArg
                rightArg
        | .lam _ leftType leftBody _,
          .lam _ rightType rightBody _ =>
            psDefEqReadOnlyWithEnvFuel
                environment
                metaContext
                localContext
                remaining
                leftType
                rightType
              && psDefEqReadOnlyWithEnvFuel
                environment
                metaContext
                localContext
                remaining
                leftBody
                rightBody
        | .forallE _ leftType leftBody _,
          .forallE _ rightType rightBody _ =>
            psDefEqReadOnlyWithEnvFuel
                environment
                metaContext
                localContext
                remaining
                leftType
                rightType
              && psDefEqReadOnlyWithEnvFuel
                environment
                metaContext
                localContext
                remaining
                leftBody
                rightBody
        | .proj leftType leftIndex leftValue,
          .proj rightType rightIndex rightValue =>
            psNameEq leftType rightType
              && leftIndex == rightIndex
              && psDefEqReadOnlyWithEnvFuel
                environment
                metaContext
                localContext
                remaining
                leftValue
                rightValue
        | _, _ => false

def psDefEqReadOnlyWithEnv
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (left : PsExpr)
    (right : PsExpr) : Bool :=
  psDefEqReadOnlyWithEnvFuel
    environment
    metaContext
    localContext
    256
    left
    right
