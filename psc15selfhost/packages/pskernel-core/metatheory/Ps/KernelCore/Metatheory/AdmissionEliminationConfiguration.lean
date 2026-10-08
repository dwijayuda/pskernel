import Ps.KernelCore.Metatheory.AdmissionHeaderSpineConfiguration
import Ps.KernelCore.Metatheory.ExprEq
import Ps.KernelCore.Admission.Inductive.Common.Elimination

/-- Independent structural membership used by singleton large elimination. -/
def PsKernelStructuralExprMember (expr : PsKernelExpr) (values : List PsKernelExpr) : Prop :=
  ∃ actual : PsKernelExpr, List.Mem actual values ∧ PsKernelStructuralExprEq expr actual

theorem psKernelSimpleExprMember_true_refines
    (needle : PsKernelExpr) (values : List PsKernelExpr)
    (hRun : psKernelSimpleExprMember needle values = true) :
    PsKernelStructuralExprMember needle values := by
  induction values with
  | nil => simp [psKernelSimpleExprMember] at hRun
  | cons item rest ih =>
      cases hEqual : psKernelExprEq needle item with
      | true =>
          exact ⟨item, List.Mem.head rest,
            psKernelExprEq_true_refines_structural needle item hEqual⟩
      | false =>
          have hTail : psKernelSimpleExprMember needle rest = true := by
            simpa [psKernelSimpleExprMember, hEqual] using hRun
          obtain ⟨actual, hMember, hStructural⟩ := ih hTail
          exact ⟨actual, List.Mem.tail item hMember, hStructural⟩

theorem psKernelSimpleAllExprsMember_true_refines
    (values haystack : List PsKernelExpr)
    (hRun : psKernelSimpleAllExprsMember values haystack = true) :
    ∀ expr : PsKernelExpr, List.Mem expr values ->
      PsKernelStructuralExprMember expr haystack := by
  induction values with
  | nil =>
      intro expr hMember
      cases hMember
  | cons item rest ih =>
      cases hItem : psKernelSimpleExprMember item haystack with
      | false => simp [psKernelSimpleAllExprsMember, hItem] at hRun
      | true =>
          have hTail : psKernelSimpleAllExprsMember rest haystack = true := by
            simpa [psKernelSimpleAllExprsMember, hItem] using hRun
          intro expr hMember
          cases hMember with
          | head => exact psKernelSimpleExprMember_true_refines item haystack hItem
          | tail => exact ih hTail expr (by assumption)


/-- Independent natural-number semantics for universe expressions. -/
def psKernelAdmissionLevelValue
    (parameterValue metavariableValue : PsKernelName -> Nat) :
    PsKernelLevel -> Nat
  | .zero => 0
  | .succ level => Nat.succ (psKernelAdmissionLevelValue parameterValue metavariableValue level)
  | .max left right => Nat.max
      (psKernelAdmissionLevelValue parameterValue metavariableValue left)
      (psKernelAdmissionLevelValue parameterValue metavariableValue right)
  | .imax left right =>
      let rightValue := psKernelAdmissionLevelValue parameterValue metavariableValue right;
      if rightValue = 0 then 0
      else Nat.max (psKernelAdmissionLevelValue parameterValue metavariableValue left) rightValue
  | .param name => parameterValue name
  | .mvar name => metavariableValue name

def PsKernelAdmissionLevelAlwaysZero (level : PsKernelLevel) : Prop :=
  ∀ parameterValue metavariableValue : PsKernelName -> Nat,
    psKernelAdmissionLevelValue parameterValue metavariableValue level = 0

theorem psKernelLevelNormalizesToZero_true_semantic
    (level : PsKernelLevel)
    (hZero : psKernelLevelNormalizesToZero level = true) :
    PsKernelAdmissionLevelAlwaysZero level := by
  induction level with
  | zero => intro parameterValue metavariableValue; rfl
  | succ level ih => simp [psKernelLevelNormalizesToZero] at hZero
  | max left right ihLeft ihRight =>
      cases hLeft : psKernelLevelNormalizesToZero left with
      | false => simp [psKernelLevelNormalizesToZero, hLeft] at hZero
      | true =>
          have hRight : psKernelLevelNormalizesToZero right = true := by
            simpa [psKernelLevelNormalizesToZero, hLeft] using hZero
          intro parameterValue metavariableValue
          simp [psKernelAdmissionLevelValue, ihLeft hLeft parameterValue metavariableValue, ihRight hRight parameterValue metavariableValue]
  | imax left right ihLeft ihRight =>
      have hRight : psKernelLevelNormalizesToZero right = true := hZero
      intro parameterValue metavariableValue
      simp [psKernelAdmissionLevelValue, ihRight hRight parameterValue metavariableValue]
  | param name => simp [psKernelLevelNormalizesToZero] at hZero
  | mvar name => simp [psKernelLevelNormalizesToZero] at hZero

