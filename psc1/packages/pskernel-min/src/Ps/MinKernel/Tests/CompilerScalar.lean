-- R5 integration fixture only; excluded from the connected checker runtime.
def psR5Add (a : Nat) (b : Nat) : Nat := Nat.add a b

def psR5Sub (a : Nat) (b : Nat) : Nat := Nat.sub a b

def psR5Choose (flag : Bool) (a : Nat) (b : Nat) : Nat :=
  if flag then Nat.add a b else Nat.sub a b

def psR5Three (a : Nat) (b : Nat) (c : Nat) : Nat := Nat.add a (Nat.add b c)

def psR5Capture (a : Nat) (b : Nat) (c : Nat) : Nat :=
  let pending : Nat -> Nat := psR5Three (Nat.add a 1) (Nat.add b 2);
  pending c

def psR5UseClosure (seed : Nat) (value : Nat) : Nat :=
  let captured := Nat.add seed 1;
  let fn : Nat -> Nat := fun (arg : Nat) => Nat.add captured arg;
  fn value
