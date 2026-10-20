import Ps.KernelCore.API.KernelContractV1

structure PsKernelProviderCapability where
  target : PsKernelTargetIdentity
  nativeEvaluator : Option PsKernelNativeEvaluator

def psKernelProviderDefault : PsKernelProviderCapability :=
  PsKernelProviderCapability.mk psKernelTargetIdentityV1 Option.none

def psKernelProviderCompatible (provider : PsKernelProviderCapability) : Bool :=
  if psKernelStringEq provider.target.contract psKernelTargetIdentityV1.contract then
    if psKernelStringEq provider.target.leanVersion psKernelTargetIdentityV1.leanVersion then
      if psKernelStringEq provider.target.leanCommit psKernelTargetIdentityV1.leanCommit then
        -- Lean 4.35 removed kernel reduction through Lean.reduceBool/reduceNat.
        -- Retained 4.34 evaluator values cannot enable that rule for this target.
        match provider.nativeEvaluator with
        | Option.none => true
        | Option.some _ => false
      else false
    else false
  else false
