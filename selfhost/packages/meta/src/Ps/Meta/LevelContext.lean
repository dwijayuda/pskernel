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
      if Nat.beq value target then true else psNatListContains rest target

def psLevelFindAssignmentInList (id : Nat) : List PsLevelAssignment -> Option PsLevel
  | [] => Option.none
  | assignment :: rest =>
      if Nat.beq assignment.id id then
        Option.some assignment.value
      else
        psLevelFindAssignmentInList id rest

def psLevelFindAssignment (context : PsLevelMetaContext) (id : Nat) : Option PsLevel :=
  psLevelFindAssignmentInList id context.assignments

def psLevelMetaFresh (context : PsLevelMetaContext) : PsLevelFreshResult :=
  let id := context.nextId
  {
    context := {
      nextId := Nat.succ id
      declarations := List.cons id context.declarations
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
          | Option.none => level
          | Option.some value => psLevelInstantiateWithFuel context fuel value
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

def psLevelOccursResolved (target : Nat) : PsLevel -> Bool
  | .mvar id => id == target
  | .succ value => psLevelOccursResolved target value
  | .max left right =>
      psLevelOccursResolved target left || psLevelOccursResolved target right
  | .imax left right =>
      psLevelOccursResolved target left || psLevelOccursResolved target right
  | _ => false

def psLevelOccurs (context : PsLevelMetaContext) (target : Nat) (level : PsLevel) : Bool :=
  psLevelOccursResolved target (psLevelInstantiate context level)

def psLevelAssign
    (context : PsLevelMetaContext)
    (id : Nat)
    (value : PsLevel) : Option PsLevelMetaContext :=
  if psNatListContains context.declarations id then
    match psLevelFindAssignment context id with
    | Option.some _ => Option.none
    | Option.none =>
        let resolved := psLevelInstantiate context value
        if psLevelOccurs context id resolved then
          Option.none
        else
          Option.some {
            nextId := context.nextId
            declarations := context.declarations
            assignments := List.cons { id := id, value := resolved } context.assignments
          }
  else
    Option.none

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
            | Option.none => { context := context, success := false }
            | Option.some next => { context := next, success := true }
        | value, .mvar id =>
            match psLevelAssign context id value with
            | Option.none => { context := context, success := false }
            | Option.some next => { context := next, success := true }
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

def psLevelHasMVar : PsLevel -> Bool
  | .mvar _ => true
  | .succ value => psLevelHasMVar value
  | .max left right => psLevelHasMVar left || psLevelHasMVar right
  | .imax left right => psLevelHasMVar left || psLevelHasMVar right
  | _ => false

def psLevelListHasMVar : List PsLevel -> Bool
  | [] => false
  | level :: rest => psLevelHasMVar level || psLevelListHasMVar rest
