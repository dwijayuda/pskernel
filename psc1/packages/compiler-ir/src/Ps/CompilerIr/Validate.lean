import Ps.CompilerIr.Check
import Ps.CompilerIr.Specialize
import Ps.Foundation.Name

-- A raw construction wrapper is never independent admission evidence.
inductive PsVerifiedIrValidationError where
  | illTypedOrUnresolved
  | budgetExhausted

def psValidateErasedIrModule
    (source : PsErasedIrModule) :
    Except PsVerifiedIrValidationError PsValidatedIrModule :=
  let report := psCheckVerifiedIrModule psIrCheckDefaultOptions source.raw;
  if !report.traversalComplete then
    Except.error PsVerifiedIrValidationError.budgetExhausted
  else if report.accepted then Except.ok (PsValidatedIrModule.mk source.raw)
  else Except.error PsVerifiedIrValidationError.illTypedOrUnresolved

-- Revalidate on every call, including manually constructed wrapper data.
def psStrictValidateModule
    (module : PsVerifiedIrModule) :
    Except PsVerifiedIrValidationError PsValidatedIrModule :=
  psValidateErasedIrModule (PsErasedIrModule.mk module)

def psStrictFindDeclaration
    (declarations : List PsVerifiedIrDeclaration) (name : String) :
    Option PsVerifiedIrDeclaration :=
  match declarations with
  | List.nil => Option.none
  | List.cons declaration rest =>
      if psStringEq declaration.name name then Option.some declaration
      else psStrictFindDeclaration rest name
