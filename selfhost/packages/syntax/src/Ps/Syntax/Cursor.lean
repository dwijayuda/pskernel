import Ps.Foundation.Source

structure PsLexCursor where
  remaining : List Char
  position : PsSourcePos

structure PsLexStep where
  char : Char
  cursor : PsLexCursor

partial def psLexStringToListFrom
    (source : String)
    (position : Nat) : List Char :=
  if
      String.Internal.atEnd
        source
        (String.Pos.Raw.mk position) then
    List.nil
  else
    let char : Char :=
      String.Internal.get
        source
        (String.Pos.Raw.mk position);
    let nextPosition : Nat :=
      String.Pos.Raw.byteIdx
        (String.Internal.next
          source
          (String.Pos.Raw.mk position));
    List.cons
      char
      (psLexStringToListFrom source nextPosition)

def psLexStringToList (source : String) : List Char :=
  psLexStringToListFrom source 0

def psLexCursorFromString (source : String) : PsLexCursor :=
  {
    remaining := psLexStringToList source
    position := { byteOffset := 0, line := 1, column := 1 }
  }

def psLexCursorDone (cursor : PsLexCursor) : Bool :=
  match cursor.remaining with
  | List.nil => true
  | List.cons head tail => false

def psLexCursorPeek (cursor : PsLexCursor) : Option Char :=
  match cursor.remaining with
  | List.nil => Option.none
  | List.cons char rest => Option.some char

def psLexAdvancePosition (position : PsSourcePos) (char : Char) : PsSourcePos :=
  let charSize : Nat :=
    String.utf8ByteSize (String.singleton char);
  if Nat.beq (Char.toNat char) 10 then
    {
      byteOffset := Nat.add position.byteOffset charSize
      line := Nat.add position.line 1
      column := 1
    }
  else
    {
      byteOffset := Nat.add position.byteOffset charSize
      line := position.line
      column := Nat.add position.column 1
    }

def psLexCursorAdvance (cursor : PsLexCursor) : Option PsLexStep :=
  match cursor.remaining with
  | List.nil => Option.none
  | List.cons char rest =>
      Option.some {
        char := char
        cursor := {
          remaining := rest
          position := psLexAdvancePosition cursor.position char
        }
      }

def psLexCursorPeekSecond (cursor : PsLexCursor) : Option Char :=
  match cursor.remaining with
  | List.nil => Option.none
  | List.cons first rest =>
      match rest with
      | List.nil => Option.none
      | List.cons second tail => Option.some second
