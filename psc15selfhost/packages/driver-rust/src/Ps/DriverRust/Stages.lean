import Ps.DriverRust.Bootstrap
import Ps.CompilerIr.Encode

inductive PsCompilerRustStagesError where
  | compiler (error : PsCompilerError)
  | emit (error : PsRustEmitError)
  | encode (error : PsIrEncodeError)

structure PsCompilerRustStages where
  rustSource : String
  runtimeIr : String
  verifiedIr : String
  erasureCorrespondence : String

-- Retain the current generic source backend without inventing a RustIR.
-- These are observed stages, not a source-to-Rust preservation theorem.
-- Production output still requires the host's live accepted source session.
def psCompilerRustStagesFromPrepared (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerRustStagesError PsCompilerRustStages :=
  match psCompilerErasureProductFromPrepared prepared with
  | Except.error error => Except.error (PsCompilerRustStagesError.compiler error)
  | Except.ok product =>
      match psIrEncodeModule product.erased.raw with
      | Except.error error => Except.error (PsCompilerRustStagesError.encode error)
      | Except.ok runtime =>
          match psValidateErasedIrModule product.erased with
          | Except.error error =>
              Except.error (PsCompilerRustStagesError.compiler (PsCompilerError.irValidation error))
          | Except.ok validated =>
              match psIrEncodeModule validated.raw with
              | Except.error error => Except.error (PsCompilerRustStagesError.encode error)
              | Except.ok verified =>
                  match psRustEmitValidatedModule validated with
                  | Except.error error => Except.error (PsCompilerRustStagesError.emit error)
                  | Except.ok output =>
                      Except.ok (PsCompilerRustStages.mk output runtime verified product.correspondence)
