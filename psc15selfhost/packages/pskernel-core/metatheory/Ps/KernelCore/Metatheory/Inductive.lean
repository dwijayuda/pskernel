import Ps.KernelCore.Admission.Inductive.Common.Occurrence

/-
Independent Assurance Plane predicates for simple-inductive occurrence checks.

The executable checker is fuel-bounded.  These predicates are structural and
fuel-free; they express what a successful uniform-occurrence check certifies.
-/

def PsKernelUniformOccurrenceHeadValid
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat) : Prop :=
  ∃
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (args : List PsKernelExpr),
      psKernelExprGetAppFn expr =
        PsKernelExpr.const name levels ∧
      psKernelExprGetAppArgs expr = args ∧
      psKernelSimpleDeclaredNameMember
          name
          declaredNames =
        true ∧
      psKernelExprListLength args = numParams ∧
      psKernelNatGe offset numParams = true ∧
      psKernelLevelListEq levels expectedLevels = true ∧
      psKernelSimpleUniformParamArgsMatch
          offset
          args
          0 =
        true

def PsKernelUniformOccurrenceSafe
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat) :
    PsKernelExpr -> Nat -> Prop
  | expr, offset =>
      match
          psKernelSimpleCheckUniformOccurrenceHead
            declaredNames
            expectedLevels
            numParams
            expr
            offset with
      | Except.error _ =>
          False
      | Except.ok true =>
          PsKernelUniformOccurrenceHeadValid
            declaredNames
            expectedLevels
            numParams
            expr
            offset
      | Except.ok false =>
          match expr with
          | PsKernelExpr.app fn arg =>
              PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  fn
                  offset ∧
                PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  arg
                  offset
          | PsKernelExpr.lam _ type body _ =>
              PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  type
                  offset ∧
                PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  body
                  (Nat.succ offset)
          | PsKernelExpr.forallE _ type body _ =>
              PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  type
                  offset ∧
                PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  body
                  (Nat.succ offset)
          | PsKernelExpr.letE _ type value body _ =>
              PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  type
                  offset ∧
                PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  value
                  offset ∧
                PsKernelUniformOccurrenceSafe
                  declaredNames
                  expectedLevels
                  numParams
                  body
                  (Nat.succ offset)
          | PsKernelExpr.mdata _ body =>
              PsKernelUniformOccurrenceSafe
                declaredNames
                expectedLevels
                numParams
                body
                offset
          | PsKernelExpr.proj _ _ body =>
              PsKernelUniformOccurrenceSafe
                declaredNames
                expectedLevels
                numParams
                body
                offset
          | _ =>
              True
termination_by expr

def PsKernelUniformOccurrencesSafe
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (ctorTypes : List PsKernelExpr) : Prop :=
  ∀ expr : PsKernelExpr,
    List.Mem expr ctorTypes ->
      PsKernelUniformOccurrenceSafe
        declaredNames
        expectedLevels
        numParams
        expr
        0
