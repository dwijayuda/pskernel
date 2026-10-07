import Ps.KernelCore.Checker.DefEq.FinalRules
import Ps.KernelCore.Metatheory.CheckerContracts

/-
Configuration preservation for the proposition classifier used by DefEq.

This theorem intentionally makes no semantic proof-irrelevance claim yet.
The executable helper infers the input expression's type and WHNF-reduces that
inferred type to a Sort; later proof-irrelevance refinement must model that
exact relationship rather than claiming the proposition expression itself
reduces to Sort 0.
-/

theorem psKernelDefEqIsPropWith_configuration_preserves
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hInfer :
      PsKernelInferOnlyConfigurationPreserves inferType)
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (answer : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqIsPropWith
          inferType
          whnf
          context
          state
          expr =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  cases hInferRun :
      inferType context state expr with
  | error error =>
      simp [
        psKernelDefEqIsPropWith,
        hInferRun
      ] at hSuccess
  | ok inferRun =>
      rcases inferRun with ⟨inferredType, inferredState⟩
      have hInferredConfig :=
        hInfer
          context
          state
          inferredState
          expr
          inferredType
          hConfig
          hInferRun
      cases hWhnfRun :
          whnf
            context
            inferredState
            inferredType with
      | error error =>
          simp [
            psKernelDefEqIsPropWith,
            hInferRun,
            hWhnfRun
          ] at hSuccess
      | ok whnfRun =>
          rcases whnfRun with ⟨reducedType, reducedState⟩
          have hReduced :=
            hWhnf
              context
              inferredState
              reducedState
              inferredType
              reducedType
              hInferredConfig
              hWhnfRun
          cases reducedType with
          | sort level =>
              simp [
                psKernelDefEqIsPropWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | _ =>
              simp [
                psKernelDefEqIsPropWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess


theorem psKernelDefEqIsPropWith_true_refines
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hInfer :
      PsKernelInferOnlyConfigurationPreserves inferType)
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqIsPropWith
          inferType
          whnf
          context
          state
          expr =
        Except.ok (Prod.mk true nextState)) :
    ∃ (inferredType : PsKernelExpr) (level : PsKernelLevel),
      PsKernelReductionClosure
          context.environment
          context.localContext
          inferredType
          (PsKernelExpr.sort level) ∧
        psKernelLevelNormalizesToZero level = true := by
  cases hInferRun :
      inferType context state expr with
  | error error =>
      simp [
        psKernelDefEqIsPropWith,
        hInferRun
      ] at hSuccess
  | ok inferRun =>
      rcases inferRun with ⟨inferredType, inferredState⟩
      have hInferredConfig :=
        hInfer
          context
          state
          inferredState
          expr
          inferredType
          hConfig
          hInferRun
      cases hWhnfRun :
          whnf context inferredState inferredType with
      | error error =>
          simp [
            psKernelDefEqIsPropWith,
            hInferRun,
            hWhnfRun
          ] at hSuccess
      | ok whnfRun =>
          rcases whnfRun with ⟨reducedType, reducedState⟩
          have hReduced :=
            hWhnf
              context
              inferredState
              reducedState
              inferredType
              reducedType
              hInferredConfig
              hWhnfRun
          cases reducedType with
          | sort level =>
              simp [
                psKernelDefEqIsPropWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
              rcases hSuccess with ⟨hProp, rfl⟩
              exact ⟨inferredType, level, hReduced.1, hProp⟩
          | _ =>
              simp [
                psKernelDefEqIsPropWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess

theorem psKernelDefEqEtaStructFieldsWithFuel_configuration_preserves
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (induct : PsKernelName)
    (term : PsKernelExpr)
    (args : List PsKernelExpr)
    (numParams index : Nat)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqEtaStructFieldsWithFuel
          fuel defeq context state
          induct term args numParams index =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  induction fuel generalizing state nextState index value with
  | zero =>
      simp [psKernelDefEqEtaStructFieldsWithFuel] at hSuccess
  | succ remaining ih =>
      simp only [psKernelDefEqEtaStructFieldsWithFuel] at hSuccess
      by_cases hMore :
          psKernelNatLt
              index
              (Nat.sub
                (psKernelExprListLength args)
                numParams) =
            true
      · rw [if_pos hMore] at hSuccess
        cases hArg :
            psKernelExprListGet
              args
              (Nat.add numParams index) with
        | none =>
            simp only [hArg] at hSuccess
            simp at hSuccess
            rcases hSuccess with ⟨rfl, rfl⟩
            exact hConfig
        | some arg =>
            simp only [hArg] at hSuccess
            cases hRun :
                defeq
                  context
                  state
                  (PsKernelExpr.proj induct index term)
                  arg with
            | error error =>
                simp only [hRun] at hSuccess
                simp at hSuccess
            | ok run =>
                rcases run with ⟨eqValue, eqState⟩
                simp only [hRun] at hSuccess
                have hEq :=
                  hDefEq
                    context
                    state
                    eqState
                    (PsKernelExpr.proj induct index term)
                    arg
                    eqValue
                    hConfig
                    hRun
                by_cases hEqValue : eqValue = true
                · rw [if_pos hEqValue] at hSuccess
                  exact
                    ih
                      eqState
                      nextState
                      (Nat.succ index)
                      value
                      hEq.1
                      (by simpa [Nat.succ_eq_add_one] using hSuccess)
                · rw [if_neg hEqValue] at hSuccess
                  simp at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hEq.1
      · rw [if_neg hMore] at hSuccess
        simp at hSuccess
        rcases hSuccess with ⟨rfl, rfl⟩
        exact hConfig


theorem psKernelDefEqEtaStructFieldsWithFuel_true_refines
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (induct : PsKernelName)
    (term : PsKernelExpr)
    (args : List PsKernelExpr)
    (numParams index : Nat)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqEtaStructFieldsWithFuel
          fuel defeq context state
          induct term args numParams index =
        Except.ok (Prod.mk true nextState)) :
    PsKernelStructureEtaCompareJudgment
      context.environment
      context.localContext
      induct
      term
      args
      numParams
      index := by
  induction fuel generalizing state nextState index with
  | zero =>
      simp [psKernelDefEqEtaStructFieldsWithFuel] at hSuccess
  | succ remaining ih =>
      simp only [psKernelDefEqEtaStructFieldsWithFuel] at hSuccess
      by_cases hMore :
          psKernelNatLt
              index
              (Nat.sub
                (psKernelExprListLength args)
                numParams) =
            true
      · rw [if_pos hMore] at hSuccess
        cases hArg :
            psKernelExprListGet
              args
              (Nat.add numParams index) with
        | none =>
            simp only [hArg] at hSuccess
            simp at hSuccess
        | some arg =>
            simp only [hArg] at hSuccess
            cases hRun :
                defeq
                  context
                  state
                  (PsKernelExpr.proj induct index term)
                  arg with
            | error error =>
                simp only [hRun] at hSuccess
                simp at hSuccess
            | ok run =>
                rcases run with ⟨eqValue, eqState⟩
                simp only [hRun] at hSuccess
                have hEq :=
                  hDefEq
                    context
                    state
                    eqState
                    (PsKernelExpr.proj induct index term)
                    arg
                    eqValue
                    hConfig
                    hRun
                by_cases hEqValue : eqValue = true
                · rw [if_pos hEqValue] at hSuccess
                  exact
                    PsKernelStructureEtaCompareJudgment.step
                      induct
                      term
                      args
                      numParams
                      index
                      arg
                      hMore
                      hArg
                      (hEq.2 hEqValue)
                      (ih
                        eqState
                        nextState
                        (Nat.succ index)
                        hEq.1
                        (by
                          simpa [Nat.succ_eq_add_one] using hSuccess))
                · rw [if_neg hEqValue] at hSuccess
                  simp at hSuccess
                  exact (hEqValue hSuccess.1).elim
      · rw [if_neg hMore] at hSuccess
        have hDone :
            psKernelNatLt
                index
                (Nat.sub
                  (psKernelExprListLength args)
                  numParams) =
              false := by
          cases hValue :
              psKernelNatLt
                index
                (Nat.sub
                  (psKernelExprListLength args)
                  numParams) <;>
            simp_all
        exact
          PsKernelStructureEtaCompareJudgment.done
            induct
            term
            args
            numParams
            index
            hDone

theorem psKernelDefEqEtaStructCoreWith_configuration_preserves
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (term structureValue : PsKernelExpr)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqEtaStructCoreWith
          defeq inferType context state term structureValue =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  simp only [psKernelDefEqEtaStructCoreWith] at hSuccess
  cases hFn : psKernelExprGetAppFn structureValue with
  | const ctorName levels =>
      simp only [hFn] at hSuccess
      cases hFind :
          psKernelEnvironmentFind
            context.environment
            ctorName with
      | none =>
          simp only [hFind] at hSuccess
          simp at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hConfig
      | some info =>
          simp only [hFind] at hSuccess
          cases info with
          | ctorInfo ctor =>
              simp only at hSuccess
              by_cases hArity :
                  Nat.beq
                      (psKernelExprListLength
                        (psKernelExprGetAppArgs structureValue))
                      (Nat.add ctor.numParams ctor.numFields) =
                    true
              · rw [if_pos hArity] at hSuccess
                by_cases hStructure :
                    psKernelEnvironmentIsNonRecStructure
                        context.environment
                        ctor.induct =
                      true
                · rw [if_pos hStructure] at hSuccess
                  cases hTerm :
                      inferType context state term with
                  | error error =>
                      simp only [hTerm] at hSuccess
                      simp at hSuccess
                  | ok termRun =>
                      simp only [hTerm] at hSuccess
                      rcases termRun with ⟨termType, termState⟩
                      have hTermConfig :=
                        hInfer
                          context
                          state
                          termState
                          term
                          termType
                          hConfig
                          hTerm
                      cases hStructType :
                          inferType
                            context
                            termState
                            structureValue with
                      | error error =>
                          simp only [hStructType] at hSuccess
                          simp at hSuccess
                      | ok structRun =>
                          simp only [hStructType] at hSuccess
                          rcases structRun with
                            ⟨structureType, structureState⟩
                          have hStructureConfig :=
                            hInfer
                              context
                              termState
                              structureState
                              structureValue
                              structureType
                              hTermConfig
                              hStructType
                          cases hTypes :
                              defeq
                                context
                                structureState
                                termType
                                structureType with
                          | error error =>
                              simp only [hTypes] at hSuccess
                              simp at hSuccess
                          | ok typeRun =>
                              simp only [hTypes] at hSuccess
                              rcases typeRun with
                                ⟨typesEqual, typeState⟩
                              have hTypeSemantic :=
                                hDefEq
                                  context
                                  structureState
                                  typeState
                                  termType
                                  structureType
                                  typesEqual
                                  hStructureConfig
                                  hTypes
                              by_cases hTypesEqual :
                                  typesEqual = true
                              · rw [if_pos hTypesEqual] at hSuccess
                                exact
                                  psKernelDefEqEtaStructFieldsWithFuel_configuration_preserves
                                    (Nat.succ ctor.numFields)
                                    defeq
                                    hDefEq
                                    context
                                    typeState
                                    nextState
                                    ctor.induct
                                    term
                                    (psKernelExprGetAppArgs structureValue)
                                    ctor.numParams
                                    0
                                    value
                                    hTypeSemantic.1
                                    hSuccess
                              · rw [if_neg hTypesEqual] at hSuccess
                                simp at hSuccess
                                rcases hSuccess with ⟨rfl, rfl⟩
                                exact hTypeSemantic.1
                · rw [if_neg hStructure] at hSuccess
                  simp at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hConfig
              · rw [if_neg hArity] at hSuccess
                simp at hSuccess
                rcases hSuccess with ⟨rfl, rfl⟩
                exact hConfig
          | axiomInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | defnInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | thmInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | opaqueInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | inductInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | recInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | quotInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
  | bvar index =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | fvar name =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | mvar name =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | sort level =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | app fn arg =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | lam name type body binderInfo =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | forallE name type body binderInfo =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | letE name type value body nondep =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | lit literal =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | mdata metadata body =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | proj typeName index body =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig


theorem psKernelDefEqEtaStructCoreWith_true_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (term structureValue : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqEtaStructCoreWith
          defeq inferType context state term structureValue =
        Except.ok (Prod.mk true nextState)) :
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      term
      structureValue := by
  simp only [psKernelDefEqEtaStructCoreWith] at hSuccess
  cases hFn : psKernelExprGetAppFn structureValue with
  | const ctorName levels =>
      simp only [hFn] at hSuccess
      cases hFind :
          psKernelEnvironmentFind
            context.environment
            ctorName with
      | none =>
          simp only [hFind] at hSuccess
          simp at hSuccess
      | some info =>
          simp only [hFind] at hSuccess
          cases info with
          | ctorInfo ctor =>
              simp only at hSuccess
              by_cases hArity :
                  Nat.beq
                      (psKernelExprListLength
                        (psKernelExprGetAppArgs structureValue))
                      (Nat.add ctor.numParams ctor.numFields) =
                    true
              · rw [if_pos hArity] at hSuccess
                by_cases hStructure :
                    psKernelEnvironmentIsNonRecStructure
                        context.environment
                        ctor.induct =
                      true
                · rw [if_pos hStructure] at hSuccess
                  cases hTerm :
                      inferType context state term with
                  | error error =>
                      simp only [hTerm] at hSuccess
                      simp at hSuccess
                  | ok termRun =>
                      simp only [hTerm] at hSuccess
                      rcases termRun with ⟨termType, termState⟩
                      have hTermConfig :=
                        hInfer
                          context
                          state
                          termState
                          term
                          termType
                          hConfig
                          hTerm
                      cases hStructType :
                          inferType
                            context
                            termState
                            structureValue with
                      | error error =>
                          simp only [hStructType] at hSuccess
                          simp at hSuccess
                      | ok structRun =>
                          simp only [hStructType] at hSuccess
                          rcases structRun with
                            ⟨structureType, structureState⟩
                          have hStructureConfig :=
                            hInfer
                              context
                              termState
                              structureState
                              structureValue
                              structureType
                              hTermConfig
                              hStructType
                          cases hTypes :
                              defeq
                                context
                                structureState
                                termType
                                structureType with
                          | error error =>
                              simp only [hTypes] at hSuccess
                              simp at hSuccess
                          | ok typeRun =>
                              simp only [hTypes] at hSuccess
                              rcases typeRun with
                                ⟨typesEqual, typeState⟩
                              have hTypeSemantic :=
                                hDefEq
                                  context
                                  structureState
                                  typeState
                                  termType
                                  structureType
                                  typesEqual
                                  hStructureConfig
                                  hTypes
                              by_cases hTypesEqual :
                                  typesEqual = true
                              · rw [if_pos hTypesEqual] at hSuccess
                                have hFields :=
                                  psKernelDefEqEtaStructFieldsWithFuel_true_refines
                                    (Nat.succ ctor.numFields)
                                    defeq
                                    hDefEq
                                    context
                                    typeState
                                    nextState
                                    ctor.induct
                                    term
                                    (psKernelExprGetAppArgs structureValue)
                                    ctor.numParams
                                    0
                                    hTypeSemantic.1
                                    hSuccess
                                have hCtor :
                                    psKernelFindConstantInList
                                        ctorName
                                        context.environment.constants =
                                      Option.some
                                        (PsKernelConstantInfo.ctorInfo ctor) := by
                                  unfold psKernelEnvironmentFind at hFind
                                  calc
                                    psKernelFindConstantInList
                                        ctorName
                                        context.environment.constants =
                                      psKernelFindConstantInList
                                        ctorName
                                        (psKernelEnvironmentIndexFind
                                          context.environment.index
                                          ctorName) :=
                                      (hConfig.1 ctorName).symm
                                    _ =
                                        Option.some
                                          (PsKernelConstantInfo.ctorInfo ctor) :=
                                      hFind
                                exact
                                  PsKernelDefEqJudgment.structureEtaAlgorithmic
                                    term
                                    structureValue
                                    termType
                                    structureType
                                    ctorName
                                    levels
                                    ctor
                                    hFn
                                    hCtor
                                    hArity
                                    hStructure
                                    (hTypeSemantic.2 hTypesEqual)
                                    hFields
                              · rw [if_neg hTypesEqual] at hSuccess
                                simp at hSuccess
                                exact (hTypesEqual hSuccess.1).elim
                · rw [if_neg hStructure] at hSuccess
                  simp at hSuccess
              · rw [if_neg hArity] at hSuccess
                simp at hSuccess
          | axiomInfo infoValue =>
              simp at hSuccess
          | defnInfo infoValue =>
              simp at hSuccess
          | thmInfo infoValue =>
              simp at hSuccess
          | opaqueInfo infoValue =>
              simp at hSuccess
          | inductInfo infoValue =>
              simp at hSuccess
          | recInfo infoValue =>
              simp at hSuccess
          | quotInfo infoValue =>
              simp at hSuccess
  | bvar index =>
      simp only [hFn] at hSuccess
      simp at hSuccess
  | fvar name =>
      simp only [hFn] at hSuccess
      simp at hSuccess
  | mvar name =>
      simp only [hFn] at hSuccess
      simp at hSuccess
  | sort level =>
      simp only [hFn] at hSuccess
      simp at hSuccess
  | app fn arg =>
      simp only [hFn] at hSuccess
      simp at hSuccess
  | lam name type body binderInfo =>
      simp only [hFn] at hSuccess
      simp at hSuccess
  | forallE name type body binderInfo =>
      simp only [hFn] at hSuccess
      simp at hSuccess
  | letE name type value body nondep =>
      simp only [hFn] at hSuccess
      simp at hSuccess
  | lit literal =>
      simp only [hFn] at hSuccess
      simp at hSuccess
  | mdata metadata body =>
      simp only [hFn] at hSuccess
      simp at hSuccess
  | proj typeName index body =>
      simp only [hFn] at hSuccess
      simp at hSuccess

theorem psKernelDefEqEtaStructWith_configuration_preserves
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqEtaStructWith
          defeq inferType context state left right =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  simp only [psKernelDefEqEtaStructWith] at hSuccess
  cases hFirst :
      psKernelDefEqEtaStructCoreWith
        defeq inferType context state left right with
  | error error =>
      simp only [hFirst] at hSuccess
      simp at hSuccess
  | ok firstRun =>
      simp only [hFirst] at hSuccess
      rcases firstRun with ⟨firstValue, firstState⟩
      have hFirstConfig :=
        psKernelDefEqEtaStructCoreWith_configuration_preserves
          defeq
          inferType
          hDefEq
          hInfer
          context
          state
          firstState
          left
          right
          firstValue
          hConfig
          hFirst
      by_cases hFirstTrue : firstValue = true
      · rw [if_pos hFirstTrue] at hSuccess
        simp at hSuccess
        rcases hSuccess with ⟨rfl, rfl⟩
        exact hFirstConfig
      · rw [if_neg hFirstTrue] at hSuccess
        cases hSecond :
            psKernelDefEqEtaStructCoreWith
              defeq inferType
              context firstState right left with
        | error error =>
            simp only [hSecond] at hSuccess
            simp at hSuccess
        | ok secondRun =>
            simp only [hSecond] at hSuccess
            rcases secondRun with ⟨secondValue, secondState⟩
            have hSecondConfig :=
              psKernelDefEqEtaStructCoreWith_configuration_preserves
                defeq
                inferType
                hDefEq
                hInfer
                context
                firstState
                secondState
                right
                left
                secondValue
                hFirstConfig
                hSecond
            simp at hSuccess
            rcases hSuccess with ⟨rfl, rfl⟩
            exact hSecondConfig



theorem psKernelDefEqEtaStructWith_true_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqEtaStructWith
          defeq inferType context state left right =
        Except.ok (Prod.mk true nextState)) :
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  simp only [psKernelDefEqEtaStructWith] at hSuccess
  cases hFirst :
      psKernelDefEqEtaStructCoreWith
        defeq inferType context state left right with
  | error error =>
      simp only [hFirst] at hSuccess
      simp at hSuccess
  | ok firstRun =>
      simp only [hFirst] at hSuccess
      rcases firstRun with ⟨firstValue, firstState⟩
      have hFirstConfig :=
        psKernelDefEqEtaStructCoreWith_configuration_preserves
          defeq
          inferType
          hDefEq
          hInfer
          context
          state
          firstState
          left
          right
          firstValue
          hConfig
          hFirst
      by_cases hFirstTrue : firstValue = true
      · have hFirstRun :
            psKernelDefEqEtaStructCoreWith
                defeq inferType context state left right =
              Except.ok (Prod.mk true firstState) := by
          simpa [hFirstTrue] using hFirst
        exact
          psKernelDefEqEtaStructCoreWith_true_refines
            defeq
            inferType
            hDefEq
            hInfer
            context
            state
            firstState
            left
            right
            hConfig
            hFirstRun
      · rw [if_neg hFirstTrue] at hSuccess
        cases hSecond :
            psKernelDefEqEtaStructCoreWith
              defeq inferType
              context firstState right left with
        | error error =>
            simp only [hSecond] at hSuccess
            simp at hSuccess
        | ok secondRun =>
            simp only [hSecond] at hSuccess
            rcases secondRun with ⟨secondValue, secondState⟩
            by_cases hSecondTrue : secondValue = true
            · have hSecondRun :
                  psKernelDefEqEtaStructCoreWith
                      defeq inferType
                      context firstState right left =
                    Except.ok (Prod.mk true secondState) := by
                simpa [hSecondTrue] using hSecond
              exact
                PsKernelDefEqJudgment.symm
                  right
                  left
                  (psKernelDefEqEtaStructCoreWith_true_refines
                    defeq
                    inferType
                    hDefEq
                    hInfer
                    context
                    firstState
                    secondState
                    right
                    left
                    hFirstConfig
                    hSecondRun)
            · simp [hSecondTrue] at hSuccess


theorem psKernelDefEqEtaStructWith_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqEtaStructWith
          defeq inferType context state left right =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right) := by
  constructor
  · exact
      psKernelDefEqEtaStructWith_configuration_preserves
        defeq
        inferType
        hDefEq
        hInfer
        context
        state
        nextState
        left
        right
        value
        hConfig
        hSuccess
  · intro hValue
    cases value with
    | false =>
        simp at hValue
    | true =>
        exact
          psKernelDefEqEtaStructWith_true_refines
            defeq
            inferType
            hDefEq
            hInfer
            context
            state
            nextState
            left
            right
            hConfig
            hSuccess

