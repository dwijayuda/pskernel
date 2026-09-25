inductive Ordering where
  | lt
  | eq
  | gt

def orderingReverse (value : Ordering) : Ordering :=
  match value with
  | Ordering.lt => Ordering.gt
  | Ordering.eq => Ordering.eq
  | Ordering.gt => Ordering.lt


def orderingNat (left : Nat) (right : Nat) : Ordering :=
  if Nat.blt left right then
    Ordering.lt
  else if Nat.blt right left then
    Ordering.gt
  else
    Ordering.eq
