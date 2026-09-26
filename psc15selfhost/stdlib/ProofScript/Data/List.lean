import ProofScript.Data.Option

inductive List (α : Type) where
  | nil
  | cons (head : α) (tail : List α)

def listMap {α : Type} {β : Type}
    (f : α -> β) (xs : List α) : List β :=
  match xs with
  | List.nil => List.nil
  | List.cons head tail =>
      List.cons (f head) (listMap f tail)

def listAppend {α : Type}
    (xs : List α) (ys : List α) : List α :=
  match xs with
  | List.nil => ys
  | List.cons head tail =>
      List.cons head (listAppend tail ys)

def listLength {α : Type} (xs : List α) : Nat :=
  match xs with
  | List.nil => 0
  | List.cons head tail => listLength tail

def listHeadOption {α : Type}
    (xs : List α) : Option α :=
  match xs with
  | List.nil => Option.none
  | List.cons head tail => Option.some head

def listIsEmpty {α : Type} (xs : List α) : Bool :=
  match xs with
  | List.nil => true
  | List.cons head tail => false

def listHeadOrElse {α : Type}
    (xs : List α) (fallback : α) : α :=
  match xs with
  | List.nil => fallback
  | List.cons head tail => head



def listReverse {α : Type} (xs : List α) : List α :=
  match xs with
  | List.nil => List.nil
  | List.cons head tail =>
      listAppend
        (listReverse tail)
        (List.cons head List.nil)
