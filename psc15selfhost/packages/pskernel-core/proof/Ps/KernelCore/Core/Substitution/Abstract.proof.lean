import Ps.KernelCore.Core.Substitution.Abstract
import Ps.KernelCore.Metatheory.SubstitutionRefinement

theorem psKernelNameLastIndexWorker_nil
    (needle : PsKernelName)
    (index : Nat)
    (answer : Option Nat) :
    psKernelNameLastIndexWorker List.nil needle index answer = answer := by
  rfl

theorem psKernelNameLastIndex_nil
    (needle : PsKernelName) :
    psKernelNameLastIndex needle List.nil = Option.none := by
  rfl

theorem psKernelExprAbstractFVarsAtChangedWithFuel_zero
    (expr : PsKernelExpr)
    (fvars : List PsKernelName)
    (offset : Nat) :
    psKernelExprAbstractFVarsAtChangedWithFuel
        0 expr fvars offset =
      Prod.mk expr false := by
  rfl

theorem psKernelExprAbstractFVarsAt_empty
    (expr : PsKernelExpr)
    (offset : Nat) :
    psKernelExprAbstractFVarsAt expr List.nil offset = expr := by
  rfl

theorem psKernelExprAbstractFVars_empty
    (expr : PsKernelExpr) :
    psKernelExprAbstractFVars expr List.nil = expr := by
  rfl

theorem psKernelExprAbstractFVars_anonymous_singleton :
    psKernelExprAbstractFVars
        (PsKernelExpr.fvar PsKernelName.anonymous)
        (List.cons PsKernelName.anonymous List.nil) =
      PsKernelExpr.bvar 0 := by
  rfl

theorem psKernelExprAbstractFVars_under_one_lambda_anonymous
    (name : PsKernelName)
    (level : PsKernelLevel)
    (binderInfo : PsKernelBinderInfo) :
    psKernelExprAbstractFVars
        (PsKernelExpr.lam
          name
          (PsKernelExpr.sort level)
          (PsKernelExpr.fvar PsKernelName.anonymous)
          binderInfo)
        (List.cons PsKernelName.anonymous List.nil) =
      PsKernelExpr.lam
        name
        (PsKernelExpr.sort level)
        (PsKernelExpr.bvar 1)
        binderInfo := by
  rfl

theorem psKernelExprAbstractInstantiate_roundtrip_under_one_lambda_anonymous
    (name : PsKernelName)
    (level : PsKernelLevel)
    (binderInfo : PsKernelBinderInfo) :
    psKernelExprInstantiate1
        (psKernelExprAbstractFVars
          (PsKernelExpr.lam
            name
            (PsKernelExpr.sort level)
            (PsKernelExpr.fvar PsKernelName.anonymous)
            binderInfo)
          (List.cons PsKernelName.anonymous List.nil))
        (PsKernelExpr.fvar PsKernelName.anonymous) =
      PsKernelExpr.lam
        name
        (PsKernelExpr.sort level)
        (PsKernelExpr.fvar PsKernelName.anonymous)
        binderInfo := by
  rfl


theorem psKernelExprAbstractFVarsAt_refines_reference
    (expr : PsKernelExpr)
    (fvars : List PsKernelName)
    (offset : Nat) :
    psKernelExprAbstractFVarsAt expr fvars offset =
      psKernelExprAbstractFVarsAtReference expr fvars offset := by
  exact
    psKernelExprAbstractFVarsAt_refines_reference_core
      expr fvars offset

theorem psKernelExprAbstractFVars_refines_reference
    (expr : PsKernelExpr)
    (fvars : List PsKernelName) :
    psKernelExprAbstractFVars expr fvars =
      psKernelExprAbstractFVarsReference expr fvars := by
  exact
    psKernelExprAbstractFVars_refines_reference_core
      expr fvars


theorem psKernelExprAbstractInstantiate_roundtrip_singleton
    (expr : PsKernelExpr)
    (target : PsKernelName)
    (offset : Nat)
    (hClosed :
      psKernelExprHasLooseAt expr offset = false)
    (hNameSound :
      PsKernelNameEqSoundAgainst target) :
    psKernelExprInstantiateAt
        (psKernelExprAbstractFVarsAt
          expr
          (List.cons target List.nil)
          offset)
        0
        (List.cons (PsKernelExpr.fvar target) List.nil)
        offset =
      expr := by
  exact
    psKernelExprAbstractInstantiate_roundtrip_singleton_core
      expr target offset hClosed hNameSound
