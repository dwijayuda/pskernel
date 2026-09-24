import ProofScript.Data.Option
import ProofScript.Data.Ordering

inductive Map (K : Type) (V : Type) where
  | empty
  | node (key : K) (value : V) (tail : Map K V)

def mapEmpty {K : Type} {V : Type} : Map K V :=
  Map.empty

def mapFindOption {K : Type} {V : Type}
    (compare : K -> K -> Ordering)
    (key : K)
    (map : Map K V) : Option V :=
  match map with
  | Map.empty => Option.none
  | Map.node current currentValue tail =>
      match compare key current with
      | Ordering.lt => Option.none
      | Ordering.eq => Option.some currentValue
      | Ordering.gt => mapFindOption compare key tail

def mapContains {K : Type} {V : Type}
    (compare : K -> K -> Ordering)
    (key : K)
    (map : Map K V) : Bool :=
  match map with
  | Map.empty => false
  | Map.node current currentValue tail =>
      match compare key current with
      | Ordering.lt => false
      | Ordering.eq => true
      | Ordering.gt => mapContains compare key tail

def mapInsert {K : Type} {V : Type}
    (compare : K -> K -> Ordering)
    (key : K)
    (value : V)
    (map : Map K V) : Map K V :=
  match map with
  | Map.empty => Map.node key value Map.empty
  | Map.node current currentValue tail =>
      match compare key current with
      | Ordering.lt =>
          Map.node key value (Map.node current currentValue tail)
      | Ordering.eq =>
          Map.node current value tail
      | Ordering.gt =>
          Map.node current currentValue
            (mapInsert compare key value tail)
