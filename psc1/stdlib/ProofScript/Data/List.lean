import ProofScript.Data.Option

-- List and its constructors are owned by the checked Essential Core prelude.
-- These helpers extend that identity and compose with literals/finite loops.

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

def listLengthAcc {α : Type} (xs : List α) : Nat -> Nat :=
  match xs with
  | List.nil => fun (total : Nat) => total
  | List.cons _ tail =>
      fun (total : Nat) =>
        let smaller : Nat -> Nat := listLengthAcc tail;
        smaller (Nat.succ total)

def listLength {α : Type} (xs : List α) : Nat :=
  listLengthAcc xs 0

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



def listReverseAcc {α : Type} (xs : List α) : List α -> List α :=
  match xs with
  | List.nil => fun (reversed : List α) => reversed
  | List.cons head tail =>
      fun (reversed : List α) =>
        let smaller : List α -> List α := listReverseAcc tail;
        smaller (List.cons head reversed)

def listReverse {α : Type} (xs : List α) : List α :=
  listReverseAcc xs List.nil
