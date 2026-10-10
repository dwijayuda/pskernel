import Ps.KernelCore.Metatheory.CheckerInitialConfiguration
import Ps.KernelCore.Metatheory.AdmissionHeaderConfiguration
import Ps.KernelCore.Metatheory.AdmissionDefinitionConfiguration
import Ps.KernelCore.Metatheory.AdmissionRefinement
import Ps.KernelCore.Admission.Declaration.Admission

/-
Ordinary axiom admission refinement.

The successful executable operation first validates the declaration header
with the concrete checked kernel, including inference of a Sort for its type,
then uses the independently justified authoritative environment extension.

The environment index-refinement precondition is mandatory: checked-session
soundness is not assumed for arbitrary forged environment indexes. String and
native-reduction contracts stay explicit TCB boundaries.
-/

theorem psKernelAddAxiom_configuration_refines
    (fuel : Nat)
    (environment result : PsKernelEnvironment)
    (value : PsKernelAxiomInfo)
    (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun :
      psKernelAddAxiom
          fuel environment value maxRecDepth maxNatSize =
        Except.ok result) :
    (∃ (inferredType : PsKernelExpr) (level : PsKernelLevel),
      PsKernelTypingJudgment
          environment psKernelLocalContextEmpty
          value.base.type inferredType ∧
        PsKernelReductionClosure
          environment psKernelLocalContextEmpty
          inferredType (PsKernelExpr.sort level)) ∧
      PsKernelDeclarationExtension
        environment result (PsKernelConstantInfo.axiomInfo value) := by
  let safety :=
    if value.isUnsafe then
      PsKernelDefinitionSafety.unsafeDef
    else
      PsKernelDefinitionSafety.safe
  let session :=
    psKernelMkCheckerSession
      environment value.base.levelParams safety
      maxRecDepth maxNatSize
  have hInitial :
      PsKernelCheckerConfigurationSound
        session.context session.state :=
    psKernelMkCheckerSession_configuration_sound
      environment value.base.levelParams safety
      maxRecDepth maxNatSize hIndex
  cases hHeader :
      psKernelCheckConstantBaseWithSession
        fuel session value.base with
  | error error =>
      simp [psKernelAddAxiom, safety, session, hHeader] at hRun
  | ok checkedSession =>
      obtain ⟨inferredType, level, hTyped, hSort, _⟩ :=
        psKernelCheckConstantBaseWithSession_configuration_refines
          fuel hNative hString
          session checkedSession value.base
          hInitial hHeader
      have hAdd :
          psKernelEnvironmentAdd
              environment (PsKernelConstantInfo.axiomInfo value) =
            Except.ok result := by
        simpa [psKernelAddAxiom, safety, session, hHeader] using hRun
      constructor
      · refine ⟨inferredType, level, ?_, ?_⟩
        · simpa [
            session, psKernelMkCheckerSession,
            psKernelCheckerContextEmpty
          ] using hTyped
        · simpa [
            session, psKernelMkCheckerSession,
            psKernelCheckerContextEmpty
          ] using hSort
      · exact
          psKernelEnvironmentAdd_success_refines_extension
            environment result
            (PsKernelConstantInfo.axiomInfo value)
            hAdd
