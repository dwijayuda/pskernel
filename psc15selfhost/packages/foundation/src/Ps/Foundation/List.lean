def psListLengthAcc {alpha : Type} (values : List alpha) : Nat -> Nat :=
  match values with
  | List.nil => fun (count : Nat) => count
  | List.cons _ rest =>
      let smaller : Nat -> Nat := psListLengthAcc rest;
      fun (count : Nat) => smaller (Nat.succ count)

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

def psListReverseAcc {alpha : Type} (values : List alpha) : List alpha -> List alpha :=
  match values with
  | List.nil => fun (acc : List alpha) => acc
  | List.cons value rest =>
      let smaller : List alpha -> List alpha := psListReverseAcc rest;
      fun (acc : List alpha) => smaller (List.cons value acc)

def psListReverse {alpha : Type} (values : List alpha) : List alpha :=
  psListReverseAcc values List.nil

-- Build the left spine with tail calls, then share the original right suffix.
def psListAppend {alpha : Type} (left : List alpha) (right : List alpha) : List alpha :=
  psListReverseAcc (psListReverse left) right

def psListMapWorker {alpha beta : Type}
    (convert : alpha -> beta) (values : List alpha) : List beta -> List beta :=
  match values with
  | List.nil => fun (reversed : List beta) => psListReverse reversed
  | List.cons value rest =>
      let smaller : List beta -> List beta := psListMapWorker convert rest;
      fun (reversed : List beta) => smaller (List.cons (convert value) reversed)

def psListMap {alpha beta : Type} (convert : alpha -> beta) (values : List alpha) : List beta :=
  psListMapWorker convert values List.nil

def psListMapExceptWorker {alpha beta error : Type}
    (convert : alpha -> Except error beta) (values : List alpha) :
    List beta -> Except error (List beta) :=
  match values with
  | List.nil => fun (reversed : List beta) => Except.ok (psListReverse reversed)
  | List.cons value rest =>
      let smaller : List beta -> Except error (List beta) :=
        psListMapExceptWorker convert rest;
      fun (reversed : List beta) =>
        match convert value with
        | Except.error failure => Except.error failure
        | Except.ok result => smaller (List.cons result reversed)

def psListMapExcept {alpha beta error : Type}
    (convert : alpha -> Except error beta) (values : List alpha) : Except error (List beta) :=
  psListMapExceptWorker convert values List.nil

-- Flatten successful chunks as they arrive. Preserve first-error order and
-- avoid one native continuation per element or per encoded byte.
def psListFlatMapExceptWorker {alpha beta error : Type}
    (convert : alpha -> Except error (List beta)) (values : List alpha) :
    List beta -> Except error (List beta) :=
  match values with
  | List.nil => fun (reversed : List beta) => Except.ok (psListReverse reversed)
  | List.cons value rest =>
      let smaller : List beta -> Except error (List beta) :=
        psListFlatMapExceptWorker convert rest;
      fun (reversed : List beta) =>
        match convert value with
        | Except.error failure => Except.error failure
        | Except.ok chunk => smaller (psListReverseAcc chunk reversed)

def psListFlatMapExcept {alpha beta error : Type}
    (convert : alpha -> Except error (List beta)) (values : List alpha) :
    Except error (List beta) :=
  psListFlatMapExceptWorker convert values List.nil

def psListTake {alpha : Type} (count : Nat) : List alpha -> List alpha :=
  match count with
  | Nat.zero => fun (_values : List alpha) => List.nil
  | Nat.succ remaining =>
      let smaller : List alpha -> List alpha := psListTake remaining;
      fun (values : List alpha) =>
        match values with
        | List.nil => List.nil
        | List.cons value rest => List.cons value (smaller rest)

def psListZip {alpha beta : Type} (left : List alpha) : List beta -> List (Prod alpha beta) :=
  match left with
  | List.nil => fun (_right : List beta) => List.nil
  | List.cons value rest =>
      let smaller : List beta -> List (Prod alpha beta) := psListZip rest;
      fun (right : List beta) =>
        match right with
        | List.nil => List.nil
        | List.cons other others => List.cons (Prod.mk value other) (smaller others)

-- Right folds evaluate the tail before the head without keeping a native frame
-- per list cell. This preserves rightmost-error precedence for Except folds.
def psListFoldLeftWorker {alpha beta : Type}
    (combine : alpha -> beta -> beta)
    (values : List alpha) : beta -> beta :=
  match values with
  | List.nil => fun (acc : beta) => acc
  | List.cons value rest =>
      let smaller : beta -> beta := psListFoldLeftWorker combine rest;
      fun (acc : beta) => smaller (combine value acc)

def psListFoldRight {alpha beta : Type}
    (combine : alpha -> beta -> beta)
    (values : List alpha)
    (initial : beta) : beta :=
  psListFoldLeftWorker combine (psListReverse values) initial

def psListFoldLeftExceptWorker {alpha beta error : Type}
    (combine : alpha -> beta -> Except error beta)
    (values : List alpha) : beta -> Except error beta :=
  match values with
  | List.nil => fun (acc : beta) => Except.ok acc
  | List.cons value rest =>
      let smaller : beta -> Except error beta :=
        psListFoldLeftExceptWorker combine rest;
      fun (acc : beta) =>
        match combine value acc with
        | Except.error failure => Except.error failure
        | Except.ok next => smaller next

def psListFoldRightExcept {alpha beta error : Type}
    (combine : alpha -> beta -> Except error beta)
    (values : List alpha)
    (initial : beta) : Except error beta :=
  psListFoldLeftExceptWorker combine (psListReverse values) initial