theorem psKernelDefEqStringLitExpansionCoreWith_configuration_preserves
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : Option Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqStringLitExpansionCoreWith
          defeq whnf context state left right =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  simp only [psKernelDefEqStringLitExpansionCoreWith] at hSuccess
  cases left with
  | lit literal =>
      cases literal with
      | str value =>
          simp only at hSuccess
          by_cases hString :
              psKernelExprIsStringOfListApp right = true
          · rw [if_pos hString] at hSuccess
            cases hWhnfRun :
                whnf
                  context
                  state
                  (psKernelStringLitToConstructor value) with
            | error error =>
                simp only [hWhnfRun] at hSuccess
                simp at hSuccess
            | ok whnfRun =>
                simp only [hWhnfRun] at hSuccess
                rcases whnfRun with ⟨expanded, whnfState⟩
                have hWhnfSemantic :=
                  hWhnf
                    context state whnfState
                    (psKernelStringLitToConstructor value)
                    expanded
                    hConfig hWhnfRun
                cases hEqRun :
                    defeq
                      context
                      whnfState
                      expanded
                      right with
                | error error =>
                    simp only [hEqRun] at hSuccess
                    simp at hSuccess
                | ok eqRun =>
                    simp only [hEqRun] at hSuccess
                    rcases eqRun with ⟨eqValue, eqState⟩
                    have hEqSemantic :=
                      hDefEq
                        context
                        whnfState
                        eqState
                        expanded
                        right
                        eqValue
                        hWhnfSemantic.2
                        hEqRun
                    simp at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact hEqSemantic.1
          · rw [if_neg hString] at hSuccess
            simp at hSuccess
            rcases hSuccess with ⟨rfl, rfl⟩
            exact hConfig
      | nat value =>
          simp at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hConfig
  | bvar index =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | fvar name =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | mvar name =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | sort level =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | const name levels =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | app fn arg =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | lam name type body binderInfo =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | forallE name type body binderInfo =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | letE name type value body nondep =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | mdata metadata body =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | proj typeName index body =>
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig


