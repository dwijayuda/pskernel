import Ps.KernelCore.Name
import PSC1Kernel.Name

def psKernelCoreNameParity : Bool :=
  let kcAnon := PsKernelCoreName.anonymous
  let kcFoo := PsKernelCoreName.str kcAnon "Foo"
  let kcBar := PsKernelCoreName.str kcAnon "Bar"
  let kcFooOne := PsKernelCoreName.num kcFoo 1
  let kcFooTwo := PsKernelCoreName.num kcFoo 2
  let refAnon := PSC1Kernel.Name.anonymous
  let refFoo := PSC1Kernel.Name.str refAnon "Foo"
  let refBar := PSC1Kernel.Name.str refAnon "Bar"
  let refFooOne := PSC1Kernel.Name.num refFoo 1
  let refFooTwo := PSC1Kernel.Name.num refFoo 2
  (psKernelCoreNameEq kcAnon kcAnon == PSC1Kernel.Name.eq refAnon refAnon) &&
  (psKernelCoreNameEq kcFoo kcFoo == PSC1Kernel.Name.eq refFoo refFoo) &&
  (psKernelCoreNameEq kcFoo kcBar == PSC1Kernel.Name.eq refFoo refBar) &&
  (psKernelCoreNameEq kcFooOne kcFooOne == PSC1Kernel.Name.eq refFooOne refFooOne) &&
  (psKernelCoreNameEq kcFooOne kcFooTwo == PSC1Kernel.Name.eq refFooOne refFooTwo) &&
  (psKernelCoreNameEq kcFoo kcFooOne == PSC1Kernel.Name.eq refFoo refFooOne) &&
  (!psKernelCoreNameHasDuplicates [kcFoo, kcBar, kcFooOne]) &&
  psKernelCoreNameHasDuplicates [kcFoo, kcBar, kcFoo]

def main : IO Unit := do
  if psKernelCoreNameParity then
    IO.println "PSC2_KERNEL_CORE_NAME_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_NAME_PARITY: FAIL")
