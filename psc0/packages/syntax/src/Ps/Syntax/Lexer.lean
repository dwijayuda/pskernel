import Ps.Syntax.Cursor
import Ps.Syntax.Token

inductive PsLexError where
  | unterminatedBlockComment (span : PsSourceSpan)
  | unterminatedString (span : PsSourceSpan)
  | newlineInString (span : PsSourceSpan)
  | unterminatedCharacter (span : PsSourceSpan)
  | fuelExhausted
  | invalidSource (reason : String) (span : PsSourceSpan)

structure PsLexRead where
  cursor : PsLexCursor
  charsRev : List Char

def psLexSpan (start : PsSourcePos) (stop : PsSourcePos) : PsSourceSpan :=
  { start := start, stop := stop }

def psLexString (charsRev : List Char) : String :=
  match charsRev with
  | List.nil => ""
  | List.cons char rest =>
      String.push (psLexString rest) char

def psLexAdvanceChar (position : PsSourcePos) (char : Char) : PsSourcePos :=
  psLexAdvancePosition position char

def psLexAdvanceTwo
    (position : PsSourcePos)
    (first : Char)
    (second : Char) : PsSourcePos :=
  psLexAdvanceChar (psLexAdvanceChar position first) second


def psLexListLength {α : Type} (xs : List α) : Nat :=
  match xs with
  | List.nil => 0
  | List.cons _ tail =>
      Nat.add 1 (psLexListLength tail)

def psLexCharEq (left : Char) (right : Char) : Bool :=
  Nat.beq (Char.toNat left) (Char.toNat right)

def psLexNatBetween (lower value upper : Nat) : Bool :=
  if Nat.ble lower value then
    Nat.ble value upper
  else
    false

def psLexWhitespace (char : Char) : Bool :=
  if psLexCharEq char ' ' then
    true
  else if psLexCharEq char '\t' then
    true
  else if psLexCharEq char '\r' then
    true
  else
    psLexCharEq char '\n'

def psLexSkipLineComment
    (remaining : List Char) :
    PsSourcePos -> PsLexCursor :=
  match remaining with
  | List.nil =>
      fun (position : PsSourcePos) =>
        { remaining := List.nil, position := position }
  | List.cons char rest =>
      fun (position : PsSourcePos) =>
        let smaller : PsSourcePos -> PsLexCursor :=
          psLexSkipLineComment rest;
        if psLexCharEq char '\n' then
          {
            remaining := List.cons char rest
            position := position
          }
        else
          smaller
            (psLexAdvanceChar position char)

def psLexSkipBlockCommentWithFuel
    (fuel : Nat) :
    Nat ->
    List Char ->
    PsSourcePos ->
    PsSourcePos ->
    Except PsLexError PsLexCursor :=
  match fuel with
  | 0 =>
      fun (depth : Nat) (remaining : List Char) (start : PsSourcePos) (position : PsSourcePos) =>
        Except.error
          (PsLexError.unterminatedBlockComment
            (psLexSpan start position))
  | remainingFuel + 1 =>
      fun (depth : Nat) (remaining : List Char) (start : PsSourcePos) (position : PsSourcePos) =>
        let smaller :
            Nat ->
            List Char ->
            PsSourcePos ->
            PsSourcePos ->
            Except PsLexError PsLexCursor :=
          psLexSkipBlockCommentWithFuel remainingFuel;
        match remaining with
        | List.nil =>
            Except.error
              (PsLexError.unterminatedBlockComment
                (psLexSpan start position))
        | List.cons first rest =>
            match rest with
            | List.nil =>
                smaller
                  depth
                  List.nil
                  start
                  (psLexAdvanceChar position first)
            | List.cons second tail =>
                if psLexCharEq first '/' then
                  if psLexCharEq second '-' then
                    smaller
                      (Nat.add depth 1)
                      tail
                      start
                      (psLexAdvanceTwo position first second)
                  else
                    smaller
                      depth
                      rest
                      start
                      (psLexAdvanceChar position first)
                else if psLexCharEq first '-' then
                  if psLexCharEq second '/' then
                    if Nat.beq depth 1 then
                      Except.ok {
                        remaining := tail
                        position :=
                          psLexAdvanceTwo position first second
                      }
                    else
                      smaller
                        (Nat.sub depth 1)
                        tail
                        start
                        (psLexAdvanceTwo position first second)
                  else
                    smaller
                      depth
                      rest
                      start
                      (psLexAdvanceChar position first)
                else
                  smaller
                    depth
                    rest
                    start
                    (psLexAdvanceChar position first)

def psLexSkipBlockComment
    (depth : Nat)
    (remaining : List Char)
    (start : PsSourcePos)
    (position : PsSourcePos) :
    Except PsLexError PsLexCursor :=
  psLexSkipBlockCommentWithFuel
    (Nat.add (psLexListLength remaining) 1)
    depth
    remaining
    start
    position

