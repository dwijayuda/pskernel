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

def boundedUnit (value : Unit) : Nat := 1

-- The failed Bool-context attempt creates constraints in both generic numeric
-- operands. The recognized Prop fallback and later Int/Array contexts must be fresh.
def rollbackCase (flag : Bool) : Nat :=
  let chosen : Nat := if boundedId (if flag then 1 else 3) < boundedId 2 then 7 else 9;
  let integer : Int := boundedId (boundedId 7);
  let empty : Array Int := boundedId #[];
  chosen + Array.size empty + (if integer == 7 then 1 else 0)

def callCase (flag : Bool) : Nat :=
  let unit : Nat := boundedUnit (());
  boundedAfter unit (boundedDependent Nat flag (if flag then 23 else 29))

def ownerLambdaCase (flag : Bool) : Nat :=
  let callback : Nat -> Nat := fun input =>
    let nested : Id Nat := (do
      if flag then return input + 3
      return input + 5
    );
    nested;
  let inner : Nat := ownerProgram flag;
  let outer : Id Nat := (do
    let mut amount : Nat := 0
    for i in [0, 1] do
      for j in [0, 1] do
        amount := amount + 1
        if flag then return callback inner + i + j
    return amount + callback inner
  );
  outer

def joinsCase (flag : Bool) : Nat :=
  let program : Id Nat := (do
    let amount : Bool := flag
    let mut amount : Nat := if amount then 2 else 5
    let old : Nat -> Nat := fun value => amount + value
    if flag then
      amount := amount + 10
    else
      amount := amount + 20
    for value in [1, 2] do
      if Nat.beq value 1 then
        amount := amount + 1
      else
        amount := amount + 4
    return amount * 100 + old 3
  );
  program

def handlerScopeProgram (flag : Bool) : Except Nat Nat := do
  let mut amount : Nat := 2
  try {
    try {
      amount := 10
      if flag then throw 3
      return amount + 20
    } catch error => { throw (error + 4) }
  } catch error => { amount := amount + error }
  return amount + 100

def handlerScopeCase (flag : Bool) : Nat :=
  match handlerScopeProgram flag with
  | Except.error error => error + 1000
  | Except.ok value => value

def collectionController (flag : Bool) : CompilerM Unit Nat Nat Nat := do
  let mut order : Nat := 0
  let items : List Nat := if flag then [1, 2, 3] else []
  for value in items do
    let old : Nat <- compilerGet ()
    compilerSet (old + 1)
    order := order * 10 + value
  let values : Array Nat := if flag then #[4, 5] else #[6]
  for value in values do
    let old : Nat <- compilerGet ()
    compilerSet (old + 1)
    order := order * 10 + value
    if !flag then throw (order + old)
  return order

def collectionControllerCase (flag : Bool) : Nat :=
  let program : CompilerM Unit Nat Nat Nat := collectionController flag;
  match program.run () 7 with
  | Result.error error => error + 1000000
  | Result.ok pair => pair.fst * 100 + pair.snd

def rangeControllerCase (flag : Bool) : Nat :=
  let observed : Id Nat := (do
    let mut total : Nat := 0
    let lower : Nat := if flag then 2 else 5
    let upper : Nat := if flag then 5 else 2
    for value in [lower:upper] do
      total := total * 10 + value
    for value in [3:3] do
      total := 999
    return total
  );
  observed

def streamingControllerCase (flag : Bool) : Nat :=
  let observed : Id Nat := (do
    let mut total : Nat := 0
    let upper : Nat := if flag then 100000 else 1000000000000000000
    for value in [0:upper] do
      if !flag then return value + 17
      total := total + 1
    return total
  );
  observed

partial def boundedCountdown (count total : Nat) : Nat :=
  if Nat.beq count 0 then total else boundedCountdown (count - 1) (total + 1)

partial def boundedRecursiveSum (count : Nat) : Nat :=
  if Nat.beq count 0 then 0 else count + boundedRecursiveSum (count - 1)

partial def boundedRecursiveApply (step : Nat -> Nat) (count : Nat) : Nat :=
  if Nat.beq count 0 then step 3
  else boundedRecursiveApply (fun value => step (value + 1)) (count - 1)

def directRecursionCase (flag : Bool) : Nat := boundedCountdown (if flag then 100000 else 0) 7
def nonTailRecursionCase (flag : Bool) : Nat := boundedRecursiveSum (if flag then 100 else 20)
def higherOrderRecursionCase (flag : Bool) : Nat :=
  boundedRecursiveApply (fun value => value * 2) (if flag then 30 else 10)

def tupleProductsCase (flag : Bool) : Nat :=
  let program : Id Nat := (do
    let seed : Nat := if flag then 3 else 5
    let captured : Nat -> Nat := fun value => seed + value
    let (seed, (_, extra)) : Nat × (Bool × Nat) := (seed + 11, (flag, 13))
    let (grouped) : Nat := seed
    let () : Unit := ()
    return captured (grouped + extra)
  );
  program

namespace BoundedIdentity
def offset : Nat := 2
namespace Inner
def selected (flag : Bool) : Nat := if flag then offset else _root_.BoundedIdentity.offset
end Inner
end BoundedIdentity

namespace BoundedIdentity.Inner
def offset : Nat := 5
def choice (flag : Bool) : Nat :=
  let offset : Nat := if flag then 7 else 11;
  offset + selected flag + BoundedIdentity.Inner.offset + _root_.BoundedIdentity.offset
end BoundedIdentity.Inner

def BoundedIdentity.dotted (flag : Bool) : Nat := BoundedIdentity.Inner.choice flag
def namespaceCoreCase (flag : Bool) : Nat := BoundedIdentity.dotted flag
