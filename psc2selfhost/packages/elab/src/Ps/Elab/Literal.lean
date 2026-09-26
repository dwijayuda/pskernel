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

def psParseNaturalChars
    (chars : List Char)
    (value : Nat) : Option Nat :=
  match chars with
  | [] =>
      some value
  | '_' :: rest =>
      psParseNaturalChars rest value
  | char :: rest =>
      match psDecimalDigitValue char with
      | none =>
          none
      | some digit =>
          psParseNaturalChars rest (value * 10 + digit)

def psParseNaturalText (text : String) : Option Nat :=
  psParseNaturalChars (String.toList text) 0

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

def psReadFixedHex
    (count : Nat)
    (chars : List Char)
    (value : Nat) :
    Option (Prod Nat (List Char)) :=
  match count with
  | 0 =>
      some (Prod.mk value chars)
  | nextCount + 1 =>
      match chars with
      | [] =>
          none
      | char :: rest =>
          match psHexDigitValue char with
          | none =>
              none
          | some digit =>
              psReadFixedHex
                nextCount
                rest
                (value * 16 + digit)

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
    Option (Prod Char (List Char)) :=
  match psReadFixedHex count rest 0 with
  | none =>
      none
  | some decoded =>
      let value := Prod.fst decoded;
      let tail := Prod.snd decoded;
      if psValidUnicodeScalar value then
        some (Prod.mk (Char.ofNat value) tail)
      else
        none

def psDecodeStringBodyWithFuel
    (fuel : Nat)
    (chars : List Char)
    (charsRev : List Char) :
    Option String :=
  match fuel with
  | 0 =>
      none
  | nextFuel + 1 =>
      match chars with
      | [] =>
          none
      | '"' :: restAfterQuote =>
          match restAfterQuote with
          | [] =>
              some (String.ofList (List.reverse charsRev))
          | _ :: _ =>
              none
      | '\\' :: restAfterSlash =>
          match restAfterSlash with
          | [] =>
              none
          | '"' :: rest =>
              psDecodeStringBodyWithFuel
                nextFuel
                rest
                ('"' :: charsRev)
          | '\\' :: rest =>
              psDecodeStringBodyWithFuel
                nextFuel
                rest
                ('\\' :: charsRev)
          | 'n' :: rest =>
              psDecodeStringBodyWithFuel
                nextFuel
                rest
                ('\n' :: charsRev)
          | 'r' :: rest =>
              psDecodeStringBodyWithFuel
                nextFuel
                rest
                ('\r' :: charsRev)
          | 't' :: rest =>
              psDecodeStringBodyWithFuel
                nextFuel
                rest
                ('\t' :: charsRev)
          | '0' :: rest =>
              psDecodeStringBodyWithFuel
                nextFuel
                rest
                (Char.ofNat 0 :: charsRev)
          | 'x' :: rest =>
              match psDecodeEscapedChar 2 rest with
              | none =>
                  none
              | some decoded =>
                  psDecodeStringBodyWithFuel
                    nextFuel
                    (Prod.snd decoded)
                    (Prod.fst decoded :: charsRev)
          | 'u' :: rest =>
              match psDecodeEscapedChar 4 rest with
              | none =>
                  none
              | some decoded =>
                  psDecodeStringBodyWithFuel
                    nextFuel
                    (Prod.snd decoded)
                    (Prod.fst decoded :: charsRev)
          | _ :: _ =>
              none
      | char :: rest =>
          psDecodeStringBodyWithFuel
            nextFuel
            rest
            (char :: charsRev)

def psDecodeStringLiteral (text : String) : Option String :=
  match String.toList text with
  | '"' :: rest =>
      psDecodeStringBodyWithFuel
        (Nat.succ (List.length rest))
        rest
        []
  | _ =>
      none

def psDecodeCharacterEscape
    (escaped : Char) : Option Char :=
  match escaped with
  | '\'' => some '\''
  | '"' => some '"'
  | '\\' => some '\\'
  | 'n' => some '\n'
  | 'r' => some '\r'
  | 't' => some '\t'
  | _ => none

def psDecodeCharacterEscapedTail
    (decoded : Option (Prod Char (List Char))) :
    Option Char :=
  match decoded with
  | none =>
      none
  | some pair =>
      match Prod.snd pair with
      | '\'' :: [] =>
          some (Prod.fst pair)
      | _ =>
          none

def psDecodeCharacterLiteral (text : String) : Option Char :=
  match String.toList text with
  | '\'' :: char :: '\'' :: [] =>
      some char
  | '\'' :: '\\' :: escaped :: '\'' :: [] =>
      psDecodeCharacterEscape escaped
  | '\'' :: '\\' :: 'x' :: rest =>
      psDecodeCharacterEscapedTail
        (psDecodeEscapedChar 2 rest)
  | '\'' :: '\\' :: 'u' :: rest =>
      psDecodeCharacterEscapedTail
        (psDecodeEscapedChar 4 rest)
  | _ =>
      none