def psLexSkipTriviaWithFuel
    (fuel : Nat) :
    List Char ->
    PsSourcePos ->
    Except PsLexError PsLexCursor :=
  match fuel with
  | 0 =>
      fun (remaining : List Char) (position : PsSourcePos) =>
        Except.ok {
          remaining := remaining
          position := position
        }
  | remainingFuel + 1 =>
      fun (remaining : List Char) (position : PsSourcePos) =>
        let smaller :
            List Char ->
            PsSourcePos ->
            Except PsLexError PsLexCursor :=
          psLexSkipTriviaWithFuel remainingFuel;
        match remaining with
        | List.nil =>
            Except.ok {
              remaining := List.nil
              position := position
            }
        | List.cons first rest =>
            match rest with
            | List.cons second tail =>
                if psLexCharEq first '-' then
                  if psLexCharEq second '-' then
                    let afterPrefix :=
                      psLexAdvanceTwo position first second;
                    let cursor :=
                      psLexSkipLineComment tail afterPrefix;
                    smaller
                      cursor.remaining
                      cursor.position
                  else if psLexWhitespace first then
                    smaller
                      rest
                      (psLexAdvanceChar position first)
                  else
                    Except.ok {
                      remaining := List.cons first rest
                      position := position
                    }
                else if psLexCharEq first '/' then
                  if psLexCharEq second '-' then
                    let afterPrefix :=
                      psLexAdvanceTwo position first second;
                    match
                        psLexSkipBlockComment
                          1
                          tail
                          position
                          afterPrefix with
                    | Except.error error => Except.error error
                    | Except.ok cursor =>
                        smaller
                          cursor.remaining
                          cursor.position
                  else if psLexWhitespace first then
                    smaller
                      rest
                      (psLexAdvanceChar position first)
                  else
                    Except.ok {
                      remaining := List.cons first rest
                      position := position
                    }
                else if psLexWhitespace first then
                  smaller
                    rest
                    (psLexAdvanceChar position first)
                else
                  Except.ok {
                    remaining := List.cons first rest
                    position := position
                  }
            | List.nil =>
                if psLexWhitespace first then
                  smaller
                    List.nil
                    (psLexAdvanceChar position first)
                else
                  Except.ok {
                    remaining := List.cons first List.nil
                    position := position
                  }

def psLexSkipTrivia
    (remaining : List Char)
    (position : PsSourcePos) : Except PsLexError PsLexCursor :=
  psLexSkipTriviaWithFuel (Nat.add (psLexListLength remaining) 1) remaining position

def psLexLetterLike (char : Char) : Bool :=
  let code : Nat := Char.toNat char;
  if psLexNatBetween 945 code 969 then
    if Nat.beq code 955 then false else true
  else if psLexNatBetween 913 code 937 then
    if Nat.beq code 928 then
      false
    else if Nat.beq code 931 then
      false
    else
      true
  else if psLexNatBetween 970 code 1019 then
    true
  else if psLexNatBetween 7936 code 8190 then
    true
  else if psLexNatBetween 8448 code 8527 then
    true
  else if psLexNatBetween 119964 code 120223 then
    true
  else if psLexNatBetween 192 code 255 then
    if Nat.beq code 215 then
      false
    else if Nat.beq code 247 then
      false
    else
      true
  else
    psLexNatBetween 256 code 383

def psLexNumericSubscript (char : Char) : Bool :=
  psLexNatBetween 8320 (Char.toNat char) 8329

def psLexSubscriptAlnum (char : Char) : Bool :=
  let code : Nat := Char.toNat char;
  if psLexNumericSubscript char then
    true
  else if psLexNatBetween 8336 code 8348 then
    true
  else if psLexNatBetween 7522 code 7530 then
    true
  else
    Nat.beq code 11388

def psLexAsciiAlpha (char : Char) : Bool :=
  let code : Nat := Char.toNat char;
  if psLexNatBetween 65 code 90 then
    true
  else
    psLexNatBetween 97 code 122

def psLexDigit (char : Char) : Bool :=
  psLexNatBetween 48 (Char.toNat char) 57

def psLexIdentifierStart (char : Char) : Bool :=
  if psLexAsciiAlpha char then
    true
  else if psLexCharEq char '_' then
    true
  else
    psLexLetterLike char

def psLexIdentifierContinue (char : Char) : Bool :=
  if psLexAsciiAlpha char then
    true
  else if psLexDigit char then
    true
  else if psLexCharEq char '_' then
    true
  else if psLexCharEq char '\'' then
    true
  else if psLexCharEq char '!' then
    true
  else if psLexCharEq char '?' then
    true
  else if psLexLetterLike char then
    true
  else
    psLexSubscriptAlnum char

def psLexNaturalContinue (char : Char) : Bool :=
  if psLexDigit char then
    true
  else
    psLexCharEq char '_'

def psLexReadIdentifier
    (remaining : List Char) :
    PsSourcePos -> List Char -> PsLexRead :=
  match remaining with
  | List.nil =>
      fun (position : PsSourcePos) (charsRev : List Char) =>
        {
          cursor := { remaining := List.nil, position := position }
          charsRev := charsRev
        }
  | List.cons char rest =>
      fun (position : PsSourcePos) (charsRev : List Char) =>
        let smaller : PsSourcePos -> List Char -> PsLexRead :=
          psLexReadIdentifier rest;
        if psLexIdentifierContinue char then
          smaller
            (psLexAdvanceChar position char)
            (List.cons char charsRev)
        else
          {
            cursor := { remaining := List.cons char rest, position := position }
            charsRev := charsRev
          }

def psLexReadNatural
    (remaining : List Char) :
    PsSourcePos -> List Char -> PsLexRead :=
  match remaining with
  | List.nil =>
      fun (position : PsSourcePos) (charsRev : List Char) =>
        {
          cursor := { remaining := List.nil, position := position }
          charsRev := charsRev
        }
  | List.cons char rest =>
      fun (position : PsSourcePos) (charsRev : List Char) =>
        let smaller : PsSourcePos -> List Char -> PsLexRead :=
          psLexReadNatural rest;
        if psLexNaturalContinue char then
          smaller
            (psLexAdvanceChar position char)
            (List.cons char charsRev)
        else
          {
            cursor := { remaining := List.cons char rest, position := position }
            charsRev := charsRev
          }

