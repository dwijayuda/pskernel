def replayNatCase (value : Nat) : Nat :=
  match value with
  | Nat.zero => 7
  | Nat.succ previous => previous

def replayNatSum (value : Nat) : Nat :=
  match value with
  | Nat.zero => 0
  | Nat.succ previous => Nat.add value (replayNatSum previous)

def replayNatSuccessor (value : Nat) : Nat :=
  Nat.succ (Nat.add Nat.zero value)
