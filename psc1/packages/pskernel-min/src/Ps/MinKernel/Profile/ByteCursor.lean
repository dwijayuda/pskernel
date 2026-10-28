-- Indexed byte access for the C1 representation decision.
-- No parser, declaration admission or public checker entry is introduced.
inductive PsMinByteCursorError where
  | endOfInput
  | byteRange
  | incomplete

structure PsMinByteCursorState where
  offset : Nat
  digest : Nat

def psMinByteDigestStep (digest : Nat) (byte : Nat) : Nat :=
  Nat.mod (Nat.add (Nat.mul digest 257) byte) 65521

def psMinByteCursorRead (size : Nat) (byteAt : Nat -> Nat) (offset : Nat) :
    Except PsMinByteCursorError Nat :=
  if Nat.blt offset size then
    let byte := byteAt offset;
    if Nat.ble byte 255 then Except.ok byte
    else Except.error PsMinByteCursorError.byteRange
  else Except.error PsMinByteCursorError.endOfInput

def psMinByteCursorWalk
    (remaining : Nat) (size : Nat) (byteAt : Nat -> Nat) :
    PsMinByteCursorState -> Except PsMinByteCursorError PsMinByteCursorState :=
  match remaining with
  | Nat.zero =>
      fun (state : PsMinByteCursorState) =>
        if Nat.beq state.offset size then Except.ok state
        else Except.error PsMinByteCursorError.incomplete
  | Nat.succ rest =>
      let smaller : PsMinByteCursorState -> Except PsMinByteCursorError PsMinByteCursorState :=
        psMinByteCursorWalk rest size byteAt;
      fun (state : PsMinByteCursorState) =>
        match psMinByteCursorRead size byteAt state.offset with
        | Except.error error => Except.error error
        | Except.ok byte =>
            smaller (PsMinByteCursorState.mk (Nat.succ state.offset)
              (psMinByteDigestStep state.digest byte))

-- Scalar bridge for native/generated experiments. 65521 is outside the residue
-- range and denotes refusal. A digest is not an admission verdict.
def psMinByteCursorDigest (size : Nat) (byteAt : Nat -> Nat) : Nat :=
  match psMinByteCursorWalk size size byteAt (PsMinByteCursorState.mk 0 0) with
  | Except.error _ => 65521
  | Except.ok state => state.digest