-- RC4 numeric lexing supports binary/octal/hexadecimal and internal
-- separators. The reader intentionally does not interpret numeric values.
def psLexRadixBase (char : Char) : Option Nat :=
  if psLexCharEq char 'b' || psLexCharEq char 'B' then some 2
  else if psLexCharEq char 'o' || psLexCharEq char 'O' then some 8
  else if psLexCharEq char 'x' || psLexCharEq char 'X' then some 16
  else none

def psLexRadixDigit (base : Nat) (char : Char) : Bool :=
  let code := Char.toNat char
  if psLexCharEq char '_' then true
  else if base == 2 then psLexNatBetween 48 code 49
  else if base == 8 then psLexNatBetween 48 code 55
  else if base == 16 then psLexDigit char ||
    psLexNatBetween 65 code 70 || psLexNatBetween 97 code 102
  else psLexDigit char

def psLexReadRadixDigits (base : Nat) (remaining : List Char)
    (position : PsSourcePos) (charsRev : List Char) : PsLexRead :=
  match remaining with
  | [] => { cursor := { remaining := [], position }, charsRev }
  | char :: rest =>
    if psLexRadixDigit base char then
      psLexReadRadixDigits base rest (psLexAdvanceChar position char)
        (char :: charsRev)
    else
      { cursor := { remaining := char :: rest, position }, charsRev }

def psLexReadNumeral (first : Char) (remaining : List Char)
    (start : PsSourcePos) : PsLexRead :=
  let firstPosition := psLexAdvanceChar start first
  if !psLexCharEq first '0' then
    psLexReadNatural remaining firstPosition [first]
  else
    match remaining with
    | [] => psLexReadNatural remaining firstPosition [first]
    | radix :: rest =>
      match psLexRadixBase radix with
      | none => psLexReadNatural remaining firstPosition [first]
      | some base =>
        psLexReadRadixDigits base rest (psLexAdvanceChar firstPosition radix)
          [radix, first]

def psLexReadStringBodyWithFuel
    (fuel : Nat) :
    List Char ->
    PsSourcePos ->
    PsSourcePos ->
    List Char ->
    Except PsLexError PsLexRead :=
  match fuel with
  | 0 =>
      fun (remaining : List Char) (position : PsSourcePos) (start : PsSourcePos) (charsRev : List Char) =>
        Except.error
          (PsLexError.unterminatedString
            (psLexSpan start position))
  | remainingFuel + 1 =>
      fun (remaining : List Char) (position : PsSourcePos) (start : PsSourcePos) (charsRev : List Char) =>
        let smaller :
            List Char ->
            PsSourcePos ->
            PsSourcePos ->
            List Char ->
            Except PsLexError PsLexRead :=
          psLexReadStringBodyWithFuel remainingFuel;
        match remaining with
        | List.nil =>
            Except.error
              (PsLexError.unterminatedString
                (psLexSpan start position))
        | List.cons char rest =>
            if psLexCharEq char '"' then
              let stop := psLexAdvanceChar position char;
              Except.ok {
                cursor := {
                  remaining := rest
                  position := stop
                }
                charsRev := List.cons char charsRev
              }
            else if psLexCharEq char '\n' then
              Except.error
                (PsLexError.newlineInString
                  (psLexSpan start position))
            else if psLexCharEq char '\\' then
              match rest with
              | List.nil =>
                  Except.error
                    (PsLexError.unterminatedString
                      (psLexSpan start position))
              | List.cons escaped tail =>
                  let afterSlash :=
                    psLexAdvanceChar position char;
                  let afterEscape :=
                    psLexAdvanceChar afterSlash escaped;
                  smaller
                    tail
                    afterEscape
                    start
                    (List.cons escaped
                      (List.cons char charsRev))
            else
              smaller
                rest
                (psLexAdvanceChar position char)
                start
                (List.cons char charsRev)

def psLexReadStringBody
    (remaining : List Char)
    (position : PsSourcePos)
    (start : PsSourcePos)
    (charsRev : List Char) :
    Except PsLexError PsLexRead :=
  psLexReadStringBodyWithFuel
    (Nat.add (psLexListLength remaining) 1)
    remaining
    position
    start
    charsRev

def psLexHexDigit (char : Char) : Bool :=
  let code : Nat := Char.toNat char;
  if psLexNatBetween 48 code 57 then
    true
  else if psLexNatBetween 97 code 102 then
    true
  else
    psLexNatBetween 65 code 70

def psLexCharacterEscapeAllowed (char : Char) : Bool :=
  if psLexCharEq char '\'' then
    true
  else if psLexCharEq char '"' then
    true
  else if psLexCharEq char '\\' then
    true
  else if psLexCharEq char 'n' then
    true
  else if psLexCharEq char 'r' then
    true
  else
    psLexCharEq char 't'

def psLexCharacterError
    (start position : PsSourcePos) :
    Except PsLexError PsLexRead :=
  Except.error
    (PsLexError.unterminatedCharacter
      (psLexSpan start position))

def psLexReadCharacterHex2
    (position start : PsSourcePos)
    (charsRev : List Char)
    (remaining : List Char) :
    Except PsLexError PsLexRead :=
  match remaining with
  | List.cons first rest1 =>
      match rest1 with
      | List.cons second rest2 =>
          match rest2 with
          | List.cons close tail =>
              if psLexCharEq close '\'' then
                if psLexHexDigit first then
                  if psLexHexDigit second then
                    let afterSlash :=
                      psLexAdvanceChar position '\\';
                    let afterX :=
                      psLexAdvanceChar afterSlash 'x';
                    let afterFirst :=
                      psLexAdvanceChar afterX first;
                    let afterSecond :=
                      psLexAdvanceChar afterFirst second;
                    let stop :=
                      psLexAdvanceChar afterSecond close;
                    Except.ok {
                      cursor := {
                        remaining := tail
                        position := stop
                      }
                      charsRev :=
                        List.cons close
                          (List.cons second
                            (List.cons first
                              (List.cons 'x'
                                (List.cons '\\' charsRev))))
                    }
                  else
                    psLexCharacterError start position
                else
                  psLexCharacterError start position
              else
                psLexCharacterError start position
          | List.nil => psLexCharacterError start position
      | List.nil => psLexCharacterError start position
  | List.nil => psLexCharacterError start position

