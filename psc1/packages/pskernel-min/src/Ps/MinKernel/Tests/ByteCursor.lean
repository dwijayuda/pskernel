import Ps.MinKernel.Profile.ByteCursor

-- Scalar test bridges; no byte parser/admission authority.
def psMinByteCursorReadCode (size : Nat) (byteAt : Nat -> Nat) (offset : Nat) : Nat :=
  match psMinByteCursorRead size byteAt offset with
  | Except.ok byte => byte
  | Except.error error =>
      match error with
      | PsMinByteCursorError.endOfInput => 256
      | PsMinByteCursorError.byteRange => 257
      | PsMinByteCursorError.incomplete => 258

def psMinByteCursorWalkCode (remaining : Nat) (size : Nat) (byteAt : Nat -> Nat) : Nat :=
  match psMinByteCursorWalk remaining size byteAt (PsMinByteCursorState.mk 0 0) with
  | Except.ok state => state.digest
  | Except.error _ => 65521
