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
