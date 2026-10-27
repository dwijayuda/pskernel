/- Isolated normalized profile. Raw canonical names/bytes are not admitted here. -/
inductive PsMinRegTy where
  | empty
  | unit
  | nat
  | boolean
  | data (index : Nat)
  | arr (domain : PsMinRegTy) (result : PsMinRegTy)
  | list (element : PsMinRegTy)
  | option (element : PsMinRegTy)

inductive PsMinRegField where
  | ground (type : PsMinRegTy)
  | recursive

structure PsMinRegSpec where
  levelParameters : Nat
  parameters : Nat
  indices : Nat
  motives : Nat
  minors : Nat
  constructors : List (List PsMinRegField)

def psMinRegTyEq (fuel : Nat) (left right : PsMinRegTy) : Bool :=
  match fuel with
  | Nat.zero => false
  | Nat.succ remaining =>
    match left with
    | PsMinRegTy.empty =>
      match right with
      | PsMinRegTy.empty => true
      | _ => false
    | PsMinRegTy.unit =>
      match right with
      | PsMinRegTy.unit => true
      | _ => false
    | PsMinRegTy.nat =>
      match right with
      | PsMinRegTy.nat => true
      | _ => false
    | PsMinRegTy.boolean =>
      match right with
      | PsMinRegTy.boolean => true
      | _ => false
    | PsMinRegTy.data index =>
      match right with
      | PsMinRegTy.data other => Nat.beq index other
      | _ => false
    | PsMinRegTy.arr domain result =>
      match right with
      | PsMinRegTy.arr otherDomain otherResult =>
        if psMinRegTyEq remaining domain otherDomain then
          psMinRegTyEq remaining result otherResult
        else false
      | _ => false
    | PsMinRegTy.list element =>
      match right with
      | PsMinRegTy.list other => psMinRegTyEq remaining element other
      | _ => false
    | PsMinRegTy.option element =>
      match right with
      | PsMinRegTy.option other => psMinRegTyEq remaining element other
      | _ => false

def psMinRegTyValid (fuel bound : Nat) (type : PsMinRegTy) : Bool :=
  match fuel with
  | Nat.zero => false
  | Nat.succ remaining =>
    match type with
    | PsMinRegTy.empty => true
    | PsMinRegTy.unit => true
    | PsMinRegTy.nat => true
    | PsMinRegTy.boolean => true
    | PsMinRegTy.data index => Nat.blt index bound
    | PsMinRegTy.arr domain result =>
      if psMinRegTyValid remaining bound domain then psMinRegTyValid remaining bound result else false
    | PsMinRegTy.list element => psMinRegTyValid remaining bound element
    | PsMinRegTy.option element => psMinRegTyValid remaining bound element

def psMinRegLiftTy (type : PsMinRegTy) : PsMinRegTy :=
  match type with
  | PsMinRegTy.empty => PsMinRegTy.empty
  | PsMinRegTy.unit => PsMinRegTy.unit
  | PsMinRegTy.nat => PsMinRegTy.nat
  | PsMinRegTy.boolean => PsMinRegTy.boolean
  | PsMinRegTy.data index => PsMinRegTy.data (Nat.succ index)
  | PsMinRegTy.arr domain result => PsMinRegTy.arr (psMinRegLiftTy domain) (psMinRegLiftTy result)
  | PsMinRegTy.list element => PsMinRegTy.list (psMinRegLiftTy element)
  | PsMinRegTy.option element => PsMinRegTy.option (psMinRegLiftTy element)

def psMinRegFieldCount (fields : List PsMinRegField) : Nat :=
  match fields with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (psMinRegFieldCount rest)

def psMinRegSelfCount (fields : List PsMinRegField) : Nat :=
  match fields with
  | List.nil => 0
  | List.cons field rest =>
    match field with
    | PsMinRegField.ground _ => psMinRegSelfCount rest
    | PsMinRegField.recursive => Nat.succ (psMinRegSelfCount rest)

def psMinRegCtorCount (constructors : List (List PsMinRegField)) : Nat :=
  match constructors with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (psMinRegCtorCount rest)

def psMinRegSpecCount (specs : List PsMinRegSpec) : Nat :=
  match specs with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (psMinRegSpecCount rest)

def psMinRegFieldsValid (fuel bound : Nat) (fields : List PsMinRegField) : Bool :=
  match fields with
  | List.nil => true
  | List.cons field rest =>
    match field with
    | PsMinRegField.ground type =>
      if psMinRegTyValid fuel bound type then psMinRegFieldsValid fuel bound rest else false
    | PsMinRegField.recursive => psMinRegFieldsValid fuel bound rest

def psMinRegConstructorsValid (fuel bound : Nat) (constructors : List (List PsMinRegField)) : Bool :=
  match constructors with
  | List.nil => true
  | List.cons fields rest =>
    if psMinRegFieldsValid fuel bound fields then psMinRegConstructorsValid fuel bound rest else false