theorem psKernelDefEqStringLitExpansionWith_configuration_preserves
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : Option Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqStringLitExpansionWith
          defeq whnf context state left right =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  simp only [psKernelDefEqStringLitExpansionWith] at hSuccess
  cases hFirst :
      psKernelDefEqStringLitExpansionCoreWith
        defeq whnf context state left right with
  | error error =>
      simp only [hFirst] at hSuccess
      simp at hSuccess
  | ok firstRun =>
      simp only [hFirst] at hSuccess
      rcases firstRun with ⟨firstAnswer, firstState⟩
      have hFirstConfig :=
        psKernelDefEqStringLitExpansionCoreWith_configuration_preserves
          defeq whnf hDefEq hWhnf
          context state firstState
          left right firstAnswer
          hConfig hFirst
      cases firstAnswer with
      | some firstValue =>
          simp at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hFirstConfig
      | none =>
          cases hSecond :
              psKernelDefEqStringLitExpansionCoreWith
                defeq whnf
                context firstState right left with
          | error error =>
              simp only [hSecond] at hSuccess
              simp at hSuccess
          | ok secondRun =>
              simp only [hSecond] at hSuccess
              rcases secondRun with ⟨secondAnswer, secondState⟩
              have hSecondConfig :=
                psKernelDefEqStringLitExpansionCoreWith_configuration_preserves
                  defeq whnf hDefEq hWhnf
                  context firstState secondState
                  right left secondAnswer
                  hFirstConfig hSecond
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hSecondConfig