def psLexReadCharacterHex4
    (position start : PsSourcePos)
    (charsRev : List Char)
    (remaining : List Char) :
    Except PsLexError PsLexRead :=
  match remaining with
  | List.cons first rest1 =>
      match rest1 with
      | List.cons second rest2 =>
          match rest2 with
          | List.cons third rest3 =>
              match rest3 with
              | List.cons fourth rest4 =>
                  match rest4 with
                  | List.cons close tail =>
                      if psLexCharEq close '\'' then
                        if psLexHexDigit first then
                          if psLexHexDigit second then
                            if psLexHexDigit third then
                              if psLexHexDigit fourth then
                                let afterSlash :=
                                  psLexAdvanceChar position '\\';
                                let afterU :=
                                  psLexAdvanceChar afterSlash 'u';
                                let afterFirst :=
                                  psLexAdvanceChar afterU first;
                                let afterSecond :=
                                  psLexAdvanceChar afterFirst second;
                                let afterThird :=
                                  psLexAdvanceChar afterSecond third;
                                let afterFourth :=
                                  psLexAdvanceChar afterThird fourth;
                                let stop :=
                                  psLexAdvanceChar afterFourth close;
                                Except.ok {
                                  cursor := {
                                    remaining := tail
                                    position := stop
                                  }
                                  charsRev :=
                                    List.cons close
                                      (List.cons fourth
                                        (List.cons third
                                          (List.cons second
                                            (List.cons first
                                              (List.cons 'u'
                                                (List.cons '\\' charsRev))))))
                                }
                              else
                                psLexCharacterError start position
                            else
                              psLexCharacterError start position
                          else
                            psLexCharacterError start position
                        else
                          psLexCharacterError start position
                      else
                        psLexCharacterError start position
                  | List.nil => psLexCharacterError start position
              | List.nil => psLexCharacterError start position
          | List.nil => psLexCharacterError start position
      | List.nil => psLexCharacterError start position
  | List.nil => psLexCharacterError start position

def psLexReadCharacterBody
    (remaining : List Char)
    (position : PsSourcePos)
    (start : PsSourcePos)
    (charsRev : List Char) :
    Except PsLexError PsLexRead :=
  match remaining with
  | List.nil =>
      psLexCharacterError start position
  | List.cons first rest =>
      if psLexCharEq first '\n' then
        psLexCharacterError start position
      else if psLexCharEq first '\\' then
        match rest with
        | List.nil =>
            psLexCharacterError start position
        | List.cons escaped tail =>
            if psLexCharEq escaped 'x' then
              psLexReadCharacterHex2
                position
                start
                charsRev
                tail
            else if psLexCharEq escaped 'u' then
              psLexReadCharacterHex4
                position
                start
                charsRev
                tail
            else
              match tail with
              | List.nil =>
                  psLexCharacterError start position
              | List.cons close afterClose =>
                  if psLexCharEq close '\'' then
                    if psLexCharacterEscapeAllowed escaped then
                      let afterSlash :=
                        psLexAdvanceChar position first;
                      let afterEscape :=
                        psLexAdvanceChar afterSlash escaped;
                      let stop :=
                        psLexAdvanceChar afterEscape close;
                      Except.ok {
                        cursor := {
                          remaining := afterClose
                          position := stop
                        }
                        charsRev :=
                          List.cons close
                            (List.cons escaped
                              (List.cons first charsRev))
                      }
                    else
                      psLexCharacterError start position
                  else
                    psLexCharacterError start position
      else
        match rest with
        | List.nil =>
            psLexCharacterError start position
        | List.cons close tail =>
            if psLexCharEq close '\'' then
              let afterChar :=
                psLexAdvanceChar position first;
              let stop :=
                psLexAdvanceChar afterChar close;
              Except.ok {
                cursor := {
                  remaining := tail
                  position := stop
                }
                charsRev :=
                  List.cons close
                    (List.cons first charsRev)
              }
            else
              psLexCharacterError
                start
                (psLexAdvanceChar position close)

def psLexPairEq
    (first second expectedFirst expectedSecond : Char) : Bool :=
  if psLexCharEq first expectedFirst then
    psLexCharEq second expectedSecond
  else
    false

def psLexIsTwoCharSymbol (first : Char) (second : Char) : Bool :=
  if psLexPairEq first second ':' '=' then
    true
  else if psLexPairEq first second '=' '>' then
    true
  else if psLexPairEq first second '-' '>' then
    true
  else if psLexPairEq first second '=' '=' then
    true
  else if psLexPairEq first second '!' '=' then
    true
  else if psLexPairEq first second '<' '=' then
    true
  else if psLexPairEq first second '>' '=' then
    true
  else if psLexPairEq first second '<' '-' then
    true
  else if psLexPairEq first second '&' '&' then
    true
  else if psLexPairEq first second '|' '|' then
    true
  else if psLexPairEq first second ':' ':' then
    true
  else if psLexPairEq first second '+' '+' then
    true
  else
    psLexPairEq first second '*' '*'

def psLexTokenFromRead
    (kind : PsTokenKind)
    (start : PsSourcePos)
    (read : PsLexRead) : PsToken :=
  {
    kind := kind
    text := psLexString read.charsRev
    span := psLexSpan start read.cursor.position
  }

