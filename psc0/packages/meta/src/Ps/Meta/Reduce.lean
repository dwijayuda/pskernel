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

-- Normalize a complete application spine. Pending arguments survive beta,
-- delta, local-let and projection steps, so a dictionary method exposing a
-- primitive is recognized while it is still saturated. Reducing the function
-- alone first would unfold its logical model and lose the native fast path.
-- This follows pinned Lean Meta/WHNF.lean's whnfCore -> reduceNat? -> delta
-- ordering, using the existing portable spine and iota mechanisms.
def psWhnfSpineWithTransparencyFuel (transparency : PsTransparency)
    (environment : PsEnvironment) (metaContext : PsMetaContext)
    (localContext : PsLocalContext) (fuel : Nat) :
    PsExpr → List PsExpr → PsExpr :=
  match fuel with
  | 0 => fun expr args => psWhnfCore metaContext localContext (psReduceApply expr args)
  | remaining + 1 => fun expr args =>
    let step := psWhnfSpineWithTransparencyFuel transparency environment
      metaContext localContext remaining
    let reduce := fun value => step value []
    let view := psReduceAppView (psMetaInstantiate metaContext expr) args
    let applied := psReduceApply view.head view.args
    match (psReduceNatPrimitive reduce applied).orElse
        (fun _ => psReduceIota reduce environment applied) with
    | some value => step value []
    | none => match view.head with
      | .fvar id =>
        match psLocalFindById localContext id with
        | some (.letDecl _ _ _ value) => step value view.args
        | _ => applied
      | .letE _ _ value body =>
        step (psExprInstantiate1 body value) view.args
      | .lam _ _ body _ =>
        match view.args with
        | [] => view.head
        | argument :: rest => step (psExprInstantiate1 body argument) rest
      | .constE name levels =>
        if psNameEq name psNatZeroName then step (.lit (.natural 0)) view.args else
        match psEnvironmentFind environment name with
        | none => applied
        | some declaration =>
          match if psEnvironmentCanUnfold environment transparency name
              then psDeclarationValue declaration else none with
          | none => applied
          | some value =>
            let parameters := psDeclarationLevelParams declaration
            if parameters.length == levels.length then
              step (psExprInstantiateLevelParams parameters levels value) view.args
            else applied
      | .proj typeName index major =>
        let major := reduce major
        match psReduceProjectionIota (fun value => value) environment typeName index major with
        | some field => step field view.args
        | none => psReduceApply (.proj typeName index major) view.args
      | _ => applied

def psWhnfWithTransparencyFuel (transparency : PsTransparency)
    (environment : PsEnvironment) (metaContext : PsMetaContext)
    (localContext : PsLocalContext) (fuel : Nat) (expr : PsExpr) : PsExpr :=
  psWhnfSpineWithTransparencyFuel transparency environment metaContext localContext fuel expr []

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
