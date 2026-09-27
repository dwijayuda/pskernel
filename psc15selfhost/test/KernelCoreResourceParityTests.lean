import Ps.KernelCore.Resource
import PSC1Kernel.TypeChecker

def psKernelCoreResourceOkUnit
    (result : PsKernelCoreResult String Unit) : Bool :=
  match result with
  | PsKernelCoreResult.ok _ => true
  | PsKernelCoreResult.error _ => false

def psKernelCoreResourceExactError
    (result : PsKernelCoreResult String Unit)
    (expected : String) : Bool :=
  match result with
  | PsKernelCoreResult.error actual => actual == expected
  | PsKernelCoreResult.ok _ => false

def psReferenceResourceOkUnit
    (result : Except String Unit) : Bool :=
  match result with
  | Except.ok _ => true
  | Except.error _ => false

def psReferenceResourceExactError
    (result : Except String Unit)
    (expected : String) : Bool :=
  match result with
  | Except.error actual => actual == expected
  | Except.ok _ => false

def psKernelCoreResourceConstantsParity : Bool :=
  psKernelCoreLeanNatMaxSizeDefault == PSC1Kernel.leanNatMaxSizeDefault &&
  psKernelCoreLeanUInt32Max == PSC1Kernel.leanUInt32Max &&
  psKernelCoreLeanMaxSmallNat == PSC1Kernel.leanMaxSmallNat

def psKernelCoreResourceSizeParity : Bool :=
  let values : List Nat := [
    0,
    1,
    PSC1Kernel.leanMaxSmallNat,
    PSC1Kernel.leanMaxSmallNat + 1,
    (2 ^ 64) - 1,
    2 ^ 64,
    (2 ^ 128) - 1,
    2 ^ 128
  ]
  values.all (fun value =>
    psKernelCoreNatSizeInBytes value == PSC1Kernel.natSizeInBytes value)

def psKernelCoreResourceLimitParity : Bool :=
  let tiny : PsKernelCoreResourceConfig := { maxNatSize := 8 }
  let exactValue : Nat := (2 ^ 64) - 1
  let overValue : Nat := 2 ^ 64
  let expected :=
    "the kernel refused a Nat numeral because its size exceeds the maximum"
  psKernelCoreResourceOkUnit (psKernelCoreCheckNatSize tiny exactValue) &&
  psReferenceResourceOkUnit (PSC1Kernel.checkNatSize 8 exactValue) &&
  psKernelCoreResourceExactError
    (psKernelCoreCheckNatSize tiny overValue) expected &&
  psReferenceResourceExactError
    (PSC1Kernel.checkNatSize 8 overValue) expected

def psKernelCoreResourceCountParity : Bool :=
  let op := "Nat.pow"
  let expected :=
    "the kernel refused to evaluate Nat.pow because its second argument does not fit in a 32-bit unsigned integer"
  psKernelCoreResourceOkUnit
      (psKernelCoreCheckCountArg op psKernelCoreLeanUInt32Max) &&
  psReferenceResourceOkUnit
      (PSC1Kernel.checkCountArg op PSC1Kernel.leanUInt32Max) &&
  psKernelCoreResourceExactError
      (psKernelCoreCheckCountArg op (psKernelCoreLeanUInt32Max + 1)) expected &&
  psReferenceResourceExactError
      (PSC1Kernel.checkCountArg op (PSC1Kernel.leanUInt32Max + 1)) expected

def psKernelCoreResourceErrorDistinctFromBudget : Bool :=
  let tiny : PsKernelCoreResourceConfig := { maxNatSize := 8 }
  let result :=
    psKernelCoreCheckNatSize tiny (2 ^ 64)
  match result with
  | PsKernelCoreResult.error message =>
      message != "reduction budget exhausted" &&
      message != "inference budget exhausted" &&
      message != "check budget exhausted"
  | PsKernelCoreResult.ok _ => false

def psKernelCoreResourceParity : Bool :=
  psKernelCoreResourceConstantsParity &&
  psKernelCoreResourceSizeParity &&
  psKernelCoreResourceLimitParity &&
  psKernelCoreResourceCountParity &&
  psKernelCoreResourceErrorDistinctFromBudget

def main : IO Unit := do
  if !psKernelCoreResourceParity then
    throw (IO.userError "PSC2_KERNEL_CORE_RESOURCE_PARITY: FAIL")
  IO.println "PSC2_KERNEL_CORE_RESOURCE_PARITY: PASS"
