import Ps.KernelOne.Data

inductive PsKernelOneName where
  | anonymous
  | str (parent : PsKernelOneName) (value : String)
  | num (parent : PsKernelOneName) (value : Nat)

def psKernelOneStringPositionAfter
    (value : String)
    (steps : Nat) : Nat :=
  match steps with
  | Nat.zero => 0
  | Nat.succ remaining =>
      let previous :=
        psKernelOneStringPositionAfter value remaining;
      if String.Internal.atEnd value (String.Pos.Raw.mk previous) then
        previous
      else
        String.Pos.Raw.byteIdx
          (String.Internal.next
            value
            (String.Pos.Raw.mk previous))

def psKernelOneStringEqCount
    (left : String)
    (right : String)
    (count : Nat) : Bool :=
  match count with
  | Nat.zero => true
  | Nat.succ remaining =>
      let leftPos :=
        psKernelOneStringPositionAfter left remaining;
      let rightPos :=
        psKernelOneStringPositionAfter right remaining;
      if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
        false
      else if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
        false
      else
        let leftChar : Char :=
          String.Internal.get left (String.Pos.Raw.mk leftPos);
        let rightChar : Char :=
          String.Internal.get right (String.Pos.Raw.mk rightPos);
        if Nat.beq (Char.toNat leftChar) (Char.toNat rightChar) then
          psKernelOneStringEqCount left right remaining
        else
          false

def psKernelOneStringEq
    (left : String)
    (right : String) : Bool :=
  let leftLength := String.Internal.length left;
  let rightLength := String.Internal.length right;
  if Nat.beq leftLength rightLength then
    psKernelOneStringEqCount left right leftLength
  else
    false

def psKernelOneNameEq
    (left : PsKernelOneName) : PsKernelOneName -> Bool :=
  match left with
  | PsKernelOneName.anonymous =>
      fun (right : PsKernelOneName) =>
        match right with
        | PsKernelOneName.anonymous => true
        | _ => false
  | PsKernelOneName.str leftParent leftValue =>
      let parentEq : PsKernelOneName -> Bool :=
        psKernelOneNameEq leftParent;
      fun (right : PsKernelOneName) =>
        match right with
        | PsKernelOneName.str rightParent rightValue =>
            if parentEq rightParent then
              psKernelOneStringEq leftValue rightValue
            else
              false
        | _ => false
  | PsKernelOneName.num leftParent leftValue =>
      let parentEq : PsKernelOneName -> Bool :=
        psKernelOneNameEq leftParent;
      fun (right : PsKernelOneName) =>
        match right with
        | PsKernelOneName.num rightParent rightValue =>
            if parentEq rightParent then
              Nat.beq leftValue rightValue
            else
              false
        | _ => false

def psKernelOneNameMember
    (target : PsKernelOneName)
    (names : PsKernelOneList PsKernelOneName) : Bool :=
  match names with
  | PsKernelOneList.nil => false
  | PsKernelOneList.cons name rest =>
      if psKernelOneNameEq target name then
        true
      else
        psKernelOneNameMember target rest

def psKernelOneNameHasDuplicates
    (names : PsKernelOneList PsKernelOneName) : Bool :=
  match names with
  | PsKernelOneList.nil => false
  | PsKernelOneList.cons name rest =>
      if psKernelOneNameMember name rest then
        true
      else
        psKernelOneNameHasDuplicates rest
