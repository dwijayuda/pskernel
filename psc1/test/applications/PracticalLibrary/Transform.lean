import ProofScript.Data.Array

def libraryTransform (values : Array Nat) : Array Nat :=
  arrayMap (fun value => value + 1) (arraySet values 0 20)

def librarySum (values : Array Nat) : Nat :=
  arrayFoldl (fun total value => total + value) 0 values 0 (arraySize values)
