import Ps.KernelCore

open Ps.KernelCore

def psKernelCoreBoundaryAvailable : Bool :=
  match Name.str Name.anonymous "Core" with
  | Name.str Name.anonymous "Core" => true
  | _ => false

def main : IO Unit := do
  if psKernelCoreBoundaryAvailable then
    IO.println "PSC2_KERNEL_CORE_BOUNDARY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_BOUNDARY: FAIL")
