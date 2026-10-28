import Ps.MinKernel.Profile.RegularCheck

-- Normalized operational schemas. Raw canonical names/bytes are outside this API.
def psMinOpFieldType (fields : List PsMinRegField) (index : Nat) : Option PsMinRegTy :=
  match fields with
  | List.nil => Option.none
  | List.cons field rest =>
    match index with
    | Nat.zero =>
      match field with
      | PsMinRegField.ground type => Option.some (psMinRegLiftTy type)
      | PsMinRegField.recursive => Option.some (PsMinRegTy.data 0)
    | Nat.succ previous => psMinOpFieldType rest previous

def psMinOpProjectionType (specs : List PsMinRegSpec) (slot field : Nat) : Option PsMinRegTy :=
  match specs with
  | List.nil => Option.none
  | List.cons spec rest =>
    match slot with
    | Nat.zero =>
      match spec.constructors with
      | List.nil => Option.none
      | List.cons fields others =>
        match others with
        | List.nil =>
          match psMinOpFieldType fields field with
          | Option.none => Option.none
          | Option.some type => Option.some (PsMinRegTy.arr (PsMinRegTy.data 0) type)
        | List.cons _ _ => Option.none
    | Nat.succ previous =>
      match psMinOpProjectionType rest previous field with
      | Option.none => Option.none
      | Option.some type => Option.some (psMinRegLiftTy type)

inductive PsMinOpPrimitive where
  | natSucc
  | natPred
  | natAdd
  | natSub
  | natBeq
  | natBlt
  | boolNot
  | boolBeq
  | natRec (result : PsMinRegTy)
  | listNil (element : PsMinRegTy)
  | listCons (element : PsMinRegTy)
  | listRec (element : PsMinRegTy) (result : PsMinRegTy)
  | optionNone (element : PsMinRegTy)
  | optionSome (element : PsMinRegTy)
  | optionRec (element : PsMinRegTy) (result : PsMinRegTy)
  | boolEqIte (result : PsMinRegTy)

def psMinOpPrimitiveSignature (primitive : PsMinOpPrimitive) : PsMinRegTy :=
  match primitive with
  | PsMinOpPrimitive.natSucc => PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.nat
  | PsMinOpPrimitive.natPred => PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.nat
  | PsMinOpPrimitive.natAdd => PsMinRegTy.arr PsMinRegTy.nat (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.nat)
  | PsMinOpPrimitive.natSub => PsMinRegTy.arr PsMinRegTy.nat (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.nat)
  | PsMinOpPrimitive.natBeq => PsMinRegTy.arr PsMinRegTy.nat (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.boolean)
  | PsMinOpPrimitive.natBlt => PsMinRegTy.arr PsMinRegTy.nat (PsMinRegTy.arr PsMinRegTy.nat PsMinRegTy.boolean)
  | PsMinOpPrimitive.boolNot => PsMinRegTy.arr PsMinRegTy.boolean PsMinRegTy.boolean
  | PsMinOpPrimitive.boolBeq => PsMinRegTy.arr PsMinRegTy.boolean (PsMinRegTy.arr PsMinRegTy.boolean PsMinRegTy.boolean)
  | PsMinOpPrimitive.natRec result =>
    PsMinRegTy.arr result (PsMinRegTy.arr (PsMinRegTy.arr PsMinRegTy.nat (PsMinRegTy.arr result result)) (PsMinRegTy.arr PsMinRegTy.nat result))
  | PsMinOpPrimitive.listNil element => PsMinRegTy.list element
  | PsMinOpPrimitive.listCons element => PsMinRegTy.arr element (PsMinRegTy.arr (PsMinRegTy.list element) (PsMinRegTy.list element))
  | PsMinOpPrimitive.listRec element result =>
    PsMinRegTy.arr result (PsMinRegTy.arr (PsMinRegTy.arr element (PsMinRegTy.arr (PsMinRegTy.list element) (PsMinRegTy.arr result result))) (PsMinRegTy.arr (PsMinRegTy.list element) result))
  | PsMinOpPrimitive.optionNone element => PsMinRegTy.option element
  | PsMinOpPrimitive.optionSome element => PsMinRegTy.arr element (PsMinRegTy.option element)
  | PsMinOpPrimitive.optionRec element result =>
    PsMinRegTy.arr result (PsMinRegTy.arr (PsMinRegTy.arr element result) (PsMinRegTy.arr (PsMinRegTy.option element) result))
  | PsMinOpPrimitive.boolEqIte result =>
    PsMinRegTy.arr PsMinRegTy.boolean (PsMinRegTy.arr PsMinRegTy.boolean (PsMinRegTy.arr result (PsMinRegTy.arr result result)))

