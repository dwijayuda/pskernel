import Ps.KernelCore.Metatheory.DefEqLazyContinuation
import Ps.KernelCore.Metatheory.PrimitiveNatReduction
import Ps.KernelCore.Metatheory.DefEqQuickConfiguration

/-
Reusable fuel-driven LazyDelta proof infrastructure.

The executable fast Nat-reduction stage is intentionally optional:
an eager comparison invokes the independently proved primitive reducer,
whereas a non-eager comparison returns an unchanged configuration and an
undecided reduction. Both branches refine the same semantic postcondition.
-/

theorem psKernelLazyOptionalNat_configuration_sound
    (eager : Bool)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (answer : Option PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      (if eager then
         psKernelReduceNatWith whnf context state expr
       else
         Except.ok (Prod.mk Option.none state)) =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelOptionalReductionPostcondition
      context nextState expr answer := by
  cases eager with
  | false =>
      simp at hRun
      rcases hRun with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | true =>
      exact
        psKernelReduceNatWith_configuration_sound
          whnf hWhnf
          context state nextState expr answer
          hConfig
          (by simpa using hRun)


/-
The eager Nat stage of lazy equality composes exactly one reduction or,
if there is no Nat reduction, delegates to the already verified native and
delta-step continuation. A successful DefEq of Nat-reduced operands is lifted
by reduceCompare rather than general algorithmic transitivity.
-/
theorem psKernelDefEqLazyReductionAfterPred_configuration_sound
    (resume :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod PsKernelDeltaResult PsKernelCheckerState))
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
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hResume : PsKernelDeltaResultConfigurationSound resume)
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (hStep :
      PsKernelDeltaStepConfigurationSound
        (psKernelDefEqLazyStep defeq coreWhnf))
    (hNative : PsKernelNativeReductionSoundLaw) :
    PsKernelDeltaResultConfigurationSound
      (psKernelDefEqLazyReductionAfterPred
        resume defeq whnf coreWhnf) := by
  intro context state nextState left right answer hConfig hRun
  by_cases hEager :
      context.eagerReduce = true ∨
        (psKernelExprHasFVar left = false ∧
          psKernelExprHasFVar right = false)
  case neg =>
      have hNativeRun :
          psKernelDefEqNativeThenLazyStep
              resume defeq coreWhnf context state left right =
            Except.ok (Prod.mk answer nextState) := by
        simpa [psKernelDefEqLazyReductionAfterPred, hEager] using hRun
      exact
        psKernelDefEqNativeThenLazyStep_configuration_sound_of_components
          resume defeq coreWhnf
          hResume hDefEq hStep hNative
          context state nextState left right answer
          hConfig hNativeRun
  case pos =>
      cases hLeftNat :
          psKernelReduceNatWith whnf context state left with
      | error error =>
          simp [
            psKernelDefEqLazyReductionAfterPred,
            hEager, hLeftNat
          ] at hRun
      | ok leftRun =>
          rcases leftRun with ⟨leftAnswer, leftState⟩
          have hLeftSound :=
            psKernelReduceNatWith_configuration_sound
              whnf hWhnf
              context state leftState left leftAnswer
              hConfig hLeftNat
          cases leftAnswer with
          | some leftValue =>
              cases hEq :
                  defeq context leftState leftValue right with
              | error error =>
                  simp [
                    psKernelDefEqLazyReductionAfterPred,
                    hEager, hLeftNat, hEq
                  ] at hRun
              | ok eqRun =>
                  rcases eqRun with ⟨eqValue, eqState⟩
                  have hEqSound :=
                    hDefEq
                      context leftState eqState
                      leftValue right eqValue
                      hLeftSound.1 hEq
                  simp [
                    psKernelDefEqLazyReductionAfterPred,
                    hEager, hLeftNat, hEq
                  ] at hRun
                  rcases hRun with ⟨rfl, rfl⟩
                  refine ⟨hEqSound.1, ?_⟩
                  cases eqValue with
                  | false =>
                      trivial
                  | true =>
                      exact
                        PsKernelDefEqJudgment.reduceCompare
                          left right leftValue right
                          hLeftSound.2
                          (PsKernelReductionClosure.refl right)
                          (hEqSound.2 rfl)
          | none =>
              cases hRightNat :
                  psKernelReduceNatWith whnf context leftState right with
              | error error =>
                  simp [
                    psKernelDefEqLazyReductionAfterPred,
                    hEager, hLeftNat, hRightNat
                  ] at hRun
              | ok rightRun =>
                  rcases rightRun with ⟨rightAnswer, rightState⟩
                  have hRightSound :=
                    psKernelReduceNatWith_configuration_sound
                      whnf hWhnf
                      context leftState rightState right rightAnswer
                      hLeftSound.1 hRightNat
                  cases rightAnswer with
                  | some rightValue =>
                      cases hEq :
                          defeq context rightState left rightValue with
                      | error error =>
                          simp [
                            psKernelDefEqLazyReductionAfterPred,
                            hEager, hLeftNat, hRightNat, hEq
                          ] at hRun
                      | ok eqRun =>
                          rcases eqRun with ⟨eqValue, eqState⟩
                          have hEqSound :=
                            hDefEq
                              context rightState eqState
                              left rightValue eqValue
                              hRightSound.1 hEq
                          simp [
                            psKernelDefEqLazyReductionAfterPred,
                            hEager, hLeftNat, hRightNat, hEq
                          ] at hRun
                          rcases hRun with ⟨rfl, rfl⟩
                          refine ⟨hEqSound.1, ?_⟩
                          cases eqValue with
                          | false =>
                              trivial
                          | true =>
                              exact
                                PsKernelDefEqJudgment.reduceCompare
                                  left right left rightValue
                                  (PsKernelReductionClosure.refl left)
                                  hRightSound.2
                                  (hEqSound.2 rfl)
                  | none =>
                      have hNativeRun :
                          psKernelDefEqNativeThenLazyStep
                              resume defeq coreWhnf
                              context rightState left right =
                            Except.ok (Prod.mk answer nextState) := by
                        simpa [
                          psKernelDefEqLazyReductionAfterPred,
                          hEager, hLeftNat, hRightNat
                        ] using hRun
                      exact
                        psKernelDefEqNativeThenLazyStep_configuration_sound_of_components
                          resume defeq coreWhnf
                          hResume hDefEq hStep hNative
                          context rightState nextState
                          left right answer
                          hRightSound.1 hNativeRun



