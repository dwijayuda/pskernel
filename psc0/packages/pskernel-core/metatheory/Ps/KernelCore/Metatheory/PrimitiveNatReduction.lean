import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.ReductionCongruence

/-
Semantic refinement for the primitive Nat reduction pipeline used by public
WHNF.  This module deliberately proves the executable primitive table rather
than postulating it as a soundness assumption.
-/


theorem psKernelExprNatLiteralValue_some_refines_literal
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (expr : PsKernelExpr)
    (value : Nat)
    (hValue :
      psKernelExprNatLiteralValue expr =
        Option.some value) :
    PsKernelReductionClosure
      environment
      localContext
      expr
      (PsKernelExpr.lit (PsKernelLiteral.nat value)) := by
  cases expr with
  | lit literal =>
      cases literal with
      | nat candidate =>
          simp [psKernelExprNatLiteralValue] at hValue
          subst value
          exact
            PsKernelReductionClosure.refl
              (PsKernelExpr.lit
                (PsKernelLiteral.nat candidate))
      | str text =>
          simp [psKernelExprNatLiteralValue] at hValue
  | const name levels =>
      cases levels with
      | nil =>
          cases hName :
              psKernelNameEq name psKernelNatZeroName with
          | false =>
              simp [
                psKernelExprNatLiteralValue,
                hName
              ] at hValue
          | true =>
              simp [
                psKernelExprNatLiteralValue,
                hName
              ] at hValue
              subst value
              exact
                PsKernelReductionClosure.cons
                  (PsKernelExpr.const name List.nil)
                  (PsKernelExpr.lit (PsKernelLiteral.nat 0))
                  (PsKernelExpr.lit (PsKernelLiteral.nat 0))
                  (PsKernelReductionStep.natZeroLiteral
                    name
                    hName)
                  (PsKernelReductionClosure.refl
                    (PsKernelExpr.lit
                      (PsKernelLiteral.nat 0)))
      | cons level rest =>
          simp [psKernelExprNatLiteralValue] at hValue
  | bvar index =>
      simp [psKernelExprNatLiteralValue] at hValue
  | fvar name =>
      simp [psKernelExprNatLiteralValue] at hValue
  | mvar name =>
      simp [psKernelExprNatLiteralValue] at hValue
  | sort level =>
      simp [psKernelExprNatLiteralValue] at hValue
  | app fn arg =>
      simp [psKernelExprNatLiteralValue] at hValue
  | lam name type body binderInfo =>
      simp [psKernelExprNatLiteralValue] at hValue
  | forallE name type body binderInfo =>
      simp [psKernelExprNatLiteralValue] at hValue
  | letE name type value body nondep =>
      simp [psKernelExprNatLiteralValue] at hValue
  | mdata metadata body =>
      simp [psKernelExprNatLiteralValue] at hValue
  | proj typeName index body =>
      simp [psKernelExprNatLiteralValue] at hValue