theorem psKernelLevelNormalizesToZero_false_positive_at_one
    (level : PsKernelLevel)
    (hNonZero : psKernelLevelNormalizesToZero level = false) :
    0 < psKernelAdmissionLevelValue (fun _ => 1) (fun _ => 1) level := by
  induction level with
  | zero => simp [psKernelLevelNormalizesToZero] at hNonZero
  | succ level ih => simp [psKernelAdmissionLevelValue]
  | max left right ihLeft ihRight =>
      cases hLeft : psKernelLevelNormalizesToZero left with
      | false =>
          have hPositive := ihLeft hLeft
          exact Nat.lt_of_lt_of_le hPositive (Nat.le_max_left _ _)
      | true =>
          have hRight : psKernelLevelNormalizesToZero right = false := by
            simpa [psKernelLevelNormalizesToZero, hLeft] using hNonZero
          have hPositive := ihRight hRight
          exact Nat.lt_of_lt_of_le hPositive (Nat.le_max_right _ _)
  | imax left right ihLeft ihRight =>
      have hRight : psKernelLevelNormalizesToZero right = false := hNonZero
      have hPositive := ihRight hRight
      simp only [psKernelAdmissionLevelValue]
      have hNotZero : psKernelAdmissionLevelValue (fun _ => 1) (fun _ => 1) right ≠ 0 := by omega
      simp only [hNotZero, ↓reduceIte]
      exact Nat.lt_of_lt_of_le hPositive (Nat.le_max_right _ _)
  | param name => simp [psKernelAdmissionLevelValue]
  | mvar name => simp [psKernelAdmissionLevelValue]

theorem psKernelLevelNormalizesToZero_false_semantic
    (level : PsKernelLevel)
    (hNonZero : psKernelLevelNormalizesToZero level = false) :
    ¬ PsKernelAdmissionLevelAlwaysZero level := by
  intro hAlwaysZero
  have hZero := hAlwaysZero (fun _ => 1) (fun _ => 1)
  have hPositive := psKernelLevelNormalizesToZero_false_positive_at_one level hNonZero
  omega

theorem psKernelLevelIsNotZero_true_semantic
    (level : PsKernelLevel)
    (hNonZero : psKernelLevelIsNotZero level = true) :
    ∀ parameterValue metavariableValue : PsKernelName -> Nat,
      0 < psKernelAdmissionLevelValue parameterValue metavariableValue level := by
  induction level with
  | zero => simp [psKernelLevelIsNotZero] at hNonZero
  | succ level ih =>
      intro parameterValue metavariableValue
      simp [psKernelAdmissionLevelValue]
  | max left right ihLeft ihRight =>
      cases hLeft : psKernelLevelIsNotZero left with
      | true =>
          intro parameterValue metavariableValue
          have hPositive := ihLeft hLeft parameterValue metavariableValue
          exact Nat.lt_of_lt_of_le hPositive (Nat.le_max_left _ _)
      | false =>
          have hRight : psKernelLevelIsNotZero right = true := by
            simpa [psKernelLevelIsNotZero, hLeft] using hNonZero
          intro parameterValue metavariableValue
          have hPositive := ihRight hRight parameterValue metavariableValue
          exact Nat.lt_of_lt_of_le hPositive (Nat.le_max_right _ _)
  | imax left right ihLeft ihRight =>
      have hRight : psKernelLevelIsNotZero right = true := hNonZero
      intro parameterValue metavariableValue
      have hPositive := ihRight hRight parameterValue metavariableValue
      have hNotZero : psKernelAdmissionLevelValue parameterValue metavariableValue right ≠ 0 := by omega
      simp only [psKernelAdmissionLevelValue, hNotZero, ↓reduceIte]
      exact Nat.lt_of_lt_of_le hPositive (Nat.le_max_right _ _)
  | param name => simp [psKernelLevelIsNotZero] at hNonZero
  | mvar name => simp [psKernelLevelIsNotZero] at hNonZero


