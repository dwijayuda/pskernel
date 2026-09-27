def psCharCodeEq (char : Char) (code : Nat) : Bool :=
  Nat.beq (Char.toNat char) code

def psDecimalDigitValue (char : Char) : Option Nat :=
  if psCharCodeEq char 48 then
    Option.some 0
  else if psCharCodeEq char 49 then
    Option.some 1
  else if psCharCodeEq char 50 then
    Option.some 2
  else if psCharCodeEq char 51 then
    Option.some 3
  else if psCharCodeEq char 52 then
    Option.some 4
  else if psCharCodeEq char 53 then
    Option.some 5
  else if psCharCodeEq char 54 then
    Option.some 6
  else if psCharCodeEq char 55 then
    Option.some 7
  else if psCharCodeEq char 56 then
    Option.some 8
  else if psCharCodeEq char 57 then
    Option.some 9
  else
    Option.none

def psParseNaturalChars
    (chars : List Char)
    (value : Nat) : Option Nat :=
  match chars with
  | [] =>
      Option.some value
  | char :: rest =>
      if psCharCodeEq char 95 then
        psParseNaturalChars rest value
      else
        match psDecimalDigitValue char with
        | Option.none =>
            Option.none
        | Option.some digit =>
            psParseNaturalChars rest (value * 10 + digit)

def psParseNaturalText (text : String) : Option Nat :=
  psParseNaturalChars (String.toList text) 0

def psHexDigitValue (char : Char) : Option Nat :=
  if psCharCodeEq char 48 then
    Option.some 0
  else if psCharCodeEq char 49 then
    Option.some 1
  else if psCharCodeEq char 50 then
    Option.some 2
  else if psCharCodeEq char 51 then
    Option.some 3
  else if psCharCodeEq char 52 then
    Option.some 4
  else if psCharCodeEq char 53 then
    Option.some 5
  else if psCharCodeEq char 54 then
    Option.some 6
  else if psCharCodeEq char 55 then
    Option.some 7
  else if psCharCodeEq char 56 then
    Option.some 8
  else if psCharCodeEq char 57 then
    Option.some 9
  else if psCharCodeEq char 97 then
    Option.some 10
  else if psCharCodeEq char 98 then
    Option.some 11
  else if psCharCodeEq char 99 then
    Option.some 12
  else if psCharCodeEq char 100 then
    Option.some 13
  else if psCharCodeEq char 101 then
    Option.some 14
  else if psCharCodeEq char 102 then
    Option.some 15
  else if psCharCodeEq char 65 then
    Option.some 10
  else if psCharCodeEq char 66 then
    Option.some 11
  else if psCharCodeEq char 67 then
    Option.some 12
  else if psCharCodeEq char 68 then
    Option.some 13
  else if psCharCodeEq char 69 then
    Option.some 14
  else if psCharCodeEq char 70 then
    Option.some 15
  else
    Option.none

def psReadFixedHex
    (count : Nat)
    (chars : List Char)
    (value : Nat) :
    Option (Prod Nat (List Char)) :=
  match count with
  | 0 =>
      Option.some (Prod.mk value chars)
  | nextCount + 1 =>
      match chars with
      | [] =>
          Option.none
      | char :: rest =>
          match psHexDigitValue char with
          | Option.none =>
              Option.none
          | Option.some digit =>
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
  | Option.none =>
      Option.none
  | Option.some decoded =>
      let value := Prod.fst decoded;
      let tail := Prod.snd decoded;
      if psValidUnicodeScalar value then
        Option.some (Prod.mk (Char.ofNat value) tail)
      else
        Option.none

