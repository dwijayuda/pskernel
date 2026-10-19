import PsKernelLeanWasm.Api

def expectEq (label actual expected : String) : IO Unit := do
  if actual == expected then pure ()
  else throw <| IO.userError s!"{label}: expected {expected}, got {actual}"

def expectContains (label value needle : String) : IO Unit := do
  if (value.splitOn needle).length > 1 then pure ()
  else throw <| IO.userError s!"{label}: expected {needle} in {value}"

private def validRequest : String :=
  "{\"admissions\":[{\"declaration\":{\"h\":{\"h\":\"1\",\"k\":\"regular\"},\"k\":\"definition\",\"lp\":[],\"n\":{\"k\":\"s\",\"p\":{\"k\":\"a\"},\"v\":\"wasmAccepted\"},\"s\":\"safe\",\"t\":{\"k\":\"const\",\"ls\":[],\"n\":{\"k\":\"s\",\"p\":{\"k\":\"a\"},\"v\":\"Nat\"}},\"v\":{\"k\":\"nat\",\"v\":\"1\"}},\"kind\":\"constant\"}],\"format\":\"proofscript-checked-admissions\",\"version\":2}"

private def invalidRequest : String :=
  "{\"admissions\":[{\"declaration\":{\"h\":{\"h\":\"1\",\"k\":\"regular\"},\"k\":\"definition\",\"lp\":[],\"n\":{\"k\":\"s\",\"p\":{\"k\":\"a\"},\"v\":\"wasmRejected\"},\"s\":\"safe\",\"t\":{\"k\":\"const\",\"ls\":[],\"n\":{\"k\":\"s\",\"p\":{\"k\":\"a\"},\"v\":\"Nat\"}},\"v\":{\"k\":\"sort\",\"l\":{\"k\":\"z\"}}},\"kind\":\"constant\"}],\"format\":\"proofscript-checked-admissions\",\"version\":2}"

def main : IO Unit := do
  let accepted ← PsKernelLeanWasm.checkCanonicalAdmissionsJson validRequest
  expectContains "accepted protocol" accepted "\"protocol\":\"pskernel-lean/1\""
  expectContains "accepted provider" accepted "\"provider\":\"lean4-cpp\""
  expectContains "accepted value" accepted "\"accepted\":true"

  let acceptedAgain ← PsKernelLeanWasm.checkCanonicalAdmissionsJson validRequest
  expectEq "repeated deterministic check" acceptedAgain accepted

  let rejected ← PsKernelLeanWasm.checkCanonicalAdmissionsJson invalidRequest
  expectContains "kernel rejected" rejected "\"accepted\":false"
  expectContains "kernel rejection kind" rejected "\"errorKind\":\"kernel-rejection\""
  expectContains "kernel rejection index" rejected "\"declarationIndex\":0"

  let malformed ← PsKernelLeanWasm.checkCanonicalAdmissionsJson "{"
  expectContains "malformed rejected" malformed "\"accepted\":false"
  expectContains "malformed kind" malformed "\"errorKind\":\"malformed-request\""

  let wrongVersion ← PsKernelLeanWasm.checkCanonicalAdmissionsJson
    "{\"admissions\":[],\"format\":\"proofscript-checked-admissions\",\"version\":1}"
  expectContains "version rejected" wrongVersion "\"accepted\":false"
  expectContains "version kind" wrongVersion "\"errorKind\":\"protocol-version\""

  IO.println "PSC2_LEAN_KERNEL_WASM_API_TESTS: PASS"