/-
A successful Nat-predecessor recognizer must originate from one of the two
independently specified successor representations.  In particular a malformed
multi-argument Nat.succ head is not accepted as a successor representation.
-/
theorem psKernelExprList_singleton_of_length_one
    (args : List PsKernelExpr)
    (value : PsKernelExpr)
    (hLength :
      Nat.beq (psKernelExprListLength args) 1 = true)
    (hGet :
      psKernelExprListGet args 0 = Option.some value) :
    args = List.cons value List.nil := by
  cases args with
  | nil =>
      simp [psKernelExprListLength] at hLength
  | cons first rest =>
      cases rest with
      | nil =>
          have hValue : first = value := by
            simpa [psKernelExprListGet] using hGet
          subst first
          rfl
      | cons second tail =>
          simp [psKernelExprListLength] at hLength


theorem psKernelExprNatPred_some_refines
    (expr predecessor : PsKernelExpr)
    (hSuccess :
      psKernelExprNatPred expr = Option.some predecessor) :
    PsKernelNatSuccessorRep expr predecessor := by
  cases expr with
  | lit literal =>
      cases literal with
      | nat value =>
          cases value with
          | zero =>
              simp [psKernelExprNatPred] at hSuccess
          | succ previous =>
              have hPred :
                  PsKernelExpr.lit (PsKernelLiteral.nat previous) =
                    predecessor := by
                simpa [psKernelExprNatPred] using hSuccess
              subst predecessor
              exact PsKernelNatSuccessorRep.literal previous
      | str value =>
          simp [psKernelExprNatPred] at hSuccess
  | app fn arg =>
      cases hHead :
          psKernelExprGetAppFn (PsKernelExpr.app fn arg) with
      | const name levels =>
          cases levels with
          | nil =>
              cases hName :
                  psKernelNameEq name psKernelNatSuccName with
              | false =>
                  simp [
                    psKernelExprNatPred, hHead, hName
                  ] at hSuccess
              | true =>
                  cases hArity :
                      Nat.beq
                        (psKernelExprGetAppNumArgs
                          (PsKernelExpr.app fn arg))
                        1 with
                  | false =>
                      simp [
                        psKernelExprNatPred, hHead, hName, hArity
                      ] at hSuccess
                  | true =>
                      have hArg :
                          psKernelExprListGet
                              (psKernelExprGetAppArgs
                                (PsKernelExpr.app fn arg))
                              0 =
                            Option.some predecessor := by
                        simpa [
                          psKernelExprNatPred, hHead, hName, hArity
                        ] using hSuccess
                      have hArgs :=
                        psKernelExprList_singleton_of_length_one
                          (psKernelExprGetAppArgs
                            (PsKernelExpr.app fn arg))
                          predecessor
                          hArity
                          hArg
                      exact
                        PsKernelNatSuccessorRep.constructor
                          (PsKernelExpr.app fn arg)
                          predecessor name hHead hName hArgs
          | cons level tail =>
              simp [psKernelExprNatPred, hHead] at hSuccess
      | bvar index =>
          simp [psKernelExprNatPred, hHead] at hSuccess
      | fvar name =>
          simp [psKernelExprNatPred, hHead] at hSuccess
      | mvar name =>
          simp [psKernelExprNatPred, hHead] at hSuccess
      | sort level =>
          simp [psKernelExprNatPred, hHead] at hSuccess
      | app head argument =>
          simp [psKernelExprNatPred, hHead] at hSuccess
      | lam name type body info =>
          simp [psKernelExprNatPred, hHead] at hSuccess
      | forallE name type body info =>
          simp [psKernelExprNatPred, hHead] at hSuccess
      | letE name type value body nondep =>
          simp [psKernelExprNatPred, hHead] at hSuccess
      | lit literal =>
          simp [psKernelExprNatPred, hHead] at hSuccess
      | mdata metadata body =>
          simp [psKernelExprNatPred, hHead] at hSuccess
      | proj typeName index body =>
          simp [psKernelExprNatPred, hHead] at hSuccess
  | bvar index =>
      simp [psKernelExprNatPred, psKernelExprGetAppFn] at hSuccess
  | fvar name =>
      simp [psKernelExprNatPred, psKernelExprGetAppFn] at hSuccess
  | mvar name =>
      simp [psKernelExprNatPred, psKernelExprGetAppFn] at hSuccess
  | sort level =>
      simp [psKernelExprNatPred, psKernelExprGetAppFn] at hSuccess
  | const name levels =>
      cases levels with
      | nil =>
          simp [
            psKernelExprNatPred, psKernelExprGetAppFn,
            psKernelExprGetAppNumArgs, psKernelExprGetAppArgs,
            psKernelExprGetAppArgsWorker, psKernelExprListLength
          ] at hSuccess
      | cons level tail =>
          simp [psKernelExprNatPred, psKernelExprGetAppFn] at hSuccess
  | lam name type body info =>
      simp [psKernelExprNatPred, psKernelExprGetAppFn] at hSuccess
  | forallE name type body info =>
      simp [psKernelExprNatPred, psKernelExprGetAppFn] at hSuccess
  | letE name type value body nondep =>
      simp [psKernelExprNatPred, psKernelExprGetAppFn] at hSuccess
  | mdata metadata body =>
      simp [psKernelExprNatPred, psKernelExprGetAppFn] at hSuccess
  | proj typeName index body =>
      simp [psKernelExprNatPred, psKernelExprGetAppFn] at hSuccess


