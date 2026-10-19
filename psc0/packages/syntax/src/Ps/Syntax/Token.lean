import Ps.Foundation.Source

inductive PsTokenKind where
  | identifier
  | natural
  | scientific
  | string
  | character
  | symbol
  | endOfInput

def psTokenKindEq
    (left : PsTokenKind)
    (right : PsTokenKind) : Bool :=
  match left with
  | PsTokenKind.identifier =>
      match right with
      | PsTokenKind.identifier => true
      | _ => false
  | PsTokenKind.natural =>
      match right with
      | PsTokenKind.natural => true
      | _ => false
  | PsTokenKind.scientific =>
      match right with
      | PsTokenKind.scientific => true
      | _ => false
  | PsTokenKind.string =>
      match right with
      | PsTokenKind.string => true
      | _ => false
  | PsTokenKind.character =>
      match right with
      | PsTokenKind.character => true
      | _ => false
  | PsTokenKind.symbol =>
      match right with
      | PsTokenKind.symbol => true
      | _ => false
  | PsTokenKind.endOfInput =>
      match right with
      | PsTokenKind.endOfInput => true
      | _ => false

structure PsToken where
  kind : PsTokenKind
  text : String
  span : PsSourceSpan

-- Keep raw spelling on tokens so an escaped keyword is never classified as
-- grammar punctuation. Decode only at the identifier-to-syntax boundary.
def psTokenIdentifierEscaped (token : PsToken) : Bool :=
  psTokenKindEq token.kind .identifier &&
    token.text.startsWith "«" && token.text.endsWith "»"

def psTokenIdentifierText (token : PsToken) : String :=
  if psTokenIdentifierEscaped token then
    String.ofList ((token.text.toList.drop 1).dropLast)
  else token.text
