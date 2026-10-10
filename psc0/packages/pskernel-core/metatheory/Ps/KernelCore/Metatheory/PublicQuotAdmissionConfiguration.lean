import Ps.KernelCore.Metatheory.AdmissionQuotIndexConfiguration
import Ps.KernelCore.Metatheory.PublicKernelConfiguration

/-
Public KernelContract-v1 quotient admission, including provider decoration,
preflight and the public declaration-size gate.

The successful result is the exact internally checked quotient environment
with the provider evaluator cleared.  The theorem proves index soundness
without asserting that arbitrary low-level environments are well formed.
-/

theorem psKernelV1DispatchQuot_index_refines
    (session : PsKernelKernelSession)
    (result : PsKernelEnvironment)
    (hIndex : PsKernelEnvironmentIndexRefines session.environment)
    (hRun :
      psKernelV1DispatchDeclaration
          session PsKernelDeclarationRequest.quot =
        Except.ok result) :
    PsKernelEnvironmentIndexRefines result := by
  have hWithNative :
      PsKernelEnvironmentIndexRefines
        (psKernelKernelSessionEnvironment session) := by
    intro name
    simpa [
      psKernelKernelSessionEnvironment,
      psKernelEnvironmentWithNativeEvaluator
    ] using hIndex name
  cases hQuot :
      psKernelAddQuot
        (psKernelKernelSessionEnvironment session) with
  | error message =>
      simp [
        psKernelV1DispatchDeclaration,
        psKernelV1EnvironmentOutcome,
        hQuot
      ] at hRun
  | ok nextEnvironment =>
      simp [
        psKernelV1DispatchDeclaration,
        psKernelV1EnvironmentOutcome,
        hQuot
      ] at hRun
      subst result
      exact
        psKernelAddQuot_success_index_refines
          (psKernelKernelSessionEnvironment session)
          nextEnvironment hWithNative hQuot


theorem psKernelV1CheckedEnvironment_quot_index_refines
    (session : PsKernelKernelSession)
    (result : PsKernelEnvironment)
    (hIndex : PsKernelEnvironmentIndexRefines session.environment)
    (hRun :
      psKernelV1CheckedEnvironment
          session PsKernelDeclarationRequest.quot =
        Except.ok result) :
    PsKernelEnvironmentIndexRefines result := by
  cases hPreflight :
      psKernelKernelSessionPreflight session with
  | error error =>
      simp [psKernelV1CheckedEnvironment, hPreflight] at hRun
  | ok preflight =>
      cases preflight
      cases hDispatch :
          psKernelV1DispatchDeclaration
            session PsKernelDeclarationRequest.quot with
      | error error =>
          simp [
            psKernelV1CheckedEnvironment,
            hPreflight, hDispatch
          ] at hRun
      | ok nextEnvironment =>
          have hNextIndex :=
            psKernelV1DispatchQuot_index_refines
              session nextEnvironment hIndex hDispatch
          cases hResource :
              psKernelResourceAllowsSize
                session.resources
                (psKernelEnvironmentSize nextEnvironment) with
          | false =>
              simp [
                psKernelV1CheckedEnvironment,
                hPreflight, hDispatch, hResource
              ] at hRun
          | true =>
              simp [
                psKernelV1CheckedEnvironment,
                hPreflight, hDispatch, hResource
              ] at hRun
              subst result
              intro name
              simpa [
                psKernelEnvironmentWithNativeEvaluator
              ] using hNextIndex name


theorem psKernelV1AdmitQuot_index_refines
    (session : PsKernelKernelSession)
    (admitted : PsKernelAdmissionResult)
    (hIndex : PsKernelEnvironmentIndexRefines session.environment)
    (hRun :
      psKernelV1AdmitDeclaration
          session PsKernelDeclarationRequest.quot =
        Except.ok admitted) :
    PsKernelEnvironmentIndexRefines
      admitted.session.environment := by
  cases hChecked :
      psKernelV1CheckedEnvironment
        session PsKernelDeclarationRequest.quot with
  | error error =>
      simp [
        psKernelV1AdmitDeclaration,
        hChecked
      ] at hRun
  | ok nextEnvironment =>
      have hNextIndex :=
        psKernelV1CheckedEnvironment_quot_index_refines
          session nextEnvironment hIndex hChecked
      simp [
        psKernelV1AdmitDeclaration,
        hChecked
      ] at hRun
      subst admitted
      exact hNextIndex
