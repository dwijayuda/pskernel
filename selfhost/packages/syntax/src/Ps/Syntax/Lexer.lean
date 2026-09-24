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
      { remaining := [], position := position }
  | '\n' :: rest, position =>
      { remaining := '\n' :: rest, position := position }
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
      Except.ok { remaining := [], position := position }
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
        Except.ok { remaining := char :: rest, position := position }

def psLexSkipTrivia
    (remaining : List Char)
    (position : PsSourcePos) : Except PsLexError PsLexCursor :=
  psLexSkipTriviaWithFuel (remaining.length + 1) remaining position

def psLexIdentifierStart (char : Char) : Bool :=
  char.isAlpha || char == '_'

def psLexIdentifierContinue (char : Char) : Bool :=
  char.isAlphanum || char == '_' || char == '\'' || char == '?'

def psLexDigit (char : Char) : Bool :=
  char.isDigit

def psLexReadIdentifier :
    List Char -> PsSourcePos -> List Char -> PsLexRead
  | [], position, charsRev =>
      {
        cursor := { remaining := [], position := position }
        charsRev := charsRev
      }
  | char :: rest, position, charsRev =>
      if psLexIdentifierContinue char then
        psLexReadIdentifier
          rest
          (psLexAdvanceChar position char)
          (char :: charsRev)
      else
        {
          cursor := { remaining := char :: rest, position := position }
          charsRev := charsRev
        }

def psLexReadNatural :
    List Char -> PsSourcePos -> List Char -> PsLexRead
  | [], position, charsRev =>
      {
        cursor := { remaining := [], position := position }
        charsRev := charsRev
      }
  | char :: rest, position, charsRev =>
      if psLexDigit char || char == '_' then
        psLexReadNatural
          rest
          (psLexAdvanceChar position char)
          (char :: charsRev)
      else
        {
          cursor := { remaining := char :: rest, position := position }
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
        charsRev := '"' :: charsRev
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
        (escaped :: '\\' :: charsRev)
  | char :: rest, position, start, charsRev =>
      psLexReadStringBody
        rest
        (psLexAdvanceChar position char)
        start
        (char :: charsRev)

def psLexReadCharacterBody :
    List Char -> PsSourcePos -> PsSourcePos -> List Char ->
    Except PsLexError PsLexRead
  | [], position, start, _ =>
      Except.error
        (PsLexError.unterminatedCharacter (psLexSpan start position))
  | '\n' :: _, position, start, _ =>
      Except.error
        (PsLexError.unterminatedCharacter (psLexSpan start position))
  | '\\' :: escaped :: '\'' :: rest, position, _, charsRev =>
      let afterSlash := psLexAdvanceChar position '\\'
      let afterEscape := psLexAdvanceChar afterSlash escaped
      let stop := psLexAdvanceChar afterEscape '\''
      Except.ok {
        cursor := { remaining := rest, position := stop }
        charsRev := '\'' :: escaped :: '\\' :: charsRev
      }
  | char :: '\'' :: rest, position, _, charsRev =>
      let afterChar := psLexAdvanceChar position char
      let stop := psLexAdvanceChar afterChar '\''
      Except.ok {
        cursor := { remaining := rest, position := stop }
        charsRev := '\'' :: char :: charsRev
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
      match psLexReadStringBody rest afterOpen start ['"'] with
      | Except.error error => Except.error error
      | Except.ok read =>
          Except.ok
            (psLexTokenFromRead PsTokenKind.string start read, read.cursor)
  | '\'' :: rest =>
      let afterOpen := psLexAdvanceChar start '\''
      match psLexReadCharacterBody rest afterOpen start ['\''] with
      | Except.error error => Except.error error
      | Except.ok read =>
          Except.ok
            (psLexTokenFromRead PsTokenKind.character start read, read.cursor)
  | first :: second :: rest =>
      if psLexIdentifierStart first then
        let read :=
          psLexReadIdentifier
            (second :: rest)
            (psLexAdvanceChar start first)
            [first]
        Except.ok
          (psLexTokenFromRead PsTokenKind.identifier start read, read.cursor)
      else if psLexDigit first then
        let read :=
          psLexReadNatural
            (second :: rest)
            (psLexAdvanceChar start first)
            [first]
        Except.ok
          (psLexTokenFromRead PsTokenKind.natural start read, read.cursor)
      else if psLexIsTwoCharSymbol first second then
        let stop := psLexAdvanceTwo start first second
        let read : PsLexRead := {
          cursor := { remaining := rest, position := stop }
          charsRev := [second, first]
        }
        Except.ok
          (psLexTokenFromRead PsTokenKind.symbol start read, read.cursor)
      else
        let stop := psLexAdvanceChar start first
        let read : PsLexRead := {
          cursor := { remaining := second :: rest, position := stop }
          charsRev := [first]
        }
        Except.ok
          (psLexTokenFromRead PsTokenKind.symbol start read, read.cursor)
  | first :: rest =>
      if psLexIdentifierStart first then
        let read :=
          psLexReadIdentifier
            rest
            (psLexAdvanceChar start first)
            [first]
        Except.ok
          (psLexTokenFromRead PsTokenKind.identifier start read, read.cursor)
      else if psLexDigit first then
        let read :=
          psLexReadNatural
            rest
            (psLexAdvanceChar start first)
            [first]
        Except.ok
          (psLexTokenFromRead PsTokenKind.natural start read, read.cursor)
      else
        let stop := psLexAdvanceChar start first
        let read : PsLexRead := {
          cursor := { remaining := rest, position := stop }
          charsRev := [first]
        }
        Except.ok
          (psLexTokenFromRead PsTokenKind.symbol start read, read.cursor)

def psLexAllWithFuel :
    Nat -> PsLexCursor -> Except PsLexError (List PsToken)
  | 0, cursor =>
      if psLexCursorDone cursor then
        let position := cursor.position
        Except.ok [{
          kind := PsTokenKind.endOfInput
          text := ""
          span := psLexSpan position position
        }]
      else
        Except.error PsLexError.fuelExhausted
  | fuel + 1, cursor =>
      match psLexSkipTrivia cursor.remaining cursor.position with
      | Except.error error => Except.error error
      | Except.ok ready =>
          if psLexCursorDone ready then
            let position := ready.position
            Except.ok [{
              kind := PsTokenKind.endOfInput
              text := ""
              span := psLexSpan position position
            }]
          else
            match psLexReadToken ready with
            | Except.error error => Except.error error
            | Except.ok (token, next) =>
                match psLexAllWithFuel fuel next with
                | Except.error error => Except.error error
                | Except.ok rest => Except.ok (token :: rest)

def psLex (source : String) : Except PsLexError (List PsToken) :=
  let cursor := psLexCursorFromString source
  psLexAllWithFuel (source.toList.length + 1) cursor
