def countRenamed {alpha : Type} (values : List alpha) : Nat :=
  match values with
  | List.nil => 0
  | List.cons _ rest => Nat.add 1 (countRenamed rest)

def countSuccessor (values : List Nat) : Nat :=
  match values with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (countSuccessor rest)

def offsetCount (values : List Nat) : Nat :=
  match values with
  | List.nil => 1
  | List.cons _ rest => Nat.add 1 (offsetCount rest)

def doubleCount (values : List Nat) : Nat :=
  match values with
  | List.nil => 0
  | List.cons _ rest => Nat.add 2 (doubleCount rest)

def headSum (values : List Nat) : Nat :=
  match values with
  | List.nil => 0
  | List.cons value rest => Nat.add value (headSum rest)
