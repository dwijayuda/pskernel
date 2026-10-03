inductive PsKernelName where
  | anonymous
  | str (parent : PsKernelName) (value : String)
  | num (parent : PsKernelName) (value : Nat)

inductive PsKernelNameComponent where
  | str (value : String)
  | num (value : Nat)

def psKernelStringEqFromWithFuel
    (fuel : Nat)
    (left : String)
    (right : String)
    (leftPos : Nat)
    (rightPos : Nat) : Bool :=
  match fuel with
  | Nat.zero =>
      false
  | Nat.succ remaining =>
      if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
        String.Internal.atEnd right (String.Pos.Raw.mk rightPos)
      else if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
        false
      else
        let leftChar :=
          String.Internal.get left (String.Pos.Raw.mk leftPos)
        let rightChar :=
          String.Internal.get right (String.Pos.Raw.mk rightPos)
        if Nat.beq (Char.toNat leftChar) (Char.toNat rightChar) then
          psKernelStringEqFromWithFuel
            remaining
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
        else
          false

def psKernelStringEq
    (left : String)
    (right : String) : Bool :=
  if Nat.beq (String.utf8ByteSize left) (String.utf8ByteSize right) then
    psKernelStringEqFromWithFuel
      (Nat.succ (String.utf8ByteSize left))
      left
      right
      0
      0
  else
    false

def psKernelNatCmp
    (left : Nat)
    (right : Nat) : Ordering :=
  if Nat.beq left right then
    Ordering.eq
  else if Nat.ble left right then
    Ordering.lt
  else
    Ordering.gt

def psKernelNatLt
    (left : Nat)
    (right : Nat) : Bool :=
  if Nat.beq left right then
    false
  else
    Nat.ble left right

def psKernelNatGt
    (left : Nat)
    (right : Nat) : Bool :=
  psKernelNatLt right left

def psKernelNatGe
    (left : Nat)
    (right : Nat) : Bool :=
  Nat.ble right left

def psKernelStringCmpWithFuel
    (fuel : Nat)
    (left : String)
    (right : String)
    (leftPos : Nat)
    (rightPos : Nat) : Ordering :=
  match fuel with
  | Nat.zero =>
      Ordering.eq
  | Nat.succ remaining =>
      if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
        if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
          Ordering.eq
        else
          Ordering.lt
      else if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
        Ordering.gt
      else
        let leftChar :=
          Char.toNat
            (String.Internal.get
              left
              (String.Pos.Raw.mk leftPos))
        let rightChar :=
          Char.toNat
            (String.Internal.get
              right
              (String.Pos.Raw.mk rightPos))
        if Nat.beq leftChar rightChar then
          psKernelStringCmpWithFuel
            remaining
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
        else if Nat.ble leftChar rightChar then
          Ordering.lt
        else
          Ordering.gt

def psKernelStringCmp
    (left : String)
    (right : String) : Ordering :=
  psKernelStringCmpWithFuel
    (Nat.succ
      (Nat.add
        (String.utf8ByteSize left)
        (String.utf8ByteSize right)))
    left
    right
    0
    0

def psKernelNatToString
    (value : Nat) : String :=
  Int.repr (Int.ofNat value)

def psKernelNameEq
    (left : PsKernelName)
    (right : PsKernelName) : Bool :=
  match left with
  | PsKernelName.anonymous =>
      match right with
      | PsKernelName.anonymous => true
      | _ => false
  | PsKernelName.str leftParent leftValue =>
      match right with
      | PsKernelName.str rightParent rightValue =>
          if psKernelStringEq leftValue rightValue then
            psKernelNameEq leftParent rightParent
          else
            false
      | _ => false
  | PsKernelName.num leftParent leftValue =>
      match right with
      | PsKernelName.num rightParent rightValue =>
          if Nat.beq leftValue rightValue then
            psKernelNameEq leftParent rightParent
          else
            false
      | _ => false

def psKernelNameAppendAfter
    (name : PsKernelName)
    (suffix : String) : PsKernelName :=
  match name with
  | PsKernelName.str parent value =>
      PsKernelName.str parent (String.Internal.append value suffix)
  | other =>
      PsKernelName.str other suffix

