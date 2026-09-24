import Ps.Foundation.Source

inductive PsTokenKind where
  | identifier
  | natural
  | string
  | character
  | symbol
  | endOfInput

structure PsToken where
  kind : PsTokenKind
  text : String
  span : PsSourceSpan
