def psListLength {alpha : Type} (values : List alpha) : Nat :=
  match values with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (psListLength rest)

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

def psListAppend {alpha : Type} (left : List alpha) : List alpha -> List alpha :=
  match left with
  | List.nil => fun (right : List alpha) => right
  | List.cons value rest =>
      let smaller : List alpha -> List alpha := psListAppend rest;
      fun (right : List alpha) => List.cons value (smaller right)

def psListMap {alpha beta : Type} (convert : alpha -> beta) (values : List alpha) : List beta :=
  match values with
  | List.nil => List.nil
  | List.cons value rest => List.cons (convert value) (psListMap convert rest)

def psListMapExcept {alpha beta error : Type}
    (convert : alpha -> Except error beta) (values : List alpha) : Except error (List beta) :=
  match values with
  | List.nil => Except.ok List.nil
  | List.cons value rest =>
      match convert value with
      | Except.error failure => Except.error failure
      | Except.ok result =>
          match psListMapExcept convert rest with
          | Except.error failure => Except.error failure
          | Except.ok results => Except.ok (List.cons result results)

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
