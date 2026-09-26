import Ps.KernelCore

def psKernelCoreBoundaryAvailable : Bool :=
  match PsKernelCoreName.str PsKernelCoreName.anonymous "Core" with
  | PsKernelCoreName.str PsKernelCoreName.anonymous "Core" => true
  | _ => false

def main : IO Unit := do
  if psKernelCoreBoundaryAvailable then
    IO.println "PSC2_KERNEL_CORE_BOUNDARY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_BOUNDARY: FAIL")
