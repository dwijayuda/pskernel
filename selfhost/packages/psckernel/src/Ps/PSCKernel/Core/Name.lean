inductive PsCKernelName where
  | anonymous
  | str (parent : PsCKernelName) (value : String)
  | num (parent : PsCKernelName) (value : Nat)

inductive PsCKernelNameComponent where
  | str (value : String)
  | num (value : Nat)

def psCKernelAnonymous : PsCKernelName :=
  PsCKernelName.anonymous

def psCKernelStrName (parent : PsCKernelName) (value : String) : PsCKernelName :=
  PsCKernelName.str parent value

def psCKernelNumName (parent : PsCKernelName) (value : Nat) : PsCKernelName :=
  PsCKernelName.num parent value

partial def psCKernelStringEqFrom
    (left : String)
    (right : String)
    (leftPos : Nat)
    (rightPos : Nat) : Bool :=
  if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
    String.Internal.atEnd right (String.Pos.Raw.mk rightPos)
  else if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
    false
  else
    let leftChar : Char :=
      String.Internal.get left (String.Pos.Raw.mk leftPos)
    let rightChar : Char :=
      String.Internal.get right (String.Pos.Raw.mk rightPos)
    if Nat.beq (Char.toNat leftChar) (Char.toNat rightChar) then
      psCKernelStringEqFrom
        left
        right
        (String.Pos.Raw.byteIdx
          (String.Internal.next left (String.Pos.Raw.mk leftPos)))
        (String.Pos.Raw.byteIdx
          (String.Internal.next right (String.Pos.Raw.mk rightPos)))
    else
      false

def psCKernelStringEq (left : String) (right : String) : Bool :=
  psCKernelStringEqFrom left right 0 0

partial def psCKernelNatToString (value : Nat) : String :=
  if Nat.blt value 10 then
    String.singleton (Char.ofNat (Nat.add 48 value))
  else
    String.Internal.append
      (psCKernelNatToString (Nat.div value 10))
      (String.singleton
        (Char.ofNat (Nat.add 48 (Nat.mod value 10))))

def psCKernelNameEq (left : PsCKernelName) : PsCKernelName -> Bool :=
  match left with
  | PsCKernelName.anonymous =>
      fun (right : PsCKernelName) =>
        match right with
        | PsCKernelName.anonymous => true
        | _ => false
  | PsCKernelName.str leftParent leftValue =>
      let compareParent : PsCKernelName -> Bool := psCKernelNameEq leftParent
      fun (right : PsCKernelName) =>
        match right with
        | PsCKernelName.str rightParent rightValue =>
            if compareParent rightParent then
              psCKernelStringEq leftValue rightValue
            else
              false
        | _ => false
  | PsCKernelName.num leftParent leftValue =>
      let compareParent : PsCKernelName -> Bool := psCKernelNameEq leftParent
      fun (right : PsCKernelName) =>
        match right with
        | PsCKernelName.num rightParent rightValue =>
            if compareParent rightParent then
              Nat.beq leftValue rightValue
            else
              false
        | _ => false

partial def psCKernelNameFromDottedGo
    (source : String)
    (position : Nat)
    (parent : PsCKernelName)
    (part : String) : PsCKernelName :=
  if String.Internal.atEnd source (String.Pos.Raw.mk position) then
    if Nat.beq (String.Internal.length part) 0 then
      parent
    else
      PsCKernelName.str parent part
  else
    let current : Char :=
      String.Internal.get source (String.Pos.Raw.mk position)
    let nextPosition : Nat :=
      String.Pos.Raw.byteIdx
        (String.Internal.next source (String.Pos.Raw.mk position))
    if Nat.beq (Char.toNat current) 46 then
      let nextParent : PsCKernelName :=
        if Nat.beq (String.Internal.length part) 0 then
          parent
        else
          PsCKernelName.str parent part
      psCKernelNameFromDottedGo source nextPosition nextParent ""
    else
      psCKernelNameFromDottedGo
        source
        nextPosition
        parent
        (String.Internal.append part (String.singleton current))

def psCKernelNameFromDotted (source : String) : PsCKernelName :=
  if psCKernelStringEq source "" then
    psCKernelAnonymous
  else if psCKernelStringEq source "_" then
    psCKernelAnonymous
  else
    psCKernelNameFromDottedGo source 0 psCKernelAnonymous ""

def psCKernelNameAppendAfter
    (name : PsCKernelName)
    (suffix : String) : PsCKernelName :=
  match name with
  | PsCKernelName.str parent value =>
      PsCKernelName.str parent (String.Internal.append value suffix)
  | _ => PsCKernelName.str name suffix

def psCKernelNameAppendIndexAfter
    (name : PsCKernelName)
    (index : Nat) : PsCKernelName :=
  psCKernelNameAppendAfter
    name
    (String.Internal.append "_" (psCKernelNatToString index))

def psCKernelNameIsPrefixOf
    (candidate : PsCKernelName)
    (name : PsCKernelName) : Bool :=
  if psCKernelNameEq candidate name then
    true
  else
    match name with
    | PsCKernelName.anonymous => false
    | PsCKernelName.str parent _ =>
        psCKernelNameIsPrefixOf candidate parent
    | PsCKernelName.num parent _ =>
        psCKernelNameIsPrefixOf candidate parent

def psCKernelNameAppend
    (base : PsCKernelName)
    (suffix : PsCKernelName) : PsCKernelName :=
  match suffix with
  | PsCKernelName.anonymous => base
  | PsCKernelName.str parent value =>
      PsCKernelName.str (psCKernelNameAppend base parent) value
  | PsCKernelName.num parent value =>
      PsCKernelName.num (psCKernelNameAppend base parent) value

