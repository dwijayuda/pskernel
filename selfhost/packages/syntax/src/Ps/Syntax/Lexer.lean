import Ps.Syntax.Cursor
import Ps.Syntax.Token

inductive PsLexError where
  | unterminatedBlockComment (span : PsSourceSpan)
  | unterminatedString (span : PsSourceSpan)
  | newlineInString (span : PsSourceSpan)
  | unterminatedCharacter (span : PsSourceSpan)
  | fuelExhausted

structure PsLexRead where
  cursor : PsLexCursor
  charsRev : List Char

def psLexSpan (start : PsSourcePos) (stop : PsSourcePos) : PsSourceSpan :=
  { start := start, stop := stop }

def psLexString (charsRev : List Char) : String :=
  String.ofList charsRev.reverse

def psLexAdvanceChar (position : PsSourcePos) (char : Char) : PsSourcePos :=
  psLexAdvancePosition position char

def psLexAdvanceTwo
    (position : PsSourcePos)
    (first : Char)
    (second : Char) : PsSourcePos :=
  psLexAdvanceChar (psLexAdvanceChar position first) second

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
    (remaining : List Char)
    (position : PsSourcePos) : PsLexCursor :=
  match remaining with
  | List.nil =>
      { remaining := List.nil, position := position }
  | List.cons char rest =>
      if psLexCharEq char '\n' then
        {
          remaining := List.cons char rest
          position := position
        }
      else
        psLexSkipLineComment
          rest
          (psLexAdvanceChar position char)

def psLexSkipBlockCommentWithFuel
    (fuel : Nat)
    (depth : Nat)
    (remaining : List Char)
    (start : PsSourcePos)
    (position : PsSourcePos) :
    Except PsLexError PsLexCursor :=
  match fuel with
  | 0 =>
      Except.error
        (PsLexError.unterminatedBlockComment
          (psLexSpan start position))
  | remainingFuel + 1 =>
      match remaining with
      | List.nil =>
          Except.error
            (PsLexError.unterminatedBlockComment
              (psLexSpan start position))
      | List.cons first rest =>
          match rest with
          | List.nil =>
              psLexSkipBlockCommentWithFuel
                remainingFuel
                depth
                List.nil
                start
                (psLexAdvanceChar position first)
          | List.cons second tail =>
              if psLexCharEq first '/' then
                if psLexCharEq second '-' then
                  psLexSkipBlockCommentWithFuel
                    remainingFuel
                    (Nat.add depth 1)
                    tail
                    start
                    (psLexAdvanceTwo position first second)
                else
                  psLexSkipBlockCommentWithFuel
                    remainingFuel
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
                    psLexSkipBlockCommentWithFuel
                      remainingFuel
                      (Nat.sub depth 1)
                      tail
                      start
                      (psLexAdvanceTwo position first second)
                else
                  psLexSkipBlockCommentWithFuel
                    remainingFuel
                    depth
                    rest
                    start
                    (psLexAdvanceChar position first)
              else
                psLexSkipBlockCommentWithFuel
                  remainingFuel
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
    (Nat.add (List.length remaining) 1)
    depth
    remaining
    start
    position

def psLexSkipTriviaWithFuel
    (fuel : Nat)
    (remaining : List Char)
    (position : PsSourcePos) :
    Except PsLexError PsLexCursor :=
  match fuel with
  | 0 =>
      Except.ok {
        remaining := remaining
        position := position
      }
  | remainingFuel + 1 =>
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
                  psLexSkipTriviaWithFuel
                    remainingFuel
                    cursor.remaining
                    cursor.position
                else if psLexWhitespace first then
                  psLexSkipTriviaWithFuel
                    remainingFuel
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
                      psLexSkipTriviaWithFuel
                        remainingFuel
                        cursor.remaining
                        cursor.position
                else if psLexWhitespace first then
                  psLexSkipTriviaWithFuel
                    remainingFuel
                    rest
                    (psLexAdvanceChar position first)
                else
                  Except.ok {
                    remaining := List.cons first rest
                    position := position
                  }
              else if psLexWhitespace first then
                psLexSkipTriviaWithFuel
                  remainingFuel
                  rest
                  (psLexAdvanceChar position first)
              else
                Except.ok {
                  remaining := List.cons first rest
                  position := position
                }
          | List.nil =>
              if psLexWhitespace first then
                psLexSkipTriviaWithFuel
                  remainingFuel
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
  psLexSkipTriviaWithFuel (Nat.add remaining.length 1) remaining position

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

def psLexReadIdentifier :
    List Char -> PsSourcePos -> List Char -> PsLexRead
  | [], position, charsRev =>
      {
        cursor := { remaining := List.nil, position := position }
        charsRev := charsRev
      }
  | char :: rest, position, charsRev =>
      if psLexIdentifierContinue char then
        psLexReadIdentifier
          rest
          (psLexAdvanceChar position char)
          (List.cons char charsRev)
      else
        {
          cursor := { remaining := List.cons char rest, position := position }
          charsRev := charsRev
        }

def psLexReadNatural :
    List Char -> PsSourcePos -> List Char -> PsLexRead
  | [], position, charsRev =>
      {
        cursor := { remaining := List.nil, position := position }
        charsRev := charsRev
      }
  | char :: rest, position, charsRev =>
      if psLexNaturalContinue char then
        psLexReadNatural
          rest
          (psLexAdvanceChar position char)
          (List.cons char charsRev)
      else
        {
          cursor := { remaining := List.cons char rest, position := position }
          charsRev := charsRev
        }

def psLexReadStringBody
    (remaining : List Char)
    (position : PsSourcePos)
    (start : PsSourcePos)
    (charsRev : List Char) :
    Except PsLexError PsLexRead :=
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
            psLexReadStringBody
              tail
              afterEscape
              start
              (List.cons escaped
                (List.cons char charsRev))
      else
        psLexReadStringBody
          rest
          (psLexAdvanceChar position char)
          start
          (List.cons char charsRev)

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
        | Except.error error => Except.error error
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
              let read :=
                psLexReadNatural
                  List.nil
                  (psLexAdvanceChar start first)
                  (List.cons first List.nil);
              Except.ok
                (Prod.mk
                  (psLexTokenFromRead
                    PsTokenKind.natural
                    start
                    read)
                  read.cursor)
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
              let read :=
                psLexReadNatural
                  (List.cons second tail)
                  (psLexAdvanceChar start first)
                  (List.cons first List.nil);
              Except.ok
                (Prod.mk
                  (psLexTokenFromRead
                    PsTokenKind.natural
                    start
                    read)
                  read.cursor)
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

def psLexAllWithFuel :
    Nat -> PsLexCursor -> Except PsLexError (List PsToken)
  | 0, cursor =>
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
  | fuel + 1, cursor =>
      match psLexSkipTrivia cursor.remaining cursor.position with
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
                match psLexAllWithFuel fuel next with
                | Except.error error => Except.error error
                | Except.ok rest =>
                    Except.ok (List.cons token rest)

def psLex (source : String) : Except PsLexError (List PsToken) :=
  let cursor := psLexCursorFromString source;
  psLexAllWithFuel (Nat.add source.toList.length 1) cursor
