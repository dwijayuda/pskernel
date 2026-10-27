-- Regular R4 ingress: proposed source groups and names, never caller type authority.
import Ps.MinKernel.Profile.CoreIngress

structure PsMinRegCoreConstructor where
  name : PsMinCoreName
  type : PsMinCoreExpr

structure PsMinRegCoreGroup where
  name : PsMinCoreName
  type : PsMinCoreExpr
  constructors : List PsMinRegCoreConstructor

inductive PsMinRegCoreEntry where
  | definition (declaration : PsMinCoreDeclaration)
  | inductiveE (group : PsMinRegCoreGroup)

structure PsMinRegCorePlan where
  source : PsMinRegCoreGroup
  spec : PsMinRegSpec
  ordinal : Nat

structure PsMinRegCoreState where
  groups : List PsMinRegCorePlan
  used : List PsMinCoreName
  count : Nat

structure PsMinRegCoreConstructorBinding where
  slot : Nat
  index : Nat

structure PsMinRegCoreRecursorBinding where
  slot : Nat
  owner : PsMinCoreName
  minors : Nat

def psMinRegCoreDouble (value : Nat) : Nat := Nat.add value value

-- This separate self-check domain retains the first ingress domain's limits.
-- Budget values are source expressions rather than larger literal whitelists.
def psMinRegCoreByteBudget : Nat :=
  psMinRegCoreDouble (psMinRegCoreDouble (psMinRegCoreDouble (psMinRegCoreDouble (psMinRegCoreDouble (psMinRegCoreDouble (psMinRegCoreDouble (psMinRegCoreDouble (psMinRegCoreDouble (psMinRegCoreDouble (psMinRegCoreDouble (1024)))))))))))

def psMinRegCoreScalarValid (value : Nat) : Bool :=
  if Nat.blt 65536 value then false else true

def psMinRegCoreExprValid (fuel : Nat) : PsMinCoreExpr -> Bool :=
  match fuel with
  | Nat.zero => fun _ => false
  | Nat.succ rest => fun expr =>
    let smaller : PsMinCoreExpr -> Bool := psMinRegCoreExprValid rest;
    match expr with
    | .sort level => Nat.blt level 2
    | .bvar index => psMinRegCoreScalarValid index
    | .natural value => psMinRegCoreScalarValid value
    | .constant name levels => if psMinCoreNameValid 16 name then
        if psMinByteLengthAtMost 1 levels then psMinCoreLevelsValid levels else false else false
    | .app fn arg => if smaller fn then smaller arg else false
    | .lam name binder type body => if psMinCoreNameValid 16 name then if Nat.blt binder 4 then
        if smaller type then smaller body else false else false else false
    | .forallE name binder type body => if psMinCoreNameValid 16 name then if Nat.blt binder 4 then
        if smaller type then smaller body else false else false else false
    | .letE name type value body => if psMinCoreNameValid 16 name then if smaller type then
        if smaller value then smaller body else false else false else false
    | .projection name index value => if psMinCoreNameValid 16 name then
        if psMinRegCoreScalarValid index then smaller value else false else false

def psMinRegCoreRecName (owner : PsMinCoreName) : PsMinCoreName :=
  PsMinCoreName.str owner [114, 101, 99]

def psMinRegCoreConstructorCount (constructors : List PsMinRegCoreConstructor) : Nat :=
  match constructors with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (psMinRegCoreConstructorCount rest)

def psMinRegCoreSpecs (groups : List PsMinRegCorePlan) : List PsMinRegSpec :=
  match groups with
  | List.nil => List.nil
  | List.cons plan rest => List.cons plan.spec (psMinRegCoreSpecs rest)

def psMinRegCoreGroupSlot (total visible : Nat) (groups : List PsMinRegCorePlan)
    (name : PsMinCoreName) : Option Nat :=
  match groups with
  | List.nil => Option.none
  | List.cons plan rest =>
    if psMinCoreNameEq name plan.source.name then
      if Nat.blt plan.ordinal visible then if Nat.blt plan.ordinal total then
        Option.some (Nat.sub total (Nat.succ plan.ordinal)) else Option.none else Option.none
    else psMinRegCoreGroupSlot total visible rest name

def psMinRegCoreFindConstructorIndex (constructors : List PsMinRegCoreConstructor)
    (name : PsMinCoreName) : Option Nat :=
  match constructors with
  | List.nil => Option.none
  | List.cons head rest => if psMinCoreNameEq name head.name then Option.some 0 else
      match psMinRegCoreFindConstructorIndex rest name with
      | Option.none => Option.none
      | Option.some index => Option.some (Nat.succ index)

