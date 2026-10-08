import Ps.Foundation.Name

def psWasmIntDecimalMagnitudeWithFuel
    (remainingFuel : Nat) :
    String -> Nat -> Nat -> Nat :=
  match remainingFuel with
  | 0 =>
      fun (_text : String) (_position : Nat) (acc : Nat) =>
        acc
  | fuel + 1 =>
      let smaller : String -> Nat -> Nat -> Nat :=
        psWasmIntDecimalMagnitudeWithFuel fuel;
      fun (text : String) (position : Nat) (acc : Nat) =>
        if String.Internal.atEnd text (String.Pos.Raw.mk position) then
          acc
        else
          let char : Char :=
            String.Internal.get text (String.Pos.Raw.mk position);
          let digit : Nat :=
            Nat.sub (Char.toNat char) 48;
          let nextPosition : Nat :=
            String.Pos.Raw.byteIdx
              (String.Internal.next
                text
                (String.Pos.Raw.mk position));
          smaller
            text
            nextPosition
            (Nat.add (Nat.mul acc 10) digit)

def psWasmIntNegativeMagnitude
    (value : Int) : Bool × Nat :=
  let text : String := Int.repr value;
  let fuel : Nat := Nat.succ (String.utf8ByteSize text);
  if String.Internal.atEnd text (String.Pos.Raw.mk 0) then
    Prod.mk false 0
  else
    let first : Char :=
      String.Internal.get text (String.Pos.Raw.mk 0);
    if Nat.beq (Char.toNat first) 45 then
      let start : Nat :=
        String.Pos.Raw.byteIdx
          (String.Internal.next text (String.Pos.Raw.mk 0));
      Prod.mk
        true
        (psWasmIntDecimalMagnitudeWithFuel fuel text start 0)
    else
      Prod.mk
        false
        (psWasmIntDecimalMagnitudeWithFuel fuel text 0 0)

def psWasmIntSignMagnitude
    (value : Int) : Int × Nat :=
  let parts : Bool × Nat :=
    psWasmIntNegativeMagnitude value;
  let magnitude : Nat :=
    Prod.snd parts;
  let sign : Int :=
    if Prod.fst parts then
      Int.negSucc 0
    else if Nat.beq magnitude 0 then
      Int.ofNat 0
    else
      Int.ofNat 1;
  Prod.mk sign magnitude

def psWasmIntIsZero (value : Int) : Bool :=
  let parts : Bool × Nat :=
    psWasmIntNegativeMagnitude value;
  if Prod.fst parts then
    false
  else
    Nat.beq (Prod.snd parts) 0

def psWasmIntIsNegativeOne (value : Int) : Bool :=
  let parts : Bool × Nat :=
    psWasmIntNegativeMagnitude value;
  if Prod.fst parts then
    Nat.beq (Prod.snd parts) 1
  else
    false

def psWasmIntToNat (value : Int) : Nat :=
  let parts : Bool × Nat :=
    psWasmIntNegativeMagnitude value;
  if Prod.fst parts then
    0
  else
    Prod.snd parts

def psWasmIntEDivNat
    (value : Int)
    (divisor : Nat) : Int :=
  if Nat.beq divisor 0 then
    Int.ofNat 0
  else
    let parts : Bool × Nat :=
      psWasmIntNegativeMagnitude value;
    let magnitude : Nat :=
      Prod.snd parts;
    if Prod.fst parts then
      Int.negSucc
        (Nat.div
          (Nat.sub magnitude 1)
          divisor)
    else
      Int.ofNat (Nat.div magnitude divisor)

def psWasmIntEModNat
    (value : Int)
    (divisor : Nat) : Int :=
  if Nat.beq divisor 0 then
    value
  else
    let parts : Bool × Nat :=
      psWasmIntNegativeMagnitude value;
    let magnitude : Nat :=
      Prod.snd parts;
    if Prod.fst parts then
      Int.ofNat
        (Nat.sub
          (Nat.sub divisor 1)
          (Nat.mod
            (Nat.sub magnitude 1)
            divisor))
    else
      Int.ofNat (Nat.mod magnitude divisor)
