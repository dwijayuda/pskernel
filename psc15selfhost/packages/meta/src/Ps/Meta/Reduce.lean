import Ps.Core.Equality
import Ps.Core.Subst
import Ps.Core.LevelSubst
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Meta.Context

def psWhnfCoreWithFuel
    (fuel : Nat)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext) : PsExpr -> PsExpr :=
  match fuel with
  | Nat.zero =>
      fun (expr : PsExpr) => psMetaInstantiate metaContext expr
  | Nat.succ remaining =>
      let smaller : PsExpr -> PsExpr :=
        psWhnfCoreWithFuel remaining metaContext localContext;
      fun (expr : PsExpr) =>
        let instantiated := psMetaInstantiate metaContext expr;
        match instantiated with
        | .fvar id =>
            match psLocalFindById localContext id with
            | some declaration =>
                match declaration with
                | .letDecl _ _ _ value => smaller value
                | _ => instantiated
            | none => instantiated
        | .letE _ _ value body =>
            smaller (psExprInstantiate1 body value)
        | .app fn arg =>
            let reducedFn := smaller fn;
            match reducedFn with
            | .lam _ _ body _ =>
                smaller (psExprInstantiate1 body arg)
            | _ => PsExpr.app reducedFn arg
        | _ => instantiated

def psWhnfCoreApplyFuel
    (fuel : Nat)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (expr : PsExpr) : PsExpr :=
  let worker : PsExpr -> PsExpr :=
    psWhnfCoreWithFuel fuel metaContext localContext;
  worker expr

def psWhnfCore
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (expr : PsExpr) : PsExpr :=
  psWhnfCoreApplyFuel 256 metaContext localContext expr

def psDefEqReadOnly
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (left : PsExpr)
    (right : PsExpr) : Bool :=
  let leftValue := psWhnfCore metaContext localContext left;
  let rightValue := psWhnfCore metaContext localContext right;
  psExprAlphaEq leftValue rightValue

def psWhnfWithFuel
    (fuel : Nat)
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext) : PsExpr -> PsExpr :=
  match fuel with
  | Nat.zero =>
      fun (expr : PsExpr) => psWhnfCore metaContext localContext expr
  | Nat.succ remaining =>
      let smaller : PsExpr -> PsExpr :=
        psWhnfWithFuel remaining environment metaContext localContext;
      fun (expr : PsExpr) =>
        let core :=
          psWhnfCoreApplyFuel remaining metaContext localContext expr;
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
                      smaller
                        (psExprInstantiateLevelParams
                          parameters levels value)
                    else
                      core
        | .app fn arg =>
            let reducedFn := smaller fn;
            if psExprAlphaEq reducedFn fn then
              core
            else
              smaller (PsExpr.app reducedFn arg)
        | _ => core

def psWhnf
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (expr : PsExpr) : PsExpr :=
  let worker : PsExpr -> PsExpr :=
    psWhnfWithFuel 256 environment metaContext localContext;
  worker expr

def psDefEqReadOnlyWithEnvFuel
    (fuel : Nat)
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext) :
    PsExpr -> PsExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (left : PsExpr) =>
        fun (right : PsExpr) =>
          psExprAlphaEq
            (psWhnf environment metaContext localContext left)
            (psWhnf environment metaContext localContext right)
  | Nat.succ remaining =>
      let smaller : PsExpr -> PsExpr -> Bool :=
        psDefEqReadOnlyWithEnvFuel
          remaining environment metaContext localContext;
      fun (left : PsExpr) =>
        fun (right : PsExpr) =>
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
                    if smaller leftFn rightFn then
                      smaller leftArg rightArg
                    else
                      false
                | _ => false
            | .lam _ leftType leftBody _ =>
                match rightValue with
                | .lam _ rightType rightBody _ =>
                    if smaller leftType rightType then
                      smaller leftBody rightBody
                    else
                      false
                | _ => false
            | .forallE _ leftType leftBody _ =>
                match rightValue with
                | .forallE _ rightType rightBody _ =>
                    if smaller leftType rightType then
                      smaller leftBody rightBody
                    else
                      false
                | _ => false
            | .proj leftType leftIndex leftValue =>
                match rightValue with
                | .proj rightType rightIndex rightValue =>
                    if psNameEq leftType rightType then
                      if Nat.beq leftIndex rightIndex then
                        smaller leftValue rightValue
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
  let worker : PsExpr -> PsExpr -> Bool :=
    psDefEqReadOnlyWithEnvFuel 256 environment metaContext localContext;
  worker left right