def psMinRegSpecValid (fuel bound : Nat) (spec : PsMinRegSpec) : Bool :=
  if Nat.beq spec.levelParameters 0 then
    if Nat.beq spec.parameters 0 then
      if Nat.beq spec.indices 0 then
        if Nat.beq spec.motives 1 then
          if Nat.beq spec.minors (psMinRegCtorCount spec.constructors) then
            psMinRegConstructorsValid fuel bound spec.constructors
          else false
        else false
      else false
    else false
  else false

def psMinRegRegistryValid (fuel : Nat) (specs : List PsMinRegSpec) : Bool :=
  match specs with
  | List.nil => true
  | List.cons spec rest =>
    match fuel with
    | Nat.zero => false
    | Nat.succ remaining =>
      if psMinRegRegistryValid remaining rest then
        psMinRegSpecValid remaining (psMinRegSpecCount rest) spec
      else false

def psMinRegCtorAt (constructors : List (List PsMinRegField)) (index : Nat) : Option (List PsMinRegField) :=
  match constructors with
  | List.nil => Option.none
  | List.cons fields rest =>
    match index with
    | Nat.zero => Option.some fields
    | Nat.succ previous => psMinRegCtorAt rest previous

-- Ground references are relative to the earlier registry; current self is slot0.
def psMinRegFieldArrow (fields : List PsMinRegField) (result : PsMinRegTy) : PsMinRegTy :=
  match fields with
  | List.nil => result
  | List.cons field rest =>
    match field with
    | PsMinRegField.ground type => PsMinRegTy.arr (psMinRegLiftTy type) (psMinRegFieldArrow rest result)
    | PsMinRegField.recursive => PsMinRegTy.arr (PsMinRegTy.data 0) (psMinRegFieldArrow rest result)

def psMinRegRepeatArrow (count : Nat) (domain result : PsMinRegTy) : PsMinRegTy :=
  match count with
  | Nat.zero => result
  | Nat.succ previous => PsMinRegTy.arr domain (psMinRegRepeatArrow previous domain result)

def psMinRegMinorTy (result : PsMinRegTy) (fields : List PsMinRegField) : PsMinRegTy :=
  psMinRegFieldArrow fields (psMinRegRepeatArrow (psMinRegSelfCount fields) result result)

def psMinRegRecursorTy (result : PsMinRegTy) (constructors : List (List PsMinRegField)) : PsMinRegTy :=
  match constructors with
  | List.nil => PsMinRegTy.arr (PsMinRegTy.data 0) result
  | List.cons fields rest => PsMinRegTy.arr (psMinRegMinorTy result fields) (psMinRegRecursorTy result rest)

def psMinRegCtorTypeAt (specs : List PsMinRegSpec) (dataIndex constructorIndex : Nat) : Option PsMinRegTy :=
  match specs with
  | List.nil => Option.none
  | List.cons spec rest =>
    match dataIndex with
    | Nat.zero =>
      match psMinRegCtorAt spec.constructors constructorIndex with
      | Option.none => Option.none
      | Option.some fields => Option.some (psMinRegFieldArrow fields (PsMinRegTy.data 0))
    | Nat.succ previous =>
      match psMinRegCtorTypeAt rest previous constructorIndex with
      | Option.none => Option.none
      | Option.some type => Option.some (psMinRegLiftTy type)

def psMinRegRecursorAllowed (fuel bound : Nat) (spec : PsMinRegSpec)
    (universe parameters indices motives minors : Nat) (result : PsMinRegTy) : Bool :=
  if Nat.beq universe 1 then
    if Nat.beq parameters 0 then
      if Nat.beq indices 0 then
        if Nat.beq motives 1 then
          if Nat.beq minors (psMinRegCtorCount spec.constructors) then
            psMinRegTyValid fuel bound result
          else false
        else false
      else false
    else false
  else false

-- Result codes are relative to the selected family and its earlier registry.
def psMinRegRecursorTypeAt (fuel : Nat) (specs : List PsMinRegSpec)
    (dataIndex universe parameters indices motives minors : Nat) (result : PsMinRegTy) : Option PsMinRegTy :=
  match specs with
  | List.nil => Option.none
  | List.cons spec rest =>
    match dataIndex with
    | Nat.zero =>
      if psMinRegRecursorAllowed fuel (Nat.succ (psMinRegSpecCount rest)) spec
          universe parameters indices motives minors result then
        Option.some (psMinRegRecursorTy result spec.constructors)
      else Option.none
    | Nat.succ previous =>
      match psMinRegRecursorTypeAt fuel rest previous universe parameters indices motives minors result with
      | Option.none => Option.none
      | Option.some type => Option.some (psMinRegLiftTy type)