theorem psKernelDefEqUnitLikeWith_configuration_preserves
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqUnitLikeWith
          defeq inferType whnf
          context state left right =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  simp only [psKernelDefEqUnitLikeWith] at hSuccess
  cases hLeftInfer :
      inferType context state left with
  | error error =>
      simp only [hLeftInfer] at hSuccess
      simp at hSuccess
  | ok leftRun =>
      simp only [hLeftInfer] at hSuccess
      rcases leftRun with ⟨leftType, leftState⟩
      have hLeftConfig :=
        hInfer
          context state leftState
          left leftType
          hConfig hLeftInfer
      cases hTypeWhnf :
          whnf context leftState leftType with
      | error error =>
          simp only [hTypeWhnf] at hSuccess
          simp at hSuccess
      | ok reducedRun =>
          simp only [hTypeWhnf] at hSuccess
          rcases reducedRun with ⟨reducedType, reducedState⟩
          have hReducedConfig :=
            (hWhnf
              context leftState reducedState
              leftType reducedType
              hLeftConfig hTypeWhnf).2
          cases hHead : psKernelExprGetAppFn reducedType with
          | const inductName levels =>
              simp only [hHead] at hSuccess
              by_cases hStructure :
                  psKernelEnvironmentIsNonRecStructure
                      context.environment
                      inductName =
                    true
              · rw [if_pos hStructure] at hSuccess
                cases hFind :
                    psKernelEnvironmentFind
                      context.environment
                      inductName with
                | none =>
                    simp only [hFind] at hSuccess
                    simp at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    exact hReducedConfig
                | some info =>
                    simp only [hFind] at hSuccess
                    cases info with
                    | inductInfo inductInfo =>
                        simp only at hSuccess
                        cases hCtors : inductInfo.ctors with
                        | nil =>
                            simp only [hCtors] at hSuccess
                            simp at hSuccess
                            rcases hSuccess with ⟨rfl, rfl⟩
                            exact hReducedConfig
                        | cons ctorName ctorTail =>
                            simp only [hCtors] at hSuccess
                            cases ctorTail with
                            | nil =>
                                simp only at hSuccess
                                cases hCtorFind :
                                    psKernelEnvironmentFind
                                      context.environment
                                      ctorName with
                                | none =>
                                    simp only [hCtorFind] at hSuccess
                                    simp at hSuccess
                                    rcases hSuccess with ⟨rfl, rfl⟩
                                    exact hReducedConfig
                                | some ctorValue =>
                                    simp only [hCtorFind] at hSuccess
                                    cases ctorValue with
                                    | ctorInfo ctor =>
                                        simp only at hSuccess
                                        by_cases hNoFields :
                                            Nat.beq ctor.numFields 0 = true
                                        · rw [if_pos hNoFields] at hSuccess
                                          cases hRightInfer :
                                              inferType
                                                context
                                                reducedState
                                                right with
                                          | error error =>
                                              simp only [hRightInfer] at hSuccess
                                              simp at hSuccess
                                          | ok rightRun =>
                                              simp only [hRightInfer] at hSuccess
                                              rcases rightRun with
                                                ⟨rightType, rightState⟩
                                              have hRightConfig :=
                                                hInfer
                                                  context
                                                  reducedState
                                                  rightState
                                                  right
                                                  rightType
                                                  hReducedConfig
                                                  hRightInfer
                                              exact
                                                (hDefEq
                                                  context
                                                  rightState
                                                  nextState
                                                  reducedType
                                                  rightType
                                                  value
                                                  hRightConfig
                                                  hSuccess).1
                                        · rw [if_neg hNoFields] at hSuccess
                                          simp at hSuccess
                                          rcases hSuccess with ⟨rfl, rfl⟩
                                          exact hReducedConfig
                                    | axiomInfo infoValue =>
                                        simp at hSuccess
                                        rcases hSuccess with ⟨rfl, rfl⟩
                                        exact hReducedConfig
                                    | defnInfo infoValue =>
                                        simp at hSuccess
                                        rcases hSuccess with ⟨rfl, rfl⟩
                                        exact hReducedConfig
                                    | thmInfo infoValue =>
                                        simp at hSuccess
                                        rcases hSuccess with ⟨rfl, rfl⟩
                                        exact hReducedConfig
                                    | opaqueInfo infoValue =>
                                        simp at hSuccess
                                        rcases hSuccess with ⟨rfl, rfl⟩
                                        exact hReducedConfig
                                    | inductInfo infoValue =>
                                        simp at hSuccess
                                        rcases hSuccess with ⟨rfl, rfl⟩
                                        exact hReducedConfig
                                    | recInfo infoValue =>
                                        simp at hSuccess
                                        rcases hSuccess with ⟨rfl, rfl⟩
                                        exact hReducedConfig
                                    | quotInfo infoValue =>
                                        simp at hSuccess
                                        rcases hSuccess with ⟨rfl, rfl⟩
                                        exact hReducedConfig
                            | cons second tail =>
                                simp at hSuccess
                                rcases hSuccess with ⟨rfl, rfl⟩
                                exact hReducedConfig
                    | axiomInfo infoValue =>
                        simp at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact hReducedConfig
                    | defnInfo infoValue =>
                        simp at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact hReducedConfig
                    | thmInfo infoValue =>
                        simp at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact hReducedConfig
                    | opaqueInfo infoValue =>
                        simp at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact hReducedConfig
                    | ctorInfo infoValue =>
                        simp at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact hReducedConfig
                    | recInfo infoValue =>
                        simp at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact hReducedConfig
                    | quotInfo infoValue =>
                        simp at hSuccess
                        rcases hSuccess with ⟨rfl, rfl⟩
                        exact hReducedConfig
              · rw [if_neg hStructure] at hSuccess
                simp at hSuccess
                rcases hSuccess with ⟨rfl, rfl⟩
                exact hReducedConfig
          | bvar index =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig
          | fvar name =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig
          | mvar name =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig
          | sort level =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig
          | app fn arg =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig
          | lam name type body binderInfo =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig
          | forallE name type body binderInfo =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig
          | letE name type value body nondep =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig
          | lit literal =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig
          | mdata metadata body =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig
          | proj typeName index body =>
              simp only [hHead] at hSuccess
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReducedConfig



