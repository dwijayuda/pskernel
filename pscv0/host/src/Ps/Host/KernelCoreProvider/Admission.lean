import Ps.Host.KernelCoreProvider.Protocol
import Ps.Host.KernelCoreProvider.Prelude

namespace PsKernelCoreProvider

def admissionError (error : PsKernelError) (index : Nat) : PsKernelCoreProviderError :=
  { kind := match error with
      | .rejectedInvalid _ => .kernelRejection
      | .declinedUnsupported _ => .unsupportedCoreForm
      | .resourceExhausted _ _ => .resourceExhausted
      | .internalError _ => .providerInternalError
    message := kernelErrorMessage error
    declarationIndex := some index }

-- Every request starts with a freshly checked prelude. A failed transaction
-- exposes neither a session nor a partial environment to the host.
def checkCanonicalAdmissions (source : String)
    (resources : PsKernelResourcePolicy := psKernelResourcePolicyDefault) :
    Except PsKernelCoreProviderError PsKernelKernelSession := do
  let declarations ← decodeCanonicalAdmissions source
  let prelude ← buildCorePreludeSession
  let mut session := { prelude with resources := resources }
  let mut index := 0
  for declaration in declarations do
    match psKernelV1AdmitDeclaration session declaration with
    | .ok result => session := result.session
    | .error error => throw (admissionError error index)
    index := index + 1
  pure session

end PsKernelCoreProvider
