import Ps.KernelCore.Checker.Recursor.Analysis
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelFindRecursorRule_nil
    (ctorName : PsKernelName) :
    psKernelFindRecursorRule ctorName List.nil = Option.none := by
  rfl

theorem psKernelRecursorMajorInductWithFuel_zero
    (expr : PsKernelExpr)
    (index : Nat) :
    psKernelRecursorMajorInductWithFuel 0 expr index = Option.none := by
  rfl

theorem psKernelExprListAnyMVar_nil :
    psKernelExprListAnyMVar List.nil = false := by
  rfl

theorem psKernelRecursorExprListAppend_eq_append
    (left right : List PsKernelExpr) :
    psKernelExprListAppend left right = List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelExprListAppend, ih]

theorem psKernelStructureFieldsWithFuel_zero
    (inductName : PsKernelName)
    (major : PsKernelExpr)
    (fieldCount index : Nat) :
    psKernelStructureFieldsWithFuel
        0 inductName major fieldCount index =
      List.nil := by
  rfl


theorem psKernelFindRecursorRule_some_matches
    (ctorName : PsKernelName)
    (rules : List PsKernelRecursorRule)
    (rule : PsKernelRecursorRule)
    (h :
      psKernelFindRecursorRule ctorName rules =
        Option.some rule) :
    psKernelNameEq rule.ctor ctorName = true := by
  induction rules with
  | nil =>
      simp [psKernelFindRecursorRule] at h
  | cons head tail ih =>
      cases hEq :
          psKernelNameEq head.ctor ctorName with
      | false =>
          simp [psKernelFindRecursorRule, hEq] at h
          exact ih h
      | true =>
          simp [psKernelFindRecursorRule, hEq] at h
          subst rule
          exact hEq

theorem psKernelFindRecursorRule_some_mem
    (ctorName : PsKernelName)
    (rules : List PsKernelRecursorRule)
    (rule : PsKernelRecursorRule)
    (h :
      psKernelFindRecursorRule ctorName rules =
        Option.some rule) :
    rule ∈ rules := by
  induction rules with
  | nil =>
      simp [psKernelFindRecursorRule] at h
  | cons head tail ih =>
      cases hEq :
          psKernelNameEq head.ctor ctorName with
      | false =>
          simp [psKernelFindRecursorRule, hEq] at h
          exact List.mem_cons_of_mem head (ih h)
      | true =>
          simp [psKernelFindRecursorRule, hEq] at h
          subst rule
          exact List.mem_cons_self


theorem psKernelIsConstructorApp_true_refines_authoritative
    (environment : PsKernelEnvironment)
    (expr : PsKernelExpr)
    (hIndex :
      PsKernelEnvironmentIndexRefines environment)
    (hConstructor :
      psKernelIsConstructorApp environment expr = true) :
    ∃
      (name : PsKernelName)
      (levels : List PsKernelLevel)
      (ctor : PsKernelConstructorInfo),
      psKernelExprGetAppFn expr =
          PsKernelExpr.const name levels ∧
      psKernelFindConstantInList
          name
          environment.constants =
        Option.some
          (PsKernelConstantInfo.ctorInfo ctor) := by
  cases hFn : psKernelExprGetAppFn expr with
  | bvar index =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
  | fvar name =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
  | mvar name =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
  | sort level =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
  | const name levels =>
      cases hFind :
          psKernelEnvironmentFind environment name with
      | none =>
          simp [
            psKernelIsConstructorApp,
            hFn,
            hFind
          ] at hConstructor
      | some info =>
          cases info with
          | axiomInfo value =>
              simp [
                psKernelIsConstructorApp,
                hFn,
                hFind
              ] at hConstructor
          | defnInfo value =>
              simp [
                psKernelIsConstructorApp,
                hFn,
                hFind
              ] at hConstructor
          | thmInfo value =>
              simp [
                psKernelIsConstructorApp,
                hFn,
                hFind
              ] at hConstructor
          | opaqueInfo value =>
              simp [
                psKernelIsConstructorApp,
                hFn,
                hFind
              ] at hConstructor
          | inductInfo value =>
              simp [
                psKernelIsConstructorApp,
                hFn,
                hFind
              ] at hConstructor
          | ctorInfo ctor =>
              refine ⟨name, levels, ctor, rfl, ?_⟩
              unfold psKernelEnvironmentFind at hFind
              rw [hIndex name] at hFind
              exact hFind
          | recInfo value =>
              simp [
                psKernelIsConstructorApp,
                hFn,
                hFind
              ] at hConstructor
          | quotInfo value =>
              simp [
                psKernelIsConstructorApp,
                hFn,
                hFind
              ] at hConstructor
  | app fn arg =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
  | lam name type body binderInfo =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
  | forallE name type body binderInfo =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
  | letE name type value body nondep =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
  | lit literal =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
  | mdata metadata body =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
  | proj typeName index body =>
      simp [psKernelIsConstructorApp, hFn] at hConstructor
