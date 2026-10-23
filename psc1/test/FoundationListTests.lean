import Ps.Foundation.List
import FoundationListReference

private theorem reverse_acc_eq (values acc : List alpha) :
    psListReverseAcc values acc = values.reverse ++ acc := by
  induction values generalizing acc with
  | nil => rfl
  | cons head tail ih =>
      simp [psListReverseAcc, ih, List.reverse_cons, List.append_assoc]

private theorem reverse_eq (values : List alpha) : psListReverse values = values.reverse := by
  simp [psListReverse, reverse_acc_eq]

private theorem ref_length_eq (values : List alpha) :
    FoundationListReference.psListLength values = values.length := by
  induction values with
  | nil => rfl
  | cons head tail ih => simp [FoundationListReference.psListLength, ih]

private theorem length_acc_eq (values : List alpha) (count : Nat) :
    psListLengthAcc values count = count + values.length := by
  induction values generalizing count with
  | nil => simp [psListLengthAcc]
  | cons head tail ih =>
      simp [psListLengthAcc, ih, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]

theorem foundation_length_eq (values : List alpha) :
    psListLength values = FoundationListReference.psListLength values := by
  simp [psListLength, length_acc_eq, ref_length_eq]

private theorem ref_append_eq (left right : List alpha) :
    FoundationListReference.psListAppend left right = left ++ right := by
  induction left with
  | nil => rfl
  | cons head tail ih => simp [FoundationListReference.psListAppend, ih]

theorem foundation_append_eq (left right : List alpha) :
    psListAppend left right = FoundationListReference.psListAppend left right := by
  simp [psListAppend, reverse_acc_eq, reverse_eq, ref_append_eq]

private theorem ref_map_eq (convert : alpha -> beta) (values : List alpha) :
    FoundationListReference.psListMap convert values = values.map convert := by
  induction values with
  | nil => rfl
  | cons head tail ih => simp [FoundationListReference.psListMap, ih]

private theorem map_acc_eq (convert : alpha -> beta) (values : List alpha) (acc : List beta) :
    psListMapAcc convert values acc = acc.reverse ++ values.map convert := by
  induction values generalizing acc with
  | nil => simp [psListMapAcc, reverse_eq]
  | cons head tail ih =>
      simp [psListMapAcc, ih, List.reverse_cons, List.append_assoc]

theorem foundation_map_eq (convert : alpha -> beta) (values : List alpha) :
    psListMap convert values = FoundationListReference.psListMap convert values := by
  simp [psListMap, map_acc_eq, ref_map_eq]

private theorem map_except_acc_eq (convert : alpha -> Except error beta)
    (values : List alpha) (acc : List beta) :
    psListMapExceptAcc convert values acc =
      match FoundationListReference.psListMapExcept convert values with
      | .error failure => .error failure
      | .ok mapped => .ok (acc.reverse ++ mapped) := by
  induction values generalizing acc with
  | nil => simp [psListMapExceptAcc, FoundationListReference.psListMapExcept, reverse_eq]
  | cons head tail ih =>
      simp only [psListMapExceptAcc, FoundationListReference.psListMapExcept]
      cases result : convert head with
      | error failure => simp [result]
      | ok value =>
          simp only [result]
          rw [ih]
          cases rest : FoundationListReference.psListMapExcept convert tail with
          | error failure => simp [rest]
          | ok mapped => simp [rest, List.reverse_cons, List.append_assoc]

theorem foundation_map_except_eq (convert : alpha -> Except error beta) (values : List alpha) :
    psListMapExcept convert values = FoundationListReference.psListMapExcept convert values := by
  have h := map_except_acc_eq convert values []
  cases result : FoundationListReference.psListMapExcept convert values with
  | error failure => simpa [psListMapExcept, result] using h
  | ok mapped => simpa [psListMapExcept, result] using h

private theorem take_acc_eq (count : Nat) (values acc : List alpha) :
    psListTakeAcc count values acc =
      acc.reverse ++ FoundationListReference.psListTake count values := by
  induction count generalizing values acc with
  | zero => simp [psListTakeAcc, FoundationListReference.psListTake, reverse_eq]
  | succ remaining ih =>
      cases values with
      | nil => simp [psListTakeAcc, FoundationListReference.psListTake, reverse_eq]
      | cons head tail =>
          simp [psListTakeAcc, FoundationListReference.psListTake, ih, List.reverse_cons, List.append_assoc]

theorem foundation_take_eq (count : Nat) (values : List alpha) :
    psListTake count values = FoundationListReference.psListTake count values := by
  simp [psListTake, take_acc_eq]

private theorem zip_acc_eq (left : List alpha) (right : List beta) (acc : List (alpha × beta)) :
    psListZipAcc left right acc =
      acc.reverse ++ FoundationListReference.psListZip left right := by
  induction left generalizing right acc with
  | nil => simp [psListZipAcc, FoundationListReference.psListZip, reverse_eq]
  | cons head tail ih =>
      cases right with
      | nil => simp [psListZipAcc, FoundationListReference.psListZip, reverse_eq]
      | cons other others =>
          simp [psListZipAcc, FoundationListReference.psListZip, ih, List.reverse_cons, List.append_assoc]

theorem foundation_zip_eq (left : List alpha) (right : List beta) :
    psListZip left right = FoundationListReference.psListZip left right := by
  simp [psListZip, zip_acc_eq]

#print axioms foundation_map_eq
#print axioms foundation_map_except_eq

def runFoundationListTests : IO Unit := do
  let values := List.range 100000
  if psListLength values != 100000 then throw (IO.userError "list length")
  if psListMap Nat.succ values != values.map Nat.succ then throw (IO.userError "list map/order")
  if psListAppend values [100000] != values ++ [100000] then throw (IO.userError "list append/order")
  if psListTake 1000 values != values.take 1000 then throw (IO.userError "list take")
  if psListZip values [5,6] != [(0,5),(1,6)] then throw (IO.userError "list zip truncation/order")
  let refuse : Nat -> Except Nat Nat := fun n => if n == 17 then Except.error n else Except.ok (n+1)
  if psListMapExcept refuse values != Except.error 17 then throw (IO.userError "first error")
  let accept : Nat -> Except Nat Nat := fun n => Except.ok (n+1)
  if psListMapExcept accept values != Except.ok (values.map Nat.succ) then throw (IO.userError "mapExcept order")
  IO.println "PSC1_FOUNDATION_LIST: six all-input retained API equalities;100000-element native traversal; ordered mapping/first-error/truncation"
