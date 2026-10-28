import Ps.Foundation.List

/-! Small persistent traversals used by portable module generation. These keep
the existing left-to-right evaluation order and do not use host list methods. -/

def psListAll {alpha : Type} (predicate : alpha -> Bool) (values : List alpha) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest => if predicate value then psListAll predicate rest else false

def psListFilterAcc {alpha : Type} (predicate : alpha -> Bool)
    (values acc : List alpha) : List alpha :=
  match values with
  | List.nil => psListReverse acc
  | List.cons value rest =>
      psListFilterAcc predicate rest (if predicate value then List.cons value acc else acc)

def psListFilter {alpha : Type} (predicate : alpha -> Bool) (values : List alpha) : List alpha :=
  psListFilterAcc predicate values []

def psListFind {alpha : Type} (predicate : alpha -> Bool) (values : List alpha) : Option alpha :=
  match values with
  | List.nil => Option.none
  | List.cons value rest =>
      if predicate value then Option.some value else psListFind predicate rest

def psListFilterMapAcc {alpha beta : Type} (convert : alpha -> Option beta)
    (values : List alpha) (acc : List beta) : List beta :=
  match values with
  | List.nil => psListReverse acc
  | List.cons value rest =>
      match convert value with
      | Option.none => psListFilterMapAcc convert rest acc
      | Option.some result => psListFilterMapAcc convert rest (List.cons result acc)

def psListFilterMap {alpha beta : Type} (convert : alpha -> Option beta)
    (values : List alpha) : List beta :=
  psListFilterMapAcc convert values []

def psListFlattenAcc {alpha : Type} (values : List (List alpha)) (acc : List alpha) : List alpha :=
  match values with
  | List.nil => psListReverse acc
  | List.cons value rest => psListFlattenAcc rest (psListReverseAcc value acc)

def psListFlatten {alpha : Type} (values : List (List alpha)) : List alpha :=
  psListFlattenAcc values []

def psListFlatMap {alpha beta : Type} (convert : alpha -> List beta)
    (values : List alpha) : List beta :=
  psListFlatten (psListMap convert values)

def psListHeadOption {alpha : Type} (values : List alpha) : Option alpha :=
  match values with
  | List.nil => Option.none
  | List.cons value _ => Option.some value

def psListTail {alpha : Type} (values : List alpha) : List alpha :=
  match values with
  | List.nil => []
  | List.cons _ rest => rest

def psListGetOption {alpha : Type} (values : List alpha) : Nat -> Option alpha :=
  match values with
  | List.nil => fun (_index : Nat) => Option.none
  | List.cons value rest =>
      let smaller : Nat -> Option alpha := psListGetOption rest;
      fun (index : Nat) =>
        match index with
        | Nat.zero => Option.some value
        | Nat.succ remaining => smaller remaining

def psListFilterExceptAcc {alpha error : Type} (predicate : alpha -> Except error Bool)
    (values acc : List alpha) : Except error (List alpha) :=
  match values with
  | List.nil => Except.ok (psListReverse acc)
  | List.cons value rest =>
      match predicate value with
      | Except.error reason => Except.error reason
      | Except.ok keep =>
          psListFilterExceptAcc predicate rest (if keep then List.cons value acc else acc)

def psListFilterExcept {alpha error : Type} (predicate : alpha -> Except error Bool)
    (values : List alpha) : Except error (List alpha) :=
  psListFilterExceptAcc predicate values []

def psExceptMapError {alpha before after : Type} (convert : before -> after)
    (result : Except before alpha) : Except after alpha :=
  match result with
  | Except.ok value => Except.ok value
  | Except.error reason => Except.error (convert reason)

