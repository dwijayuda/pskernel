inductive PsKernelName where
  | anonymous
  | str (parent : PsKernelName) (value : String)
  | num (parent : PsKernelName) (value : Nat)

inductive PsKernelNameComponent where
  | str (value : String)
  | num (value : Nat)

inductive PsKernelOrdering where
  | lt
  | eq
  | gt

def psKernelStringEqFromWithFuel
    (fuel : Nat) :
    String -> String -> Nat -> Nat -> Bool :=
  match fuel with
  | Nat.zero =>
      fun
        (_left : String)
        (_right : String)
        (_leftPos : Nat)
        (_rightPos : Nat) =>
        false
  | Nat.succ remaining =>
      let smaller :
          String -> String -> Nat -> Nat -> Bool :=
        psKernelStringEqFromWithFuel remaining;
      fun
        (left : String)
        (right : String)
        (leftPos : Nat)
        (rightPos : Nat) =>
        if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
          String.Internal.atEnd right (String.Pos.Raw.mk rightPos)
        else if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
          false
        else
          let leftChar :=
            String.Internal.get left (String.Pos.Raw.mk leftPos);
          let rightChar :=
            String.Internal.get right (String.Pos.Raw.mk rightPos);
          if Nat.beq (Char.toNat leftChar) (Char.toNat rightChar) then
            smaller
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
    (right : Nat) : PsKernelOrdering :=
  if Nat.beq left right then
    PsKernelOrdering.eq
  else if Nat.ble left right then
    PsKernelOrdering.lt
  else
    PsKernelOrdering.gt

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
    (fuel : Nat) :
    String -> String -> Nat -> Nat -> PsKernelOrdering :=
  match fuel with
  | Nat.zero =>
      fun
        (_left : String)
        (_right : String)
        (_leftPos : Nat)
        (_rightPos : Nat) =>
        PsKernelOrdering.eq
  | Nat.succ remaining =>
      let smaller :
          String -> String -> Nat -> Nat -> PsKernelOrdering :=
        psKernelStringCmpWithFuel remaining;
      fun
        (left : String)
        (right : String)
        (leftPos : Nat)
        (rightPos : Nat) =>
        if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
          if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
            PsKernelOrdering.eq
          else
            PsKernelOrdering.lt
        else if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
          PsKernelOrdering.gt
        else
          let leftChar :=
            Char.toNat
              (String.Internal.get
                left
                (String.Pos.Raw.mk leftPos));
          let rightChar :=
            Char.toNat
              (String.Internal.get
                right
                (String.Pos.Raw.mk rightPos));
          if Nat.beq leftChar rightChar then
            smaller
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
            PsKernelOrdering.lt
          else
            PsKernelOrdering.gt

def psKernelStringCmp
    (left : String)
    (right : String) : PsKernelOrdering :=
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
    (left : PsKernelName) :
    PsKernelName -> Bool :=
  match left with
  | PsKernelName.anonymous =>
      fun (right : PsKernelName) =>
        match right with
        | PsKernelName.anonymous => true
        | _ => false
  | PsKernelName.str leftParent leftValue =>
      let smaller : PsKernelName -> Bool :=
        psKernelNameEq leftParent;
      fun (right : PsKernelName) =>
        match right with
        | PsKernelName.str rightParent rightValue =>
            if psKernelStringEq leftValue rightValue then
              smaller rightParent
            else
              false
        | _ => false
  | PsKernelName.num leftParent leftValue =>
      let smaller : PsKernelName -> Bool :=
        psKernelNameEq leftParent;
      fun (right : PsKernelName) =>
        match right with
        | PsKernelName.num rightParent rightValue =>
            if Nat.beq leftValue rightValue then
              smaller rightParent
            else
              false
        | _ => false

