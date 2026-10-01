def oneNatIdentity (n : Nat) : Nat :=
  match n with
  | Nat.zero => Nat.zero
  | Nat.succ k => Nat.succ (oneNatIdentity k)

def oneNatSum (n : Nat) : Nat :=
  match n with
  | Nat.zero => 0
  | Nat.succ k => Nat.add k (oneNatSum k)

def oneNatCaptured (bias : Nat) (n : Nat) : Nat :=
  match n with
  | Nat.zero => bias
  | Nat.succ k => Nat.add bias (oneNatCaptured bias k)

def oneNatLarge (base : Nat) (n : Nat) : Nat :=
  match n with
  | Nat.zero => base
  | Nat.succ k => Nat.succ (oneNatLarge base k)
