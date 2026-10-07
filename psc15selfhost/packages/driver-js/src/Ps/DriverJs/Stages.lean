import Ps.DriverJs.Bootstrap
import Ps.CompilerIr.Encode

inductive PsCompilerJavaScriptStagesError where
  | compiler (error : PsCompilerError)
  | javaScript (error : PsCompilerJavaScriptError)
  | encode (error : PsIrEncodeError)

structure PsCompilerJavaScriptStages where
  javaScript : String
  runtimeIr : String
  verifiedIr : String
  specializedIr : String

-- The snapshots come from one actual pipeline execution. A checked host
-- capability is still required for production access to this internal API.
def psCompilerJavaScriptStagesFromValidated
    (runtime verified : String)
    (validated : PsValidatedIrModule) :
    Except PsCompilerJavaScriptStagesError PsCompilerJavaScriptStages :=
  match psCompilerJavaScriptSpecializeValidatedIr validated with
  | Except.error error => Except.error (PsCompilerJavaScriptStagesError.javaScript error)
  | Except.ok specialized =>
      match psValidateErasedIrModule (PsErasedIrModule.mk specialized.raw) with
      | Except.error error =>
          Except.error (PsCompilerJavaScriptStagesError.compiler (PsCompilerError.irValidation error))
      | Except.ok _ =>
          match psIrEncodeModule specialized.raw with
          | Except.error error => Except.error (PsCompilerJavaScriptStagesError.encode error)
          | Except.ok encoded =>
              match psCompilerJavaScriptEmitSpecialized specialized with
              | Except.error error => Except.error (PsCompilerJavaScriptStagesError.javaScript error)
              | Except.ok output => Except.ok (PsCompilerJavaScriptStages.mk output runtime verified encoded)

def psCompilerJavaScriptStagesFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerJavaScriptStagesError PsCompilerJavaScriptStages :=
  match psCompilerErasedIrFromPrepared prepared with
  | Except.error error => Except.error (PsCompilerJavaScriptStagesError.compiler error)
  | Except.ok erased =>
      match psIrEncodeModule erased.raw with
      | Except.error error => Except.error (PsCompilerJavaScriptStagesError.encode error)
      | Except.ok runtime =>
          match psValidateErasedIrModule erased with
          | Except.error error =>
              Except.error (PsCompilerJavaScriptStagesError.compiler (PsCompilerError.irValidation error))
          | Except.ok validated =>
              match psIrEncodeModule validated.raw with
              | Except.error error => Except.error (PsCompilerJavaScriptStagesError.encode error)
              | Except.ok verified => psCompilerJavaScriptStagesFromValidated runtime verified validated
