import Ps.Compiler.Api

/-!
PSCV compiler-package experiment: environment, erasure and VerifiedIR proofs.

These theorems establish the wrapper-level fail-closed behavior of the current
pipeline. They do not prove that erasure preserves source semantics or that the
VerifiedIR validator itself is complete/sound; those obligations belong to the
imported packages.
-/

theorem pscv_environment_from_prepared_validation_error
    (prepared : PsCompilerAdmissionReadyModule)
    (error : PsCompilerError)
    (hValidate :
      psCompilerValidatePrepared prepared = Except.error error) :
    psCompilerEnvironmentFromPrepared prepared =
      Except.error error := by
  simp [psCompilerEnvironmentFromPrepared, hValidate]

theorem pscv_environment_from_prepared_add_error
    (prepared : PsCompilerAdmissionReadyModule)
    (error : PsElabError)
    (hValidate :
      psCompilerValidatePrepared prepared = Except.ok Unit.unit)
    (hAdd :
      psAddDeclarationList
          psSelfHostProdPreludeEnvironment
          prepared.declarations =
        Except.error error) :
    psCompilerEnvironmentFromPrepared prepared =
      Except.error (.elaboration error) := by
  simp [psCompilerEnvironmentFromPrepared, hValidate, hAdd]

theorem pscv_environment_from_prepared_success
    (prepared : PsCompilerAdmissionReadyModule)
    (environment : PsEnvironment)
    (hValidate :
      psCompilerValidatePrepared prepared = Except.ok Unit.unit)
    (hAdd :
      psAddDeclarationList
          psSelfHostProdPreludeEnvironment
          prepared.declarations =
        Except.ok environment) :
    psCompilerEnvironmentFromPrepared prepared =
      Except.ok environment := by
  simp [psCompilerEnvironmentFromPrepared, hValidate, hAdd]

theorem pscv_erased_ir_environment_error
    (prepared : PsCompilerAdmissionReadyModule)
    (error : PsCompilerError)
    (hEnvironment :
      psCompilerEnvironmentFromPrepared prepared = Except.error error) :
    psCompilerErasedIrFromPrepared prepared =
      Except.error error := by
  simp [psCompilerErasedIrFromPrepared, hEnvironment]

theorem pscv_erased_ir_erasure_error
    (prepared : PsCompilerAdmissionReadyModule)
    (environment : PsEnvironment)
    (error : PsErasureError)
    (hEnvironment :
      psCompilerEnvironmentFromPrepared prepared = Except.ok environment)
    (hErase :
      psEraseCoreModuleWithRuntimePrelude
          environment
          psSelfHostRuntimePreludeDeclarationsWithProd
          prepared.declarations =
        Except.error error) :
    psCompilerErasedIrFromPrepared prepared =
      Except.error (.erasure error) := by
  simp [psCompilerErasedIrFromPrepared, hEnvironment, hErase]

theorem pscv_erased_ir_success
    (prepared : PsCompilerAdmissionReadyModule)
    (environment : PsEnvironment)
    (raw : PsVerifiedIrModule)
    (hEnvironment :
      psCompilerEnvironmentFromPrepared prepared = Except.ok environment)
    (hErase :
      psEraseCoreModuleWithRuntimePrelude
          environment
          psSelfHostRuntimePreludeDeclarationsWithProd
          prepared.declarations =
        Except.ok raw) :
    psCompilerErasedIrFromPrepared prepared =
      Except.ok (PsErasedIrModule.mk raw) := by
  simp [psCompilerErasedIrFromPrepared, hEnvironment, hErase]

theorem pscv_verified_ir_erasure_error
    (prepared : PsCompilerAdmissionReadyModule)
    (error : PsCompilerError)
    (hErase :
      psCompilerErasedIrFromPrepared prepared = Except.error error) :
    psCompilerVerifiedIrFromPrepared prepared =
      Except.error error := by
  simp [psCompilerVerifiedIrFromPrepared, hErase]

theorem pscv_verified_ir_validation_error
    (prepared : PsCompilerAdmissionReadyModule)
    (erased : PsErasedIrModule)
    (error : PsVerifiedIrValidationError)
    (hErase :
      psCompilerErasedIrFromPrepared prepared = Except.ok erased)
    (hValidate :
      psValidateErasedIrModule erased = Except.error error) :
    psCompilerVerifiedIrFromPrepared prepared =
      Except.error (.irValidation error) := by
  simp [psCompilerVerifiedIrFromPrepared, hErase, hValidate]

theorem pscv_verified_ir_success
    (prepared : PsCompilerAdmissionReadyModule)
    (erased : PsErasedIrModule)
    (validated : PsValidatedIrModule)
    (hErase :
      psCompilerErasedIrFromPrepared prepared = Except.ok erased)
    (hValidate :
      psValidateErasedIrModule erased = Except.ok validated) :
    psCompilerVerifiedIrFromPrepared prepared =
      Except.ok validated := by
  simp [psCompilerVerifiedIrFromPrepared, hErase, hValidate]

theorem pscv_verified_ir_elaborated_prepare_error
    (elaborated : PsElabModuleResult)
    (error : PsCompilerError)
    (hPrepare :
      psCompilerPrepareElaborated elaborated = Except.error error) :
    psCompilerVerifiedIrFromElaborated elaborated =
      Except.error error := by
  simp [psCompilerVerifiedIrFromElaborated, hPrepare]

theorem pscv_verified_ir_elaborated_success
    (elaborated : PsElabModuleResult)
    (prepared : PsCompilerAdmissionReadyModule)
    (validated : PsValidatedIrModule)
    (hPrepare :
      psCompilerPrepareElaborated elaborated = Except.ok prepared)
    (hValidated :
      psCompilerVerifiedIrFromPrepared prepared = Except.ok validated) :
    psCompilerVerifiedIrFromElaborated elaborated =
      Except.ok validated := by
  simp [psCompilerVerifiedIrFromElaborated, hPrepare, hValidated]

theorem pscv_verified_ir_source_prepare_error
    (kind : PsCompilerSourceKind)
    (source : String)
    (error : PsCompilerError)
    (hPrepare :
      psCompilerPrepareSource kind source = Except.error error) :
    psCompilerVerifiedIrSource kind source =
      Except.error error := by
  simp [psCompilerVerifiedIrSource, hPrepare]

theorem pscv_verified_ir_source_success
    (kind : PsCompilerSourceKind)
    (source : String)
    (prepared : PsCompilerAdmissionReadyModule)
    (validated : PsValidatedIrModule)
    (hPrepare :
      psCompilerPrepareSource kind source = Except.ok prepared)
    (hValidated :
      psCompilerVerifiedIrFromPrepared prepared = Except.ok validated) :
    psCompilerVerifiedIrSource kind source =
      Except.ok validated := by
  simp [psCompilerVerifiedIrSource, hPrepare, hValidated]