-- Lean 4.35.0 Lean/Parser/Basic.decimalNumberFn. Decimal tokens retain
-- their exact spelling; neither lexing nor parsing rounds a floating value.
-- Apache-2.0, Microsoft Corporation, Leonardo de Moura.
def psLexNumericToken (first : Char) (remaining : List Char) (start : PsSourcePos) :
    Except PsLexError (PsToken × PsLexCursor) := do
  let integer := psLexReadNumeral first remaining start
  let finish := fun kind read => (psLexTokenFromRead kind start read, read.cursor)
  let radix := psLexCharEq first '0' &&
    (remaining.head?.bind psLexRadixBase).isSome
  if radix then return finish .natural integer
  match integer.cursor.remaining with
  | '.' :: '.' :: _ => return finish .natural integer
  | '.' :: _ | 'e' :: _ | 'E' :: _ => pure ()
  | _ => return finish .natural integer
  let checked : PsLexRead → Except PsLexError PsLexRead := fun read => do
    if read.charsRev.head? == some '_' then
      throw (.invalidSource "trailing separator in scientific literal"
        (psLexSpan start read.cursor.position))
    pure read
  let integer ← checked integer
  let (fraction, bareDot) := match integer.cursor.remaining with
    | '.' :: rest =>
      let position := psLexAdvanceChar integer.cursor.position '.'
      let charsRev := '.' :: integer.charsRev
      if rest.head?.any psLexDigit then
        (psLexReadNatural rest position charsRev, false)
      else ({ cursor := { remaining := rest, position }, charsRev }, true)
    | _ => (integer, false)
  let fraction ← checked fraction
  match fraction.cursor.remaining with
  | marker :: rest =>
    if marker == 'e' || marker == 'E' then
      let position := psLexAdvanceChar fraction.cursor.position marker
      let charsRev := marker :: fraction.charsRev
      let (rest, position, charsRev) := match rest with
        | sign :: tail =>
          if sign == '+' || sign == '-' then
            (tail, psLexAdvanceChar position sign, sign :: charsRev)
          else (rest, position, charsRev)
        | [] => (rest, position, charsRev)
      if !rest.head?.any psLexDigit then
        throw (.invalidSource "missing exponent digits in scientific literal"
          (psLexSpan start position))
      let exponent ← checked (psLexReadNatural rest position charsRev)
      return finish .scientific exponent
    else if bareDot && (psLexIdentifierStart marker || marker == '«') then
      throw (.invalidSource "identifier after decimal point; parenthesize the number"
        (psLexSpan start fraction.cursor.position))
    else return finish .scientific fraction
  | [] => return finish .scientific fraction

def psLexReadToken
    (cursor : PsLexCursor) :
    Except PsLexError (Prod PsToken PsLexCursor) :=
  let start := cursor.position;
  match cursor.remaining with
  | List.nil =>
      let token : PsToken := {
        kind := PsTokenKind.endOfInput
        text := ""
        span := psLexSpan start start
      };
      Except.ok
        (Prod.mk token cursor)
  | List.cons first rest =>
      if psLexCharEq first '"' then
        let afterOpen := psLexAdvanceChar start first;
        match
            psLexReadStringBody
              rest
              afterOpen
              start
              (List.cons first List.nil) with
        | Except.error error => Except.error error
        | Except.ok read =>
            Except.ok
              (Prod.mk
                (psLexTokenFromRead
                  PsTokenKind.string
                  start
                  read)
                read.cursor)
      else if psLexCharEq first '\'' then
        let afterOpen := psLexAdvanceChar start first;
        match
            psLexReadCharacterBody
              rest
              afterOpen
              start
              (List.cons first List.nil) with
        | Except.error error =>
            -- Lean's xs[i]'h proof-index suffix starts with a quote but is not
            -- a character literal. Prefer an actual complete character token;
            -- otherwise keep a quote token only before a proof identifier or
            -- parenthesized term. All other malformed characters still fail.
            match rest with
            | proofStart :: _ =>
              if psLexIdentifierStart proofStart || psLexCharEq proofStart '(' then
                let read : PsLexRead := {
                  cursor := { remaining := rest, position := afterOpen }
                  charsRev := [first] }
                Except.ok (Prod.mk
                  (psLexTokenFromRead PsTokenKind.symbol start read) read.cursor)
              else Except.error error
            | [] => Except.error error
        | Except.ok read =>
            Except.ok
              (Prod.mk
                (psLexTokenFromRead
                  PsTokenKind.character
                  start
                  read)
                read.cursor)
      else
        match rest with
        | List.nil =>
            if psLexIdentifierStart first then
              let read :=
                psLexReadIdentifier
                  List.nil
                  (psLexAdvanceChar start first)
                  (List.cons first List.nil);
              Except.ok
                (Prod.mk
                  (psLexTokenFromRead
                    PsTokenKind.identifier
                    start
                    read)
                  read.cursor)
            else if psLexDigit first then
              psLexNumericToken first List.nil start
            else
              let stop := psLexAdvanceChar start first;
              let read : PsLexRead := {
                cursor := {
                  remaining := List.nil
                  position := stop
                }
                charsRev := List.cons first List.nil
              };
              Except.ok
                (Prod.mk
                  (psLexTokenFromRead
                    PsTokenKind.symbol
                    start
                    read)
                  read.cursor)
        | List.cons second tail =>
            if psLexIdentifierStart first then
              let read :=
                psLexReadIdentifier
                  (List.cons second tail)
                  (psLexAdvanceChar start first)
                  (List.cons first List.nil);
              Except.ok
                (Prod.mk
                  (psLexTokenFromRead
                    PsTokenKind.identifier
                    start
                    read)
                  read.cursor)
            else if psLexDigit first then
              psLexNumericToken first (List.cons second tail) start
            else if psLexIsTwoCharSymbol first second then
              let stop := psLexAdvanceTwo start first second;
              let read : PsLexRead := {
                cursor := {
                  remaining := tail
                  position := stop
                }
                charsRev :=
                  List.cons second
                    (List.cons first List.nil)
              };
              Except.ok
                (Prod.mk
                  (psLexTokenFromRead
                    PsTokenKind.symbol
                    start
                    read)
                  read.cursor)
            else
              let stop := psLexAdvanceChar start first;
              let read : PsLexRead := {
                cursor := {
                  remaining := List.cons second tail
                  position := stop
                }
                charsRev := List.cons first List.nil
              };
              Except.ok
                (Prod.mk
                  (psLexTokenFromRead
                    PsTokenKind.symbol
                    start
                    read)
                  read.cursor)

