import JsonRecords.Input
import JsonRecords.Transform

def pairCase (flag : Bool) : Nat := recordObservation (pairCaseInput flag)

def scalarCase (flag : Bool) : Nat := recordObservation (scalarCaseInput flag)

def loneCase (flag : Bool) : Nat := recordObservation (loneCaseInput flag)

def badPairCase (flag : Bool) : Nat := recordObservation (badPairCaseInput flag)

def truncatedCase (flag : Bool) : Nat := recordObservation (truncatedCaseInput flag)

def mixedCase (flag : Bool) : Nat := recordObservation (mixedCaseInput flag)

def scalarDecoderCase (flag : Bool) : Nat :=
  let source : String := if flag then "D83D\\uDE00" else "DFFF";
  match jsonReadUnicode4 source 0 with
  | Result.ok value => 2
  | Result.error error =>
      match error with
      | JsonError.invalidUnicode => 1
      | _ => 2

def separatorCase (flag : Bool) : Nat :=
  let source : String := if flag then "[1,  ]" else "{\"text\":\"A\", }";
  match jsonParse source with
  | Result.error _ => 1
  | Result.ok _ => 0
