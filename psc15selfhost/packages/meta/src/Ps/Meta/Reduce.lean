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
      let instantiated := psMetaInstantiate metaContext expr;
      match instantiated with
      | .fvar id =>
          match psLocalFindById localContext id with
          | some declaration =>
              match declaration with
              | .letDecl _ _ _ value =>
                  psWhnfCoreWithFuel metaContext localContext fuel value
              | _ => instantiated
          | none => instantiated
      | .letE _ _ value body =>
          psWhnfCoreWithFuel
            metaContext
            localContext
            fuel
            (psExprInstantiate1 body value)
      | .app fn arg =>
          let reducedFn := psWhnfCoreWithFuel metaContext localContext fuel fn;
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
  let leftValue := psWhnfCore metaContext localContext left;
  let rightValue := psWhnfCore metaContext localContext right;
  psExprAlphaEq leftValue rightValue

def psWhnfWithFuel
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext) : Nat -> PsExpr -> PsExpr
  | 0, expr => psWhnfCore metaContext localContext expr
  | fuel + 1, expr =>
      let core := psWhnfCoreWithFuel metaContext localContext fuel expr;
      match core with
      | .constE name levels =>
          match psEnvironmentFind environment name with
          | none => core
          | some declaration =>
              match psDeclarationValue declaration with
              | none => core
              | some value =>
                  let parameters := psDeclarationLevelParams declaration;
                  if Nat.beq parameters.length levels.length then
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
            psWhnfWithFuel environment metaContext localContext fuel fn;
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
        psWhnf environment metaContext localContext left;
      let rightValue :=
        psWhnf environment metaContext localContext right;
      if psExprAlphaEq leftValue rightValue then
        true
      else
        match leftValue with
        | .app leftFn leftArg =>
            match rightValue with
            | .app rightFn rightArg =>
                if psDefEqReadOnlyWithEnvFuel
                    environment
                    metaContext
                    localContext
                    remaining
                    leftFn
                    rightFn then
                  psDefEqReadOnlyWithEnvFuel
                    environment
                    metaContext
                    localContext
                    remaining
                    leftArg
                    rightArg
                else
                  false
            | _ => false
        | .lam _ leftType leftBody _ =>
            match rightValue with
            | .lam _ rightType rightBody _ =>
                if psDefEqReadOnlyWithEnvFuel
                    environment
                    metaContext
                    localContext
                    remaining
                    leftType
                    rightType then
                  psDefEqReadOnlyWithEnvFuel
                    environment
                    metaContext
                    localContext
                    remaining
                    leftBody
                    rightBody
                else
                  false
            | _ => false
        | .forallE _ leftType leftBody _ =>
            match rightValue with
            | .forallE _ rightType rightBody _ =>
                if psDefEqReadOnlyWithEnvFuel
                    environment
                    metaContext
                    localContext
                    remaining
                    leftType
                    rightType then
                  psDefEqReadOnlyWithEnvFuel
                    environment
                    metaContext
                    localContext
                    remaining
                    leftBody
                    rightBody
                else
                  false
            | _ => false
        | .proj leftType leftIndex leftValue =>
            match rightValue with
            | .proj rightType rightIndex rightValue =>
                if psNameEq leftType rightType then
                  if Nat.beq leftIndex rightIndex then
                    psDefEqReadOnlyWithEnvFuel
                      environment
                      metaContext
                      localContext
                      remaining
                      leftValue
                      rightValue
                  else
                    false
                else
                  false
            | _ => false
        | _ => false

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
