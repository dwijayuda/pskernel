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

def psLevelFindAssignmentInListWorker
    (assignments : List PsLevelAssignment) :
    Nat -> Option PsLevel :=
  match assignments with
  | [] =>
      fun (_id : Nat) => Option.none
  | assignment :: rest =>
      let smaller : Nat -> Option PsLevel :=
        psLevelFindAssignmentInListWorker rest;
      fun (id : Nat) =>
        if Nat.beq assignment.id id then
          Option.some assignment.value
        else
          smaller id

def psLevelFindAssignmentInList
    (id : Nat)
    (assignments : List PsLevelAssignment) : Option PsLevel :=
  psLevelFindAssignmentInListWorker assignments id

def psLevelFindAssignment (context : PsLevelMetaContext) (id : Nat) : Option PsLevel :=
  psLevelFindAssignmentInList id context.assignments

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

def psLevelInstantiateWithFuelWorker
    (fuel : Nat) : PsLevelMetaContext -> PsLevel -> PsLevel :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsLevelMetaContext) (level : PsLevel) => level
  | Nat.succ remaining =>
      let smaller : PsLevelMetaContext -> PsLevel -> PsLevel :=
        psLevelInstantiateWithFuelWorker remaining;
      fun (context : PsLevelMetaContext) (level : PsLevel) =>
        match level with
        | .mvar id =>
            match psLevelFindAssignment context id with
            | Option.none => level
            | Option.some value => smaller context value
        | .succ value =>
            PsLevel.succ (smaller context value)
        | .max left right =>
            PsLevel.max (smaller context left) (smaller context right)
        | .imax left right =>
            PsLevel.imax (smaller context left) (smaller context right)
        | _ => level

def psLevelInstantiateWithFuel
    (context : PsLevelMetaContext)
    (fuel : Nat)
    (level : PsLevel) : PsLevel :=
  psLevelInstantiateWithFuelWorker fuel context level

def psLevelAssignmentListLength
    (assignments : List PsLevelAssignment) : Nat :=
  match assignments with
  | [] => Nat.zero
  | _ :: rest => Nat.succ (psLevelAssignmentListLength rest)

def psLevelInstantiate (context : PsLevelMetaContext) (level : PsLevel) : PsLevel :=
  let fuel := Nat.succ (psLevelAssignmentListLength context.assignments);
  psLevelInstantiateWithFuel context fuel level

def psLevelOccursResolvedWorker
    (level : PsLevel) : Nat -> Bool :=
  match level with
  | .mvar id =>
      fun (target : Nat) => Nat.beq id target
  | .succ value =>
      let smaller : Nat -> Bool :=
        psLevelOccursResolvedWorker value;
      fun (target : Nat) => smaller target
  | .max left right =>
      let leftOccurs : Nat -> Bool :=
        psLevelOccursResolvedWorker left;
      let rightOccurs : Nat -> Bool :=
        psLevelOccursResolvedWorker right;
      fun (target : Nat) =>
        if leftOccurs target then true else rightOccurs target
  | .imax left right =>
      let leftOccurs : Nat -> Bool :=
        psLevelOccursResolvedWorker left;
      let rightOccurs : Nat -> Bool :=
        psLevelOccursResolvedWorker right;
      fun (target : Nat) =>
        if leftOccurs target then true else rightOccurs target
  | _ =>
      fun (_target : Nat) => false

def psLevelOccursResolved
    (target : Nat)
    (level : PsLevel) : Bool :=
  psLevelOccursResolvedWorker level target

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
          let assignment : PsLevelAssignment :=
            { id := id, value := resolved };
          let next : PsLevelMetaContext :=
            {
              nextId := context.nextId
              declarations := context.declarations
              assignments := List.cons assignment context.assignments
            };
          Option.some next
  else
    Option.none

def psLevelUnifyWithFuelWorker
    (fuel : Nat) :
    PsLevelMetaContext -> PsLevel -> PsLevel -> PsLevelUnifyResult :=
  match fuel with
  | Nat.zero =>
      fun (context : PsLevelMetaContext)
          (_left : PsLevel)
          (_right : PsLevel) =>
        { context := context, success := false }
  | Nat.succ remaining =>
      let smaller :
          PsLevelMetaContext -> PsLevel -> PsLevel -> PsLevelUnifyResult :=
        psLevelUnifyWithFuelWorker remaining;
      fun (context : PsLevelMetaContext)
          (left : PsLevel)
          (right : PsLevel) =>
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
          | .succ leftInner =>
              match rightValue with
              | .mvar id =>
                  match psLevelAssign context id leftValue with
                  | Option.none => { context := context, success := false }
                  | Option.some next => { context := next, success := true }
              | .succ rightInner =>
                  smaller context leftInner rightInner
              | _ => { context := context, success := false }
          | .max leftA leftB =>
              match rightValue with
              | .mvar id =>
                  match psLevelAssign context id leftValue with
                  | Option.none => { context := context, success := false }
                  | Option.some next => { context := next, success := true }
              | .max rightA rightB =>
                  let first := smaller context leftA rightA;
                  if first.success then
                    smaller first.context leftB rightB
                  else
                    first
              | _ => { context := context, success := false }
          | .imax leftA leftB =>
              match rightValue with
              | .mvar id =>
                  match psLevelAssign context id leftValue with
                  | Option.none => { context := context, success := false }
                  | Option.some next => { context := next, success := true }
              | .imax rightA rightB =>
                  let first := smaller context leftA rightA;
                  if first.success then
                    smaller first.context leftB rightB
                  else
                    first
              | _ => { context := context, success := false }
          | _ =>
              match rightValue with
              | .mvar id =>
                  match psLevelAssign context id leftValue with
                  | Option.none => { context := context, success := false }
                  | Option.some next => { context := next, success := true }
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
  | [] => []
  | level :: rest =>
      List.cons
        (psLevelInstantiate context level)
        (psLevelInstantiateList context rest)

