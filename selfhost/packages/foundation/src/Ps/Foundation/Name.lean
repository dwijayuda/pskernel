inductive PsName where
  | anonymous
  | str (parent : PsName) (value : String)
  | num (parent : PsName) (value : Nat)

def psNameDepth (name : PsName) : Nat :=
  match name with
  | PsName.anonymous => 0
  | PsName.str parent _ => Nat.add (psNameDepth parent) 1
  | PsName.num parent _ => Nat.add (psNameDepth parent) 1

partial def psStringEqFrom
    (left : String)
    (right : String)
    (leftPos : Nat)
    (rightPos : Nat) : Bool :=
  if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
    String.Internal.atEnd right (String.Pos.Raw.mk rightPos)
  else if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
    false
  else
    let leftChar : Char := String.Internal.get left (String.Pos.Raw.mk leftPos);
    let rightChar : Char := String.Internal.get right (String.Pos.Raw.mk rightPos);
    if Nat.beq (Char.toNat leftChar) (Char.toNat rightChar) then
      psStringEqFrom
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

def psStringEq (left : String) (right : String) : Bool :=
  psStringEqFrom left right 0 0

partial def psNatToString (value : Nat) : String :=
  if Nat.blt value 10 then
    String.singleton (Char.ofNat (Nat.add 48 value))
  else
    String.Internal.append
      (psNatToString (Nat.div value 10))
      (String.singleton
        (Char.ofNat
          (Nat.add 48 (Nat.mod value 10))))

partial def psNameEq (left : PsName) : PsName -> Bool :=
  match left with
  | PsName.anonymous =>
      fun (right : PsName) =>
        match right with
        | PsName.anonymous => true
        | _ => false
  | PsName.str leftPrefix leftValue =>
      let smaller : PsName -> Bool := psNameEq leftPrefix;
      fun (right : PsName) =>
        match right with
        | PsName.str rightPrefix rightValue =>
            if smaller rightPrefix then
              psStringEq leftValue rightValue
            else
              false
        | _ => false
  | PsName.num leftPrefix leftValue =>
      let smaller : PsName -> Bool := psNameEq leftPrefix;
      fun (right : PsName) =>
        match right with
        | PsName.num rightPrefix rightValue =>
            if smaller rightPrefix then
              Nat.beq leftValue rightValue
            else
              false
        | _ => false

def psNameAppendStr (parent : PsName) (value : String) : PsName :=
  PsName.str parent value

def psNameAppendNum (parent : PsName) (value : Nat) : PsName :=
  PsName.num parent value

def psNameToString (name : PsName) : String :=
  match name with
  | PsName.anonymous => ""
  | PsName.str parent value =>
      let prefixText : String := psNameToString parent;
      if Nat.beq (String.Internal.length prefixText) 0 then
        value
      else
        String.Internal.append
          (String.Internal.append prefixText ".")
          value
  | PsName.num parent value =>
      let prefixText : String := psNameToString parent;
      let suffix : String := psNatToString value;
      if Nat.beq (String.Internal.length prefixText) 0 then
        suffix
      else
        String.Internal.append
          (String.Internal.append prefixText ".")
          suffix

def psNameLastComponent (name : PsName) : String :=
  match name with
  | PsName.anonymous => ""
  | PsName.str _ value => value
  | PsName.num _ value => psNatToString value
