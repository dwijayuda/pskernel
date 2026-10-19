import ProofScript.Data.Option

def arrayEmptyWithCapacity {α : Type}
    (capacity : Nat) : Array α :=
  Array.emptyWithCapacity capacity

def arraySize {α : Type}
    (xs : Array α) : Nat :=
  Array.size xs

def arrayPush {α : Type}
    (xs : Array α) (value : α) : Array α :=
  Array.push xs value

def arrayGetD {α : Type}
    (xs : Array α) (index : Nat) (fallback : α) : α :=
  Array.getD xs index fallback

def arraySetIfInBounds {α : Type}
    (xs : Array α) (index : Nat) (value : α) : Array α :=
  Array.setIfInBounds xs index value

def arrayMap {α : Type} {β : Type}
    (f : α -> β) (xs : Array α) : Array β :=
  Array.map f xs

def arrayFoldl {α : Type} {β : Type}
    (f : β -> α -> β)
    (init : β)
    (xs : Array α)
    (start : Nat)
    (stop : Nat) : β :=
  Array.foldl f init xs start stop


def arrayEmpty {α : Type}
    (unit : Unit) : Array α :=
  Array.emptyWithCapacity 0

def arraySome {α : Type}
    (value : α) : Option α :=
  Option.some value

def arrayGetOption {α : Type}
    (xs : Array α) (index : Nat) : Option α :=
  Array.getD
    (Array.map arraySome xs)
    index
    Option.none

def arraySet {α : Type}
    (xs : Array α) (index : Nat) (value : α) : Array α :=
  Array.setIfInBounds xs index value

def arrayAnyStep {α : Type}
    (predicate : α -> Bool)
    (found : Bool)
    (value : α) : Bool :=
  if found then true else predicate value

def arrayAny {α : Type}
    (predicate : α -> Bool)
    (xs : Array α) : Bool :=
  Array.foldl
    (arrayAnyStep predicate)
    false
    xs
    0
    (Array.size xs)

def arrayAllStep {α : Type}
    (predicate : α -> Bool)
    (accepted : Bool)
    (value : α) : Bool :=
  if accepted then predicate value else false

def arrayAll {α : Type}
    (predicate : α -> Bool)
    (xs : Array α) : Bool :=
  Array.foldl
    (arrayAllStep predicate)
    true
    xs
    0
    (Array.size xs)

def arrayFindStep {α : Type}
    (predicate : α -> Bool)
    (found : Option α)
    (value : α) : Option α :=
  match found with
  | Option.some current => Option.some current
  | Option.none =>
      if predicate value then Option.some value else Option.none

def arrayFindOption {α : Type}
    (predicate : α -> Bool)
    (xs : Array α) : Option α :=
  Array.foldl
    (arrayFindStep predicate)
    Option.none
    xs
    0
    (Array.size xs)
