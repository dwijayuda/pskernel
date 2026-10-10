import Ps.KernelCore.Core.Expr

universe u v

/-- Carried syntax and its inferred type. This is data, not a typing proof. -/
structure PsKernelInferenceResultOf (Expr : Type u) where
  expr : Expr
  type : Expr

def psKernelInferenceResultMap {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (result : PsKernelInferenceResultOf Expr) :
    PsKernelInferenceResultOf Expr' :=
  { expr := f result.expr, type := f result.type }

/-- The shared expression-bearing fields of an exposed dependent function. -/
structure PsKernelForallViewOf (Expr : Type u) where
  name : PsKernelName
  domain : Expr
  body : Expr
  binderInfo : PsKernelBinderInfo

abbrev PsKernelForallView := PsKernelForallViewOf PsKernelExpr

namespace PsKernelForallView

@[match_pattern] abbrev mk
    (name : PsKernelName) (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) : PsKernelForallView :=
  PsKernelForallViewOf.mk name domain body binderInfo

@[simp] abbrev name (view : PsKernelForallView) : PsKernelName :=
  PsKernelForallViewOf.name view

@[simp] abbrev domain (view : PsKernelForallView) : PsKernelExpr :=
  PsKernelForallViewOf.domain view

@[simp] abbrev body (view : PsKernelForallView) : PsKernelExpr :=
  PsKernelForallViewOf.body view

@[simp] abbrev binderInfo (view : PsKernelForallView) : PsKernelBinderInfo :=
  PsKernelForallViewOf.binderInfo view

end PsKernelForallView

def psKernelForallViewMap {Expr : Type u} {Expr' : Type v}
    (f : Expr → Expr') (view : PsKernelForallViewOf Expr) :
    PsKernelForallViewOf Expr' :=
  {
    name := view.name
    domain := f view.domain
    body := f view.body
    binderInfo := view.binderInfo
  }
