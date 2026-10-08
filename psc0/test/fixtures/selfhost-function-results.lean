def replayReturnedFunction (value : Nat) : Nat -> Nat :=
  match value with
  | Nat.zero => fun (other : Nat) => Nat.add other 7
  | Nat.succ previous => fun (other : Nat) => Nat.add previous other

def replayNestedFunction (__ps_eta_0 : Nat) : Nat -> Nat -> Nat :=
  fun (middle : Nat) =>
    match middle with
    | Nat.zero => fun (last : Nat) => Nat.add __ps_eta_0 last
    | Nat.succ previous => fun (last : Nat) => Nat.add __ps_eta_0 (Nat.add previous last)

def replayPartialFunction : Nat -> Nat := replayReturnedFunction 3

def replayFuelFunction (fuel : Nat) : Nat -> Nat :=
  match fuel with
  | Nat.zero => fun (value : Nat) => value
  | Nat.succ remaining =>
      let smaller : Nat -> Nat := replayFuelFunction remaining;
      fun (value : Nat) => smaller (Nat.succ value)

def replayReverseAcc {alpha : Type} (values : List alpha) : List alpha -> List alpha :=
  match values with
  | List.nil => fun (acc : List alpha) => acc
  | List.cons value rest =>
      let smaller : List alpha -> List alpha := replayReverseAcc rest;
      fun (acc : List alpha) => smaller (List.cons value acc)

def replayReverse {alpha : Type} (values : List alpha) : List alpha :=
  let pending : List alpha -> List alpha := replayReverseAcc values;
  pending List.nil

def replayReversed : List Nat := replayReverse (List.cons 7 (List.cons 9 List.nil))

def replayPairProjection (left : Nat) (right : Nat) : Nat :=
  let pair : Prod Nat Nat := Prod.mk left right;
  Nat.add (Prod.fst pair) (Prod.snd pair)

structure ReplayBox where
  value : Nat

def replayRecordFunction (first : Nat) : Nat -> ReplayBox :=
  fun (second : Nat) => ReplayBox.mk (Nat.add first second)

def replayPartialOuter (first : Nat) : Nat -> Nat := replayReturnedFunction first

def replayIgnoredParameters (_ : Nat) (_ : Nat) (value : Nat) : Nat := value

def replayStrictBindings (arguments : Nat) (eval : Nat) : Nat := Nat.add arguments eval

def replayShadowedBinding (value : Nat) : Nat :=
  let value : Nat := Nat.add value 1;
  let value : Nat := Nat.add value 2;
  value

def replayStructureShadow (value : ReplayBox) : Nat :=
  match value with
  | ReplayBox.mk field =>
      match ReplayBox.mk (Nat.succ field) with
      | ReplayBox.mk result => result