theorem psKernelDefEqUnitLikeWith_true_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqUnitLikeWith
          defeq inferType whnf
          context state left right =
        Except.ok (Prod.mk true nextState)) :
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  simp only [psKernelDefEqUnitLikeWith] at hSuccess
  cases hLeftInfer :
      inferType context state left with
  | error error =>
      simp only [hLeftInfer] at hSuccess
      simp at hSuccess
  | ok leftRun =>
      simp only [hLeftInfer] at hSuccess
      rcases leftRun with ⟨leftType, leftState⟩
      have hLeftConfig :=
        hInfer
          context state leftState
          left leftType
          hConfig hLeftInfer
      cases hTypeWhnf :
          whnf context leftState leftType with
      | error error =>
          simp only [hTypeWhnf] at hSuccess
          simp at hSuccess
      | ok reducedRun =>
          simp only [hTypeWhnf] at hSuccess
          rcases reducedRun with ⟨reducedType, reducedState⟩
          have hReduced :=
            hWhnf
              context leftState reducedState
              leftType reducedType
              hLeftConfig hTypeWhnf
          cases hHead : psKernelExprGetAppFn reducedType with
          | const inductName levels =>
              simp only [hHead] at hSuccess
              by_cases hStructure :
                  psKernelEnvironmentIsNonRecStructure
                      context.environment
                      inductName =
                    true
              · rw [if_pos hStructure] at hSuccess
                cases hFind :
                    psKernelEnvironmentFind
                      context.environment
                      inductName with
                | none =>
                    simp only [hFind] at hSuccess
                    simp at hSuccess
                | some info =>
                    simp only [hFind] at hSuccess
                    cases info with
                    | inductInfo inductInfo =>
                        simp only at hSuccess
                        cases hCtors : inductInfo.ctors with
                        | nil =>
                            simp only [hCtors] at hSuccess
                            simp at hSuccess
                        | cons ctorName ctorTail =>
                            simp only [hCtors] at hSuccess
                            cases ctorTail with
                            | nil =>
                                simp only at hSuccess
                                cases hCtorFind :
                                    psKernelEnvironmentFind
                                      context.environment
                                      ctorName with
                                | none =>
                                    simp only [hCtorFind] at hSuccess
                                    simp at hSuccess
                                | some ctorValue =>
                                    simp only [hCtorFind] at hSuccess
                                    cases ctorValue with
                                    | ctorInfo ctor =>
                                        simp only at hSuccess
                                        by_cases hNoFields :
                                            Nat.beq ctor.numFields 0 = true
                                        · rw [if_pos hNoFields] at hSuccess
                                          cases hRightInfer :
                                              inferType
                                                context
                                                reducedState
                                                right with
                                          | error error =>
                                              simp only [hRightInfer] at hSuccess
                                              simp at hSuccess
                                          | ok rightRun =>
                                              simp only [hRightInfer] at hSuccess
                                              rcases rightRun with
                                                ⟨rightType, rightState⟩
                                              have hRightConfig :=
                                                hInfer
                                                  context
                                                  reducedState
                                                  rightState
                                                  right
                                                  rightType
                                                  hReduced.2
                                                  hRightInfer
                                              have hTypes :=
                                                (hDefEq
                                                  context
                                                  rightState
                                                  nextState
                                                  reducedType
                                                  rightType
                                                  true
                                                  hRightConfig
                                                  hSuccess).2 rfl
                                              have hLookup :
                                                  PsKernelEnvironmentLookupSound
                                                    context.environment := by
                                                intro name info hEnvironmentFind
                                                unfold psKernelEnvironmentFind at hEnvironmentFind
                                                calc
                                                  psKernelFindConstantInList
                                                      name
                                                      context.environment.constants =
                                                    psKernelFindConstantInList
                                                      name
                                                      (psKernelEnvironmentIndexFind
                                                        context.environment.index
                                                        name) :=
                                                    (hConfig.1 name).symm
                                                  _ = Option.some info :=
                                                    hEnvironmentFind
                                              have hInduct :=
                                                hLookup
                                                  inductName
                                                  (PsKernelConstantInfo.inductInfo
                                                    inductInfo)
                                                  hFind
                                              have hCtor :=
                                                hLookup
                                                  ctorName
                                                  (PsKernelConstantInfo.ctorInfo
                                                    ctor)
                                                  hCtorFind
                                              have hTypeHead :
                                                  psKernelExprGetAppFn reducedType =
                                                    PsKernelExpr.const
                                                      inductName
                                                      (match
                                                        psKernelExprGetAppFn
                                                          reducedType with
                                                       | PsKernelExpr.const _ foundLevels =>
                                                           foundLevels
                                                       | _ => List.nil) := by
                                                simpa [hHead] using hHead
                                              have hNoFieldsEq :
                                                  ctor.numFields = 0 := by
                                                simpa using hNoFields
                                              exact
                                                PsKernelDefEqJudgment.unitLike
                                                  left
                                                  right
                                                  leftType
                                                  rightType
                                                  reducedType
                                                  inductName
                                                  ctorName
                                                  inductInfo
                                                  ctor
                                                  hReduced.1
                                                  hTypeHead
                                                  hStructure
                                                  hInduct
                                                  hCtors
                                                  hCtor
                                                  hNoFieldsEq
                                                  hTypes
                                        · rw [if_neg hNoFields] at hSuccess
                                          simp at hSuccess
                                    | axiomInfo infoValue =>
                                        simp at hSuccess
                                    | defnInfo infoValue =>
                                        simp at hSuccess
                                    | thmInfo infoValue =>
                                        simp at hSuccess
                                    | opaqueInfo infoValue =>
                                        simp at hSuccess
                                    | inductInfo infoValue =>
                                        simp at hSuccess
                                    | recInfo infoValue =>
                                        simp at hSuccess
                                    | quotInfo infoValue =>
                                        simp at hSuccess
                            | cons second tail =>
                                simp at hSuccess
                    | axiomInfo infoValue =>
                        simp at hSuccess
                    | defnInfo infoValue =>
                        simp at hSuccess
                    | thmInfo infoValue =>
                        simp at hSuccess
                    | opaqueInfo infoValue =>
                        simp at hSuccess
                    | ctorInfo infoValue =>
                        simp at hSuccess
                    | recInfo infoValue =>
                        simp at hSuccess
                    | quotInfo infoValue =>
                        simp at hSuccess
              · rw [if_neg hStructure] at hSuccess
                simp at hSuccess
          | bvar index =>
              simp only [hHead] at hSuccess
              simp at hSuccess
          | fvar name =>
              simp only [hHead] at hSuccess
              simp at hSuccess
          | mvar name =>
              simp only [hHead] at hSuccess
              simp at hSuccess
          | sort level =>
              simp only [hHead] at hSuccess
              simp at hSuccess
          | app fn arg =>
              simp only [hHead] at hSuccess
              simp at hSuccess
          | lam name type body binderInfo =>
              simp only [hHead] at hSuccess
              simp at hSuccess
          | forallE name type body binderInfo =>
              simp only [hHead] at hSuccess
              simp at hSuccess
          | letE name type value body nondep =>
              simp only [hHead] at hSuccess
              simp at hSuccess
          | lit literal =>
              simp only [hHead] at hSuccess
              simp at hSuccess
          | mdata metadata body =>
              simp only [hHead] at hSuccess
              simp at hSuccess
          | proj typeName index body =>
              simp only [hHead] at hSuccess
              simp at hSuccess