/-
The fast zero shortcut does not equate arbitrary syntactic expressions.
Its supported representations are exactly Nat literal zero or an uninstantiated
Nat.zero constructor. Each reduces to the same literal by a separately
enumerated semantic reduction rule.
-/
theorem psKernelExprIsNatZero_reduces_to_literal
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (expr : PsKernelExpr)
    (hZero : psKernelExprIsNatZero expr = true) :
    PsKernelReductionClosure
      environment localContext
      expr
      (PsKernelExpr.lit (PsKernelLiteral.nat 0)) := by
  cases expr with
  | lit literal =>
      cases literal with
      | nat value =>
          cases value with
          | zero =>
              exact
                PsKernelReductionClosure.refl
                  (PsKernelExpr.lit (PsKernelLiteral.nat 0))
          | succ predecessor =>
              simp [psKernelExprIsNatZero] at hZero
      | str value =>
          simp [psKernelExprIsNatZero] at hZero
  | const name levels =>
      cases levels with
      | nil =>
          have hName :
              psKernelNameEq name psKernelNatZeroName = true := by
            simpa [psKernelExprIsNatZero] using hZero
          exact
            PsKernelReductionClosure.cons
              (PsKernelExpr.const name List.nil)
              (PsKernelExpr.lit (PsKernelLiteral.nat 0))
              (PsKernelExpr.lit (PsKernelLiteral.nat 0))
              (PsKernelReductionStep.natZeroLiteral name hName)
              (PsKernelReductionClosure.refl
                (PsKernelExpr.lit (PsKernelLiteral.nat 0)))
      | cons level rest =>
          simp [psKernelExprIsNatZero] at hZero
  | bvar index =>
      simp [psKernelExprIsNatZero] at hZero
  | fvar name =>
      simp [psKernelExprIsNatZero] at hZero
  | mvar name =>
      simp [psKernelExprIsNatZero] at hZero
  | sort level =>
      simp [psKernelExprIsNatZero] at hZero
  | app fn arg =>
      simp [psKernelExprIsNatZero] at hZero
  | lam name type body binderInfo =>
      simp [psKernelExprIsNatZero] at hZero
  | forallE name type body binderInfo =>
      simp [psKernelExprIsNatZero] at hZero
  | letE name type value body nondep =>
      simp [psKernelExprIsNatZero] at hZero
  | mdata metadata body =>
      simp [psKernelExprIsNatZero] at hZero
  | proj typeName index body =>
      simp [psKernelExprIsNatZero] at hZero