def psLexAllWorker
    (inputBound : Nat)
    (fuel : Nat) :
    PsLexCursor -> Except PsLexError (List PsToken) :=
  match fuel with
  | 0 =>
      fun (cursor : PsLexCursor) =>
        if psLexCursorDone cursor then
          let position := cursor.position;
          let token : PsToken := {
            kind := PsTokenKind.endOfInput
            text := ""
            span := psLexSpan position position
          };
          Except.ok
            (List.cons token List.nil)
        else
          Except.error PsLexError.fuelExhausted
  | remainingFuel + 1 =>
      fun (cursor : PsLexCursor) =>
        let smaller :
            PsLexCursor ->
            Except PsLexError (List PsToken) :=
          psLexAllWorker inputBound remainingFuel;
        match psLexSkipTriviaWithFuel inputBound cursor.remaining cursor.position with
        | Except.error error => Except.error error
        | Except.ok ready =>
            if psLexCursorDone ready then
              let position := ready.position;
              let token : PsToken := {
                kind := PsTokenKind.endOfInput
                text := ""
                span := psLexSpan position position
              };
              Except.ok
                (List.cons token List.nil)
            else
              match psLexReadToken ready with
              | Except.error error => Except.error error
              | Except.ok pair =>
                  let token : PsToken := pair.fst;
                  let next : PsLexCursor := pair.snd;
                  match smaller next with
                  | Except.error error => Except.error error
                  | Except.ok rest =>
                      Except.ok (List.cons token rest)

def psLexAllWithFuel (fuel : Nat) (cursor : PsLexCursor) : Except PsLexError (List PsToken) :=
  psLexAllWorker (Nat.succ (psLexListLength cursor.remaining)) fuel cursor

def psLex (source : String) : Except PsLexError (List PsToken) :=
  let cursor := psLexCursorFromString source;
  let bound := Nat.succ (String.utf8ByteSize source);
  psLexAllWorker bound bound cursor

def psLexProofScriptWhitespaceError
    (reason : String)
    (position : PsSourcePos)
    (char : Char) : Except PsLexError PsLexCursor :=
  Except.error
    (PsLexError.invalidSource
      reason
      (psLexSpan position (psLexAdvanceChar position char)))

def psLexSkipProofScriptTriviaWithFuel
    (fuel : Nat) :
    List Char ->
    PsSourcePos ->
    Except PsLexError PsLexCursor :=
  match fuel with
  | 0 =>
      fun (remaining : List Char) (position : PsSourcePos) =>
        match remaining with
        | [] => Except.ok { remaining := [], position := position }
        | _ => Except.error PsLexError.fuelExhausted
  | remainingFuel + 1 =>
      fun (remaining : List Char) (position : PsSourcePos) =>
        let smaller :
            List Char ->
            PsSourcePos ->
            Except PsLexError PsLexCursor :=
          psLexSkipProofScriptTriviaWithFuel remainingFuel;
        match remaining with
        | [] => Except.ok { remaining := [], position := position }
        | first :: rest =>
            if psLexCharEq first ' ' then
              smaller rest (psLexAdvanceChar position first)
            else if psLexCharEq first '\n' then
              smaller rest (psLexAdvanceChar position first)
            else if psLexCharEq first '\t' then
              psLexProofScriptWhitespaceError
                "horizontal tab outside a literal or comment" position first
            else if psLexCharEq first '\r' then
              match rest with
              | second :: tail =>
                  if psLexCharEq second '\n' then
                    smaller tail (psLexAdvanceTwo position first second)
                  else
                    psLexProofScriptWhitespaceError
                      "lone carriage return outside a literal or comment" position first
              | [] =>
                  psLexProofScriptWhitespaceError
                    "lone carriage return outside a literal or comment" position first
            else if Nat.beq (Char.toNat first) 65279 then
              psLexProofScriptWhitespaceError
                "byte order mark is only allowed once at the start of a source file"
                position first
            else
              match rest with
              | second :: tail =>
                  if psLexPairEq first second '-' '-' then
                    let afterPrefix := psLexAdvanceTwo position first second;
                    let cursor := psLexSkipLineComment tail afterPrefix;
                    smaller cursor.remaining cursor.position
                  else if psLexPairEq first second '/' '-' then
                    let afterPrefix := psLexAdvanceTwo position first second;
                    match psLexSkipBlockComment 1 tail position afterPrefix with
                    | Except.error error => Except.error error
                    | Except.ok cursor =>
                        smaller cursor.remaining cursor.position
                  else
                    Except.ok { remaining := remaining, position := position }
              | [] =>
                  Except.ok { remaining := remaining, position := position }

-- Lean RC4 raw literals begin with r followed by any number of '#'s
-- and a quote. An unmatched prefix remains an ordinary identifier/symbol.
def psLexRawOpening (fuel : Nat) (remaining : List Char)
    (hashes : Nat := 0) : Option (Nat × List Char) :=
  match fuel, remaining with
  | 0, _ => none
  | _ + 1, [] => none
  | fuel + 1, char :: rest =>
    if psLexCharEq char '"' then some (hashes, rest)
    else if psLexCharEq char '#' then psLexRawOpening fuel rest (hashes + 1)
    else none