theorem psKernelDefEqUnitLikeWith_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqUnitLikeWith
          defeq inferType whnf
          context state left right =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right) := by
  constructor
  · exact
      psKernelDefEqUnitLikeWith_configuration_preserves
        defeq
        inferType
        whnf
        hDefEq
        hInfer
        hWhnf
        context
        state
        nextState
        left
        right
        value
        hConfig
        hSuccess
  · intro hValue
    cases value with
    | false =>
        simp at hValue
    | true =>
        exact
          psKernelDefEqUnitLikeWith_true_refines
            defeq
            inferType
            whnf
            hDefEq
            hInfer
            hWhnf
            context
            state
            nextState
            left
            right
            hConfig
            hSuccess

theorem psKernelDefEqStringLitExpansionCoreWith_true_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqStringLitExpansionCoreWith
          defeq whnf context state left right =
        Except.ok (Prod.mk (Option.some true) nextState)) :
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  simp only [psKernelDefEqStringLitExpansionCoreWith] at hSuccess
  cases left with
  | lit literal =>
      cases literal with
      | str value =>
          simp only at hSuccess
          by_cases hString :
              psKernelExprIsStringOfListApp right = true
          · rw [if_pos hString] at hSuccess
            cases hWhnfRun :
                whnf
                  context
                  state
                  (psKernelStringLitToConstructor value) with
            | error error =>
                simp only [hWhnfRun] at hSuccess
                simp at hSuccess
            | ok whnfRun =>
                simp only [hWhnfRun] at hSuccess
                rcases whnfRun with ⟨expanded, whnfState⟩
                have hWhnfSemantic :=
                  hWhnf
                    context state whnfState
                    (psKernelStringLitToConstructor value)
                    expanded
                    hConfig hWhnfRun
                cases hEqRun :
                    defeq
                      context
                      whnfState
                      expanded
                      right with
                | error error =>
                    simp only [hEqRun] at hSuccess
                    simp at hSuccess
                | ok eqRun =>
                    simp only [hEqRun] at hSuccess
                    rcases eqRun with ⟨eqValue, eqState⟩
                    simp at hSuccess
                    rcases hSuccess with ⟨rfl, rfl⟩
                    have hEqSemantic :=
                      (hDefEq
                        context
                        whnfState
                        eqState
                        expanded
                        right
                        true
                        hWhnfSemantic.2
                        hEqRun).2 rfl
                    have hLiteralReduction :
                        PsKernelReductionClosure
                          context.environment
                          context.localContext
                          (PsKernelExpr.lit
                            (PsKernelLiteral.str value))
                          expanded :=
                      PsKernelReductionClosure.cons
                        (PsKernelExpr.lit
                          (PsKernelLiteral.str value))
                        (psKernelStringLitToConstructor value)
                        expanded
                        (PsKernelReductionStep.stringLiteral value)
                        hWhnfSemantic.1
                    exact
                      PsKernelDefEqJudgment.reduceCompare
                        (PsKernelExpr.lit
                          (PsKernelLiteral.str value))
                        right
                        expanded
                        right
                        hLiteralReduction
                        (PsKernelReductionClosure.refl right)
                        hEqSemantic
          · rw [if_neg hString] at hSuccess
            simp at hSuccess
      | nat value =>
          simp at hSuccess
  | _ =>
      simp at hSuccess