def psMinRegCoreFindConstructor (total visible : Nat) (groups : List PsMinRegCorePlan)
    (name : PsMinCoreName) : Option PsMinRegCoreConstructorBinding :=
  match groups with
  | List.nil => Option.none
  | List.cons plan rest =>
    if Nat.blt plan.ordinal visible then if Nat.blt plan.ordinal total then
      match psMinRegCoreFindConstructorIndex plan.source.constructors name with
      | Option.some index => Option.some (PsMinRegCoreConstructorBinding.mk
          (Nat.sub total (Nat.succ plan.ordinal)) index)
      | Option.none => psMinRegCoreFindConstructor total visible rest name
    else psMinRegCoreFindConstructor total visible rest name
    else psMinRegCoreFindConstructor total visible rest name

def psMinRegCoreFindRecursor (total visible : Nat) (groups : List PsMinRegCorePlan)
    (name : PsMinCoreName) : Option PsMinRegCoreRecursorBinding :=
  match groups with
  | List.nil => Option.none
  | List.cons plan rest =>
    if psMinCoreNameEq name (psMinRegCoreRecName plan.source.name) then
      if Nat.blt plan.ordinal visible then if Nat.blt plan.ordinal total then
        Option.some (PsMinRegCoreRecursorBinding.mk (Nat.sub total (Nat.succ plan.ordinal))
          plan.source.name plan.spec.minors)
      else Option.none else Option.none
    else psMinRegCoreFindRecursor total visible rest name

-- total fixes the final carrier registry; visible enforces original source order.
def psMinRegCoreType (fuel total visible : Nat) (groups : List PsMinRegCorePlan)
    (expr : PsMinCoreExpr) : Option PsMinRegTy :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ rest =>
    match expr with
    | .constant name levels =>
      if psMinByteEq levels List.nil then
        match psMinCoreType (Nat.succ rest) expr with
        | Option.some code => Option.some code
        | Option.none => match psMinRegCoreGroupSlot total visible groups name with
          | Option.none => Option.none
          | Option.some slot => Option.some (PsMinRegTy.data slot)
      else Option.none
    | .forallE _ _ domain body =>
      match psMinRegCoreType rest total visible groups domain with
      | Option.none => Option.none
      | Option.some a => match psMinRegCoreType rest total visible groups body with
        | Option.none => Option.none
        | Option.some b => Option.some (PsMinRegTy.arr a b)
    | .app fn arg => match fn with
      | .constant name levels => if psMinByteEq levels List.nil then
          match psMinRegCoreType rest total visible groups arg with
          | Option.none => Option.none
          | Option.some a => if psMinCoreIsType a then
              if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [76, 105, 115, 116]) then Option.some (PsMinRegTy.list a) else
              if psMinCoreNameEq name (PsMinCoreName.str PsMinCoreName.anonymous [79, 112, 116, 105, 111, 110]) then Option.some (PsMinRegTy.option a) else Option.none
            else Option.none
        else Option.none
      | _ => Option.none
    | _ => Option.none

def psMinRegCoreNoOwner (fuel : Nat) (owner : PsMinCoreName) (expr : PsMinCoreExpr) : Bool :=
  match fuel with
  | Nat.zero => false
  | Nat.succ remaining =>
    match expr with
    | .constant name _ => if psMinCoreNameEq name owner then false else true
    | .app fn arg => if psMinRegCoreNoOwner remaining owner fn then psMinRegCoreNoOwner remaining owner arg else false
    | .lam _ _ type body => if psMinRegCoreNoOwner remaining owner type then psMinRegCoreNoOwner remaining owner body else false
    | .forallE _ _ type body => if psMinRegCoreNoOwner remaining owner type then psMinRegCoreNoOwner remaining owner body else false
    | .letE _ type value body => if psMinRegCoreNoOwner remaining owner type then
        if psMinRegCoreNoOwner remaining owner value then psMinRegCoreNoOwner remaining owner body else false else false
    | .projection _ _ value => psMinRegCoreNoOwner remaining owner value
    | _ => true

def psMinRegCoreGroundField (older : Nat) (groups : List PsMinRegCorePlan) (owner : PsMinCoreName)
    (sourceType : PsMinCoreExpr) : Option PsMinRegField :=
  if psMinRegCoreNoOwner 256 owner sourceType then
    match psMinRegCoreType 256 older older groups sourceType with
    | Option.none => Option.none
    | Option.some code => Option.some (PsMinRegField.ground code)
  else Option.none

