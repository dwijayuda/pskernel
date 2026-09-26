import Ps.KernelCore.Data

inductive PsKernelCoreName where
  | anonymous
  | str (parent : PsKernelCoreName) (value : String)
  | num (parent : PsKernelCoreName) (value : Nat)

def psKernelCoreStringPositionAfter
    (value : String)
    (steps : Nat) : Nat :=
  match steps with
  | Nat.zero => 0
  | Nat.succ remaining =>
      let previous :=
        psKernelCoreStringPositionAfter value remaining;
      if String.Internal.atEnd value (String.Pos.Raw.mk previous) then
        previous
      else
        String.Pos.Raw.byteIdx
          (String.Internal.next
            value
            (String.Pos.Raw.mk previous))

def psKernelCoreStringEqCount
    (left : String)
    (right : String)
    (count : Nat) : Bool :=
  match count with
  | Nat.zero => true
  | Nat.succ remaining =>
      let leftPos :=
        psKernelCoreStringPositionAfter left remaining;
      let rightPos :=
        psKernelCoreStringPositionAfter right remaining;
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
          psKernelCoreStringEqCount left right remaining
        else
          false

def psKernelCoreStringEq
    (left : String)
    (right : String) : Bool :=
  let leftLength := String.Internal.length left;
  let rightLength := String.Internal.length right;
  if Nat.beq leftLength rightLength then
    psKernelCoreStringEqCount left right leftLength
  else
    false

def psKernelCoreNameEq
    (left : PsKernelCoreName) : PsKernelCoreName -> Bool :=
  match left with
  | PsKernelCoreName.anonymous =>
      fun (right : PsKernelCoreName) =>
        match right with
        | PsKernelCoreName.anonymous => true
        | _ => false
  | PsKernelCoreName.str leftParent leftValue =>
      let parentEq : PsKernelCoreName -> Bool :=
        psKernelCoreNameEq leftParent;
      fun (right : PsKernelCoreName) =>
        match right with
        | PsKernelCoreName.str rightParent rightValue =>
            if parentEq rightParent then
              psKernelCoreStringEq leftValue rightValue
            else
              false
        | _ => false
  | PsKernelCoreName.num leftParent leftValue =>
      let parentEq : PsKernelCoreName -> Bool :=
        psKernelCoreNameEq leftParent;
      fun (right : PsKernelCoreName) =>
        match right with
        | PsKernelCoreName.num rightParent rightValue =>
            if parentEq rightParent then
              Nat.beq leftValue rightValue
            else
              false
        | _ => false

def psKernelCoreNameMember
    (target : PsKernelCoreName)
    (names : PsKernelCoreList PsKernelCoreName) : Bool :=
  match names with
  | PsKernelCoreList.nil => false
  | PsKernelCoreList.cons name rest =>
      if psKernelCoreNameEq target name then
        true
      else
        psKernelCoreNameMember target rest

def psKernelCoreNameHasDuplicates
    (names : PsKernelCoreList PsKernelCoreName) : Bool :=
  match names with
  | PsKernelCoreList.nil => false
  | PsKernelCoreList.cons name rest =>
      if psKernelCoreNameMember name rest then
        true
      else
        psKernelCoreNameHasDuplicates rest
