import Ps.KernelCore.API.KernelContractV1

theorem psKernelTargetIdentityV1_contract :
    psKernelTargetIdentityV1.contract = "KernelContract-v1" := by
  rfl

theorem psKernelTargetIdentityV1_version :
    psKernelTargetIdentityV1.leanVersion = "4.35.0-rc4" := by
  rfl

theorem psKernelTargetIdentityV1_commit :
    psKernelTargetIdentityV1.leanCommit =
      "c29b6dda4f7c20e3eeaa717c4e565663c5cfa364" := by
  rfl
