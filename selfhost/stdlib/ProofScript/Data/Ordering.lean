inductive Ordering where
  | lt
  | eq
  | gt

def orderingReverse (value : Ordering) : Ordering :=
  match value with
  | Ordering.lt => Ordering.gt
  | Ordering.eq => Ordering.eq
  | Ordering.gt => Ordering.lt