def psLexRawTrailingHashes (count : Nat) (remaining : List Char) :
    Option (List Char) :=
  match count, remaining with
  | 0, _ => some remaining
  | _ + 1, [] => none
  | count + 1, char :: rest =>
    if psLexCharEq char '#' then psLexRawTrailingHashes count rest else none

def psLexReadRawBody (fuel : Nat) (hashes : Nat) (remaining : List Char)
    (position start : PsSourcePos) (charsRev : List Char) :
    Except PsLexError PsLexRead :=
  match fuel with
  | 0 => .error (.unterminatedString (psLexSpan start position))
  | fuel + 1 =>
    match remaining with
    | [] => .error (.unterminatedString (psLexSpan start position))
    | char :: rest =>
      if psLexCharEq char '"' then
        match psLexRawTrailingHashes hashes rest with
        | some trailing =>
          let closing := '"' :: List.replicate hashes '#'
          return {
            cursor := {
              remaining := trailing
              position := closing.foldl psLexAdvanceChar position }
            charsRev := closing.foldl (fun acc c => c :: acc) charsRev }
        | none =>
          psLexReadRawBody fuel hashes rest (psLexAdvanceChar position char)
            start (char :: charsRev)
      else
        psLexReadRawBody fuel hashes rest (psLexAdvanceChar position char)
          start (char :: charsRev)

def psLexRawToken? (cursor : PsLexCursor) :
    Option (Except PsLexError (PsToken × PsLexCursor)) :=
  match cursor.remaining with
  | [] => none
  | first :: rest =>
    if !psLexCharEq first 'r' then none
    else
      match psLexRawOpening (rest.length + 1) rest with
      | none => none
      | some (hashes, body) =>
        let opening := 'r' :: List.replicate hashes '#' ++ ['"']
        let position := opening.foldl psLexAdvanceChar cursor.position
        let reversed := opening.foldl (fun acc c => c :: acc) ([] : List Char)
        some ((psLexReadRawBody (body.length + 1) hashes body position
          cursor.position reversed).map fun read =>
            (psLexTokenFromRead .string cursor.position read, read.cursor))

-- An interpolated token retains its exact input span, while the same
-- scanner records literal chunks and embedded source terms. Text, escapes,
-- expression nesting, quotes and Lean comments are lexed separately.
-- The embedded source is parsed later by the ordinary v7 term parser.
inductive PsLexInterpolationPart where
  | literal (value : String)
  | expression (value : String)

inductive PsLexInterpolationMode where
  | text (escaped : Bool)
  | expression (depth : Nat) (quote : Option Char) (escaped : Bool)
      (lineComment : Bool) (blockDepth : Nat)

structure PsLexInterpolatedRead where
  cursor : PsLexCursor
  charsRev : List Char
  partsRev : List PsLexInterpolationPart

def psLexScanInterpolated (fuel : Nat) (remaining : List Char)
    (position start : PsSourcePos) (charsRev segmentRev : List Char)
    (partsRev : List PsLexInterpolationPart) (mode : PsLexInterpolationMode) :
    Except PsLexError PsLexInterpolatedRead :=
  match fuel with
  | 0 => .error (.unterminatedString (psLexSpan start position))
  | fuel + 1 =>
    match remaining with
    | [] => .error (.unterminatedString (psLexSpan start position))
    | char :: rest =>
      let step := fun nextMode =>
        psLexScanInterpolated fuel rest (psLexAdvanceChar position char)
          start (char :: charsRev) (char :: segmentRev) partsRev nextMode
      let stepTwo := fun (second : Char) (tail : List Char) nextMode =>
        psLexScanInterpolated fuel tail (psLexAdvanceTwo position char second)
          start (second :: char :: charsRev) (second :: char :: segmentRev)
          partsRev nextMode
      match mode with
      | .text escaped =>
        if escaped then step (.text false)
        else if psLexCharEq char '\\' then step (.text true)
        else if psLexCharEq char '"' then
          let parts := if segmentRev.isEmpty then partsRev
            else .literal (psLexString segmentRev) :: partsRev
          .ok {
            cursor := { remaining := rest, position := psLexAdvanceChar position char }
            charsRev := char :: charsRev
            partsRev := parts }
        else if psLexCharEq char '\n' || psLexCharEq char '\r' then
          .error (.newlineInString (psLexSpan start position))
        else if psLexCharEq char '{' then
          match rest with
          | '{' :: tail =>
            psLexScanInterpolated fuel tail (psLexAdvanceTwo position char '{')
              start ('{' :: char :: charsRev) ('{' :: segmentRev) partsRev (.text false)
          | _ =>
            let parts := if segmentRev.isEmpty then partsRev
              else .literal (psLexString segmentRev) :: partsRev
            psLexScanInterpolated fuel rest (psLexAdvanceChar position char)
              start (char :: charsRev) [] parts (.expression 1 none false false 0)
        else if psLexCharEq char '}' then
          match rest with
          | '}' :: tail =>
            psLexScanInterpolated fuel tail (psLexAdvanceTwo position char '}')
              start ('}' :: char :: charsRev) ('}' :: segmentRev) partsRev (.text false)
          | _ => .error (.invalidSource "unescaped closing brace in interpolation"
                    (psLexSpan position (psLexAdvanceChar position char)))
        else step (.text false)
      | .expression depth quote escaped lineComment blockDepth =>
        if blockDepth > 0 then
          match rest with
          | second :: tail =>
            if psLexPairEq char second '/' '-' then
              stepTwo second tail (.expression depth none false false (blockDepth + 1))
            else if psLexPairEq char second '-' '/' then
              stepTwo second tail (.expression depth none false false (blockDepth - 1))
            else step (.expression depth none false false blockDepth)
          | [] => step (.expression depth none false false blockDepth)
        else if lineComment then
          step (.expression depth none false (char != '\n') 0)
        else if quote.isSome then
          if escaped then step (.expression depth quote false false 0)
          else if psLexCharEq char '\\' then
            step (.expression depth quote true false 0)
          else if quote == some char then
            step (.expression depth none false false 0)
          else step (.expression depth quote false false 0)
        else
          match rest with
          | second :: tail =>
            if psLexPairEq char second '-' '-' then
              stepTwo second tail (.expression depth none false true 0)
            else if psLexPairEq char second '/' '-' then
              stepTwo second tail (.expression depth none false false 1)
            else if psLexCharEq char '"' then
              step (.expression depth (some '"') false false 0)
            else if psLexCharEq char '\'' then
              let characterLiteral := match rest with
                | _ :: '\'' :: _ => true
                | '\\' :: _ :: '\'' :: _ => true
                | _ => false
              step (.expression depth (if characterLiteral then some '\'' else none) false false 0)
            else if psLexCharEq char '{' then
              step (.expression (depth + 1) none false false 0)
            else if psLexCharEq char '}' then
              if depth == 1 then
                let parts := .expression (psLexString segmentRev) :: partsRev
                psLexScanInterpolated fuel rest (psLexAdvanceChar position char)
                  start (char :: charsRev) [] parts (.text false)
              else step (.expression (depth - 1) none false false 0)
            else step (.expression depth none false false 0)
          | [] =>
            if psLexCharEq char '"' then
              step (.expression depth (some '"') false false 0)
            else if psLexCharEq char '{' then
              step (.expression (depth + 1) none false false 0)
            else if psLexCharEq char '}' && depth == 1 then
              let parts := .expression (psLexString segmentRev) :: partsRev
              psLexScanInterpolated fuel rest (psLexAdvanceChar position char)
                start (char :: charsRev) [] parts (.text false)
            else if psLexCharEq char '}' then
              step (.expression (depth - 1) none false false 0)
            else step (.expression depth none false false 0)

