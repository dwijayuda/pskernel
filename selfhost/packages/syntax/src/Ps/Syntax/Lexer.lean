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

def psLexSkipLineComment :
    List Char -> PsSourcePos -> PsLexCursor
  | [], position =>
      { remaining := List.nil, position := position }
  | '\n' :: rest, position =>
      { remaining := List.cons '\n' rest, position := position }
  | char :: rest, position =>
      psLexSkipLineComment rest (psLexAdvanceChar position char)

def psLexSkipBlockComment :
    Nat -> List Char -> PsSourcePos -> PsSourcePos ->
    Except PsLexError PsLexCursor
  | _, [], start, position =>
      Except.error
        (PsLexError.unterminatedBlockComment (psLexSpan start position))
  | depth, '/' :: '-' :: rest, start, position =>
      psLexSkipBlockComment
        (depth + 1)
        rest
        start
        (psLexAdvanceTwo position '/' '-')
  | 1, '-' :: '/' :: rest, _, position =>
      Except.ok {
        remaining := rest
        position := psLexAdvanceTwo position '-' '/'
      }
  | depth + 1, '-' :: '/' :: rest, start, position =>
      psLexSkipBlockComment
        depth
        rest
        start
        (psLexAdvanceTwo position '-' '/')
  | depth, char :: rest, start, position =>
      psLexSkipBlockComment
        depth
        rest
        start
        (psLexAdvanceChar position char)

def psLexSkipTriviaWithFuel :
    Nat -> List Char -> PsSourcePos -> Except PsLexError PsLexCursor
  | 0, remaining, position =>
      Except.ok { remaining := remaining, position := position }
  | _ + 1, [], position =>
      Except.ok { remaining := List.nil, position := position }
  | fuel + 1, '-' :: '-' :: rest, position =>
      let afterPrefix := psLexAdvanceTwo position '-' '-'
      let cursor := psLexSkipLineComment rest afterPrefix
      psLexSkipTriviaWithFuel fuel cursor.remaining cursor.position
  | fuel + 1, '/' :: '-' :: rest, position =>
      let start := position
      let afterPrefix := psLexAdvanceTwo position '/' '-'
      match psLexSkipBlockComment 1 rest start afterPrefix with
      | Except.error error => Except.error error
      | Except.ok cursor =>
          psLexSkipTriviaWithFuel fuel cursor.remaining cursor.position
  | fuel + 1, char :: rest, position =>
      if char.isWhitespace then
        psLexSkipTriviaWithFuel
          fuel
          rest
          (psLexAdvanceChar position char)
      else
        Except.ok { remaining := List.cons char rest, position := position }

def psLexSkipTrivia
    (remaining : List Char)
    (position : PsSourcePos) : Except PsLexError PsLexCursor :=
  psLexSkipTriviaWithFuel (remaining.length + 1) remaining position

def psLexLetterLike (char : Char) : Bool :=
  (0x3b1 <= char.val && char.val <= 0x3c9 && char.val != 0x3bb)
    || (0x391 <= char.val && char.val <= 0x3a9
      && char.val != 0x3a0 && char.val != 0x3a3)
    || (0x3ca <= char.val && char.val <= 0x3fb)
    || (0x1f00 <= char.val && char.val <= 0x1ffe)
    || (0x2100 <= char.val && char.val <= 0x214f)
    || (0x1d49c <= char.val && char.val <= 0x1d59f)
    || (0x00c0 <= char.val && char.val <= 0x00ff
      && char.val != 0x00d7 && char.val != 0x00f7)
    || (0x0100 <= char.val && char.val <= 0x017f)

def psLexNumericSubscript (char : Char) : Bool :=
  0x2080 <= char.val && char.val <= 0x2089

def psLexSubscriptAlnum (char : Char) : Bool :=
  psLexNumericSubscript char
    || (0x2090 <= char.val && char.val <= 0x209c)
    || (0x1d62 <= char.val && char.val <= 0x1d6a)
    || char.val == 0x2c7c

def psLexIdentifierStart (char : Char) : Bool :=
  char.isAlpha || char == '_' || psLexLetterLike char

def psLexIdentifierContinue (char : Char) : Bool :=
  char.isAlphanum
    || char == '_'
    || char == '\''
    || char == '!'
    || char == '?'
    || psLexLetterLike char
    || psLexSubscriptAlnum char

def psLexDigit (char : Char) : Bool :=
  char.isDigit

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
      if psLexDigit char || char == '_' then
        psLexReadNatural
          rest
          (psLexAdvanceChar position char)
          (List.cons char charsRev)
      else
        {
          cursor := { remaining := List.cons char rest, position := position }
          charsRev := charsRev
        }

