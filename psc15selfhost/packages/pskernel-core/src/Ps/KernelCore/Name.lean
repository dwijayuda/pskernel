import Ps.KernelCore.Data

inductive PsKernelCoreName where
  | anonymous
  | str (parent : PsKernelCoreName) (value : String)
  | num (parent : PsKernelCoreName) (value : Nat)

def psKernelCoreStringEqFrom
    (left : String)
    (right : String)
    (leftPos : Nat)
    (rightPos : Nat)
    (fuel : Nat) : Bool :=
  match fuel with
  | Nat.zero =>
      if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
        String.Internal.atEnd right (String.Pos.Raw.mk rightPos)
      else
        false
  | Nat.succ remaining =>
      if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
        String.Internal.atEnd right (String.Pos.Raw.mk rightPos)
      else if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
        false
      else
        let leftChar : Char :=
          String.Internal.get left (String.Pos.Raw.mk leftPos);
        let rightChar : Char :=
          String.Internal.get right (String.Pos.Raw.mk rightPos);
        if Nat.beq (Char.toNat leftChar) (Char.toNat rightChar) then
          psKernelCoreStringEqFrom
            left
            right
            (String.Pos.Raw.byteIdx
              (String.Internal.next
                left
                (String.Pos.Raw.mk leftPos)))
            (String.Pos.Raw.byteIdx
              (String.Internal.next
                right
                (String.Pos.Raw.mk rightPos)))
            remaining
        else
          false

def psKernelCoreStringEq
    (left : String)
    (right : String) : Bool :=
  psKernelCoreStringEqFrom
    left
    right
    0
    0
    (String.utf8ByteSize left)

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
