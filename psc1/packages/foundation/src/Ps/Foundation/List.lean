-- Fully applied accumulators keep list spine traversal off the target call stack.
def psListLengthAcc {alpha : Type} (values : List alpha) (count : Nat) : Nat :=
  match values with
  | List.nil => count
  | List.cons _ rest => psListLengthAcc rest (Nat.succ count)

def psListLength {alpha : Type} (values : List alpha) : Nat :=
  psListLengthAcc values 0

def psListIsEmpty {alpha : Type} (values : List alpha) : Bool :=
  match values with
  | List.nil => true
  | List.cons _ _ => false

def psListAny {alpha : Type} (predicate : alpha -> Bool) (values : List alpha) : Bool :=
  match values with
  | List.nil => false
  | List.cons value rest =>
      if predicate value then true else psListAny predicate rest

def psListReverseAcc {alpha : Type}
    (values : List alpha) (acc : List alpha) : List alpha :=
  match values with
  | List.nil => acc
  | List.cons value rest => psListReverseAcc rest (List.cons value acc)

def psListReverse {alpha : Type} (values : List alpha) : List alpha :=
  psListReverseAcc values List.nil

def psListAppend {alpha : Type}
    (left : List alpha) (right : List alpha) : List alpha :=
  psListReverseAcc (psListReverse left) right

def psListMapAcc {alpha beta : Type} (convert : alpha -> beta)
    (values : List alpha) (acc : List beta) : List beta :=
  match values with
  | List.nil => psListReverse acc
  | List.cons value rest => psListMapAcc convert rest (List.cons (convert value) acc)

def psListMap {alpha beta : Type} (convert : alpha -> beta) (values : List alpha) : List beta :=
  psListMapAcc convert values List.nil

def psListMapExceptAcc {alpha beta error : Type}
    (convert : alpha -> Except error beta) (values : List alpha) (acc : List beta) :
    Except error (List beta) :=
  match values with
  | List.nil => Except.ok (psListReverse acc)
  | List.cons value rest =>
      match convert value with
      | Except.error failure => Except.error failure
      | Except.ok result => psListMapExceptAcc convert rest (List.cons result acc)

def psListMapExcept {alpha beta error : Type}
    (convert : alpha -> Except error beta) (values : List alpha) : Except error (List beta) :=
  psListMapExceptAcc convert values List.nil

def psListTakeAcc {alpha : Type} (count : Nat) (values : List alpha) (acc : List alpha) : List alpha :=
  match count with
  | Nat.zero => psListReverse acc
  | Nat.succ remaining =>
      match values with
      | List.nil => psListReverse acc
      | List.cons value rest => psListTakeAcc remaining rest (List.cons value acc)

def psListTake {alpha : Type} (count : Nat) (values : List alpha) : List alpha :=
  psListTakeAcc count values List.nil

def psListZipAcc {alpha beta : Type} (left : List alpha) (right : List beta)
    (acc : List (Prod alpha beta)) : List (Prod alpha beta) :=
  match left with
  | List.nil => psListReverse acc
  | List.cons value rest =>
      match right with
      | List.nil => psListReverse acc
      | List.cons other others => psListZipAcc rest others (List.cons (Prod.mk value other) acc)

def psListZip {alpha beta : Type}
    (left : List alpha) (right : List beta) : List (Prod alpha beta) :=
  psListZipAcc left right List.nil