def psCKernelNameReplacePrefix
    (name : PsCKernelName)
    (query : PsCKernelName)
    (replacement : PsCKernelName) : PsCKernelName :=
  if psCKernelNameEq name query then
    replacement
  else
    match name with
    | PsCKernelName.anonymous => PsCKernelName.anonymous
    | PsCKernelName.str parent value =>
        PsCKernelName.str
          (psCKernelNameReplacePrefix parent query replacement)
          value
    | PsCKernelName.num parent value =>
        PsCKernelName.num
          (psCKernelNameReplacePrefix parent query replacement)
          value

partial def psCKernelStringUtf16LengthFrom
    (source : String)
    (position : Nat) : Nat :=
  if String.Internal.atEnd source (String.Pos.Raw.mk position) then
    0
  else
    let current : Char :=
      String.Internal.get source (String.Pos.Raw.mk position)
    let currentWidth : Nat :=
      if Nat.blt (Char.toNat current) 65536 then 1 else 2
    let nextPosition : Nat :=
      String.Pos.Raw.byteIdx
        (String.Internal.next source (String.Pos.Raw.mk position))
    Nat.add
      currentWidth
      (psCKernelStringUtf16LengthFrom source nextPosition)

def psCKernelStringUtf16Length (source : String) : Nat :=
  psCKernelStringUtf16LengthFrom source 0

def psCKernelNameKey (name : PsCKernelName) : String :=
  match name with
  | PsCKernelName.anonymous => "a"
  | PsCKernelName.str parent value =>
      String.Internal.append
        (psCKernelNameKey parent)
        (String.Internal.append
          "/s:"
          (String.Internal.append
            (psCKernelNatToString (psCKernelStringUtf16Length value))
            (String.Internal.append ":" value)))
  | PsCKernelName.num parent value =>
      String.Internal.append
        (psCKernelNameKey parent)
        (String.Internal.append "/n:" (psCKernelNatToString value))

partial def psCKernelStringCmpFrom
    (left : String)
    (right : String)
    (leftPos : Nat)
    (rightPos : Nat) : Int :=
  if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
    if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
      0
    else
      -1
  else if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
    1
  else
    let leftChar : Char :=
      String.Internal.get left (String.Pos.Raw.mk leftPos)
    let rightChar : Char :=
      String.Internal.get right (String.Pos.Raw.mk rightPos)
    let leftValue : Nat := Char.toNat leftChar
    let rightValue : Nat := Char.toNat rightChar
    if Nat.blt leftValue rightValue then
      -1
    else if Nat.blt rightValue leftValue then
      1
    else
      psCKernelStringCmpFrom
        left
        right
        (String.Pos.Raw.byteIdx
          (String.Internal.next left (String.Pos.Raw.mk leftPos)))
        (String.Pos.Raw.byteIdx
          (String.Internal.next right (String.Pos.Raw.mk rightPos)))

def psCKernelStringCmp (left : String) (right : String) : Int :=
  psCKernelStringCmpFrom left right 0 0

def psCKernelNameComponentListAppend
    (left : List PsCKernelNameComponent)
    (right : List PsCKernelNameComponent) : List PsCKernelNameComponent :=
  match left with
  | [] => right
  | head :: tail =>
      head :: psCKernelNameComponentListAppend tail right

def psCKernelNameComponents
    (name : PsCKernelName) : List PsCKernelNameComponent :=
  match name with
  | PsCKernelName.anonymous => []
  | PsCKernelName.str parent value =>
      psCKernelNameComponentListAppend
        (psCKernelNameComponents parent)
        [PsCKernelNameComponent.str value]
  | PsCKernelName.num parent value =>
      psCKernelNameComponentListAppend
        (psCKernelNameComponents parent)
        [PsCKernelNameComponent.num value]

def psCKernelNameComponentCmp
    (left : PsCKernelNameComponent)
    (right : PsCKernelNameComponent) : Int :=
  match left with
  | PsCKernelNameComponent.num leftValue =>
      match right with
      | PsCKernelNameComponent.str _ => -1
      | PsCKernelNameComponent.num rightValue =>
          if Nat.beq leftValue rightValue then
            0
          else if Nat.blt leftValue rightValue then
            -1
          else
            1
  | PsCKernelNameComponent.str leftValue =>
      match right with
      | PsCKernelNameComponent.num _ => 1
      | PsCKernelNameComponent.str rightValue =>
          psCKernelStringCmp leftValue rightValue

def psCKernelNameComponentListCmp
    (left : List PsCKernelNameComponent)
    (right : List PsCKernelNameComponent) : Int :=
  match left with
  | [] =>
      match right with
      | [] => 0
      | _ => -1
  | leftHead :: leftTail =>
      match right with
      | [] => 1
      | rightHead :: rightTail =>
          let headResult : Int :=
            psCKernelNameComponentCmp leftHead rightHead
          if headResult == 0 then
            psCKernelNameComponentListCmp leftTail rightTail
          else
            headResult

def psCKernelNameCmp
    (left : PsCKernelName)
    (right : PsCKernelName) : Int :=
  psCKernelNameComponentListCmp
    (psCKernelNameComponents left)
    (psCKernelNameComponents right)

def psCKernelNameToString (name : PsCKernelName) : String :=
  match name with
  | PsCKernelName.anonymous => "[anonymous]"
  | PsCKernelName.str parent value =>
      match parent with
      | PsCKernelName.anonymous => value
      | _ =>
          String.Internal.append
            (String.Internal.append (psCKernelNameToString parent) ".")
            value
  | PsCKernelName.num parent value =>
      match parent with
      | PsCKernelName.anonymous => psCKernelNatToString value
      | _ =>
          String.Internal.append
            (String.Internal.append (psCKernelNameToString parent) ".")
            (psCKernelNatToString value)
