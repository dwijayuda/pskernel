import Ps.Compiler.Candidate
import Ps.Erasure.Definition
import Ps.CompilerIr.Validate

-- Unchecked transformation implementation. Only bootstrap drivers and the trusted
-- checked host composition may invoke this layer; candidate preparation cannot.
def psCompilerEnvironmentFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsEnvironment :=
  match psCompilerValidatePrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      match
          psAddDeclarationList
            psSelfHostProdPreludeEnvironment
            prepared.declarations with
      | Except.error error =>
          Except.error (PsCompilerError.elaboration error)
      | Except.ok environment =>
          Except.ok environment

def psCompilerErasedIrFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsErasedIrModule :=
  match psCompilerEnvironmentFromPrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok environment =>
      match
          psEraseCoreModuleWithRuntimePrelude
            environment
            psSelfHostRuntimePreludeDeclarationsWithProd
            prepared.declarations with
      | Except.error error =>
          Except.error (PsCompilerError.erasure error)
      | Except.ok ir =>
          Except.ok (PsErasedIrModule.mk ir)

def psCompilerVerifiedIrFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerError PsValidatedIrModule :=
  match psCompilerErasedIrFromPrepared prepared with
  | Except.error error =>
      Except.error error
  | Except.ok erased =>
      match psValidateErasedIrModule erased with
      | Except.error error =>
          Except.error (PsCompilerError.irValidation error)
      | Except.ok validated =>
          Except.ok validated

def psCompilerVerifiedIrFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerError PsValidatedIrModule :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerVerifiedIrFromPrepared prepared

def psCompilerVerifiedIrSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsValidatedIrModule :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok prepared =>
      psCompilerVerifiedIrFromPrepared prepared
