import Ps.Foundation.List
import Ps.Foundation.Name
import Ps.Foundation.Text
import Ps.Bridge.Json
import Ps.Foundation.Source
import Ps.Foundation.StringSet

def extendedSeed : PsName := PsName.anonymous

def extendedDouble (value : Nat) : Nat := Nat.mul value 2

def extendedSum (values : List Nat) : Nat :=
  match values with
  | List.nil => 0
  | List.cons value rest => Nat.add value (extendedSum rest)

def extendedNumbers (value : Nat) : Nat :=
  let values : List Nat :=
    List.cons value (List.cons (Nat.add value 1) (List.cons (Nat.add value 2) List.nil));
  extendedSum
    (psListMap extendedDouble (psListTake 3 (psListReverse (psListAppend values values))))

def extendedNameText (value : Nat) : String :=
  let names : List PsName :=
    List.cons (psNameAppendNum extendedSeed value)
      (List.cons (psNameAppendStr extendedSeed "café🌱") List.nil);
  psTextJoin "/" (psListMap psNameToString names)

def extendedPairs (value : Nat) : Nat :=
  psListLength
    (psListZip
      (List.cons value (List.cons (Nat.add value 1) List.nil))
      (List.cons "a" (List.cons "b" (List.cons "c" List.nil))))

def extendedCurried (left : Nat) : Nat -> Nat :=
  fun (right : Nat) => Nat.add left right

def extendedCurriedUse (left right : Nat) : Nat :=
  extendedCurried left right

def extendedCanonical (source : String) : String :=
  match psJsonParse source with
  | Except.error _ => "parse-error"
  | Except.ok value =>
      match psJsonEncodeCanonical value with
      | Except.error _ => "encode-error"
      | Except.ok text => text

def extendedDepth (name : PsName) : Nat := psNameDepth name

def extendedSame (left right : PsName) : Bool := psNameEq left right


def extendedGenericLeft {alpha : Type} (left : alpha) : alpha -> alpha :=
  fun (_right : alpha) => left

def extendedGenericResult (value : Nat) : Nat :=
  extendedGenericLeft value (Nat.add value 1)

def extendedGenericString (text : String) : String :=
  extendedGenericLeft text "ignored"

def partitionedSetHas (key : String) : Bool :=
  let keys : List String := List.cons "café🌱" (List.cons "present" (List.cons "café🌱" List.nil));
  psStringSetContains (psStringSetFromList keys) key

def partitionedSpan : PsSourceSpan := {
  start := { byteOffset := 0, line := 1, column := 1 }
  stop := { byteOffset := 41, line := 1, column := 42 }
}

def partitionedColumn (span : PsSourceSpan) : Nat := span.stop.column
