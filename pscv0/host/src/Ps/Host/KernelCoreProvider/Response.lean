import Ps.Host.KernelCoreProvider.Admission

namespace PsKernelCoreProvider

def providerAcceptedJson : String :=
  "{" ++ providerIdentityJsonFields ++
  ",\"accepted\":true}"

def providerErrorIndexJson : Option Nat -> String
  | none => ""
  | some declarationIndex =>
      ",\"declarationIndex\":" ++ toString declarationIndex

def providerRejectedJson (error : PsKernelCoreProviderError) : String :=
  "{" ++ providerIdentityJsonFields ++
  ",\"accepted\":false" ++
  ",\"errorKind\":" ++ psJsonQuote error.kind.code ++
  providerErrorIndexJson error.declarationIndex ++
  ",\"message\":" ++ psJsonQuote error.message ++
  "}"

def checkCanonicalAdmissionsJson (source : String) : IO String := do
  let result := checkCanonicalAdmissions source
  match result with
  | .ok _ => pure providerAcceptedJson
  | .error error => pure (providerRejectedJson error)

end PsKernelCoreProvider
