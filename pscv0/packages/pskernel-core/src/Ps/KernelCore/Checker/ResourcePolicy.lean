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

def psKernelResourceMessage
    (message : String) : Option PsKernelResourceError :=
  if psKernelStringEq message "deep recursion detected, use maxRecDepth to increase the limit" then
    Option.some PsKernelResourceError.recursionDepth
  else if psKernelStringEq message "kernel defeq argument budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel defeq argument-list budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel defeq forall-spine budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel defeq lambda-spine budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel definitional equality budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel inference budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel lazy-delta budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel lazy-projection budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel projection field budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel projection parameter budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel recursor budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel reduction budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "kernel structure eta budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "mutual constructor field budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "mutual recursive-argument budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "nested auxiliary-name budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "nested constructor parameter budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "nested expression mapping budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "nested preprocessing queue budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "nested restoration parameter budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "nested rule comparison budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "simple inductive constructor admission budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "simple inductive constructor parameter budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "simple inductive elimination budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "simple inductive field budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "simple inductive index budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "simple inductive recursive-argument budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "simple inductive uniform-occurrence budget exhausted" then
    Option.some PsKernelResourceError.fuel
  else if psKernelStringEq message "the kernel refused a Nat numeral because its size exceeds the maximum" then
    Option.some PsKernelResourceError.natSize
  else if psKernelStringEq message "the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size" then
    Option.some PsKernelResourceError.natSize
  else
    Option.none

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
