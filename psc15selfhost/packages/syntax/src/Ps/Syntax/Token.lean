import Ps.Foundation.Source

inductive PsTokenKind where
  | identifier
  | natural
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
