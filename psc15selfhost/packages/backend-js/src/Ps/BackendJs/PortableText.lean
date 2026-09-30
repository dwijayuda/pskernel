def psJsTextConcat2
    (left right : String) : String :=
  String.Internal.append left right


def psJsTextConcat3
    (first second third : String) : String :=
  psJsTextConcat2 first (psJsTextConcat2 second third)


def psJsTextCharCode (char : Char) : Nat :=
  Char.toNat char


def psJsTextCharEq (left right : Char) : Bool :=
  Nat.beq (psJsTextCharCode left) (psJsTextCharCode right)


def psJsTextStringAtEnd
    (value : String)
    (position : Nat) : Bool :=
  String.Internal.atEnd value (String.Pos.Raw.mk position)


def psJsTextStringGet
    (value : String)
    (position : Nat) : Char :=
  String.Internal.get value (String.Pos.Raw.mk position)


def psJsTextStringNext
    (value : String)
    (position : Nat) : Nat :=
  String.Pos.Raw.byteIdx
    (String.Internal.next value (String.Pos.Raw.mk position))


def psJsTextStringCharsWithFuel
    (fuel : Nat) : String -> Nat -> List Char :=
  match fuel with
  | Nat.zero =>
      fun (_value : String) =>
        fun (_position : Nat) =>
          List.nil
  | Nat.succ remaining =>
      let smaller : String -> Nat -> List Char :=
        psJsTextStringCharsWithFuel remaining;
      fun (value : String) =>
        fun (position : Nat) =>
          if psJsTextStringAtEnd value position then
            List.nil
          else
            List.cons
              (psJsTextStringGet value position)
              (smaller value (psJsTextStringNext value position))


def psJsTextStringToChars (value : String) : List Char :=
  psJsTextStringCharsWithFuel
    (Nat.succ (String.utf8ByteSize value))
    value
    0


def psJsTextStringOfChars (chars : List Char) : String :=
  match chars with
  | List.nil =>
      ""
  | List.cons head tail =>
      psJsTextConcat2
        (String.push "" head)
        (psJsTextStringOfChars tail)


def psJsTextCharListEqWithFuel (fuel : Nat) :
    List Char -> List Char -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_left : List Char) =>
        fun (_right : List Char) => false
  | Nat.succ remaining =>
      let smaller : List Char -> List Char -> Bool :=
        psJsTextCharListEqWithFuel remaining;
      fun (left : List Char) =>
        fun (right : List Char) =>
          match left with
          | List.nil =>
              match right with
              | List.nil => true
              | List.cons _rightHead _rightTail => false
          | List.cons leftHead leftTail =>
              match right with
              | List.nil => false
              | List.cons rightHead rightTail =>
                  if psJsTextCharEq leftHead rightHead then
                    smaller leftTail rightTail
                  else
                    false


def psJsTextStringEq (left right : String) : Bool :=
  psJsTextCharListEqWithFuel
    (Nat.succ (String.utf8ByteSize left))
    (psJsTextStringToChars left)
    (psJsTextStringToChars right)


def psJsTextNatInRange
    (value lower upper : Nat) : Bool :=
  if Nat.ble lower value then
    Nat.ble value upper
  else
    false


def psJsTextHexDigit (value : Nat) : String :=
  if Nat.beq value 0 then "0"
  else if Nat.beq value 1 then "1"
  else if Nat.beq value 2 then "2"
  else if Nat.beq value 3 then "3"
  else if Nat.beq value 4 then "4"
  else if Nat.beq value 5 then "5"
  else if Nat.beq value 6 then "6"
  else if Nat.beq value 7 then "7"
  else if Nat.beq value 8 then "8"
  else if Nat.beq value 9 then "9"
  else if Nat.beq value 10 then "a"
  else if Nat.beq value 11 then "b"
  else if Nat.beq value 12 then "c"
  else if Nat.beq value 13 then "d"
  else if Nat.beq value 14 then "e"
  else "f"


def psJsTextEscapeControl (value : Nat) : String :=
  psJsTextConcat3
    "\\u00"
    (psJsTextHexDigit (Nat.div value 16))
    (psJsTextHexDigit (Nat.mod value 16))


def psJsTextEscapeChar (char : Char) : String :=
  let value : Nat := Char.toNat char;
  if Nat.beq value 8 then
    "\\b"
  else if Nat.beq value 9 then
    "\\t"
  else if Nat.beq value 10 then
    "\\n"
  else if Nat.beq value 12 then
    "\\f"
  else if Nat.beq value 13 then
    "\\r"
  else if Nat.beq value 34 then
    "\\\""
  else if Nat.beq value 92 then
    "\\\\"
  else if Nat.blt value 32 then
    psJsTextEscapeControl value
  else
    psJsTextStringOfChars (List.cons char List.nil)


def psJsTextEscapeChars (chars : List Char) : String :=
  match chars with
  | List.nil =>
      ""
  | List.cons char rest =>
      psJsTextConcat2
        (psJsTextEscapeChar char)
        (psJsTextEscapeChars rest)


def psJsTextQuote (value : String) : String :=
  psJsTextConcat3
    "\""
    (psJsTextEscapeChars (psJsTextStringToChars value))
    "\""
