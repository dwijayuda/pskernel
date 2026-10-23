import Lean

namespace PSC1StandardCollectionReference

def listCase (flag : Bool) : Nat :=
  let values : List Nat := if flag then [3, 5, 7] else []
  let reversed := List.reverse values
  let head := match reversed with
    | [] => 0
    | value :: _ => value
  List.length values * 100 + List.length (List.append values [11]) * 10 + head

def arrayCase (flag : Bool) : Nat :=
  let original : Array Nat := #[3, 5, 7]
  let alias := original
  let changed := Array.setIfInBounds original 0 11
  let index : Nat := if flag then 0 else 9007199254740993123456789
  let selected := match changed[index]? with
    | none => 19
    | some value => value
  let empty : Array Nat := #[]
  let absent := match empty[0]? with
    | none => 23
    | some _ => 999
  selected * 100 + Array.getD alias 0 0 * 10 + absent

def exceptCase (flag : Bool) : Nat :=
  let observed : Except Nat Nat := do
    if flag then throw 7
    return 9
  match observed with
  | .error error => error + 100
  | .ok value => value + 200

def arrayOperationsCase (flag : Bool) : Nat :=
  let values : Array Nat := if flag then #[] else #[3, 5]
  let appended := Array.push values 7
  let changed := Array.setIfInBounds appended 0 11
  let mapped := Array.map (fun value => value + 2) changed
  let folded := Array.foldl (fun total value => total * 10 + value) 0 mapped 0 mapped.size
  let empty : Array Nat := #[]
  let emptyFold := Array.foldl (fun total value => total + value) 7 empty 0 9007199254740993123456789
  folded + values.size * 10000 + Array.getD values 0 19 + emptyFold

end PSC1StandardCollectionReference

def main : IO Unit := do
  IO.println ("PSC1_STANDARD_COLLECTION_REFERENCE: " ++ (Lean.Json.mkObj [
    ("leanVersion",Lean.toJson Lean.versionString),
    ("leanCommit",Lean.toJson Lean.githash),
    ("listCaseFalse",Lean.toJson (toString (PSC1StandardCollectionReference.listCase false))),
    ("listCaseTrue",Lean.toJson (toString (PSC1StandardCollectionReference.listCase true))),
    ("arrayCaseFalse",Lean.toJson (toString (PSC1StandardCollectionReference.arrayCase false))),
    ("arrayCaseTrue",Lean.toJson (toString (PSC1StandardCollectionReference.arrayCase true))),
    ("exceptCaseFalse",Lean.toJson (toString (PSC1StandardCollectionReference.exceptCase false))),
    ("exceptCaseTrue",Lean.toJson (toString (PSC1StandardCollectionReference.exceptCase true))),
    ("arrayOperationsCaseFalse",Lean.toJson (toString (PSC1StandardCollectionReference.arrayOperationsCase false))),
    ("arrayOperationsCaseTrue",Lean.toJson (toString (PSC1StandardCollectionReference.arrayOperationsCase true)))
  ]).compress)
