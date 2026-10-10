import Ps.Core.Equality
import Ps.Core.Subst
import Ps.Core.LevelSubst
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Meta.Context

def psReduceNameListLength
    (values : List PsName) : Nat :=
  match values with
  | [] => 0
  | _ :: rest => Nat.succ (psReduceNameListLength rest)

def psReduceLevelListLength
    (values : List PsLevel) : Nat :=
  match values with
  | [] => 0
  | _ :: rest => Nat.succ (psReduceLevelListLength rest)

def psWhnfCoreWithFuel
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (fuel : Nat) : PsExpr -> PsExpr :=
  match fuel with
  | Nat.zero =>
      fun (expr : PsExpr) => psMetaInstantiate metaContext expr
  | Nat.succ remaining =>
      fun (expr : PsExpr) =>
        let smaller : PsExpr -> PsExpr :=
          psWhnfCoreWithFuel metaContext localContext remaining;
        let instantiated := psMetaInstantiate metaContext expr;
        match instantiated with
        | .fvar id =>
            match psLocalFindById localContext id with
            | some declaration =>
                match declaration with
                | .letDecl _ _ _ value =>
                  smaller value
                | _ => instantiated
            | _ => instantiated
        | .letE _ _ value body =>
          smaller (psExprInstantiate1 body value)
        | .app fn arg =>
            let reducedFn := smaller fn;
            match reducedFn with
            | .lam _ _ body _ =>
              smaller (psExprInstantiate1 body arg)
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
    (localContext : PsLocalContext)
    (fuel : Nat) : PsExpr -> PsExpr :=
  match fuel with
  | Nat.zero =>
      fun (expr : PsExpr) => psWhnfCore metaContext localContext expr
  | Nat.succ remaining =>
      fun (expr : PsExpr) =>
        let smaller : PsExpr -> PsExpr :=
          psWhnfWithFuel environment metaContext localContext remaining;
        let core := psWhnfCoreWithFuel metaContext localContext remaining expr;
        match core with
        | .constE name levels =>
            match psEnvironmentFind environment name with
            | none => core
            | some declaration =>
                match psDeclarationValue declaration with
                | none => core
                | some value =>
                    let parameters := psDeclarationLevelParams declaration;
                    if Nat.beq
                        (psReduceNameListLength parameters)
                        (psReduceLevelListLength levels) then
                      smaller
                        (psExprInstantiateLevelParams parameters levels value)
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
  psWhnfWithFuel environment metaContext localContext 256 expr

def psDefEqReadOnlyWithEnvFuel
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (fuel : Nat) : PsExpr -> PsExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (left : PsExpr) (right : PsExpr) =>
        psExprAlphaEq
          (psWhnf environment metaContext localContext left)
          (psWhnf environment metaContext localContext right)
  | Nat.succ remaining =>
      fun (left : PsExpr) (right : PsExpr) =>
        let smaller : PsExpr -> PsExpr -> Bool :=
          psDefEqReadOnlyWithEnvFuel environment metaContext localContext remaining;
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
  psDefEqReadOnlyWithEnvFuel
    environment
    metaContext
    localContext
    256
    left
    right
