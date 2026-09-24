import ProofScript.Data.Map

structure Set (α : Type) where
  entries : Map α Unit

def setEmpty {α : Type} : Set α :=
  Set.mk Map.empty

def setContains {α : Type}
    (compare : α -> α -> Ordering)
    (value : α)
    (set : Set α) : Bool :=
  mapContains compare value set.entries

def setInsert {α : Type}
    (compare : α -> α -> Ordering)
    (value : α)
    (set : Set α) : Set α :=
  Set.mk (mapInsert compare value Unit.unit set.entries)
