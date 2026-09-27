import Ps.KernelCore.Data

structure PsKernelCoreResourceConfig where
  maxNatSize : Nat

def psKernelCoreLeanNatMaxSizeDefault : Nat :=
  134217728

def psKernelCoreResourceConfigDefault : PsKernelCoreResourceConfig :=
  { maxNatSize := psKernelCoreLeanNatMaxSizeDefault }

def psKernelCoreLeanUInt32Max : Nat :=
  4294967295

def psKernelCoreLeanMaxSmallNat : Nat :=
  9223372036854775807

def psKernelCoreNatHeapLimbDivisor : Nat :=
  18446744073709551616

def psKernelCoreNatHeapWordCountFuel
    (fuel : Nat) : Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun (_current : Nat) => 0
  | Nat.succ remaining =>
      let smaller : Nat -> Nat :=
        psKernelCoreNatHeapWordCountFuel remaining;
      fun (current : Nat) =>
        if Nat.beq current 0 then
          0
        else
          Nat.add 1 (smaller (Nat.div current psKernelCoreNatHeapLimbDivisor))

def psKernelCoreNatHeapWordCount (value : Nat) : Nat :=
  psKernelCoreNatHeapWordCountFuel value value

def psKernelCoreNatSizeInBytes (value : Nat) : Nat :=
  if Nat.ble value psKernelCoreLeanMaxSmallNat then
    8
  else
    Nat.mul (psKernelCoreNatHeapWordCount value) 8

def psKernelCoreCheckNatSize
    (resources : PsKernelCoreResourceConfig)
    (value : Nat) : PsKernelCoreResult String Unit :=
  if Nat.ble (psKernelCoreNatSizeInBytes value) resources.maxNatSize then
    PsKernelCoreResult.ok Unit.unit
  else
    PsKernelCoreResult.error
      "the kernel refused a Nat numeral because its size exceeds the maximum"

def psKernelCoreCheckCountArg
    (operation : String)
    (count : Nat) : PsKernelCoreResult String Unit :=
  if Nat.ble count psKernelCoreLeanUInt32Max then
    PsKernelCoreResult.ok Unit.unit
  else
    PsKernelCoreResult.error
      (String.append
        "the kernel refused to evaluate "
        (String.append operation
          " because its second argument does not fit in a 32-bit unsigned integer"))
