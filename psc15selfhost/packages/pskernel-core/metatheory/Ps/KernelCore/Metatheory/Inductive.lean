import Ps.KernelCore.Metatheory.Judgments
import Ps.KernelCore.Admission.Inductive.Common.Occurrence
import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor
import Ps.KernelCore.Admission.Inductive.Common.RecursorValidation

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
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat) : Prop :=
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


def PsKernelSimpleInductiveAppValid
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (result : PsKernelExpr)
    (indices : List PsKernelExpr) : Prop :=
  ∃
    (resultName : PsKernelName)
    (resultLevels : List PsKernelLevel),
      psKernelExprGetAppFn result =
        PsKernelExpr.const resultName resultLevels ∧
      psKernelNameEq resultName target = true ∧
      psKernelLevelListEq resultLevels levels = true ∧
      psKernelConsumeSimpleResultParams
          params
          (psKernelExprGetAppArgs result) =
        Option.some indices ∧
      psKernelExprListLength indices = numIndices

def PsKernelSimpleConstructorResultValid
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (result : PsKernelExpr)
    (indices : List PsKernelExpr) : Prop :=
  PsKernelSimpleInductiveAppValid
      target
      levels
      params
      numIndices
      result
      indices ∧
    psKernelSimpleIndicesContainTarget
        target
        indices =
      false


def PsKernelSessionCheckSoundAtFuel
    (fuel : Nat) : Prop :=
  ∀
    (session nextSession : PsKernelCheckerSession)
    (expr result : PsKernelExpr),
    psKernelSessionCheck
        fuel
        session
        expr =
      Except.ok (Prod.mk result nextSession) ->
    PsKernelTypingJudgment
      session.context.environment
      session.context.localContext
      expr
      result

def PsKernelSessionDefEqSoundAtFuel
    (fuel : Nat) : Prop :=
  ∀
    (session nextSession : PsKernelCheckerSession)
    (left right : PsKernelExpr),
    psKernelSessionIsDefEq
        fuel
        session
        left
        right =
      Except.ok (Prod.mk true nextSession) ->
    PsKernelDefEqJudgment
      session.context.environment
      session.context.localContext
      left
      right

inductive PsKernelSimpleRecursorRulesValid
    (fuel : Nat)
    (params : List PsKernelOpenBinder)
    (ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel) :
    PsKernelCheckerSession ->
    List PsKernelSimpleConstructorShape ->
    List PsKernelRecursorRule ->
    Prop
  | nil
      (session : PsKernelCheckerSession) :
      PsKernelSimpleRecursorRulesValid
        fuel
        params
        ruleBinders
        motive
        levels
        session
        List.nil
        List.nil
  | cons
      (session checkedSession equalSession : PsKernelCheckerSession)
      (shape : PsKernelSimpleConstructorShape)
      (shapeRest : List PsKernelSimpleConstructorShape)
      (rule : PsKernelRecursorRule)
      (ruleRest : List PsKernelRecursorRule)
      (gotType : PsKernelExpr)
      (hCheck :
        psKernelSessionCheck
            fuel
            session
            rule.rhs =
          Except.ok (Prod.mk gotType checkedSession))
      (hTyping :
        PsKernelTypingJudgment
          session.context.environment
          session.context.localContext
          rule.rhs
          gotType)
      (hDefEqRun :
        psKernelSessionIsDefEq
            fuel
            checkedSession
            gotType
            (psKernelCloseOpenBinders
              (psKernelOpenBinderListAppend
                ruleBinders
                shape.fields)
              (psKernelSimpleMotiveApp
                motive
                shape.resultIndices
                (psKernelSimpleCtorApp
                  levels
                  params
                  shape))) =
          Except.ok (Prod.mk true equalSession))
      (hDefEq :
        PsKernelDefEqJudgment
          checkedSession.context.environment
          checkedSession.context.localContext
          gotType
          (psKernelCloseOpenBinders
            (psKernelOpenBinderListAppend
              ruleBinders
              shape.fields)
            (psKernelSimpleMotiveApp
              motive
              shape.resultIndices
              (psKernelSimpleCtorApp
                levels
                params
                shape))))
      (hRest :
        PsKernelSimpleRecursorRulesValid
          fuel
          params
          ruleBinders
          motive
          levels
          equalSession
          shapeRest
          ruleRest) :
      PsKernelSimpleRecursorRulesValid
        fuel
        params
        ruleBinders
        motive
        levels
        session
        (List.cons shape shapeRest)
        (List.cons rule ruleRest)
