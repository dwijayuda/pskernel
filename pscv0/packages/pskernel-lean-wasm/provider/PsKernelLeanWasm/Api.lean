import PsKernelLean.Response

namespace PsKernelLeanWasm

def checkCanonicalAdmissionsJson (source : String) : IO String :=
  PsKernelLean.checkCanonicalAdmissionsJson source

end PsKernelLeanWasm
