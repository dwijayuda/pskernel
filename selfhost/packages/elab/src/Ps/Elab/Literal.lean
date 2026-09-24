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

def psHexDigitValue : Char -> Option Nat
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
  | 'a' => some 10
  | 'b' => some 11
  | 'c' => some 12
  | 'd' => some 13
  | 'e' => some 14
  | 'f' => some 15
  | 'A' => some 10
  | 'B' => some 11
  | 'C' => some 12
  | 'D' => some 13
  | 'E' => some 14
  | 'F' => some 15
  | _ => none

def psReadFixedHex :
    Nat -> List Char -> Nat -> Option (Nat × List Char)
  | 0, rest, value => some (value, rest)
  | count + 1, [], _ => none
  | count + 1, char :: rest, value =>
      match psHexDigitValue char with
      | none => none
      | some digit =>
          psReadFixedHex count rest (value * 16 + digit)

def psValidUnicodeScalar (value : Nat) : Bool :=
  if value < 55296 then
    true
  else if 57343 < value then
    value < 1114112
  else
    false

def psDecodeEscapedChar
    (count : Nat)
    (rest : List Char) :
    Option (Char × List Char) :=
  match psReadFixedHex count rest 0 with
  | none => none
  | some (value, tail) =>
      if psValidUnicodeScalar value then
        some (Char.ofNat value, tail)
      else
        none

def psDecodeStringBodyWithFuel :
    Nat -> List Char -> List Char -> Option String
  | 0, _, _ => none
  | _ + 1, [], _ => none
  | _ + 1, '"' :: [], charsRev =>
      some (String.ofList charsRev.reverse)
  | _ + 1, '"' :: _ :: _, _ => none
  | fuel + 1, '\\' :: '"' :: rest, charsRev =>
      psDecodeStringBodyWithFuel fuel rest ('"' :: charsRev)
  | fuel + 1, '\\' :: '\\' :: rest, charsRev =>
      psDecodeStringBodyWithFuel fuel rest ('\\' :: charsRev)
  | fuel + 1, '\\' :: 'n' :: rest, charsRev =>
      psDecodeStringBodyWithFuel fuel rest ('\n' :: charsRev)
  | fuel + 1, '\\' :: 'r' :: rest, charsRev =>
      psDecodeStringBodyWithFuel fuel rest ('\r' :: charsRev)
  | fuel + 1, '\\' :: 't' :: rest, charsRev =>
      psDecodeStringBodyWithFuel fuel rest ('\t' :: charsRev)
  | fuel + 1, '\\' :: '0' :: rest, charsRev =>
      psDecodeStringBodyWithFuel fuel rest (Char.ofNat 0 :: charsRev)
  | fuel + 1, '\\' :: 'x' :: rest, charsRev =>
      match psDecodeEscapedChar 2 rest with
      | none => none
      | some (char, tail) =>
          psDecodeStringBodyWithFuel fuel tail (char :: charsRev)
  | fuel + 1, '\\' :: 'u' :: rest, charsRev =>
      match psDecodeEscapedChar 4 rest with
      | none => none
      | some (char, tail) =>
          psDecodeStringBodyWithFuel fuel tail (char :: charsRev)
  | _ + 1, '\\' :: _ :: _, _ => none
  | fuel + 1, char :: rest, charsRev =>
      psDecodeStringBodyWithFuel fuel rest (char :: charsRev)

def psDecodeStringLiteral (text : String) : Option String :=
  match text.toList with
  | '"' :: rest =>
      psDecodeStringBodyWithFuel (rest.length + 1) rest []
  | _ => none
