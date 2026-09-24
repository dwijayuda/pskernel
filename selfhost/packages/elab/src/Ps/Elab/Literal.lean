def psDecimalDigitValue : Char -> Option Nat
  | '0' => some 0
  | '1' => some 1
  | '2' => some 2
  | '3' => some 3
  | '4' => some 4
  | '5' => some 5
  | '6' => some 6
  | '7' => some 7
  | '8' => some 8
  | '9' => some 9
  | _ => none

def psParseNaturalChars : List Char -> Nat -> Option Nat
  | [], value => some value
  | '_' :: rest, value => psParseNaturalChars rest value
  | char :: rest, value =>
      match psDecimalDigitValue char with
      | none => none
      | some digit =>
          psParseNaturalChars rest (value * 10 + digit)

def psParseNaturalText (text : String) : Option Nat :=
  psParseNaturalChars text.toList 0
