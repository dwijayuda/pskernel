import Ps.KernelCore.API.Provider
import Ps.KernelCore.Metatheory.Comparator

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


theorem psKernelProviderCompatible_refines_target_identity
    (hSound : PsKernelStringEqSoundLaw)
    (provider : PsKernelProviderCapability)
    (hCompatible :
      psKernelProviderCompatible provider = true) :
    provider.target = psKernelTargetIdentityV1 := by
  cases provider with
  | mk target nativeEvaluator =>
      cases target with
      | mk contract leanVersion leanCommit =>
          unfold psKernelProviderCompatible at hCompatible
          simp only [psKernelTargetIdentityV1] at hCompatible ⊢
          cases hContract :
              psKernelStringEq
                contract
                "KernelContract-v1" with
          | false =>
              simp [hContract] at hCompatible
          | true =>
              cases hVersion :
                  psKernelStringEq
                    leanVersion
                    "4.35.0-rc4" with
              | false =>
                  simp [
                    hContract,
                    hVersion
                  ] at hCompatible
              | true =>
                  have hCommit :
                      psKernelStringEq
                          leanCommit
                          "c29b6dda4f7c20e3eeaa717c4e565663c5cfa364" =
                        true := by
                    simpa [
                      hContract,
                      hVersion
                    ] using hCompatible
                  have hContractEq :
                      contract = "KernelContract-v1" :=
                    hSound
                      contract
                      "KernelContract-v1"
                      hContract
                  have hVersionEq :
                      leanVersion = "4.35.0-rc4" :=
                    hSound
                      leanVersion
                      "4.35.0-rc4"
                      hVersion
                  have hCommitEq :
                      leanCommit =
                        "c29b6dda4f7c20e3eeaa717c4e565663c5cfa364" :=
                    hSound
                      leanCommit
                      "c29b6dda4f7c20e3eeaa717c4e565663c5cfa364"
                      hCommit
                  rw [
                    hContractEq,
                    hVersionEq,
                    hCommitEq
                  ]

theorem psKernelProviderCompatible_true_iff_target_identity
    (hRefl : PsKernelStringEqReflexiveLaw)
    (hSound : PsKernelStringEqSoundLaw)
    (provider : PsKernelProviderCapability) :
    psKernelProviderCompatible provider = true ↔
      provider.target = psKernelTargetIdentityV1 := by
  constructor
  · exact
      psKernelProviderCompatible_refines_target_identity
        hSound
        provider
  · intro hTarget
    cases provider with
    | mk target nativeEvaluator =>
        simp only at hTarget
        subst target
        apply psKernelProviderCompatible_of_fields
        · exact hRefl psKernelTargetIdentityV1.contract
        · exact hRefl psKernelTargetIdentityV1.leanVersion
        · exact hRefl psKernelTargetIdentityV1.leanCommit