def psLexReadStringBody :
    List Char -> PsSourcePos -> PsSourcePos -> List Char ->
    Except PsLexError PsLexRead
  | [], position, start, _ =>
      Except.error
        (PsLexError.unterminatedString (psLexSpan start position))
  | '"' :: rest, position, _, charsRev =>
      let stop := psLexAdvanceChar position '"'
      Except.ok {
        cursor := { remaining := rest, position := stop }
        charsRev := List.cons '"' charsRev
      }
  | '\n' :: _, position, start, _ =>
      Except.error
        (PsLexError.newlineInString (psLexSpan start position))
  | '\\' :: escaped :: rest, position, start, charsRev =>
      let afterSlash := psLexAdvanceChar position '\\'
      let afterEscape := psLexAdvanceChar afterSlash escaped
      psLexReadStringBody
        rest
        afterEscape
        start
        (List.cons escaped (List.cons '\\' charsRev))
  | char :: rest, position, start, charsRev =>
      psLexReadStringBody
        rest
        (psLexAdvanceChar position char)
        start
        (List.cons char charsRev)

def psLexHexDigit (char : Char) : Bool :=
  ('0' <= char && char <= '9')
    || ('a' <= char && char <= 'f')
    || ('A' <= char && char <= 'F')

def psLexReadCharacterBody :
    List Char -> PsSourcePos -> PsSourcePos -> List Char ->
    Except PsLexError PsLexRead
  | [], position, start, _ =>
      Except.error
        (PsLexError.unterminatedCharacter (psLexSpan start position))
  | '\n' :: _, position, start, _ =>
      Except.error
        (PsLexError.unterminatedCharacter (psLexSpan start position))
  | '\\' :: 'x' :: first :: second :: '\'' :: rest,
      position, start, charsRev =>
      if psLexHexDigit first && psLexHexDigit second then
        let afterSlash := psLexAdvanceChar position '\\'
        let afterX := psLexAdvanceChar afterSlash 'x'
        let afterFirst := psLexAdvanceChar afterX first
        let afterSecond := psLexAdvanceChar afterFirst second
        let stop := psLexAdvanceChar afterSecond '\''
        Except.ok {
          cursor := { remaining := rest, position := stop }
          charsRev :=
            List.cons '\'' (List.cons second (List.cons first (List.cons 'x' (List.cons '\\' charsRev))))
        }
      else
        Except.error
          (PsLexError.unterminatedCharacter
            (psLexSpan start position))
  | '\\' :: 'u' :: first :: second :: third :: fourth :: '\'' :: rest,
      position, start, charsRev =>
      if
          psLexHexDigit first
            && psLexHexDigit second
            && psLexHexDigit third
            && psLexHexDigit fourth then
        let afterSlash := psLexAdvanceChar position '\\'
        let afterU := psLexAdvanceChar afterSlash 'u'
        let afterFirst := psLexAdvanceChar afterU first
        let afterSecond := psLexAdvanceChar afterFirst second
        let afterThird := psLexAdvanceChar afterSecond third
        let afterFourth := psLexAdvanceChar afterThird fourth
        let stop := psLexAdvanceChar afterFourth '\''
        Except.ok {
          cursor := { remaining := rest, position := stop }
          charsRev :=
            List.cons '\''
              (List.cons fourth
                (List.cons third
                  (List.cons second
                    (List.cons first
                      (List.cons 'u'
                        (List.cons '\\' charsRev))))))
        }
      else
        Except.error
          (PsLexError.unterminatedCharacter
            (psLexSpan start position))
  | '\\' :: escaped :: '\'' :: rest, position, start, charsRev =>
      if
          escaped == '\''
            || escaped == '"'
            || escaped == '\\'
            || escaped == 'n'
            || escaped == 'r'
            || escaped == 't' then
        let afterSlash := psLexAdvanceChar position '\\'
        let afterEscape := psLexAdvanceChar afterSlash escaped
        let stop := psLexAdvanceChar afterEscape '\''
        Except.ok {
          cursor := { remaining := rest, position := stop }
          charsRev := List.cons '\'' (List.cons escaped (List.cons '\\' charsRev))
        }
      else
        Except.error
          (PsLexError.unterminatedCharacter
            (psLexSpan start position))
  | char :: '\'' :: rest, position, _, charsRev =>
      let afterChar := psLexAdvanceChar position char
      let stop := psLexAdvanceChar afterChar '\''
      Except.ok {
        cursor := { remaining := rest, position := stop }
        charsRev := List.cons '\'' (List.cons char charsRev)
      }
  | _ :: rest, position, start, _ =>
      let stop :=
        match rest with
        | [] => position
        | char :: _ => psLexAdvanceChar position char
      Except.error
        (PsLexError.unterminatedCharacter (psLexSpan start stop))