def psDecodeStringBodyWithFuel
    (fuel : Nat)
    (chars : List Char)
    (charsRev : List Char) :
    Option String :=
  match fuel with
  | 0 =>
      Option.none
  | nextFuel + 1 =>
      match chars with
      | [] =>
          Option.none
      | char :: restAfterChar =>
          if psCharCodeEq char 34 then
            match restAfterChar with
            | [] =>
                Option.some (String.ofList (List.reverse charsRev))
            | _ :: _ =>
                Option.none
          else if psCharCodeEq char 92 then
            match restAfterChar with
            | [] =>
                Option.none
            | escaped :: rest =>
                if psCharCodeEq escaped 34 then
                  psDecodeStringBodyWithFuel
                    nextFuel
                    rest
                    (Char.ofNat 34 :: charsRev)
                else if psCharCodeEq escaped 92 then
                  psDecodeStringBodyWithFuel
                    nextFuel
                    rest
                    (Char.ofNat 92 :: charsRev)
                else if psCharCodeEq escaped 110 then
                  psDecodeStringBodyWithFuel
                    nextFuel
                    rest
                    (Char.ofNat 10 :: charsRev)
                else if psCharCodeEq escaped 114 then
                  psDecodeStringBodyWithFuel
                    nextFuel
                    rest
                    (Char.ofNat 13 :: charsRev)
                else if psCharCodeEq escaped 116 then
                  psDecodeStringBodyWithFuel
                    nextFuel
                    rest
                    (Char.ofNat 9 :: charsRev)
                else if psCharCodeEq escaped 48 then
                  psDecodeStringBodyWithFuel
                    nextFuel
                    rest
                    (Char.ofNat 0 :: charsRev)
                else if psCharCodeEq escaped 120 then
                  match psDecodeEscapedChar 2 rest with
                  | Option.none =>
                      Option.none
                  | Option.some decoded =>
                      psDecodeStringBodyWithFuel
                        nextFuel
                        (Prod.snd decoded)
                        (Prod.fst decoded :: charsRev)
                else if psCharCodeEq escaped 117 then
                  match psDecodeEscapedChar 4 rest with
                  | Option.none =>
                      Option.none
                  | Option.some decoded =>
                      psDecodeStringBodyWithFuel
                        nextFuel
                        (Prod.snd decoded)
                        (Prod.fst decoded :: charsRev)
                else
                  Option.none
          else
            psDecodeStringBodyWithFuel
              nextFuel
              restAfterChar
              (char :: charsRev)

def psDecodeStringLiteral (text : String) : Option String :=
  match String.toList text with
  | [] =>
      Option.none
  | first :: rest =>
      if psCharCodeEq first 34 then
        psDecodeStringBodyWithFuel
          (Nat.succ (List.length rest))
          rest
          []
      else
        Option.none

def psDecodeCharacterEscape
    (escaped : Char) : Option Char :=
  if psCharCodeEq escaped 39 then
    Option.some (Char.ofNat 39)
  else if psCharCodeEq escaped 34 then
    Option.some (Char.ofNat 34)
  else if psCharCodeEq escaped 92 then
    Option.some (Char.ofNat 92)
  else if psCharCodeEq escaped 110 then
    Option.some (Char.ofNat 10)
  else if psCharCodeEq escaped 114 then
    Option.some (Char.ofNat 13)
  else if psCharCodeEq escaped 116 then
    Option.some (Char.ofNat 9)
  else
    Option.none

def psDecodeCharacterEscapedTail
    (decoded : Option (Prod Char (List Char))) :
    Option Char :=
  match decoded with
  | Option.none =>
      Option.none
  | Option.some pair =>
      match Prod.snd pair with
      | [] =>
          Option.none
      | closing :: rest =>
          match rest with
          | [] =>
              if psCharCodeEq closing 39 then
                Option.some (Prod.fst pair)
              else
                Option.none
          | _ :: _ =>
              Option.none

def psDecodeCharacterLiteral (text : String) : Option Char :=
  match String.toList text with
  | [] =>
      Option.none
  | opening :: rest =>
      if psCharCodeEq opening 39 then
        match rest with
        | [] =>
            Option.none
        | value :: tail =>
            if psCharCodeEq value 92 then
              match tail with
              | [] =>
                  Option.none
              | escaped :: escapedTail =>
                  if psCharCodeEq escaped 120 then
                    psDecodeCharacterEscapedTail
                      (psDecodeEscapedChar 2 escapedTail)
                  else if psCharCodeEq escaped 117 then
                    psDecodeCharacterEscapedTail
                      (psDecodeEscapedChar 4 escapedTail)
                  else
                    match escapedTail with
                    | [] =>
                        Option.none
                    | closing :: afterClosing =>
                        match afterClosing with
                        | [] =>
                            if psCharCodeEq closing 39 then
                              psDecodeCharacterEscape escaped
                            else
                              Option.none
                        | _ :: _ =>
                            Option.none
            else
              match tail with
              | [] =>
                  Option.none
              | closing :: afterClosing =>
                  match afterClosing with
                  | [] =>
                      if psCharCodeEq closing 39 then
                        Option.some value
                      else
                        Option.none
                  | _ :: _ =>
                      Option.none
      else
        Option.none
