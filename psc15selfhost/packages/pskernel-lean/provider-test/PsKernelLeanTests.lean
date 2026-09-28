import PsKernelLean.Protocol

def expectEq (label actual expected : String) : IO Unit := do
  if actual == expected then
    pure ()
  else
    throw <| IO.userError s!"{label}: expected {expected}, got {actual}"

def main : IO Unit := do
  expectEq "providerProtocol" PsKernelLean.providerProtocol "pskernel-lean/1"
  expectEq "providerName" PsKernelLean.providerName "lean4-cpp"
  expectEq "providerVersion" PsKernelLean.providerVersion "4.34.0"
  expectEq "providerProfile" PsKernelLean.providerProfile "lean4.34-core"
  expectEq "leanVersion" Lean.versionString "4.34.0"
  IO.println "PSC2_LEAN_KERNEL_PROVIDER_METADATA: PASS"