def psLevelInstantiateExprWorker
    (expr : PsExpr) : PsLevelMetaContext -> PsExpr :=
  match expr with
  | .bvar index =>
      fun (_context : PsLevelMetaContext) => PsExpr.bvar index
  | .fvar id =>
      fun (_context : PsLevelMetaContext) => PsExpr.fvar id
  | .mvar id =>
      fun (_context : PsLevelMetaContext) => PsExpr.mvar id
  | .sortE level =>
      fun (context : PsLevelMetaContext) =>
        PsExpr.sortE (psLevelInstantiate context level)
  | .constE name levels =>
      fun (context : PsLevelMetaContext) =>
        PsExpr.constE name (psLevelInstantiateList context levels)
  | .app fn arg =>
      let fnWorker : PsLevelMetaContext -> PsExpr :=
        psLevelInstantiateExprWorker fn;
      let argWorker : PsLevelMetaContext -> PsExpr :=
        psLevelInstantiateExprWorker arg;
      fun (context : PsLevelMetaContext) =>
        PsExpr.app (fnWorker context) (argWorker context)
  | .lam name type body binder =>
      let typeWorker : PsLevelMetaContext -> PsExpr :=
        psLevelInstantiateExprWorker type;
      let bodyWorker : PsLevelMetaContext -> PsExpr :=
        psLevelInstantiateExprWorker body;
      fun (context : PsLevelMetaContext) =>
        PsExpr.lam name (typeWorker context) (bodyWorker context) binder
  | .forallE name type body binder =>
      let typeWorker : PsLevelMetaContext -> PsExpr :=
        psLevelInstantiateExprWorker type;
      let bodyWorker : PsLevelMetaContext -> PsExpr :=
        psLevelInstantiateExprWorker body;
      fun (context : PsLevelMetaContext) =>
        PsExpr.forallE name (typeWorker context) (bodyWorker context) binder
  | .letE name type value body =>
      let typeWorker : PsLevelMetaContext -> PsExpr :=
        psLevelInstantiateExprWorker type;
      let valueWorker : PsLevelMetaContext -> PsExpr :=
        psLevelInstantiateExprWorker value;
      let bodyWorker : PsLevelMetaContext -> PsExpr :=
        psLevelInstantiateExprWorker body;
      fun (context : PsLevelMetaContext) =>
        PsExpr.letE
          name
          (typeWorker context)
          (valueWorker context)
          (bodyWorker context)
  | .lit value =>
      fun (_context : PsLevelMetaContext) => PsExpr.lit value
  | .proj typeName index value =>
      let valueWorker : PsLevelMetaContext -> PsExpr :=
        psLevelInstantiateExprWorker value;
      fun (context : PsLevelMetaContext) =>
        PsExpr.proj typeName index (valueWorker context)

def psLevelInstantiateExpr
    (context : PsLevelMetaContext)
    (expr : PsExpr) : PsExpr :=
  psLevelInstantiateExprWorker expr context

def psLevelHasMVarWorker (level : PsLevel) : Bool :=
  match level with
  | .mvar _ => true
  | .succ value =>
      let smaller : Bool := psLevelHasMVarWorker value;
      smaller
  | .max left right =>
      let leftHas : Bool := psLevelHasMVarWorker left;
      let rightHas : Bool := psLevelHasMVarWorker right;
      if leftHas then true else rightHas
  | .imax left right =>
      let leftHas : Bool := psLevelHasMVarWorker left;
      let rightHas : Bool := psLevelHasMVarWorker right;
      if leftHas then true else rightHas
  | _ => false

def psLevelHasMVar (level : PsLevel) : Bool :=
  psLevelHasMVarWorker level

def psLevelListHasMVarWorker
    (levels : List PsLevel) : Bool :=
  match levels with
  | [] => false
  | level :: rest =>
      let smaller : Bool := psLevelListHasMVarWorker rest;
      if psLevelHasMVar level then true else smaller

def psLevelListHasMVar (levels : List PsLevel) : Bool :=
  psLevelListHasMVarWorker levels