-- Codes are the explicitly supplied closed type arguments of each schema.
def psMinOpPrimitiveCodesValid (fuel bound : Nat) (primitive : PsMinOpPrimitive) : Bool :=
  match primitive with
  | PsMinOpPrimitive.natRec result => psMinRegTyValid fuel bound result
  | PsMinOpPrimitive.listNil element => psMinRegTyValid fuel bound element
  | PsMinOpPrimitive.listCons element => psMinRegTyValid fuel bound element
  | PsMinOpPrimitive.listRec element result =>
    if psMinRegTyValid fuel bound element then psMinRegTyValid fuel bound result else false
  | PsMinOpPrimitive.optionNone element => psMinRegTyValid fuel bound element
  | PsMinOpPrimitive.optionSome element => psMinRegTyValid fuel bound element
  | PsMinOpPrimitive.optionRec element result =>
    if psMinRegTyValid fuel bound element then psMinRegTyValid fuel bound result else false
  | PsMinOpPrimitive.boolEqIte result => psMinRegTyValid fuel bound result
  | _ => true

def psMinOpPrimitiveLevel (primitive : PsMinOpPrimitive) : Nat :=
  match primitive with
  | PsMinOpPrimitive.natRec _ => 1
  | PsMinOpPrimitive.listRec _ _ => 1
  | PsMinOpPrimitive.optionRec _ _ => 1
  | PsMinOpPrimitive.boolEqIte _ => 1
  | _ => 0

def psMinOpPrimitiveParameters (primitive : PsMinOpPrimitive) : Nat :=
  match primitive with
  | PsMinOpPrimitive.listNil _ => 1
  | PsMinOpPrimitive.listCons _ => 1
  | PsMinOpPrimitive.listRec _ _ => 1
  | PsMinOpPrimitive.optionNone _ => 1
  | PsMinOpPrimitive.optionSome _ => 1
  | PsMinOpPrimitive.optionRec _ _ => 1
  | PsMinOpPrimitive.boolEqIte _ => 1
  | _ => 0

def psMinOpPrimitiveMotives (primitive : PsMinOpPrimitive) : Nat :=
  match primitive with
  | PsMinOpPrimitive.natRec _ => 1
  | PsMinOpPrimitive.listRec _ _ => 1
  | PsMinOpPrimitive.optionRec _ _ => 1
  | _ => 0

def psMinOpPrimitiveMinors (primitive : PsMinOpPrimitive) : Nat :=
  match primitive with
  | PsMinOpPrimitive.natRec _ => 2
  | PsMinOpPrimitive.listRec _ _ => 2
  | PsMinOpPrimitive.optionRec _ _ => 2
  | _ => 0

def psMinOpPrimitiveType (fuel bound : Nat) (primitive : PsMinOpPrimitive)
    (sortLevel parameters indices motives minors : Nat) : Option PsMinRegTy :=
  if Nat.beq sortLevel (psMinOpPrimitiveLevel primitive) then
    if Nat.beq parameters (psMinOpPrimitiveParameters primitive) then
      if Nat.beq indices 0 then
        if Nat.beq motives (psMinOpPrimitiveMotives primitive) then
          if Nat.beq minors (psMinOpPrimitiveMinors primitive) then
            if psMinOpPrimitiveCodesValid fuel bound primitive then Option.some (psMinOpPrimitiveSignature primitive)
            else Option.none
          else Option.none
        else Option.none
      else Option.none
    else Option.none
  else Option.none