theorem psKernelNatZeroPair_defeq
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (left right : PsKernelExpr)
    (hLeft : psKernelExprIsNatZero left = true)
    (hRight : psKernelExprIsNatZero right = true) :
    PsKernelDefEqJudgment
      environment localContext left right := by
  exact
    PsKernelDefEqJudgment.reduceCompare
      left right
      (PsKernelExpr.lit (PsKernelLiteral.nat 0))
      (PsKernelExpr.lit (PsKernelLiteral.nat 0))
      (psKernelExprIsNatZero_reduces_to_literal
        environment localContext left hLeft)
      (psKernelExprIsNatZero_reduces_to_literal
        environment localContext right hRight)
      (PsKernelDefEqJudgment.literal
        (PsKernelLiteral.nat 0)
        (PsKernelLiteral.nat 0)
        rfl)

/-
The fast Nat.succ comparison is justified by the independent successor
representation on both operands and recursive DefEq on their predecessors.
-/
theorem psKernelNatPredPair_defeq
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (left right leftPred rightPred : PsKernelExpr)
    (hLeft :
      psKernelExprNatPred left = Option.some leftPred)
    (hRight :
      psKernelExprNatPred right = Option.some rightPred)
    (hPred :
      PsKernelDefEqJudgment
        environment localContext leftPred rightPred) :
    PsKernelDefEqJudgment
      environment localContext left right := by
  exact
    PsKernelDefEqJudgment.natSuccessorPred
      left right leftPred rightPred
      (psKernelExprNatPred_some_refines
        left leftPred hLeft)
      (psKernelExprNatPred_some_refines
        right rightPred hRight)
      hPred


/-
Complete fuel induction for lazy-delta equality.

