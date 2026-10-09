import Ps.KernelCore.API.KernelContractV1

theorem psKernelTargetIdentityV1_contract :
    psKernelTargetIdentityV1.contract = "KernelContract-v1" := by
  rfl

theorem psKernelTargetIdentityV1_version :
    psKernelTargetIdentityV1.leanVersion = "4.34.0" := by
  rfl

theorem psKernelTargetIdentityV1_commit :
    psKernelTargetIdentityV1.leanCommit =
      "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b" := by
  rfl
