import Ps.KernelCore.Data

structure PsKernelCoreResourceConfig where
  maxNatSize : Nat

def psKernelCoreLeanNatMaxSizeDefault : Nat :=
  128 * 1024 * 1024

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
        if current == 0 then
          0
        else
          1 + smaller (current / psKernelCoreNatHeapLimbDivisor)

def psKernelCoreNatHeapWordCount (value : Nat) : Nat :=
  psKernelCoreNatHeapWordCountFuel value value

def psKernelCoreNatSizeInBytes (value : Nat) : Nat :=
  if value <= psKernelCoreLeanMaxSmallNat then
    8
  else
    psKernelCoreNatHeapWordCount value * 8

def psKernelCoreCheckNatSize
    (resources : PsKernelCoreResourceConfig)
    (value : Nat) : PsKernelCoreResult String Unit :=
  if psKernelCoreNatSizeInBytes value > resources.maxNatSize then
    PsKernelCoreResult.error
      "the kernel refused a Nat numeral because its size exceeds the maximum"
  else
    PsKernelCoreResult.ok Unit.unit

def psKernelCoreCheckCountArg
    (operation : String)
    (count : Nat) : PsKernelCoreResult String Unit :=
  if count > psKernelCoreLeanUInt32Max then
    PsKernelCoreResult.error
      ("the kernel refused to evaluate " ++ operation ++
        " because its second argument does not fit in a 32-bit unsigned integer")
  else
    PsKernelCoreResult.ok Unit.unit
