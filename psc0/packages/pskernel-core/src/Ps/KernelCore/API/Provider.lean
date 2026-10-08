import Ps.KernelCore.API.KernelContractV1

structure PsKernelProviderCapability where
  target : PsKernelTargetIdentity
  nativeEvaluator : Option PsKernelNativeEvaluator

def psKernelProviderDefault : PsKernelProviderCapability :=
  PsKernelProviderCapability.mk psKernelTargetIdentityV1 Option.none

def psKernelProviderCompatible (provider : PsKernelProviderCapability) : Bool :=
  if psKernelStringEq provider.target.contract psKernelTargetIdentityV1.contract then
    if psKernelStringEq provider.target.leanVersion psKernelTargetIdentityV1.leanVersion then
      psKernelStringEq provider.target.leanCommit psKernelTargetIdentityV1.leanCommit
    else false
  else false
