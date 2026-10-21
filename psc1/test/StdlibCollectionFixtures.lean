import ProofScript.Data.List
import ProofScript.Data.Array
import ProofScript.Data.Except

def listCase (flag : Bool) : Nat :=
  let values : List Nat := if flag then [3, 5, 7] else [];
  let reversed : List Nat := listReverse values;
  let head : Nat := match listHeadOption reversed with
    | Option.none => 0
    | Option.some value => value;
  listLength values * 100 + listLength (listAppend values [11]) * 10 + head

def arrayCase (flag : Bool) : Nat :=
  let original : Array Nat := #[3, 5, 7];
  let alias : Array Nat := original;
  let changed : Array Nat := arraySet original 0 11;
  let index : Nat := if flag then 0 else 9007199254740993123456789;
  let selected : Nat := match arrayGetOption changed index with
    | Option.none => 19
    | Option.some value => value;
  let empty : Array Nat := arrayEmpty ();
  let absent : Nat := match arrayGetOption empty 0 with
    | Option.none => 23
    | Option.some value => 999;
  selected * 100 + arrayGetD alias 0 0 * 10 + absent

def exceptCase (flag : Bool) : Nat :=
  let observed : Except Nat Nat := (do
    if flag then
      throw 7
    return 9
  );
  match observed with
  | Except.error error => error + 100
  | Except.ok value => value + 200

def arrayOperationsCase (flag : Bool) : Nat :=
  let values : Array Nat := if flag then #[] else #[3, 5];
  let appended : Array Nat := arrayPush values 7;
  let changed : Array Nat := arraySet appended 0 11;
  let mapped : Array Nat := arrayMap (fun value => value + 2) changed;
  let folded : Nat := arrayFoldl (fun total value => total * 10 + value) 0 mapped 0 (arraySize mapped);
  let empty : Array Nat := arrayEmpty ();
  let emptyFold : Nat := arrayFoldl (fun total value => total + value) 7 empty 0 9007199254740993123456789;
  folded + arraySize values * 10000 + arrayGetD values 0 19 + emptyFold
