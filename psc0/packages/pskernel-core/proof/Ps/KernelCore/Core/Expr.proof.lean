import Ps.KernelCore.Core.Expr
import Ps.KernelCore.Metatheory.Comparator

theorem psKernelExprGetAppFn_app
    (fn arg : PsKernelExpr) :
    psKernelExprGetAppFn (PsKernelExpr.app fn arg) =
      psKernelExprGetAppFn fn := by
  rfl

theorem psKernelExprGetAppFn_bvar
    (index : Nat) :
    psKernelExprGetAppFn (PsKernelExpr.bvar index) =
      PsKernelExpr.bvar index := by
  rfl

theorem psKernelExprGetAppFn_const
    (name : PsKernelName)
    (levels : List PsKernelLevel) :
    psKernelExprGetAppFn (PsKernelExpr.const name levels) =
      PsKernelExpr.const name levels := by
  rfl

theorem psKernelExprGetAppArgs_bvar
    (index : Nat) :
    psKernelExprGetAppArgs (PsKernelExpr.bvar index) = List.nil := by
  rfl

theorem psKernelExprHasFVar_fvar
    (name : PsKernelName) :
    psKernelExprHasFVar (PsKernelExpr.fvar name) = true := by
  rfl

theorem psKernelExprHasFVar_bvar
    (index : Nat) :
    psKernelExprHasFVar (PsKernelExpr.bvar index) = false := by
  rfl

theorem psKernelExprListLength_eq_length
    (values : List PsKernelExpr) :
    psKernelExprListLength values = List.length values := by
  induction values with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelExprListLength, ih]

theorem psKernelExprGetAppNumArgs_def
    (expr : PsKernelExpr) :
    psKernelExprGetAppNumArgs expr =
      psKernelExprListLength (psKernelExprGetAppArgs expr) := by
  rfl


theorem psKernelBoolEq_symm
    (left right : Bool) :
    psKernelBoolEq left right =
      psKernelBoolEq right left :=
  psKernelBoolEq_symm_core left right

theorem psKernelLiteralEq_symm
    (left right : PsKernelLiteral) :
    psKernelLiteralEq left right =
      psKernelLiteralEq right left :=
  psKernelLiteralEq_symm_core left right

theorem psKernelExprEq_symm
    (left right : PsKernelExpr) :
    psKernelExprEq left right =
      psKernelExprEq right left :=
  psKernelExprEq_symm_core left right
