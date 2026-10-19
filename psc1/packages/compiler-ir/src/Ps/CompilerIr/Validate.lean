import Ps.CompilerIr.Check
import Ps.CompilerIr.Specialize

-- PSC1's copied experimental backends referenced a validator that was absent
-- from this older bootstrap tree. Restore a real bounded IR gate before enabling
-- those backends; a raw PsVerifiedIrModule is never an admission certificate.
inductive PsVerifiedIrValidationError where
  | illTypedOrUnresolved
  | budgetExhausted
  deriving Repr

def psValidateErasedIrModule
    (source : PsErasedIrModule) :
    Except PsVerifiedIrValidationError PsValidatedIrModule :=
  let report := psCheckVerifiedIrModule psIrCheckDefaultOptions source.raw
  if !report.traversalComplete then
    Except.error .budgetExhausted
  else if report.accepted then
    Except.ok { raw := source.raw }
  else
    Except.error .illTypedOrUnresolved

-- Compatibility entry: the full checker runs on every call, not just once
-- when the IR is first constructed.
def psStrictValidateModule
    (module : PsVerifiedIrModule) :
    Except PsVerifiedIrValidationError PsValidatedIrModule :=
  psValidateErasedIrModule { raw := module }