def psLexInterpolatedRead? (cursor : PsLexCursor) :
    Option (Except PsLexError PsLexInterpolatedRead) :=
  match cursor.remaining with
  | 's' :: '!' :: '"' :: rest =>
    let opening : List Char := ['s', '!', '"']
    let position := opening.foldl psLexAdvanceChar cursor.position
    let reversed := opening.foldl (fun acc char => char :: acc) ([] : List Char)
    some (psLexScanInterpolated (rest.length + 1) rest position cursor.position
      reversed [] [] (.text false))
  | _ => none

def psLexInterpolatedToken? (cursor : PsLexCursor) :
    Option (Except PsLexError (PsToken × PsLexCursor)) :=
  (psLexInterpolatedRead? cursor).map fun result =>
    result.map fun read =>
      ({ kind := .string, text := psLexString read.charsRev,
         span := psLexSpan cursor.position read.cursor.position }, read.cursor)

def psLexInterpolationParts? (text : String) : Option (List PsLexInterpolationPart) := do
  let result ← psLexInterpolatedRead? (psLexCursorFromString text)
  let read ← result.toOption
  if read.cursor.remaining.isEmpty then some read.partsRev.reverse else none

def psLexAllProofScriptWorker
    (inputBound : Nat)
    (fuel : Nat) :
    PsLexCursor -> Except PsLexError (List PsToken) :=
  match fuel with
  | 0 =>
      fun (cursor : PsLexCursor) =>
        if psLexCursorDone cursor then
          let position := cursor.position;
          let token : PsToken := {
            kind := PsTokenKind.endOfInput
            text := ""
            span := psLexSpan position position
          };
          Except.ok
            (List.cons token List.nil)
        else
          Except.error PsLexError.fuelExhausted
  | remainingFuel + 1 =>
      fun (cursor : PsLexCursor) =>
        let smaller :
            PsLexCursor ->
            Except PsLexError (List PsToken) :=
          psLexAllProofScriptWorker inputBound remainingFuel;
        match psLexSkipProofScriptTriviaWithFuel inputBound cursor.remaining cursor.position with
        | Except.error error => Except.error error
        | Except.ok ready =>
            if psLexCursorDone ready then
              let position := ready.position;
              let token : PsToken := {
                kind := PsTokenKind.endOfInput
                text := ""
                span := psLexSpan position position
              };
              Except.ok
                (List.cons token List.nil)
            else
              let parsed := match psLexInterpolatedToken? ready with
                | some result => result
                | none => match psLexRawToken? ready with
                  | some result => result
                  | none => psLexReadToken ready
              match parsed with
              | Except.error error => Except.error error
              | Except.ok pair =>
                  let token : PsToken := pair.fst;
                  let next : PsLexCursor := pair.snd;
                  match smaller next with
                  | Except.error error => Except.error error
                  | Except.ok rest =>
                      Except.ok (List.cons token rest)


def psLexProofScript (source : String) : Except PsLexError (List PsToken) :=
  let original := psLexCursorFromString source;
  let cursor : PsLexCursor :=
    match original.remaining with
    | first :: rest =>
        if Nat.beq (Char.toNat first) 65279 then
          {
            remaining := rest
            position := {
              byteOffset := 3
              line := 1
              column := 1
            }
          }
        else
          original
    | [] => original;
  let bound := Nat.succ (String.utf8ByteSize source);
  psLexAllProofScriptWorker bound bound cursor
