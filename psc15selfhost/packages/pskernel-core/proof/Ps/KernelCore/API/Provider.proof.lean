import Ps.KernelCore.API.Provider

/-!
Proofs for the provider-target compatibility boundary.

These lemmas are intentionally about the exact public decision procedure. They
make explicit that provider identity mismatches fail closed before a checked
session can be constructed.
-/

theorem psKernelProviderCompatible_of_fields
    (provider : PsKernelProviderCapability)
    (hContract :
      psKernelStringEq
          provider.target.contract
          psKernelTargetIdentityV1.contract = true)
    (hVersion :
      psKernelStringEq
          provider.target.leanVersion
          psKernelTargetIdentityV1.leanVersion = true)
    (hCommit :
      psKernelStringEq
          provider.target.leanCommit
          psKernelTargetIdentityV1.leanCommit = true) :
    psKernelProviderCompatible provider = true := by
  simp [psKernelProviderCompatible, hContract, hVersion, hCommit]

theorem psKernelProviderIncompatible_of_contract
    (provider : PsKernelProviderCapability)
    (hContract :
      psKernelStringEq
          provider.target.contract
          psKernelTargetIdentityV1.contract = false) :
    psKernelProviderCompatible provider = false := by
  simp [psKernelProviderCompatible, hContract]

theorem psKernelProviderIncompatible_of_version
    (provider : PsKernelProviderCapability)
    (hContract :
      psKernelStringEq
          provider.target.contract
          psKernelTargetIdentityV1.contract = true)
    (hVersion :
      psKernelStringEq
          provider.target.leanVersion
          psKernelTargetIdentityV1.leanVersion = false) :
    psKernelProviderCompatible provider = false := by
  simp [psKernelProviderCompatible, hContract, hVersion]

theorem psKernelProviderIncompatible_of_commit
    (provider : PsKernelProviderCapability)
    (hContract :
      psKernelStringEq
          provider.target.contract
          psKernelTargetIdentityV1.contract = true)
    (hVersion :
      psKernelStringEq
          provider.target.leanVersion
          psKernelTargetIdentityV1.leanVersion = true)
    (hCommit :
      psKernelStringEq
          provider.target.leanCommit
          psKernelTargetIdentityV1.leanCommit = false) :
    psKernelProviderCompatible provider = false := by
  simp [psKernelProviderCompatible, hContract, hVersion, hCommit]
