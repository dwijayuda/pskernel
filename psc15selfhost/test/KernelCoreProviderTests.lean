import Ps.Host.KernelCoreProvider.Admission

open PsKernelCoreProvider

def expectError {α : Type} (label : String) (kind : PsKernelCoreProviderErrorKind)
    (result : Except PsKernelCoreProviderError α) : IO Unit := do
  match result with
  | .error error =>
      if error.kind != kind then throw (IO.userError (label ++ ": " ++ error.message))
  | .ok _ => throw (IO.userError (label ++ ": unexpectedly accepted"))

def main : IO Unit := do
  expectError "expression mvar" .unsupportedCoreForm (toCoreExpr (.mvar 1))
  expectError "free variable" .unsupportedCoreForm (toCoreExpr (.fvar 1))
  expectError "universe mvar" .unsupportedCoreForm (toCoreLevel (.mvar 1))
  expectError "malformed JSON" .malformedRequest (checkCanonicalAdmissions "{")
  expectError "version" .protocolVersion
    (checkCanonicalAdmissions "{\"format\":\"proofscript-checked-admissions\",\"version\":1,\"admissions\":[]}")
  let source := "{\"format\":\"proofscript-checked-admissions\",\"version\":2,\"admissions\":[{\"kind\":\"constant\",\"declaration\":{\"k\":\"definition\",\"n\":{\"k\":\"s\",\"p\":{\"k\":\"a\"},\"v\":\"M4Budget\"},\"lp\":[],\"s\":\"safe\",\"h\":{\"k\":\"regular\",\"h\":\"1\"},\"t\":{\"k\":\"const\",\"n\":{\"k\":\"s\",\"p\":{\"k\":\"a\"},\"v\":\"Nat\"},\"ls\":[]},\"v\":{\"k\":\"nat\",\"v\":\"1\"}}}]}"
  for policy in [
      { psKernelResourcePolicyDefault with fuel := 0 },
      { psKernelResourcePolicyDefault with cancelled := true },
      { psKernelResourcePolicyDefault with maxDeclarations := 1 }] do
    expectError "resource outcome" .resourceExhausted (checkCanonicalAdmissions source policy)
  -- A failed call must not poison a later fresh request.
  for _ in [0:2] do
    match checkCanonicalAdmissions source with
    | .ok _ => pure ()
    | .error error => throw (IO.userError error.message)
  IO.println "M4_PROVIDER_API: PASS (conversion, malformed/version, resource outcomes, fresh sessions)"
