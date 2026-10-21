import ProofScript.Compiler.Effect

def boundedId {A : Type} (value : A) : A := value
def boundedDependent {Tag : Type} (A : Type) (tag : Tag) (value : A) : A := value
def boundedAfter (count : Nat) {A : Type} (value : A) : A := value

def contextsCase (flag : Bool) : Nat :=
  let integer : Int := boundedId (boundedId 7);
  let pair : Prod Int Nat := (integer, if flag then 11 else 13);
  let empty : Array Int := #[];
  let apply : Nat -> Nat := fun value => value + 3;
  apply pair.snd + Array.size empty

def telescopeCase (flag : Bool) : Nat :=
  let integer : Int := boundedDependent Int true (boundedId 9);
  let observed : Nat := boundedAfter 0 (boundedDependent Nat flag (if flag then 17 else 19));
  let values : Array Int := #[integer];
  observed + Array.size values

def ownerProgram (flag : Bool) : Id Nat := do
  let mut amount : Nat := 2
  let inner : Nat <- (do
    if flag then return 7
    return 9
  )
  amount := amount + inner
  for value in [1, 2] do
    if flag then return amount + value
    amount := amount + value
  return amount + 10

def ownerCase (flag : Bool) : Nat := ownerProgram flag

def loopProgram (flag : Bool) : Id Nat := do
  let mut total : Nat := 0
  let values : Array Nat := if flag then #[2, 4] else #[]
  for value in values do
    total := total + value
  for value in [1, 3] do
    total := total + value
  let start : Nat := if flag then 2 else 5
  for index in [start:4] do
    total := total + index
  return total

def loopCase (flag : Bool) : Nat := loopProgram flag

def scopeProgram (flag : Bool) : Except Nat Nat := do
  let mut amount : Nat := 3
  let captured : Nat -> Nat := fun value => amount + value
  try
    amount := 10
    if flag then throw 7
    amount := amount + 1
  catch error =>
    amount := amount + error
  return amount + captured 2

def scopeCase (flag : Bool) : Nat :=
  match scopeProgram flag with
  | Except.error error => error + 1000
  | Except.ok value => value
