def replayTailSwap (fuel : Nat) : Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (left right : Nat) => left
  | Nat.succ remaining =>
      let smaller : Nat -> Nat -> Nat := replayTailSwap remaining;
      fun (left right : Nat) => smaller right left

def replayTailReverse (values : List Nat) : List Nat -> List Nat :=
  match values with
  | List.nil => fun (acc : List Nat) => acc
  | List.cons head rest =>
      let smaller : List Nat -> List Nat := replayTailReverse rest;
      fun (acc : List Nat) => smaller (List.cons head acc)

def replayTailFuel (fuel : Nat) : Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (value : Nat) => value
  | Nat.succ remaining =>
      let smaller : Nat -> Nat := replayTailFuel remaining;
      fun (value : Nat) => smaller (Nat.add value 1)

def replayNonTail (fuel : Nat) : Nat :=
  match fuel with
  | Nat.zero => 7
  | Nat.succ remaining => Nat.add 2 (replayNonTail remaining)

def replayEscapedTail (fuel : Nat) : Nat -> Nat :=
  let inner : Nat -> Nat := replayTailFuel fuel;
  inner
