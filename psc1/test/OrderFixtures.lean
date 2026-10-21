def natOrderCase (flag : Bool) : Nat :=
  let a : Nat := if flag then 2 else 0;
  (if a < 1 then 1 else 0) + (if a ≤ 1 then 2 else 0) +
    (if a > 1 then 4 else 0) + (if a ≥ 1 then 8 else 0) +
    (if a <= a then 16 else 0) + (if a < a then 0 else 32)

def intOrderCase (flag : Bool) : Nat :=
  let a : Int := if flag then -7 else 3;
  let b : Int := -2;
  (if a < b then 1 else 0) + (if a <= b then 2 else 0) +
    (if a > b then 4 else 0) + (if a >= b then 8 else 0) +
    (if b < 0 then 16 else 0) + (if b <= b then 32 else 0) +
    (if b < b then 0 else 64)

def largeOrderCase (flag : Bool) : Nat :=
  let n : Nat := if flag then 184467440737095516160 else 184467440737095516159;
  let i : Int := if flag then -184467440737095516161 else 184467440737095516161;
  (if n > 184467440737095516159 then 1 else 0) +
    (if n <= 184467440737095516160 then 2 else 0) +
    (if i < -184467440737095516160 then 4 else 0) +
    (if i >= -184467440737095516160 then 8 else 0)

partial def orderWhile (limit : Nat) : Id Nat := do
  let mut index : Nat := 0
  while index < limit do
    index := index + 1
  return index

def controlOrderCase (flag : Bool) : Nat :=
  let limit : Nat := if flag then 3 else 1;
  let relation : Prop := limit > 2;
  let value : Id Nat := (do
    let mut total : Nat := 0
    for n in [0, 1, 2, 3] do
      if n < limit then
        total := total + 1
      else
        pure ()
    return total
  );
  let observed : Nat := value;
  let counted : Nat := orderWhile limit;
  if relation then observed + counted + 10 else observed + counted

partial def operatorSpin (flag : Bool) : Bool := operatorSpin flag

def numericCase (flag : Bool) : Nat :=
  let n : Nat := if flag then 184467440737095516160 else 7;
  let integer : Int := if flag then -7 else 9;
  let intOk : Bool := ((integer + 3) * -2) == (if flag then 8 else -24) &&
    (integer - 3) == (if flag then -10 else 6);
  let saturation : Nat := 2 - 9;
  let zeroDiv : Nat := n / 0;
  let zeroMod : Nat := n % 0;
  let quotient : Nat := 17 / 5;
  let remainder : Nat := 17 % 5;
  let precedence : Nat := 2 + 3 * 4;
  let association : Nat := 10 - 3 - 2;
  let exactValue : Nat := (n + 1) * 3 - n;
  if intOk && saturation == 0 && zeroDiv == 0 && zeroMod == n &&
      quotient == 3 && remainder == 2 && precedence == 14 && association == 5 then exactValue else 0

def shortCircuitCase (flag : Bool) : Nat :=
  let andValue : Bool := flag && (if flag then true else operatorSpin flag);
  let orValue : Bool := flag || (if flag then operatorSpin flag else false);
  let negated : Bool := !flag == (if flag then false else true);
  if andValue == flag && orValue == flag && negated then
    if flag then 17 else 19
  else 0
