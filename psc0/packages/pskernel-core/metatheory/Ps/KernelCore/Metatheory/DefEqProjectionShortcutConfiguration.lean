import Ps.KernelCore.Metatheory.DefEqLazyContinuation
import Ps.KernelCore.Metatheory.RecursorBoundedConfiguration
import Ps.KernelCore.Metatheory.DefEqQuickConfiguration

/-
Concrete projection shortcut refinement used by the DefEq checker knot.

The head equality checks are validated against the independent name and
universe semantics. Projection comparison uses the separately proved
projection-sensitive lazy-delta fuel induction at its precise expression-size
budget.  Only a successful equality decision becomes semantic DefEq evidence;
an undecided result still preserves checker configuration.

No unrestricted transitivity or additional trusted reduction laws are used.
-/

theorem psKernelDefEqProjectionShortcut_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hBeta : PsKernelBetaSpineSoundLaw)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw) :
    PsKernelOptionalDefEqConfigurationSound
      (psKernelDefEqProjectionShortcut defeq) := by
  intro context state nextState left right answer hConfig hRun
  cases left with
  | const leftName leftLevels =>
      cases right with
      | const rightName rightLevels =>
          by_cases hName :
              psKernelNameEq leftName rightName = true
          · by_cases hLevels :
                psKernelLevelListsEquivalent
                    leftLevels rightLevels = true
            · simp [
                psKernelDefEqProjectionShortcut,
                hName, hLevels
              ] at hRun
              rcases hRun with ⟨rfl, rfl⟩
              have hNames :
                  leftName = rightName :=
                psKernelNameEq_sound_of_string_law
                  hString leftName rightName hName
              subst rightName
              have hUniverse :=
                psKernelLevelListsEquivalent_normalized_sound
                  hString leftLevels rightLevels hLevels
              exact
                ⟨hConfig,
                  PsKernelDefEqJudgment.constLevels
                    leftName leftLevels rightLevels hUniverse⟩
            · simp [
                psKernelDefEqProjectionShortcut,
                hName, hLevels
              ] at hRun
              rcases hRun with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          · simp [
              psKernelDefEqProjectionShortcut,
              hName
            ] at hRun
            rcases hRun with ⟨rfl, rfl⟩
            exact ⟨hConfig, trivial⟩
      | _ =>
          simp [psKernelDefEqProjectionShortcut] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | fvar leftName =>
      cases right with
      | fvar rightName =>
          by_cases hName :
              psKernelNameEq leftName rightName = true
          · simp [
              psKernelDefEqProjectionShortcut,
              hName
            ] at hRun
            rcases hRun with ⟨rfl, rfl⟩
            exact
              ⟨hConfig,
                PsKernelDefEqJudgment.structural
                  (PsKernelExpr.fvar leftName)
                  (PsKernelExpr.fvar rightName)
                  (PsKernelStructuralExprEq.fvar
                    leftName rightName hName)⟩
          · simp [
              psKernelDefEqProjectionShortcut,
              hName
            ] at hRun
            rcases hRun with ⟨rfl, rfl⟩
            exact ⟨hConfig, trivial⟩
      | _ =>
          simp [psKernelDefEqProjectionShortcut] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | proj leftName leftIndex leftExpr =>
      cases right with
      | proj rightName rightIndex rightExpr =>
          by_cases hName :
              psKernelNameEq leftName rightName = true
          · by_cases hIndex :
                Nat.beq leftIndex rightIndex = true
            · let fuel :=
                Nat.succ
                  (Nat.add
                    (psKernelExprNodeCount leftExpr)
                    (psKernelExprNodeCount rightExpr))
              have hCore :
                  PsKernelWhnfCoreConfigurationSound
                    (psKernelWhnfCoreWithRecursorFuel
                      fuel defeq) :=
                psKernelWhnfCoreWithRecursorFuel_configuration_sound_of_defeq
                  fuel defeq hDefEq hBeta hNative
              have hQuick :
                  PsKernelOptionalDefEqConfigurationSound
                    (psKernelDefEqQuick defeq) :=
                psKernelDefEqQuick_configuration_sound
                  defeq hDefEq hString
              have hStep :
                  PsKernelDeltaStepConfigurationSound
                    (psKernelDefEqLazyStep
                      defeq
                      (psKernelWhnfCoreWithRecursorFuel
                        fuel defeq)) :=
                psKernelDefEqLazyStep_configuration_sound
                  defeq
                  (psKernelWhnfCoreWithRecursorFuel
                    fuel defeq)
                  hDefEq hQuick hCore hString
              cases hLazy :
                  psKernelDefEqLazyProjReductionWithFuel
                    (psKernelExprNodeCount leftExpr +
                      psKernelExprNodeCount rightExpr + 1)
                    defeq
                    (psKernelWhnfCoreWithRecursorFuel
                      (psKernelExprNodeCount leftExpr +
                        psKernelExprNodeCount rightExpr + 1) defeq)
                    context state
                    leftExpr rightExpr leftName leftIndex with
              | error error =>
                  simp [
                    psKernelDefEqProjectionShortcut,
                    hName, hIndex, hLazy
                  ] at hRun
              | ok lazyRun =>
                  rcases lazyRun with ⟨value, lazyState⟩
                  have hLazySound :=
                    psKernelDefEqLazyProjReductionWithFuel_configuration_sound
                      fuel
                      defeq
                      (psKernelWhnfCoreWithRecursorFuel
                        fuel defeq)
                      hDefEq hStep
                      context state lazyState
                      leftExpr rightExpr leftName leftIndex
                      value hConfig hLazy
                  cases value with
                  | false =>
                      simp [
                        psKernelDefEqProjectionShortcut,
                        hName, hIndex, hLazy
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      exact ⟨hLazySound.1, trivial⟩
                  | true =>
                      have hNames :
                          leftName = rightName :=
                        psKernelNameEq_sound_of_string_law
                          hString leftName rightName hName
                      have hIndices :
                          leftIndex = rightIndex := by
                        simpa using hIndex
                      simp [
                        psKernelDefEqProjectionShortcut,
                        hName, hIndex, hLazy
                      ] at hRun
                      rcases hRun with ⟨rfl, rfl⟩
                      subst rightName
                      subst rightIndex
                      exact ⟨hLazySound.1, hLazySound.2 rfl⟩
            · simp [
                psKernelDefEqProjectionShortcut,
                hName, hIndex
              ] at hRun
              rcases hRun with ⟨rfl, rfl⟩
              exact ⟨hConfig, trivial⟩
          · simp [
              psKernelDefEqProjectionShortcut, hName
            ] at hRun
            rcases hRun with ⟨rfl, rfl⟩
            exact ⟨hConfig, trivial⟩
      | _ =>
          simp [psKernelDefEqProjectionShortcut] at hRun
          rcases hRun with ⟨rfl, rfl⟩
          exact ⟨hConfig, trivial⟩
  | _ =>
      simp [psKernelDefEqProjectionShortcut] at hRun
      rcases hRun with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