theorem psKernelReduceNatBinary_some_refines_step
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize : Nat)
    (op : PsKernelName)
    (left right : Nat)
    (result : PsKernelExpr)
    (hSuccess :
      psKernelReduceNatBinary
          maxNatSize
          op
          left
          right =
        Except.ok (Option.some result)) :
    PsKernelReductionStep
      environment
      localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      result := by
  cases hAdd :
      psKernelNameEq op psKernelNatAddName with
  | true =>
      cases hSize :
          psKernelCheckNatSize
            maxNatSize
            (Nat.add left right) with
      | error error =>
          simp_all [psKernelReduceNatBinary]
      | ok checked =>
          simp_all [psKernelReduceNatBinary]
          subst result
          exact
            PsKernelReductionStep.natAdd
              op left right hAdd
  | false =>
      cases hSub :
          psKernelNameEq op psKernelNatSubName with
      | true =>
          cases hSize :
              psKernelCheckNatSize
                maxNatSize
                (Nat.sub left right) with
          | error error =>
              simp_all [psKernelReduceNatBinary]
          | ok checked =>
              simp_all [psKernelReduceNatBinary]
              subst result
              exact
                PsKernelReductionStep.natSub
                  op left right hSub
      | false =>
          cases hMul :
              psKernelNameEq op psKernelNatMulName with
          | true =>
              cases hSize :
                  psKernelCheckNatSize
                    maxNatSize
                    (Nat.mul left right) with
              | error error =>
                  simp_all [psKernelReduceNatBinary]
              | ok checked =>
                  simp_all [psKernelReduceNatBinary]
                  subst result
                  exact
                    PsKernelReductionStep.natMul
                      op left right hMul
          | false =>
              cases hPow :
                  psKernelNameEq op psKernelNatPowName with
              | true =>
                  cases hCount :
                      psKernelCheckCountArg
                        "Nat.pow"
                        right with
                  | error error =>
                      simp_all [psKernelReduceNatBinary]
                  | ok checked =>
                      cases hGt :
                          psKernelNatGt left 1 with
                      | false =>
                          simp_all [psKernelReduceNatBinary]
                          subst result
                          exact
                            PsKernelReductionStep.natPow
                              op left right hPow
                      | true =>
                          cases hZero :
                              Nat.beq right 0 with
                          | true =>
                              simp_all [psKernelReduceNatBinary]
                              subst result
                              simpa [hZero] using
                                (PsKernelReductionStep.natPowZero
                                  op left right hPow hZero)
                          | false =>
                              cases hTooBig :
                                  psKernelNatGt
                                    (psKernelNatSizeInBytes left)
                                    (Nat.div maxNatSize right) with
                              | true =>
                                  simp_all [psKernelReduceNatBinary]
                              | false =>
                                  simp_all [psKernelReduceNatBinary]
                                  subst result
                                  exact
                                    PsKernelReductionStep.natPow
                                      op left right hPow
              | false =>
                  cases hGcd :
                      psKernelNameEq op psKernelNatGcdName with
                  | true =>
                      simp_all [psKernelReduceNatBinary]
                      subst result
                      exact
                        PsKernelReductionStep.natGcd
                          op left right hGcd
                  | false =>
                      cases hMod :
                          psKernelNameEq op psKernelNatModName with
                      | true =>
                          simp_all [psKernelReduceNatBinary]
                          subst result
                          simpa using
                            (PsKernelReductionStep.natMod
                              op left right hMod)
                      | false =>
                          cases hDiv :
                              psKernelNameEq op psKernelNatDivName with
                          | true =>
                              simp_all [psKernelReduceNatBinary]
                              subst result
                              simpa using
                                (PsKernelReductionStep.natDiv
                                  op left right hDiv)
                          | false =>
                              cases hBeq :
                                  psKernelNameEq op psKernelNatBeqName with
                              | true =>
                                  simp_all [psKernelReduceNatBinary]
                                  subst result
                                  exact
                                    PsKernelReductionStep.natBeq
                                      op left right hBeq
                              | false =>
                                  cases hBle :
                                      psKernelNameEq op psKernelNatBleName with
                                  | true =>
                                      simp_all [psKernelReduceNatBinary]
                                      subst result
                                      exact
                                        PsKernelReductionStep.natBle
                                          op left right hBle
                                  | false =>
                                      cases hLand :
                                          psKernelNameEq op psKernelNatLandName with
                                      | true =>
                                          simp_all [psKernelReduceNatBinary]
                                          subst result
                                          exact
                                            PsKernelReductionStep.natLand
                                              op left right hLand
                                      | false =>
                                          cases hLor :
                                              psKernelNameEq op psKernelNatLorName with
                                          | true =>
                                              simp_all [psKernelReduceNatBinary]
                                              subst result
                                              exact
                                                PsKernelReductionStep.natLor
                                                  op left right hLor
                                          | false =>
                                              cases hXor :
                                                  psKernelNameEq op psKernelNatXorName with
                                              | true =>
                                                  simp_all [psKernelReduceNatBinary]
                                                  subst result
                                                  exact
                                                    PsKernelReductionStep.natXor
                                                      op left right hXor
                                              | false =>
                                                  cases hShiftLeft :
                                                      psKernelNameEq op psKernelNatShiftLeftName with
                                                  | true =>
                                                      cases hLeftZero :
                                                          Nat.beq left 0 with
                                                      | true =>
                                                          simp_all [psKernelReduceNatBinary]
                                                          subst result
                                                          simpa [hLeftZero] using
                                                            (PsKernelReductionStep.natShiftLeftZero
                                                              op left right hShiftLeft hLeftZero)
                                                      | false =>
                                                          cases hCount :
                                                              psKernelCheckCountArg
                                                                "Nat.shiftLeft"
                                                                right with
                                                          | error error =>
                                                              simp_all [psKernelReduceNatBinary]
                                                          | ok checked =>
                                                              cases hTooBig :
                                                                  psKernelNatGt
                                                                    (Nat.add
                                                                      (Nat.add
                                                                        (psKernelNatSizeInBytes left)
                                                                        (Nat.div right 8))
                                                                      1)
                                                                    maxNatSize with
                                                              | true =>
                                                                  simp_all [psKernelReduceNatBinary]
                                                              | false =>
                                                                  simp_all [psKernelReduceNatBinary]
                                                                  subst result
                                                                  exact
                                                                    PsKernelReductionStep.natShiftLeft
                                                                      op left right hShiftLeft
                                                  | false =>
                                                      cases hShiftRight :
                                                          psKernelNameEq op psKernelNatShiftRightName with
                                                      | true =>
                                                          simp_all [psKernelReduceNatBinary]
                                                          subst result
                                                          exact
                                                            PsKernelReductionStep.natShiftRight
                                                              op left right hShiftRight
                                                      | false =>
                                                          simp_all [psKernelReduceNatBinary]


