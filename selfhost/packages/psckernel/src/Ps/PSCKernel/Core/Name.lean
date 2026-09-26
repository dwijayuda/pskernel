inductive PsCKernelName where
  | anonymous
  | str (prefix : PsCKernelName) (value : String)
  | num (prefix : PsCKernelName) (value : Nat)

inductive PsCKernelNameComponent where
  | str (value : String)
  | num (value : Nat)

def psCKernelAnonymous : PsCKernelName :=
  PsCKernelName.anonymous

def psCKernelStrName (prefix : PsCKernelName) (value : String) : PsCKernelName :=
  PsCKernelName.str prefix value

def psCKernelNumName (prefix : PsCKernelName) (value : Nat) : PsCKernelName :=
  PsCKernelName.num prefix value

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
  | PsCKernelName.str leftPrefix leftValue =>
      let comparePrefix : PsCKernelName -> Bool := psCKernelNameEq leftPrefix
      fun (right : PsCKernelName) =>
        match right with
        | PsCKernelName.str rightPrefix rightValue =>
            if comparePrefix rightPrefix then
              psCKernelStringEq leftValue rightValue
            else
              false
        | _ => false
  | PsCKernelName.num leftPrefix leftValue =>
      let comparePrefix : PsCKernelName -> Bool := psCKernelNameEq leftPrefix
      fun (right : PsCKernelName) =>
        match right with
        | PsCKernelName.num rightPrefix rightValue =>
            if comparePrefix rightPrefix then
              Nat.beq leftValue rightValue
            else
              false
        | _ => false

partial def psCKernelNameFromDottedGo
    (source : String)
    (position : Nat)
    (prefix : PsCKernelName)
    (part : String) : PsCKernelName :=
  if String.Internal.atEnd source (String.Pos.Raw.mk position) then
    if Nat.beq (String.Internal.length part) 0 then
      prefix
    else
      PsCKernelName.str prefix part
  else
    let current : Char :=
      String.Internal.get source (String.Pos.Raw.mk position)
    let nextPosition : Nat :=
      String.Pos.Raw.byteIdx
        (String.Internal.next source (String.Pos.Raw.mk position))
    if Nat.beq (Char.toNat current) 46 then
      let nextPrefix : PsCKernelName :=
        if Nat.beq (String.Internal.length part) 0 then
          prefix
        else
          PsCKernelName.str prefix part
      psCKernelNameFromDottedGo source nextPosition nextPrefix ""
    else
      psCKernelNameFromDottedGo
        source
        nextPosition
        prefix
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
  | PsCKernelName.str prefix value =>
      PsCKernelName.str prefix (String.Internal.append value suffix)
  | _ => PsCKernelName.str name suffix

def psCKernelNameAppendIndexAfter
    (name : PsCKernelName)
    (index : Nat) : PsCKernelName :=
  psCKernelNameAppendAfter
    name
    (String.Internal.append "_" (psCKernelNatToString index))

def psCKernelNameIsPrefixOf
    (prefix : PsCKernelName)
    (name : PsCKernelName) : Bool :=
  if psCKernelNameEq prefix name then
    true
  else
    match name with
    | PsCKernelName.anonymous => false
    | PsCKernelName.str parent _ =>
        psCKernelNameIsPrefixOf prefix parent
    | PsCKernelName.num parent _ =>
        psCKernelNameIsPrefixOf prefix parent

def psCKernelNameAppend
    (prefix : PsCKernelName)
    (suffix : PsCKernelName) : PsCKernelName :=
  match suffix with
  | PsCKernelName.anonymous => prefix
  | PsCKernelName.str parent value =>
      PsCKernelName.str (psCKernelNameAppend prefix parent) value
  | PsCKernelName.num parent value =>
      PsCKernelName.num (psCKernelNameAppend prefix parent) value

def psCKernelNameReplacePrefix
    (name : PsCKernelName)
    (prefix : PsCKernelName)
    (replacement : PsCKernelName) : PsCKernelName :=
  if psCKernelNameEq name prefix then
    replacement
  else
    match name with
    | PsCKernelName.anonymous => PsCKernelName.anonymous
    | PsCKernelName.str parent value =>
        PsCKernelName.str
          (psCKernelNameReplacePrefix parent prefix replacement)
          value
    | PsCKernelName.num parent value =>
        PsCKernelName.num
          (psCKernelNameReplacePrefix parent prefix replacement)
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
  | PsCKernelName.str prefix value =>
      String.Internal.append
        (psCKernelNameKey prefix)
        (String.Internal.append
          "/s:"
          (String.Internal.append
            (psCKernelNatToString (psCKernelStringUtf16Length value))
            (String.Internal.append ":" value)))
  | PsCKernelName.num prefix value =>
      String.Internal.append
        (psCKernelNameKey prefix)
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
  | PsCKernelName.str prefix value =>
      psCKernelNameComponentListAppend
        (psCKernelNameComponents prefix)
        [PsCKernelNameComponent.str value]
  | PsCKernelName.num prefix value =>
      psCKernelNameComponentListAppend
        (psCKernelNameComponents prefix)
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
  | PsCKernelName.str PsCKernelName.anonymous value => value
  | PsCKernelName.num PsCKernelName.anonymous value =>
      psCKernelNatToString value
  | PsCKernelName.str prefix value =>
      String.Internal.append
        (String.Internal.append (psCKernelNameToString prefix) ".")
        value
  | PsCKernelName.num prefix value =>
      String.Internal.append
        (String.Internal.append (psCKernelNameToString prefix) ".")
        (psCKernelNatToString value)
