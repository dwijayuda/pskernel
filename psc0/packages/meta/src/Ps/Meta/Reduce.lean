import Ps.Meta.Iota
import Ps.Meta.NatReduce
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

def psWhnfWithTransparencyFuel (transparency : PsTransparency)
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
          psWhnfWithTransparencyFuel transparency environment metaContext localContext remaining;
        let core := psWhnfCoreWithFuel metaContext localContext remaining expr;
        match core with
        | .constE name levels =>
            if psNameEq name psNatZeroName then .lit (.natural 0) else
            match psEnvironmentFind environment name with
            | none => core
            | some declaration =>
                match if psTransparencyAllows transparency (psEnvironmentReducibility environment name)
                    then psDeclarationValue declaration else none with
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
            match (psReduceNatPrimitive smaller core).orElse
                (fun _ => psReduceIota smaller environment core) with
            | some value => smaller value
            | none =>
              let reducedFn := smaller fn;
              if psExprAlphaEq reducedFn fn then core
              else smaller (PsExpr.app reducedFn arg)
        | .proj typeName index major =>
            match psReduceProjectionIota smaller environment typeName index major with
            | some field => smaller field
            | none =>
              let reducedMajor := smaller major
              if psExprAlphaEq reducedMajor major then core
              else .proj typeName index reducedMajor
        | _ => core

def psWhnfWithFuel := psWhnfWithTransparencyFuel .all

def psWhnfWithTransparency (transparency : PsTransparency)
    (environment : PsEnvironment) (metaContext : PsMetaContext)
    (localContext : PsLocalContext) (expr : PsExpr) : PsExpr :=
  psWhnfWithTransparencyFuel transparency environment metaContext localContext 256 expr

def psWhnf
    (environment : PsEnvironment)
    (metaContext : PsMetaContext)
    (localContext : PsLocalContext)
    (expr : PsExpr) : PsExpr :=
  psWhnfWithFuel environment metaContext localContext 256 expr

-- Structural conversion owns reduction and congruence. A caller with a type
-- inference capability may supply typed proof irrelevance as an additional
-- closed rule; plain reduction callers use the same walker without that rule.
-- Bodies are opened in a real local context before invoking the typed rule.
def psDefEqReadOnlyWithTransparencyProofs (transparency : PsTransparency)
    (environment : PsEnvironment) (metaContext : PsMetaContext)
    (proofEq : PsLocalContext → PsExpr → PsExpr → Bool)
    (fuel : Nat) (localContext : PsLocalContext) (left right : PsExpr) : Bool :=
  let left := psWhnfWithTransparency transparency environment metaContext localContext left
  let right := psWhnfWithTransparency transparency environment metaContext localContext right
  if psExprAlphaEq left right then true else
  match fuel with
  | 0 => false
  | fuel + 1 =>
    let smaller := psDefEqReadOnlyWithTransparencyProofs transparency environment metaContext proofEq fuel
    let structural := match left, right with
      | .sortE a, .sortE b => psLevelEquivalent a b
      | .constE a levels, .constE b other =>
        psNameEq a b && levels.length == other.length &&
          (levels.zip other).all (fun pair => psLevelEquivalent pair.fst pair.snd)
      | .app fn arg, .app otherFn otherArg =>
        smaller localContext fn otherFn && smaller localContext arg otherArg
      | .lam name domain body binder, .lam _ otherDomain otherBody _
      | .forallE name domain body binder, .forallE _ otherDomain otherBody _ =>
        if !smaller localContext domain otherDomain then false else
          let pushed := psLocalPushBinding localContext name domain binder
          smaller pushed.context (psExprInstantiate1 body (.fvar pushed.id))
            (psExprInstantiate1 otherBody (.fvar pushed.id))
      | .proj owner index value, .proj otherOwner otherIndex otherValue =>
        psNameEq owner otherOwner && index == otherIndex && smaller localContext value otherValue
      | _, _ => false
    structural || proofEq localContext left right

def psDefEqReadOnlyWithProofs := psDefEqReadOnlyWithTransparencyProofs .all

def psDefEqReadOnlyWithTransparency (transparency : PsTransparency)
    (environment : PsEnvironment) (metaContext : PsMetaContext)
    (locals : PsLocalContext) (left right : PsExpr) : Bool :=
  psDefEqReadOnlyWithTransparencyProofs transparency environment metaContext
    (fun _ _ _ => false) 256 locals left right

def psDefEqReadOnlyWithEnvFuel
    (environment : PsEnvironment) (metaContext : PsMetaContext)
    (localContext : PsLocalContext) (fuel : Nat) (left right : PsExpr) : Bool :=
  psDefEqReadOnlyWithProofs environment metaContext (fun _ _ _ => false)
    fuel localContext left right

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