/--
Independent singleton-constructor large-elimination evidence. Every opened
domain is checked; fields whose universes are not uniformly zero are retained
and must occur structurally among the constructor result arguments.
-/
inductive PsKernelLargeEliminationConstructorAllowed
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext -> PsKernelExpr -> List PsKernelExpr -> Prop where
  | terminal (localContext : PsKernelLocalContext)
      (type residual : PsKernelExpr) (nonProp : List PsKernelExpr)
      (hReduction : PsKernelReductionClosure environment localContext type residual)
      (hTerminal : PsKernelRawConstructorPiHead residual = false)
      (hMembers : ∀ expr : PsKernelExpr, List.Mem expr nonProp ->
        PsKernelStructuralExprMember expr (psKernelExprGetAppArgs residual)) :
      PsKernelLargeEliminationConstructorAllowed environment localContext type nonProp
  | binder (localContext : PsKernelLocalContext)
      (type domain body : PsKernelExpr) (userName fresh : PsKernelName)
      (binderInfo : PsKernelBinderInfo) (level : PsKernelLevel)
      (nonProp nextNonProp : List PsKernelExpr)
      (hReduction : PsKernelReductionClosure environment localContext type
        (PsKernelExpr.forallE userName domain body binderInfo))
      (hTyping : PsKernelTypingJudgment environment localContext domain (PsKernelExpr.sort level))
      (hFresh : psKernelLocalContextFind localContext fresh = none)
      (hClassification :
        (PsKernelAdmissionLevelAlwaysZero level ∧ nextNonProp = nonProp) ∨
        (¬ PsKernelAdmissionLevelAlwaysZero level ∧ nextNonProp = PsKernelExpr.fvar fresh :: nonProp))
      (hTail : PsKernelLargeEliminationConstructorAllowed environment
        (psKernelLocalContextAddLocal localContext fresh userName
          (psKernelExprConsumeTypeAnnotations domain) binderInfo)
        (psKernelExprInstantiate1 body (PsKernelExpr.fvar fresh)) nextNonProp) :
      PsKernelLargeEliminationConstructorAllowed environment localContext type nonProp