def psKernelNameAppend
    (base : PsKernelName)
    (suffix : PsKernelName) : PsKernelName :=
  match suffix with
  | PsKernelName.anonymous =>
      base
  | PsKernelName.str parent value =>
      PsKernelName.str
        (psKernelNameAppend base parent)
        value
  | PsKernelName.num parent value =>
      PsKernelName.num
        (psKernelNameAppend base parent)
        value

def psKernelNameAppendIndexAfter
    (name : PsKernelName)
    (index : Nat) : PsKernelName :=
  psKernelNameAppendAfter
    name
    (String.Internal.append "_" (psKernelNatToString index))

def psKernelNameIsPrefixOf
    (needle : PsKernelName)
    (candidate : PsKernelName) : Bool :=
  match candidate with
  | PsKernelName.anonymous =>
      psKernelNameEq needle PsKernelName.anonymous
  | PsKernelName.str parent value =>
      let current := PsKernelName.str parent value
      if psKernelNameEq needle current then
        true
      else
        psKernelNameIsPrefixOf needle parent
  | PsKernelName.num parent value =>
      let current := PsKernelName.num parent value
      if psKernelNameEq needle current then
        true
      else
        psKernelNameIsPrefixOf needle parent

def psKernelNameReplacePrefix
    (name : PsKernelName)
    (oldPrefix : PsKernelName)
    (newPrefix : PsKernelName) : Option PsKernelName :=
  if psKernelNameEq name oldPrefix then
    Option.some newPrefix
  else
    match name with
    | PsKernelName.str parent value =>
        match
            psKernelNameReplacePrefix
              parent
              oldPrefix
              newPrefix with
        | Option.some replacedParent =>
            Option.some
              (PsKernelName.str replacedParent value)
        | Option.none =>
            Option.none
    | PsKernelName.num parent value =>
        match
            psKernelNameReplacePrefix
              parent
              oldPrefix
              newPrefix with
        | Option.some replacedParent =>
            Option.some
              (PsKernelName.num replacedParent value)
        | Option.none =>
            Option.none
    | PsKernelName.anonymous =>
        Option.none

def psKernelNameComponentAppend
    (left : List PsKernelNameComponent)
    (right : List PsKernelNameComponent) :
    List PsKernelNameComponent :=
  match left with
  | List.nil => right
  | List.cons head tail =>
      List.cons
        head
        (psKernelNameComponentAppend tail right)

def psKernelNameComponents
    (name : PsKernelName) :
    List PsKernelNameComponent :=
  match name with
  | PsKernelName.anonymous =>
      List.nil
  | PsKernelName.str parent value =>
      psKernelNameComponentAppend
        (psKernelNameComponents parent)
        (List.cons
          (PsKernelNameComponent.str value)
          List.nil)
  | PsKernelName.num parent value =>
      psKernelNameComponentAppend
        (psKernelNameComponents parent)
        (List.cons
          (PsKernelNameComponent.num value)
          List.nil)

def psKernelNameComponentCmp
    (left : PsKernelNameComponent)
    (right : PsKernelNameComponent) : Ordering :=
  match left with
  | PsKernelNameComponent.num leftValue =>
      match right with
      | PsKernelNameComponent.num rightValue =>
          psKernelNatCmp leftValue rightValue
      | PsKernelNameComponent.str _ =>
          Ordering.lt
  | PsKernelNameComponent.str leftValue =>
      match right with
      | PsKernelNameComponent.num _ =>
          Ordering.gt
      | PsKernelNameComponent.str rightValue =>
          psKernelStringCmp leftValue rightValue

def psKernelCompareNameComponents
    (left : List PsKernelNameComponent)
    (right : List PsKernelNameComponent) :
    Ordering :=
  match left with
  | List.nil =>
      match right with
      | List.nil => Ordering.eq
      | List.cons _ _ => Ordering.lt
  | List.cons leftHead leftTail =>
      match right with
      | List.nil =>
          Ordering.gt
      | List.cons rightHead rightTail =>
          match
              psKernelNameComponentCmp
                leftHead
                rightHead with
          | Ordering.eq =>
              psKernelCompareNameComponents
                leftTail
                rightTail
          | ordering =>
              ordering

def psKernelNameCmp
    (left : PsKernelName)
    (right : PsKernelName) : Ordering :=
  psKernelCompareNameComponents
    (psKernelNameComponents left)
    (psKernelNameComponents right)
