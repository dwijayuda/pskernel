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

/- PSC0's 55-source compiler closure includes deeply nested inductive
   admissions. The general small-request kernel policy (fuel=4096) is
   intentionally not increased globally. This host-only policy bounds one
   full compiler admission by a fixed larger *semantic checking* budget.
   Resource exhaustion still rejects; no provider fallback or unchecked
   declaration insertion is permitted. The host process has a separate
   wall-clock limit. -/
def compilerSelfHostResourcePolicy : PsKernelResourcePolicy :=
  { psKernelResourcePolicyDefault with fuel := 131072 }

-- Every request starts with a freshly checked prelude. A failed transaction
-- exposes neither a session nor a partial environment to the host.
def checkCanonicalAdmissions (source : String)
    (resources : PsKernelResourcePolicy := compilerSelfHostResourcePolicy) :
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
