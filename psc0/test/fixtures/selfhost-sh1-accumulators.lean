-- Ordinary authoring forms. The generated compiler must consume this raw file.
def sh1ReverseInto {alpha : Type}
    (items : List alpha) (out : List alpha) : List alpha :=
  match items with
  | List.nil => out
  | List.cons item tail => sh1ReverseInto tail (List.cons item out)

def sh1NatAcc (fuel : Nat) (total : Nat) : Nat :=
  match fuel with
  | Nat.zero => total
  | Nat.succ remaining => sh1NatAcc remaining (Nat.add total 3)

def sh1Swap (fuel : Nat) (left : Nat) (right : Nat) : Nat :=
  match fuel with
  | Nat.zero => left
  | Nat.succ remaining => sh1Swap remaining right left

def sh1StateBefore (state : Nat) (items : List Nat) : Nat :=
  match items with
  | List.nil => state
  | List.cons item tail => sh1StateBefore (Nat.add state item) tail

def sh1FunctionResult (fuel : Nat) (offset : Nat) : Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (value : Nat) => Nat.add offset value
  | Nat.succ remaining => sh1FunctionResult remaining (Nat.add offset 2)

def sh1WithProof {p : Prop} (h : p) (fuel : Nat) (state : Nat) : Nat :=
  match fuel with
  | Nat.zero => state
  | Nat.succ remaining => sh1WithProof h remaining (Nat.succ state)

def sh1Partial : Nat -> Nat := sh1NatAcc 4

-- Existing accepted source is retained as a correspondence reference.
def sh1WorkerReference (fuel : Nat) : Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (left : Nat) (right : Nat) => left
  | Nat.succ remaining =>
      let smaller : Nat -> Nat -> Nat := sh1WorkerReference remaining;
      fun (left : Nat) (right : Nat) => smaller right left

def sh1Shadow (state : Nat) (fuel : Nat) : Nat :=
  match fuel with
  | Nat.zero => state
  | Nat.succ state => sh1Shadow (Nat.succ state) state

def sh1OuterHypothesis (fuel : Nat) (state : Nat) : Nat :=
  match fuel with
  | Nat.zero => state
  | Nat.succ remaining =>
      match state with
      | Nat.zero => sh1OuterHypothesis remaining 1
      | Nat.succ ignored => sh1OuterHypothesis remaining (Nat.succ state)
