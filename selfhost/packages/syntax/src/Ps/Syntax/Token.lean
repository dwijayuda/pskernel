import Ps.Foundation.Source

inductive PsTokenKind where
  | identifier
  | natural
  | string
  | character
  | symbol
  | endOfInput

def psTokenKindEq : PsTokenKind -> PsTokenKind -> Bool
  | .identifier, .identifier => true
  | .natural, .natural => true
  | .string, .string => true
  | .character, .character => true
  | .symbol, .symbol => true
  | .endOfInput, .endOfInput => true
  | _, _ => false

structure PsToken where
  kind : PsTokenKind
  text : String
  span : PsSourceSpan
