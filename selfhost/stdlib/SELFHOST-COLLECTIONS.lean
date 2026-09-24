import ProofScript.Data.Option
import ProofScript.Data.Prod
import ProofScript.Data.Result
import ProofScript.Data.List

def collectionOption : Option Nat :=
  optionMap (fun (x : Nat) => x) (Option.some 1)

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
  listMap (fun (x : Nat) => x) collectionList