def psKernelNameAppendAfter
    (name : PsKernelName)
    (suffix : String) : PsKernelName :=
  match name with
  | PsKernelName.str parent value =>
      PsKernelName.str parent (String.Internal.append value suffix)
  | PsKernelName.anonymous =>
      PsKernelName.str PsKernelName.anonymous suffix
  | PsKernelName.num parent value =>
      PsKernelName.str
        (PsKernelName.num parent value)
        suffix

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
      let current := PsKernelName.str parent value;
      if psKernelNameEq needle current then
        true
      else
        psKernelNameIsPrefixOf needle parent
  | PsKernelName.num parent value =>
      let current := PsKernelName.num parent value;
      if psKernelNameEq needle current then
        true
      else
        psKernelNameIsPrefixOf needle parent

def psKernelNameReplacePrefix
    (name : PsKernelName) :
    PsKernelName -> PsKernelName -> Option PsKernelName :=
  match name with
  | PsKernelName.anonymous =>
      fun
        (oldPrefix : PsKernelName)
        (newPrefix : PsKernelName) =>
        if
            psKernelNameEq
              PsKernelName.anonymous
              oldPrefix then
          Option.some newPrefix
        else
          Option.none
  | PsKernelName.str parent value =>
      let smaller :
          PsKernelName ->
          PsKernelName ->
          Option PsKernelName :=
        psKernelNameReplacePrefix parent;
      fun
        (oldPrefix : PsKernelName)
        (newPrefix : PsKernelName) =>
        let current :=
          PsKernelName.str parent value;
        if psKernelNameEq current oldPrefix then
          Option.some newPrefix
        else
          match smaller oldPrefix newPrefix with
          | Option.some replacedParent =>
              Option.some
                (PsKernelName.str
                  replacedParent
                  value)
          | Option.none =>
              Option.none
  | PsKernelName.num parent value =>
      let smaller :
          PsKernelName ->
          PsKernelName ->
          Option PsKernelName :=
        psKernelNameReplacePrefix parent;
      fun
        (oldPrefix : PsKernelName)
        (newPrefix : PsKernelName) =>
        let current :=
          PsKernelName.num parent value;
        if psKernelNameEq current oldPrefix then
          Option.some newPrefix
        else
          match smaller oldPrefix newPrefix with
          | Option.some replacedParent =>
              Option.some
                (PsKernelName.num
                  replacedParent
                  value)
          | Option.none =>
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
    (right : PsKernelNameComponent) : PsKernelOrdering :=
  match left with
  | PsKernelNameComponent.num leftValue =>
      match right with
      | PsKernelNameComponent.num rightValue =>
          psKernelNatCmp leftValue rightValue
      | PsKernelNameComponent.str _ =>
          PsKernelOrdering.lt
  | PsKernelNameComponent.str leftValue =>
      match right with
      | PsKernelNameComponent.num _ =>
          PsKernelOrdering.gt
      | PsKernelNameComponent.str rightValue =>
          psKernelStringCmp leftValue rightValue

def psKernelCompareNameComponents
    (left : List PsKernelNameComponent) :
    List PsKernelNameComponent -> PsKernelOrdering :=
  match left with
  | List.nil =>
      fun (right : List PsKernelNameComponent) =>
        match right with
        | List.nil => PsKernelOrdering.eq
        | List.cons _ _ => PsKernelOrdering.lt
  | List.cons leftHead leftTail =>
      let smaller :
          List PsKernelNameComponent -> PsKernelOrdering :=
        psKernelCompareNameComponents leftTail;
      fun (right : List PsKernelNameComponent) =>
        match right with
        | List.nil =>
            PsKernelOrdering.gt
        | List.cons rightHead rightTail =>
            match
                psKernelNameComponentCmp
                  leftHead
                  rightHead with
            | PsKernelOrdering.eq =>
                smaller rightTail
            | PsKernelOrdering.lt =>
                PsKernelOrdering.lt
            | PsKernelOrdering.gt =>
                PsKernelOrdering.gt

def psKernelNameCmp
    (left : PsKernelName)
    (right : PsKernelName) : PsKernelOrdering :=
  psKernelCompareNameComponents
    (psKernelNameComponents left)
    (psKernelNameComponents right)

def psKernelNameListLength
    (values : List PsKernelName) : Nat :=
  match values with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ
        (psKernelNameListLength rest)
