import Ps.DriverJs.Bootstrap
import Ps.CompilerIr.Encode
import Ps.BackendJs.Encode

inductive PsCompilerJavaScriptStagesError where
  | compiler (error : PsCompilerError)
  | javaScript (error : PsCompilerJavaScriptError)
  | encode (error : PsIrEncodeError)
  | targetValidation (error : PsJsIrValidationError)
  | targetSnapshot (error : PsJsIrEncodeError)

structure PsCompilerJavaScriptStages where
  javaScript : String
  runtimeIr : String
  verifiedIr : String
  specializedIr : String
  jsIr : String

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
              match
                  psJsLowerSpecializedValidatedModuleWithProfile
                    (Option.some psCompilerJavaScriptTarget64)
                    specialized with
              | Except.error error =>
                  Except.error
                    (PsCompilerJavaScriptStagesError.javaScript
                      (PsCompilerJavaScriptError.emit
                        (PsJsEmitError.lower error)))
              | Except.ok jsIr =>
                  match psJsValidateModule jsIr with
                  | Except.error error =>
                      Except.error
                        (PsCompilerJavaScriptStagesError.targetValidation
                          error)
                  | Except.ok _ =>
                      match psJsIrEncodeModule jsIr with
                      | Except.error error =>
                          Except.error
                            (PsCompilerJavaScriptStagesError.targetSnapshot
                              error)
                      | Except.ok targetIr =>
                          match psJsPrintModuleStackSafe jsIr with
                          | Except.error error =>
                              Except.error
                                (PsCompilerJavaScriptStagesError.javaScript
                                  (PsCompilerJavaScriptError.emit error))
                          | Except.ok output =>
                              Except.ok
                                (PsCompilerJavaScriptStages.mk
                                  output
                                  runtime
                                  verified
                                  encoded
                                  targetIr)

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
