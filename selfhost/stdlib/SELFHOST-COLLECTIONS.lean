import ProofScript.Data.Option
import ProofScript.Data.Prod
import ProofScript.Data.Result
import ProofScript.Data.List
import ProofScript.Data.Map
import ProofScript.Data.Set

def collectionIdentityNat (x : Nat) : Nat :=
  x

def collectionOption : Option Nat :=
  optionMap collectionIdentityNat (Option.some 1)

def collectionPair : Prod Nat Bool :=
  product 2 true

def collectionPairFirst : Nat :=
  productFst collectionPair

def collectionResult : Result Nat String :=
  resultFromOption collectionOption "missing"

def collectionList : List Nat :=
  List.cons 1 (List.cons 2 List.nil)

def collectionLength : Nat :=
  listLength collectionList

def collectionMapped : List Nat :=
  listMap collectionIdentityNat collectionList

def compareAlwaysEq (left : Nat) (right : Nat) : Ordering :=
  Ordering.eq

def collectionMap : Map Nat String :=
  mapInsert compareAlwaysEq 1 "one" Map.empty

def collectionMapLookup : Option String :=
  mapFindOption compareAlwaysEq 1 collectionMap

def collectionSet : Set Nat :=
  setInsert compareAlwaysEq 1 (setEmpty Unit.unit)

def collectionSetContains : Bool :=
  setContains compareAlwaysEq 1 collectionSet
