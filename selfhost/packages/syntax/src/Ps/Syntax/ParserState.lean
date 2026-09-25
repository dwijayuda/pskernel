import Ps.Foundation.Name
import Ps.Syntax.Token
import ProofScript.Data.List
import ProofScript.Data.Option

structure PsTokenCursor where
  remaining : List PsToken

structure PsTokenRead where
  token : PsToken
  cursor : PsTokenCursor

structure PsParseResult (α : Type) where
  value : α
  cursor : PsTokenCursor

inductive PsParseError where
  | fuelExhausted
  | unexpectedEnd (expected : String)
  | expectedText (expected : String) (actual : String) (span : PsSourceSpan)
  | expectedKind
      (expected : PsTokenKind)
      (actual : PsTokenKind)
      (span : PsSourceSpan)

def psTokenCursorFromTokens (tokens : List PsToken) : PsTokenCursor :=
  { remaining := tokens }

def psTokenCursorPeek (cursor : PsTokenCursor) : Option PsToken :=
  match cursor.remaining with
  | List.nil => Option.none
  | List.cons token rest => Option.some token

def psTokenCursorDone (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | Option.none => true
  | Option.some token => psTokenKindEq token.kind PsTokenKind.endOfInput

def psTokenCursorAdvance (cursor : PsTokenCursor) : Option PsTokenRead :=
  match cursor.remaining with
  | List.nil => Option.none
  | List.cons token rest =>
      Option.some {
        token := token
        cursor := { remaining := rest }
      }

def psTokenCursorAtText (cursor : PsTokenCursor) (text : String) : Bool :=
  match psTokenCursorPeek cursor with
  | Option.none => false
  | Option.some token => psStringEq token.text text

def psTokenCursorAtKind (cursor : PsTokenCursor) (kind : PsTokenKind) : Bool :=
  match psTokenCursorPeek cursor with
  | Option.none => false
  | Option.some token => psTokenKindEq token.kind kind

def psTokenCursorExpectText
    (cursor : PsTokenCursor)
    (expected : String) : Except PsParseError PsTokenRead :=
  match psTokenCursorAdvance cursor with
  | Option.none => Except.error (PsParseError.unexpectedEnd expected)
  | Option.some read =>
      if psStringEq read.token.text expected then
        Except.ok read
      else
        Except.error
          (PsParseError.expectedText expected read.token.text read.token.span)

def psTokenCursorExpectKind
    (cursor : PsTokenCursor)
    (expected : PsTokenKind) : Except PsParseError PsTokenRead :=
  match psTokenCursorAdvance cursor with
  | Option.none => Except.error (PsParseError.unexpectedEnd "token")
  | Option.some read =>
      if psTokenKindEq read.token.kind expected then
        Except.ok read
      else
        Except.error
          (PsParseError.expectedKind expected read.token.kind read.token.span)