theorem psKernelReduceNatBinary_some_refines
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (maxNatSize : Nat)
    (op : PsKernelName)
    (left right : Nat)
    (result : PsKernelExpr)
    (hSuccess :
      psKernelReduceNatBinary
          maxNatSize
          op
          left
          right =
        Except.ok (Option.some result)) :
    PsKernelReductionClosure
      environment
      localContext
      (PsKernelExpr.app
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat left)))
        (PsKernelExpr.lit (PsKernelLiteral.nat right)))
      result :=
  PsKernelReductionClosure.cons
    (PsKernelExpr.app
      (PsKernelExpr.app
        (PsKernelExpr.const op List.nil)
        (PsKernelExpr.lit (PsKernelLiteral.nat left)))
      (PsKernelExpr.lit (PsKernelLiteral.nat right)))
    result
    result
    (psKernelReduceNatBinary_some_refines_step
      environment
      localContext
      maxNatSize
      op
      left
      right
      result
      hSuccess)
    (PsKernelReductionClosure.refl result)


theorem psKernelReduceNatWith_preserves_configuration
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound publicWhnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (answer : Option PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelReduceNatWith
          publicWhnf
          context
          state
          expr =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  cases expr with
  | app fn right =>
      cases fn with
      | const op levels =>
          cases levels with
          | nil =>
              cases hSucc :
                  psKernelNameEq op psKernelNatSuccName with
              | false =>
                  simp [psKernelReduceNatWith, hSucc] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hConfig
              | true =>
                  cases hRight :
                      publicWhnf context state right with
                  | error error =>
                      simp [
                        psKernelReduceNatWith,
                        hSucc,
                        hRight
                      ] at hSuccess
                  | ok rightRun =>
                      rcases rightRun with ⟨rightReduced, state1⟩
                      have hRightSemantic :=
                        hWhnf
                          context
                          state
                          state1
                          right
                          rightReduced
                          hConfig
                          hRight
                      cases hLiteral :
                          psKernelExprNatLiteralValue rightReduced with
                      | none =>
                          simp [
                            psKernelReduceNatWith,
                            hSucc,
                            hRight,
                            hLiteral
                          ] at hSuccess
                          rcases hSuccess with ⟨rfl, rfl⟩
                          exact hRightSemantic.2
                      | some value =>
                          cases hSize :
                              psKernelCheckNatSize
                                context.maxNatSize
                                (Nat.succ value) with
                          | error error =>
                              simp [
                                psKernelReduceNatWith,
                                hSucc,
                                hRight,
                                hLiteral,
                                hSize
                              ] at hSuccess
                          | ok checked =>
                              simp [
                                psKernelReduceNatWith,
                                hSucc,
                                hRight,
                                hLiteral,
                                hSize
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact hRightSemantic.2
          | cons level rest =>
              simp [psKernelReduceNatWith] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
      | app binaryHead left =>
          cases binaryHead with
          | const op levels =>
              cases levels with
              | nil =>
                  cases hOp : psKernelNatBinarySupported op with
                  | false =>
                      simp [psKernelReduceNatWith, hOp] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact hConfig
                  | true =>
                      cases hLeft :
                          publicWhnf context state left with
                      | error error =>
                          simp [
                            psKernelReduceNatWith, hOp,
                            hLeft
                          ] at hSuccess
                      | ok leftRun =>
                          rcases leftRun with ⟨leftReduced, state1⟩
                          have hLeftSemantic :=
                            hWhnf
                              context
                              state
                              state1
                              left
                              leftReduced
                              hConfig
                              hLeft
                          cases hLeftLiteral : psKernelExprNatLiteralValue leftReduced with
                          | none =>
                              simp [psKernelReduceNatWith, hOp, hLeft, hLeftLiteral] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact hLeftSemantic.2
                          | some leftValue =>
                              cases hRight :
                                  publicWhnf context state1 right with
                              | error error =>
                                  simp [
                                    psKernelReduceNatWith, hOp, hLeftLiteral,
                                    hLeft,
                                    hRight
                                  ] at hSuccess
                              | ok rightRun =>
                                  rcases rightRun with ⟨rightReduced, state2⟩
                                  have hRightSemantic :=
                                    hWhnf
                                      context
                                      state1
                                      state2
                                      right
                                      rightReduced
                                      hLeftSemantic.2
                                      hRight
                                  cases hRightLiteral :
                                      psKernelExprNatLiteralValue rightReduced with
                                  | none =>
                                      simp [
                                        psKernelReduceNatWith, hOp, hLeftLiteral,
                                        hLeft,
                                        hRight,
                                        hLeftLiteral,
                                        hRightLiteral
                                      ] at hSuccess
                                      rcases hSuccess with ⟨rfl, rfl⟩
                                      exact hRightSemantic.2
                                  | some rightValue =>
                                      cases hBinary :
                                          psKernelReduceNatBinary
                                            context.maxNatSize
                                            op
                                            leftValue
                                            rightValue with
                                      | error error =>
                                          simp [
                                            psKernelReduceNatWith, hOp, hLeftLiteral,
                                            hLeft,
                                            hRight,
                                            hLeftLiteral,
                                            hRightLiteral,
                                            hBinary
                                          ] at hSuccess
                                      | ok binaryAnswer =>
                                          simp [
                                            psKernelReduceNatWith, hOp, hLeftLiteral,
                                            hLeft,
                                            hRight,
                                            hLeftLiteral,
                                            hRightLiteral,
                                            hBinary
                                          ] at hSuccess
                                          rcases hSuccess with ⟨rfl, rfl⟩
                                          exact hRightSemantic.2
              | cons level rest =>
                  simp [psKernelReduceNatWith] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hConfig
          | _ =>
              simp [psKernelReduceNatWith] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
      | _ =>
          simp [psKernelReduceNatWith] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hConfig
  | _ =>
      simp [psKernelReduceNatWith] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig


theorem psKernelReduceNatWith_some_refines
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound publicWhnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelReduceNatWith
          publicWhnf
          context
          state
          expr =
        Except.ok
          (Prod.mk (Option.some result) nextState)) :
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result := by
  cases expr with
  | app fn right =>
      cases fn with
      | const op levels =>
          cases levels with
          | nil =>
              cases hSucc :
                  psKernelNameEq op psKernelNatSuccName with
              | false =>
                  simp [psKernelReduceNatWith, hSucc] at hSuccess
              | true =>
                  cases hRight :
                      publicWhnf context state right with
                  | error error =>
                      simp [
                        psKernelReduceNatWith,
                        hSucc,
                        hRight
                      ] at hSuccess
                  | ok rightRun =>
                      rcases rightRun with ⟨rightReduced, state1⟩
                      have hRightSemantic :=
                        hWhnf
                          context
                          state
                          state1
                          right
                          rightReduced
                          hConfig
                          hRight
                      cases hLiteral :
                          psKernelExprNatLiteralValue rightReduced with
                      | none =>
                          simp [
                            psKernelReduceNatWith,
                            hSucc,
                            hRight,
                            hLiteral
                          ] at hSuccess
                      | some value =>
                          have hRightLiteralReduction :=
                            psKernelExprNatLiteralValue_some_refines_literal
                              context.environment
                              context.localContext
                              rightReduced
                              value
                              hLiteral
                          have hRightToLiteral :=
                            psKernelReductionClosure_transitive
                              context.environment
                              context.localContext
                              right
                              rightReduced
                              (PsKernelExpr.lit
                                (PsKernelLiteral.nat value))
                              hRightSemantic.1
                              hRightLiteralReduction
                          cases hSize :
                              psKernelCheckNatSize
                                context.maxNatSize
                                (Nat.succ value) with
                          | error error =>
                              simp [
                                psKernelReduceNatWith,
                                hSucc,
                                hRight,
                                hLiteral,
                                hSize
                              ] at hSuccess
                          | ok checked =>
                              simp [
                                psKernelReduceNatWith,
                                hSucc,
                                hRight,
                                hLiteral,
                                hSize
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              have hArg :
                                  PsKernelReductionClosure
                                    context.environment
                                    context.localContext
                                    (PsKernelExpr.app
                                      (PsKernelExpr.const op List.nil)
                                      right)
                                    (PsKernelExpr.app
                                      (PsKernelExpr.const op List.nil)
                                      (PsKernelExpr.lit
                                        (PsKernelLiteral.nat value))) :=
                                PsKernelReductionClosure.appArg
                                  (PsKernelExpr.const op List.nil)
                                  right
                                  (PsKernelExpr.lit
                                    (PsKernelLiteral.nat value))
                                  hRightToLiteral
                              have hPrimitive :
                                  PsKernelReductionClosure
                                    context.environment
                                    context.localContext
                                    (PsKernelExpr.app
                                      (PsKernelExpr.const op List.nil)
                                      (PsKernelExpr.lit
                                        (PsKernelLiteral.nat value)))
                                    (PsKernelExpr.lit
                                      (PsKernelLiteral.nat
                                        (Nat.succ value))) :=
                                PsKernelReductionClosure.cons
                                  (PsKernelExpr.app
                                    (PsKernelExpr.const op List.nil)
                                    (PsKernelExpr.lit
                                      (PsKernelLiteral.nat value)))
                                  (PsKernelExpr.lit
                                    (PsKernelLiteral.nat
                                      (Nat.succ value)))
                                  (PsKernelExpr.lit
                                    (PsKernelLiteral.nat
                                      (Nat.succ value)))
                                  (PsKernelReductionStep.natSucc
                                    op value hSucc)
                                  (PsKernelReductionClosure.refl
                                    (PsKernelExpr.lit
                                      (PsKernelLiteral.nat
                                        (Nat.succ value))))
                              exact
                                psKernelReductionClosure_transitive
                                  context.environment
                                  context.localContext
                                  (PsKernelExpr.app
                                    (PsKernelExpr.const op List.nil)
                                    right)
                                  (PsKernelExpr.app
                                    (PsKernelExpr.const op List.nil)
                                    (PsKernelExpr.lit
                                      (PsKernelLiteral.nat value)))
                                  (PsKernelExpr.lit
                                    (PsKernelLiteral.nat
                                      (Nat.succ value)))
                                  hArg
                                  hPrimitive
          | cons level rest =>
              simp [psKernelReduceNatWith] at hSuccess
      | app binaryHead left =>
          cases binaryHead with
          | const op levels =>
              cases levels with
              | nil =>
                  cases hOp : psKernelNatBinarySupported op with
                  | false =>
                      simp [psKernelReduceNatWith, hOp] at hSuccess
                  | true =>
                      cases hLeft :
                          publicWhnf context state left with
                      | error error =>
                          simp [psKernelReduceNatWith, hOp, hLeft] at hSuccess
                      | ok leftRun =>
                          rcases leftRun with ⟨leftReduced, state1⟩
                          have hLeftSemantic :=
                            hWhnf
                              context
                              state
                              state1
                              left
                              leftReduced
                              hConfig
                              hLeft
                          cases hLeftLiteral : psKernelExprNatLiteralValue leftReduced with
                          | none =>
                              simp [psKernelReduceNatWith, hOp, hLeft, hLeftLiteral] at hSuccess
                          | some leftValue =>
                              cases hRight :
                                  publicWhnf context state1 right with
                              | error error =>
                                  simp [
                                    psKernelReduceNatWith, hOp, hLeftLiteral,
                                    hLeft,
                                    hRight
                                  ] at hSuccess
                              | ok rightRun =>
                                  rcases rightRun with ⟨rightReduced, state2⟩
                                  have hRightSemantic :=
                                    hWhnf
                                      context
                                      state1
                                      state2
                                      right
                                      rightReduced
                                      hLeftSemantic.2
                                      hRight
                                  have hLeftLiteralReduction :=
                                    psKernelExprNatLiteralValue_some_refines_literal
                                      context.environment
                                      context.localContext
                                      leftReduced
                                      leftValue
                                      hLeftLiteral
                                  have hLeftToLiteral :=
                                    psKernelReductionClosure_transitive
                                      context.environment
                                      context.localContext
                                      left
                                      leftReduced
                                      (PsKernelExpr.lit
                                        (PsKernelLiteral.nat leftValue))
                                      hLeftSemantic.1
                                      hLeftLiteralReduction
                                  cases hRightLiteral :
                                      psKernelExprNatLiteralValue rightReduced with
                                  | none =>
                                      simp [
                                        psKernelReduceNatWith, hOp, hLeftLiteral,
                                        hLeft,
                                        hRight,
                                        hLeftLiteral,
                                        hRightLiteral
                                      ] at hSuccess
                                  | some rightValue =>
                                      have hRightLiteralReduction :=
                                        psKernelExprNatLiteralValue_some_refines_literal
                                          context.environment
                                          context.localContext
                                          rightReduced
                                          rightValue
                                          hRightLiteral
                                      have hRightToLiteral :=
                                        psKernelReductionClosure_transitive
                                          context.environment
                                          context.localContext
                                          right
                                          rightReduced
                                          (PsKernelExpr.lit
                                            (PsKernelLiteral.nat rightValue))
                                          hRightSemantic.1
                                          hRightLiteralReduction
                                      cases hBinary :
                                          psKernelReduceNatBinary
                                            context.maxNatSize
                                            op
                                            leftValue
                                            rightValue with
                                      | error error =>
                                          simp [
                                            psKernelReduceNatWith, hOp, hLeftLiteral,
                                            hLeft,
                                            hRight,
                                            hLeftLiteral,
                                            hRightLiteral,
                                            hBinary
                                          ] at hSuccess
                                      | ok binaryAnswer =>
                                          cases binaryAnswer with
                                          | none =>
                                              simp [
                                                psKernelReduceNatWith, hOp, hLeftLiteral,
                                                hLeft,
                                                hRight,
                                                hLeftLiteral,
                                                hRightLiteral,
                                                hBinary
                                              ] at hSuccess
                                          | some binaryResult =>
                                              have hBinarySemantic :=
                                                psKernelReduceNatBinary_some_refines
                                                  context.environment
                                                  context.localContext
                                                  context.maxNatSize
                                                  op
                                                  leftValue
                                                  rightValue
                                                  binaryResult
                                                  hBinary
                                              simp [
                                                psKernelReduceNatWith, hOp, hLeftLiteral,
                                                hLeft,
                                                hRight,
                                                hLeftLiteral,
                                                hRightLiteral,
                                                hBinary
                                              ] at hSuccess
                                              rcases hSuccess with ⟨rfl, rfl⟩
                                              have hLeftInner :
                                                  PsKernelReductionClosure
                                                    context.environment
                                                    context.localContext
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.const op List.nil)
                                                      left)
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.const op List.nil)
                                                      (PsKernelExpr.lit
                                                        (PsKernelLiteral.nat
                                                          leftValue))) :=
                                                PsKernelReductionClosure.appArg
                                                  (PsKernelExpr.const op List.nil)
                                                  left
                                                  (PsKernelExpr.lit
                                                    (PsKernelLiteral.nat
                                                      leftValue))
                                                  hLeftToLiteral
                                              have hLeftOuter :
                                                  PsKernelReductionClosure
                                                    context.environment
                                                    context.localContext
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.app
                                                        (PsKernelExpr.const op List.nil)
                                                        left)
                                                      right)
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.app
                                                        (PsKernelExpr.const op List.nil)
                                                        (PsKernelExpr.lit
                                                          (PsKernelLiteral.nat
                                                            leftValue)))
                                                      right) :=
                                                PsKernelReductionClosure.appFn
                                                  (PsKernelExpr.app
                                                    (PsKernelExpr.const op List.nil)
                                                    left)
                                                  (PsKernelExpr.app
                                                    (PsKernelExpr.const op List.nil)
                                                    (PsKernelExpr.lit
                                                      (PsKernelLiteral.nat
                                                        leftValue)))
                                                  right
                                                  hLeftInner
                                              have hRightOuter :
                                                  PsKernelReductionClosure
                                                    context.environment
                                                    context.localContext
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.app
                                                        (PsKernelExpr.const op List.nil)
                                                        (PsKernelExpr.lit
                                                          (PsKernelLiteral.nat
                                                            leftValue)))
                                                      right)
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.app
                                                        (PsKernelExpr.const op List.nil)
                                                        (PsKernelExpr.lit
                                                          (PsKernelLiteral.nat
                                                            leftValue)))
                                                      (PsKernelExpr.lit
                                                        (PsKernelLiteral.nat
                                                          rightValue))) :=
                                                PsKernelReductionClosure.appArg
                                                  (PsKernelExpr.app
                                                    (PsKernelExpr.const op List.nil)
                                                    (PsKernelExpr.lit
                                                      (PsKernelLiteral.nat
                                                        leftValue)))
                                                  right
                                                  (PsKernelExpr.lit
                                                    (PsKernelLiteral.nat
                                                      rightValue))
                                                  hRightToLiteral
                                              have hOperands :=
                                                psKernelReductionClosure_transitive
                                                  context.environment
                                                  context.localContext
                                                  (PsKernelExpr.app
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.const op List.nil)
                                                      left)
                                                    right)
                                                  (PsKernelExpr.app
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.const op List.nil)
                                                      (PsKernelExpr.lit
                                                        (PsKernelLiteral.nat
                                                          leftValue)))
                                                    right)
                                                  (PsKernelExpr.app
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.const op List.nil)
                                                      (PsKernelExpr.lit
                                                        (PsKernelLiteral.nat
                                                          leftValue)))
                                                    (PsKernelExpr.lit
                                                      (PsKernelLiteral.nat
                                                        rightValue)))
                                                  hLeftOuter
                                                  hRightOuter
                                              exact
                                                psKernelReductionClosure_transitive
                                                  context.environment
                                                  context.localContext
                                                  (PsKernelExpr.app
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.const op List.nil)
                                                      left)
                                                    right)
                                                  (PsKernelExpr.app
                                                    (PsKernelExpr.app
                                                      (PsKernelExpr.const op List.nil)
                                                      (PsKernelExpr.lit
                                                        (PsKernelLiteral.nat
                                                          leftValue)))
                                                    (PsKernelExpr.lit
                                                      (PsKernelLiteral.nat
                                                        rightValue)))
                                                  binaryResult
                                                  hOperands
                                                  hBinarySemantic
              | cons level rest =>
                  simp [psKernelReduceNatWith] at hSuccess
          | _ =>
              simp [psKernelReduceNatWith] at hSuccess
      | _ =>
          simp [psKernelReduceNatWith] at hSuccess
  | _ =>
      simp [psKernelReduceNatWith] at hSuccess


theorem psKernelReduceNatWith_configuration_sound
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound publicWhnf) :
    PsKernelOptionalReductionConfigurationSound
      (psKernelReduceNatWith publicWhnf) := by
  intro
    context state nextState expr answer
    hConfig hSuccess
  constructor
  · exact
      psKernelReduceNatWith_preserves_configuration
        publicWhnf
        hWhnf
        context
        state
        nextState
        expr
        answer
        hConfig
        hSuccess
  · cases answer with
    | none =>
        trivial
    | some result =>
        exact
          psKernelReduceNatWith_some_refines
            publicWhnf
            hWhnf
            context
            state
            nextState
            expr
            result
            hConfig
            hSuccess