def psLexIsTwoCharSymbol (first : Char) (second : Char) : Bool :=
  (first == ':' && second == '=')
    || (first == '=' && second == '>')
    || (first == '-' && second == '>')
    || (first == '=' && second == '=')
    || (first == '!' && second == '=')
    || (first == '<' && second == '=')
    || (first == '>' && second == '=')
    || (first == '<' && second == '-')
    || (first == '&' && second == '&')
    || (first == '|' && second == '|')
    || (first == ':' && second == ':')
    || (first == '+' && second == '+')
    || (first == '*' && second == '*')

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
    (cursor : PsLexCursor) : Except PsLexError (PsToken × PsLexCursor) :=
  let start := cursor.position
  match cursor.remaining with
  | [] =>
      Except.ok (
        {
          kind := PsTokenKind.endOfInput
          text := ""
          span := psLexSpan start start
        },
        cursor
      )
  | '"' :: rest =>
      let afterOpen := psLexAdvanceChar start '"'
      match psLexReadStringBody rest afterOpen start (List.cons '"' List.nil) with
      | Except.error error => Except.error error
      | Except.ok read =>
          Except.ok
            (psLexTokenFromRead PsTokenKind.string start read, read.cursor)
  | '\'' :: rest =>
      let afterOpen := psLexAdvanceChar start '\''
      match psLexReadCharacterBody rest afterOpen start (List.cons '\'' List.nil) with
      | Except.error error => Except.error error
      | Except.ok read =>
          Except.ok
            (psLexTokenFromRead PsTokenKind.character start read, read.cursor)
  | first :: second :: rest =>
      if psLexIdentifierStart first then
        let read :=
          psLexReadIdentifier
            (List.cons second rest)
            (psLexAdvanceChar start first)
            (List.cons first List.nil)
        Except.ok
          (psLexTokenFromRead PsTokenKind.identifier start read, read.cursor)
      else if psLexDigit first then
        let read :=
          psLexReadNatural
            (List.cons second rest)
            (psLexAdvanceChar start first)
            (List.cons first List.nil)
        Except.ok
          (psLexTokenFromRead PsTokenKind.natural start read, read.cursor)
      else if psLexIsTwoCharSymbol first second then
        let stop := psLexAdvanceTwo start first second
        let read : PsLexRead := {
          cursor := { remaining := rest, position := stop }
          charsRev := List.cons second (List.cons first List.nil)
        }
        Except.ok
          (psLexTokenFromRead PsTokenKind.symbol start read, read.cursor)
      else
        let stop := psLexAdvanceChar start first
        let read : PsLexRead := {
          cursor := { remaining := List.cons second rest, position := stop }
          charsRev := List.cons first List.nil
        }
        Except.ok
          (psLexTokenFromRead PsTokenKind.symbol start read, read.cursor)
  | first :: rest =>
      if psLexIdentifierStart first then
        let read :=
          psLexReadIdentifier
            rest
            (psLexAdvanceChar start first)
            (List.cons first List.nil)
        Except.ok
          (psLexTokenFromRead PsTokenKind.identifier start read, read.cursor)
      else if psLexDigit first then
        let read :=
          psLexReadNatural
            rest
            (psLexAdvanceChar start first)
            (List.cons first List.nil)
        Except.ok
          (psLexTokenFromRead PsTokenKind.natural start read, read.cursor)
      else
        let stop := psLexAdvanceChar start first
        let read : PsLexRead := {
          cursor := { remaining := rest, position := stop }
          charsRev := List.cons first List.nil
        }
        Except.ok
          (psLexTokenFromRead PsTokenKind.symbol start read, read.cursor)

def psLexAllWithFuel :
    Nat -> PsLexCursor -> Except PsLexError (List PsToken)
  | 0, cursor =>
      if psLexCursorDone cursor then
        let position := cursor.position
        Except.ok
          (List.cons
            {
              kind := PsTokenKind.endOfInput
              text := ""
              span := psLexSpan position position
            }
            List.nil)
      else
        Except.error PsLexError.fuelExhausted
  | fuel + 1, cursor =>
      match psLexSkipTrivia cursor.remaining cursor.position with
      | Except.error error => Except.error error
      | Except.ok ready =>
          if psLexCursorDone ready then
            let position := ready.position
            Except.ok
              (List.cons
                {
                  kind := PsTokenKind.endOfInput
                  text := ""
                  span := psLexSpan position position
                }
                List.nil)
          else
            match psLexReadToken ready with
            | Except.error error => Except.error error
            | Except.ok (token, next) =>
                match psLexAllWithFuel fuel next with
                | Except.error error => Except.error error
                | Except.ok rest => Except.ok (List.cons token rest)

def psLex (source : String) : Except PsLexError (List PsToken) :=
  let cursor := psLexCursorFromString source
  psLexAllWithFuel (source.toList.length + 1) cursor
