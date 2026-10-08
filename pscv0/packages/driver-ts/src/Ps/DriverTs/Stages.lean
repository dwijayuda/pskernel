import Ps.DriverTs.Bootstrap
import Ps.CompilerIr.Encode

inductive PsCompilerTypeScriptStagesError where
  | compiler (error : PsCompilerError)
  | emit (error : PsTsEmitError)
  | encode (error : PsIrEncodeError)

structure PsCompilerTypeScriptStages where
  typeScript : String
  runtimeIr : String
  verifiedIr : String
  erasureCorrespondence : String

-- One erasure/validation/emission execution; snapshots describe the actual
-- modules passed between stages. This is an Internal/bootstrap API: only the
-- checked host session may expose its output on the production path.
def psCompilerTypeScriptStagesFromPrepared (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerTypeScriptStagesError PsCompilerTypeScriptStages :=
  match psCompilerErasureProductFromPrepared prepared with
  | Except.error error => Except.error (PsCompilerTypeScriptStagesError.compiler error)
  | Except.ok product =>
      match psIrEncodeModule product.erased.raw with
      | Except.error error => Except.error (PsCompilerTypeScriptStagesError.encode error)
      | Except.ok runtime =>
          match psValidateErasedIrModule product.erased with
          | Except.error error => Except.error (PsCompilerTypeScriptStagesError.compiler (PsCompilerError.irValidation error))
          | Except.ok validated =>
              match psIrEncodeModule validated.raw with
              | Except.error error => Except.error (PsCompilerTypeScriptStagesError.encode error)
              | Except.ok verified =>
                  match psTsEmitValidatedModule validated with
                  | Except.error error => Except.error (PsCompilerTypeScriptStagesError.emit error)
                  | Except.ok output => Except.ok (PsCompilerTypeScriptStages.mk output runtime verified product.correspondence)
