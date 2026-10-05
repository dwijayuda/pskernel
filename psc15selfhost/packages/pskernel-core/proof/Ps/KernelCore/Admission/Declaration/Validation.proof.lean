import Ps.KernelCore.Admission.Declaration.Validation

theorem psKernelNameListsEq_nil :
    psKernelNameListsEq List.nil List.nil = true := by
  rfl

theorem psKernelNameMember_nil
    (name : PsKernelName) :
    psKernelNameMember name List.nil = false := by
  rfl

theorem psKernelLevelsHaveMVar_nil :
    psKernelLevelsHaveMVar List.nil = false := by
  rfl

theorem psKernelExprHasMVar_bvar
    (index : Nat) :
    psKernelExprHasMVar (PsKernelExpr.bvar index) = false := by
  rfl


theorem psKernelCheckNoMVarNoFVar_rejects_mvar
    (expr : PsKernelExpr)
    (h : psKernelExprHasMVar expr = true) :
    psKernelCheckNoMVarNoFVar expr =
      Except.error "declaration has metavariables" := by
  simp [psKernelCheckNoMVarNoFVar, h]

theorem psKernelCheckNoMVarNoFVar_rejects_fvar
    (expr : PsKernelExpr)
    (hMVar : psKernelExprHasMVar expr = false)
    (hFVar : psKernelExprHasFVar expr = true) :
    psKernelCheckNoMVarNoFVar expr =
      Except.error "declaration has free variables" := by
  simp [psKernelCheckNoMVarNoFVar, hMVar, hFVar]

theorem psKernelCheckNoMVarNoFVar_accepts_closed
    (expr : PsKernelExpr)
    (hMVar : psKernelExprHasMVar expr = false)
    (hFVar : psKernelExprHasFVar expr = false) :
    psKernelCheckNoMVarNoFVar expr =
      Except.ok Unit.unit := by
  simp [psKernelCheckNoMVarNoFVar, hMVar, hFVar]

theorem psKernelCheckLevelParams_rejects_undefined
    (expr : PsKernelExpr)
    (allowed : List PsKernelName)
    (name : PsKernelName)
    (h :
      psKernelFindUndefExprLevelParam expr allowed =
        Option.some name) :
    psKernelCheckLevelParams expr allowed =
      Except.error
        "invalid reference to undefined universe level parameter" := by
  simp [psKernelCheckLevelParams, h]

theorem psKernelCheckLevelParams_accepts_defined
    (expr : PsKernelExpr)
    (allowed : List PsKernelName)
    (h :
      psKernelFindUndefExprLevelParam expr allowed =
        Option.none) :
    psKernelCheckLevelParams expr allowed =
      Except.ok Unit.unit := by
  simp [psKernelCheckLevelParams, h]
