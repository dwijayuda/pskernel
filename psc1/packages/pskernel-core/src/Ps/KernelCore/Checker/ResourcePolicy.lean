import Ps.KernelCore.Core.Name

/- Resource policy for one public operation. Fuel is a recursive bound, not a
   consumed instruction count; each declaration receives the same configured
   bound. Cancellation is sampled before entry. The pure portable checker cannot
   interrupt a running call or catch host stack/memory failures. -/
structure PsKernelResourcePolicy where
  fuel : Nat
  maxRecDepth : Nat
  maxNatSize : Nat
  cancelled : Bool
  maxDeclarations : Nat

inductive PsKernelResourceError where
  | fuel
  | recursionDepth
  | natSize
  | cancelled
  | declarationLimit
  | hostStack

def psKernelResourcePolicyDefault : PsKernelResourcePolicy :=
  PsKernelResourcePolicy.mk 4096 0 (Nat.mul (Nat.mul 128 1024) 1024) false 0

def psKernelResourceMessageWithPrefix
    (prefix : String) (message : String) : Option PsKernelResourceError :=
  if psKernelStringEq message (String.Internal.append prefix "deep recursion detected, use maxRecDepth to increase the limit") then
    Option.some PsKernelResourceError.recursionDepth
  else if psKernelStringEq message (String.Internal.append prefix "kernel defeq argument budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel defeq argument-list budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel defeq forall-spine budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel defeq lambda-spine budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel definitional equality budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel inference budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel lazy-delta budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel lazy-projection budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel projection field budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel projection parameter budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel recursor budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel reduction budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "kernel structure eta budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "mutual constructor field budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "mutual recursive-argument budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "nested auxiliary-name budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "nested constructor parameter budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "nested expression mapping budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "nested preprocessing queue budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "nested restoration parameter budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "nested rule comparison budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "simple inductive constructor admission budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "simple inductive constructor parameter budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "simple inductive elimination budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "simple inductive field budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "simple inductive index budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "simple inductive recursive-argument budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "simple inductive uniform-occurrence budget exhausted") then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message (String.Internal.append prefix "the kernel refused a Nat numeral because its size exceeds the maximum") then
    Option.some PsKernelResourceError.natSize
  else if psKernelStringEq message (String.Internal.append prefix "the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size") then
    Option.some PsKernelResourceError.natSize
  else
    Option.none

def psKernelResourceMessage
    (message : String) : Option PsKernelResourceError :=
  psKernelResourceMessageWithPrefix "" message

def psKernelResourcePreflight
    (policy : PsKernelResourcePolicy) : Option PsKernelResourceError :=
  if policy.cancelled then
    Option.some PsKernelResourceError.cancelled
  else if Nat.beq policy.fuel 0 then
    Option.some PsKernelResourceError.fuel
  else
    Option.none

def psKernelResourceAllowsSize
    (policy : PsKernelResourcePolicy)
    (declarations : Nat) : Bool :=
  if Nat.beq policy.maxDeclarations 0 then true
  else Nat.ble declarations policy.maxDeclarations
