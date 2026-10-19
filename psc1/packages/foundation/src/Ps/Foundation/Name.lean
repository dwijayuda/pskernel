inductive PsName where
  | anonymous
  | str (parent : PsName) (value : String)
  | num (parent : PsName) (value : Nat)

def psNameDepth (name : PsName) : Nat :=
  match name with
  | PsName.anonymous => 0
  | PsName.str parent _ => Nat.add (psNameDepth parent) 1
  | PsName.num parent _ => Nat.add (psNameDepth parent) 1

def psStringEqFromWithFuel (fuel : Nat) : String -> String -> Nat -> Nat -> Bool :=
  match fuel with
  | Nat.zero => fun (_left : String) (_right : String) (_leftPos : Nat) (_rightPos : Nat) => false
  | Nat.succ remaining =>
      fun (left : String) (right : String) (leftPos : Nat) (rightPos : Nat) =>
        let smaller : String -> String -> Nat -> Nat -> Bool := psStringEqFromWithFuel remaining;
        if String.Internal.atEnd left (String.Pos.Raw.mk leftPos) then
          String.Internal.atEnd right (String.Pos.Raw.mk rightPos)
        else if String.Internal.atEnd right (String.Pos.Raw.mk rightPos) then
          false
        else
          let leftChar : Char := String.Internal.get left (String.Pos.Raw.mk leftPos);
          let rightChar : Char := String.Internal.get right (String.Pos.Raw.mk rightPos);
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

def psStringEqFrom
    (left : String) (right : String) (leftPos : Nat) (rightPos : Nat) : Bool :=
  psStringEqFromWithFuel (Nat.succ (String.utf8ByteSize left)) left right leftPos rightPos

def psStringEq (left : String) (right : String) : Bool :=
  if Nat.beq (String.utf8ByteSize left) (String.utf8ByteSize right) then
    psStringEqFrom left right 0 0
  else false

def psNatToString (value : Nat) : String :=
  Int.repr (Int.ofNat value)

def psNameEq (left : PsName) : PsName -> Bool :=
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
