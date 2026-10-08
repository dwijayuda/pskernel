import Ps.CompilerIr.Decode
import Ps.CompilerIr.Validate

inductive PsIrArtifactValidationError where
  | decode (error : PsIrDecodeError)
  | invalidIr (error : PsVerifiedIrValidationError)

-- Freshly replay strict validation of the retained canonical bytes. The closed
-- module validator deliberately rejects external imports without link context.
def psIrValidateEncodedModule (source : String) : Except PsIrArtifactValidationError PsValidatedIrModule :=
  match psIrDecodeModule source with
  | Except.error error => Except.error (PsIrArtifactValidationError.decode error)
  | Except.ok module =>
      match psValidateErasedIrModule (PsErasedIrModule.mk module) with
      | Except.error error => Except.error (PsIrArtifactValidationError.invalidIr error)
      | Except.ok validated => Except.ok validated
