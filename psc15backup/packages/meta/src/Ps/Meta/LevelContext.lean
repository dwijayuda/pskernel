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

def psLevelFindAssignmentInList
    (id : Nat)
    (assignments : List PsLevelAssignment) : Option PsLevel :=
  match assignments with
  | [] => Option.none
  | assignment :: rest =>
      if Nat.beq assignment.id id then
        Option.some assignment.value
      else
        psLevelFindAssignmentInList id rest

def psLevelMetaFresh (context : PsLevelMetaContext) : PsLevelFreshResult :=
  let id := context.nextId;
  {
    context := {
      nextId := Nat.succ id
      declarations := List.cons id context.declarations
      assignments := context.assignments
    }
    level := PsLevel.mvar id
  }

def psLevelFindAssignment (context : PsLevelMetaContext) (id : Nat) : Option PsLevel :=
  psLevelFindAssignmentInList id context.assignments

def psLevelAssignmentCount (assignments : List PsLevelAssignment) : Nat :=
  match assignments with
  | [] => Nat.zero
  | assignment :: rest =>
      Nat.succ (psLevelAssignmentCount rest)

def psLevelInstantiateWithFuel
    (context : PsLevelMetaContext)
    (fuel : Nat) : PsLevel -> PsLevel :=
  match fuel with
  | Nat.zero =>
      fun (level : PsLevel) => level
  | Nat.succ remaining =>
      let smaller : PsLevel -> PsLevel :=
        psLevelInstantiateWithFuel context remaining;
      fun (level : PsLevel) =>
        match level with
        | .mvar id =>
            match psLevelFindAssignment context id with
            | Option.none => level
            | Option.some value => smaller value
        | .succ value =>
            PsLevel.succ (smaller value)
        | .max left right =>
            PsLevel.max (smaller left) (smaller right)
        | .imax left right =>
            PsLevel.imax (smaller left) (smaller right)
        | _ => level

def psLevelInstantiate (context : PsLevelMetaContext) (level : PsLevel) : PsLevel :=
  psLevelInstantiateWithFuel
    context
    (Nat.succ (psLevelAssignmentCount context.assignments))
    level

def psLevelOccursResolved
    (target : Nat)
    (level : PsLevel) : Bool :=
  match level with
  | .mvar id => Nat.beq id target
  | .succ value => psLevelOccursResolved target value
  | .max left right =>
      if psLevelOccursResolved target left then
        true
      else
        psLevelOccursResolved target right
  | .imax left right =>
      if psLevelOccursResolved target left then
        true
      else
        psLevelOccursResolved target right
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
        let resolved := psLevelInstantiate context value;
        if psLevelOccurs context id resolved then
          Option.none
        else
          Option.some {
            nextId := context.nextId
            declarations := context.declarations
            assignments :=
              List.cons
                (PsLevelAssignment.mk id resolved)
                context.assignments
          }
  else
    Option.none

def psLevelUnifyWithFuelWorker
    (fuel : Nat) :
    PsLevelMetaContext -> PsLevel -> PsLevel -> PsLevelUnifyResult :=
  match fuel with
  | Nat.zero =>
      fun (context : PsLevelMetaContext) (_left : PsLevel) (_right : PsLevel) =>
        { context := context, success := false }
  | Nat.succ remaining =>
      let smaller : PsLevelMetaContext -> PsLevel -> PsLevel -> PsLevelUnifyResult :=
        psLevelUnifyWithFuelWorker remaining;
      fun (context : PsLevelMetaContext) (left : PsLevel) (right : PsLevel) =>
        let leftValue := psLevelInstantiate context left;
        let rightValue := psLevelInstantiate context right;
        if psLevelStructuralEq leftValue rightValue then
          { context := context, success := true }
        else
          match leftValue with
          | .mvar id =>
              match psLevelAssign context id rightValue with
              | Option.none => { context := context, success := false }
              | Option.some next => { context := next, success := true }
          | _ =>
              match rightValue with
              | .mvar id =>
                  match psLevelAssign context id leftValue with
                  | Option.none => { context := context, success := false }
                  | Option.some next => { context := next, success := true }
              | .succ rightInner =>
                  match leftValue with
                  | .succ leftInner =>
                      smaller context leftInner rightInner
                  | _ => { context := context, success := false }
              | .max rightA rightB =>
                  match leftValue with
                  | .max leftA leftB =>
                      let first := smaller context leftA rightA;
                      if first.success then
                        smaller first.context leftB rightB
                      else
                        first
                  | _ => { context := context, success := false }
              | .imax rightA rightB =>
                  match leftValue with
                  | .imax leftA leftB =>
                      let first := smaller context leftA rightA;
                      if first.success then
                        smaller first.context leftB rightB
                      else
                        first
                  | _ => { context := context, success := false }
              | _ => { context := context, success := false }

def psLevelUnifyWithFuel
    (context : PsLevelMetaContext)
    (fuel : Nat)
    (left : PsLevel)
    (right : PsLevel) : PsLevelUnifyResult :=
  psLevelUnifyWithFuelWorker fuel context left right

def psLevelUnify
    (context : PsLevelMetaContext)
    (left : PsLevel)
    (right : PsLevel) : PsLevelUnifyResult :=
  psLevelUnifyWithFuel context 256 left right

def psLevelInstantiateList
    (context : PsLevelMetaContext)
    (levels : List PsLevel) : List PsLevel :=
  match levels with
  | [] => List.nil
  | level :: rest =>
      List.cons
        (psLevelInstantiate context level)
        (psLevelInstantiateList context rest)

def psLevelInstantiateExpr
    (context : PsLevelMetaContext)
    (expr : PsExpr) : PsExpr :=
  match expr with
  | .sortE level => PsExpr.sortE (psLevelInstantiate context level)
  | .constE name levels =>
      PsExpr.constE name (psLevelInstantiateList context levels)
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
  | _ => expr

def psLevelHasMVar
    (level : PsLevel) : Bool :=
  match level with
  | .mvar _ => true
  | .succ value => psLevelHasMVar value
  | .max left right =>
      if psLevelHasMVar left then
        true
      else
        psLevelHasMVar right
  | .imax left right =>
      if psLevelHasMVar left then
        true
      else
        psLevelHasMVar right
  | _ => false

def psLevelListHasMVar
    (levels : List PsLevel) : Bool :=
  match levels with
  | [] => false
  | level :: rest =>
      if psLevelHasMVar level then
        true
      else
        psLevelListHasMVar rest
