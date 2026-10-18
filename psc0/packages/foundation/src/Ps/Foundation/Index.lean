-- Persistent bounded-depth buckets. The caller owns hashing and collision
-- equality; bucket membership is never semantic evidence.
inductive PsBucketIndex (α : Type) where
  | empty
  | bucket (values : List α)
  | branch (left right : PsBucketIndex α)

def psBucketFind {α : Type} (fuel : Nat) (index : PsBucketIndex α)
    (hash : Nat) : List α :=
  match fuel with
  | 0 => match index with | .bucket values => values | _ => []
  | fuel + 1 => match index with
    | .branch left right =>
      psBucketFind fuel (if hash % 2 == 0 then left else right) (hash / 2)
    | _ => []

def psBucketInsert {α : Type} (fuel : Nat) (index : PsBucketIndex α)
    (hash : Nat) (value : α) : PsBucketIndex α :=
  match fuel with
  | 0 => .bucket (value :: psBucketFind 0 index hash)
  | fuel + 1 =>
    let (left, right) := match index with
      | .branch left right => (left, right)
      | _ => (.empty, .empty)
    if hash % 2 == 0 then .branch (psBucketInsert fuel left (hash / 2) value) right
    else .branch left (psBucketInsert fuel right (hash / 2) value)
