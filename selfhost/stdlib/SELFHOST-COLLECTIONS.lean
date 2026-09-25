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

def collectionMap : Map Nat String :=
  mapInsert orderingNat 2 "two"
    (mapInsert orderingNat 1 "one" Map.empty)

def collectionMapLookup : Option String :=
  mapFindOption orderingNat 2 collectionMap

def collectionMapMissing : Option String :=
  mapFindOption orderingNat 3 collectionMap

def collectionSet : Set Nat :=
  setInsert orderingNat 2
    (setInsert orderingNat 1 (setEmpty Unit.unit))

def collectionSetContains : Bool :=
  setContains orderingNat 2 collectionSet

def collectionSetMissing : Bool :=
  setContains orderingNat 3 collectionSet