theorem psKernelDefEqStringLitExpansionWith_true_refines
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqStringLitExpansionWith
          defeq whnf context state left right =
        Except.ok (Prod.mk (Option.some true) nextState)) :
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  simp only [psKernelDefEqStringLitExpansionWith] at hSuccess
  cases hFirst :
      psKernelDefEqStringLitExpansionCoreWith
        defeq whnf context state left right with
  | error error =>
      simp only [hFirst] at hSuccess
      simp at hSuccess
  | ok firstRun =>
      simp only [hFirst] at hSuccess
      rcases firstRun with ⟨firstAnswer, firstState⟩
      have hFirstConfig :=
        psKernelDefEqStringLitExpansionCoreWith_configuration_preserves
          defeq whnf hDefEq hWhnf
          context state firstState
          left right firstAnswer
          hConfig hFirst
      cases firstAnswer with
      | some firstValue =>
          cases firstValue with
          | false =>
              simp at hSuccess
          | true =>
              exact
                psKernelDefEqStringLitExpansionCoreWith_true_refines
                  defeq whnf hDefEq hWhnf
                  context state firstState
                  left right hConfig hFirst
      | none =>
          cases hSecond :
              psKernelDefEqStringLitExpansionCoreWith
                defeq whnf
                context firstState right left with
          | error error =>
              simp only [hSecond] at hSuccess
              simp at hSuccess
          | ok secondRun =>
              simp only [hSecond] at hSuccess
              rcases secondRun with ⟨secondAnswer, secondState⟩
              cases secondAnswer with
              | none =>
                  simp at hSuccess
              | some secondValue =>
                  cases secondValue with
                  | false =>
                      simp at hSuccess
                  | true =>
                      exact
                        PsKernelDefEqJudgment.symm
                          right
                          left
                          (psKernelDefEqStringLitExpansionCoreWith_true_refines
                            defeq whnf hDefEq hWhnf
                            context firstState secondState
                            right left hFirstConfig hSecond)


theorem psKernelDefEqStringLitExpansionWith_optional_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : Option Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqStringLitExpansionWith
          defeq whnf context state left right =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelOptionalDefEqPostcondition
      context nextState left right answer := by
  refine
    ⟨
      psKernelDefEqStringLitExpansionWith_configuration_preserves
        defeq whnf hDefEq hWhnf
        context state nextState
        left right answer
        hConfig hSuccess,
      ?_
    ⟩
  cases answer with
  | none =>
      trivial
  | some value =>
      cases value with
      | false =>
          trivial
      | true =>
          exact
            psKernelDefEqStringLitExpansionWith_true_refines
              defeq whnf hDefEq hWhnf
              context state nextState
              left right hConfig hSuccess
