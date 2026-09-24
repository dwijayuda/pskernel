import Ps.Core.Equality
import Ps.Core.Expr
import Ps.Core.Level

structure PsLevelAssignment where
  id : Nat
  value : PsLevel

structure PsLevelMetaContext where
  nextId : Nat
  declarations : List Nat
  assignments : List PsLevelAssignment

structure PsLevelFreshResult where
  context : PsLevelMetaContext
  level : PsLevel

structure PsLevelUnifyResult where
  context : PsLevelMetaContext
  success : Bool

def psLevelMetaEmpty : PsLevelMetaContext :=
  { nextId := 0, declarations := [], assignments := [] }

def psNatListContains (values : List Nat) (target : Nat) : Bool :=
  match values with
  | [] => false
  | value :: rest =>
      if value == target then true else psNatListContains rest target

def psLevelFindAssignmentInList (id : Nat) : List PsLevelAssignment -> Option PsLevel
  | [] => none
  | assignment :: rest =>
      if assignment.id == id then
        some assignment.value
      else
        psLevelFindAssignmentInList id rest

def psLevelFindAssignment (context : PsLevelMetaContext) (id : Nat) : Option PsLevel :=
  psLevelFindAssignmentInList id context.assignments

def psLevelMetaFresh (context : PsLevelMetaContext) : PsLevelFreshResult :=
  let id := context.nextId
  {
    context := {
      nextId := id + 1
      declarations := id :: context.declarations
      assignments := context.assignments
    }
    level := PsLevel.mvar id
  }

def psLevelInstantiateWithFuel
    (context : PsLevelMetaContext) : Nat -> PsLevel -> PsLevel
  | 0, level => level
  | fuel + 1, level =>
      match level with
      | .mvar id =>
          match psLevelFindAssignment context id with
          | none => level
          | some value => psLevelInstantiateWithFuel context fuel value
      | .succ value =>
          PsLevel.succ (psLevelInstantiateWithFuel context fuel value)
      | .max left right =>
          PsLevel.max
            (psLevelInstantiateWithFuel context fuel left)
            (psLevelInstantiateWithFuel context fuel right)
      | .imax left right =>
          PsLevel.imax
            (psLevelInstantiateWithFuel context fuel left)
            (psLevelInstantiateWithFuel context fuel right)
      | _ => level

def psLevelInstantiate (context : PsLevelMetaContext) (level : PsLevel) : PsLevel :=
  psLevelInstantiateWithFuel context (context.assignments.length + 1) level

def psLevelOccurs (context : PsLevelMetaContext) (target : Nat) (level : PsLevel) : Bool :=
  let resolved := psLevelInstantiate context level
  match resolved with
  | .mvar id => id == target
  | .succ value => psLevelOccurs context target value
  | .max left right =>
      psLevelOccurs context target left || psLevelOccurs context target right
  | .imax left right =>
      psLevelOccurs context target left || psLevelOccurs context target right
  | _ => false

def psLevelAssign
    (context : PsLevelMetaContext)
    (id : Nat)
    (value : PsLevel) : Option PsLevelMetaContext :=
  if psNatListContains context.declarations id then
    match psLevelFindAssignment context id with
    | some _ => none
    | none =>
        let resolved := psLevelInstantiate context value
        if psLevelOccurs context id resolved then
          none
        else
          some {
            nextId := context.nextId
            declarations := context.declarations
            assignments := { id := id, value := resolved } :: context.assignments
          }
  else
    none

def psLevelUnifyWithFuel
    (context : PsLevelMetaContext) : Nat -> PsLevel -> PsLevel -> PsLevelUnifyResult
  | 0, _, _ => { context := context, success := false }
  | fuel + 1, left, right =>
      let leftValue := psLevelInstantiate context left
      let rightValue := psLevelInstantiate context right
      if psLevelStructuralEq leftValue rightValue then
        { context := context, success := true }
      else
        match leftValue, rightValue with
        | .mvar id, value =>
            match psLevelAssign context id value with
            | none => { context := context, success := false }
            | some next => { context := next, success := true }
        | value, .mvar id =>
            match psLevelAssign context id value with
            | none => { context := context, success := false }
            | some next => { context := next, success := true }
        | .succ leftInner, .succ rightInner =>
            psLevelUnifyWithFuel context fuel leftInner rightInner
        | .max leftA leftB, .max rightA rightB =>
            let first := psLevelUnifyWithFuel context fuel leftA rightA
            if first.success then
              psLevelUnifyWithFuel first.context fuel leftB rightB
            else
              first
        | .imax leftA leftB, .imax rightA rightB =>
            let first := psLevelUnifyWithFuel context fuel leftA rightA
            if first.success then
              psLevelUnifyWithFuel first.context fuel leftB rightB
            else
              first
        | _, _ => { context := context, success := false }

def psLevelUnify
    (context : PsLevelMetaContext)
    (left : PsLevel)
    (right : PsLevel) : PsLevelUnifyResult :=
  psLevelUnifyWithFuel context 256 left right

def psLevelInstantiateExpr (context : PsLevelMetaContext) : PsExpr -> PsExpr
  | .sortE level => PsExpr.sortE (psLevelInstantiate context level)
  | .constE name levels =>
      PsExpr.constE name (levels.map (psLevelInstantiate context))
  | .app fn arg =>
      PsExpr.app
        (psLevelInstantiateExpr context fn)
        (psLevelInstantiateExpr context arg)
  | .lam name type body binder =>
      PsExpr.lam
        name
        (psLevelInstantiateExpr context type)
        (psLevelInstantiateExpr context body)
        binder
  | .forallE name type body binder =>
      PsExpr.forallE
        name
        (psLevelInstantiateExpr context type)
        (psLevelInstantiateExpr context body)
        binder
  | .letE name type value body =>
      PsExpr.letE
        name
        (psLevelInstantiateExpr context type)
        (psLevelInstantiateExpr context value)
        (psLevelInstantiateExpr context body)
  | .proj typeName index value =>
      PsExpr.proj typeName index (psLevelInstantiateExpr context value)
  | expr => expr