The induction uses the established abstract callback contracts for recursive
DefEq, WHNF/core WHNF, Nat reduction and native reduction. Its success cases
are justified by an independent Nat-zero rule, successor congruence, or the
already-proved eager-Nat/native/lazy-step continuation. It introduces no
algorithmic DefEq transitivity or new trusted reduction assumptions.
-/
theorem psKernelDefEqLazyReductionWithFuel_configuration_sound
    (fuel : Nat)
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
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (hCore : PsKernelWhnfCoreConfigurationSound coreWhnf)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw) :
    PsKernelDeltaResultConfigurationSound
      (psKernelDefEqLazyReductionWithFuel
        fuel defeq whnf coreWhnf) := by
  have hQuick :
      PsKernelOptionalDefEqConfigurationSound
        (psKernelDefEqQuick defeq) :=
    psKernelDefEqQuick_configuration_sound
      defeq hDefEq hString
  have hStep :
      PsKernelDeltaStepConfigurationSound
        (psKernelDefEqLazyStep defeq coreWhnf) :=
    psKernelDefEqLazyStep_configuration_sound
      defeq coreWhnf hDefEq hQuick hCore hString
  induction fuel with
  | zero =>
      intro context state nextState left right answer hConfig hRun
      simp [psKernelDefEqLazyReductionWithFuel] at hRun
  | succ remaining ih =>
      intro context state nextState left right answer hConfig hRun
      let resume :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelDeltaResult PsKernelCheckerState) :=
        psKernelDefEqLazyReductionWithFuel
          remaining defeq whnf coreWhnf
      have hResume :
          PsKernelDeltaResultConfigurationSound resume := by
        simpa [resume] using ih
      have hAfter :
          PsKernelDeltaResultConfigurationSound
            (psKernelDefEqLazyReductionAfterPred
              resume defeq whnf coreWhnf) :=
        psKernelDefEqLazyReductionAfterPred_configuration_sound
          resume defeq whnf coreWhnf
          hResume hDefEq hWhnf hStep hNative
      by_cases hZeroPair :
          psKernelExprIsNatZero left = true ∧
            psKernelExprIsNatZero right = true
      · simp [
          psKernelDefEqLazyReductionWithFuel,
          hZeroPair.1, hZeroPair.2
        ] at hRun
        rcases hRun with ⟨rfl, rfl⟩
        exact
          ⟨
            hConfig,
            psKernelNatZeroPair_defeq
              context.environment context.localContext
              left right hZeroPair.1 hZeroPair.2
          ⟩
      · have hFastRun :
            (match psKernelExprNatPred left with
             | Option.some leftPred =>
                 match psKernelExprNatPred right with
                 | Option.some rightPred =>
                     match defeq context state leftPred rightPred with
                     | Except.error error =>
                         Except.error error
                     | Except.ok result =>
                         Except.ok
                           (Prod.mk
                             (PsKernelDeltaResult.decided
                               (Prod.fst result))
                             (Prod.snd result))
                 | Option.none =>
                     psKernelDefEqLazyReductionAfterPred
                       resume defeq whnf coreWhnf
                       context state left right
             | Option.none =>
                 psKernelDefEqLazyReductionAfterPred
                   resume defeq whnf coreWhnf
                   context state left right) =
              Except.ok (Prod.mk answer nextState) := by
          simp [
            psKernelDefEqLazyReductionWithFuel,
            hZeroPair
          ] at hRun
          change
            (match psKernelExprNatPred left with
             | Option.some leftPred =>
                 match psKernelExprNatPred right with
                 | Option.some rightPred =>
                     match defeq context state leftPred rightPred with
                     | Except.error error => Except.error error
                     | Except.ok result =>
                         Except.ok
                           (Prod.mk
                             (PsKernelDeltaResult.decided
                               (Prod.fst result))
                             (Prod.snd result))
                 | Option.none =>
                     psKernelDefEqLazyReductionAfterPred
                       resume defeq whnf coreWhnf context state left right
             | Option.none =>
                 psKernelDefEqLazyReductionAfterPred
                   resume defeq whnf coreWhnf context state left right) =
              Except.ok (Prod.mk answer nextState) at hRun
          exact hRun
        cases hLeftPred : psKernelExprNatPred left with
        | none =>
            have hAfterRun :
                psKernelDefEqLazyReductionAfterPred
                    resume defeq whnf coreWhnf
                    context state left right =
                  Except.ok (Prod.mk answer nextState) := by
              simpa [hLeftPred] using hFastRun
            exact
              hAfter
                context state nextState left right answer
                hConfig hAfterRun
        | some leftPred =>
            cases hRightPred : psKernelExprNatPred right with
            | none =>
                have hAfterRun :
                    psKernelDefEqLazyReductionAfterPred
                        resume defeq whnf coreWhnf
                        context state left right =
                      Except.ok (Prod.mk answer nextState) := by
                  simpa [hLeftPred, hRightPred] using hFastRun
                exact
                  hAfter
                    context state nextState left right answer
                    hConfig hAfterRun
            | some rightPred =>
                cases hEq :
                    defeq context state leftPred rightPred with
                | error error =>
                    simp [
                      hLeftPred, hRightPred, hEq
                    ] at hFastRun
                | ok eqRun =>
                    rcases eqRun with ⟨eqValue, eqState⟩
                    have hEqSound :=
                      hDefEq
                        context state eqState
                        leftPred rightPred eqValue
                        hConfig hEq
                    simp [
                      hLeftPred, hRightPred, hEq
                    ] at hFastRun
                    rcases hFastRun with ⟨rfl, rfl⟩
                    refine ⟨hEqSound.1, ?_⟩
                    cases eqValue with
                    | false =>
                        trivial
                    | true =>
                        exact
                          psKernelNatPredPair_defeq
                            context.environment context.localContext
                            left right leftPred rightPred
                            hLeftPred hRightPred
                            (hEqSound.2 rfl)