def psMinRegCoreField (older : Nat) (groups : List PsMinRegCorePlan) (owner : PsMinCoreName)
    (sourceType : PsMinCoreExpr) : Option PsMinRegField :=
  match sourceType with
  | .constant name levels =>
    if psMinByteEq levels List.nil then if psMinCoreNameEq name owner then
      Option.some PsMinRegField.recursive
    else psMinRegCoreGroundField older groups owner sourceType
    else Option.none
  | _ => psMinRegCoreGroundField older groups owner sourceType

-- Only direct self fields are recognized. A self occurrence under an arrow,
-- List/Option or a different family is never visible to the ground type parser.
def psMinRegCoreConstructorFields (fuel older : Nat) (groups : List PsMinRegCorePlan)
    (owner : PsMinCoreName) (sourceType : PsMinCoreExpr) : Option (List PsMinRegField) :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ rest => match sourceType with
    | .constant name levels => if psMinByteEq levels List.nil then
        if psMinCoreNameEq name owner then Option.some List.nil else Option.none
      else Option.none
    | .forallE _ _ domain body =>
      match psMinRegCoreField older groups owner domain with
      | Option.none => Option.none
      | Option.some field => match psMinRegCoreConstructorFields rest older groups owner body with
        | Option.none => Option.none
        | Option.some fields => Option.some (List.cons field fields)
    | _ => Option.none

def psMinRegCoreAllFields (older : Nat) (groups : List PsMinRegCorePlan)
    (owner : PsMinCoreName) (constructors : List PsMinRegCoreConstructor) :
    Option (List (List PsMinRegField)) :=
  match constructors with
  | List.nil => Option.some List.nil
  | List.cons ctor rest =>
    match psMinRegCoreConstructorFields 256 older groups owner ctor.type with
    | Option.none => Option.none
    | Option.some fields => match psMinRegCoreAllFields older groups owner rest with
      | Option.none => Option.none
      | Option.some tail => Option.some (List.cons fields tail)

def psMinRegCoreReserveConstructors (constructors : List PsMinRegCoreConstructor)
    (used : List PsMinCoreName) : Option (List PsMinCoreName) :=
  match constructors with
  | List.nil => Option.some used
  | List.cons ctor rest => if psMinCoreFresh used ctor.name then
      psMinRegCoreReserveConstructors rest (List.cons ctor.name used)
    else Option.none

def psMinRegCoreBuildGroup (state : PsMinRegCoreState) (group : PsMinRegCoreGroup) :
    Option PsMinRegCoreState :=
  if psMinCoreFresh state.used group.name then
    if psMinCoreExprEq 4 group.type (PsMinCoreExpr.sort 1) then
      match psMinRegCoreReserveConstructors group.constructors (List.cons group.name state.used) with
      | Option.none => Option.none
      | Option.some used =>
        let recName : PsMinCoreName := psMinRegCoreRecName group.name;
        if psMinCoreFresh used recName then
          match psMinRegCoreAllFields state.count state.groups group.name group.constructors with
          | Option.none => Option.none
          | Option.some fields =>
            let spec : PsMinRegSpec := PsMinRegSpec.mk 0 0 0 1
              (psMinRegCoreConstructorCount group.constructors) fields;
            if psMinRegSpecValid 512 state.count spec then
              Option.some (PsMinRegCoreState.mk
                (List.cons (PsMinRegCorePlan.mk group spec state.count) state.groups)
                (List.cons recName used) (Nat.succ state.count))
            else Option.none
        else Option.none
    else Option.none
  else Option.none

def psMinRegCoreBuildPlans (fuel : Nat) (entries : List PsMinRegCoreEntry)
    (state : PsMinRegCoreState) : Option PsMinRegCoreState :=
  match entries with
  | List.nil => Option.some state
  | List.cons entry rest =>
    match fuel with
    | Nat.zero => Option.none
    | Nat.succ remaining => match entry with
      | .definition decl =>
        if psMinCoreFresh state.used decl.name then
          psMinRegCoreBuildPlans remaining rest (PsMinRegCoreState.mk state.groups
            (List.cons decl.name state.used) state.count)
        else Option.none
      | .inductiveE group => match psMinRegCoreBuildGroup state group with
        | Option.none => Option.none
        | Option.some next => psMinRegCoreBuildPlans remaining rest next

def psMinRegCorePlans (entries : List PsMinRegCoreEntry) : Option PsMinRegCoreState :=
  psMinRegCoreBuildPlans 512 entries (PsMinRegCoreState.mk List.nil List.nil 0)
