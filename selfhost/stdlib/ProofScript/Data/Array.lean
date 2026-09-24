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