theorem psKernelSimpleCtorAllowsLargeElimWithFuel_true_semantic
    (fuel : Nat) (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw) :
    ∀ (session : PsKernelCheckerSession) (type : PsKernelExpr)
      (nonProp : List PsKernelExpr),
      PsKernelCheckerConfigurationSound session.context session.state ->
      psKernelSimpleCtorAllowsLargeElimWithFuel fuel session type nonProp = Except.ok true ->
      PsKernelLargeEliminationConstructorAllowed session.context.environment
        session.context.localContext type nonProp := by
  induction fuel with
  | zero =>
      intro session type nonProp hConfig hRun
      simp [psKernelSimpleCtorAllowsLargeElimWithFuel] at hRun
  | succ remaining ih =>
      intro session type nonProp hConfig hRun
      cases hWhnf : psKernelSessionWhnf remaining session type with
      | error message => simp [psKernelSimpleCtorAllowsLargeElimWithFuel, hWhnf] at hRun
      | ok reduced =>
          have hReducedSound := psKernelSessionWhnf_concrete_refines_reduction
            remaining hNative hString session reduced.2 type reduced.1 hConfig hWhnf
          have hReducedContext := psKernelSessionWhnf_success_preserves_context_core
            remaining session reduced.2 type reduced.1 hWhnf
          have hReducedConfig : PsKernelCheckerConfigurationSound reduced.2.context reduced.2.state := by
            simpa [hReducedContext] using hReducedSound.2
          cases hShape : reduced.1 with
          | forallE userName domain body binderInfo =>
              cases hCheck : psKernelSessionCheck remaining reduced.2 domain with
              | error message =>
                  simp [psKernelSimpleCtorAllowsLargeElimWithFuel, hWhnf, hShape, hCheck] at hRun
              | ok checked =>
                  cases hSort : psKernelSessionEnsureSort remaining checked.2 checked.1 with
                  | error message =>
                      simp [psKernelSimpleCtorAllowsLargeElimWithFuel, hWhnf, hShape, hCheck, hSort] at hRun
                  | ok sorted =>
                      have hCheckedSound := psKernelSessionCheck_concrete_refines_typing
                        remaining hNative hString reduced.2 checked.2 domain checked.1 hReducedConfig hCheck
                      have hCheckedContext := psKernelSessionCheck_success_preserves_context_core
                        remaining reduced.2 checked.2 domain checked.1 hCheck
                      have hCheckedConfig : PsKernelCheckerConfigurationSound checked.2.context checked.2.state := by
                        simpa [hCheckedContext] using hCheckedSound.2
                      have hSortedSound := psKernelSessionEnsureSort_concrete_refines_reduction
                        remaining hNative hString checked.2 sorted.2 checked.1 sorted.1 hCheckedConfig hSort
                      have hSortedContext := psKernelSessionEnsureSort_success_preserves_context_core
                        remaining checked.2 sorted.2 checked.1 sorted.1 hSort
                      have hSortedConfig : PsKernelCheckerConfigurationSound sorted.2.context sorted.2.state := by
                        simpa [hSortedContext] using hSortedSound.2
                      let opened := psKernelSessionWithLocal sorted.2 userName
                        (psKernelExprConsumeTypeAnnotations domain) binderInfo
                      let nextNonProp := if psKernelLevelNormalizesToZero sorted.1 then nonProp
                        else PsKernelExpr.fvar opened.1 :: nonProp
                      have hOpenedConfig := psKernelSessionWithLocal_preserves_configuration
                        sorted.2 userName (psKernelExprConsumeTypeAnnotations domain)
                        binderInfo hString hSortedConfig
                      have hFresh := psKernelSessionWithLocal_fresh_absent
                        sorted.2 userName (psKernelExprConsumeTypeAnnotations domain)
                        binderInfo hString hSortedConfig
                      have hTailRun : psKernelSimpleCtorAllowsLargeElimWithFuel remaining opened.2
                          (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1)) nextNonProp =
                            Except.ok true := by
                        simpa [psKernelSimpleCtorAllowsLargeElimWithFuel, hWhnf, hShape,
                          hCheck, hSort, opened, nextNonProp] using hRun
                      have hTail := ih opened.2
                        (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                        nextNonProp hOpenedConfig hTailRun
                      have hDomain : PsKernelTypingJudgment session.context.environment
                          session.context.localContext domain (PsKernelExpr.sort sorted.1) := by
                        apply PsKernelTypingJudgment.convert domain checked.1 (PsKernelExpr.sort sorted.1)
                        · simpa [hReducedContext] using hCheckedSound.1
                        · apply PsKernelDefEqJudgment.reductionClosure
                          simpa [hCheckedContext, hReducedContext] using hSortedSound.1
                      refine PsKernelLargeEliminationConstructorAllowed.binder session.context.localContext
                        type domain body userName opened.1 binderInfo sorted.1 nonProp nextNonProp
                        (by simpa [hShape] using hReducedSound.1) hDomain ?_ ?_ ?_
                      · simpa [opened, hSortedContext, hCheckedContext, hReducedContext] using hFresh
                      · cases hZero : psKernelLevelNormalizesToZero sorted.1 with
                        | true =>
                            exact Or.inl ⟨psKernelLevelNormalizesToZero_true_semantic sorted.1 hZero,
                              by simp [nextNonProp, hZero]⟩
                        | false =>
                            exact Or.inr ⟨psKernelLevelNormalizesToZero_false_semantic sorted.1 hZero,
                              by simp [nextNonProp, hZero]⟩
                      · simpa [opened, psKernelSessionWithLocal, psKernelCheckerContextWithLocalContext,
                          hSortedContext, hCheckedContext, hReducedContext] using hTail
          | _ =>
              have hMembers : psKernelSimpleAllExprsMember nonProp
                  (psKernelExprGetAppArgs reduced.1) = true := by
                simpa [psKernelSimpleCtorAllowsLargeElimWithFuel, hWhnf, hShape] using hRun
              exact PsKernelLargeEliminationConstructorAllowed.terminal
                session.context.localContext type reduced.1 nonProp hReducedSound.1
                (by simp [PsKernelRawConstructorPiHead, hShape])
                (psKernelSimpleAllExprsMember_true_refines nonProp
                  (psKernelExprGetAppArgs reduced.1) hMembers)


def PsKernelSimpleLargeEliminationPolicyValid
    (environment : PsKernelEnvironment) (localContext : PsKernelLocalContext)
    (params : List PsKernelOpenBinder) (resultLevel : PsKernelLevel)
    (ctors : List PsKernelSimpleConstructorDecl) : Prop :=
  (∀ parameterValue metavariableValue : PsKernelName -> Nat,
    0 < psKernelAdmissionLevelValue parameterValue metavariableValue resultLevel) ∨
  ctors = [] ∨
  (∃ (ctor : PsKernelSimpleConstructorDecl) (afterParams : PsKernelExpr),
    ctors = [ctor] ∧
    PsKernelRawConstructorParamSpineValid environment localContext params ctor.type afterParams ∧
    PsKernelLargeEliminationConstructorAllowed environment localContext afterParams [])

theorem psKernelSimpleCtorAllowsLargeElim_true_semantic
    (fuel : Nat) (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session : PsKernelCheckerSession) (params : List PsKernelOpenBinder)
    (type : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound session.context session.state)
    (hRun : psKernelSimpleCtorAllowsLargeElim fuel session params type = Except.ok true) :
    ∃ afterParams : PsKernelExpr,
      PsKernelRawConstructorParamSpineValid session.context.environment
        session.context.localContext params type afterParams ∧
      PsKernelLargeEliminationConstructorAllowed session.context.environment
        session.context.localContext afterParams [] := by
  cases hParams : psKernelOpenSimpleConstructorParams fuel session params type with
  | error message => simp [psKernelSimpleCtorAllowsLargeElim, hParams] at hRun
  | ok afterParams =>
      have hParamSound := psKernelOpenSimpleConstructorParams_raw_spine_refines
        fuel session params type afterParams hConfig hNative hString hParams
      have hParamConfig : PsKernelCheckerConfigurationSound
          afterParams.session.context afterParams.session.state := by
        simpa [hParamSound.2.1] using hParamSound.2.2
      have hWorker : psKernelSimpleCtorAllowsLargeElimWithFuel (Nat.succ fuel)
          afterParams.session afterParams.result [] = Except.ok true := by
        simpa [psKernelSimpleCtorAllowsLargeElim, hParams] using hRun
      have hAllowed := psKernelSimpleCtorAllowsLargeElimWithFuel_true_semantic
        (Nat.succ fuel) hNative hString afterParams.session afterParams.result []
        hParamConfig hWorker
      exact ⟨afterParams.result, hParamSound.1, by simpa [hParamSound.2.1] using hAllowed⟩

theorem psKernelSimpleElimOnlyAtZero_false_semantic
    (fuel : Nat) (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (session : PsKernelCheckerSession) (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel) (ctors : List PsKernelSimpleConstructorDecl)
    (hConfig : PsKernelCheckerConfigurationSound session.context session.state)
    (hRun : psKernelSimpleElimOnlyAtZero fuel session params resultLevel ctors = Except.ok false) :
    PsKernelSimpleLargeEliminationPolicyValid session.context.environment session.context.localContext
      params resultLevel ctors := by
  cases hPositive : psKernelLevelIsNotZero resultLevel with
  | true =>
      exact Or.inl (psKernelLevelIsNotZero_true_semantic resultLevel hPositive)
  | false =>
      cases ctors with
      | nil => exact Or.inr (Or.inl rfl)
      | cons ctor rest =>
          cases rest with
          | cons second remaining =>
              simp [psKernelSimpleElimOnlyAtZero, hPositive] at hRun
          | nil =>
              cases hAllowed : psKernelSimpleCtorAllowsLargeElim fuel session params ctor.type with
              | error message =>
                  simp [psKernelSimpleElimOnlyAtZero, hPositive, hAllowed] at hRun
              | ok allowed =>
                  cases allowed with
                  | false =>
                      simp [psKernelSimpleElimOnlyAtZero, hPositive, hAllowed] at hRun
                  | true =>
                      obtain ⟨afterParams, hSpine, hFields⟩ :=
                        psKernelSimpleCtorAllowsLargeElim_true_semantic fuel hNative hString
                          session params ctor.type hConfig hAllowed
                      exact Or.inr (Or.inr ⟨ctor, afterParams, rfl, hSpine, hFields⟩)
