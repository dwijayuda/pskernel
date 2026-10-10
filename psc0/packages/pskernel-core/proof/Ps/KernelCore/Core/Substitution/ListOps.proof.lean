import Ps.KernelCore.Core.Substitution.ListOps

/-!
Foundational list-helper proofs for substitution/beta reasoning.

Unlike the API wrapper lemmas, these are reusable algebraic facts about the
portable substitution support code and are intended to feed later
Lift/Instantiate/Beta proofs.
-/

theorem psKernelExprListGet_nil
    (index : Nat) :
    psKernelExprListGet List.nil index = Option.none := by
  rfl

theorem psKernelExprListGet_cons_zero
    (head : PsKernelExpr)
    (tail : List PsKernelExpr) :
    psKernelExprListGet (List.cons head tail) Nat.zero =
      Option.some head := by
  rfl

theorem psKernelExprListGet_cons_succ
    (head : PsKernelExpr)
    (tail : List PsKernelExpr)
    (index : Nat) :
    psKernelExprListGet
        (List.cons head tail)
        (Nat.succ index) =
      psKernelExprListGet tail index := by
  rfl

theorem psKernelExprListTake_zero
    (values : List PsKernelExpr) :
    psKernelExprListTake Nat.zero values = List.nil := by
  rfl

theorem psKernelExprListDrop_zero
    (values : List PsKernelExpr) :
    psKernelExprListDrop Nat.zero values = values := by
  rfl

theorem psKernelExprListTake_append_drop
    (amount : Nat)
    (values : List PsKernelExpr) :
    List.append
        (psKernelExprListTake amount values)
        (psKernelExprListDrop amount values) =
      values := by
  induction amount generalizing values with
  | zero =>
      simp [psKernelExprListTake, psKernelExprListDrop]
  | succ amount ih =>
      cases values with
      | nil =>
          simp [psKernelExprListTake, psKernelExprListDrop]
      | cons head tail =>
          simp [psKernelExprListTake, psKernelExprListDrop]
          exact ih tail

theorem psKernelExprListReverseWorker_append
    (values acc : List PsKernelExpr) :
    psKernelExprListReverseWorker values acc =
      List.append (List.reverse values) acc := by
  induction values generalizing acc with
  | nil =>
      simp [psKernelExprListReverseWorker]
  | cons head tail ih =>
      simp [psKernelExprListReverseWorker, ih, List.append_assoc]

theorem psKernelExprListReverse_eq_reverse
    (values : List PsKernelExpr) :
    psKernelExprListReverse values =
      List.reverse values := by
  simp [psKernelExprListReverse, psKernelExprListReverseWorker_append]
