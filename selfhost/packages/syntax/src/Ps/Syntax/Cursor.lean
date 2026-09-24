import Ps.Foundation.Source

structure PsLexCursor where
  remaining : List Char
  position : PsSourcePos

structure PsLexStep where
  char : Char
  cursor : PsLexCursor

def psLexCursorFromString (source : String) : PsLexCursor :=
  {
    remaining := source.toList
    position := { byteOffset := 0, line := 1, column := 1 }
  }

def psLexCursorDone (cursor : PsLexCursor) : Bool :=
  match cursor.remaining with
  | [] => true
  | _ => false

def psLexCursorPeek (cursor : PsLexCursor) : Option Char :=
  match cursor.remaining with
  | [] => none
  | char :: _ => some char

def psLexAdvancePosition (position : PsSourcePos) (char : Char) : PsSourcePos :=
  if char == '\n' then
    {
      byteOffset := position.byteOffset + char.utf8Size
      line := position.line + 1
      column := 1
    }
  else
    {
      byteOffset := position.byteOffset + char.utf8Size
      line := position.line
      column := position.column + 1
    }

def psLexCursorAdvance (cursor : PsLexCursor) : Option PsLexStep :=
  match cursor.remaining with
  | [] => none
  | char :: rest =>
      some {
        char := char
        cursor := {
          remaining := rest
          position := psLexAdvancePosition cursor.position char
        }
      }

def psLexCursorPeekSecond (cursor : PsLexCursor) : Option Char :=
  match cursor.remaining with
  | _ :: second :: _ => some second
  | _ => none
