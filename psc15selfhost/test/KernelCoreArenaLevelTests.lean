import KernelCore.Foundation.Core

def main : IO Unit :=
  if psKernelCoreLevelTests then
    IO.println "PSKERNEL_CORE_ARENA_LEVEL_REGRESSION: PASS"
  else
    throw (IO.userError "PSKERNEL_CORE_ARENA_LEVEL_REGRESSION: FAIL")
